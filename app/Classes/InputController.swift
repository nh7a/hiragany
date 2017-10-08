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
        NSLog("InputController got initialized")
    }
    
    override open func inputText(_ string: String!, key keyCode: Int, modifiers flags: Int, client sender: Any!) -> Bool {
        NSLog("input: string(%@), keyCode(%X), flags(%X)", string, keyCode, flags)
        
        guard let client = sender as? IMKTextInput else { return false }
        
        let flags = NSEvent.ModifierFlags(rawValue: UInt(flags))
        if flags.contains(.command) || flags.contains(.control) {
            commitComposition(client: client)
            return false
        }
        
        let charset = CharacterSet.alphanumerics.union(.punctuationCharacters).union(.symbols)
        if !Scanner(string: string).scanCharacters(from: charset, into: nil) {
            NSLog("control code!")
            if romanBuffer.isEmpty, kanaBuffer.isEmpty { return false }
            var handled = true
            switch keyCode {
            case 0x33:  // delete key
                deleteBackward(client: client)
                return true
            case 0x24:  // enter key
                handled = false
            case 0x31:  // space
                receive(string: " ", client: client)
            case 0x30:  // tab key
                fixTrailingN(client: client)
            default:
                NSLog("Unexpected Input: keyCode(%lX) flags(%lX)", keyCode, flags.rawValue)
                handled = false
            }
            commitComposition(client: client)
            return handled
        }
        
        if receive(string: string, client: client) {
            return true
        }
        
        NSLog("buffer: %@,%@,%@", kanjiBuffer, kanaBuffer, romanBuffer)
        if ConversionEngine.shared.isSymbol(string) {
            NSLog("flush: symbol")
            commitComposition(client: client)
        } else {
            showPreedit(client: client)
        }
        return true
    }
    
    open override func menu() -> NSMenu! {
        let m = NSMenu(title: "Hiragany")
        let item = m.addItem(withTitle: "Kakamany Mode", action: #selector(toggleKakamany), keyEquivalent: "")
        item.state = isKakamanyMode ? .on : .off
        return m
    }
}

private extension InputController {
    @discardableResult
    func receive(string: String, client: IMKTextInput) -> Bool {
        let kana = ConversionEngine.shared.toKana(roman: romanBuffer + string)
        kanaBuffer += kana.candidate
        romanBuffer = kana.remainder
        
        if isKakamanyMode {
            let kanji = ConversionEngine.shared.toKanji(kana: kanaBuffer)
            kanjiBuffer = kanji.candidate + kanji.remainder
        } else {
            if romanBuffer.isEmpty {
                commitComposition(client: client)
                return true
            }
        }
        return false
    }

    func commitComposition(client: IMKTextInput) {
        let text = getPreedit()
        if !text.isEmpty {
            NSLog("commit: \(text)")
            client.insertText(text, replacementRange: NSMakeRange(NSNotFound, NSNotFound))
            romanBuffer = ""
            kanaBuffer = ""
            kanjiBuffer = ""
        }
    }
    
    func deleteBackward(client: IMKTextInput) {
        if !romanBuffer.isEmpty {
            romanBuffer.removeLast()
        } else if !kanaBuffer.isEmpty {
            kanaBuffer.removeLast()
        }
        
        let kanji = ConversionEngine.shared.toKanji(kana: kanaBuffer)
        kanjiBuffer = kanji.candidate + kanji.remainder
        
        showPreedit(client: client)
    }

    func getPreedit() -> String {
        return (kanjiBuffer.isEmpty ? kanaBuffer : kanjiBuffer) + romanBuffer
    }
    
    func showPreedit(client: IMKTextInput) {
        let text = getPreedit()
        client.setMarkedText(text, selectionRange: NSMakeRange(0, text.count), replacementRange: NSMakeRange(NSNotFound, NSNotFound))
    }
    
    func fixTrailingN(client: IMKTextInput) {
        if romanBuffer == "n" || romanBuffer == "N" {
            receive(string: romanBuffer, client: client)
        }
    }
    
    @objc func toggleKakamany() {
        isKakamanyMode = !isKakamanyMode
        UserDefaults.standard.set(isKakamanyMode, forKey: "kakamany")
    }
}
