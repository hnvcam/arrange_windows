//
//  Accessibility.swift
//  Runner
//
//  Created by Cam Hoang on 10/04/2024.
//
import Cocoa
import Foundation

class Accessibility {
    let wrappedElement: AXUIElement

    init(_ element: AXUIElement) {
        wrappedElement = element
    }
    
    convenience init(_ pid: pid_t) {
        self.init(AXUIElementCreateApplication(pid))
    }
    
    convenience init?(_ bundleIdentifier: String) {
        guard let app = (NSWorkspace.shared.runningApplications.first { $0.bundleIdentifier == bundleIdentifier }) else { return nil }
        self.init(app.processIdentifier)
    }
    
    private var role: NSAccessibility.Role? {
        guard let value = wrappedElement.getValue(NSAccessibility.Attribute.role) as? String else { return nil }
        return NSAccessibility.Role(rawValue: value)
    }
    
    private var isApplication: Bool? {
        guard let role = role else { return nil }
        return role == .application
    }
    
    var isWindow: Bool? {
        guard let role = role else { return nil }
        return role == .window
    }
    
    var isSheet: Bool? {
        guard let role = role else { return nil }
        return role == .sheet
    }
    
    var isToolbar: Bool? {
        guard let role = role else { return nil }
        return role == .toolbar
    }
    
    var isGroup: Bool? {
        guard let role = role else { return nil }
        return role == .group
    }
    
    var isStaticText: Bool? {
        guard let role = role else { return nil }
        return role == .staticText
    }
    
    var windowElement: Accessibility? {
        if isWindow == true { return self }
        return getElementValue(.window)
    }
    
    private var subrole: NSAccessibility.Subrole? {
        guard let value = wrappedElement.getValue(.subrole) as? String else { return nil }
        return NSAccessibility.Subrole(rawValue: value)
    }
    
    var isFullScreen: Bool? {
        get {
            guard let subrole = windowElement?.getElementValue(NSAccessibility.Attribute.fullScreenButton)?.subrole else { return nil }
            return subrole == NSAccessibility.Subrole.zoomButton
        }
    }
    
    private var position: CGPoint? {
        get {
            wrappedElement.getWrappedValue(.position)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.position, newValue)
//            print("AX position proposed: \(newValue.debugDescription), result: \(position?.debugDescription ?? "N/A")")
        }
    }
    
    var size: CGSize? {
        get {
            wrappedElement.getWrappedValue(.size)
        }
        set {
            guard let newValue = newValue else { return }
            wrappedElement.setValue(.size, newValue)
//            print("AX sizing proposed: \(newValue.debugDescription), result: \(size?.debugDescription ?? "N/A")")
        }
    }
    
    var frame: CGRect {
        guard let position = position, let size = size else { return .null }
        return .init(origin: position, size: size)
    }
    
    /// The Accessebility API only allows size & position adjustments individually.
    /// To handle moving to different displays, we have to adjust the size then the position, then the size again since macOS will enforce sizes that fit on the current display.
    /// When windows take a long time to adjust size & position, there is some visual stutter with doing each of these actions. The stutter can be slightly reduced by removing the initial size adjustment, which can make unsnap restore appear smoother.
    func setFrame(_ frame: CGRect, adjustSizeFirst: Bool = true) {
        let appElement = applicationElement
        var enhancedUI: Bool? = nil

        if let appElement = appElement {
            enhancedUI = appElement.enhancedUserInterface
            if enhancedUI == true {
                print("AXEnhancedUserInterface was enabled, will disable before resizing")
                appElement.enhancedUserInterface = false
            }
        }

        if adjustSizeFirst {
            size = frame.size
        }
        position = frame.origin
        size = frame.size

        // If "enhanced user interface" was originally enabled for the app, turn it back on
        if let appElement = appElement, enhancedUI == true {
            appElement.enhancedUserInterface = true
        }
    }
    
    func setFullScreen() -> Bool? {
        if let buttonRef = wrappedElement.getValue(NSAccessibility.Attribute.fullScreenButton) {
            AXUIElementPerformAction(buttonRef as! AXUIElement, kAXPressAction as CFString)
            return isFullScreen
        }
        print("No fullscreen button for app \(String(describing: wrappedElement.getValue(.title)))")
        return nil
    }
    
    var pid: pid_t? {
        wrappedElement.getPid()
    }
    
    private var applicationElement: Accessibility? {
        if isApplication == true { return self }
        guard let pid = pid else { return nil }
        return Accessibility(pid)
    }
    
    private var focusedWindowElement: Accessibility? {
        applicationElement?.getElementValue(.focusedWindow)
    }
    
    var windowElements: [Accessibility]? {
        applicationElement?.getElementsValue(.windows)
    }
    
    private func getElementsValue(_ attribute: NSAccessibility.Attribute) -> [Accessibility]? {
        guard let value = wrappedElement.getValue(attribute), let array = value as? [AXUIElement] else { return nil }
        return array.map { Accessibility($0) }
    }
    
    private func getElementValue(_ attribute: NSAccessibility.Attribute) -> Accessibility? {
        guard let value = wrappedElement.getValue(attribute), CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return Accessibility(value as! AXUIElement)
    }
    
    var enhancedUserInterface: Bool? {
        get {
            applicationElement?.wrappedElement.getValue(.enhancedUserInterface) as? Bool
        }
        set {
            guard let newValue = newValue else { return }
            applicationElement?.wrappedElement.setValue(.enhancedUserInterface, newValue)
        }
    }
}


enum EnhancedUI: Int {
    case disableEnable = 1 /// The default behavior - disable Enhanced UI on every window move/resize
    case disableOnly = 2 /// Don't re-enable enhanced UI after it gets disabled
    case frontmostDisable = 3 /// Disable enhanced UI every time the frontmost app gets changed
}
