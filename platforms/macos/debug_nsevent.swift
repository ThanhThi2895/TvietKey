#!/usr/bin/env swift
// Debug NSEvent global monitoring
import Foundation
import Cocoa

print("=== NSEvent Global Monitor Debug ===\n")

// Check permissions
let trusted = AXIsProcessTrusted()
print("AXIsProcessTrusted: \(trusted)")

// Try global monitor (can only observe, not modify)
print("\nTrying NSEvent.addGlobalMonitorForEvents...")

var monitor: Any?

monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
    print("Key: \(event.keyCode), chars: \(event.characters ?? "nil")")
}

if monitor != nil {
    print("✅ Global monitor created!")
    print("This can observe but NOT modify events")
    print("Press keys for 10 seconds...\n")

    // Need to run the app
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)

    // Run for 10 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        print("\nTest complete!")
        NSEvent.removeMonitor(monitor!)
        app.terminate(nil)
    }

    app.run()
} else {
    print("❌ Failed to create global monitor!")
}
