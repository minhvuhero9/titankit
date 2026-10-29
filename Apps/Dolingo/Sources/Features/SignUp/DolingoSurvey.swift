import SwiftUI
import TitanFeatures
import TitanIcons
import TitanLocalization

/// The 12 sign-up questions from the Figma screens "sign up step 1" to "step 12".
/// Answers are saved by step id in `DolingoKeys.surveyAnswers`.
@MainActor
enum DolingoSurvey {
    enum Step {
        static let language = "language"
        static let appLanguage = "appLanguage"
        static let level = "level"
        static let reason = "reason"
        static let skills = "skills"
        static let challenge = "challenge"
        static let age = "age"
        static let profession = "profession"
        static let topics = "topics"
        static let dailyGoal = "dailyGoal"
        static let reminder = "reminder"
        static let source = "source"
    }

    /// Languages Dolingo teaches, with their flag.
    static let languages: [(code: String, flag: String)] = [
        ("en", "🇺🇸"), ("zh", "🇨🇳"), ("es", "🇪🇸"), ("fr", "🇫🇷"), ("hi", "🇮🇳"),
        ("ar", "🇦🇪"), ("ja", "🇯🇵"), ("ko", "🇰🇷"), ("de", "🇩🇪"),
    ]

    /// Minutes a day for each daily goal option.
    static let dailyMinutes = [5, 10, 15, 30, 60]

    static func steps(appLanguages: [String] = AppConfig.languages) -> [SurveyStep] {
        [
            SurveyStep(Step.language, title: Text("survey.language.title"), kind: .single(
                languages.map { SurveyOption($0.code, title: languageName($0.code), emoji: $0.flag) }
            )),
            SurveyStep(Step.appLanguage, title: Text("survey.appLanguage.title"), kind: .single(
                appLanguages.map { code in
                    SurveyOption(code, title: Text(verbatim: Language(code).displayName), emoji: appLanguageFlag(code))
                }
            )),
            SurveyStep(Step.level, kind: .single([
                SurveyOption("beginner", title: Text("survey.level.beginner"), detail: Text("survey.level.beginner.detail"), icon: Image(tk: TKColorIcon.signalLow)),
                SurveyOption("elementary", title: Text("survey.level.elementary"), detail: Text("survey.level.elementary.detail"), icon: Image(tk: TKColorIcon.signalMedium)),
                SurveyOption("intermediate", title: Text("survey.level.intermediate"), detail: Text("survey.level.intermediate.detail"), icon: Image(tk: TKColorIcon.signalHigh)),
                SurveyOption("advanced", title: Text("survey.level.advanced"), detail: Text("survey.level.advanced.detail"), icon: Image(tk: TKColorIcon.signalFull)),
            ])) { answers in
                Text("survey.level.title \(learningLanguageName(answers))")
            },
            SurveyStep(Step.reason, kind: .single([
                SurveyOption("travel", title: Text("survey.reason.travel"), icon: Image(tk: TKColorIcon.airplane)),
                SurveyOption("career", title: Text("survey.reason.career"), icon: Image(tk: TKColorIcon.briefcase)),
                SurveyOption("education", title: Text("survey.reason.education"), icon: Image(tk: TKColorIcon.greenBook)),
                SurveyOption("culture", title: Text("survey.reason.culture"), icon: Image(tk: TKColorIcon.familyManGirl)),
                SurveyOption("fun", title: Text("survey.reason.fun"), icon: Image(tk: TKColorIcon.confettiBall)),
                SurveyOption("other", title: Text("survey.option.other"), icon: Image(tk: TKColorIcon.other)),
            ])) { answers in
                Text("survey.reason.title \(learningLanguageName(answers))")
            },
            SurveyStep(Step.skills, title: Text("survey.skills.title"), kind: .multiple(
                textOptions("survey.skills", ["all", "grammar", "speaking", "listening", "writing", "reading", "vocabulary"])
            )),
            SurveyStep(Step.challenge, title: Text("survey.challenge.title"), kind: .single(
                textOptions("survey.challenge", ["time", "motivation", "memorizing", "pronunciation", "partners", "grammar", "vocabulary"])
            )),
            SurveyStep(Step.age, title: Text("survey.age.title"), kind: .single(
                textOptions("survey.age", ["under18", "18to24", "25to34", "35to44", "45to54", "55to64", "65plus"])
            )),
            SurveyStep(Step.profession, title: Text("survey.profession.title"), kind: .single(
                textOptions("survey.profession", ["student", "educator", "professional", "healthcare", "technology", "arts", "other"])
            )),
            SurveyStep(Step.topics, title: Text("survey.topics.title"), kind: .chips(
                textOptions("survey.topic", [
                    "travel", "cooking", "yoga", "hiking", "movies", "pets", "photography", "gaming", "music",
                    "painting", "art", "sports", "fitness", "reading", "technology", "dancing", "boardGames",
                    "science", "fashion", "motorcycling", "history", "nature", "literature",
                ])
            )),
            SurveyStep(Step.dailyGoal, title: Text("survey.dailyGoal.title"), kind: .single(
                zip(dailyMinutes, [TKColorIcon.lapTimer1, .lapTimer2, .lapTimer3, .lapTimer4, .lapTimer5]).map { minutes, icon in
                    SurveyOption(String(minutes), title: Text("survey.dailyGoal.minutes \(minutes)"),
                                 detail: Text(LocalizedStringKey("survey.dailyGoal.\(minutes).detail")), icon: Image(tk: icon))
                }
            )),
            SurveyStep(Step.reminder, title: Text("survey.reminder.title"), kind: .time(hour: 20, minute: 0),
                       footnote: Text("survey.reminder.footnote")),
            SurveyStep(Step.source, title: Text("survey.source.title"), kind: .single([
                SurveyOption("social", title: Text("survey.source.social"), emoji: "📱"),
                SurveyOption("google", title: Text("survey.source.google"), icon: Image("SocialGoogle")),
                SurveyOption("youtube", title: Text("survey.source.youtube"), emoji: "▶️"),
                SurveyOption("appStore", title: Text("survey.source.appStore"), emoji: "📲"),
                SurveyOption("friends", title: Text("survey.source.friends"), icon: Image(tk: TKColorIcon.familyManGirl)),
                SurveyOption("other", title: Text("survey.option.other"), icon: Image(tk: TKColorIcon.other)),
            ])),
        ]
    }

    /// The app language the user picked in step 2, if Dolingo supports it.
    static func appLanguage(from answers: [String: SurveyAnswer], supported: [String] = AppConfig.languages) -> String? {
        answers[Step.appLanguage]?.optionIds.first.flatMap { supported.contains($0) ? $0 : nil }
    }

    static func languageName(_ code: String) -> Text {
        Text(LocalizedStringKey("survey.language.\(code)"))
    }

    private static func learningLanguageName(_ answers: [String: SurveyAnswer]) -> Text {
        languageName(answers[Step.language]?.optionIds.first ?? "en")
    }

    private static func appLanguageFlag(_ code: String) -> String {
        switch code {
        case "vi": "🇻🇳"
        case "en": "🇺🇸"
        default: "🏳️"
        }
    }

    /// Options that are only a line of text; each title is `<prefix>.<id>` in Localizable.
    private static func textOptions(_ prefix: String, _ ids: [String]) -> [SurveyOption] {
        ids.map { SurveyOption($0, title: Text(LocalizedStringKey("\(prefix).\($0)"))) }
    }
}
