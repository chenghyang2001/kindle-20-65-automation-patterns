---
name: legacy-system-context
description: Background and constraints of the legacy system. Use when working on tasks related to this system.
user-invocable: false
---

# Legacy Payment System Background

This system was built in 2008. It has the following constraints:
- Session management is file-based (no database)
- Character encoding is Shift-JIS
- PHP 5.6 compatibility required (no modern PHP features)
- External API integration via XML-RPC only

## Important Notes

- `payment_processor.php` must not be modified (under PCI DSS audit)
- Do not write directly under the `session/` directory
- Logs must be written to `logs/legacy/`

## Common Issues

- Character corruption: always pass all input/output through `mb_convert_encoding()`
- Session expiry: 30-minute timeout is configured
