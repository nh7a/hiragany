#import "HiraganyGlobal.h"
#import "ConversionEngine.h"

@interface ConversionEngine(Private)
-(id)loadPlist:(NSString*)name;
-(void)testForDebug;
@end

@implementation ConversionEngine

@synthesize katakana = katakana_;

-(void)awakeFromNib {
    katakana_ = NO;
    romakanaDic_ = [self loadPlist:@"RomaKana"];
    kanakanjiDic_ = [self loadPlist:@"KanaKanji"];
    symbolDic_ = [self loadPlist:@"Symbol"];
    particles_ = [[NSArray arrayWithObjects:@"は", @"が", @"で", @"の", @"を", @"に", @"な", @"へ", @"と", @"とは", @"では", @"には", @"へは", nil] retain];
#ifdef DEBUG
    [self testForDebug];
#endif
}

-(void)dealloc {
    [romakanaDic_ release];
    [kanakanjiDic_ release];
    [symbolDic_ release];
    [particles_ release];
    [super dealloc];
}

-(NSArray*)convertRomanToKana:(NSString*)string {
    if (!romakanaDic_) return [NSArray arrayWithObjects:@"", string, nil];
    
    NSMutableString* buf = [[NSMutableString new] autorelease];
    NSRange range;
    range.location = 0;
    range.length = 0;
    
    NSString* key = katakana_ ? [string uppercaseString] : [string lowercaseString];
    for (int i = 0; i < [key length]; i++) {
        range.length += 1;
        NSString* k = [key substringWithRange: range];
        NSString* converted = [romakanaDic_ objectForKey:k];
        if (converted) {
            DebugLog(@"conversion: %@", converted);
            if ([self isSymbol:k]) {
                return [NSArray arrayWithObjects:buf, converted, nil];
            }                
            range.location += range.length;
            range.length = 0;
            [buf appendString:converted];
        } else if ([k length] > 1) {
            unichar firstChar = [k characterAtIndex:0];
            unichar secondChar = [k characterAtIndex:1];
            if (firstChar == secondChar) {
                [buf appendString:(katakana_ ? @"ッ" : @"っ")];
                range.location++;
                range.length--;
                continue;
            }
            if (firstChar == 'n') {  // n is special
                NSString* n = [romakanaDic_ objectForKey:[NSString stringWithFormat:@"%@a", k]];
                if (!n) {
                    [buf appendString:@"ん"];
                    range.location++;
                    range.length--;
                }
            } else if (firstChar == 'N') {  // N is awesome
                NSString* n = [romakanaDic_ objectForKey:[NSString stringWithFormat:@"%@A", k]];
                if (!n) {
                    [buf appendString:@"ン"];
                    range.location++;
                    range.length--;
                }
            }
            NSString* symbol = [NSString stringWithCharacters:&secondChar length:1];
            if ([self isSymbol:symbol]) {
                if (firstChar != 'n' && firstChar != 'N') {
                    [buf appendString:[NSString stringWithCharacters:&firstChar length:1]];
                    range.location++;
                }
                NSString* converted = [romakanaDic_ objectForKey:symbol];
                return [NSArray arrayWithObjects:buf, converted, nil];
            }
        }
    }
    
    if (range.length) {
        return [NSArray arrayWithObjects:buf, [key substringWithRange:range], nil];
    }
    return [NSArray arrayWithObjects:buf, nil];
}

-(NSArray*)convertKanaToKanji:(NSString*)string {
    if (!kanakanjiDic_) return [NSArray arrayWithObjects:@"", string, nil];
    
    NSString* converted = [kanakanjiDic_ objectForKey:string];
    if (converted) {
        return [NSArray arrayWithObject:converted];
    }
    for (NSString* particle in particles_) {
        NSUInteger len = [string length] - [particle length];
        if (len > 0) {
            if ([string hasSuffix:particle]) {
                converted = [kanakanjiDic_ objectForKey:[string substringToIndex:len]];
                if (converted) {
                    return [NSArray arrayWithObjects:converted, particle, nil];
                }
            }
        }
    }
    return [NSArray arrayWithObjects:@"", string, nil];
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
                NSLog(@"convert: %@ -> %@ -> %@", string,
                      [kana objectAtIndex:0], [results objectAtIndex:0]);
            else
                NSLog(@"convert: %@ -> %@ -> %@/%@",
                      string, [kana objectAtIndex:0], [results objectAtIndex:0], [results objectAtIndex:1]);
        } else {
            if ([results count] == 1)
                NSLog(@"convert: %@ -> %@/%@ -> %@", string,
                      [kana objectAtIndex:0], [kana objectAtIndex:1], [results objectAtIndex:0]);
            else
                NSLog(@"convert: %@ -> %@/%@ -> %@/%@",
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
    NSString* errorDesc = nil;
    NSPropertyListFormat format;
    NSString* plistPath = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
    NSData* plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    id plist = [NSPropertyListSerialization propertyListFromData:plistXML
                                                mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                          format:&format
                                                errorDescription:&errorDesc];    
    if (plist) {
        NSLog(@"Plist has been loaded: %@", name);
        [plist retain];
    } else {
        NSLog(errorDesc);
        [errorDesc release];
    }
    return plist;
}

-(void)testForDebug {
    verbosity_ = 9;
    [self convert:@"a"];
    [self convert:@"kyaku"];
    [self convert:@"gashisuru"];
    [self convert:@"kyouto"];
    [self convert:@"kenkou"];
    [self convert:@"kennkou"];
    [self convert:@"gassyuku"];
    [self convert:@"dattai"];
    [self convert:@"gakkari"];
    [self convert:@"keppaku"];
    [self convert:@"utsurundesu"];
    [self convert:@"aima"];
    [self convert:@"aimai"];
    [self convert:@"aikagi"];
    [self convert:@"aikagiw"];
    [self convert:@"aikagiwo"];
    [self convert:@"aikagih"];
    [self convert:@"aikagiha"];
    [self convert:@"runrun"];
    [self convert:@"runrun "];
    [self convert:@"runnrun"];
    [self convert:@"gunkan"];
    [self convert:@"gunkan."];
    [self convert:@"gunkann"];
    [self convert:@"gunkann."];
    [self convert:@"w."];
    [self convert:@"ww."];
    [self convert:@"www."];
    verbosity_ = 0;
}

@end
