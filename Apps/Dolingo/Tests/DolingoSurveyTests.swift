import XCTest
import TitanFeatures
import TitanLocalization
@testable import Dolingo

@MainActor
final class DolingoSurveyTests: XCTestCase {
    func testTenStepsWithUniqueIds() {
        let steps = DolingoSurvey.steps()
        XCTAssertEqual(steps.count, 10)
        XCTAssertEqual(Set(steps.map(\.id)).count, 10)
        XCTAssertEqual(steps.first?.id, DolingoSurvey.Step.level)
        XCTAssertEqual(steps.last?.id, DolingoSurvey.Step.source)
    }

    func testEverySurveyStringExistsInBothLanguages() {
        var keys = [
            "survey.level.title", "survey.reason.title",
            "survey.skills.title", "survey.challenge.title", "survey.age.title", "survey.profession.title",
            "survey.topics.title", "survey.dailyGoal.title", "survey.dailyGoal.minutes %lld", "survey.reminder.title",
            "survey.reminder.footnote", "survey.source.title", "survey.option.other",
            "plan.preparing.title", "plan.preparing.message", "plan.ready.title", "plan.ready.message", "plan.ready.action",
        ]
        keys += DolingoSurvey.dailyMinutes.map { "survey.dailyGoal.\($0).detail" }
        for level in ["beginner", "elementary", "intermediate", "advanced"] {
            keys += ["survey.level.\(level)", "survey.level.\(level).detail"]
        }
        let options: [String: [String]] = [
            "survey.reason": ["travel", "career", "education", "culture", "fun"],
            "survey.skills": ["all", "grammar", "speaking", "listening", "writing", "reading", "vocabulary"],
            "survey.challenge": ["time", "motivation", "memorizing", "pronunciation", "partners", "grammar", "vocabulary"],
            "survey.age": ["under18", "18to24", "25to34", "35to44", "45to54", "55to64", "65plus"],
            "survey.profession": ["student", "educator", "professional", "healthcare", "technology", "arts", "other"],
            "survey.source": ["social", "google", "youtube", "appStore", "friends"],
        ]
        for (prefix, ids) in options {
            keys += ids.map { "\(prefix).\($0)" }
        }
        let topics = DolingoSurvey.steps().first { $0.id == DolingoSurvey.Step.topics }
        if case let .chips(chips)? = topics?.kind {
            keys += chips.map { "survey.topic.\($0.id)" }
        } else {
            XCTFail("Topics should be chips")
        }
        for key in keys {
            for code in AppConfig.languages {
                XCTAssertNotEqual(KitStrings.string(key, locale: Locale(identifier: code)), key, "\(key) \(code)")
            }
        }
    }
}
