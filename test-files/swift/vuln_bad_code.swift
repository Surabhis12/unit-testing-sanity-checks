//
// swift_security_bad_practices.swift
// Intentionally insecure + bad-practice examples for testing static analysis & SAST.
// DO NOT USE IN PRODUCTION.
// Run in a sandboxed environment if you want to exercise parts of it.
//

import Foundation
import CommonCrypto // for MD5 (insecure) — available on Apple platforms


// ---------------------------
// 1) Hard-coded secret in source
// ---------------------------
let API_SECRET = "TOP-SECRET-DO-NOT-COMMIT-12345" // secret in repo

// ---------------------------
// 2) Storing secrets in UserDefaults (insecure)
// ---------------------------
func storeSecretInUserDefaults(_ secret: String) {
    // Bad: storing sensitive secret in plaintext in UserDefaults
    UserDefaults.standard.set(secret, forKey: "api_secret")
}

// ---------------------------
// 3) Force-unwrapping optionals (runtime crash risk)
// ---------------------------
func crashIfNil(_ s: String?) -> Int {
    // Force unwrap — will crash if s is nil
    return s!.count
}

// ---------------------------
// 4) Unsafe TLS: ignoring certificate validation (example for URLSessionDelegate)
// ---------------------------
class InsecureSessionDelegate: NSObject, URLSessionDelegate {
    // BAD: trusts any certificate
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

func fetchIgnoringTLS(url: URL) {
    let cfg = URLSessionConfiguration.default
    let ses = URLSession(configuration: cfg, delegate: InsecureSessionDelegate(), delegateQueue: nil)
    let task = ses.dataTask(with: url) { data, resp, err in
        if let d = data { print("Fetched \(d.count) bytes") }
    }
    task.resume()
}

// ---------------------------
// 5) Weak randomness (not CSPRNG)
// ---------------------------
func weakToken() -> String {
    // uses arc4random_uniform - ok for non-crypto, BAD for tokens/keys
    return String(format: "%08x", arc4random_uniform(UInt32.max))
}

// ---------------------------
// 6) Weak hashing (MD5) and homemade "encryption"
// ---------------------------
func md5(_ s: String) -> String {
    // MD5 is cryptographically broken — shouldn't be used for passwords or integrity checks
    let data = s.data(using: .utf8)!
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { CC_MD5($0.baseAddress, CC_LONG(data.count), &digest) }
    return digest.map { String(format: "%02x", $0) }.joined()
}

func xorObfuscate(_ s: String) -> String {
    // Not encryption — weak obfuscation easily reversed
    return String(s.utf8.map { Character(UnicodeScalar($0 ^ 0xAA)) })
}

// ---------------------------
// 7) SQL concatenation (SQL injection risk)
// ---------------------------
func buildQuery(username: String) -> String {
    // BAD: never concatenate user input into SQL
    return "SELECT * FROM users WHERE username = '\(username)';"
}

// ---------------------------
// 8) Using try! and force-try (swallows errors via crash)
// ---------------------------
func parseJSONForce(_ data: Data) -> [String: Any] {
    // force-try will crash on invalid JSON
    let obj = try! JSONSerialization.jsonObject(with: data, options: [])
    return obj as! [String: Any]
}

// ---------------------------
// 9) Blocking the main thread (bad UX / DoS risk in GUI apps)
// ---------------------------
func heavySyncWork() {
    // synchronous heavy I/O on main thread — bad practice for apps
    if let text = try? String(contentsOfFile: "/etc/hosts") {
        print("hosts len: \(text.count)")
    }
}

// ---------------------------
// 10) Retain cycle via closure capturing self strongly (memory leak)
// ---------------------------
class LeakyClass {
    var value = 0
    var timer: Timer?

    func startLeakyTimer() {
        // capture self strongly -> retain cycle
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.value += 1
        }
    }

    deinit {
        print("LeakyClass deinit")
    }
}

// ---------------------------
// 11) Swallowing errors (bad error handling)
// ---------------------------
func swallowErrors() {
    do {
        throw NSError(domain: "demo", code: 1, userInfo: nil)
    } catch {
        // BAD: silently ignoring — hides bugs and security issues
    }
}

// ---------------------------
// 12) Unsafe file handling — predictable temp file (TOCTOU)
// ---------------------------
func createPredictableTempFile() -> URL {
    let path = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tmp_\(ProcessInfo.processInfo.processIdentifier).dat")
    try? "sensitive".write(to: path, atomically: true, encoding: .utf8)
    return path
}

// ---------------------------
// 13) Using `Any` and force-casts — fragile and unsafe
// ---------------------------
func dangerousCast(_ obj: Any) -> Int {
    // force-cast may throw at runtime
    return (obj as! Int) + 1
}

// ---------------------------
// 14) Global mutable state (bad testability / thread-safety)
// ---------------------------
var GLOBAL_CACHE: [String: String] = [:]

// ---------------------------
// 15) Building RegEx from user input (ReDoS)
// ---------------------------
func userRegex(_ pattern: String) -> Bool {
    // user-controlled regex can be exploited for ReDoS
    let r = try? NSRegularExpression(pattern: pattern)
    return r?.firstMatch(in: "test string", options: [], range: NSRange(location: 0, length: 11)) != nil
}

// ---------------------------
// 16) Exposing internal mutable arrays (escaping internal state)
// ---------------------------
class Exposed {
    private var arr: [String] = ["a", "b"]
    func getArr() -> [String] {
        return arr // returns a copy in Swift, but if it's class type it could escape — still a smell
    }
}

// ---------------------------
// Driver to exercise some things (safe to run but avoid untrusted inputs)
// ---------------------------
func main() {
    print("Weak token example: \(weakToken())")
    print("MD5('password'): \(md5("password"))")
    print("Obf: \(xorObfuscate("secret"))")
    storeSecretInUserDefaults(API_SECRET)
    GLOBAL_CACHE["k"] = "v"

    // Dangerous: do not use untrusted input here when testing in CI
    let q = buildQuery("alice'; DROP TABLE users; --")
    print("Query: \(q)")

    // Force-try parsing (catch to avoid crash in CI)
    let data = "{}".data(using: .utf8)!
    _ = parseJSONForce(data)

    swallowErrors()
    _ = createPredictableTempFile()
    let _ = userRegex("(a+)+$") // dangerous but safe here

    let leak = LeakyClass()
    leak.startLeakyTimer()
    // intentionally not invalidating timer -> leak for leak detection tools

    // Avoid running insecure TLS fetch in CI unless sandboxed
    // fetchIgnoringTLS(url: URL(string: "https://example.com")!)
}

main()
