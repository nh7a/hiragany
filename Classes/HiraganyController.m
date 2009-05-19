#import "HiraganyController.h"
#import "ConversionEngine.h"
#import "HiraganyApplicationDelegate.h"


@implementation HiraganyController


-(BOOL)inputText:(NSString*)string client:(id)sender {
  NSScanner* scanner = [NSScanner scannerWithString:string];
  NSString* scanned;    
  if (![scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&scanned] &&
      ![scanner scanCharactersFromSet:[NSCharacterSet punctuationCharacterSet] intoString:&scanned]) {
    NSLog(@"flush: control char");
    [[NSApp delegate] conversionEngine].katakana = NO;

    [self commitComposition:sender];
    return NO;
  }

  unichar lastChar = [string characterAtIndex:[string length]-1];
  NSLog(@"inputText: [%@/%d] (%d)", string, [string length], lastChar);
  
  unichar firstChar = [string characterAtIndex:0];
  if ('A' <= firstChar && firstChar <= 'Z') {  // kludge!
    [[NSApp delegate] conversionEngine].katakana = YES;
  } else {
    [[NSApp delegate] conversionEngine].katakana = NO;
  }
  [self originalBufferAppend:string client:sender];
  BOOL handled = [self convert:string client:sender];
  return handled;
}

-(void)commitComposition:(id)sender {
  NSString* text = [self composedBuffer];
  
  if (text == nil || [text length] == 0) {
    text = [self originalBuffer];
  }

  [sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
  [self setComposedBuffer:@""];
  [self setOriginalBuffer:@""];
}

-(NSMutableString*)composedBuffer {
  if (composedBuffer_ == nil) {
    composedBuffer_ = [[NSMutableString alloc] init];
  }
  return composedBuffer_;
}

-(void)setComposedBuffer:(NSString*)string {
  NSMutableString* buffer = [self composedBuffer];
  [buffer setString:string];
}

-(NSMutableString*)originalBuffer {
  if (originalBuffer_ == nil) {
    originalBuffer_ = [[NSMutableString alloc] init];
  }
  return originalBuffer_;
}

-(void)originalBufferAppend:(NSString*)string client:(id)sender {
  NSMutableString* buffer = [self originalBuffer];
  [buffer appendString: string];
  [sender setMarkedText:buffer
         selectionRange:NSMakeRange(0, [buffer length])
       replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
}

-(void)setOriginalBuffer:(NSString*)string {
  NSMutableString* buffer = [self originalBuffer];
  [buffer setString:string];
}

-(BOOL)didCommandBySelector:(SEL)aSelector client:(id)sender {
  NSLog(@"didCommandBySelector: %s", sel_getName(aSelector));
  if ([self respondsToSelector:aSelector]) {
    NSString* bufferedText = [self originalBuffer];
    
    if (bufferedText && [bufferedText length] > 0) {
      if (aSelector == @selector(insertNewline:) || aSelector == @selector(deleteBackward:) ) {
        [self performSelector:aSelector withObject:sender];
        return YES; 
      }
    }
  }
  return NO;
}

- (void)insertNewline:(id)sender {
  [self commitComposition:sender];
  [[NSApp delegate] conversionEngine].katakana = NO;
  NSLog(@"insertNewline!");
}

- (void)deleteBackward:(id)sender {
  NSMutableString* originalText = [self originalBuffer];
  
  if ([originalText length] > 0) {
    [originalText deleteCharactersInRange:NSMakeRange([originalText length] - 1, 1)];
    [sender setMarkedText:originalText
           selectionRange:NSMakeRange(0, [originalText length])
         replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
  }
}

- (BOOL)convert:(NSString*)trigger client:(id)sender {
  NSString* originalText = [self originalBuffer];
  if (!originalText || [originalText length] == 0) {
    return NO;
  }
  
  NSLog(@"convert: trigger[%@] [%@]", trigger, originalText);
  NSArray* arr = [[[NSApp delegate] conversionEngine] convert:originalText];
  if (!arr) {
    NSLog(@"flush: unknown combination");
    [self commitComposition:sender];
  } else if ([arr count] > 0) {
    NSString* convertedString;
    convertedString = [arr objectAtIndex:0];
    if ([convertedString length] > 0) {
      NSLog(@"converted: [%@] -> [%@]", originalText, convertedString);
      [self setComposedBuffer:convertedString];
      [self commitComposition:sender];
      
      if ([arr count] == 2) {
        [self originalBufferAppend:[arr objectAtIndex:1] client:sender];
      }
    }
  }
  return YES;
}

-(NSMenu*)menu {
  return nil;
//  return [[NSApp delegate] menu];
}

-(void)dealloc {
  [composedBuffer_ release];
  [originalBuffer_ release];
  [super dealloc];
}
 
@end
