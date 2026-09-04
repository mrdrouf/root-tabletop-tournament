"""Move every completed WORK_QUEUE item into WORK_QUEUE_ARCHIVE.md.

Standing rule from the maintainer: the work queue only ever shows what is OPEN.
Run this after ticking anything, before committing.
    python3 tools/queue_archive.py
"""
import os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
Q = os.path.join(ROOT, "WORK_QUEUE.md")
A = os.path.join(ROOT, "WORK_QUEUE_ARCHIVE.md")
KEEP = ("Golden rule", "m###", "STRUCTURAL", "Standing rule")


def split(src):
    open_lines, done_lines, mode = [], [], None
    for ln in src.split("\n"):
        if re.match(r"^- \[x\]", ln):
            mode = "done"; done_lines.append(ln); continue
        if re.match(r"^- \[ \]|^- \[~\]", ln):
            mode = "open"; open_lines.append(ln); continue
        if ln.startswith("#"):
            mode = None; open_lines.append(ln); done_lines.append(ln); continue
        (done_lines if mode == "done" else open_lines).append(ln)
    return open_lines, done_lines


def squeeze(lines):
    out = []
    for l in lines:
        if not l.strip() and out and not out[-1].strip():
            continue
        out.append(l)
    return "\n".join(out).strip() + "\n"


def drop_empty_sections(text):
    kept = []
    for blk in re.split(r"(?m)^(?=## )", text):
        head = blk.split("\n", 1)[0]
        if (not head.startswith("##")
                or re.search(r"^- \[", blk[len(head):], re.M)
                or any(k in head for k in KEEP)):
            kept.append(blk)
    return re.sub(r"\n{3,}", "\n\n", "".join(kept)).strip() + "\n"


def main():
    src = open(Q, encoding="utf-8").read()
    op, done = split(src)
    moved = sum(1 for l in done if re.match(r"^- \[x\]", l))
    if not moved:
        print("[queue] nothing completed to archive"); return
    arch = open(A, encoding="utf-8").read() if os.path.exists(A) else \
        ("# RTT work queue — archive\n\nCompleted items, moved out of `WORK_QUEUE.md`.\n")
    open(A, "w", encoding="utf-8").write(arch.rstrip() + "\n\n" + squeeze(done))
    open(Q, "w", encoding="utf-8").write(drop_empty_sections(squeeze(op)))
    still = open(Q, encoding="utf-8").read().count("\n- [ ]")
    print("[queue] archived %d completed item(s); %d still open" % (moved, still))


if __name__ == "__main__":
    main()
