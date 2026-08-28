"""
m540 — repoint button-icon assets to Adrien's newly-uploaded Steam art.

The recomposed label icons (art-left / name-right) and the feathered map icons were imported
into TTS (Steam Cloud) from assets/upload/. Each asset's URL appears in every asset registry
(bab7e1's CustomUIAssets, the selector-clone template's CustomUIAssets, and the onLoad rebuild
table), so a global old->new URL swap updates them all at once — and it also survives the
onLoad setCustomAssets rebuild (the m510 blank-out), because the onLoad table URL is swapped too.

Old URLs read from the current CustomUIAssets; new URLs recovered from Adrien's Mods/Images cache
by content SHA1 after upload.

PENDING: "Clearing Priorities Big" (the recomposed "Clearing Numbers", no red dot) was not in the
cache yet — Adrien still needs to re-import assets/upload/clearing_priorities_label.png; its swap
will be added here once the new URL is recovered.
"""
from . import framework

# asset -> (old_url, new_url)
SWAPS = {
    "Landmarks": (
        "https://steamusercontent-a.akamaihd.net/ugc/1862810258466467224/9564630227863DEDC450E448CE529E7A155FC9F4/",
        "https://steamusercontent-a.akamaihd.net/ugc/12936154875885790386/85439BAAE5C809A82FAF83A96E5232DFF4152DD0/"),
    "Vagabond Cards": (
        "https://steamusercontent-a.akamaihd.net/ugc/1725416402718274003/CD92CEB17685C1F47F3251FA59A5A6C89E068AF3/",
        "https://steamusercontent-a.akamaihd.net/ugc/13747817220151181841/9A47D69E9103B9502DBED36BEA4DA6F9C70C6EB8/"),
    "FivePlayerArt": (
        "https://steamusercontent-a.akamaihd.net/ugc/13228007358041271497/D7F3C16E093B57844CA249AAEEF2D59C0219B76D/",
        "https://steamusercontent-a.akamaihd.net/ugc/10646501209524696434/622AC9B1FA1D4C6B239DF99C896C07640F449574/"),  # Marsh 5-player label (real map art)
    "Clearing Priorities Big": (
        "https://steamusercontent-a.akamaihd.net/ugc/1725416402719800299/10FBE62951D9E567FEB3DE44340D49C41EB89D21/",
        "https://steamusercontent-a.akamaihd.net/ugc/17343862070314210598/A5AFE2885F4656D394532C9DA4E260DAEBB5D271/"),
    "Autumn Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/1809859635019282433/EAE1E0EB9E10AF35A6454618104EE3020576DD16/",
        "https://steamusercontent-a.akamaihd.net/ugc/9338841708247799860/688C6CB9F5A34B2A2B067C6DA493AD653B7D9C6A/"),
    "Winter Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/1809859635019393365/09310ED059684EEB7BCA2EA49712DA5F9802506F/",
        "https://steamusercontent-a.akamaihd.net/ugc/12863190738702993416/F9C676622A48D6E15BB3AE235E26CE7BC8D11283/"),
    "Lake Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/1809859635019191842/2261ACDE35BDD17F956C0A37DFC2C3149C62C1EF/",
        "https://steamusercontent-a.akamaihd.net/ugc/11224158918879846636/C034E1855CED11FD28D76E3020D629478FABD195/"),
    "Mountain Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/1809859635019203841/04C054FE627986D614002EE42DC1BDA96D001F13/",
        "https://steamusercontent-a.akamaihd.net/ugc/17146621840035729417/55256EFBD832F89B16ADAF98A382D4BF09162487/"),
    "Marsh Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/15295993499701766575/8C34CBD5E5C0DCFF8C987C3A04CF845A78BC4DD6/",
        "https://steamusercontent-a.akamaihd.net/ugc/12189840401890527004/1A5500DF801E01874A28C059E04D049043948426/"),
    "Gorge Map": (
        "https://steamusercontent-a.akamaihd.net/ugc/9571499348614187950/2081E28B4413E5CD5E1AF77206BCDF6E423BAD8E/",
        "https://steamusercontent-a.akamaihd.net/ugc/17163206417596942920/65DEC204EF54C27F6BAFE8202D3AE63F73D28DD3/"),
}

NAME = "repoint button-icon assets to the recomposed/feathered Steam art (%d icons)" % len(SWAPS)


def apply(text):
    for name, (old, new) in SWAPS.items():
        if text.count(old) == 0:
            raise framework.BuildError("m540: old URL for %r not found" % name)
        text = text.replace(old, new)
    return text
