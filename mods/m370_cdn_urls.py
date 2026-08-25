"""
m370 — serve our own assets via the jsDelivr CDN instead of raw.githubusercontent.

`raw.githubusercontent.com` is not a CDN — TTS loads it slowly and sometimes fails
on the first attempt (blank art until you reload). jsDelivr mirrors the exact same
GitHub files on a fast, TTS-friendly CDN. Pure URL swap; runs last so it catches
every asset any earlier mod added.

Note: jsDelivr caches a branch ref (@main) ~12h. After pushing NEW/updated assets,
purge them: curl https://purge.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/<path>
"""
from . import framework

NAME = "serve our assets via jsDelivr CDN (reliable) instead of raw.githubusercontent"

RAW = "https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main"
CDN = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main"


def apply(text):
    n = text.count(RAW)
    if n == 0:
        raise framework.BuildError("no raw.githubusercontent URLs found to swap")
    return text.replace(RAW, CDN)
