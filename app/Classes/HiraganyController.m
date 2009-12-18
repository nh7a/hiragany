#import "HiraganyGlobal.h"
#import "HiraganyController.h"
#import "ConversionEngine.h"
#import "HiraganyApplicationDelegate.h"

#define IMPL_METHOD 2

@interface HiraganyController(Private)
- (NSString*)getMarkedText;
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

#if (IMPL_METHOD == 1)
- (BOOL)inputText:(NSString*)string client:(id)sender {
    return [self inputText:string key:0 modifiers:0 client:sender];
}

-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
    DebugLog(@"didCommandBySelector: %s", sel_getName(aSelector));
    if ([self respondsToSelector:aSelector]) {
        if ([[self getMarkedText] length] > 0) {
            if (aSelector == @selector(insertNewline:) ||
                aSelector == @selector(insertTab:) ||
                aSelector == @selector(deleteBackward:) ) {
                [self performSelector:aSelector withObject:sender];
                return YES; 
            }
        }
    }
    return NO;
}
#endif

#if (IMPL_METHOD == 1 || IMPL_METHOD == 2)
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
            case 0x33:  // delete key
                [self deleteBackward:sender];
                return YES;
            case 0x24:  // enter key
                if (![romanBuffer_ length] && ![kanaBuffer_ length]) {
                    return NO;
                }
                [self commitComposition:sender];
                [sender insertText:@"\n" replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
                break;
            case 0x31:  // space
                [self appendString:@" " sender:sender];
                [self commitComposition:sender];
                return YES;
                break;
            default:
                DebugLog(@"flush: control char: %X %X", keyCode, flags);
                [self commitComposition:sender];
                break;
        }
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
        NSString* text = [self getMarkedText];
        [sender setMarkedText:text
               selectionRange:NSMakeRange(0, [text length])
             replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
    }
    return YES;
}
#endif

#if (IMPL_METHOD == 3)
- (BOOL)handleEvent:(NSEvent*)event client:(id)sender {
    DebugLog(@"handleEvent: %@", event);
    return YES;
}
#endif

-(void)commitComposition:(id)sender {
    NSString* text = [self getMarkedText];
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

- (void)insertNewline:(id)sender {
    [self commitComposition:sender];
    [[NSApp delegate] conversionEngine].katakana = NO;
}

- (void)insertTab:(id)sender {
    [self commitComposition:sender];
    [[NSApp delegate] conversionEngine].katakana = NO;
}

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
    NSString* text = [self getMarkedText];
    [sender setMarkedText:text
           selectionRange:NSMakeRange(0, [text length])
         replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
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

-(NSString*)getMarkedText {
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
    DebugLog(@"marked: \"%@\"", text);
    return text;
}

@end
