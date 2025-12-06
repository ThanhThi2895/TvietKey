import Foundation

class RustBridge {
    /// Process Vietnamese input
    static func processInput(_ input: String, mode: UInt8) -> String {
        guard let cInput = input.cString(using: .utf8) else {
            return input
        }

        let result = process_input(cInput, mode)

        guard let result = result else {
            return input
        }

        let output = String(cString: result)
        free_string(result)
        return output
    }

    /// Start keyboard hook
    static func startHook() {
        start_hook { keyPtr in
            guard let keyPtr = keyPtr else { return }
            let key = String(cString: keyPtr)
            print("Key pressed: \(key)")
        }
    }

    /// Stop keyboard hook
    static func stopHook() {
        stop_hook()
    }

    /// Save configuration
    static func saveConfig(enabled: Bool, mode: UInt8) {
        save_config(enabled, mode)
    }

    /// Load configuration
    static func loadConfig() -> (enabled: Bool, mode: UInt8) {
        let configPtr = load_config()
        guard let configPtr = configPtr else {
            return (true, 0)
        }

        let config = configPtr.pointee
        free_config(configPtr)

        return (config.enabled, config.mode)
    }
}

// MARK: - C Interop

struct RustConfig {
    let enabled: Bool
    let mode: UInt8
}

// C function declarations
@_silgen_name("process_input")
func process_input(_ input: UnsafePointer<CChar>, _ mode: UInt8) -> UnsafeMutablePointer<CChar>?

@_silgen_name("start_hook")
func start_hook(_ callback: @escaping @convention(c) (UnsafePointer<CChar>?) -> Void)

@_silgen_name("stop_hook")
func stop_hook()

@_silgen_name("save_config")
func save_config(_ enabled: Bool, _ mode: UInt8)

@_silgen_name("load_config")
func load_config() -> UnsafeMutablePointer<RustConfig>?

@_silgen_name("free_string")
func free_string(_ s: UnsafeMutablePointer<CChar>?)

@_silgen_name("free_config")
func free_config(_ config: UnsafeMutablePointer<RustConfig>?)
