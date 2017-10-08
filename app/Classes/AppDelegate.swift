import Cocoa
import InputMethodKit

private var server: IMKServer?

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        server = IMKServer(name: "Hiragany_Connection", bundleIdentifier: Bundle.main.bundleIdentifier)
        NSLog("Hiragany got launched.")
    }    
}
