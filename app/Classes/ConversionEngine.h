#import <Cocoa/Cocoa.h>

@interface ConversionEngine : NSObject {
    BOOL katakana_;
    NSDictionary* romakanaDic_;
    NSDictionary* kanakanjiDic_;
    NSDictionary* symbolDic_;
    NSDictionary* particleDic_;
    int verbosity_;
}

@property (nonatomic) BOOL katakana;

-(NSArray*)convert:(NSString*)string;
-(NSArray*)convertRomanToKana:(NSString*)string;
-(NSArray*)convertKanaToKanji:(NSString*)string;
-(NSString*)convertHiraToKata:(NSString*)string;
-(BOOL)isSymbol:(NSString*)string;

@end
