// SubtleVulnsCertOwasp.java
// Demonstrates multiple subtle CERT Java + OWASP violations while running normally.
// Build: javac SubtleVulnsCertOwasp.java && java SubtleVulnsCertOwasp
//
// WARNING: Intentionally insecure code. Use only in isolated test environments.

import javax.net.ssl.*;
import java.io.*;
import java.lang.reflect.Constructor;
import java.net.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.*;
import java.security.cert.X509Certificate;
import java.sql.*;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class SubtleVulnsCertOwasp {

    // 1) Hard-coded credential (CERT: sensitive data in source)
    private static final String API_KEY = "AKIA_TEST_SECRET_ABCDEFG123456";

    // 2) Weak RNG used for token generation (OWASP: weak randomness)
    public static String generateWeakToken() {
        // ThreadLocalRandom is okay for non-crypto, but using seed/time or Random would be worse.
        // Here we intentionally mix Random with system time to be suspicious.
        Random r = new Random(System.currentTimeMillis() ^ System.identityHashCode(SubtleVulnsCertOwasp.class));
        long v = r.nextLong();
        return Long.toHexString(v);
    }

    // 3) SQL creation via string concatenation => SQL injection (OWASP A1 / CERT SQL_INJECTION)
    public static void unsafeSqlQuery(String username) throws SQLException {
        // Using in-memory H2/Derby would complicate run; keep code benign but pattern is insecure.
        String sql = "SELECT * FROM users WHERE username = '" + username + "';"; // <- vulnerable
        System.out.println("Unsafe SQL: " + sql);
        // (No DB execution performed to avoid side-effects)
    }

    // 4) Insecure TLS: naive TrustManager that accepts all certs (OWASP: insecure TLS)
    public static void disableTlsValidation() {
        try {
            TrustManager[] trustAll = new TrustManager[] {
                new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers(){ return new X509Certificate[0]; }
                    public void checkClientTrusted(X509Certificate[] certs, String authType) { }
                    public void checkServerTrusted(X509Certificate[] certs, String authType) { }
                }
            };
            SSLContext sc = SSLContext.getInstance("TLS");
            sc.init(null, trustAll, new SecureRandom());
            HttpsURLConnection.setDefaultSSLSocketFactory(sc.getSocketFactory());
            // Hostname verifier bypass
            HttpsURLConnection.setDefaultHostnameVerifier((hostname, session) -> true);
            System.out.println("TLS validation disabled (demo).");
        } catch (Exception e) {
            // intentionally swallow for demo
        }
    }

    // 5) Insecure deserialization (CERT: DO NOT deserialize untrusted bytes)
    public static Object insecureDeserialize(byte[] data) {
        // Uses native Java deserialization without any allowlist — classic hazard.
        try (ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(data))) {
            return ois.readObject(); // vulnerable pattern
        } catch (Exception e) {
            return null;
        }
    }

    // 6) Command construction with minimal validation -> command injection (OWASP)
    public static void runShellList(String fileArg) throws IOException {
        // Passes to shell; if fileArg contains shell metacharacters, injection possible.
        String cmd = "ls -l " + fileArg;
        // Use Runtime.exec(String) which goes through shell on some platforms — risky.
        Process p = Runtime.getRuntime().exec(new String[] {"sh", "-c", cmd});
        try (BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()))) {
            // Print only first line to look normal
            String line = br.readLine();
            if (line != null) System.out.println("ls -> " + line);
        } catch (IOException ignored) {}
    }

    // 7) Path traversal: concatenating user path directly (OWASP)
    public static String readUserFile(String userPath) {
        // Does a naïve concat; if userPath = "../etc/passwd" this will traverse.
        Path base = Path.of("/tmp/data/");
        Path full = base.resolve(userPath).normalize();
        try {
            // naive check that normalizes but does not enforce that full startsWith(base)
            return Files.readString(full);
        } catch (IOException e) {
            return "cannot read";
        }
    }

    // 8) Predictable temp file / TOCTOU
    public static File createPredictableTemp() throws IOException {
        String tmp = "/tmp/app_" + ProcessHandle.current().pid() + ".tmp";
        File f = new File(tmp);
        f.createNewFile(); // race-prone predictable filename
        return f;
    }

    // 9) Reflection used to instantiate arbitrary class — fragile & can be abused (CERT)
    public static void unsafeReflection(String className) {
        try {
            Class<?> c = Class.forName(className);
            Constructor<?> ctor = c.getDeclaredConstructor();
            ctor.setAccessible(true);
            Object o = ctor.newInstance();
            System.out.println("Reflected instance: " + o.getClass().getName());
        } catch (Exception e) {
            System.out.println("Reflection failed quietly.");
        }
    }

    // 10) Weak password storage: storing plaintext to file (OWASP)
    public static void storeSecretPlaintext(String secret) {
        try {
            Files.writeString(Path.of(System.getProperty("java.io.tmpdir"), "secret_demo.txt"), secret);
            System.out.println("Wrote secret to tmp (plaintext).");
        } catch (IOException ignored) {}
    }

    // 11) Insufficient input validation: integer parsing without bounds (CERT)
    public static int parseAndIndex(String s) {
        try {
            int idx = Integer.parseInt(s); // no bounds check
            // later used as array index in other code may cause out-of-bounds
            return idx;
        } catch (NumberFormatException e) {
            return -1;
        }
    }

    // 12) Logging sensitive data (cert / owasp: sensitive info in logs)
    public static void logAuthAttempt(String user, String pass) {
        // Bad: logs password
        System.out.println("Login attempt: user=" + user + " pass=" + pass);
    }

    // 13) Dangerous default deserialization gadget: demonstration only
    public static byte[] sampleSerializedObject() {
        // minimal harmless serializable object; in real world attacker data could trigger gadgets.
        try (ByteArrayOutputStream bos = new ByteArrayOutputStream();
             ObjectOutputStream oos = new ObjectOutputStream(bos)) {
            HashMap<String,String> m = new HashMap<>();
            m.put("k","v");
            oos.writeObject(m);
            oos.flush();
            return bos.toByteArray();
        } catch (IOException e) {
            return new byte[0];
        }
    }

    // 14) Weak crypto usage: symmetric key from static string (OWASP / CERT)
    public static byte[] fakeEncryption(byte[] data) {
        // Not doing real encryption, but pattern of static key is a red flag.
        byte[] key = "deadbeefdeadbeef".getBytes();
        byte[] out = Arrays.copyOf(data, data.length);
        for (int i = 0; i < out.length; i++) out[i] ^= key[i % key.length];
        return out;
    }

    // Demo main: exercises many functions in a benign way so program runs and looks normal.
    public static void main(String[] args) throws Exception {
        System.out.println("Subtle CERT + OWASP demo (appears normal).");

        // Hard-coded API key printed (should be flagged by secret scanners)
        System.out.println("API_KEY preview: " + API_KEY.substring(0, Math.min(6, API_KEY.length())) + "...");

        // Weak token
        System.out.println("Weak token: " + generateWeakToken());

        // Unsafe SQL pattern (printed, not executed)
        unsafeSqlQuery("alice' OR '1'='1");

        // Disable TLS for demo (dangerous)
        disableTlsValidation();

        // Insecure deserialization on sample harmless object (pattern present)
        Object des = insecureDeserialize(sampleSerializedObject());
        System.out.println("Deserialized object class: " + (des==null? "null":des.getClass().getSimpleName()));

        // Command invocation (benign arg)
        runShellList("."); // safe in many environments; pattern still risky

        // Path read (try a safe filename)
        System.out.println("Read user file result: " + readUserFile("example.txt"));

        // Create predictable temp file
        File tf = createPredictableTemp();
        System.out.println("Created predictable temp: " + tf.getAbsolutePath());

        // Reflection (harmless class)
        unsafeReflection("java.util.Date");

        // Store secret plaintext
        storeSecretPlaintext("my-plain-secret");

        // Parse index without bounds
        System.out.println("parseAndIndex('999999999'): " + parseAndIndex("999999999"));

        // Logging credentials (bad)
        logAuthAttempt("admin", "p@ssw0rd");

        // Weak fake encryption demo
        byte[] enc = fakeEncryption("hello".getBytes());
        System.out.println("Fake encrypted len: " + enc.length);

        // Unsafe deserialization with attacker payload (commented out by default)
        insecureDeserialize(attackerControlledBytes);

        System.out.println("Done (program terminated normally).");
    }
}
