# fx skill discovery on Omarchy

## Symptom

fx reports six skill discovery issues at startup:

```text
Skills: 6 discovery issues; some skills may be missing
```

The generated model context includes:

```xml
<skill_discovery_warning skipped_candidate_count="6" incomplete_root_count="0" missing_from_incomplete_roots="0" />
```

## Cause

Omarchy exposes the `diagnose-crash` and `omarchy` skills through symlinks in
three fx-compatible user roots:

```text
~/.agents/skills/
~/.claude/skills/
~/.codex/skills/
```

All six links resolve outside the home directory to:

```text
/usr/share/omarchy/default/agents/skills/
```

fx 0.0.6 rejects these external links unless their target is explicitly added
to `FX_SKILL_SYMLINK_AUTHORITIES`. With skill tracing enabled, each warning has
the cause `linked_candidate_unavailable`. The `SKILL.md` files themselves are
valid.

## Fix

Authorize the read-only Omarchy skill directory before starting fx:

```bash
export FX_SKILL_SYMLINK_AUTHORITIES=/usr/share/omarchy/default/agents/skills
fx
```

Add the export to the shell startup configuration to persist it. The variable
accepts colon-separated absolute paths when more than one external skill root is
needed.

To diagnose similar problems, launch fx with skill tracing:

```bash
FX_TRACE=1 FX_TRACE_STDERR=1 FX_TRACE_SCOPES=skills fx
```

Relevant documentation: [fx skills](https://fx.sh/docs/capabilities/skills).
