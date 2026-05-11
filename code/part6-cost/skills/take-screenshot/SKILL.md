---
name: take-screenshot
description: "Take a screenshot of a URL. Argument: URL"
---

# Take Screenshot

Argument: $ARGUMENTS

## Steps

Run the following script to capture a screenshot:

```bash
npx playwright screenshot --browser chromium \
  "$ARGUMENTS" \
  "screenshots/$(date +%Y%m%d-%H%M%S).png"
```

After capturing, report the file path.
