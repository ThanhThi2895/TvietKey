#!/usr/bin/env swift
// Debug test for GoNhanh keyboard hook

import Foundation
import Carbon
import Cocoa

// Test 1: Check if we can create event tap
print("=== GoNhanh Debug Test ===\n")

print("1. Testing CGEvent.tapCreate...")
let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.tapDisabledByTimeout.rawValue)

let tap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: { proxy, type, event, refcon in
        print("   Callback received: type=\(type.rawValue)")
        return Unmanaged.passUnretained(event)
    },
    userInfo: nil
)

if tap == nil {
    print("   FAILED: Cannot create event tap!")
    print("   -> Check System Settings > Privacy & Security > Accessibility")
    print("   -> Make sure Terminal (or the app) has permission")
    exit(1)
} else {
    print("   OK: Event tap created successfully")
}

// Test 2: Check Rust library loading
print("\n2. Testing Rust library...")

// Try to load the library
let libPath = "/Users/khaphan/Documents/Work/gonhanh.org/platforms/macos/libgonhanh_core.a"
if FileManager.default.fileExists(atPath: libPath) {
    print("   OK: Library exists at \(libPath)")
} else {
    print("   FAILED: Library not found!")
    exit(1)
}

// Test 3: Test FFI calls
print("\n3. Testing FFI calls...")

@_silgen_name("ime_init")
func ime_init()

@_silgen_name("ime_key")
func ime_key(_ key: UInt16, _ caps: Bool, _ ctrl: Bool) -> UnsafeMutableRawPointer?

@_silgen_name("ime_free")
func ime_free(_ result: UnsafeMutableRawPointer?)

ime_init()
print("   OK: ime_init() called")

// Test: type 'a' (keycode 0)
let r1 = ime_key(0, false, false)
print("   ime_key(0, false, false) = \(r1 != nil ? "got result" : "nil")")
if let ptr = r1 {
    // Read raw bytes
    let bytes = ptr.assumingMemoryBound(to: UInt8.self)
    // chars is 32 x 4 = 128 bytes, then action, backspace, count, _pad
    let action = bytes[128]
    let backspace = bytes[129]
    let count = bytes[130]
    print("   Result: action=\(action), backspace=\(backspace), count=\(count)")
    ime_free(ptr)
}

// Test: type 's' (keycode 1) - should produce 'á'
let r2 = ime_key(1, false, false)
print("   ime_key(1, false, false) = \(r2 != nil ? "got result" : "nil")")
if let ptr = r2 {
    let bytes = ptr.assumingMemoryBound(to: UInt8.self)
    let action = bytes[128]
    let backspace = bytes[129]
    let count = bytes[130]
    print("   Result: action=\(action), backspace=\(backspace), count=\(count)")

    if action == 1 && count > 0 {
        // Read first char (UInt32 at offset 0)
        let charPtr = ptr.assumingMemoryBound(to: UInt32.self)
        let charCode = charPtr[0]
        if let scalar = Unicode.Scalar(charCode) {
            print("   Output char: '\(Character(scalar))' (U+\(String(format: "%04X", charCode)))")
        }
    }
    ime_free(ptr)
}

print("\n=== Test Complete ===")
