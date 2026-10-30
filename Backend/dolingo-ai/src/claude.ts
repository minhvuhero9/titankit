import Anthropic from "@anthropic-ai/sdk";
import { betaZodOutputFormat } from "@anthropic-ai/sdk/helpers/beta/zod";
import type * as z from "zod/v4";
import type { ChatRequest } from "./chat.ts";
import { DRAFT_PROMPT, learnerContext, roleplayContext, TURN_PROMPT, TUTOR_PROMPT } from "./prompts.ts";
import { type Draft, type DraftRequest, DraftSchema, type Turn, type TurnRequest, TurnSchema } from "./roleplay.ts";

export const MODEL = "claude-opus-5-5";

/** What the app sees while a reply streams. */
export type ReplyEvent =
  | { type: "text"; text: string }
  /** Another model takes over: the text sent so far must be thrown away. */
  | { type: "restart" }
  | { type: "done" }
  | { type: "error"; code: ReplyErrorCode };

/**
 * - `refused`: the model declined, even after the fallback.
 * - `busy`: rate limited or overloaded; trying again in a moment may work.
 * - `unavailable`: the server could not reach Anthropic.
 * - `failed`: anything else.
 */
export type ReplyErrorCode = "refused" | "busy" | "unavailable" | "failed";

/** Where replies come from; tests swap in a fake. */
export interface ReplySource {
  reply(request: ChatRequest, signal?: AbortSignal): AsyncGenerator<ReplyEvent>;
}

/** A JSON answer, or why there is none. */
export type AIResult<T> = { ok: true; value: T } | { ok: false; code: ReplyErrorCode };

/** Roleplays written by the learner; tests swap in a fake. */
export interface RoleplayAI {
  draft(request: DraftRequest, signal?: AbortSignal): Promise<AIResult<Draft>>;
  turn(request: TurnRequest, signal?: AbortSignal): Promise<AIResult<Turn>>;
}

export class ClaudeReplySource implements ReplySource, RoleplayAI {
  private readonly client: Anthropic;

  constructor(apiKey: string) {
    this.client = new Anthropic({ apiKey });
  }

  async *reply(request: ChatRequest, signal?: AbortSignal): AsyncGenerator<ReplyEvent> {
    const system: Anthropic.Beta.BetaTextBlockParam[] = [{ type: "text", text: TUTOR_PROMPT }];
    const context = learnerContext(request.learner);
    if (context) system.push({ type: "text", text: context });

    try {
      const stream = this.client.beta.messages.stream(
        {
          model: MODEL,
          max_tokens: 4096,
          // Chat replies are short; low effort keeps them quick and cheap.
          output_config: { effort: "low" },
          // Caches the conversation so far for the next turn.
          cache_control: { type: "ephemeral" },
          // A declined request is retried server-side on the model Anthropic recommends.
          betas: ["server-side-fallback-2026-07-01"],
          fallbacks: "default",
          system,
          messages: request.turns.map((turn) => ({ role: turn.role, content: turn.text })),
        },
        { signal },
      );

      for await (const event of stream) {
        if (event.type === "content_block_start" && event.content_block.type === "fallback") {
          yield { type: "restart" };
        } else if (event.type === "content_block_delta" && event.delta.type === "text_delta") {
          yield { type: "text", text: event.delta.text };
        }
      }

      const message = await stream.finalMessage();
      yield message.stop_reason === "refusal" ? { type: "error", code: "refused" } : { type: "done" };
    } catch (error) {
      yield { type: "error", code: errorCode(error) };
    }
  }

  draft(request: DraftRequest, signal?: AbortSignal): Promise<AIResult<Draft>> {
    const form = {
      title: request.title,
      myRole: request.myRole,
      aiRole: request.aiRole,
      scenario: request.scenario,
      goalsWanted: request.withGoals,
    };
    return this.structured(DraftSchema, [DRAFT_PROMPT], [{ role: "user", content: JSON.stringify(form) }], signal);
  }

  turn(request: TurnRequest, signal?: AbortSignal): Promise<AIResult<Turn>> {
    const system = [TURN_PROMPT, roleplayContext(request.roleplay)];
    const context = learnerContext(request.learner);
    if (context) system.push(context);
    // The Messages API starts with a user turn; the AI's opening line follows this cue.
    const messages: Anthropic.Beta.BetaMessageParam[] = [{ role: "user", content: "(The learner is ready. Start the role-play.)" }];
    for (const turn of request.turns) {
      if (turn.role === "user" && messages.at(-1)?.role === "user") {
        // The learner spoke first: their line replaces the cue.
        messages[messages.length - 1] = { role: "user", content: turn.text };
      } else {
        messages.push({ role: turn.role, content: turn.text });
      }
    }
    return this.structured(TurnSchema, system, messages, signal);
  }

  private async structured<Schema extends z.ZodType>(
    schema: Schema,
    system: string[],
    messages: Anthropic.Beta.BetaMessageParam[],
    signal?: AbortSignal,
  ): Promise<AIResult<z.infer<Schema>>> {
    try {
      const message = await this.client.beta.messages.parse(
        {
          model: MODEL,
          max_tokens: 16000,
          output_config: { effort: "low", format: betaZodOutputFormat(schema) },
          betas: ["server-side-fallback-2026-07-01"],
          fallbacks: "default",
          system: system.map((text) => ({ type: "text" as const, text })),
          messages,
        },
        { signal },
      );
      if (message.stop_reason === "refusal") return { ok: false, code: "refused" };
      if (message.parsed_output === null) return { ok: false, code: "failed" };
      return { ok: true, value: message.parsed_output as z.infer<Schema> };
    } catch (error) {
      return { ok: false, code: errorCode(error) };
    }
  }
}

export function errorCode(error: unknown): ReplyErrorCode {
  if (error instanceof Anthropic.RateLimitError) return "busy";
  if (error instanceof Anthropic.APIConnectionError) return "unavailable";
  if (error instanceof Anthropic.APIError && typeof error.status === "number" && error.status >= 500) return "busy";
  return "failed";
}
