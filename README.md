# SmallVec

SmallVec is a vector data structure that provides the performance benefits of stack allocation for small collections while automatically switching to heap allocation when needed. This is particularly useful for performance-critical applications where you want to avoid heap allocations for common cases.

## Usage

```jai
#import "Basic";
SmallVec :: #import "small_vec";

main :: () {
    // Create a SmallVec with capacity 4 for u32 elements
    vec := SmallVec.init(u32, 4);
    
    // Push elements (stays in local buffer)
    SmallVec.push(*vec, 10);
    SmallVec.push(*vec, 20);
    SmallVec.push(*vec, 30);
    SmallVec.push(*vec, 40);
    
    // Push one more - triggers switch to remote buffer
    SmallVec.push(*vec, 50);
    
    // Check status
    print("Length: %, Is remote: %\n", 
    SmallVec.len(vec), 
    SmallVec.is_remote(vec));
    
    for vec {
        //
    }
    
    // Pop elements
    value, success := SmallVec.pop(*vec);
    if success {
        print("Popped: %\n", value);
    }
    
    // Clean up
    SmallVec.deinit(*vec);
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Acknowledgments

- Inspired by Rust's SmallVec implementation
- Built for the Jai programming language
