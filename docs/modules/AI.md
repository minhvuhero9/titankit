# TitanAI

[← Về tổng quan](../README.md)

TitanAI cho app trò chuyện với gia sư AI. App không bao giờ giữ khoá API của nhà cung cấp AI: `RemoteChatService` nói chuyện với server riêng của app (Dolingo dùng [`Backend/dolingo-ai`](../../Backend/dolingo-ai)), server mới gọi model.

## 1. Trách nhiệm

**Làm:**
- Gửi cả cuộc trò chuyện và thông tin người học (tên, trình độ), nhận câu trả lời chảy về từng đoạn.
- Đổi lỗi mạng, lỗi server, việc model từ chối trả lời thành `ChatReplyEvent`.
- `MockChatService` trả lời ngay trên máy, từng từ một, cho preview, test và khi chưa có server.
- `AIServerClient` gọi các lệnh JSON khác của server (Dolingo dùng cho roleplay tự tạo).

**Không làm:**
- Không vẽ giao diện và không lưu cuộc trò chuyện (việc của app, Dolingo dùng `TutorChat`).
- Không gọi thẳng API của Anthropic hay nhà cung cấp nào khác.

## 2. API chính

```swift
public protocol ChatService: Sendable {
    func reply(to conversation: [ChatMessage], learner: ChatLearner) -> AsyncStream<ChatReplyEvent>
}

public enum ChatReplyEvent { case text(String), restart, done, refused, failed(TitanError) }

let chat: any ChatService = RemoteChatService(baseURL: url, clientKey: key)   // MockChatService() khi chưa có server
for await event in chat.reply(to: messages, learner: ChatLearner(level: "beginner")) {
    switch event {
    case let .text(piece): reply += piece        // nối vào câu trả lời đang hiện
    case .restart: reply = ""                     // model dự phòng trả lời lại từ đầu
    case .done: break
    case .refused, .failed: ...                   // báo lỗi, trả câu hỏi về ô nhập
    }
}
```

Luồng luôn kết thúc bằng `.done`, `.refused` hoặc `.failed`. Thôi đọc luồng (ví dụ đóng màn hình) là yêu cầu bị huỷ.

## 3. Giao thức với server

`POST <AI_BASE_URL>/v1/chat`, header `X-Dolingo-Key: <AI_CLIENT_KEY>`:

```json
{ "turns": [{ "role": "user", "text": "How do I say cảm ơn?" }], "learner": { "name": "An", "level": "beginner" } }
```

Trả về `text/event-stream`, mỗi dòng `data:` là một JSON: `{"type":"text","text":"..."}`, `{"type":"restart"}`, rồi `{"type":"done"}` hoặc `{"type":"error","code":"refused|busy|unavailable|failed"}`. Mã HTTP 400 khi yêu cầu sai, 401 khi sai khoá.

### Roleplay do người học tạo

Hai lệnh JSON thường (không stream), gọi qua `AIServerClient` trong kit, trả `AIAnswer.answer(value)` hoặc `.refused`:

- `POST /v1/roleplay/draft` với `{ title, myRole, aiRole, scenario, withGoals, learner }`: AI giữ nguyên ô người học đã viết, điền ô trống, chọn emoji, và viết 3–4 mục tiêu (kèm nghĩa tiếng Việt) khi `withGoals` bật. Trả `{ emoji, title, myRole, aiRole, scenario, tasks: [{ text, meaning }] }`.
- `POST /v1/roleplay/turn` với `{ roleplay: { title, myRole, aiRole, scenario, tasks: [{ id, text }] }, turns, learner }`: `turns` rỗng thì AI mở đầu; sau đó các lượt xen kẽ và kết thúc bằng người học. Trả `{ reply, translation, completedTaskIds, hint, hintTranslation, isFinished }`.

Lỗi: 400 yêu cầu sai, 401 sai khoá, 422 model từ chối, 503 bận, 502 lỗi khác. Server dùng structured outputs (`betaZodOutputFormat`) nên câu trả lời luôn đúng dạng JSON trên.

## 4. Server `Backend/dolingo-ai`

Cloudflare Worker viết bằng TypeScript, dùng `@anthropic-ai/sdk`:

- Model `claude-opus-5-5`, effort `low` cho câu trả lời nhanh và rẻ, `fallbacks: "default"` để yêu cầu bị từ chối được chạy lại trên model Anthropic đề xuất (lúc đó app nhận `restart`).
- Prompt gia sư cố định nằm ở `src/prompts.ts` (tiếng Anh theo trình độ, giải thích tiếng Việt khi cần, sửa tối đa hai lỗi mỗi lượt, câu trả lời ngắn cho điện thoại); thông tin người học là một khối riêng phía sau để cache prompt vẫn trúng.
- Kiểm tra yêu cầu trước khi gọi model: tối đa 40 lượt gần nhất, mỗi tin của người học tối đa 2.000 ký tự, các lượt phải xen kẽ và kết thúc bằng người học.

Chạy và triển khai:

```bash
cd Backend/dolingo-ai
npm ci
npm run check && npm test            # CI chạy hai lệnh này ở job "dolingo-ai server checks"
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put CLIENT_KEY    # một chuỗi ngẫu nhiên dài, ví dụ: openssl rand -hex 32
npm run deploy                        # in ra URL dạng https://dolingo-ai.<tài khoản>.workers.dev
```

Rồi điền vào `Apps/Dolingo/Config/Secrets.xcconfig` (chép từ `Secrets.example.xcconfig`):

```
AI_BASE_URL = https:/$()/dolingo-ai.<tài khoản>.workers.dev
AI_CLIENT_KEY = <CLIENT_KEY ở trên>
```

Để trống thì app dùng `MockChatService` và gia sư báo là chưa được kết nối.

## 5. Giới hạn hiện tại

- `CLIENT_KEY` nằm trong app nên ai bóc app ra cũng lấy được; nó chỉ chặn người gọi ngẫu nhiên. Khi có đăng nhập thật (giai đoạn 4), server sẽ kiểm tra token đăng nhập của người dùng và giới hạn số tin mỗi ngày theo tài khoản.
- Chưa giới hạn số tin chat cho người dùng miễn phí. Lượt tạo roleplay (10 lượt miễn phí) chỉ đếm trên máy, xoá app là đếm lại. Muốn giới hạn thì thêm đếm theo ngày ở `TutorChat` (trên máy) hoặc ở server (theo tài khoản).

## 6. Test

- Kit: `TitanAITests` kiểm tra request gửi đi, cách đọc từng dòng sự kiện, mã lỗi HTTP và `MockChatService`.
- App: `TutorChatTests` kiểm tra gửi tin, nhận câu trả lời chảy về, lưu lại, trả câu hỏi về ô nhập khi lỗi, `restart`, xoá cuộc trò chuyện.
- Server: `npm test` (`node:test`) kiểm tra kiểm tra đầu vào, khoá, định dạng luồng sự kiện với nguồn trả lời giả.
