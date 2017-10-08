import XCTest
@testable import Hiragany

class HiraganyTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test(_ converter: (String) -> ConversionEngine.Result, string: String, candidate: String, remainder: String) {
        let r = converter(string)
        XCTAssertEqual(r.candidate, candidate)
        XCTAssertEqual(r.remainder, remainder)
    }

    func testRomanToKana() {
        let c = { ConversionEngine.shared.toKana(roman: $0) }
        test(c, string: "", candidate: "", remainder: "")
        test(c, string: "a", candidate: "あ", remainder: "")
        test(c, string: "d", candidate: "", remainder: "d")
        test(c, string: "da", candidate: "だ", remainder: "")
        test(c, string: "dag", candidate: "だ", remainder: "g")
        test(c, string: "gy", candidate: "", remainder: "gy")
        test(c, string: "gya", candidate: "ぎゃ", remainder: "")
        test(c, string: "kk", candidate: "っ", remainder: "k")
        test(c, string: "batta", candidate: "ばった", remainder: "")
        test(c, string: "gakki", candidate: "がっき", remainder: "")
        test(c, string: "up", candidate: "う", remainder: "p")
        test(c, string: "upd", candidate: "う", remainder: "pd")
        test(c, string: "upde", candidate: "う", remainder: "pで")
        test(c, string: "upde-", candidate: "う", remainder: "pでー")
        test(c, string: "upde-t", candidate: "う", remainder: "pでーt")
        test(c, string: "upde-ta", candidate: "う", remainder: "pでーた")
        test(c, string: "upde-tann", candidate: "う", remainder: "pでーたん")
        test(c, string: "n", candidate: "", remainder: "n")
        test(c, string: "nn", candidate: "ん", remainder: "")
        test(c, string: "ng", candidate: "ん", remainder: "g")
        test(c, string: "nga", candidate: "んが", remainder: "")
        test(c, string: "ny", candidate: "", remainder: "ny")
        test(c, string: "nya", candidate: "にゃ", remainder: "")
        test(c, string: "nky", candidate: "ん", remainder: "ky")
        test(c, string: "nkyo", candidate: "んきょ", remainder: "")
        test(c, string: "nkyon", candidate: "んきょ", remainder: "n")
        test(c, string: "nkyonk", candidate: "んきょん", remainder: "k")
        test(c, string: "nyg", candidate: "ん", remainder: "yg")
        test(c, string: "npde", candidate: "ん", remainder: "pで")
        test(c, string: "runrun", candidate: "るんる", remainder: "n")
        test(c, string: "runrun ", candidate: "るんるん", remainder: " ")
        test(c, string: "runrun.", candidate: "るんるん", remainder: "。")
        test(c, string: "runnrun", candidate: "るんる", remainder: "n")
        test(c, string: "runnrunn", candidate: "るんるん", remainder: "")
        test(c, string: "n!", candidate: "ん", remainder: "！")
        test(c, string: "ny!", candidate: "ん", remainder: "y！")
        test(c, string: "nya!u", candidate: "にゃ", remainder: "！")
        test(c, string: "xwa", candidate: "ゎ", remainder: "")
        test(c, string: "xtu", candidate: "っ", remainder: "")
        test(c, string: "Kya", candidate: "キャ", remainder: "")
        test(c, string: "kYa", candidate: "キャ", remainder: "")
    }
    
    func testRomanToKanji() {
        let c = { ConversionEngine.shared.toKanji(roman: $0) }
        test(c, string: "", candidate: "", remainder: "")
        test(c, string: "j", candidate: "", remainder: "j")
        test(c, string: "ji", candidate: "", remainder: "じ")
        test(c, string: "jik", candidate: "", remainder: "じk")
        test(c, string: "jikk", candidate: "", remainder: "じっk")
        test(c, string: "jikky", candidate: "", remainder: "じっky")
        test(c, string: "jikkyo", candidate: "", remainder: "じっきょ")
        test(c, string: "jikkyou", candidate: "実況", remainder: "")
        test(c, string: "jikkyout", candidate: "実況", remainder: "t")
        test(c, string: "jikkyouto", candidate: "実況", remainder: "と")
        test(c, string: "jikkyoutoh", candidate: "実況", remainder: "とh")
        test(c, string: "jikkyoutoha", candidate: "実況", remainder: "とは")
        test(c, string: "shindan", candidate: "", remainder: "しんだn")
        test(c, string: "shindann", candidate: "診断", remainder: "")
        test(c, string: "shindans", candidate: "診断", remainder: "s")
        test(c, string: "shindansh", candidate: "診断", remainder: "sh")
        test(c, string: "w", candidate: "", remainder: "w")
        test(c, string: "ww", candidate: "", remainder: "っw")
        test(c, string: "www", candidate: "", remainder: "っっw")
    }
    
    func testKanaToKanji() {
        let c = { ConversionEngine.shared.toKanji(kana: $0) }
        test(c, string: "", candidate: "", remainder: "")
        test(c, string: "し", candidate: "", remainder: "し")
        test(c, string: "しん", candidate: "", remainder: "しん")
        test(c, string: "しんだ", candidate: "", remainder: "しんだ")
        test(c, string: "しんだん", candidate: "診断", remainder: "")
        test(c, string: "しんだんう", candidate: "", remainder: "しんだんう")
        test(c, string: "しんだんが", candidate: "診断", remainder: "が")
        test(c, string: "しんだんって", candidate: "診断", remainder: "って")
        test(c, string: "わわわ", candidate: "", remainder: "わわわ")
    }
}
