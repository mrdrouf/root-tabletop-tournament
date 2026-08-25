"""
m420 — style the RTT button like a Root card face.

The plain dark RTT text button looked ugly. We can't use a custom image (they blank
in TTS), but the XmlUI colour attributes work: give it the deck's parchment/cream
face with dark-brown bold lettering, echoing Root's craftable cards.
"""
from . import framework

NAME = "style the RTT button like a Root card (parchment + dark bold text)"


def apply(text):
    # add textColor + fontStyle (the button has neither by default)
    text = framework.replace_unique(
        text, 'id=\\"rttSetup\\"',
        'id=\\"rttSetup\\" textColor=\\"#3d2c15\\" fontStyle=\\"Bold\\"')
    for attr, val in (("color", "#e3d3a6"), ("fontSize", "11"), ("text", "RTT DRAFT")):
        text, n = framework.set_button_attr(text, "rttSetup", attr, val)
        if n == 0:
            raise framework.BuildError("rttSetup %s not set" % attr)
    return text
