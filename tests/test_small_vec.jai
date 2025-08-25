#import "Basic";

// Import our SmallVec module from parent directory
using SmallVecLib :: #import,file "../small_vec.jai";

main :: () {
    print("=== Testing SmallVec Public API ===\n");
    
    // Test 1: Basic creation and initialization
    print("Test 1: Basic creation...\n");
    vec := SmallVecLib.init(u32, 4);
    assert(SmallVecLib.len(vec) == 0, "New vector should have length 0");
    assert(SmallVecLib.is_local(vec), "New vector should be local");
    print("✓ Basic creation passed\n");

    // Test 2: Push operations to local buffer
    print("\nTest 2: Push to local buffer...\n");
    SmallVecLib.push(*vec, 10);
    SmallVecLib.push(*vec, 20);
    SmallVecLib.push(*vec, 30);
    SmallVecLib.push(*vec, 40);

    assert(SmallVecLib.len(vec) == 4, "Length should be 4 after 4 pushes");
    assert(SmallVecLib.is_local(vec), "Should still be local");
    print("✓ Local buffer operations passed\n");

    // Test 3: Switch to remote buffer
    print("\nTest 3: Switch to remote buffer...\n");
    SmallVecLib.push(*vec, 50);
    assert(SmallVecLib.len(vec) == 5, "Length should be 5");
    assert(SmallVecLib.is_remote(vec), "Should now be remote");
    print("✓ Remote buffer switch passed\n");

    // Test 4: Pop operations
    print("\nTest 4: Pop operations...\n");
    value, success := SmallVecLib.pop(*vec);
    assert(success && value == 50, "Should pop 50");
    assert(SmallVecLib.len(vec) == 4, "Length should be 4 after pop");

    value, success = SmallVecLib.pop(*vec);
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

    custom_vec := SmallVecLib.init(u32, 2, custom_allocator);
    SmallVecLib.push(*custom_vec, 100);
    SmallVecLib.push(*custom_vec, 200);
    SmallVecLib.push(*custom_vec, 300);  // This should trigger remote allocation

    assert(SmallVecLib.len(custom_vec) == 3, "Custom allocator vector should have length 3");
    print("✓ Custom allocator passed\n");

    // Test 6: Edge cases
    print("\nTest 6: Edge cases...\n");
    empty_vec := SmallVecLib.init(u32, 4);
    value, success = SmallVecLib.pop(*empty_vec);
    assert(!success, "Pop on empty vector should return false");
    print("✓ Edge cases passed\n");

    // Clean up
    SmallVecLib.deinit(*vec);
    SmallVecLib.deinit(*custom_vec);
    SmallVecLib.deinit(*empty_vec);



    // Test 7: Iteration

     // Create a SmallVec with capacity 3
    vec1 := SmallVecLib.init(u32, 3, context.allocator);
    defer SmallVecLib.deinit(*vec1);

    // Add some elements
    SmallVecLib.push(*vec1, 10);
    SmallVecLib.push(*vec1, 20);
    SmallVecLib.push(*vec1, 30);

    // Test basic iteration
    print("Testing basic iteration...\n");
    count := 0;
    for vec1 {
        count += 1;
        if count == 1 assert(it == 10, "First element should be 10");
        if count == 2 assert(it == 20, "Second element should be 20");
        if count == 3 assert(it == 30, "Third element should be 30");
    }
    assert(count == 3, "Should have iterated 3 times");
    print("✓ Basic iteration passed\n");

    // Test with custom variable names
    print("Testing custom variable names...\n");
    count = 0;
    for value, index: vec1 {
        count += 1;
        assert(value == vec1.variant.LocalBuf[index], "Value should match buffer");
        assert(index == count - 1, "Index should be 0, 1, 2");
    }
    assert(count == 3, "Should have iterated 3 times");
    print("✓ Custom names passed\n");

    // Test break
    print("Testing break...\n");
    count = 0;
    for vec1 {
        count += 1;
        if it == 20 break;
    }
    assert(count == 2, "Break should have stopped after 2 iterations");
    print("✓ Break test passed\n");

    // Test continue
    print("Testing continue...\n");
    count = 0;
    for vec1 {
        if it == 20 continue;
        count += 1;
    }
    assert(count == 2, "Continue should have skipped one element");
    
    print("\n🎉 All tests passed! SmallVec public API is working correctly.\n");
}
