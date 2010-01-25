#import "HiraganyGlobal.h"
#import "HiraganyController.h"
#import "ConversionEngine.h"
#import "HiraganyApplicationDelegate.h"

@interface HiraganyController(Private)
- (NSString*)getPreedit;
- (void)showPreedit:(id)sender;
- (BOOL)appendString:(NSString*)string sender:(id)sender;
- (void)deleteBackward:(id)sender;
- (BOOL)convert:(NSString*)trigger client:(id)sender;
@end

@implementation HiraganyController

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient {
    DebugLog(@"Initializing Hiragany...");
    if (self = [super initWithServer:server delegate:delegate client:inputClient]) {
        romanBuffer_ = [NSMutableString new];
        kanaBuffer_ = [NSMutableString new];
        kanjiBuffer_ = [NSMutableString new];
        kakamanyMode_ = [[NSUserDefaults standardUserDefaults] boolForKey:@"kakamany"];
    }
    return self;
}

-(void)dealloc {
    [romanBuffer_ release];
    [kanaBuffer_ release];
    [kanjiBuffer_ release];
    [super dealloc];
}
@end

#pragma mark IMKServerInput
@implementation HiraganyController (IMKServerInput)

- (BOOL)appendString:(NSString*)string sender:(id)sender {
    ConversionEngine* converter = [[NSApp delegate] conversionEngine];
    
    [romanBuffer_ appendString:string];
    NSArray* arr = [converter convertRomanToKana:romanBuffer_];
    if ([arr count] == 1) {
        [romanBuffer_ setString:@""];
    } else {
        [romanBuffer_ setString:[arr objectAtIndex:1]];
    }
    [kanaBuffer_ appendString:[arr objectAtIndex:0]];
    if (!kakamanyMode_) {
        if ([romanBuffer_ length] == 0) {
            [self commitComposition:sender];
            return YES;
        }
    } else if (converter.katakana) {
        [kanjiBuffer_ setString:@""];
        if ([romanBuffer_ length] == 0) {
            [self commitComposition:sender];
            return YES;
        }
    } else {
        arr = [converter convertKanaToKanji:kanaBuffer_];
        [kanjiBuffer_ setString:[arr objectAtIndex:0]];
        if ([arr count] == 2) {
            [kanjiBuffer_ appendString:[arr objectAtIndex:1]];
        }
    }
    return NO;
}

- (BOOL)inputText:(NSString*)string key:(NSInteger)keyCode modifiers:(NSUInteger)flags client:(id)sender {
    if (flags & NSCommandKeyMask) {
        DebugLog(@"flags: %X", flags);
        return NO;
    }
    DebugLog(@"inputText: %@, %X, %X", string, keyCode, flags);
    NSScanner* scanner = [NSScanner scannerWithString:string];
    NSString* scanned;
    if (![scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&scanned] &&
        ![scanner scanCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&scanned]) {
        if (![romanBuffer_ length] && ![kanaBuffer_ length]) {
            return NO;
        }
        switch (keyCode) {
            case 0x28:  // 'k'
            {
                NSLog(@"Force Katakanization");
                ConversionEngine* converter = [[NSApp delegate] conversionEngine];
                [kanaBuffer_  setString:[converter convertHiraToKata:kanaBuffer_]];
                [kanjiBuffer_ setString:@""];
                break;
            }
            case 0x33:  // delete key
                [self deleteBackward:sender];
                return YES;
            case 0x24:  // enter key
                if (![romanBuffer_ length] && ![kanaBuffer_ length]) {
                    return NO;
                }
                break;
            case 0x31:  // space
                if (flags & NSShiftKeyMask) {
                    [kanjiBuffer_ setString:@""];
                }
                // do not break to handle /n$/i
            case 0x30:  // tab key
                if ([romanBuffer_ isEqualToString:@"n"] || [romanBuffer_ isEqualToString:@"N"]) {
                    [self appendString:romanBuffer_ sender:sender];
                }
                break;
            default:
                NSLog(@"Unexpected Input: keyCode(%X) flags(%X)", keyCode, flags);
                break;
        }
        DebugLog(@"flush: control char: %X %X", keyCode, flags);
        [self commitComposition:sender];
        
        if (flags & NSShiftKeyMask) {
            return YES;
        }
        return NO;
    }
    
    ConversionEngine* converter = [[NSApp delegate] conversionEngine];
    if (converter.katakana == NO) {
        unichar firstChar = [string characterAtIndex:0];
        if ('A' <= firstChar && firstChar <= 'Z') {  // kludge!
            converter.katakana = YES;
        }
    }
    
    if ([self appendString:string sender:sender])
        return YES;
    
    DebugLog(@"buffer: %@,%@,%@", kanjiBuffer_, kanaBuffer_, romanBuffer_);
    BOOL isSymbol = [converter isSymbol:string];
    if (isSymbol) {
        DebugLog(@"flush: symbol");
        converter.katakana = NO;
        [self commitComposition:sender];
    } else {
        [self showPreedit:sender];
    }
    return YES;
}

-(void)commitComposition:(id)sender {
    NSString* text = [self getPreedit];
    if ([text length]) {
        DebugLog(@"commit: \"%@\"", text);
        [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
        [romanBuffer_ setString:@""];
        [kanaBuffer_ setString:@""];
        [kanjiBuffer_ setString:@""];
    }
    [[NSApp delegate] conversionEngine].katakana = NO;
}

#pragma mark -

- (void)deleteBackward:(id)sender {
    if ([romanBuffer_ length] > 0) {
        [romanBuffer_ deleteCharactersInRange:NSMakeRange([romanBuffer_ length] - 1, 1)];
    } else if ([kanaBuffer_ length] > 0) {
        [kanaBuffer_ deleteCharactersInRange:NSMakeRange([kanaBuffer_ length] - 1, 1)];
    }
    DebugLog(@"r(%@) k(%@)", romanBuffer_, kanaBuffer_);
    if ([kanaBuffer_ length]) {
        ConversionEngine* converter = [[NSApp delegate] conversionEngine];
        NSArray* arr = [converter convertKanaToKanji:kanaBuffer_];
        [kanjiBuffer_ setString:[arr objectAtIndex:0]];
        if ([arr count] == 2) {
            [kanjiBuffer_ appendString:[arr objectAtIndex:1]];
        }
    } else {
        [kanjiBuffer_ setString:@""];
    }
    [self showPreedit:sender];
}

@end

@implementation HiraganyController (IMKInputController)

#pragma mark IMKInputController
- (NSMenu*)menu {
    NSMenu* m = [[[NSMenu alloc] initWithTitle:@"Hiragany"] autorelease];
    NSMenuItem* item = [m addItemWithTitle:[NSString stringWithUTF8String:"Kakamany Mode"]
                                    action:@selector(toggleKakamany:) keyEquivalent:@""];
    [item setState:(kakamanyMode_ ? NSOnState : NSOffState)];
    return m;
}

#pragma mark -

- (void)toggleKakamany:(id)sender {
    kakamanyMode_ = !kakamanyMode_;
    [[NSUserDefaults standardUserDefaults] setBool:kakamanyMode_ forKey:@"kakamany"];
}

-(NSString*)getPreedit {
    DebugLog(@"buffer: %@/%@/%@", romanBuffer_, kanaBuffer_, kanjiBuffer_);
    NSString* text = @"";
    if ([kanjiBuffer_ length]) {
        if ([romanBuffer_ length]) {
            text = [NSString stringWithFormat:@"%@%@", kanjiBuffer_, romanBuffer_];
        } else {
            text = kanjiBuffer_;
        }
    } else if ([kanaBuffer_ length]) {
        if ([romanBuffer_ length]) {
            text = [NSString stringWithFormat:@"%@%@", kanaBuffer_, romanBuffer_];
        } else {
            text = kanaBuffer_;
        }
    } else {
        text = romanBuffer_;
    }
    DebugLog(@"preedit: \"%@\"", text);
    return text;
}

-(void)showPreedit:(id)sender {
    NSString* text = [self getPreedit];
    DebugLog(@"preedit(%@) length(%d)", text, [text length]);
    
    NSInteger style = NSUnderlineStyleNone;
    NSDictionary* attr = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithInt:style], NSUnderlineStyleAttributeName, nil];
    NSMutableAttributedString* buf = [[NSAttributedString alloc] initWithString:text
                                                                     attributes:attr];
    [sender setMarkedText:buf
           selectionRange:NSMakeRange([text length], 0)
         replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    [buf release];
}

@end
