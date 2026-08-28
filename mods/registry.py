"""
The modification sequence.

MODS is the ordered list of modifications build.py applies on top of the base
mod. Order matters. To add the next step in the sequence:

    1. create mods/mNNN_short_name.py with NAME and apply(text)
    2. import it below
    3. append it to MODS in the position it should run

The enabled list below is just the identity/branding step, so the build is an
exact copy of the base mod under the Root Tabletop Tournament name.
"""

from . import m000_identity
from . import m020_remove_tools
from . import m030_remove_fan_maps
from . import m040_remove_fan_decks
from . import m050_remove_scenarios
from . import m060_no_faction_dice
from . import m070_remove_manuals
from . import m080_remove_dead_buttons
from . import m090_remove_mode_buttons
from . import m100_four_selectors
from . import m110_remove_fandmarks
from . import m120_remove_draft_modes
from . import m130_resize_summer_button
from . import m140_remove_master_pdf
# m150_remove_title_model DISABLED: GUID 4ee1f2 is the TABLE, not a title. Removing
# it deleted the table surface. Left out of MODS until the real title is found.
from . import m160_bats_assemblies_facedown
from . import m170_resize_setup_button
from . import m180_replace_autumn_with_summer
from . import m190_compact_setup_menu
from . import m200_summer_autumn_design
from . import m210_remove_more_buttons
from . import m220_remove_hirelings
from . import m230_four_player_corners
from . import m240_five_player_setup
from . import m250_rtt_setup
from . import m260_one_board
from . import m270_credit_sign
from . import m280_tools_on_board
from . import m290_lizard_warriors
from . import m300_duchy_warriors
from . import m310_errata
from . import m320_menu_cleanup
from . import m330_setup_plaques
from . import m340_layout_polish
from . import m355_setup_fixes
from . import m350_custom_layout
from . import m360_board_cleanup
# m365_board_thickness DISABLED: the board was never a 3D model; adding real tile
# thickness clashed with the texture's fake-3D border and broke rendering. Reverted.
from . import m370_cdn_urls
from . import m380_faction_selector_clean
from . import m390_no_hover_credits
from . import m400_remove_fan_factions
from . import m410_marsh_5p
from . import m420_rtt_button_style
from . import m430_clearing_priorities_fix
from . import m431_declutter_toplevel
from . import m440_marsh_floods
from . import m445_marsh_no_landmarks
from . import m460_priority_markers
from . import m470_rtt_draft_pick
from . import m480_ranked_theme_buttons
from . import m490_faction_setup
from . import m500_marsh_5p_draft
from . import m510_ui_assets_persist
from . import m520_solo_faction_board
from . import m530_deck_spacing
from . import m540_button_art_urls
from . import m550_marquise_keep
from . import m560_bats_warriors
from . import m570_marquise_warriors
from . import m580_lilypad_pond
from . import m590_mountain_central_marker
from . import m600_fix_shuffle_rng
from . import m610_lost_city_card
from . import m620_crow_warriors
from . import m630_remove_swol_birbs
from . import m640_fix_coldload_ui
# m650_coldload_selfheal DISABLED for the m660 trim A/B (its 27s respawn would mask/blank the result).
# from . import m650_coldload_selfheal
from . import m660_trim_setup_assets   # trim bab7e1 CustomUIAssets 541 -> ~147 (cheap cold-load A/B)
# m450_label_icons DISABLED: confirmed custom (non-Steam) UI icons blank in TTS

# Ready-made examples — uncomment to begin layering real modifications:
# from . import m010_no_marquise_dice

MODS = [
    m000_identity,
    # m010_no_marquise_dice,
    m020_remove_tools,
    m030_remove_fan_maps,
    m040_remove_fan_decks,
    m050_remove_scenarios,
    m060_no_faction_dice,
    m070_remove_manuals,
    m080_remove_dead_buttons,
    m090_remove_mode_buttons,
    m100_four_selectors,
    m110_remove_fandmarks,
    m120_remove_draft_modes,
    m130_resize_summer_button,
    m140_remove_master_pdf,
    # m150_remove_title_model,  # DISABLED — 4ee1f2 is the table, not a title
    m160_bats_assemblies_facedown,
    m170_resize_setup_button,
    m180_replace_autumn_with_summer,
    m190_compact_setup_menu,
    m200_summer_autumn_design,
    m210_remove_more_buttons,
    m220_remove_hirelings,
    m230_four_player_corners,
    m240_five_player_setup,
    m250_rtt_setup,
    m260_one_board,
    m270_credit_sign,
    m280_tools_on_board,
    m290_lizard_warriors,
    m300_duchy_warriors,
    m310_errata,
    m320_menu_cleanup,
    # m330_setup_plaques,  # DISABLED: custom UI plaques blank in TTS (RTT is a text button)
    m340_layout_polish,
    m355_setup_fixes,
    m410_marsh_5p,
    m420_rtt_button_style,
    m350_custom_layout,
    m430_clearing_priorities_fix,  # after m350: rename+wrapper CP, drop stray top-level copies
    m431_declutter_toplevel,       # remove all base top-level bot/fan/reference buttons
    m440_marsh_floods,             # Marsh map: randomise the 3 flooded clearings on spawn
    m445_marsh_no_landmarks,       # Marsh map: drop the landmark models + cards
    m460_priority_markers,         # per-map: auto-place fixed clearing-priority markers
    m480_ranked_theme_buttons,     # replace RTT DRAFT text button with Ranked + Theme image buttons
    m360_board_cleanup,
    # m365_board_thickness,        # DISABLED — board was never 3D; thickness broke rendering
    m470_rtt_draft_pick,           # AFTER m360: copies the swapped v3 texture into the lightweight selector
    m490_faction_setup,            # AFTER m470: per-faction setup extras (Lizard/frogs/Badgers) dispatch
    m380_faction_selector_clean,
    m390_no_hover_credits,
    m400_remove_fan_factions,
    m370_cdn_urls,
    m500_marsh_5p_draft,   # AFTER m440/m460/m470/m490: 5-player Marsh ranked draft + towns
    m510_ui_assets_persist,  # add the 3 icons to onLoad's hardcoded asset table (fixes blank white)
    m520_solo_faction_board, # solo faction board: strip to the 12 factions + Knaves as a direct tile
    m530_deck_spacing,       # setup board: deck buttons spaced to match the map buttons
    m540_button_art_urls,    # repoint label + map button icons to Adrien's new Steam art
    m550_marquise_keep,      # bake the enlarged Marquise Keep
    m560_bats_warriors,      # bake bats warriors + assemblies (direct spawn)
    m570_marquise_warriors,  # bake the 3 staging Marquise warriors (direct spawn)
    m580_lilypad_pond,       # remove The Pond from the blueprint; spawn it directly at its world spot
    m590_mountain_central_marker,  # drop Mountain's central clearing marker (landmark, no flash)
    m600_fix_shuffle_rng,          # replace base shuffle() os.time-reseed with clean Fisher-Yates
    m610_lost_city_card,           # swap the outdated Lost City rules-card art
    m620_crow_warriors,            # bake Corvid warriors + moved supply (direct spawn)
    m630_remove_swol_birbs,        # replace the Swol Birbs fan option with the Marsh 5p button
    m640_fix_coldload_ui,          # cold-load: remove the frame-100 setCustomAssets (no re-stomp)
    # m650_coldload_selfheal,      # DISABLED for the m660 trim A/B (respawn would mask the result)
    m660_trim_setup_assets,        # cold-load: trim bab7e1 CustomUIAssets 541 -> ~147 (art-safe)
    # m450_label_icons,  # DISABLED — custom UI icons blank in TTS; VB/Landmarks stay on Steam art
]
