SmallVec :: struct(T: Type, N: s64) {
    union {
        local_buf: [N] T;
        remote_buf: [..] T = ---;
    };
    count: s64;
    is_remote: bool;
}

deinit :: (vec: *SmallVec) {
    if vec.is_remote then array_free(vec.remote_buf);
}

push :: (vec: *SmallVec, value: vec.T) {
    if !vec.is_remote && vec.count < vec.N {
        vec.local_buf[vec.count] = value;
        vec.count += 1;
        return;
    }

    if !vec.is_remote && vec.count == vec.N {
        // Copy local buf to remote array
        remote_array: [..] vec.T;
        array_add(*remote_array, ..vec.local_buf);
        array_add(*remote_array, value);
        vec.remote_buf = remote_array;

        vec.count = vec.remote_buf.count;
        vec.is_remote = true;
    } else {
        array_add(*vec.remote_buf, value);
        vec.count = vec.remote_buf.count;
    }
}

pop :: (vec: *SmallVec) -> ok:bool, item:vec.T {
    if vec.count == 0 {
        default_value: vec.T;
        return false, default_value;
    }

    vec.count -= 1;
    if !vec.is_remote { return true, vec.local_buf[vec.count]; }
    else              { return true, pop(*vec.remote_buf); }
}

for_expansion :: (vec: SmallVec, body: Code, flags: For_Flags) #expand {
    slice: [] vec.T;
    if !vec.is_remote { slice = vec.local_buf; }
    else              { slice = vec.remote_buf; }

    for `it, `it_index: slice {
        #insert body;
    }
}

#scope_file
#import "Basic";
