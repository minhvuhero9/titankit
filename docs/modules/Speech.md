# TitanSpeech

[← Về tổng quan](../README.md)

TitanSpeech nghe người dùng nói, chuyển thành chữ, rồi chấm xem câu nói khớp câu mẫu tới đâu. Dolingo dùng nó cho phần luyện nói trong bài học.

## 1. Trách nhiệm

**Làm:**
- Xin quyền micro và nhận dạng giọng nói.
- Nghe một câu: tự dừng khi người dùng ngừng nói khoảng 1,5 giây, khi hết giờ hoặc khi app gọi `stop()`.
- Chấm phát âm theo từng từ (`PronunciationScore`): bỏ qua hoa thường, dấu câu, dấu thanh; từ nói thừa hay nói sót không làm lệch các từ sau.

**Không làm:**
- Không vẽ giao diện (nút micro, nhãn kết quả nằm ở app).
- Không đọc câu mẫu (dùng `AVSpeechSynthesizer` ở app).
- Chưa chấm ngữ điệu, trọng âm: cần dịch vụ chấm phát âm riêng, sẽ là một adapter khác của cùng protocol.

## 2. API chính

```swift
public protocol SpeechRecognizer: Sendable {
    func requestAuthorization() async -> Bool
    func transcribe(language: String, timeout: Duration) async throws(TitanError) -> String
    func stop()
}

let speech: any SpeechRecognizer = AppleSpeechRecognizer()      // MockSpeechRecognizer trong test
guard await speech.requestAuthorization() else { return }       // từ chối: chuyển sang chỉ nghe và đọc
let heard = try await speech.transcribe(language: "es", timeout: .seconds(8))
let score = PronunciationScore(expected: "¡Encantado de conocerte!", heard: heard)
score.percent          // 0...100
score.verdict          // .perfect (≥ 90 %), .almostThere (≥ 60 %), .tryAgain, .notHeard
score.words            // từng từ của câu mẫu và đã nói đúng chưa, để tô màu
```

## 3. Cài đặt

- `AppleSpeechRecognizer` dùng `SFSpeechRecognizer` và `AVAudioEngine`; nhận dạng ngay trên máy khi máy hỗ trợ ngôn ngữ đó, nên giọng nói không rời điện thoại.
- App phải khai báo `NSMicrophoneUsageDescription` và `NSSpeechRecognitionUsageDescription` trong Info.plist (Dolingo đặt trong `Project.swift`, bản dịch ở `Resources/InfoPlist.xcstrings`).
- Simulator không thu được tiếng từ micro ổn định: thử trên máy thật, hoặc dùng `MockSpeechRecognizer(transcripts:)` trong preview và test.

## 4. Test

- `PronunciationScoreTests`: khớp đủ, bỏ dấu, thiếu từ, thừa từ, sai từ, im lặng.
- `MockSpeechRecognizerTests`: trả lần lượt, không có quyền thì ném `.unauthorized`.
