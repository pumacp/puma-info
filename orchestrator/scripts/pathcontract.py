#!/usr/bin/env python3
"""Resolve a path from a project's root SKILL.md path-contract, else a default.

A project may declare where its sources/outputs/pipeline I/O live in the YAML
frontmatter of its root `SKILL.md` (the "path contract"). This resolver reads a
dotted key from that contract and returns its value, or the supplied default when
the contract is absent, lacks the key, or is malformed. It never raises and has no
third-party dependency (frontmatter is parsed by hand) — so a project WITHOUT a
contract resolves to exactly the built-in default (byte-identical behaviour).

Usage:
    pathcontract.py <project_root> <dotted_key> <default>
e.g.
    pathcontract.py public/demo outputs.docs documents   -> "output/docs" or "documents"
"""
import re
import sys
import pathlib


def _frontmatter(text):
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    out = []
    for ln in lines[1:]:
        if ln.strip() == "---":
            return out          # closed frontmatter block
        out.append(ln)
    return None                 # unterminated -> treat as no contract


def _parse(fm_lines):
    """Flatten one nesting level into dotted keys: {'outputs.docs': 'output/docs'}."""
    flat = {}
    current = None
    for raw in fm_lines:
        line = raw.split("#", 1)[0].rstrip()       # strip trailing comments
        if not line.strip():
            continue
        m = re.match(r"^(\s*)([A-Za-z0-9_]+):\s*(.*)$", line)
        if not m:
            continue
        indent, key, val = m.group(1), m.group(2), m.group(3).strip().strip('"\'')
        if not indent:
            if val:
                flat[key] = val
                current = None
            else:
                current = key
        elif current:
            flat[f"{current}.{key}"] = val
    return flat


def resolve(project_root, dotted_key, default):
    try:
        skill = pathlib.Path(project_root) / "SKILL.md"
        if not skill.is_file():
            return default
        fm = _frontmatter(skill.read_text(encoding="utf-8", errors="ignore"))
        if fm is None:
            return default
        val = _parse(fm).get(dotted_key)
        return val if val else default
    except Exception:
        return default


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print(sys.argv[3] if len(sys.argv) > 3 else "")
    else:
        print(resolve(sys.argv[1], sys.argv[2], sys.argv[3]))
