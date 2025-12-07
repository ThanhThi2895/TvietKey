#!/usr/bin/env swift
// Debug event tap creation
import Foundation
import Cocoa

print("=== Event Tap Debug ===\n")

// Check permissions
let trusted = AXIsProcessTrusted()
print("AXIsProcessTrusted: \(trusted)")

if !trusted {
    print("\nNOT TRUSTED - requesting permission...")
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    AXIsProcessTrustedWithOptions(options)
    print("Please grant permission and run again")
    exit(1)
}

print("\nTrying different event tap configurations...\n")

// Callback
func callback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, refcon: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == .keyDown {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        print("Key pressed: \(keyCode)")
    }
    return Unmanaged.passUnretained(event)
}

let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

// Test 1: cghidEventTap + defaultTap
print("1. cghidEventTap + defaultTap...")
var tap = CGEvent.tapCreate(
    tap: .cghidEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: eventMask,
    callback: callback,
    userInfo: nil
)
print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")

// Test 2: cghidEventTap + listenOnly
if tap == nil {
    print("2. cghidEventTap + listenOnly...")
    tap = CGEvent.tapCreate(
        tap: .cghidEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

// Test 3: cgSessionEventTap + defaultTap
if tap == nil {
    print("3. cgSessionEventTap + defaultTap...")
    tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

// Test 4: cgSessionEventTap + listenOnly
if tap == nil {
    print("4. cgSessionEventTap + listenOnly...")
    tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

// Test 5: cgAnnotatedSessionEventTap + defaultTap
if tap == nil {
    print("5. cgAnnotatedSessionEventTap + defaultTap...")
    tap = CGEvent.tapCreate(
        tap: .cgAnnotatedSessionEventTap,
        place: .headInsertEventTap,
        options: .defaultTap,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

// Test 6: cgAnnotatedSessionEventTap + listenOnly
if tap == nil {
    print("6. cgAnnotatedSessionEventTap + listenOnly...")
    tap = CGEvent.tapCreate(
        tap: .cgAnnotatedSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

// Test 7: tailAppendEventTap instead of headInsertEventTap
if tap == nil {
    print("7. cgSessionEventTap + tailAppendEventTap...")
    tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .tailAppendEventTap,
        options: .listenOnly,
        eventsOfInterest: eventMask,
        callback: callback,
        userInfo: nil
    )
    print("   Result: \(tap != nil ? "SUCCESS" : "FAILED")")
}

if let tap = tap {
    print("\n✅ Event tap created successfully!")
    print("Running for 10 seconds - press some keys to test...")

    let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
    CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)

    // Run for 10 seconds
    CFRunLoopRunInMode(.defaultMode, 10, false)

    print("\nTest complete!")
} else {
    print("\n❌ ALL methods failed!")
    print("\nPossible solutions:")
    print("1. Open System Settings > Privacy & Security > Input Monitoring")
    print("2. Remove this app/Terminal from the list")
    print("3. Re-add it")
    print("4. Log out and log back in (or restart)")
    print("5. Check if SIP is enabled: csrutil status")
}
