# Triển khai server AI (dolingo-ai)

[← Về module AI](modules/AI.md)

Server `Backend/dolingo-ai` chạy trên Cloudflare Workers. Gói miễn phí đủ cho giai đoạn đầu (100.000 request/ngày); chi phí chính là Anthropic API.

## Hai môi trường

| Môi trường | Worker | Dùng cho | Lệnh |
| --- | --- | --- | --- |
| staging | `dolingo-ai-staging` | bản Dev và Staging của app, TestFlight | `npm run deploy:staging` |
| prod | `dolingo-ai` | bản App Store | `npm run deploy:prod` |

`wrangler deploy` không kèm `--env` tạo `dolingo-ai-dev`, không bao giờ đụng tới prod. Mỗi môi trường có biến riêng trong `wrangler.toml` (`[env.staging.vars]`, `[env.prod.vars]`) và KV `USAGE` riêng; KV được Wrangler tự tạo ở lần deploy đầu, không cần dán id.

## Làm một lần

1. Tạo tài khoản [Cloudflare](https://dash.cloudflare.com/sign-up) (miễn phí). Workers & Pages → chọn tên miền con `*.workers.dev`.
2. Lấy **Account ID** (Workers & Pages → bên phải trang tổng quan).
3. My Profile → API Tokens → Create Token → mẫu **Edit Cloudflare Workers** → giới hạn cho tài khoản này. Đó là `CLOUDFLARE_API_TOKEN`.
4. Lấy khoá Anthropic ở [console.anthropic.com](https://console.anthropic.com) → API Keys. Nên đặt hạn mức chi tiêu tháng (Billing → Limits).
5. Tạo `CLIENT_KEY`: `openssl rand -hex 32`. Chỉ cần khi còn bản build không dùng Firebase.
6. Điền `FIREBASE_PROJECT_ID` của từng môi trường trong `wrangler.toml` (Firebase → Project settings → Project ID), `SUPPORT_EMAIL` và `LEGAL_COMPANY`, rồi commit.
7. GitHub → Settings → Secrets and variables → Actions, thêm:

| Secret | Giá trị |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` | bước 3 |
| `CLOUDFLARE_ACCOUNT_ID` | bước 2 |
| `ANTHROPIC_API_KEY` | bước 4 |
| `AI_CLIENT_KEY` | bước 5 (bỏ trống nếu không dùng) |

Muốn staging và prod dùng khoá Anthropic khác nhau: Settings → Environments → tạo `ai-staging` và `ai-prod`, đặt `ANTHROPIC_API_KEY` riêng trong từng environment. Ở `ai-prod` có thể bật **Required reviewers** để deploy prod phải có người duyệt.

## Deploy

- **Tự động:** mỗi lần merge vào `main` có sửa `Backend/dolingo-ai`, workflow **Deploy AI server** deploy staging.
- **Bằng tay:** Actions → Deploy AI server → Run workflow → chọn `staging` hoặc `prod`.

Workflow chạy `check` và `test`, deploy, chép secret vào Worker, rồi chạy kiểm tra nhanh (`npm run smoke`): `/health` trả `ok` (tức là đã có khoá Anthropic), `/privacy` và `/terms` mở được, gọi `/v1/chat` không có token bị từ chối. Kiểm tra này không tốn lượt AI. URL của Worker in ở phần Summary của lần chạy.

Từ máy mình cũng được:

```bash
cd Backend/dolingo-ai
npm ci
npx wrangler login
npm run deploy:staging
printf '%s' "$ANTHROPIC_API_KEY" | npx wrangler secret put ANTHROPIC_API_KEY --env staging
npm run smoke -- https://dolingo-ai-staging.<tên miền con>.workers.dev
```

Chạy thử trên máy: tạo `Backend/dolingo-ai/.dev.vars` (git bỏ qua) chứa `ANTHROPIC_API_KEY=...` và `CLIENT_KEY=...`, rồi `npm run dev`.

## Nối app với server

Trong `Apps/Dolingo/Config/Secrets.xcconfig` (và secret `DOLINGO_SECRETS_XCCONFIG` cho TestFlight, xem [TestFlight.md](TestFlight.md)):

```
AI_BASE_URL = https:/$()/dolingo-ai-staging.<tên miền con>.workers.dev          // bản Dev
AI_BASE_URL_STAGING = https:/$()/dolingo-ai-staging.<tên miền con>.workers.dev  // bản Staging, TestFlight
AI_BASE_URL_PROD = https:/$()/dolingo-ai.<tên miền con>.workers.dev             // bản App Store
AI_CLIENT_KEY = <CLIENT_KEY nếu dùng>
```

`Staging.xcconfig` và `Prod.xcconfig` lấy `AI_BASE_URL` từ dòng của mình, nên một file Secrets build đúng server cho mọi cấu hình. Trang `/privacy` và `/terms` mặc định lấy từ cùng server (`LEGAL_BASE_URL = $(AI_BASE_URL)` trong `Shared.xcconfig`); dùng URL của **prod** khi điền Privacy Policy URL trên App Store Connect.

Có tên miền riêng thì thêm route trong `wrangler.toml` (ví dụ `routes = [{ pattern = "ai.dolingo.app", custom_domain = true }]` trong `[env.prod]`) để URL không đổi khi đổi tài khoản Cloudflare.

## Sau khi lên

- Xem log: Cloudflare → Workers → `dolingo-ai` → Logs (đã bật `observability`), hoặc `npx wrangler tail --env prod`.
- Đổi giới hạn lượt mỗi ngày: sửa `DAILY_LIMIT` trong `wrangler.toml` rồi deploy lại.
- Khi mọi bản build đã đăng nhập bằng Firebase: đặt `REQUIRE_SIGN_IN = "true"` cho prod và xoá secret `AI_CLIENT_KEY`.
- Quay về bản trước: `npx wrangler rollback --env prod`.
