#!/usr/bin/env swift
// Debug HID keyboard monitoring
import Foundation
import IOKit
import IOKit.hid

print("=== HID Keyboard Debug ===\n")

// Create HID Manager
let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
print("HID Manager created")

// Set device matching for keyboards
let matching: [[String: Any]] = [
    [
        kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
        kIOHIDDeviceUsageKey: kHIDUsage_GD_Keyboard
    ]
]
IOHIDManagerSetDeviceMatchingMultiple(manager, matching as CFArray)
print("Device matching set for keyboards")

// Callback for input values
let inputCallback: IOHIDValueCallback = { context, result, sender, value in
    let element = IOHIDValueGetElement(value)
    let usagePage = IOHIDElementGetUsagePage(element)
    let usage = IOHIDElementGetUsage(element)
    let intValue = IOHIDValueGetIntegerValue(value)

    // Only print key presses (value = 1)
    if usagePage == kHIDPage_KeyboardOrKeypad && intValue == 1 {
        print("Key pressed: usage=\(usage) (0x\(String(format: "%02X", usage)))")
    }
}

IOHIDManagerRegisterInputValueCallback(manager, inputCallback, nil)
print("Input callback registered")

// Schedule with run loop
IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)

// Open manager
let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
if openResult == kIOReturnSuccess {
    print("\n✅ HID Manager opened successfully!")
    print("Listening for keyboard events for 15 seconds...")
    print("Press some keys to test...\n")

    // Run for 15 seconds
    CFRunLoopRunInMode(.defaultMode, 15, false)

    print("\nTest complete!")
    IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
} else {
    print("\n❌ Failed to open HID Manager: \(openResult)")
    print("This might require Input Monitoring permission")
}
