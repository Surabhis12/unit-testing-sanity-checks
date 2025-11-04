use std::ptr;
use std::mem;
use std::fs::File;
use std::io::Read;
use std::thread;
use std::sync::{Arc, Mutex};

fn main() {
    // --- SECURITY VULNERABILITY 1: Unsafe pointer manipulation ---
    unsafe {
        let mut data = 42;
        let ptr = &mut data as *mut i32;
        *ptr = 0; // Dangerous: raw pointer deref
        let dangling: *mut i32 = mem::transmute(0xDEADBEEFusize); // fake pointer
        println!("Value: {}", *dangling); // Undefined behavior
    }
    

    // --- SECURITY VULNERABILITY 2: Sensitive data exposure ---
    let password = "supersecret123"; // Hardcoded password
    println!("Password: {}", password); // Prints sensitive info

    // --- SECURITY VULNERABILITY 3: Unchecked file read ---
    let mut file = File::open("user_data.txt").unwrap(); // Panics if missing
    let mut contents = String::new();
    file.read_to_string(&mut contents).unwrap();
    println!("User data: {}", contents);

    // --- BAD PRACTICE 1: Race condition with Arc + Mutex ---
    let shared = Arc::new(Mutex::new(0));
    for _ in 0..5 {
        let s = Arc::clone(&shared);
        thread::spawn(move || {
            let mut num = s.lock().unwrap();
            *num += 1;
            println!("Counter = {}", *num);
        });
    }

    // --- BAD PRACTICE 2: Panic misuse ---
    panic!("Just because I can!");

    // --- BAD PRACTICE 3: Ignoring Result ---
    let _ = File::open("/tmp/missing_file"); // silently ignoring errors

    // --- BAD PRACTICE 4: Use of unwrap() everywhere ---
    let config = std::env::var("CONFIG").unwrap(); // crash if not set
    println!("Config: {}", config);
}
