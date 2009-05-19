#import <Cocoa/Cocoa.h>

@interface ConversionEngine : NSObject {
  BOOL katakana;
  NSDictionary* romakanaDic_;
}

@property (nonatomic) BOOL katakana;

-(NSArray*)convert:(NSString*)string;

@end
