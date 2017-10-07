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
    
    func testConvertRomanToKana() {
        let c = ConversionEngine()
        
        XCTAssertEqual(c.convertRomanToKana(string: "a"), ["あ"])
        XCTAssertEqual(c.convertRomanToKana(string: "d"), ["", "d"])
        XCTAssertEqual(c.convertRomanToKana(string: "da"), ["だ"])
        XCTAssertEqual(c.convertRomanToKana(string: "dag"), ["だ", "g"])
        XCTAssertEqual(c.convertRomanToKana(string: "gy"), ["", "gy"])
        XCTAssertEqual(c.convertRomanToKana(string: "gya"), ["ぎゃ"])
        XCTAssertEqual(c.convertRomanToKana(string: "kk"), ["っ", "k"])
        XCTAssertEqual(c.convertRomanToKana(string: "batta"), ["ばった"])
        XCTAssertEqual(c.convertRomanToKana(string: "gakki"), ["がっき"])
        XCTAssertEqual(c.convertRomanToKana(string: "up"), ["う", "p"])
        XCTAssertEqual(c.convertRomanToKana(string: "upd"), ["う", "pd"])
        XCTAssertEqual(c.convertRomanToKana(string: "upde"), ["う", "pで"])
        XCTAssertEqual(c.convertRomanToKana(string: "upde-"), ["う", "pでー"])
        XCTAssertEqual(c.convertRomanToKana(string: "upde-t"), ["う", "pでーt"])
        XCTAssertEqual(c.convertRomanToKana(string: "upde-ta"), ["う", "pでーた"])
        XCTAssertEqual(c.convertRomanToKana(string: "upde-tann"), ["う", "pでーたん"])
        XCTAssertEqual(c.convertRomanToKana(string: "n"), ["", "n"])
        XCTAssertEqual(c.convertRomanToKana(string: "nn"), ["ん"])
        XCTAssertEqual(c.convertRomanToKana(string: "ng"), ["ん", "g"])
        XCTAssertEqual(c.convertRomanToKana(string: "nga"), ["んが"])
        XCTAssertEqual(c.convertRomanToKana(string: "ny"), ["", "ny"])
        XCTAssertEqual(c.convertRomanToKana(string: "nya"), ["にゃ"])
        XCTAssertEqual(c.convertRomanToKana(string: "nky"), ["ん", "ky"])
        XCTAssertEqual(c.convertRomanToKana(string: "nkyo"), ["んきょ"])
        XCTAssertEqual(c.convertRomanToKana(string: "nyg"), ["ん", "yg"])
        XCTAssertEqual(c.convertRomanToKana(string: "npde"), ["ん", "pで"])
        XCTAssertEqual(c.convertRomanToKana(string: "runrun"), ["るんる", "n"])
        XCTAssertEqual(c.convertRomanToKana(string: "runrun "), ["るんるん", " "])
        XCTAssertEqual(c.convertRomanToKana(string: "runrun."), ["るんるん", "。"])
        XCTAssertEqual(c.convertRomanToKana(string: "runnrun"), ["るんる", "n"])
        XCTAssertEqual(c.convertRomanToKana(string: "runnrunn"), ["るんるん"])
        XCTAssertEqual(c.convertRomanToKana(string: "n!"), ["ん", "！"])
        XCTAssertEqual(c.convertRomanToKana(string: "ny!"), ["ん", "y！"])
        XCTAssertEqual(c.convertRomanToKana(string: "nya!u"), ["にゃ", "！"])
        XCTAssertEqual(c.convertRomanToKana(string: "xwa"), ["ゎ"])
        XCTAssertEqual(c.convertRomanToKana(string: "xtu"), ["っ"])
    }
    
    func testConvert() {
        let c = ConversionEngine()
        
        XCTAssertEqual(c.convert(string: "j"), ["", "j"])
        XCTAssertEqual(c.convert(string: "ji"), ["", "じ"])
        XCTAssertEqual(c.convert(string: "jik"), ["", "じk"])
        XCTAssertEqual(c.convert(string: "jikk"), ["", "じっk"])
        XCTAssertEqual(c.convert(string: "jikky"), ["", "じっky"])
        XCTAssertEqual(c.convert(string: "jikkyo"), ["", "じっきょ"])
        XCTAssertEqual(c.convert(string: "jikkyou"), ["実況"])
        XCTAssertEqual(c.convert(string: "jikkyout"), ["実況", "t"])
        XCTAssertEqual(c.convert(string: "jikkyouto"), ["実況", "と"])
        XCTAssertEqual(c.convert(string: "jikkyoutoh"), ["実況", "とh"])
        XCTAssertEqual(c.convert(string: "jikkyoutoha"), ["実況", "とは"])
        XCTAssertEqual(c.convert(string: "shindan"), ["", "しんだn"])
        XCTAssertEqual(c.convert(string: "shindann"), ["診断"])
        XCTAssertEqual(c.convert(string: "shindans"), ["診断", "s"])
        XCTAssertEqual(c.convert(string: "shindansh"), ["診断", "sh"])
        XCTAssertEqual(c.convert(string: "w"), ["", "w"])
        XCTAssertEqual(c.convert(string: "ww"), ["", "っw"])
        XCTAssertEqual(c.convert(string: "www"), ["", "っっw"])

    }
}
