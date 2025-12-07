import Foundation
import Cocoa

print("=== TestEventTap App ===")

// Check permissions
let trusted = AXIsProcessTrusted()
print("AXIsProcessTrusted: \(trusted)")

if !trusted {
    print("Requesting permission...")
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
}

// Callback
func callback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        print("KEY: \(keyCode)")
    }
    return Unmanaged.passUnretained(event)
}

// Try to create event tap
let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

print("Creating event tap...")

if let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: callback,
    userInfo: nil
) {
    print("✅ Event tap created!")

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    print("Listening for 30 seconds...")
    CFRunLoopRunInMode(.defaultMode, 30, false)
} else {
    print("❌ Event tap FAILED!")
    print("Please add this app to Input Monitoring in System Settings")
}
