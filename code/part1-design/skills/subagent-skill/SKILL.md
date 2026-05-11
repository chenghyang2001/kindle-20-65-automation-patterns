---
name: security-audit
description: Run a security audit. Use to check code for vulnerabilities.
context: fork
agent: Explore
allowed-tools: Read, Grep, Glob
---

# Security Audit

Run a security audit:

1. Search all TypeScript files under `src/` using Grep
2. Detect the following patterns:
   - SQL injection (string concatenation in queries)
   - XSS (direct assignment to innerHTML)
   - Hardcoded credentials (password/secret/key = "...")
   - Use of eval()
   - Dangerous regular expressions (potential ReDoS)
3. Report each finding with file path and line number

## Output Format

For each issue, report:
- File path:line number
- Issue type (SQLi / XSS / Hardcoded credential / Other)
- Severity (Critical / High / Medium / Low)
- Suggested fix (1–2 sentences)
