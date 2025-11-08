// subtle_vulns_rust.rs
// Purpose: subtle Rust examples that violate rustfmt/clippy/Secure Code WG style & security.
// Build: rustc subtle_vulns_rust.rs && ./subtle_vulns_rust
//
// WARNING: intentionally insecure / UB patterns for testing only.

use std::env;
use std::fs::{File, OpenOptions};
use std::io::{Read, Write};
use std::mem;
use std::process::Command;
use std::slice;
use std::time::{SystemTime, UNIX_EPOCH};


// ----------------------- 1) Hard-coded secret (detectable by secret scanners) ----------
const API_SECRET: &str = "APISECRET_SUPER_SECRET_1234567890";

// ----------------------- 2) Weak "random" token (time-based) -------------------------
fn weak_token() -> String {
    // Not cryptographically secure — derives token from current time which is predictable
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    format!("{:x}", now ^ (now << 13)) // looks innocent but is predictable
}

// ----------------------- 3) Predictable temp filename (TOCTOU) -----------------------
fn predictable_tmpfile() -> String {
    // predictable path based on pid and time
    let pid = std::process::id();
    let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
    let path = format!("/tmp/rust_demo_{}_{}.tmp", pid, now);
    // create file without setting restrictive permissions
    let _ = File::create(&path); // ignore errors intentionally (bad practice)
    path
}

// ----------------------- 4) Command invocation via shell (command injection risk) ---
fn list_files_shell(user_arg: &str) {
    // Unsafe pattern: constructing a shell command with user-controlled input
    // Using "sh -c" is commonly flagged by SAST rules.
    let cmd = format!("ls -l {}", user_arg); // potential injection if user_arg contains metacharacters
    // spawn with sh -c on purpose to show pattern
    let _ = Command::new("sh")
        .arg("-c")
        .arg(cmd)
        .status(); // intentionally ignore Result (bad practice)
}

// ----------------------- 5) Unchecked indexing via get_unchecked (UB risk) -----------
fn unchecked_index_example(vec: &[u8], idx: usize) -> u8 {
    unsafe {
        // using get_unchecked bypasses bounds checks — subtle UB if idx invalid
        *vec.get_unchecked(idx)
    }
}

// ----------------------- 6) Unsafe pointer cast + reinterpretation -------------------
fn unsafe_pointer_reinterpret() {
    // create a small integer and write beyond its size via raw pointer arithmetic
    let mut x: u32 = 0x41414141;
    let p: *mut u8 = &mut x as *mut u32 as *mut u8;
    unsafe {
        // write bytes directly — depending on endianness this corrupts memory
        // subtle UB if misused; static analyzers should flag raw pointer ops
        std::ptr::write(p, 0xFFu8);
    }
    // print to appear normal
    println!("x after raw write: 0x{:08x}", x);
}

// ----------------------- 7) Double free via Box::from_raw (UB) -----------------------
fn double_free_demo() {
    // Create a box, convert to raw, then create two Boxes from the same raw pointer and drop both
    let boxed = Box::new(123u32);
    let raw = Box::into_raw(boxed);
    unsafe {
        // first reconstitute and drop
        let b1 = Box::from_raw(raw);
        drop(b1);
        // second reconstitute -> double free (UB)
        let b2 = Box::from_raw(raw);
        drop(b2);
    }
    // Program might continue but this is undefined behavior and should be flagged.
}

// ----------------------- 8) Returning reference to leaked memory (looks safe) -------
fn leak_and_return() -> &'static str {
    // Leak a String to obtain a 'static str — not UB but hides memory management issues
    let s = String::from("leaked_string");
    let leaked: &'static str = Box::leak(s.into_boxed_str());
    leaked
}

// ----------------------- 9) Swallowing errors (bad error handling) ------------------
fn swallow_errors_demo(path: &str) {
    // intentionally ignoring Result and errors
    let mut f = match File::open(path) {
        Ok(f) => f,
        Err(_) => return, // swallow
    };
    let mut buf = String::new();
    let _ = f.read_to_string(&mut buf); // ignore read errors
    // intentionally not handling content
    let _ = buf;
}

// ----------------------- 10) Excessive use of unwrap/expect (clippy: unwrap_used) ----
fn unwrap_demo() {
    // multiple unwraps look normal but are brittle; clippy flags unwrap_used
    let args: Vec<String> = env::args().collect();
    // if not provided, unwrap will panic in production
    let maybe = args.get(1).unwrap_or(&String::from("default")).clone();
    println!("arg: {}", maybe);
    // parse number unsafely
    let n: i32 = "42".parse().expect("should parse"); // expect_used
    println!("parsed: {}", n);
}

// ----------------------- 11) needless_clone + redundant allocation (clippy) ----------
fn needless_clone_demo(s: &str) {
    // Here clone is unnecessary; clippy warns about needless_clone
    let x = s.to_string();
    let y = x.clone(); // needless clone
    println!("cloned len: {}", y.len());
}

// ----------------------- 12) Weak "obfuscation" used as pseudo-crypto ---------------
fn weak_xor_obfuscate(s: &str) -> String {
    s.bytes().map(|b| (b ^ 0xAAu8) as char).collect()
}

// ----------------------- main: tie things together, look benign ----------------------
fn main() {
    // Intentionally non-rustfmt formatting to test rustfmt detection:
    println!("Subtle Rust vulnerabilities demo - looks normal");

    // 1: secret printed (should be caught by secret scanners)
    println!("api secret preview: {}...", &API_SECRET[..6]);

    // 2: weak token
    println!("weak token: {}", weak_token());

    // 3: predictable tmp file
    let tmp = predictable_tmpfile();
    println!("predictable tmp created: {}", tmp);

    // 4: list files using shell with safe-looking arg
    let safe_arg = ".";
    list_files_shell(safe_arg);

    // 5: unchecked index but using small index so usually fine
    let v = vec![10u8, 20, 30];
    let val = unsafe { unchecked_index_example(&v, 1) };
    println!("unchecked index result: {}", val);

    // 6: unsafe pointer reinterpret
    unsafe_pointer_reinterpret();

    // 7: double free demo — may corrupt heap silently
    // Run in a confined test; often program continues but UB is present
    double_free_demo();

    // 8: leaked static string (hides memory management)
    let leaked = leak_and_return();
    println!("leaked static: {}", leaked);

    // 9: swallow errors on a likely-missing path
    swallow_errors_demo("/does/not/exist.txt");

    // 10: unwrap demo (panic risk)
    unwrap_demo();

    // 11: needless clone
    needless_clone_demo("hello");

    // 12: weak obfuscation
    println!("xor obf: {}", weak_xor_obfuscate("secret"));

    // Exit normally
    println!("Done (program terminated normally)");
}
