import Cocoa

class ConversionEngine: NSObject {
    var isKatakana = false
    var romakanaDic = [String: String]()
    var kanakanjiDic = [String: String]()
    var symbolDic = [String: Bool]()
    var particleDic = [String: Bool]()
    
    override init() {
        super.init()
        
        NSLog("Initializing Hiragany...");
        romakanaDic = loadPlist(name: "RomaKana") ?? [:]
        kanakanjiDic = loadPlist(name: "KanaKanji") ?? [:]
        symbolDic = loadPlist(name: "Symbols") ?? [:]
        particleDic = loadPlist(name: "Particles") ?? [:]
    }
    
    func convertRomanToKana(string: String) -> [String] {
        let buf1 = NSMutableString()
        let buf2 = NSMutableString()
        var buf = buf1
        var range = NSMakeRange(0, 0)
        
        let key: NSString = (isKatakana ? string.uppercased() : string.lowercased()) as NSString
        while range.location + range.length < key.length {
            range.length += 1
            let k = key.substring(with: range)
            var converted = romakanaDic[k]
            if let converted = converted {
                if isSymbol(k) {
                    buf2.append(converted)
                    return [buf1 as String, buf2 as String]
                }
            } else {
                if k.count == 1 ||
                    romakanaDic[ "\(k)\(isKatakana ? "A" : "a")" ] != nil ||
                    romakanaDic[ "\(k)\(isKatakana ? "U" : "u")" ] != nil {
                    continue  // The next letter may solve.
                }
                
                let firstChar = k[k.startIndex]
                if firstChar == "n" {  // n is special
                    converted = "ん"
                } else if firstChar == "N" {  // N is awesome
                    converted = "ン"
                } else {
                    if firstChar == k[k.index(after: k.startIndex)] {
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
            buf2.append(key.substring(with: range))
        }
        if buf2.length > 0 {
            return [buf1 as String, buf2 as String]
        } else {
            return [buf1 as String]
        }
    }
    
    private let kMaxParticleLength = 2

    func convertKanaToKanji(string: String) -> [String] {
        if let converted = kanakanjiDic[string] {
            return [converted]
        }
        for i in 1...kMaxParticleLength {
            let len = string.count - i
            if len <= 0 { break }
            let index = string.index(string.startIndex, offsetBy: len)
            let particle = String(string[index...])
            if particleDic[particle] == true {
                if let converted = kanakanjiDic[ String(string[..<index]) ] {
                    return [converted, particle]
                }
            }
        }
        return ["", string]
    }
    
    func convertHiraToKata(string: String) -> String {
        let buf = NSMutableString(string: string)
        CFStringTransform(buf, nil, kCFStringTransformHiraganaKatakana, false)
        return buf as String
    }
    
    func convert(string: String) -> [String] {
        let kana = convertRomanToKana(string: string)
        let converted = convertKanaToKanji(string: kana[0])
        if kana.count == 1 {
            return converted
        } else {
            if converted.count == 1 {
                return [ converted[0], kana[1]]
            } else {
                return [ converted[0], "\(converted[1])\(kana[1])"]
            }
        }
    }
    
    func isSymbol(_ string: String) -> Bool {
        return symbolDic[string] == true
    }
    
    private func loadPlist<T>(name: String) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "plist"), let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? T
        } catch {
            print("BUG: \(error)")
        }
        return nil
    }

}
