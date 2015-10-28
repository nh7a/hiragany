#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>

//Each input method needs a unique connection name. 
//Note that periods and spaces are not allowed in the connection name.
const NSString* kConnectionName = @"Hiragany_Connection";

//let this be a global so our application controller delegate can access it easily
IMKServer*       server;

int main(int argc, const char * argv[])
{
    server = [[IMKServer alloc] initWithName:(NSString*)kConnectionName bundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
    return NSApplicationMain(argc, argv);
}
