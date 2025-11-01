// KotlinSubtleVulns.kt
// Purpose: subtle Kotlin examples that violate JetBrains style + CERT Java + OWASP + SonarKotlin.
// DO NOT USE IN PRODUCTION. Use only in isolated test/sandbox environments.

import java.io.*
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import java.security.SecureRandom
import java.security.cert.X509Certificate
import java.time.Instant
import java.util.*
import javax.net.ssl.*

// ------------------ 1) Hard-coded secret (should be detected by secret scanners) ------------
private const val API_KEY = "AKIA_VERY_SECRET_EXAMPLE_1234567890"

// ------------------ 2) Weak token generation (predictable / non-CSPRNG) -------------------
fun generateWeakToken(): String {
    // Using java.util.Random seeded with time — weak and predictable
    val r = Random(System.currentTimeMillis() xor this.hashCode().toLong())
    val sb = StringBuilder()
    repeat(16) { sb.append("0123456789ABCDEF"[r.nextInt(16)]) }
    return sb.toString()
}

// ------------------ 3) Logging secrets (bad practice) ------------------------------------
fun logLogin(user: String, pass: String) {
    // prints plain password to logs — should be flagged by SonarKotlin / OWASP rules
    println("Login attempt user=$user pass=$pass")
}

// ------------------ 4) SQL built by concatenation (SQL Injection) -------------------------
fun unsafeSqlQuery(username: String): String {
    // concatenation pattern — vulnerable to SQL injection if later executed
    val sql = "SELECT * FROM users WHERE username = '$username' AND enabled=1;"
    println("Generated SQL (unsafe): $sql")
    return sql
}

// ------------------ 5) Insecure TLS: naive TrustManager that accepts all certs ------------
fun disableTlsValidation() {
    try {
        val trustAll = arrayOf<TrustManager>(object : X509TrustManager {
            override fun getAcceptedIssuers(): Array<X509Certificate> = arrayOf()
            override fun checkClientTrusted(chain: Array<X509Certificate>, authType: String) {}
            override fun checkServerTrusted(chain: Array<X509Certificate>, authType: String) {}
        })
        val sc = SSLContext.getInstance("TLS")
        sc.init(null, trustAll, SecureRandom())
        HttpsURLConnection.setDefaultSSLSocketFactory(sc.socketFactory)
        HttpsURLConnection.setDefaultHostnameVerifier { _, _ -> true }
        println("TLS validation disabled (demo).")
    } catch (e: Exception) {
        // intentionally swallow
    }
}

// ------------------ 6) Insecure deserialization (CERT: untrusted deserialization) ----------
fun insecureDeserialize(data: ByteArray): Any? {
    // No class allowlist or validation — classic pattern for gadget exploitation
    return try {
        ObjectInputStream(ByteArrayInputStream(data)).use { it.readObject() }
    } catch (t: Throwable) {
        null
    }
}

// helper to produce a harmless serialized object for demo
fun sampleSerializedMap(): ByteArray {
    return ByteArrayOutputStream().use { bos ->
        ObjectOutputStream(bos).use { oos ->
            val m = HashMap<String, String>()
            m["k"] = "v"
            oos.writeObject(m)
            oos.flush()
            bos.toByteArray()
        }
    }
}

// ------------------ 7) Predictable temp file (TOCTOU) ------------------------------------
fun createPredictableTempFile(): File {
    val path = "${System.getProperty("java.io.tmpdir")}/app_temp_${ProcessHandle.current().pid()}.tmp"
    val f = File(path)
    try {
        f.createNewFile()
        f.writeText("temporary")
    } catch (e: IOException) {
        // swallow for demo
    }
    return f
}

// ------------------ 8) Weak "encryption" / obfuscation (NOT crypto) -----------------------
fun xorObfuscate(s: String): String {
    val key = 0xAA.toByte()
    return s.toByteArray().map { (it xor key).toInt().and(0xFF) }.toByteArray().toString(Charsets.ISO_8859_1)
}

// ------------------ 9) ReDoS pattern: build RegExp from user input ------------------------
fun matchUserRegex(pattern: String, input: String): Boolean {
    // Constructing regex from untrusted input may lead to ReDoS
    val r = Regex(pattern)
    return r.containsMatchIn(input)
}

// ------------------ 10) Unsafe cast and force-unwrap (!!) --------------------------------
fun unsafeCastExample(any: Any?): Int {
    // risky cast and force unwrap can throw runtime exceptions (as! / as? in Kotlin)
    // using as (unsafe) and !! (force unwrap) — SonarKotlin/JetBrains rules will flag
    val s = any as String
    return s.length // if any was null or not string, ClassCastException/NullPointerException
}

// ------------------ 11) Swallowing exceptions silently (bad error handling) --------------
fun swallowErrors() {
    try {
        throw IllegalStateException("simulated")
    } catch (_: Exception) {
        // intentionally empty — hides problems
    }
}

// ------------------ 12) Blocking IO on main thread (bad practice for UI / servers) -------
fun blockingReadExample() {
    // reading big file synchronously on main thread
    try {
        val content = File("/etc/hosts").readText() // may block on some platforms
        println("hosts len: ${content.length}")
    } catch (e: Exception) {
        // ignore
    }
}

// ------------------ 13) Deprecated / insecure hash (MD5) usage --------------------------
fun weakMd5(s: String): String {
    val md = MessageDigest.getInstance("MD5")
    val digest = md.digest(s.toByteArray())
    return digest.joinToString("") { "%02x".format(it) } // MD5 is insecure
}

// ------------------ 14) Predictable token using time + weak RNG -------------------------
fun predictableToken(): String {
    val rnd = Random(System.currentTimeMillis())
    return (Instant.now().epochSecond.toString() + "-" + rnd.nextInt().toString())
}

// ------------------ 15) Reflection misuse -------------------------------------------------
fun unsafeReflection(className: String) {
    try {
        val c = Class.forName(className)
        val ctor = c.getDeclaredConstructor()
        ctor.isAccessible = true
        val o = ctor.newInstance()
        println("Reflected instance: ${o.javaClass.name}")
    } catch (t: Throwable) {
        // hide failure quietly
    }
}

// ------------------ 16) Path traversal via naive concat --------------------------------
fun readUnderBase(base: File, userPath: String): String {
    // naive use of File(base, userPath) without proper normalization/allowlist
    val f = File(base, userPath)
    return try {
        f.readText().take(200)
    } catch (e: Exception) {
        "unreadable"
    }
}

// ------------------ 17) Global mutable state (bad practice) ----------------------------
var GLOBAL_CACHE: MutableMap<String, String> = HashMap()

// ------------------ 18) Command invocation using Runtime.exec (command injection) -------
fun execList(userArg: String) {
    // passes string through shell; dangerous if userArg contains metacharacters
    try {
        val cmd = arrayOf("sh", "-c", "ls -l $userArg")
        val p = Runtime.getRuntime().exec(cmd)
        BufferedReader(InputStreamReader(p.inputStream)).use { br ->
            val line = br.readLine()
            if (line != null) println("ls -> $line")
        }
    } catch (e: Exception) {
        // swallow
    }
}

// ------------------ Demo main: exercise functions benignly ----------------------------
fun main() {
    println("Kotlin subtle vulnerability demo (appears normal)")

    // 1: secret preview (should be flagged by secret scanners)
    println("API key prefix: ${API_KEY.take(6)}...")

    // 2: weak token
    println("weak token: ${generateWeakToken()}")

    // 3: logging secrets (unsafe)
    logLogin("admin", "p@ssw0rd")

    // 4: unsafe SQL pattern (only prints)
    unsafeSqlQuery("alice' OR '1'='1")

    // 5: disable TLS — dangerous; used to ensure pattern is present
    disableTlsValidation()

    // 6: insecure deserialization using benign sample
    val des = insecureDeserialize(sampleSerializedMap())
    println("deserialized class: ${des?.javaClass?.name ?: "null"}")

    // 7: predictable temp file
    val tmp = createPredictableTempFile()
    println("created predictable temp: ${tmp.absolutePath}")

    // 8: weak obfuscation demonstration
    println("xor obf len: ${xorObfuscate("secret").length}")

    // 9: ReDoS-like pattern - safe short pattern provided
    try {
        println("regex match? " + matchUserRegex("a+b", "aaab"))
    } catch (e: Exception) {
        println("regex error")
    }

    // 10: unsafe cast example — call in try to avoid crash in demo
    try {
        println("unsafeCastExample -> ${unsafeCastExample("hello")}")
    } catch (t: Throwable) {
        println("unsafeCastExample failed: ${t.javaClass.simpleName}")
    }

    // 11: swallowErrors (silent)
    swallowErrors()

    // 12: blocking IO (may be fine in CI but is bad practice)
    blockingReadExample()

    // 13: weak MD5 hash
    println("md5('test'): ${weakMd5("test")}")

    // 14: predictable token
    println("predictable token: ${predictableToken()}")

    // 15: reflection (harmless class)
    unsafeReflection("java.util.Date")

    // 16: path traversal demo (reads under /tmp using safe filename)
    println("readUnderBase /tmp safe -> ${readUnderBase(File("/tmp"), "does-not-exist.txt")}")

    // 17: global mutable state usage
    GLOBAL_CACHE["k"] = "v"
    println("global cache size: ${GLOBAL_CACHE.size}")

    // 18: execList with benign arg (pattern present)
    execList(".") // still a risky pattern

    println("Done (program terminated normally).")
}
