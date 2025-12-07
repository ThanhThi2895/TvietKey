// Simple FFI test for GoNhanh
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

// FFI declarations
extern void ime_init(void);
extern void* ime_key(uint16_t key, bool caps, bool ctrl);
extern void ime_free(void* result);
extern void ime_method(uint8_t method);

// Result struct (must match Rust)
typedef struct {
    uint32_t chars[32];
    uint8_t action;
    uint8_t backspace;
    uint8_t count;
    uint8_t _pad;
} ImeResult;

int main() {
    printf("=== GoNhanh FFI Test ===\n\n");

    // Initialize
    printf("1. Calling ime_init()...\n");
    ime_init();
    printf("   OK\n");

    // Set method to Telex
    printf("2. Calling ime_method(0) for Telex...\n");
    ime_method(0);
    printf("   OK\n");

    // Type 'a' (keycode 0)
    printf("3. Calling ime_key(0, false, false) for 'a'...\n");
    void* r1 = ime_key(0, false, false);
    if (r1) {
        ImeResult* res = (ImeResult*)r1;
        printf("   action=%d, backspace=%d, count=%d\n",
               res->action, res->backspace, res->count);
        ime_free(r1);
    } else {
        printf("   returned NULL\n");
    }

    // Type 's' (keycode 1) - should produce 'á'
    printf("4. Calling ime_key(1, false, false) for 's'...\n");
    void* r2 = ime_key(1, false, false);
    if (r2) {
        ImeResult* res = (ImeResult*)r2;
        printf("   action=%d, backspace=%d, count=%d\n",
               res->action, res->backspace, res->count);
        if (res->action == 1 && res->count > 0) {
            printf("   First char: U+%04X", res->chars[0]);
            if (res->chars[0] == 0x00E1) {
                printf(" = 'á' CORRECT!\n");
            } else {
                printf(" (expected 0x00E1 = 'á')\n");
            }
        }
        ime_free(r2);
    } else {
        printf("   returned NULL\n");
    }

    printf("\n=== Test Complete ===\n");
    return 0;
}
