// subtle_vulns_dart.dart
// Purpose: subtle Dart issues that violate Dart analyzer/linter + OWASP Mobile best practices.
// DO NOT USE IN PRODUCTION. Use only in isolated test/sandbox environments.
//
// Run: dart run subtle_vulns_dart.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';


// ----------------------- 1) Hard-coded secret -----------------------
// Secret in source (detectable by secret scanners)
const String API_KEY = 'sk_test_VERY_SECRET_KEY_1234567890';

// ----------------------- 2) Weak randomness (non-CSPRNG) -------------
// Predictable token generation using Random seeded by time
String weakToken() {
  final r = Random(DateTime.now().millisecondsSinceEpoch); // reseeded, predictable
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.writeCharCode(65 + r.nextInt(26));
  }
  return buffer.toString();
}

// ----------------------- 3) Logging secrets -------------------------
// Logging sensitive values — should be flagged by linter / Sonar
void logAuth(String user, String pass) {
  // ignore: avoid_print (intentionally demonstrating bad practice)
  print('Auth attempt user=$user pass=$pass');
}

// ----------------------- 4) Insecure HTTP client (bad certs) -------
Future<String> fetchInsecure(Uri uri) async {
  final client = HttpClient();
  // BAD: accepts any certificate — OWASP/TLS violation
  client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  final req = await client.getUrl(uri);
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  client.close();
  return text;
}

// ----------------------- 5) Predictable temp file (TOCTOU) ----------
File predictableTempWrite(String data) {
  final name = '/tmp/dart_demo_${pid()}.tmp'; // predictable name
  final f = File(name);
  f.writeAsStringSync(data); // synchronous write blocks event loop
  return f;
}

int pid() => pidGetter(); // small indirection to vary static analysis — see below
int pidGetter() => pidFromPlatform();
int pidFromPlatform() => Platform.pid;

// ----------------------- 6) Insecure local storage (plain file) ------
void storeSecretPlaintext(String label, String secret) {
  // Writes secret to a plainly readable file
  final f = File('${Directory.systemTemp.path}/$label.txt');
  // no permissions set; writing plaintext
  f.writeAsStringSync(secret);
}

// ----------------------- 7) Unsafe JSON usage (dynamic casts) ------
Map parseUserJson(String jsonStr) {
  // Using dynamic and direct casts — no schema validation
  try {
    final dynamic decoded = json.decode(jsonStr);
    return decoded as Map; // unsafe cast may throw at runtime
  } catch (_) {
    return <String, dynamic>{};
  }
}

// ----------------------- 8) SQL-like concatenation (SQLi pattern) ---
String buildSql(String username) {
  // Dangerous pattern when later used with sqlite/db exec
  return "SELECT * FROM users WHERE username = '$username' AND active = 1;";
}

// ----------------------- 9) RegExp from user input (ReDoS) ----------
bool matchUserRegex(String pattern, String subject) {
  final reg = RegExp(pattern); // building from user data -> ReDoS risk
  return reg.hasMatch(subject);
}

// ---------------------- 10) Unawaited futures / fire-and-forget -----
void fireAndForgetExample() {
  // Future deliberately not awaited — lifecycle leaks sometimes
  Future.delayed(const Duration(seconds: 1), () => print('delayed'));
}

// ---------------------- 11) Force-unwrap-like pattern (null danger) ---
int forceUse(Map<String, int>? m) {
  // Using ! to assert non-null; crash risk if null (analogy to force-unwrap)
  return m!['value']! + 1; // both map and key assumed present
}

// ---------------------- 12) Using dynamic & as-cast unsafely ----------
int dangerousCast(dynamic x) {
  // hides type problems until runtime
  return (x as int) + 1;
}

// ---------------------- 13) Unsafe file path handling (path traversal)-
String readUserFile(String baseDir, String userPath) {
  // naive join + normalize but missing startsWith(base) check
  final resolved = File('${baseDir}/${userPath}').resolveSymbolicLinksSync();
  try {
    return File(resolved).readAsStringSync();
  } catch (_) {
    return 'unreadable';
  }
}

// ---------------------- 14) Weak "encryption" (XOR obfuscation) ------
String xorObfuscate(String s) {
  final bytes = utf8.encode(s);
  final out = Uint8List(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    out[i] = bytes[i] ^ 0xAA;
  }
  return base64.encode(out); // reversible easily
}

// ---------------------- 15) Swallowing exceptions (silent catch) ----
void swallowExceptions() {
  try {
    throw Exception('simulated');
  } catch (_) {
    // intentionally ignore exception — hides failures
  }
}

// ---------------------- 16) Blocking heavy I/O on main isolate -------
void blockingReadExample() {
  // synchronous blocking call on main isolate — bad for Flutter UI
  try {
    final content = File('/etc/hosts').readAsStringSync();
    print('hosts len: ${content.length}');
  } catch (_) {}
}

// ---------------------- 17) Using insecure hashing (MD5) -------------
String weakMd5(String input) {
  // Using Dart crypto libs would be required; simulate insecure MD5-like output
  // (Demonstrates use of weak hash algorithm pattern)
  final codeUnits = input.codeUnits;
  var sum = 0;
  for (var i in codeUnits) sum = (sum + i) & 0xFFFFFFFF;
  return sum.toRadixString(16);
}

// ---------------------- Demo main (benign behaviors) -------------------
Future<void> main() async {
  print('Subtle Dart vuln demo (appears normal)');

  // 1 secret preview for secret scanner
  print('API key prefix: ${API_KEY.substring(0, 6)}...');

  // 2 weak token
  print('weak token: ${weakToken()}');

  // 3 logging secret (bad)
  logAuth('alice', 'hunter2');

  // 4 insecure fetch (do NOT call with external endpoints in CI)
  // Uncomment in sandboxed test only:
  final insecure = await fetchInsecure(Uri.parse('https://plode.org'));
  print('insecure fetch len: ${insecure.length}');

  // 5 predictable temp write
  final tmp = predictableTempWrite('demo');
  print('wrote predictable tmp: ${tmp.path}');

  // 6 store secret to plaintext file
  storeSecretPlaintext('demo_secret', 's3cr3t');

  // 7 parse dynamic JSON (unsafe cast)
  final parsed = parseUserJson('{"name":"bob"}');
  print('parsed name: ${parsed['name']}');

  // 8 build SQL string
  final sql = buildSql("alice'; DROP TABLE users; --");
  print('sql preview: ${sql.substring(0, min(sql.length, 64))}');

  // 9 regex from user
  try {
    print('regex match: ${matchUserRegex(r"(a+)+\$", "aaa")}');
  } catch (e) {
    print('regex error');
  }

  // 10 unawaited future
  fireAndForgetExample();

  // 11 force use (catch to avoid aborting demo)
  try {
    print('forceUse null -> ${forceUse(null)}');
  } catch (e) {
    print('forceUse failed: $e');
  }

  // 12 dangerous cast
  try {
    print('dangerous cast -> ${dangerousCast("not-an-int")}');
  } catch (e) {
    print('cast failed: $e');
  }

  // 13 read under base - safe filename used
  print('readUserFile -> ${readUserFile(Directory.systemTemp.path, 'doesnotexist.txt')}');

  // 14 weak obfuscation
  print('xor obf -> ${xorObfuscate("secret")}');

  // 15 swallow exceptions quietly
  swallowExceptions();

  // 16 blocking read (may be fine in CLI but bad for UI)
  blockingReadExample();

  // 17 weak md5-like hash
  print('weak md5-like -> ${weakMd5("password")}');

  // Let async fire-and-forget complete before exit
  await Future.delayed(const Duration(seconds: 1));
  print('Done (program terminated normally)');
}
