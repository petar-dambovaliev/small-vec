#import "Basic";

// ============================================================================
// PUBLIC API
// ============================================================================

SmallVec :: struct(T: Type, N: s64) {
    variant: SmallVec_Variant(T, N);
    count: s64;  // LSB = 0 for local, LSB = 1 for remote
    allocator: Allocator;
}

SmallVec_Variant :: union(T: Type, N: s64) {
    LocalBuf: [N] T;
    RemoteBuf: [..] T;
}

init :: ($T: Type, $N: s64, allocator: Allocator = .{}) -> SmallVec(T, N) {
    vec: SmallVec(T, N);
    local_buf: [N] T;
    vec.variant = SmallVec_Variant(T, N).{ LocalBuf = local_buf };
    vec.count = 0;
    
    if allocator.proc != null {
        vec.allocator = allocator;
    } else {
        vec.allocator = context.allocator;
    }
    
    return vec;
}

deinit :: (vec: *SmallVec) {
    if is_remote(vec) {
        array_free(vec.variant.RemoteBuf);
    }
}

len :: (vec: SmallVec) -> s64 {
    return vec.count >> 1;  // Shift right by 1 to get count without flag
}

is_remote :: (vec: SmallVec) -> bool {
    return (vec.count & 1) != 0;  // Check LSB directly
}

is_local :: (vec: SmallVec) -> bool {
    return !is_remote(vec);  // LSB = 0 means local
}

push :: (vec: *SmallVec, value: vec.T) {
    actual_count := len(vec);

    if !is_remote(vec) && actual_count < vec.N {
        vec.variant.LocalBuf[actual_count] = value;
        set_count_and_flag(vec, actual_count + 1, false);
        return;
    }

    if !is_remote(vec) && actual_count == vec.N {
        local_data: [vec.N] vec.T;
        for i: 0..vec.N-1 {
            local_data[i] = vec.variant.LocalBuf[i];
        }

        remote_array: [..] vec.T;
        remote_array.allocator = vec.allocator;

        // Copy local data to remote array
        for i: 0..vec.N-1 {
            array_add(*remote_array, local_data[i]);
        }

        array_add(*remote_array, value);

        vec.variant = SmallVec_Variant(vec.T, vec.N).{ RemoteBuf = remote_array };
        set_count_and_flag(vec, remote_array.count, true);

    } else {
        array_add(*vec.variant.RemoteBuf, value);
        set_count_and_flag(vec, actual_count + 1, true);
    }
}

pop :: (vec: *SmallVec) -> vec.T, bool {
    actual_count := len(vec);

    if actual_count == 0 {
        default_value: vec.T;
        return default_value, false;
    }

    if !is_remote(vec) {
        set_count_and_flag(vec, actual_count - 1, false);
        return vec.variant.LocalBuf[actual_count - 1], true;
    } else {
        index := actual_count - 1;
        set_count_and_flag(vec, actual_count - 1, true);
        return vec.variant.RemoteBuf[index], true;
    }
}

for_expansion :: (vec: SmallVec, body: Code, flags: For_Flags) #expand {
    slice: [] vec.T;

    if !is_remote(vec) {
        slice = vec.variant.LocalBuf;
    } else {
        slice = vec.variant.RemoteBuf;
    }

    for `it, `it_index: slice {
        #insert body;
    }
}

// ============================================================================
// PRIVATE IMPLEMENTATION
// ============================================================================

#scope_module;

set_count_and_flag :: (vec: *SmallVec, new_count: s64, is_remote: bool) {
    if is_remote {
        vec.count = (new_count << 1) | 1;  // Shift left by 1, set LSB
    } else {
        vec.count = new_count << 1;  // Shift left by 1, clear LSB
    }
}