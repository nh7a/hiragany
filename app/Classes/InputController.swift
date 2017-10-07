import Cocoa
import InputMethodKit

@objc(InputController)
open class InputController: IMKInputController {
    var romanBuffer = ""
    var kanaBuffer = ""
    var kanjiBuffer = ""
    var isKakamanyMode = false
    
    public override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        isKakamanyMode = UserDefaults.standard.bool(forKey: "kakamany")
    }
    
    override open func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        NSLog("input: string(%@), keyCode(%X), flags(%X)", string, keyCode, flags)
        
        guard let client = sender as? IMKTextInput else { return false }
        
        let flags = NSEvent.ModifierFlags(rawValue: UInt(flags))
        if flags.contains(.command) || flags.contains(.control) {
            return false
        }
        
        let scanner = Scanner(string: string)
        let charset = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols)
        if !scanner.scanCharacters(from: charset, into: nil) {
            NSLog("control code!")
            if romanBuffer.isEmpty, kanaBuffer.isEmpty { return false }
            var handled = false
            switch keyCode {
            case 0x28:  // 'k'
                fixTrailingN(sender: client)
                kanaBuffer = AppDelegate.converter.convertHiraToKata(string: kanaBuffer)
                handled = true
            case 0x33:  // delete key
                deleteBackward(sender: client)
                return true
            case 0x24:  // enter key
                if romanBuffer.isEmpty, kanaBuffer.isEmpty {
                    return false
                }
            case 0x31:  // space
                appendString(string: " ", sender: client)
                handled = true
            case 0x30:  // tab key
                fixTrailingN(sender: client)
                handled = true
            default:
                NSLog("Unexpected Input: keyCode(%lX) flags(%lX)", keyCode, flags.rawValue)
            }
            commitComposition(sender: client)
            return handled
        }
        
        let converter = AppDelegate.converter
        if !converter.isKatakana {
            let firstChar = string.first!
            if "A" <= firstChar, firstChar <= "Z" {  // kludge!
                converter.isKatakana = true
            }
        }
        
        if appendString(string: string, sender: client) {
            return true
        }
        NSLog("buffer: %@,%@,%@", kanjiBuffer, kanaBuffer, romanBuffer)
        if converter.isSymbol(string) {
            NSLog("flush: symbol")
            converter.isKatakana = false
            commitComposition(sender: client)
        } else {
            showPreedit(sender: client)
        }
        return true
    }
    
    open override func menu() -> NSMenu! {
        let m = NSMenu(title: "Hiragany")
        let item = m.addItem(withTitle: "Kakamany Mode", action: #selector(toggleKakamany), keyEquivalent: "")
        item.state = isKakamanyMode ? .on : .off
        return m
    }

    @objc private func toggleKakamany() {
        isKakamanyMode = !isKakamanyMode
        UserDefaults.standard.set(isKakamanyMode, forKey: "kakamany")
    }
}

private extension InputController {
    @discardableResult
    func appendString(string: String, sender: IMKTextInput) -> Bool {
        let converter = AppDelegate.converter
    
        romanBuffer += string
        let arr = converter.convertRomanToKana(string: romanBuffer)
        if arr.count == 1 {
            romanBuffer = ""
        } else {
            romanBuffer = arr[1]
        }
        kanaBuffer += arr[0]
        if !isKakamanyMode {
            if romanBuffer.isEmpty {
                commitComposition(sender: sender)
                return true
            }
        } else {
            let arr = converter.convertKanaToKanji(string: kanaBuffer)
            kanjiBuffer = arr[0]
            if arr.count == 2 {
                kanjiBuffer += arr[1]
            }
        }
        return false
    }

    func commitComposition(sender: IMKTextInput) {
        let text = getPreedit()
        if !text.isEmpty {
            sender.insertText(text, replacementRange: NSMakeRange(NSNotFound, NSNotFound))
            romanBuffer = ""
            kanaBuffer = ""
            kanjiBuffer = ""
        }
        AppDelegate.converter.isKatakana = false
    }
    
    func deleteBackward(sender: IMKTextInput) {
        if !romanBuffer.isEmpty {
            romanBuffer.removeLast()
        } else if !kanaBuffer.isEmpty {
            kanaBuffer.removeLast()
        }
        if !kanaBuffer.isEmpty {
            let arr = AppDelegate.converter.convertKanaToKanji(string: kanaBuffer)
            kanjiBuffer = arr[0]
            if arr.count == 2 {
                kanjiBuffer += arr[1]
            }
        } else {
            kanjiBuffer = ""
        }
        showPreedit(sender: sender)
    }

    func getPreedit() -> String {
        var text = ""
        if !kanjiBuffer.isEmpty {
            if !romanBuffer.isEmpty {
                text = "\(kanjiBuffer)\(romanBuffer)"
            } else {
                text = kanjiBuffer
            }
        } else if !kanaBuffer.isEmpty {
            if !romanBuffer.isEmpty {
                text = "\(kanaBuffer)\(romanBuffer)"
            } else {
                text = kanaBuffer
            }
        } else {
            text = romanBuffer
        }
        return text
    }
    
    func showPreedit(sender: IMKTextInput) {
        let text = getPreedit()
        if text.isEmpty {
            AppDelegate.converter.isKatakana = false
        }
        
        sender.setMarkedText(text, selectionRange: NSMakeRange(0, text.count), replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }
    
    func fixTrailingN(sender: IMKTextInput) {
        if romanBuffer == "n" || romanBuffer == "N" {
            appendString(string: romanBuffer, sender: sender)
        }
    }
}
