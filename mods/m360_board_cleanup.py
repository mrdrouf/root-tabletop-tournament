"""
m360 — clean the board itself.

 - Swap the wood texture for a version with the baked "Board by Ehss & slugfacekillah"
   credit removed (assets/board/board_clean_v2.png, hosted via GitHub raw). v2 keeps
   the ORIGINAL 3D wood grain and removes the credit by mirroring the clean top-left
   corner over it (feathered, matching grain + vignette) — no flat patch. The original
   artists are still credited in the repo README/CHANGELOG.
 - Remove the "message roof" over the tools: the "Fan Tools Label" image, whose art
   reads "TTS Tools by the ROOT Community" (baked into the image, not text).
 - Remove the top "Weird Root mashup" banner (WWBanner).
 - Hide the leftover section labels (Map/Deck and Red/Any-Factions) that don't match
   the tournament layout.
"""
from . import framework

NAME = "clean board: new texture (no baked credit), drop banners + stray labels"

OLD_BOARD = "https://steamusercontent-a.akamaihd.net/ugc/1760320391484183045/6F0CAF900BA7AF96687B49D73B36F68022202AE4/"
# custom clean board (credit removed). Diagnostic confirmed the board texture is NOT the cold-load
# cause -- the tile renders on cold load; the blank is the setup BUTTONS. Restored per Adrien.
NEW_BOARD = "https://raw.githubusercontent.com/mrdrouf/root-tabletop-tournament/main/assets/board/board_clean_v3.png"


def apply(text):
    text = framework.replace_unique(text, OLD_BOARD, NEW_BOARD)
    # the "TTS Tools by the ROOT Community" banner over the tools
    text, n = framework.remove_xml_element(text, "Image", 'image = \\"Fan Tools Label\\"')
    if n == 0:
        raise framework.BuildError("Fan Tools Label banner not found")
    text, n = framework.remove_xml_element(text, "Image", 'image=\\"WWBanner\\"')
    if n == 0:
        raise framework.BuildError("WWBanner not found")
    for lid in ("WWMapAndDeckLabelImage", "WWFactionLabelImage"):
        text, n = framework.set_xml_attr(text, "Image", lid, "active", "false")
        if n == 0:
            raise framework.BuildError("label image not found: %s" % lid)
    return text
