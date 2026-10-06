import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const generated = new Set([
  ".git",
  "node_modules",
  "build",
  "build-e2e",
  "test-results",
  "playwright-report",
  ".dart_tool",
  "Pods",
  ".gradle",
  ".symlinks",
  "ephemeral",
  "bin",
  "obj",
  "TestResults",
  "xcuserdata",
]);
const rules = [
  ["Stripe credential", /\b(?:sk|rk|pk)_(?:live|test)_[A-Za-z0-9]{20,}\b/],
  ["Mapbox token", /\b[ps]k\.eyJ[A-Za-z0-9_.-]{40,}/],
  ["Google API key", /\bAIza[A-Za-z0-9_-]{30,}/],
  [
    "GitHub credential",
    /\b(?:gh[pousr]_[A-Za-z0-9]{25,}|github_pat_[A-Za-z0-9_]{30,})/,
  ],
  ["AWS access identifier", /\b(?:AKIA|ASIA)[A-Z0-9]{16}\b/],
  ["Private key", /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/],
  ["Credential-bearing URL", /https?:\/\/[^\s/:]+:[^\s/@]+@/],
  [
    "Database password",
    /(?:Host|Server|Data Source)=[^\n]*;(?:[^\n]*;)?(?:Password|Pwd)=[^;\s"']{8,}/i,
  ],
];
const findings = [];
let files = 0;
function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (generated.has(entry.name)) continue;
    const absolute = path.join(directory, entry.name);
    const relative = path.relative(root, absolute);
    if (entry.isSymbolicLink()) {
      findings.push({ file: relative, issue: "Unexpected symlink" });
      continue;
    }
    if (entry.isDirectory()) {
      walk(absolute);
      continue;
    }
    if (!entry.isFile()) continue;
    files++;
    if (
      (/^\.env/.test(entry.name) && entry.name !== ".env.example") ||
      /(?:^local\.json$|\.p12$|\.p8$|\.pem$|\.keystore$|\.jks$|\.mobileprovision$|\.pubxml(?:\.user)?$)/.test(
        entry.name
      )
    ) {
      findings.push({
        file: relative,
        issue: "Local configuration or credential file",
      });
    }
    const buffer = fs.readFileSync(absolute);
    if (buffer.includes(0)) continue;
    buffer
      .toString("utf8")
      .split("\n")
      .forEach((line, index) => {
        if (/REPLACE_WITH_|replace_me|example\.invalid/.test(line)) return;
        for (const [issue, regex] of rules) {
          if (regex.test(line))
            findings.push({ file: relative, line: index + 1, issue });
        }
      });
  }
}
walk(root);
console.log(
  JSON.stringify(
    {
      files,
      findings,
      scope: "Pattern preflight, not a complete security or rights audit.",
    },
    null,
    2
  )
);
process.exitCode = findings.length ? 1 : 0;
