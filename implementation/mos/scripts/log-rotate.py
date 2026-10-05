#!/usr/bin/env python3
"""log-rotate.py: rotate a Manence OS journal (Spec §8). Shipped by the framework.

The journal reads one way: entries are prepended under the H1, newest first.

1. Puts log.md back into that single order. Entries are sorted by date,
   newest first; on equal dates the file's order is kept, except for a run
   appended at the end of the file in the other direction (oldest first),
   which is reversed. The script says which directions it found.
2. When log.md is over the threshold (default 150 KB), whole ISO weeks are
   moved out, oldest first, until it is back under the target (default
   120 KB). The current week and the one before never leave log.md.
   Moved entries go to log-archive/YYYY.md (one archive per year, same
   format, newest first), merged with an archive already there.

Each entry (from a "## [YYYY-MM-DD]" heading to the next one) is kept as it
is; only the blank lines between entries are normalized (one). Nothing is
summarized and nothing is deleted. Before anything is written, the outputs
are read back and checked: same number of entries, same hash for every
entry, newest first everywhere, the preamble (frontmatter and H1) unchanged.
A failed check writes nothing.

The rotation is proposed by the weekly review and played on the user's GO.

Usage:
  python3 scripts/log-rotate.py                  # dry run: reports, writes nothing
  python3 scripts/log-rotate.py --out /tmp/rot   # dry run, the would-be files in /tmp/rot
  python3 scripts/log-rotate.py --apply          # writes log.md and log-archive/ in the core
Options: --core DIR (default: the folder above scripts/), --threshold BYTES,
         --target BYTES, --today YYYY-MM-DD, --out DIR, --apply.
Standard library only.
"""
import argparse
import collections
import datetime
import hashlib
import os
import re
import sys

HEAD_RE = re.compile(r"^## \[(\d{4}-\d{2}-\d{2})\]")
H1_RE = re.compile(r"^# \S")
LINK_RE = re.compile(r"\]\((?!https?:|#|mailto:)[^)]+\)")


def split(text):
    """Preamble (everything before the first entry) and the list of (date, entry)."""
    lines = text.split("\n")
    idx = [i for i, line in enumerate(lines) if HEAD_RE.match(line)]
    if not idx:
        return text, []
    pre = "\n".join(lines[: idx[0]])
    blocks = []
    for k, start in enumerate(idx):
        end = idx[k + 1] if k + 1 < len(idx) else len(lines)
        body = "\n".join(lines[start:end]).rstrip()
        blocks.append((HEAD_RE.match(lines[start]).group(1), body))
    return pre, blocks


def digest(block):
    return hashlib.sha256(block.strip().encode()).hexdigest()


def ordinal(day):
    return datetime.date.fromisoformat(day).toordinal()


def order(blocks):
    """A head read newest first, then possibly a tail appended oldest first.
    Sorted newest first; on equal dates the head comes before the tail, the
    head keeps the file's order and the tail is reversed."""
    dates = [d for d, _ in blocks]
    brk = len(blocks)
    for i in range(1, len(dates)):
        if dates[i] > dates[i - 1]:
            brk = i
            break
    head_ok = all(dates[i] >= dates[i + 1] for i in range(0, brk - 1))
    tail_ok = all(dates[i] <= dates[i + 1] for i in range(brk, len(dates) - 1))
    keyed = []
    for i, (d, b) in enumerate(blocks):
        key = (-ordinal(d), 0, i) if i < brk else (-ordinal(d), 1, -i)
        keyed.append((key, d, b))
    keyed.sort(key=lambda t: t[0])
    return [(d, b) for _, d, b in keyed], brk, head_ok, tail_ok


def render(pre, blocks):
    return pre.rstrip() + "\n\n" + "\n\n".join(b for _, b in blocks) + "\n"


def h1_of(pre):
    for line in pre.split("\n"):
        if H1_RE.match(line):
            return line[2:].strip()
    return None


def archive_pre(title, year, today):
    name = f"{title}, archive {year}"
    return (
        "---\n"
        "type: log\n"
        f'title: "{name}"\n'
        "description: Journal entries moved out of log.md by rotation (Spec §8), same format, newest first.\n"
        f"timestamp: {today.isoformat()}\n"
        "---\n\n"
        f"# {name}\n"
    )


def week(day):
    y, w, _ = datetime.date.fromisoformat(day).isocalendar()
    return (y, w)


def fail(msg):
    print(f"CHECK FAILED: {msg}; nothing written", file=sys.stderr)
    sys.exit(1)


def main():
    ap = argparse.ArgumentParser(description="Rotate a Manence OS log.md (Spec §8).")
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    ap.add_argument("--core", default=here, help="the core (default: the folder above scripts/)")
    ap.add_argument("--threshold", type=int, default=150_000, help="rotate above this size, in bytes")
    ap.add_argument("--target", type=int, default=120_000, help="rotate down to this size, in bytes")
    ap.add_argument("--today", default=datetime.date.today().isoformat())
    ap.add_argument("--out", help="dry run: write the would-be files into this folder")
    ap.add_argument("--apply", action="store_true", help="write into the core")
    a = ap.parse_args()
    if a.target > a.threshold:
        ap.error("--target must not exceed --threshold")
    today = datetime.date.fromisoformat(a.today)

    log_path = os.path.join(a.core, "log.md")
    with open(log_path, encoding="utf-8") as fh:
        raw = fh.read()
    pre, blocks = split(raw)
    if not blocks:
        print(f"{log_path}: no '## [YYYY-MM-DD]' entry; nothing to do")
        return
    title = h1_of(pre)
    if title is None:
        fail("no H1 above the first entry (entries are prepended under the H1)")
    print(f"source: {len(raw.encode())} bytes, {len(blocks)} entries")

    ordered, brk, head_ok, tail_ok = order(blocks)
    if brk < len(blocks):
        print(f"two directions: a head of {brk} entries ({blocks[brk - 1][0]} -> {blocks[0][0]}),"
              f" a tail of {len(blocks) - brk} ({blocks[brk][0]} -> {blocks[-1][0]});"
              f" head newest-first {head_ok}, tail oldest-first {tail_ok}; put back newest first")
    else:
        print("one direction (newest first)")

    protected = {today.isocalendar()[:2], (today - datetime.timedelta(days=7)).isocalendar()[:2]}
    cut = None  # weeks <= cut move to the archive
    if len(render(pre, ordered).encode()) > a.threshold:
        for w in sorted({week(d) for d, _ in ordered}):
            if w in protected:
                break
            cut = w
            if len(render(pre, [x for x in ordered if week(x[0]) > cut]).encode()) <= a.target:
                break
    keep = [x for x in ordered if cut is None or week(x[0]) > cut]
    arch = [x for x in ordered if cut is not None and week(x[0]) <= cut]
    if cut is None:
        print(f"threshold {a.threshold} B, target {a.target} B: under the threshold, nothing to archive")
    else:
        print(f"threshold {a.threshold} B, target {a.target} B: weeks up to {cut[0]}-W{cut[1]:02d} archived")

    for d, b in arch:
        if LINK_RE.search(b):
            print(f"note: relative link in an archived entry of {d} (one folder deeper in log-archive/: it may no longer resolve)")

    by_year = collections.defaultdict(list)
    for d, b in arch:
        by_year[d[:4]].append((d, b))
    existing, outs = [], {}
    for year, items in sorted(by_year.items()):
        rel = os.path.join("log-archive", f"{year}.md")
        path = os.path.join(a.core, rel)
        ex, ex_pre = [], None
        if os.path.exists(path):
            with open(path, encoding="utf-8") as fh:
                ex_pre, ex = split(fh.read())
            print(f"{rel} exists: {len(ex)} entries merged")
        existing += ex
        merged = sorted(items + ex, key=lambda x: -ordinal(x[0]))  # stable: new ones first
        outs[rel] = render(ex_pre if ex_pre and ex_pre.strip() else archive_pre(title, year, today), merged)

    out_log = render(pre, keep)

    # Checks, on the outputs read back.
    back_pre, back_keep = split(out_log)
    back_arch = [x for o in outs.values() for x in split(o)[1]]
    if len(back_keep) + len(back_arch) != len(blocks) + len(existing):
        fail("number of entries")
    before = collections.Counter(digest(b) for _, b in blocks + existing)
    after = collections.Counter(digest(b) for _, b in back_keep + back_arch)
    if before != after:
        fail("set of entries (a hash differs)")
    kept_dates = [d for d, _ in back_keep]
    if kept_dates != sorted(kept_dates, reverse=True):
        fail("log.md not newest first")
    for rel, o in outs.items():
        da = [d for d, _ in split(o)[1]]
        if da != sorted(da, reverse=True):
            fail(f"{rel} not newest first")
    if back_pre.rstrip() != pre.rstrip():
        fail("preamble changed")
    print("checks: OK (count, hashes, order, preamble)")

    print(f"log.md: {len(back_keep)} entries, {len(out_log.encode())} bytes,"
          f" {kept_dates[-1]} -> {kept_dates[0]}")
    for rel, o in outs.items():
        da = [d for d, _ in split(o)[1]]
        print(f"{rel}: {len(da)} entries, {len(o.encode())} bytes, {da[-1]} -> {da[0]}")

    dest = a.core if a.apply else a.out
    if not dest:
        print("dry run: nothing written (--out DIR to see the files, --apply to write them in the core)")
        return
    os.makedirs(os.path.join(dest, "log-archive"), exist_ok=True)
    with open(os.path.join(dest, "log.md"), "w", encoding="utf-8") as fh:
        fh.write(out_log)
    for rel, o in outs.items():
        with open(os.path.join(dest, rel), "w", encoding="utf-8") as fh:
            fh.write(o)
    print(f"written to {dest}")


if __name__ == "__main__":
    main()
