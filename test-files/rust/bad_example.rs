// Hard-to-detect Rust mistakes that pass basic checks but fail in real-world linting setups

fn main() {
    let nums = vec![1, 2, 3, 4, 5];

    // 1. Iterator misuse — collect result ignored
    nums.iter().map(|x| x * 2); // does nothing, silently discarded

    // 2. Unnecessary clone — performance hit
    let data = "hello".to_string();
    let copied = data.clone(); // Clippy warns only if "perf" or "pedantic" lints enabled
    println!("{:?}", copied);

    // 3. Unused variable — default Clippy may skip unless “unused_variables” enforced
    let temp_result = compute_stuff(10);

    // 4. Float equality comparison
    let a = 0.1 + 0.2;
    let b = 0.3;
    if a == b {
        println!("Equal!"); // false due to precision — Clippy warns only with "float_cmp"
    }

    // 5. Borrowing after move (hidden by shadowing)
    let s = String::from("Nikhil");
    let s = s; // moves original, shadowed silently
    // println!("{}", s); // looks fine but hides moved variable issues in real code

    // 6. Misleading range loop
    for i in 0..=5 { // includes 5, off-by-one
        if i == 5 {
            println!("Oops, extra iteration"); // subtle logic bug
        }
    }

    // 7. Use of unwrap without error handling
    let parsed: i32 = "xyz".parse().unwrap_or_else(|_| {
        // bad fallback logic: hides actual error type
        println!("failed to parse");
        0
    });
    println!("Parsed: {}", parsed);

    // 8. Unnecessary reference in comparison
    let x = 5;
    if &x == &5 {
        println!("True"); // redundant referencing, caught only with 'needless_borrow'
    }

    // 9. Uninitialized value via Option misuse
    let mut maybe_val: Option<i32> = None;
    if maybe_val.is_none() {
        maybe_val = Some(10);
    }
    if maybe_val.unwrap() > 5 { // panic if logic changes
        println!("Large enough");
    }

    // 10. Shadowed mutable borrow scope confusion
    let mut v = vec![1, 2, 3];
    let r = &mut v;
    r.push(4);
    let v = v; // rebinds and invalidates mutable borrow silently — works but confusing ownership semantics

    println!("{:?}", v);
}

fn compute_stuff(x: i32) -> i32 {
    if x > 0 {
        return x * 2;
    }
    // 11. Missing return on some code path (falls through with default 0)
    0 // subtle bug if logic expands
}
