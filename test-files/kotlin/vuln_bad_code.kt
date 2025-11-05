// KotlinSecurityBadPractices.kt
// Intentionally insecure & poor-quality code for testing static analysis tools.
// DO NOT USE IN PRODUCTION.

import java.io.File
import java.io.BufferedReader
import java.io.InputStreamReader
import java.net.HttpURLConnection
import java.net.URL
import java.security.MessageDigest
import kotlin.random.Random
import javax.crypto.Cipher
import javax.crypto.spec.SecretKeySpec


// 1) Hardcoded secret key (should never appear in code)
const val SECRET_KEY = "MySuperSecretKey123" // ⚠️ Vulnerability: hardcoded credential

// 2) Weak random token generator (not cryptographically secure)
fun generateWeakToken(): String {
    val rand = Random(System.currentTimeMillis()) // predictable seed
    return (1..16).joinToString("") { rand.nextInt(0, 9).toString() }
}

// 3) Logging sensitive data (should be sanitized)
fun logUserLogin(username: String, password: String) {
    println("User login attempt: $username / $password") // ⚠️ Exposes credentials
}

// 4) Disabling SSL certificate verification (insecure network)
fun fetchInsecure(url: String): String {
    val connection = URL(url).openConnection() as HttpURLConnection
    connection.connectTimeout = 1000
    connection.doInput = true
    // ⚠️ Insecure: ignoring all SSL checks (only for demonstration)
    if (connection is javax.net.ssl.HttpsURLConnection) {
        connection.hostnameVerifier = javax.net.ssl.HostnameVerifier { _, _ -> true }
    }
    return connection.inputStream.bufferedReader().use(BufferedReader::readText)
}

// 5) Command injection via Runtime.exec
fun runCommand(userInput: String) {
    val cmd = "ls $userInput" // ⚠️ user input directly in shell command
    val process = Runtime.getRuntime().exec(cmd)
    process.inputStream.bufferedReader().forEachLine { println(it) }
}

// 6) SQL Injection via string concatenation
fun buildQuery(username: String): String {
    // ⚠️ BAD: concatenating user input directly into SQL
    return "SELECT * FROM users WHERE username = '$username';"
}

// 7) Swallowing exceptions (silently ignoring errors)
fun swallowError() {
    try {
        throw RuntimeException("Something failed")
    } catch (e: Exception) {
        // ⚠️ Ignored silently — hides bugs and attacks
    }
}

// 8) Weak password hashing (MD5)
fun weakHash(password: String): String {
    // ⚠️ Deprecated insecure hash function
    val md = MessageDigest.getInstance("MD5")
    return md.digest(password.toByteArray()).joinToString("") { "%02x".format(it) }
}

// 9) Insecure "custom encryption" (XOR-based obfuscation)
fun xorEncrypt(data: String): String {
    val key = 0xAA
    return data.map { (it.code xor key).toChar() }.joinToString("")
}

// 10) Predictable temp file creation (TOCTOU vulnerability)
fun createTempFileInsecure(): File {
    val f = File("/tmp/kotlin_${System.currentTimeMillis()}.tmp") // predictable name
    f.writeText("Sensitive data here")
    return f
}

// 11) Blocking I/O on main thread (bad practice in Android / coroutines)
fun readBlocking() {
    val content = File("/etc/hosts").readText() // ⚠️ Blocking I/O
    println(content)
}

// 12) Unsafe cast (ClassCastException risk)
fun unsafeCast(obj: Any): String {
    return obj as String // ⚠️ May throw ClassCastException at runtime
}

// 13) Mutable global state (not thread-safe)
var globalCounter = 0 // ⚠️ Global mutable state, not synchronized

fun incrementGlobal() {
    globalCounter++ // race conditions possible
}

// 14) Unvalidated user input used in regex (ReDoS)
fun regexFromUser(input: String): Boolean {
    val regex = Regex(input) // ⚠️ User-controlled regex = potential ReDoS
    return regex.containsMatchIn("test")
}

// 15) Deprecated crypto usage (AES/ECB)
fun badEncryption(data: String): ByteArray {
    // ⚠️ ECB mode provides no IV, easily attacked
    val keySpec = SecretKeySpec(SECRET_KEY.toByteArray(), "AES")
    val cipher = Cipher.getInstance("AES/ECB/PKCS5Padding")
    cipher.init(Cipher.ENCRYPT_MODE, keySpec)
    return cipher.doFinal(data.toByteArray())
}

fun main() {
    println("Weak token: ${generateWeakToken()}")
    logUserLogin("admin", "1234")

    println("MD5 hash: ${weakHash("password")}")

    // Comment these in only in sandbox!
    fetchInsecure("https://plode.org")
    runCommand("; rm -rf /") 

    println(buildQuery("alice'; DROP TABLE users;--"))
    swallowError()
    println("Encrypted: ${xorEncrypt("secret")}")
    println("Temp file: ${createTempFileInsecure().absolutePath}")
    println("Unsafe cast result: ${unsafeCast(123)}") // runtime error
}
