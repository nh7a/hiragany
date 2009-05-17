#import <Cocoa/Cocoa.h>
#import "ConversionEngine.h"

@interface HiraganyApplicationDelegate : NSObject {
  IBOutlet ConversionEngine* conversionEngine_;
}

-(ConversionEngine*)conversionEngine;

@end
