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

deinit :: ($T: Type, $N: s64, vec: *SmallVec(T, N)) {
    if is_remote(T, N, vec) {
        array_free(vec.variant.RemoteBuf);
    }
}

len :: ($T: Type, $N: s64, vec: SmallVec(T, N)) -> s64 {
    return vec.count >> 1;  // Shift right by 1 to get count without flag
}

is_remote :: ($T: Type, $N: s64, vec: SmallVec(T, N)) -> bool {
    return (vec.count & 1) != 0;  // Check LSB directly
}

is_local :: ($T: Type, $N: s64, vec: SmallVec(T, N)) -> bool {
    return !is_remote(T, N, vec);  // LSB = 0 means local
}

push :: ($T: Type, $N: s64, vec: *SmallVec(T, N), value: T) {
    actual_count := len(T, N, vec);
    
    if !is_remote(T, N, vec) && actual_count < N {
        vec.variant.LocalBuf[actual_count] = value;
        set_count_and_flag(T, N, vec, actual_count + 1, false);
        return;
    }

    if !is_remote(T, N, vec) && actual_count == N {
        local_data: [N] T;
        for i: 0..N-1 {
            local_data[i] = vec.variant.LocalBuf[i];
        }

        remote_array: [..] T;
        remote_array.allocator = vec.allocator;
        
        // Copy local data to remote array
        for i: 0..N-1 {
            array_add(*remote_array, local_data[i]);
        }
        
        array_add(*remote_array, value);
        
        vec.variant = SmallVec_Variant(T, N).{ RemoteBuf = remote_array };
        set_count_and_flag(T, N, vec, remote_array.count, true);

    } else {
        array_add(*vec.variant.RemoteBuf, value);
        set_count_and_flag(T, N, vec, actual_count + 1, true);
    }
}

pop :: ($T: Type, $N: s64, vec: *SmallVec(T, N)) -> T, bool {
    actual_count := len(T, N, vec);
    
    if actual_count == 0 {
        default_value: T;
        return default_value, false;
    }

    if !is_remote(T, N, vec) {
        set_count_and_flag(T, N, vec, actual_count - 1, false);
        return vec.variant.LocalBuf[actual_count - 1], true;
    } else {
        index := actual_count - 1;
        set_count_and_flag(T, N, vec, actual_count - 1, true);
        return vec.variant.RemoteBuf[index], true;
    }
}

// ============================================================================
// PRIVATE IMPLEMENTATION
// ============================================================================

#scope_module;

set_count_and_flag :: ($T: Type, $N: s64, vec: *SmallVec(T, N), new_count: s64, is_remote: bool) {
    if is_remote {
        vec.count = (new_count << 1) | 1;  // Shift left by 1, set LSB
    } else {
        vec.count = new_count << 1;  // Shift left by 1, clear LSB
    }
}