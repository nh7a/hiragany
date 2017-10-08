import Cocoa

class ConversionEngine {
    typealias Result = (candidate: String, remainder: String)
    private var romakanaDic = [String: String]()
    private var kanakanjiDic = [String: String]()
    private var symbolDic = [String: Bool]()
    private var particleDic = [String: Bool]()
    
    static let shared = ConversionEngine()
    
    private init() {
        NSLog("Initializing Hiragany...");
        romakanaDic = loadPlist(name: "RomaKana")
        kanakanjiDic = loadPlist(name: "KanaKanji")
        symbolDic = loadPlist(name: "Symbols")
        particleDic = loadPlist(name: "Particles")
    }
    
    func toKana(roman string: String) -> Result {
        let buf1 = NSMutableString()
        let buf2 = NSMutableString()
        var buf = buf1
        var range = NSMakeRange(0, 0)

        let isKatakana = string.lowercased() != string
        NSLog("string: \(string) -> \(isKatakana ? "katakana" : "hiragana")")
        let nsstring: NSString = string as NSString
        while range.location + range.length < nsstring.length {
            range.length += 1
            let kk = nsstring.substring(with: range)
            let key = isKatakana ? kk.uppercased() : kk.lowercased()
            var converted = romakanaDic[key]
            if let converted = converted {
                if isSymbol(key) {
                    buf2.append(converted)
                    return (candidate: buf1 as String, remainder: buf2 as String)
                }
            } else {
                if key.count == 1 ||
                    romakanaDic[ "\(key)\(isKatakana ? "A" : "a")" ] != nil ||
                    romakanaDic[ "\(key)\(isKatakana ? "U" : "u")" ] != nil {
                    continue  // The next letter may solve.
                }
                
                let firstChar = key[key.startIndex]
                if firstChar == "n" {  // n is special
                    converted = "ん"
                } else if firstChar == "N" {  // N is awesome
                    converted = "ン"
                } else {
                    if firstChar == key[key.index(after: key.startIndex)] {
                        converted = isKatakana ? "ッ" : "っ"
                    } else {
                        converted = "\(firstChar)"
                        buf = buf2  // Switch the target buffer
                    }
                }
                range.length = 1  // Advance one letter
            }
            buf.append(converted!)
            range.location += range.length
            range.length = 0
        }
        
        if range.length > 0 {
            buf2.append(nsstring.substring(with: range))
        }
        if buf2.length > 0 {
            return (candidate: buf1 as String, remainder: buf2 as String)
        } else {
            return (candidate: buf1 as String, remainder: "")
        }
    }
    
    private let kMaxParticleLength = 2

    func toKanji(kana string: String) -> Result {
        if let converted = kanakanjiDic[string] {
            return (converted, "")
        }
        for i in 1...kMaxParticleLength {
            let len = string.count - i
            if len <= 0 { break }
            let index = string.index(string.startIndex, offsetBy: len)
            let particle = String(string[index...])
            if particleDic[particle] == true, let converted = kanakanjiDic[ String(string[..<index]) ] {
                return (converted, particle)
            }
        }
        return ("", string)
    }
    
    func toKatakana(hiragana string: String) -> String {
        let buf = NSMutableString(string: string)
        CFStringTransform(buf, nil, kCFStringTransformHiraganaKatakana, false)
        return buf as String
    }
    
    func toKanji(roman string: String) -> Result {
        let kana = toKana(roman: string)
        let kanji = toKanji(kana: kana.candidate)
        return (candidate: kanji.candidate, remainder: kanji.remainder + kana.remainder)
    }
    
    func isSymbol(_ string: String) -> Bool {
        return symbolDic[string] == true
    }
    
    private func loadPlist<T>(name: String) -> [String: T] {
        var result = [String: T]()
        
        guard let url = Bundle.main.url(forResource: name, withExtension: "plist") else {
            NSLog("BUG: \(name) is not bundled")
            return result
        }
        
        do {
            let data = try Data(contentsOf: url)
            let object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            if let dict = object as? [String: T] {
                result = dict
            }
        } catch {
            NSLog("BUG: \(error)")
        }
        
        NSLog("\(name): \(result.count) entries")
        return result
    }

}
