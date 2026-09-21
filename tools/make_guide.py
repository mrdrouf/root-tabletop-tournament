"""Render guide/RTT_Guide.html to guide/RTT_Guide.pdf with Edge in headless mode.

The guide is the one-page player sheet for the things in the mod that are not obvious: the numpad
keys, the box score, the VP panel, the turn panel, the deck holder and the setup board's habits.
Edit the HTML, run this, commit both. The footer carries a month, not a build number: the commit
hook bumps VERSION on every commit, so a number printed here would be stale the moment it landed.

    python tools/make_guide.py
"""
import os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HTML = os.path.join(ROOT, "guide", "RTT_Guide.html")
PDF = os.path.join(ROOT, "guide", "RTT_Guide.pdf")
EDGE = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
]


def main():
    exe = next((e for e in EDGE if os.path.exists(e)), None)
    if exe is None:
        sys.exit("no Edge or Chrome found to print with")
    url = "file:///" + HTML.replace("\\", "/")
    cmd = [exe, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
           "--print-to-pdf=" + PDF, url]
    subprocess.run(cmd, check=True, timeout=120)
    print("wrote %s (%d bytes)" % (PDF, os.path.getsize(PDF)))


if __name__ == "__main__":
    main()
