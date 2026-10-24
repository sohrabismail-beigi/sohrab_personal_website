#!/usr/bin/env python3
"""Generate latin/index.md (the web page version) from files/latinwords.tex.

Run from the repository root after editing the .tex file:

    python3 _scripts/latin_to_markdown.py
"""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEX = ROOT / "files" / "latinwords.tex"
OUT = ROOT / "latin" / "index.md"

HEADER = """---
title: Latin words and phrases
description: About 350 Latin words and phrases with their meanings, from ab initio to vulgo.
---
{% comment %}
  Generated from files/latinwords.tex by _scripts/latin_to_markdown.py.
  Edit the .tex file and rerun the script instead of editing this page.
{% endcomment %}

# Latin words and phrases

About 350 Latin words and phrases with their meanings, from *ab initio* to *vulgo*. This was a fun project that started with a few words and then got out of hand :-)

Also available as a [PDF](../files/latinwords.pdf) and as [LaTeX source](../files/latinwords.tex).

"""


def ligatures(text, cmd, char):
    text = text.replace("{\\%s}" % cmd, char)                          # {\ae}
    text = re.sub(r"\\%s\{([^{}]*)\}" % cmd, lambda m: char + m.group(1), text)  # \ae{re}, \ae{}
    return re.sub(r"\\%s(?![A-Za-z])" % cmd, char, text)              # \ae followed by } or punctuation


def convert(line):
    line = ligatures(line, "ae", "æ")
    line = ligatures(line, "oe", "œ")
    line = re.sub(r"\\emph\{([^{}]*)\}", r"*\1*", line)
    line = re.sub(r"\\lat\{([^{}]*)\}", r"**\1**", line)
    line = line.replace(" -- ", " – ")
    line = re.sub(r"\s+", " ", line).strip()
    if "\\" in line or "{" in line or "}" in line:
        raise ValueError("unconverted LaTeX in: " + line)
    return line


def main():
    body = TEX.read_text(encoding="utf-8").split("\\begin{document}")[1].split("\\end{document}")[0]
    entries = [convert(line) for line in body.splitlines() if line.strip()]
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_text(HEADER + "\n\n".join(entries) + "\n", encoding="utf-8")
    print(f"wrote {len(entries)} entries to {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
