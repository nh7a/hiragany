#import "ConversionEngine.h"

@implementation ConversionEngine

@synthesize katakana;

-(void)awakeFromNib {
  katakana = NO;
  NSString *errorDesc = nil;
  NSPropertyListFormat format;
  NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"RomaKana" ofType:@"plist"];
  NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
  romakanaDic_ = (NSDictionary*)[NSPropertyListSerialization propertyListFromData:plistXML
                                                  mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                            format:&format
                                                  errorDescription:&errorDesc];
  if (!romakanaDic_) {
    NSLog(errorDesc);
    [errorDesc release];
  } else {
    NSLog(@"Kana Dictionary has been loaded");
    [romakanaDic_ retain];
  }
}

-(NSArray*)convert:(NSString*)string {
  if (!romakanaDic_) return nil;
  
  NSString* key = katakana ? [string uppercaseString] : [string lowercaseString];
  NSString* converted = [romakanaDic_ objectForKey:key];
  
  NSArray* result = nil;
  if (converted) {
    result = [NSArray arrayWithObjects:converted, nil];
  } else if ([string length] > 1) {
    unichar firstChar = [string characterAtIndex:0];
    unichar secondChar = [string characterAtIndex:1];
    if (firstChar == 'n') {  // n is special
      NSArray* arr = [self convert:[string substringFromIndex:1]];
      if (arr && [arr count] > 0 && [[arr objectAtIndex:0] length] > 0) {
        result = [NSArray arrayWithObjects:[NSString stringWithFormat:@"ん%@", [arr objectAtIndex:0]], nil];
      } else {
        result = [NSArray arrayWithObjects:@"ん", [string substringFromIndex:1], nil];
      }
    } else if (firstChar == 'N') {  // N is awesome
      NSArray* arr = [self convert:[string substringFromIndex:1]];
      if (arr && [arr count] > 0 && [[arr objectAtIndex:0] length] > 0) {
        result = [NSArray arrayWithObjects:[NSString stringWithFormat:@"ン%@", [arr objectAtIndex:0]], nil];
      } else {
        result = [NSArray arrayWithObjects:@"ン", [string substringFromIndex:1], nil];
      }
    } else if (firstChar == secondChar) {
      result = [NSArray arrayWithObjects:(katakana ? @"ッ" : @"っ"), [string substringFromIndex:1], nil];
    }
  }

  return result;
}

@end
