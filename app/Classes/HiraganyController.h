#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@interface HiraganyController : IMKInputController {
  NSMutableString* composedBuffer_;
  NSMutableString* originalBuffer_;
  NSInteger insertionIndex_;
}

-(NSMutableString*)composedBuffer;
-(void)setComposedBuffer:(NSString*)string;
-(NSMutableString*)originalBuffer;
-(void)setOriginalBuffer:(NSString*)string;
-(void)originalBufferAppend:(NSString*)string client:(id)sender;

- (BOOL)convert:(NSString*)trigger client:(id)sender;

@end
