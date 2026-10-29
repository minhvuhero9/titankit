# Màn hình Dolingo trong Figma

[← Về kế hoạch App 1](App1-Plan.md)

Danh sách 112 màn hình của file Figma [DOLINGO-MUNIR-CLONE](https://www.figma.com/design/G2hGbh5hv7vDyJTbyiWyEv/DOLINGO-MUNIR-CLONE) để chia việc giai đoạn 5 và khỏi phải đọc lại Figma (gói Starter có rất ít lượt gọi mỗi tháng).

- Trang Light Theme: node `727:25421`. Trang Dark Theme: node `751:16280`. Màn tối dùng cùng bố cục, chỉ khác màu, nên chỉ cần đọc trang sáng; màu tối đã có trong `DolingoTheme`.
- Mỗi màn hình rộng 430 × 932. Mở một màn: `https://www.figma.com/design/G2hGbh5hv7vDyJTbyiWyEv/?node-id=<node, thay ":" bằng "-">`.
- Cột trạng thái: "Đã có" là màn dựng sẵn trong kit đã nối vào Dolingo; "Chưa làm" là việc của giai đoạn 5.

## Mở app (1–2)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 1 | splash screen | `3821:124001` | Đã có (`SplashScreen`) |
| 2 | welcome screen | `34449:19508` | Đã có (`OnboardingScreen`) |

## Đăng ký: bộ câu hỏi và tạo tài khoản (3–20)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 3 | sign up step 1 - select language to learn | `34455:27367` | Đã có (`SurveyScreen`) |
| 4 | sign up step 2 - select language for dolingo app | `34455:27732` | Đã có (`SurveyScreen`) |
| 5 | sign up step 3 - select current language level | `34457:28187` | Đã có (`SurveyScreen`) |
| 6 | sign up step 4 - select reason for language learning | `34457:29208` | Đã có (`SurveyScreen`) |
| 7 | sign up step 5 - select skills area to focus | `34457:30402` | Đã có (`SurveyScreen`) |
| 8 | sign up step 6 - select main challenge in language learning | `34457:30625` | Đã có (`SurveyScreen`) |
| 9 | sign up step 7 - select age | `34457:30974` | Đã có (`SurveyScreen`) |
| 10 | sign up step 8 - select profession area | `34457:31127` | Đã có (`SurveyScreen`) |
| 11 | sign up step 9 - select favorite topics | `34457:31277` | Đã có (`SurveyScreen`) |
| 12 | sign up step 10 - select learning time plan | `34457:36724` | Đã có (`SurveyScreen`) |
| 13 | sign up step 11 - set reminder time | `34457:37649` | Đã có (`SurveyScreen`) |
| 14 | sign up step 12 - select information source | `34458:38304` | Đã có (`SurveyScreen`) |
| 15 | preparing personalized learning plan | `34460:39659` | Đã có (`PreparingScreen`) |
| 16 | your plan is ready | `34460:39912` | Đã có (`SuccessScreen`) |
| 17 | sign up - enter name | `34460:40734` | Đã có (`SignUpScreen`) |
| 18 | sign up - enter email address | `34460:41011` | Đã có (`SignUpScreen`) |
| 19 | sign up - create password | `34460:41074` | Đã có (`SignUpScreen`) |
| 20 | sign up - creating an account | `34462:44363` | Đã có (`SignUpScreen`) |

## Đăng nhập và quên mật khẩu (21–27)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 21 | sign in blank form | `34461:41625` | Đã có (`LoginScreen`) |
| 22 | sign in filled form | `34461:44049` | Đã có (`LoginScreen`) |
| 23 | sign in loading | `34462:44226` | Đã có (`LoginScreen`) |
| 24 | forgot password | `4746:54104` | Chưa làm |
| 25 | enter OTP code | `4748:54244` | Chưa làm |
| 26 | create new password | `4748:54475` | Chưa làm |
| 27 | reset password successful | `4748:54632` | Chưa làm |

## Home và học bài với gia sư (28–47)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 28 | home - learning language progress fit page | `38444:40009` | Chưa làm |
| 28 | home - learning language progress scroll page | `38433:64225` | Chưa làm |
| 29 | learn language - loading | `38439:34041` | Chưa làm |
| 30 | learn a language - learn with tutor (interaction & speaking practice) | `38439:34644` | Chưa làm |
| 31 | learn a language - users practice speaking | `38441:35638` | Chưa làm |
| 32 | learn a language - users practice speaking | `38441:35794` | Chưa làm |
| 33 | learn a language - users practice speaking - perfect | `38441:35930` | Chưa làm |
| 34 | learn a language - users practice speaking - almost there | `38443:36290` | Chưa làm |
| 35 | learn a language - users practice speaking - oops.. try again | `38443:36399` | Chưa làm |
| 36 | learn a language - users practice speaking - we can't hear you | `38443:36508` | Chưa làm |
| 37 | learn language - lessons completed | `38443:37541` | Chưa làm |
| 38 | streak modal | `36442:80868` | Chưa làm |
| 39 | share streak milestone | `36443:83530` | Chưa làm |
| 40 | user earned badge modal | `36443:83722` | Chưa làm |
| 41 | share badge achievements | `36444:83903` | Chưa làm |
| 42 | learn a language - settings | `38443:36657` | Chưa làm |
| 43 | home - learning language progress fit page | `38444:40404` | Chưa làm |
| 44 | home - my courses | `38444:40811` | Chưa làm |
| 45 | home - my courses (multiple courses) | `38444:41201` | Chưa làm |
| 46 | home - learning language progress scroll page | `38444:41901` | Chưa làm |
| 47 | learn a language - leave lessons | `38443:37352` | Chưa làm |

## Chat: roleplay và chatbot AI (48–70)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 48 | chats (roleplay & AI chatbot) | `38446:43357` | Chưa làm |
| 49 | roleplay - meeting new friends | `38449:45077` | Chưa làm |
| 50 | roleplay chat | `38450:45605` | Chưa làm |
| 51 | roleplay chat - translate chat | `38456:35372` | Chưa làm |
| 52 | roleplay chat - hint | `38456:35531` | Chưa làm |
| 53 | roleplay chat - speak with active hint | `38456:35755` | Chưa làm |
| 54 | roleplay chat - chat sent | `38456:35923` | Chưa làm |
| 55 | roleplay chat - tasks & goal | `38456:36146` | Chưa làm |
| 56 | roleplay chat - settings | `38456:36481` | Chưa làm |
| 57 | roleplay chat - continue chat & speak | `38456:36945` | Chưa làm |
| 58 | roleplay chat - tasks & goal achieved | `38456:37136` | Chưa làm |
| 59 | roleplay chat - tasks & goal achieved modal | `38456:37337` | Chưa làm |
| 60 | create coleplay free trial modal | `38463:39694` | Chưa làm |
| 61 | create roleplay blank form | `38457:37773` | Chưa làm |
| 62 | create roleplay filled form | `38458:37930` | Chưa làm |
| 63 | create roleplay - generating scenario | `38458:38033` | Chưa làm |
| 64 | roleplay chat | `38458:38117` | Chưa làm |
| 65 | my roleplay | `38459:38355` | Chưa làm |
| 66 | my roleplay - more options menu | `38459:38594` | Chưa làm |
| 67 | my roleplay - delete my roleplay | `38459:38791` | Chưa làm |
| 68 | chat with dolingo - type message | `38459:38999` | Chưa làm |
| 69 | chat with dolingo | `38459:39244` | Chưa làm |
| 70 | premium content modal | `38459:39897` | Chưa làm |

## Speak: sổ tay câu và luyện nói (71–82)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 71 | speak (phrasebook) | `38459:39518` | Chưa làm |
| 72 | speaking practice | `38459:40146` | Chưa làm |
| 73 | speaking practice - play audio | `38459:42234` | Chưa làm |
| 74 | speaking practice - play audio in slow mode | `38459:42368` | Chưa làm |
| 75 | speaking practice - user speak | `38459:42505` | Chưa làm |
| 76 | speaking practice - perfect | `38459:42642` | Chưa làm |
| 77 | speaking practice - almost there | `38461:20220` | Chưa làm |
| 78 | speaking practice - oops.. try again | `38461:20351` | Chưa làm |
| 79 | speaking practice - we can't hear you | `38461:20488` | Chưa làm |
| 80 | speaking practice - save phrase | `38461:20679` | Chưa làm |
| 81 | speaking practice - leave lessons | `38461:20818` | Chưa làm |
| 82 | speak - saved phrases | `38461:20965` | Chưa làm |

## Tiến độ và thành tích (83–85)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 83 | my progress - insights | `36444:95432` | Chưa làm |
| 84 | my progress - achievements | `38461:38786` | Chưa làm |
| 85 | my progress - achievements - badge | `38461:39248` | Chưa làm |

## Tài khoản, cài đặt, nâng cấp (86–112)

| # | Màn hình | Node | Trạng thái |
| --- | --- | --- | --- |
| 86 | account & settings | `30478:40857` | Đã có (`SettingsScreen`) |
| 87 | upgrade plan - monthly | `10469:37147` | Đã có, cần so Figma (`PaywallScreen`) |
| 88 | upgrade plan - yearly | `10469:37813` | Đã có, cần so Figma (`PaywallScreen`) |
| 89 | choose payment methods | `10469:38008` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 90 | review summary | `10469:39913` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 91 | processing payment | `14479:39026` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 92 | upgrade plan subscription successful | `10469:40191` | Chưa làm |
| 93 | settings - personal info | `26452:26758` | Đã có, cần so Figma (`ProfileScreen`) |
| 94 | settings - preferences | `34500:45916` | Chưa làm |
| 95 | settings - manage courses | `34500:46927` | Chưa làm |
| 96 | settings - notification | `34500:47555` | Chưa làm |
| 97 | settings - account & security | `24484:40375` | Chưa làm |
| 98 | settings - billing & subscriptions | `24484:40381` | Chưa làm |
| 99 | settings - linked accounts | `24484:40369` | Chưa làm |
| 100 | settings - data & analytics | `34503:30531` | Chưa làm |
| 101 | settings - payment methods | `12462:31975` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 102 | add new payment | `12462:31911` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 103 | new payment method added | `12462:31904` | Bỏ: App Store bắt buộc mua qua Apple IAP, không nhập thẻ |
| 104 | settings - app appearance | `4296:47952` | Đã có (`AppearanceScreen`) |
| 105 | settings - app appearance - theme | `4303:61354` | Đã có (`AppearanceScreen`) |
| 106 | settings - app appearance - app language | `4303:61469` | Đã có (`AppearanceScreen`) |
| 107 | settings - help & support | `4299:51417` | Chưa làm |
| 108 | settings - help & support - FAQ | `4299:51654` | Chưa làm |
| 109 | settings - help & support - contact support | `4299:51893` | Chưa làm |
| 110 | settings - help & support - privacy policy | `4299:52080` | Đã có (`WebPageScreen`) |
| 111 | settings - help & support - terms of service | `4299:52181` | Đã có (`WebPageScreen`) |
| 112 | settings - logout | `32467:34622` | Đã có (`SettingsScreen`) |

## Ghi chú

- Màn 89–91 và 101–103 (chọn phương thức thanh toán, nhập thẻ) không làm: gói Premium là hàng số, App Store bắt buộc bán qua In-App Purchase. Sheet thanh toán của Apple thay cho các màn này; màn 92 (nâng cấp thành công) vẫn làm.
- Roleplay, chatbot AI và chấm điểm phát âm cần backend. Trước giai đoạn 4 chúng chạy bằng Repository Mock của app.
