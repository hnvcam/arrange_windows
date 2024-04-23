import Cocoa
import FlutterMacOS
import IOKit.ps
import window_manager

class MainFlutterWindow: NSWindow {
    var eventMonitor: Any?
    var currentWindow: Window?
    var capturing = false
    
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        // Native channel bridge
        let windowsChannel = FlutterMethodChannel(
            name: "com.tenolife.arrangeWindows/channel",
            binaryMessenger: flutterViewController.engine.binaryMessenger
        )
        
        // The rule here is
        // if the result is nil, then the action was unsuccessful
        windowsChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "currentWindow":
                self.getCurrentWindow(result)
                break
            case "allWindows":
                self.getAllWindows(result)
                break
            case "requestPermissions":
                self.requestPermissions(result);
                break
            case "startSelecting":
                self.capturing = true;
                print("Started selecting")
                result(true)
                break
            case "endSelecting":
                self.capturing = false;
                print("Ended selecting")
                result(true)
                break
            case "screenInfos":
                self.getScreenInfos(result)
                break
            case "setWindowFrame":
                self.setWindowFrame(call, result)
                break
            case "toggleFullscreen":
                self.toggleFullscreen(call, result)
                break
            case "refreshWindow":
                self.refreshWindow(call, result)
                break
            case "launchApp":
                self.launchApp(call, result)
                break
            case "closeAllWindows":
                self.closeAllWindows(call, result)
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        // End
        
        RegisterGeneratedPlugins(registry: flutterViewController)
        
        super.awakeFromNib()
        
        // Register for mouse event
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown], handler: self.handleMouseLeftClick)
        print("Monitor for mouse events")
    }
    
    override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
        super.order(place, relativeTo: otherWin)
        hiddenWindowAtLaunch()
    }
    
    override func handleClose(_ command: NSCloseCommand) -> Any? {
        
        if eventMonitor != nil {
            NSEvent.removeMonitor(eventMonitor!)
            print("Stop monitoring mouse events")
        }
        
        return super.handleClose(command)
    }
    
    private func handleMouseLeftClick(_ event: NSEvent) {
        if !capturing {
            return
        }
        
        currentWindow = MainFlutterWindow
            .all()
            .filter {$0.frame.contains(NSEvent.mouseLocation)}
            .first
    }
    
    private func checkPermissions() -> Bool {
        return AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary);
    }
    
    private func requestPermissions(_ result: @escaping FlutterResult) {
        if checkPermissions() {
            print("App is not authorized for accessibility. Requesting permission...")
            
            // Request permission by opening Security & Privacy preferences
            // NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            result(false)
        } else {
            print("App is already authorized for accessibility.")
            result(true)
        }
    }
    
    private func getCurrentWindow(_ result: @escaping FlutterResult) {
        if currentWindow != nil {
            print("Selected window: \(currentWindow!.applicationName) - \(currentWindow!.pID)")
            result(getWindowInfo(currentWindow!))
        } else {
            result(nil)
        }
    }
    
    private func getWindowInfo(_ window: Window) -> Dictionary<String, Any?> {
        var data = Dictionary<String, Any>()
        data["name"] = window.applicationName
        data["processId"] = window.pID
        data["windowNumber"] = window.windowNumber
        data["onScreen"] = window.onScreen
        data["x"] = window.frame.origin.x
        data["y"] = window.frame.origin.y
        data["width"] = window.frame.width
        data["height"] = window.frame.height
        data["alpha"] = window.alpha
        data["sharingState"] = window.sharingState
        data["layer"] = window.layer
        
        if let inst = NSRunningApplication(processIdentifier: window.pID) {
            //            print("\t Running Application with bundleIdentifier=\(String(describing: inst.bundleIdentifier)) bundleURL=\(String(describing: inst.bundleURL))")
            data["bundleIdentifier"] = inst.bundleIdentifier
            data["bundleURL"] = inst.bundleURL?.absoluteString
            data["hidden"] = inst.isHidden
            data["active"] = inst.isActive
            data["executableURL"] = inst.executableURL?.absoluteString
        }
        //        if (window.applicationName == "Xcode") {
        //            print(data);
        //        }
        return data
    }
    
    private func getScreenInfos(_ result: @escaping FlutterResult) {
        var data = Array<Dictionary<String, Any?>>()
        for screen in NSScreen.screens {
            var info = Dictionary<String, Any?>()
            info["name"] = screen.localizedName
            info["width"] = screen.frame.width
            info["height"] = screen.frame.height
            info["x"] = screen.frame.origin.x
            info["y"] = screen.frame.origin.y < 0 ? screen.frame.origin.y : NSScreen.screens[0].frame.maxY - screen.frame.maxY
            if #available(macOS 12.0, *) {
                info["safeTop"] = screen.safeAreaInsets.top
            } else {
                // Fallback on earlier versions
                info["safeTop"] = 0
            }
            if #available(macOS 12.0, *) {
                info["safeBottom"] = screen.safeAreaInsets.bottom
            } else {
                // Fallback on earlier versions
                info["safeBottom"] = 0
            }
            if #available(macOS 12.0, *) {
                info["safeLeft"] = screen.safeAreaInsets.left
            } else {
                // Fallback on earlier versions
                info["safeLeft"] = 0
            }
            if #available(macOS 12.0, *) {
                info["safeRight"] = screen.safeAreaInsets.right
            } else {
                // Fallback on earlier versions
                info["safeRight"] = 0
            }
            info["visibleX"] = screen.visibleFrame.origin.x
            // This is unable to understand, but this is how screenFlipped works, refer to Rectangle project
            info["visibleY"] = NSScreen.screens[0].frame.maxY - screen.visibleFrame.maxY
            info["visibleWidth"] = screen.visibleFrame.width
            info["visibleHeight"] = screen.visibleFrame.height
            data.append(info)
            //            print(info)
        }
        result(data)
    }
    
    private func setWindowFrame(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        let x = args["x"] as! Double
        let y = args["y"] as! Double
        let width = args["width"] as! Double
        let height = args["height"] as! Double
        if let accessibility = getAccessibility(call) {
            let window = accessibility.windowElements?.first ?? accessibility
            
            window.setFrame(CGRect(x: x, y: y, width: width, height: height))
            // because of animation when resizing, so the value here may not reflect the latest change
            let newFrame = window.frame
            var data = Dictionary<String, Any>()
            data["x"] = newFrame.origin.x
            data["y"] = newFrame.origin.y
            data["width"] = newFrame.width
            data["height"] = newFrame.height
            result(data)
            print("Application \(args["name"] ?? "Unknown") was set to \(newFrame)")
        } else {
            print("Unable to get accessibility element of \(args["name"] ?? "Unknown")")
            result(nil)
        }
    }
    
    private func getAccessibility(_ call: FlutterMethodCall) -> Accessibility? {
        if !checkPermissions() {
            return nil
        }
        
        let args = call.arguments as! Dictionary<String, Any>
        let processId = args["processId"] as! Int32?
        let bundleIdentifier = args["bundleIdentifier"] as! String?
        var accessibility: Accessibility?
        if processId != nil {
            accessibility = Accessibility(processId!)
        } else if bundleIdentifier != nil {
            accessibility = Accessibility(bundleIdentifier!)
        }
        return accessibility
    }
    
    // This does not work for some cases!!!
    //    private func setFullscreen(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    //        if let accessibility = getAccessibility(call) {
    //            let window = accessibility.windowElements?.first ?? accessibility
    //            result(window.setFullScreen())
    //        } else {
    //            result(nil)
    //        }
    //    }
    
    // we let the flutter to wait for new state of windows
    private func toggleFullscreen(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        let processId = args["processId"] as! Int32
        if let inst = NSRunningApplication(processIdentifier: processId) {
            if inst.activate(options: .activateIgnoringOtherApps) {
                let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 3, keyDown: true)!
                keyDown.flags = [.maskCommand, .maskControl]
                keyDown.post(tap: .cghidEventTap)
                
                let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 3, keyDown: false)!
                keyUp.flags = [.maskCommand, .maskControl]
                keyUp.post(tap: .cghidEventTap)
            } else {
                print("Unable to activate application \(String(describing: args["name"]))")
            }
        }
        result(true)
    }
    
    private func refreshWindow(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        let windowNumber = args["windowNumber"] as! Int?
        if let window = MainFlutterWindow.all().filter({ $0.windowNumber == windowNumber}).first {
            result(getWindowInfo(window))
        } else {
            result(nil)
        }
    }
    
    private func getAllWindows(_ result: @escaping FlutterResult) {
        result(MainFlutterWindow.all().map({
            getWindowInfo($0)
        }))
    }
    
    private func launchApp(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>
        if let bundleUrl = args["bundleURL"] as? String {
            let url = URL(string: bundleUrl)
            openApplication(url, result)
            print("Application \(args["name"] ?? "Unknown") opened by BundleURL")
        } else if let bundleIdentifier = args["bundleIdentifier"] as? String {
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
            openApplication(url, result)
            print("Application \(args["name"] ?? "Unknown") opened by BundleIdentifier")
        } else {
            result(nil)
        }
    }
    
    private func openApplication(_ url: URL?, _ result: @escaping FlutterResult) {
        if let url = url {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { runningApp, error in
                if error != nil || runningApp == nil {
                    result(nil)
                } else {
                    result(runningApp?.processIdentifier)
                }
            })
        } else {
            result(nil)
        }
    }
    
    private func closeAllWindows(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! Array<Int32>;
        for processId in args {
            if let app = NSRunningApplication(processIdentifier: processId) {
                app.terminate();
            }
        }
        result(true)
    }
    
    static func all() -> [Window] {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements)
        let windowsListInfo = CGWindowListCopyWindowInfo(options, CGMainDisplayID()) //current window
        let infoList = windowsListInfo as! [[String: Any]]
        //        print(infoList)
        return infoList
            .filter { $0["kCGWindowLayer"] as! Int == 0 }
            .map { Window(
                frame: CGRect(x: ($0["kCGWindowBounds"] as! [String: Any])["X"] as! CGFloat,
                              y: ($0["kCGWindowBounds"] as! [String: Any])["Y"] as! CGFloat,
                              width: ($0["kCGWindowBounds"] as! [String: Any])["Width"] as! CGFloat,
                              height: ($0["kCGWindowBounds"] as! [String: Any])["Height"] as! CGFloat),
                applicationName: $0["kCGWindowOwnerName"] as! String,
                windowNumber: $0["kCGWindowNumber"] as! Int,
                pID: $0["kCGWindowOwnerPID"] as! Int32,
                onScreen: $0["kCGWindowIsOnscreen"] as! Bool?,
                layer: $0["kCGWindowLayer"] as! Int,
                // https://developer.apple.com/documentation/coregraphics/quartz_window_services/window_sharing_constants
                sharingState: $0["kCGWindowSharingState"] as! Int,
                // https://developer.apple.com/documentation/coregraphics/kcgwindowalpha
                alpha: $0["kCGWindowAlpha"] as! CGFloat
            )}
    }
}

struct Window {
    var frame: CGRect
    var applicationName: String
    var windowNumber: Int
    var pID: Int32
    var onScreen: Bool?
    var layer: Int
    var sharingState: Int
    var alpha: CGFloat
}
