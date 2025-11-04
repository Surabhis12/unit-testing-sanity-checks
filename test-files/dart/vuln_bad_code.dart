// dart_security_bad_practices.dart
// Intentionally insecure + bad-practice examples for testing static analysis and reviews.
// DO NOT USE IN PRODUCTION.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// 1) Hard-coded secret (embedded credential)
const String API_KEY = 'APIKEY-DO-NOT-USE-1234567890'; // secret in source

/// 2) Weak randomness for tokens (not cryptographically secure)
String generateWeakToken() {
  final r = Random(DateTime.now().millisecondsSinceEpoch); // predictable seed
  return List<int>.generate(16, (_) => r.nextInt(256)).join('-');
}

/// 3) Logging sensitive data (bad practice)
void logCredentials(String user, String pass) {
  // prints secrets to console / logs
  print('Login attempt user=$user pass=$pass');
}

/// 4) Unsafe HTTP client: disabling certificate verification
Future<String> fetchInsecure(String url) async {
  final client = HttpClient();
  // Insecure: accepts ANY certificate
  client.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  return await res.transform(utf8.decoder).join();
}

/// 5) Command construction for Process.run (shell injection risk)
Future<void> callShell(String filename) async {
  // Unsafe concatenation passed to shell on some platforms
  // On POSIX it's safer to pass arguments as list; this is showing poor practice.
  await Process.run('sh', ['-c', 'ls -l $filename']);
}

/// 6) SQL-like injection via string interpolation (for demo only)
String buildSql(String username) {
  // BAD: concatenating user input directly into SQL string
  return "SELECT * FROM users WHERE username = '$username';";
}

/// 7) Unsafe JSON deserialization into dynamic and using as cast
Map parseUserJson(String jsonStr) {
  // Using dynamic map without validation
  final dynamic decoded = json.decode(jsonStr);
  // Dangerous cast, may throw or allow malicious structure
  return decoded as Map;
}

/// 8) Silently catching and swallowing exceptions (lost errors)
void swallowErrors() {
  try {
    throw FormatException('boom');
  } catch (e) {
    // Bad: no logging, no rethrow, hides failure
  }
}

/// 9) Unawaited futures (fire-and-forget) causing surprising lifecycle behavior
void fireAndForget() {
  Future.delayed(Duration(seconds: 1), () => print('delayed'));
  // not awaited or tracked — OK in some contexts but often a bug
}

/// 10) Using `!` (force unwrap) unsafely with nullable types
int forceUnwrap(Map<String, int>? m) {
  // Will throw if m is null or key missing
  return m!['value']! + 1;
}

/// 11) Mutable global state (bad for concurrency and testing)
List<String> _globalCache = []; // should be encapsulated / immutable / synchronized

void mutateGlobal(String v) {
  _globalCache.add(v); // no synchronization, no validation
}

/// 12) Using `dynamic` and `as` casts to hide types (fragile)
int dangerousCast(dynamic x) {
  // developer assumes x is int but may be something else
  return (x as int) + 1;
}

/// 13) Poor file handling: predictable temp filename & race
File insecureTempWrite(String content) {
  final name = '/tmp/dart_demo_${DateTime.now().millisecondsSinceEpoch}.tmp';
  final f = File(name);
  // No atomic creation; TOCTOU possible
  f.writeAsStringSync(content);
  return f;
}

/// 14) Weak "obfuscation" of secrets (not encryption)
String xorObfuscate(String s) {
  final bytes = utf8.encode(s);
  return base64.encode(bytes.map((b) => b ^ 0xAA).toList());
}

/// 15) Unchecked user input for regexp / ReDoS potential
bool matchPattern(String input) {
  // crazy complex regex from input could be heavy — here we misuse user input
  final pattern = RegExp(input); // building regex from user-controlled string
  return pattern.hasMatch('test');
}

/// Driver that exercises some functions — call functions deliberately during tests
Future<void> main() async {
  print('Demo: Dart insecure patterns and bad practices');

  // 1
  print('Hardcoded API key: $API_KEY');

  // 2
  print('Weak token: ${generateWeakToken()}');

  // 3
  logCredentials('admin', 's3cr3t');

  // 4 - do not call with untrusted urls in CI unless sandboxed
  print(await fetchInsecure('https://plode.org'));

  // 5 - unsafe call example (commented out by default)
  await callShell('; echo hacked >/tmp/hacked.txt');

  // 6
  print(buildSql("alice'; DROP TABLE users; --"));

  // 7
  try {
    final m = parseUserJson('{"name": "bob"}');
    print('Parsed name: ${m['name']}');
  } catch (e) {
    print('parse error: $e');
  }

  // 8
  swallowErrors();

  // 9
  fireAndForget();

  // 10: force unwrap demo (catch exception so program continues)
  try {
    print('force unwrap: ${forceUnwrap(null)}');
  } catch (e) {
    print('force unwrap failed: $e');
  }

  // 11
  mutateGlobal('one');
  print('global cache size: ${_globalCache.length}');

  // 12
  try {
    print('dangerous cast: ${dangerousCast("not-an-int")}');
  } catch (e) {
    print('cast failed: $e');
  }

  // 13
  final tmp = insecureTempWrite('sensitive-data');
  print('wrote temp: ${tmp.path}');

  // 14
  print('xor obf: ${xorObfuscate("secret")}');

  // 15
  try {
    print('regex match: ${matchPattern('(a+)+\$')}');
  } catch (e) {
    print('regex error: $e');
  }
}
