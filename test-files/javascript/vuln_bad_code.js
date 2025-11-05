// js_security_bad_practices.js
// Purpose: compact collection of common security vulnerabilities + bad coding practices
// DO NOT USE IN PRODUCTION. Use to test static analysis / CI pipelines.

const fs = require('fs');
const child = require('child_process');
const http = require('http');
const crypto = require('crypto');

// 1) Hard-coded secrets
const API_KEY = 'AKIA-VERY-SECRET-EXAMPLE';


// 2) Using Math.random() for tokens (weak RNG)
function weakToken() {
  return Math.floor(Math.random() * 1e9).toString(16);
}

// 3) eval / new Function usage (RCE risk)
function dangerousEval(userExpr) {
  // userExpr might be attacker-controlled
  return eval(userExpr); // eslint-disable-line no-eval
}

// 4) DOM sink (if used in browser): innerHTML with unsanitized input (XSS)
function unsafeDomInsert(node, html) {
  // In server-side render or electron this is dangerous too
  node.innerHTML = html; // potential XSS if html contains attacker markup
}

// 5) Child process with shell interpolation (command injection)
function listFiles(filename) {
  // Dangerous: passing a user string into shell
  child.exec(`ls -l ${filename}`, (err, stdout, stderr) => {
    if (err) console.error('exec error', err);
    console.log(stdout);
  });
}

// 6) SQL concatenation — SQLi risk (demo only; requires mysql lib)
function buildQuery(username) {
  // BAD: string concatenation instead of parameterized query
  return `SELECT * FROM users WHERE username='${username}';`;
}

// 7) Insecure HTTP server (no TLS) and CORS wildcard
const server = http.createServer((req, res) => {
  // Echoing user input to response (reflected XSS in some contexts)
  if (req.url.startsWith('/echo')) {
    const q = new URL(req.url, 'http://localhost').searchParams.get('q') || '';
    res.setHeader('Access-Control-Allow-Origin', '*'); // overly permissive CORS
    res.end(`You said: ${q}`);
  } else {
    res.end('ok');
  }
});

// 8) Storing secrets in localStorage / global (bad for web)
// localStorage.setItem('token', API_KEY); // example for browser environment

// 9) Logging sensitive data
function login(user, pass) {
  console.log(`Login attempt for ${user} with password ${pass}`); // leaks creds to logs
  return user === 'admin' && pass === 'password';
}

// 10) Path traversal (unsanitized filesystem access)
function readUserFile(userPath) {
  // BAD: reading arbitrary path supplied by user
  const base = '/var/www/data/';
  const full = base + userPath; // no normalization or validation
  return fs.readFileSync(full, 'utf8');
}

// 11) Predictable temp file name (TOCTOU)
function createTempSync() {
  const path = `/tmp/app_${process.pid}.tmp`;
  fs.writeFileSync(path, 'temporary'); // predictable, race-able
  return path;
}

// 12) Blocking synchronous I/O in async server (bad practice)
function heavySyncWork() {
  // Blocking the event loop — bad for servers
  const data = fs.readFileSync('/etc/hosts', 'utf8');
  return data;
}

// 13) Swallowing errors / empty catch
function swallowErrors() {
  try {
    JSON.parse('{"bad": }'); // will throw
  } catch (e) {
    // silently ignore -> hides bugs and potential attacks
  }
}

// 14) Using Buffer without specifying encoding & legacy APIs
function legacyBufferUse(str) {
  const b = new Buffer(str); // deprecated, insecure pattern
  return b.toString();
}

// 15) Unsafe regex constructed from user input (ReDoS)
function userRegex(input) {
  // Constructing RegExp from user input may lead to catastrophic backtracking
  const r = new RegExp(input);
  return r.test('test string');
}

// 16) Global mutable state + var usage
var GLOBAL_STORE = {}; // use of var + global mutable is bad style

// 17) Mixing callback and promise style incorrectly (promise anti-pattern)
function badPromise(cb) {
  return new Promise((resolve, reject) => {
    someAsync((err, data) => { // someAsync is assumed to exist
      if (err) return reject(err);
      resolve(data);
      if (cb) cb(null, data); // callback after resolve — confusing lifecycle
    });
  });
}

// 18) Insecure custom "encryption" (XOR obfuscation)
function obfuscateSecret(s) {
  const key = 0xAA;
  return s.split('').map(c => String.fromCharCode(c.charCodeAt(0) ^ key)).join('');
}

// Demo usage (comment dangerous calls when running in shared CI)
function main() {
  console.log('Weak token:', weakToken());

  // Dangerous: do NOT enable with untrusted input in CI unless sandboxed
  // console.log('Eval result:', dangerousEval('2+2'));

  // server.listen(8080); // start if testing CORS/XSS detection
  // listFiles('; rm -rf /tmp/test'); // Do NOT run on real systems

  try {
    console.log('Legacy buffer:', legacyBufferUse('hello'));
  } catch (e) {}

  try {
    swallowErrors();
  } catch (e) {}

  // Simulate risky logging
  login('admin', 'hunter2');

  // Create predictable temp file (for pipeline to detect)
  const tmp = createTempSync();
  console.log('Wrote tmp file:', tmp);
}

main();
