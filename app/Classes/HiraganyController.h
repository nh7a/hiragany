#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

@interface HiraganyController : IMKInputController {
    NSMutableString* romanBuffer_;
    NSMutableString* kanaBuffer_;
    NSMutableString* kanjiBuffer_;
    BOOL kakamanyMode_;
}

@end
