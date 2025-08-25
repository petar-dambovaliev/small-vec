#import "Basic";

// Import our SmallVec module from parent directory
SmallVec :: #import,file "../small_vec.jai";

main :: () {
    print("=== Testing SmallVec Public API ===\n");
    
    // Test 1: Basic creation and initialization
    print("Test 1: Basic creation...\n");
    vec := SmallVec.init(u32, 4);
    assert(SmallVec.len(u32, 4, vec) == 0, "New vector should have length 0");
    assert(SmallVec.is_local(u32, 4, vec), "New vector should be local");
    print("✓ Basic creation passed\n");
    
    // Test 2: Push operations to local buffer
    print("\nTest 2: Push to local buffer...\n");
    SmallVec.push(u32, 4, *vec, 10);
    SmallVec.push(u32, 4, *vec, 20);
    SmallVec.push(u32, 4, *vec, 30);
    SmallVec.push(u32, 4, *vec, 40);
    
    assert(SmallVec.len(u32, 4, vec) == 4, "Length should be 4 after 4 pushes");
    assert(SmallVec.is_local(u32, 4, vec), "Should still be local");
    print("✓ Local buffer operations passed\n");
    
    // Test 3: Switch to remote buffer
    print("\nTest 3: Switch to remote buffer...\n");
    SmallVec.push(u32, 4, *vec, 50);
    assert(SmallVec.len(u32, 4, vec) == 5, "Length should be 5");
    assert(SmallVec.is_remote(u32, 4, vec), "Should now be remote");
    print("✓ Remote buffer switch passed\n");
    
    // Test 4: Pop operations
    print("\nTest 4: Pop operations...\n");
    value, success := SmallVec.pop(u32, 4, *vec);
    assert(success && value == 50, "Should pop 50");
    assert(SmallVec.len(u32, 4, vec) == 4, "Length should be 4 after pop");
    
    value, success = SmallVec.pop(u32, 4, *vec);
    assert(success && value == 40, "Should pop 40");
    print("✓ Pop operations passed\n");
    
    // Test 5: Custom allocator
    print("\nTest 5: Custom allocator...\n");
    custom_allocator_proc :: (mode: Allocator_Mode, size: s64, old_size: s64, old_memory: *void, allocator_data: *void) -> *void {
        if mode == .ALLOCATE {
            print("  CUSTOM: Allocating % bytes\n", size);
        } else if mode == .FREE {
            print("  CUSTOM: Freeing memory\n");
        }
        return context.default_allocator.proc(mode, size, old_size, old_memory, allocator_data);
    }
    
    custom_allocator: Allocator;
    custom_allocator.proc = custom_allocator_proc;
    custom_allocator.data = null;
    
    custom_vec := SmallVec.init(u32, 2, custom_allocator);
    SmallVec.push(u32, 2, *custom_vec, 100);
    SmallVec.push(u32, 2, *custom_vec, 200);
    SmallVec.push(u32, 2, *custom_vec, 300);  // Triggers remote allocation
    
    assert(SmallVec.len(u32, 2, custom_vec) == 3, "Custom allocator vector should have length 3");
    print("✓ Custom allocator passed\n");
    
    // Test 6: Edge cases
    print("\nTest 6: Edge cases...\n");
    empty_vec := SmallVec.init(u32, 4);
    value, success = SmallVec.pop(u32, 4, *empty_vec);
    assert(!success, "Pop on empty vector should return false");
    print("✓ Edge cases passed\n");
    
    // Clean up
    SmallVec.deinit(u32, 4, *vec);
    SmallVec.deinit(u32, 2, *custom_vec);
    SmallVec.deinit(u32, 4, *empty_vec);
    
    print("\n🎉 All tests passed! SmallVec public API is working correctly.\n");
}
