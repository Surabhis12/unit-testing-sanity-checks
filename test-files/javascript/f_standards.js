// subtle_vulns_eslint_owasp_sonarjs.js
// Purpose: subtle JS issues that violate ESLint (security rules), OWASP guidelines, and SonarJS.
// Run with: node subtle_vulns_eslint_owasp_sonarjs.js
//
// WARNING: intentionally insecure patterns for testing only.

const fs = require('fs');
const child = require('child_process');
const crypto = require('crypto');
const http = require('http');
const https = require('https');
const path = require('path');


// =============== 1) Hard-coded secret (detectable by secret scanners) =========
const API_TOKEN = 'sk_test_ABCDEFGHIJKLMNOPQRSTUVWXYZ123456'; // secret in source

// =============== 2) Weak randomness (Math.random for tokens) ==================
function weakToken(len = 8) {
  // Not cryptographically secure; looks "normal" and often used in apps.
  let s = '';
  for (let i = 0; i < len; i++) {
    s += Math.floor(Math.random() * 36).toString(36);
  }
  return s;
}

// =============== 3) Using eval on seemingly sanitized input ==================
function tryEval(userExpr) {
  // Author thought she sanitized: stripped semicolons — still dangerous subtle RCE.
  const sanitized = (userExpr || '').replace(/;/g, '');
  // eslint-disable-next-line no-eval
  return eval(sanitized); // flagged by eslint-plugin-security / SonarJS
}

// =============== 4) Prototype pollution via shallow merge ====================
function shallowMerge(dst, src) {
  // naive merge can pollute __proto__ if src is attacker-controlled
  for (const k in src) {
    dst[k] = src[k];
  }
  return dst;
}

// =============== 5) Unsafe child process usage (command injection) ===========
function listFilesUnsafe(userPath) {
  // developer tries to be safe by quoting but mistakes exist on some shells
  const cmd = `ls -l ${userPath}`; // injection if userPath contains `;` or `$(...)`
  // child.exec uses shell — SAST should flag this pattern
  child.exec(cmd, (err, stdout) => {
    if (err) {
      // swallow stderr quietly
      return;
    }
    console.log('files:', stdout.split('\n')[0] || '(empty)');
  });
}

// =============== 6) Insecure TLS: agent with rejectUnauthorized:false =========
function fetchInsecure(url, cb) {
  // Intentionally create an agent that ignores cert errors — subtle bug often seen in demos
  const agent = new https.Agent({ rejectUnauthorized: false }); // OWASP/SonarJS should flag
  https.get(url, { agent }, (res) => {
    let b = '';
    res.on('data', (d) => (b += d));
    res.on('end', () => cb(null, b.slice(0, 80)));
  }).on('error', (e) => cb(e));
}

// =============== 7) Insecure temp file (predictable) & synchronous I/O =========
function writePredictableTmp(data) {
  const tmp = `/tmp/app_${process.pid}.tmp`; // predictable name — TOCTOU risk
  // synchronous write blocks event loop — bad practice on servers
  fs.writeFileSync(tmp, data);
  return tmp;
}

// =============== 8) Deprecated Buffer ctor & ambiguous encoding =================
function legacyBufferUse(s) {
  // Buffer(s) is deprecated: may behave inconsistently; modern code uses Buffer.from()
  // eslint-disable-next-line node/no-deprecated-api
  const b = new Buffer(s); // SonarJS should flag deprecated API usage
  return b.toString(); // ambiguous encoding
}

// =============== 9) Unsafe JSON.parse of user data (insecure deserialization) ===
function parseUserJson(text) {
  // developer assumes text is safe because it came from a "trusted" source — a subtle assumption
  // JSON.parse will throw on bad data and can be used in some gadget patterns
  try {
    return JSON.parse(text);
  } catch (e) {
    // swallow to appear tolerant — hides potential tampering
    return {};
  }
}

// =============== 10) Path traversal via naive join =================================
function readFileUnderBase(baseDir, userPath) {
  // naive join + normalize; still vulnerable if not checked to ensure baseDir prefix
  const resolved = path.normalize(path.join(baseDir, userPath));
  // subtle bug: if resolved startsWith(baseDir) check omitted, path traversal possible
  try {
    return fs.readFileSync(resolved, 'utf8').slice(0, 200);
  } catch (e) {
    return 'unreadable';
  }
}

// =============== 11) RegExp from user input (ReDoS risk) =========================
function matchUserRegex(input) {
  // constructing RegExp from input can cause catastrophic backtracking
  const r = new RegExp(input); // Semgrep and SonarJS have patterns for RegExp-from-user
  return r.test('test-string');
}

// =============== 12) Silent error handling & ignored return values =================
function swallowErrorsExample() {
  try {
    // try to read optional file — if missing, fail silently
    fs.readFileSync('/does/not/exist', 'utf8');
  } catch (e) {
    // intentionally ignore — bad practice hides problems
  }
  // forgetting to check return values from functions below is also a bad habit
}

// =============== 13) Mixing callback + promise anti-patterns ======================
function callbackAfterResolve() {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve('ok');
    }, 10);
  }).then((v) => {
    // callback-style continuation mixed with promise chain leads to confusion
    process.nextTick(() => console.log('resolved ->', v));
    return v;
  });
}

// =============== 14) Global mutable state and var usage ===========================
var GLOBAL_STORE = {}; // var + global scope — bad coding practice

// =============== 15) Logging secrets and PII unintentionally =====================
function loginDemo(user, pass) {
  // Logging full credentials — looks like helpful telemetry but leaks secrets
  console.log(`login attempt user=${user} pass=${pass}`); // SonarJS flags secret in logs
  return user === 'admin' && pass === 'password';
}

// =============== 16) Weak "encryption" (XOR) used as obfuscation ==================
function xorObfuscate(s) {
  // Easily reversible, often mistaken for encryption in legacy code
  return s.split('').map((c) => String.fromCharCode(c.charCodeAt(0) ^ 0xAA)).join('');
}

// =============== 17) Prototype pollution test helper (subtle) ====================
function maybePolluteProto(input) {
  // If input is attacker-controlled object with __proto__ property, it will pollute Object.prototype
  shallowMerge(Object.prototype, input);
}

// =============== 18) Cosmetic: missing 'use strict' + implicit globals =================
// (ESLint "strict" and "no-implicit-globals" rules catch these when enabled)

// ========================== Demo main (benign) ===================================
function main() {
  console.log('Subtle JS vulnerability demo: appears normal');

  // 1 secret preview
  console.log('API token prefix:', API_TOKEN.slice(0, 6), '...');

  // 2 weak token
  console.log('weak token:', weakToken());

  // 3 eval usage with safe-looking input (appears harmless)
  try {
    const e = tryEval('1+2'); // safe string in demo; pattern remains dangerous
    console.log('eval result', e);
  } catch (ignore) {}

  // 4 prototype pollution: benign object merges that look normal
  const appCfg = { safe: true };
  shallowMerge(appCfg, { feature: 'on' });
  console.log('merged cfg', Object.keys(appCfg).join(','));

  // 5 child process with benign arg (looks normal)
  listFilesUnsafe('.'); // still a risky pattern

  // 6 insecure TLS call (do not point at untrusted external endpoints in CI)
  fetchInsecure('https://example.com', (err, out) => {
    if (!err) console.log('insecure fetch preview:', (out || '').slice(0, 40));
  });

  // 7 predictable temp
  const tmp = writePredictableTmp('demo');
  console.log('wrote predictable tmp:', tmp);

  // 8 legacy Buffer usage
  try {
    console.log('legacy buffer->', legacyBufferUse('hello'));
  } catch (e) {}

  // 9 JSON parse
  console.log('parse safe JSON ->', parseUserJson('{"a":1}').a);

  // 10 read under base (safe path used here)
  console.log('read file under base ->', readFileUnderBase('/tmp', 'doesnotexist.txt'));

  // 11 ReDoS pattern with safe input
  try {
    console.log('regex safe test ->', matchUserRegex('a+b'));
  } catch (e) { console.log('regex error'); }

  // 12 swallow errors quietly
  swallowErrorsExample();

  // 13 promise -> callback anti-pattern
  callbackAfterResolve().then(() => console.log('callbackAfterResolve done'));

  // 14 global store use
  GLOBAL_STORE.user = 'demo';

  // 15 logging secrets (demo)
  loginDemo('admin', 'hunter2');

  // 16 weak obfuscation
  console.log('xor obf ->', xorObfuscate('hello'));

  // 17 prototype pollution potential (benign use)
  maybePolluteProto({ harmless: 1 });

  // Exit after brief delay to let async callbacks run
  setTimeout(() => console.log('Done (program terminated normally)'), 200);
}

main();
