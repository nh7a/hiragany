#import "HiraganyGlobal.h"
#import "ConversionEngine.h"

#define kMaxParticleLength 2

@interface ConversionEngine(Private)
-(id)loadPlist:(NSString*)name;
-(void)testRomanToKana;
-(void)testConvert;
@end

@implementation ConversionEngine

@synthesize katakana = katakana_;

-(void)awakeFromNib {
    katakana_ = NO;
    NSLog(@"Initializing Hiragany...");
    romakanaDic_  = [[self loadPlist:@"RomaKana"] retain];
    kanakanjiDic_ = [[self loadPlist:@"KanaKanji"] retain];
    symbolDic_    = [[self loadPlist:@"Symbols"] retain];
    particleDic_  = [[self loadPlist:@"Particles"] retain];

#ifdef DEBUG
    [self testRomanToKana];
    [self testConvert];
#endif
}

-(void)dealloc {
    [romakanaDic_ release];
    [kanakanjiDic_ release];
    [symbolDic_ release];
    [particleDic_ release];
    [super dealloc];
}

-(NSArray*)convertRomanToKana:(NSString*)string {
    if (!romakanaDic_) return [NSArray arrayWithObjects:@"", string, nil];
    
    NSMutableString* buf1 = [[NSMutableString new] autorelease];
    NSMutableString* buf2 = [[NSMutableString new] autorelease];
    NSMutableString* buf = buf1;
    NSRange range;
    range.location = 0;
    range.length = 0;
    
    NSString* key = katakana_ ? [string uppercaseString] : [string lowercaseString];
    while (range.location + range.length < [key length]) {
        range.length += 1;
        NSString* k = [key substringWithRange:range];
        NSString* converted = [romakanaDic_ objectForKey:k];
        if (converted) {
            if ([self isSymbol:k]) {
                [buf2 appendString:converted];
                return [NSArray arrayWithObjects:buf1, buf2, nil];
            }
        } else {
            if ([k length] == 1 ||
                [romakanaDic_ objectForKey:[NSString stringWithFormat:@"%@%@", k, katakana_ ? @"A" : @"a"]] ||
                [romakanaDic_ objectForKey:[NSString stringWithFormat:@"%@%@", k, katakana_ ? @"U" : @"u"]]) {
                continue;  // The next letter may solve.
            }
            unichar firstChar = [k characterAtIndex:0];
            if (firstChar == 'n') {  // n is special
                converted = @"ん";
            } else if (firstChar == 'N') {  // N is awesome
                converted = @"ン";
            } else {
                if (firstChar == [k characterAtIndex:1]) {
                    converted = katakana_ ? @"ッ" : @"っ";
                } else {
                    converted = [NSString stringWithCharacters:&firstChar length:1];
                    buf = buf2;  // Switch the target buffer
                }
            }
            range.length = 1;  // Advance one letter
        }
        [buf appendString:converted];
        range.location += range.length;
        range.length = 0;        
    }
    
    if (range.length) {
        [buf2 appendString:[key substringWithRange:range]];
    }
    if ([buf2 length] > 0) {
        return [NSArray arrayWithObjects:buf1, buf2, nil];
    } else {
        return [NSArray arrayWithObjects:buf1, nil];
    }
}

-(NSArray*)convertKanaToKanji:(NSString*)string {
    if (!kanakanjiDic_) return [NSArray arrayWithObjects:@"", string, nil];
    
    NSString* converted = [kanakanjiDic_ objectForKey:string];
    if (converted) {
        return [NSArray arrayWithObject:converted];
    }
    for (int i = 1; i <= kMaxParticleLength; i++) {
        NSInteger len = [string length] - i;
        if (len <= 0) break;
        NSString* particle = [string substringFromIndex:len];
        if ([particleDic_ objectForKey:particle]) {
            converted = [kanakanjiDic_ objectForKey:[string substringToIndex:len]];
            if (converted) {
                return [NSArray arrayWithObjects:converted, particle, nil];
            }
        }
    }
    return [NSArray arrayWithObjects:@"", string, nil];
}

-(NSString*)convertHiraToKata:(NSString*)string {
    CFMutableStringRef buf = CFStringCreateMutableCopy(kCFAllocatorDefault, 0, (CFStringRef)string);
    CFRange range = CFRangeMake(0, [string length]);
    CFStringTransform(buf, &range, kCFStringTransformHiraganaKatakana, NO);
    NSString *result = (NSString*)buf;
    [result autorelease];
    return result;
}

-(NSArray*)convert:(NSString*)string {
    NSArray* results;
    NSArray* kana = [self convertRomanToKana:string];
    NSArray* converted = [self convertKanaToKanji:[kana objectAtIndex:0]];
    if ([kana count] == 1) {
        results = converted;
    } else {
        if ([converted count] == 1) {
            results = [NSArray arrayWithObjects:[converted objectAtIndex:0], [kana objectAtIndex:1], nil];
        } else {
            results = [NSArray arrayWithObjects:[converted objectAtIndex:0],
                       [NSString stringWithFormat:@"%@%@", [converted objectAtIndex:1], [kana objectAtIndex:1]], nil];
        }
    }
    if (verbosity_) {
        if ([kana count] == 1) {
            if ([results count] == 1)
                NSLog(@"convert1: %@ -> %@ -> %@", string,
                      [kana objectAtIndex:0], [results objectAtIndex:0]);
            else
                NSLog(@"convert2: %@ -> %@ -> %@/%@",
                      string, [kana objectAtIndex:0], [results objectAtIndex:0], [results objectAtIndex:1]);
        } else {
            if ([results count] == 1)
                NSLog(@"convert3: %@ -> %@/%@ -> %@", string,
                      [kana objectAtIndex:0], [kana objectAtIndex:1], [results objectAtIndex:0]);
            else
                NSLog(@"convert4: %@ -> %@/%@ -> %@/%@",
                      string, [kana objectAtIndex:0], [kana objectAtIndex:1], [results objectAtIndex:0], [results objectAtIndex:1]);
        }
    }
    return results;
}

-(BOOL)isSymbol:(NSString*)string {
    return [symbolDic_ objectForKey:string] ? YES : NO;
}

# pragma mark -

-(id)loadPlist:(NSString*)name {
    NSError* error = nil;
    NSPropertyListFormat format;
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    id plist = [NSPropertyListSerialization propertyListWithData:plistXML
                                                         options:NSPropertyListMutableContainersAndLeaves
                                                          format:&format
                                                           error:&error];

    if (!plist) {
        [errorDesc release];
        NSLog(@"%@", error);
    }
    return plist;
}

#define TEST_CONVERTER(sel,a,b,c,d) {\
    NSArray* arr = [self sel:a];\
    assert([arr count]==b);\
    assert([[arr objectAtIndex:0] isEqualToString:c]);\
    if (b==2) {\
        assert([[arr objectAtIndex:1] isEqualToString:d]);\
        NSLog(@"OK: %@ -> %@ %@", a,c,d);\
    } else {\
        NSLog(@"OK: %@ -> %@",a,c);\
    }\
}

-(void)testRomanToKana {
    TEST_CONVERTER(convertRomanToKana, @"a", 1, @"あ", @"");
    TEST_CONVERTER(convertRomanToKana, @"d", 2, @"", @"d");
    TEST_CONVERTER(convertRomanToKana, @"da", 1, @"だ", @"");
    TEST_CONVERTER(convertRomanToKana, @"dag", 2, @"だ", @"g");
    TEST_CONVERTER(convertRomanToKana, @"gy", 2, @"", @"gy");
    TEST_CONVERTER(convertRomanToKana, @"gya", 1, @"ぎゃ", @"");
    TEST_CONVERTER(convertRomanToKana, @"kk", 2, @"っ", @"k");
    TEST_CONVERTER(convertRomanToKana, @"batta", 1, @"ばった", @"");
    TEST_CONVERTER(convertRomanToKana, @"gakki", 1, @"がっき", @"");
    TEST_CONVERTER(convertRomanToKana, @"up", 2, @"う", @"p");
    TEST_CONVERTER(convertRomanToKana, @"upd", 2, @"う", @"pd");
    TEST_CONVERTER(convertRomanToKana, @"upde", 2, @"う", @"pで");
    TEST_CONVERTER(convertRomanToKana, @"upde-", 2, @"う", @"pでー");
    TEST_CONVERTER(convertRomanToKana, @"upde-t", 2, @"う", @"pでーt");
    TEST_CONVERTER(convertRomanToKana, @"upde-ta", 2, @"う", @"pでーた");
    TEST_CONVERTER(convertRomanToKana, @"upde-tann", 2, @"う", @"pでーたん");
    TEST_CONVERTER(convertRomanToKana, @"n", 2, @"", @"n");
    TEST_CONVERTER(convertRomanToKana, @"nn", 1, @"ん", @"");
    TEST_CONVERTER(convertRomanToKana, @"ng", 2, @"ん", @"g");
    TEST_CONVERTER(convertRomanToKana, @"nga", 1, @"んが", @"");
    TEST_CONVERTER(convertRomanToKana, @"ny", 2, @"", @"ny");
    TEST_CONVERTER(convertRomanToKana, @"nya", 1, @"にゃ", @"");
    TEST_CONVERTER(convertRomanToKana, @"nky", 2, @"ん", @"ky");
    TEST_CONVERTER(convertRomanToKana, @"nkyo", 1, @"んきょ", @"");
    TEST_CONVERTER(convertRomanToKana, @"nyg", 2, @"ん", @"yg");
    TEST_CONVERTER(convertRomanToKana, @"npde", 2, @"ん", @"pで");
    TEST_CONVERTER(convertRomanToKana, @"runrun", 2, @"るんる", @"n");
    TEST_CONVERTER(convertRomanToKana, @"runrun ", 2, @"るんるん", @" ");
    TEST_CONVERTER(convertRomanToKana, @"runrun.", 2, @"るんるん", @"。");
    TEST_CONVERTER(convertRomanToKana, @"runnrun", 2, @"るんる", @"n");
    TEST_CONVERTER(convertRomanToKana, @"runnrunn", 1, @"るんるん", @"");
    TEST_CONVERTER(convertRomanToKana, @"n!", 2, @"ん", @"！");
    TEST_CONVERTER(convertRomanToKana, @"ny!", 2, @"ん", @"y！");
    TEST_CONVERTER(convertRomanToKana, @"nya!u", 2, @"にゃ", @"！");
    TEST_CONVERTER(convertRomanToKana, @"xwa", 1, @"ゎ", @"");
    TEST_CONVERTER(convertRomanToKana, @"xtu", 1, @"っ", @"");
    NSLog(@"convertRomanToKana: done");
}

-(void)testConvert {
    TEST_CONVERTER(convert, @"j", 2, @"", @"j");
    TEST_CONVERTER(convert, @"ji", 2, @"", @"じ");
    TEST_CONVERTER(convert, @"jik", 2, @"", @"じk");
    TEST_CONVERTER(convert, @"jikk", 2, @"", @"じっk");
    TEST_CONVERTER(convert, @"jikky", 2, @"", @"じっky");
    TEST_CONVERTER(convert, @"jikkyo", 2, @"", @"じっきょ");
    TEST_CONVERTER(convert, @"jikkyou", 1, @"実況", @"");
    TEST_CONVERTER(convert, @"jikkyout", 2, @"実況", @"t");
    TEST_CONVERTER(convert, @"jikkyouto", 2, @"実況", @"と");
    TEST_CONVERTER(convert, @"jikkyoutoh", 2, @"実況", @"とh");
    TEST_CONVERTER(convert, @"jikkyoutoha", 2, @"実況", @"とは");
    TEST_CONVERTER(convert, @"shindan", 2, @"", @"しんだn");
    TEST_CONVERTER(convert, @"shindans", 2, @"診断", @"s");
    TEST_CONVERTER(convert, @"shindansh", 2, @"診断", @"sh");
//    TEST_CONVERTER(convert, @"shindansho", 1, @"診断書", nil);
    TEST_CONVERTER(convert, @"w", 2, @"", @"w");
    TEST_CONVERTER(convert, @"ww", 2, @"", @"っw");
    TEST_CONVERTER(convert, @"www", 2, @"", @"っっw");
    NSLog(@"convert: done");
}

@end
