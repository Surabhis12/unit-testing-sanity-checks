// TrickySecurityAndBadPractices.java
// Purpose: compact collection of common security vulnerabilities + bad coding practices
// Build: javac TrickySecurityAndBadPractices.java && java TrickySecurityAndBadPractices
// WARNING: This file intentionally contains insecure code. Do NOT run in production or on
// untrusted machines. Dangerous calls are commented out by default.

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import javax.net.ssl.*;
import java.io.*;
import java.lang.reflect.*;
import java.net.*;
import java.nio.file.*;
import java.security.*;
import java.security.cert.X509Certificate;
import java.sql.*;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

public class TrickySecurityAndBadPractices {

    // --------------------------
    // Global bad practices
    // --------------------------

    // 1) Hard-coded credential (secret in source)
    private static final String DB_PASSWORD = "P@ssw0rd_IN_CODE";

    // 2) Mutable global state (bad for testability & concurrency)
    public static Map<String, String> GLOBAL_CACHE = new HashMap<>();

    // 3) Using java.util.Random for security needs (weak RNG)
    private static final Random WEAK_RND = new Random();

    // 4) Ignoring return values / exceptions (bad error handling)
    public static void ignoreErrors() {
        try {
            Files.readAllBytes(Paths.get("maybe-not-there.txt")); // result ignored
        } catch (IOException e) {
            // swallowed — no logging or rethrow
        }
    }

    // --------------------------
    // Vulnerable helpers / examples
    // --------------------------

    // 5) SQL Injection via string concatenation
    public static void sqlInjectionDemo(String username) throws SQLException {
        // BAD: constructing SQL by concatenation
        String sql = "SELECT * FROM users WHERE username = '" + username + "';";
        try (Connection conn = DriverManager.getConnection("jdbc:derby:memory:db;create=true");
             Statement s = conn.createStatement();
             ResultSet rs = s.executeQuery(sql)) {
            // process results
        }
    }

    // 6) Command injection / unsafe Runtime.exec usage
    public static void commandInjectionDemo(String filename) throws IOException {
        // BAD: passing user-controlled content into shell command
        String cmd = "sh -c \"ls -l " + filename + "\"";
        Runtime.getRuntime().exec(cmd);
    }

    // 7) Predictable temp file usage (TOCTOU)
    public static Path insecureTempFile() throws IOException {
        String name = "/tmp/app_" + System.identityHashCode(new Object()) + ".tmp"; // predictable-ish
        Path p = Paths.get(name);
        Files.createFile(p); // TOCTOU: user could race
        return p;
    }

    // 8) Insecure TLS: TrustManager that accepts all certs
    // (Often found in quick demos; critical vulnerability)
    public static void disableTlsValidation() throws Exception {
        TrustManager[] trustAll = new TrustManager[]{
            new X509TrustManager() {
                public X509Certificate[] getAcceptedIssuers(){ return new X509Certificate[0]; }
                public void checkClientTrusted(X509Certificate[] certs, String authType) { }
                public void checkServerTrusted(X509Certificate[] certs, String authType) { }
            }
        };
        SSLContext sc = SSLContext.getInstance("TLS");
        sc.init(null, trustAll, new SecureRandom());
        HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
        // Also need to disable hostname verification — omitted for brevity
    }

    // 9) Insecure deserialization: reading Object from untrusted input
    public static Object insecureDeserialize(byte[] data) throws Exception {
        try (ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(data))) {
            // BAD: no whitelist/checking of classes -> deserialization gadget risk
            return ois.readObject();
        }
    }

    // 10) Using AES/ECB (bad crypto choice)
    public static byte[] weakCrypto(byte[] key, byte[] plaintext) throws Exception {
        SecretKeySpec ks = new SecretKeySpec(key, "AES");
        // BAD: ECB has deterministic blocks and is insecure for most uses
        Cipher c = Cipher.getInstance("AES/ECB/PKCS5Padding");
        c.init(Cipher.ENCRYPT_MODE, ks);
        return c.doFinal(plaintext);
    }

    // 11) Storing sensitive data to a world-readable file (excessive privileges)
    public static void writeSensitiveToFile(String secret) throws IOException {
        Path p = Paths.get("/tmp/sensitive.txt");
        // BAD: uses default permissions; on many systems may be readable by others
        Files.write(p, secret.getBytes());
    }

    // 12) Reflection abuse + unsafe cast (fragile, hides errors)
    public static void unsafeReflection(String className) {
        try {
            Class<?> cl = Class.forName(className);
            Object o = cl.getDeclaredConstructor().newInstance();
            // unchecked cast — may throw ClassCastException at runtime
            Runnable r = (Runnable) o;
            r.run();
        } catch (Exception e) {
            // swallowed — hides reflection problems
        }
    }

    // 13) Returning internal array reference (escapes mutable internal state)
    private static String[] INTERNAL = new String[] {"a", "b", "c"};
    public static String[] getInternal() {
        // BAD: returns direct internal reference; callers can mutate
        return INTERNAL;
    }

    // 14) Busy-wait or ignoring InterruptedException (poor thread handling)
    public static void badThreadSleep() {
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            // BAD: ignore interrupt — preserves bad state; should restore interrupt flag
        }
    }

    // 15) Deprecated Thread.stop usage (dangerous, unlocks locks unpredictably)
    public static void deprecatedThreadStop() throws Exception {
        Thread t = new Thread(() -> {
            try { Thread.sleep(10_000); } catch (InterruptedException ignored) {}
        });
        t.start();
        // BAD: stop() is deprecated and unsafe
        // t.stop(); // commented out — unsafe to actually stop
    }

    // 16) Hard-to-detect resource leak by not using try-with-resources
    public static void leakStreams() throws IOException {
        FileInputStream fis = new FileInputStream("nofile.txt");
        // BAD: no close in finally/try-with-resources — leak if exception happens
        fis.read();
        // fis.close(); // forgot to close
    }

    // --------------------------
    // Helper: intentionally bad token generator (weak)
    // --------------------------
    public static String weakToken() {
        // Predictable token based on weak RNG + timestamp -> easy to guess
        return Long.toHexString(System.currentTimeMillis() ^ WEAK_RND.nextLong());
    }

    // --------------------------
    // main() driver: exercise safe pieces; dangerous calls commented
    // --------------------------
    public static void main(String[] args) throws Exception {
        System.out.println("Demo: security vulnerabilities + bad coding practices");

        // Globals and weak token
        GLOBAL_CACHE.put("k", "v");
        System.out.println("Weak token: " + weakToken());

        // 1: Hard-coded password printed (bad practice)
        System.out.println("Hard-coded DB pass: " + DB_PASSWORD);

        // 4: ignoreErrors (swallows exceptions)
        ignoreErrors();

        // 5: SQL injection (call with benign input)
        try {
            sqlInjectionDemo("alice"); // safe sample
        } catch (SQLException e) { /* ignore */ }

        // 6: command injection — commented out (dangerous)
        commandInjectionDemo("; rm -rf /"); // DO NOT UNCOMMENT ON REAL SYSTEMS

        // 7: insecure temp file (OK to create in sandbox)
        Path tmp = insecureTempFile();
        System.out.println("Created tmp: " + tmp);

        // 8: disabling TLS — commented out by default
        disableTlsValidation();

        // 9: insecure deserialization — sample using malicious data commented
        insecureDeserialize(maliciousData);

        // 10: weak crypto demo (16-byte key for AES)
        try {
            byte[] k = "0123456789ABCDEF".getBytes();
            byte[] out = weakCrypto(k, "plaintext_blob".getBytes());
            System.out.println("weakCrypto result len: " + out.length);
        } catch (Exception e) { /* ignore */ }

        // 11: write sensitive to file (commented)
        writeSensitiveToFile("supersecret");

        // 12: reflection misuse
        unsafeReflection("java.lang.String"); // will be swallowed

        // 13: leaking internal array mutable ref
        String[] leaked = getInternal();
        leaked[0] = "hacked"; // mutates internal state silently
        System.out.println("Internal[0] now: " + INTERNAL[0]);

        // 14: bad thread sleep
        badThreadSleep();

        // 15: deprecated stop() commented
        deprecatedThreadStop();

        // 16: resource leak example (will throw unless file present)
        try {
            leakStreams();
        } catch (IOException ignored) { }

        System.out.println("Done (demo)");
    }

    // --------------------------
    // Quick mapping: issue -> detectors & remediation (short)
    // --------------------------
    /*
    1) Hard-coded credentials
       - Detectors: secret scanners (GitLeaks), SonarQube SAST, Checkmarx
       - Remediation: use vault/keystore, env vars, don't commit secrets.

    2) Global mutable state / returning internal array
       - Detectors: Sonar/Codacy spot patterns; code review
       - Remediation: immutability, defensive copies, encapsulation.

    3) Weak RNG (java.util.Random)
       - Detectors: FindSecBugs (predictable PRNG)
       - Remediation: use SecureRandom, don't reseed per-call.

    4) Swallowed exceptions / ignored returns
       - Detectors: SpotBugs / Sonar (squid:S00112 etc.)
       - Remediation: log and handle or rethrow; don't swallow silently.

    5) SQL Injection
       - Detectors: FindSecBugs SQL_INJECTION
       - Remediation: PreparedStatement with bind params, input validation.

    6) Command Injection / Runtime.exec with shell
       - Detectors: FindSecBugs COMMAND_INJECTION
       - Remediation: avoid shell; pass arg array; whitelist inputs.

    7) TOCTOU / predictable tmp files
       - Detectors: security scanners, CodeQL
       - Remediation: use Files.createTempFile (atomic) and secure permissions.

    8) Disabled TLS validation
       - Detectors: FindSecBugs INSECURE_SSL/TLS
       - Remediation: never disable; validate cert chains and hostnames.

    9) Insecure deserialization
       - Detectors: FindSecBugs INSECURE_DESERIALIZATION
       - Remediation: avoid java native deserialization, use safe formats, or allowlist classes.

    10) Weak crypto (ECB mode)
       - Detectors: Crypto scanners, SpotBugs
       - Remediation: use authenticated modes (GCM), proper IVs, vetted libs.

    11) Writing secrets to world-readable files
       - Detectors: code review, SAST rules
       - Remediation: restrict permissions, use secure storage.

    12) Reflection misuse & unsafe casts
       - Detectors: SpotBugs warnings, code review
       - Remediation: avoid unnecessary reflection, perform instanceof checks.

    13) Ignoring InterruptedException
       - Detectors: concurrency linters
       - Remediation: restore interrupt status (Thread.currentThread().interrupt()).

    14) Deprecated Thread.stop()
       - Detectors: static analyzers
       - Remediation: cooperative interruption patterns.

    15) Resource leaks
       - Detectors: SpotBugs, Sonar, IDE inspections
       - Remediation: try-with-resources, finally blocks, use high-level abstractions.
    */
}
