import Anthropic from "@anthropic-ai/sdk";
import type { ChatRequest } from "./chat.ts";
import { learnerContext, TUTOR_PROMPT } from "./prompts.ts";

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

export class ClaudeReplySource implements ReplySource {
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
}

export function errorCode(error: unknown): ReplyErrorCode {
  if (error instanceof Anthropic.RateLimitError) return "busy";
  if (error instanceof Anthropic.APIConnectionError) return "unavailable";
  if (error instanceof Anthropic.APIError && typeof error.status === "number" && error.status >= 500) return "busy";
  return "failed";
}
