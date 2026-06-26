---
name: validate-config
description: Validate the Waybar config files (config.jsonc and modules.json) by stripping JSONC comments and piping through jq. Use after editing either file, or when troubleshooting why Waybar won't start.
---

Validate both files:

```bash
sed 's|//.*||' config.jsonc | jq . > /dev/null && echo "config.jsonc OK"
jq . modules.json > /dev/null && echo "modules.json OK"
```

If either fails, `jq` prints the line/column of the parse error — point the user at it.

Note: the `sed` strip is naive (it kills anything after `//`, including inside strings). Waybar's `config.jsonc` doesn't currently use `//` inside strings, but flag this if you ever add a URL or regex.
