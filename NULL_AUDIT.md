# The C# null audit (2026-09-18)

TTS prints "Object reference not set to an instance of an object" when a script calls the API on
something that does not exist: a hand a colour does not own, a destroyed object handle, a plain object
asked for custom data, a UI that has not spawned. It is not a Lua error. pcall does not catch it, and it
ends the whole call chain from the C# entry point down. The only guard is not making the call.

This is Codex's independent read of `gen/src/observer.lua` and `gen/src/logic.lua` for every such
call site, asked for after the spectator error of 2026-09-18 (a watching host in Grey or Black tripped
the recorder's hand read on every drop). Read it as a list of suspects, not of confirmed bugs: the line
numbers are as of v1.452 and drift with every edit, and "a player deletes the piece inside the
two-frame wait" is real but rare.

## What was done with it

- The **handless-player family** (items 1-6: DRAW, DRAW POND, a Game Master picking a faction, numpad 1
  from Grey or Black) is fixed in v1.454: `rttHasHand(color)` asks the game for the colour's hand
  count, and faction picks, panel draws and the supply-bag search refuse a colour without one.
- The **selector closed with its own X button** (items 21-24) is fixed in v1.454: `rttLive(o)` asks
  `isDestroyed()` before the menu refresh drives a board, and a corpse is detached from its seat.
- The **numpad 3 handle** (items 10-16) is re-found by GUID after the two-frame wait, v1.454.
- The **harness models the null** since v1.452: Grey and Black own no hand zone, a dead handle
  (method, property, UI) throws, and so does a hand transform of a hand that is not there and
  getCustomObject on a plain object. The throw passes through every pcall and the runner fails any
  case that meets one. Every path the suite drives is therefore clean of the modelled kinds.
- Everything else below -- a handle captured across a Wait and deleted by another player inside the
  window, a table scan overlapping a teardown -- is NOT fixed. The mod's own pattern for those is to
  keep a GUID and re-resolve after the wait (`getObjectFromGUID` answers nil for a corpse), and
  `RTT_RUN_ID` for callbacks that must not outlive a setup. Apply it site by site when one is seen
  in play, and add the case to the harness, which will now catch it.
- The recorder's `onObjectEnterContainer` / `onObjectDestroy` reads (items 7-9) are left as they
  are: TTS hands the handler a live handle for the duration of the event, and numpad 0 has stowed
  warriors for a week with the recorder armed without a red line.

## The report, verbatim

Audit scope: both requested files. I skipped the contents of `RTT_BOXSCORE_JSON` at logic.lua:4686 and `RTT_TURN_PANEL_JSON` at logic.lua:5448 exactly as requested. Embedded scripts at logic.lua:1476 and logic.lua:6003 were audited. `pcall` is not counted as a guard.

All five hazard shapes have at least one unguarded site.

Highest risk — reachable during ordinary play or setup

1. gen/src/logic.lua:5886 — `deck.deal(1, who)` — Guard: none; `pcall` only. `who` is the panel clicker and there is no `getHandCount()` check. A Black player who manually acquired a faction, or a Grey/Black clicker on an older table with no usable seat records, can press DRAW and deal to a colour with no hand.

2. gen/src/logic.lua:5897 — `pile.deal(1, who)` — Guard: none; the Deck branch checks the pile’s kind, not the player’s hand count. The same Grey/Black VP-panel sequence makes the pond deal to a nonexistent hand.

3. gen/src/logic.lua:5898 — `pile.deal(1, who)` — Guard: none; this Card branch makes the same deal call. A single remaining pond card plus a Grey/Black clicker reaches it.

4. gen/src/logic.lua:6982 — `Player[supColor].getHandTransform(2)` — Guard: only `supColor ~= nil`; no colour or hand-count gate. `makeFaction` rejects Grey but not Black. A Black GM clicking Woodland Alliance on a manual selector makes `supColor == "Black"` and asks for Black hand 2.

5. gen/src/logic.lua:3766 — `Player[color].setHandTransform(..., 2)` — Guard: none. A Black GM can manually pick The Winged Menace because only Grey is rejected; the extra-hand setup then writes nonexistent Black hand 2.

6. gen/src/logic.lua:11008 — `Player[color].getHandTransform(1)` — Guard: none; `pcall` only. A Grey spectator or Black GM with no recorded faction presses numpad 1 away from a deck area; the fallback tries to locate their supply relative to a hand they do not own.

7. gen/src/observer.lua:1765 — `o.getGUID()` in `onObjectEnterContainer` — Guard: none. The event’s `o` is the piece that has just been put into a bag/deck and may already have been destroyed by `putObject`; numpad 0 returning a warrior to its supply is a direct normal-play trigger.

8. gen/src/observer.lua:1767 — `o.getPosition()` in `onObjectEnterContainer` — Guard: none. The same stow event asks the already-consumed object for its position.

9. gen/src/observer.lua:1777 — `o.getGUID()` in `onObjectDestroy` — Guard: none. Any player deletion, Clear All, scripted `destruct()`, deck merge, or container consumption can deliver an already-destroyed callback handle.

10. gen/src/logic.lua:11508 — `hovered.getPosition()` — Guard: the handle was non-nil two frames earlier; no GUID re-resolution or `isDestroyed()` check. Another player can delete, bag, or merge the warrior during the two-frame numpad-3 animation.

11. gen/src/logic.lua:11511 — `hovered.getBounds()` — Guard: none beyond the stale captured handle. The same mid-animation deletion reaches it.

12. gen/src/logic.lua:11514 — `hovered.setPosition(...)` — Guard: none beyond the stale captured handle. The warrior can be returned to its supply during the two-frame wait.

13. gen/src/logic.lua:11517 — `hovered.setLock(true)` — Guard: none. The warrior may already have been destroyed or contained.

14. gen/src/logic.lua:11519 — `hovered.highlightOn(...)` — Guard: none. The warrior may already have been deleted or stowed.

15. gen/src/logic.lua:11521 — `hovered.getColorTint()` — Guard: none. The warrior may already have been deleted or stowed.

16. gen/src/logic.lua:11522 — `hovered.setColorTint(faded)` — Guard: none. The warrior may already have been deleted or stowed.

17. gen/src/logic.lua:6003, embedded `vpMarker` — `o.getName()` on each `getAllObjects()` result — Guard: none; `pcall` only. The source comments document the concrete sequence: frog cards are merged into the main deck, the pond callback refreshes VP panels while the destroyed frog deck can still be returned by `getAllObjects()`, and the fallback name walk touches that corpse.

18. gen/src/logic.lua:6003, embedded `vpRefresh` — `self.UI.setCustomAssets(assets)` — Guard: none; called immediately from `onLoad`, before object UI is guaranteed ready, and again from callbacks scheduled 10/40/120 frames later. A newly spawned VP panel can hit unready UI; clearing the faction before a retry gives the callback a dead `self`.

19. gen/src/logic.lua:6003, embedded `buildUI` — `self.UI.setXml(...)` — Guard: none; same immediate-`onLoad` UI readiness window and delayed dead-`self` window.

20. gen/src/logic.lua:6003, embedded `buildUI` — `self.setScale(...)` — Guard: none against the delayed dead `self`. Delete or Clear All the panel before its 10/40/120-frame refresh.

21. gen/src/logic.lua:6568 — `clone.UI.setAttribute("rttFactions", ...)` — Guard: only `clone ~= nil`; no `isDestroyed()` or UI-ready check. A player closes a selector with its X button, leaving `seat.board` holding the dead handle, and the scheduled faction-menu refresh later touches it.

22. gen/src/logic.lua:6572 — `clone.UI.setAttribute("rttFac"..i, "icon", f)` — Guard: only the stale non-nil handle. Same deleted-selector sequence.

23. gen/src/logic.lua:6573 — `clone.UI.setAttribute("rttFac"..i, "active", "true")` — Guard: only the stale non-nil handle. Same deleted-selector sequence.

24. gen/src/logic.lua:6575 — `clone.UI.setAttribute("rttFac"..i, "active", "false")` — Guard: only the stale non-nil handle. Same deleted-selector sequence.

25. gen/src/logic.lua:3474 — `ord.shuffle()` — Guard: `ord ~= nil` and method-field presence, neither of which detects a destroyed handle. Delete the turn-order deck during the 0.5-second post-spawn delay.

26. gen/src/logic.lua:3493 — `ord.getGUID()` — Guard: only `ord ~= nil`. Delete the turn-order deck during the nested approximately 1.1-second draft delay.

27. gen/src/logic.lua:3637 — `deck.getPosition()` — Guard: none. Host of Light captures its Pillar deck and waits three seconds; deleting, containing, or clearing that deck during the wait leaves a dead handle.

28. gen/src/logic.lua:3639 — `deck.getRotation()` — Guard: none. Same three-second Host of Light window.

29. gen/src/logic.lua:3645 — `deck.takeObject(...)` — Guard: none. Same window; the container itself can be gone.

30. gen/src/logic.lua:6213 — `rulesBoard.getPosition()` — Guard: only a stale `rulesBoard ~= nil` test. Delete/Clear the freshly spawned Knaves rules board during the one-frame delay.

31. gen/src/logic.lua:6214 — `rulesBoard.getRotation()` — Guard: only the stale nil check. Same sequence.

32. gen/src/logic.lua:6259 — `rulesBoard.getGUID()` — Guard: none. The captured rules board is used again inside the later captain-board spawn callback and may have been cleared meanwhile.

33. gen/src/logic.lua:6265 — `rulesBoard.getSnapPoints()` — Guard: none. Same nested callback lifetime.

34. gen/src/logic.lua:6277 — `rulesBoard.setSnapPoints(pts)` — Guard: none. Same nested callback lifetime.

35. gen/src/logic.lua:6518 — `deck.takeObject(...)` — Guard: only `deck ~= nil`, checked after a 0.5-second wait. Clear All or manual deletion of the temporary Knaves captain deck during that wait leaves a dead container.

36. gen/src/logic.lua:6523 — `deck.destruct()` — Guard: only `deck ~= nil`; it runs another 0.8 seconds later. The deck may already have been deleted, cleared, or collapsed.

37. gen/src/logic.lua:7599 — `deck.takeObject(...)` — Guard: the deck was non-nil before the first draw, but is captured for three calls spaced 0.6 seconds apart. Deleting, moving into a container, reloading, or clearing the shared deck during the supporter deal leaves a dead container.

38. gen/src/logic.lua:7625 — `c.flip()` — Guard: only `c ~= nil`, not `isDestroyed()`. The supporter card is captured by `Wait.condition`; deleting, stowing, or merging it before it rests or before the three-second timeout makes `faceUp` touch a corpse.

39. gen/src/logic.lua:8026 — `board.positionToWorld(...)` — Guard: only the board’s earlier non-nil value. Corvid setup captures its board and waits one frame; deleting/Clearing it during that frame leaves a dead handle.

40. gen/src/logic.lua:8031 — `board.getRotation()` — Guard: none against the captured Corvid board being destroyed during that frame.

41. gen/src/logic.lua:7966 — `board.getRotation()` — Guard: none against the same captured Corvid board.

42. gen/src/logic.lua:7982 — `board.positionToWorld(...)` — Guard: none; reached by the no-hidden-zone fallback after the same one-frame lifetime gap.

43. gen/src/logic.lua:8190 — `deck.takeObject(...)` — Guard: the deck was checked only before the recursive pull sequence. Frog removal spaces calls by 0.1 seconds; deleting, clearing, reloading, or collapsing the shared deck during the sequence leaves a dead container.

44. gen/src/logic.lua:8242 — `mainDeck.putObject(f)` — Guard: only `mainDeck ~= nil`; neither `mainDeck` nor each frog object has an `isDestroyed()` check. A frog merge running over a table teardown can receive a dying main deck or frog object from the preceding scans.

45. gen/src/logic.lua:8243 — `mainDeck.shuffle()` — Guard: only `mainDeck ~= nil`, one second after the merge. Clear/delete/reload the deck during that second.

46. gen/src/logic.lua:8516 — `bag.takeObject(...)` — Guard: the bag was non-nil before a one-object-per-frame relay. Clear the Keepers faction or delete the Relics bag while the twelve relics are being placed.

47. gen/src/logic.lua:5872 — `deck.takeObject(...)` — Guard: only a non-nil handle returned by an unguarded table scan. A VP draw during a deck merge/teardown can select a dying Deck handle and then call it as a container.

48. gen/src/logic.lua:2866 — `o.UI.setXml("")` — Guard: `o ~= nil` and an attempted GUID read, but no `isDestroyed()` or UI-ready check. Clear All or a new setup can collect an object whose UI is still spawning or already being torn down; `pcall` is not protection.

49. gen/src/logic.lua:1476, embedded `deleteThis` — `self.destruct()` inside `Wait.frames(...,1)` — Guard: none. If Clear All or another player deletes the selector in the intervening frame, the callback holds its dead `self`.

Teardown-scan and polling races

50. gen/src/observer.lua:713 — `found.getGUID()` — Guard: none; `pcall` is used as a purported liveness probe. A map rebuild can make the board-returned map handle stale before an export reads it.

51. gen/src/observer.lua:727 — `o.getSnapPoints()` — Guard: none on objects returned by `getObjectsWithTag("Map Object")`. Export during map teardown can encounter a dying map piece.

52. gen/src/observer.lua:746 — `o.getBounds()` — Guard: only `o ~= nil`; no destroyed check. The map selected by the preceding scan can be removed during an export/build.

53. gen/src/observer.lua:747 — `o.getRotation()` — Guard: only the same nil check. Same map teardown sequence.

54. gen/src/observer.lua:775 — `o.getPosition()` — Guard: none on `"RTT Priority"` tag results. Export while priority markers are being cleared can touch a corpse.

55. gen/src/observer.lua:782 — `o.getCustomObject()` — Guard: only the `"RTT Priority"` tag; no type/class gate and no destroyed check. A plain Card/Tile/Token manually given that tag, an older-save marker of the wrong type, or a priority marker being destroyed during export causes the C# null.

56. gen/src/observer.lua:831 — `b.UI.getXml()` — Guard: the board is re-resolved and nil-checked, but there is no UI-ready check. Export/version detection while the main board has just reloaded can reach it before its UI is available.

57. gen/src/observer.lua:1142 — `o.getGUID()` — Guard: none on `getAllObjects()` results. A turn keyframe that overlaps teardown can receive an already-destroyed object.

58. gen/src/observer.lua:1159 — `o.getPosition()` — Guard: only a successful GUID and held-state read, not `isDestroyed()`. A piece finalized as destroyed while the keyframe walks the snapshot can fail here.

59. gen/src/observer.lua:1163 — `o.getRotation()` — Guard: none against the keyframe handle becoming stale during teardown.

60. gen/src/observer.lua:1168 — `o.getStates()` — Guard: none against the same stale keyframe handle.

61. gen/src/observer.lua:1169 — `o.getStateId()` — Guard: only `getStates()` returning entries; no destroyed check.

62. gen/src/observer.lua:1174 — `o.getQuantity()` — Guard: none against a deck/bag collapsing or being destroyed during the keyframe.

63. gen/src/observer.lua:1401 — `o.getGUID()` — Guard: none on `getAllObjects()` results. Pressing EXPORT during Clear All or map/faction teardown can touch a corpse.

64. gen/src/observer.lua:1407 — `o.getName()` — Guard: no destroyed check. Same export/teardown sequence.

65. gen/src/observer.lua:1412 — `o.getPosition()` — Guard: no destroyed check. Same export/teardown sequence.

66. gen/src/logic.lua:2268 — `o.getLock()` through `rttResyncCardOK` — Guard: none on the initial `getAllObjects()` handle. Press Resync while an object is being destroyed.

67. gen/src/logic.lua:2269 — `o.getGUID()` through `rttResyncCardOK` — Guard: none on the initial scan handle. Same sequence.

68. gen/src/logic.lua:2272 — `o.isSmoothMoving()` — Guard: no `isDestroyed()` check. Same Resync/teardown overlap.

69. gen/src/logic.lua:2282 — `o.getLuaScript()` — Guard: no destroyed check. Same overlap.

70. gen/src/logic.lua:2285 — `o.getButtons()` — Guard: no destroyed check. Same overlap.

71. gen/src/logic.lua:2293 — `o.getLock()` — Guard: no destroyed check. Same overlap.

72. gen/src/logic.lua:2294 — `o.getVelocity()` — Guard: no destroyed check. Same overlap.

73. gen/src/logic.lua:2378 — `o.getGUID()` — Guard: none on the accounting pass’s `getAllObjects()` handles. A card disappearing during the post-reload settle pass can be a corpse in the scan.

74. gen/src/logic.lua:2378 — `o.getPosition()` — Guard: none on the same accounting-pass handle.

75. gen/src/logic.lua:2478 — `o.getGUID()` — Guard: `rttResyncCardOK` just succeeded, which is a practical same-call liveness gate but not an explicit `isDestroyed()` check. A teardown transition during the scan is the remaining theoretical window.

76. gen/src/logic.lua:2484 — `o.getLock()` — Guard: none in the “skipped cards” branch. Resync overlapping a deletion can reach it.

77. gen/src/logic.lua:2485 — `o.getGUID()` — Guard: none in the same branch.

78. gen/src/logic.lua:2611 — `o.getGUID()` — Guard: none on the first full-table sweep. Resync during selector/faction teardown can encounter a corpse; later processing correctly re-resolves the GUID, but this initial read does not.

79. gen/src/logic.lua:5560 — `o.getPosition()` — Guard: name/class properties only, no destroyed check. A VP draw during deck collapse, frog merging, or Clear All can make `rttFindDrawDeck` scan a corpse.

80. gen/src/logic.lua:5591 — `o.hasTag("Deck Object")` — Guard: name/class properties only. Same no-holder fallback during teardown.

81. gen/src/logic.lua:5594 — `o.getQuantity()` — Guard: only the Deck name/type test. Same fallback race.

82. gen/src/logic.lua:5686 — `o.getPosition()` — Guard: only a Card/Deck name gate, no destroyed check. An Otter-panel draw during a card/deck merge can scan a dying object.

83. gen/src/logic.lua:5753 — `o.getPosition()` — Guard: only a Card/Deck name gate. A pond draw during a pond-pile merge or teardown can touch a corpse.

84. gen/src/logic.lua:5753 — `pond.getPosition()` — Guard: only `pond ~= nil`; no destroyed check. Clearing the pond while a panel draw is resolving leaves a dying tagged pond handle.

85. gen/src/logic.lua:6451 — `o.getPosition()` — Guard: only `o.name` being Card/CardCustom. The 1.5-second captain detector can run while a card is merging, being deleted, or entering a container.

86. gen/src/logic.lua:6455 — `o.getData()` — Guard: only the name and geometric tests; no destroyed check. Same captain-card teardown window.

87. gen/src/logic.lua:6641 — `o.hasTag("Quest")` — Guard: none on `getAllObjects()` results. Faction setup while old faction pieces are being destroyed can encounter a corpse.

88. gen/src/logic.lua:7390 — `o.getName()` — Guard: none; the source itself notes that a piece dying this frame answers with a null. VP-placement retries during faction/frog teardown are the concrete setup path.

89. gen/src/logic.lua:7393 — `o.hasTag("RTT VP Unplaced")` — Guard: only the preceding name match, not a destroyed check. A matching VP marker deleted during placement can fail here.

90. gen/src/logic.lua:7937 — `o.getScale()` — Guard: only `o.name == "Custom_Tile"`. The fallback Corvid board search can meet a faction board being cleared.

91. gen/src/logic.lua:7939 — `o.getPosition()` — Guard: only the class and scale tests. Same fallback race.

92. gen/src/logic.lua:8066 — `o.setLock(false)` — Guard: none on `"RTT Pond"` tag results. Picking Lizards while a previous pond is being cleared can touch a dead pond.

93. gen/src/logic.lua:8067 — `o.setPosition(...)` — Guard: none. Same pond teardown race.

94. gen/src/logic.lua:8068 — `o.setRotation(...)` — Guard: none. Same race.

95. gen/src/logic.lua:8069 — `o.setLock(true)` — Guard: none. Same race.

96. gen/src/logic.lua:8124 — `pn.call("vpRefresh")` — Guard: `pn.spawning ~= true`, but no `isDestroyed()` check. A VP panel being cleared is not “spawning”; the pond callback can call its dead handle.

97. gen/src/logic.lua:8132 — `deck.getObjects()` — Guard: none inside `rttFrogCount`. Its callers pass handles returned by unguarded table scans; frog setup during a deck teardown can call a corpse.

98. gen/src/logic.lua:8237 — `o.getDescription()` — Guard: only Card/CardCustom name. Frog merging can see a dying loose frog card from `getAllObjects()`.

99. gen/src/logic.lua:8291 — `cand.getSnapPoints()` — Guard: no prior `cand ~= nil` or destroyed check; Lua nil is caught by `pcall`, but a dead handle’s C# null is not. Map readiness polling during teardown supplies the concrete window.

100. gen/src/logic.lua:8298 — `board.getTags()` — Guard: `board ~= nil`, but no destroyed check. A map handle returned from the tag lookup can be in teardown.

101. gen/src/logic.lua:8311 — `o.getSnapPoints()` — Guard: none on `"Map Object"` tag results. `rttWhenMapReady` explicitly polls while map teardown/setup is occurring.

102. gen/src/logic.lua:9043 — `o.hasTag(RTT_FLOTILLA_TAG)` — Guard: none on helper-tag results. Delayed helper-row passes can coincide with a map change destroying old helper cards.

103. gen/src/logic.lua:9044 — `o.getBounds()` — Guard: none. Same delayed map-helper teardown window.

104. gen/src/logic.lua:9101 — `o.getBounds()` — Guard: none on the helper-row scan. Same sequence.

105. gen/src/logic.lua:9101 — `o.getPosition()` — Guard: none on the same handle.

106. gen/src/logic.lua:9103 — `o.hasTag(RTT_FLOTILLA_TAG)` — Guard: none on the same handle.

107. gen/src/logic.lua:9117 — `e.o.getPosition()` — Guard: the handle was saved earlier in the same helper-row pass, but no destroyed check. A dying helper returned by the tag query can reach it.

108. gen/src/logic.lua:9118 — `e.o.setLock(false)` — Guard: none against that dying helper.

109. gen/src/logic.lua:9119 — `e.o.setPosition(...)` — Guard: none against that dying helper.

110. gen/src/logic.lua:9120 — `e.o.setLock(true)` — Guard: none against that dying helper.

111. gen/src/logic.lua:9136 — `card.getPosition()` — Guard: only `card ~= nil`. A scheduled Flotilla adjustment can find its card just as a map/faction clear destroys it.

112. gen/src/logic.lua:9140 — `o.hasTag(RTT_HELPER_TAG)` — Guard: none on Flotilla-tag results. Same delayed adjustment/teardown overlap.

113. gen/src/logic.lua:9145 — `o.getPosition()` — Guard: no destroyed check. Same overlap.

114. gen/src/logic.lua:9146 — `o.getLock()` — Guard: no destroyed check. Same overlap.

115. gen/src/logic.lua:9147 — `o.setLock(false)` — Guard: no destroyed check. Same overlap.

116. gen/src/logic.lua:9148 — `o.setPosition(...)` — Guard: no destroyed check. Same overlap.

117. gen/src/logic.lua:9149 — `o.setLock(true)` — Guard: no destroyed check. Same overlap.

Unguarded but legacy, externally callable, or otherwise lower reachability

118. gen/src/logic.lua:2056 — `p.setHandTransform(up, 1)` — Guard: only `Player[color] ~= nil`; no hand-count or Grey/Black gate. `rttResyncHands` is currently defined but unreferenced. If externally invoked after a Black manual pick has produced a Black seat record, it writes nonexistent Black hand 1.

119. gen/src/logic.lua:2060 — `q.setHandTransform(home, 1)` — Guard: only `q ~= nil`; no hand-count check. Same currently-unreferenced Black-seat sequence, three frames later.

120. gen/src/logic.lua:3747 — `Player[color].getHandTransform(1)` — Guard: no hand-count check, but the current Winged Menace caller always supplies `hand1`, so the fallback is not used. An older/external caller passing Black or Grey reaches it.

121. gen/src/logic.lua:4045 — `Player[color].getHandTransform(1)` — Guard: no hand-count check, but the current Alliance caller supplies `hand1`. An older/external Black/Grey call reaches the fallback.

122. gen/src/logic.lua:4046 — `Player[color].setHandTransform(..., 2)` — Guard: none. In the current Black Alliance path, line 6982 aborts first; a direct/older call with Black reaches this site.

123. gen/src/logic.lua:7574 — `Player[color].getHandTransform(2)` — Guard: none. Normal internal callers use seat colours; direct invocation with Black/Grey, or a corrupted saved supporter colour, reaches a nonexistent hand.

124. gen/src/logic.lua:6546 — `d.deal(1, seated[who])` — Hand guard: real colour gate; `seated` is built only from seated non-Grey/non-Black players. Container guard: none across the recurring 0.15-second waits. `rttDealHands` is currently unreferenced; if externally invoked and the deck is deleted mid-deal, `d` becomes stale.

125. gen/src/logic.lua:2137 — `o.setColorTint(...)` in the delayed tint undo — Guard: none against a dead captured handle. Reachability is low because `RTT_RESYNC_MODE` defaults to `"lock"`; switching it to `"tint"` and deleting the object during the frame wait triggers it.

126. gen/src/logic.lua:1354 — `o.hasTag("Shuffleable")` — Guard: none after the same callback may have called `o.destroy()` at 1344, 1347, or 1349. `spawnDraftFaction` is legacy/unreferenced; invoking it for a destroyed Quest/Ruin Set piece gives a definite post-destroy call.

127. gen/src/logic.lua:1354 — first `o.shuffle()` — Guard: none after the same possible destroy. Same legacy sequence.

128. gen/src/logic.lua:1354 — second `o.shuffle()` — Guard: none after the same possible destroy. Same legacy sequence.

129. gen/src/logic.lua:3270 — `self.UI.setAttribute(id, "icon", ...)` — Guard: none against reload/deletion during the three-second disarm timer. The normal board is permanent, but arming a button and then using the table-control Reset Board or deleting the board can leave the timer’s old `self`.

130. gen/src/logic.lua:3271 — `self.UI.setAttribute(id, "color", ...)` — Guard: none against the same timer/reload window.

Guarded or invariant-safe sites checked

131. gen/src/observer.lua:505 — `p.getHandObjects(h)` — Real guard: `nhands = p.getHandCount()` at 501, then `h` ranges only from 1 through that count. Grey/Black produce zero iterations.

132. gen/src/observer.lua:1362 — `p.getHandObjects(1)` — Real guard: `p.getHandCount()` at 1361 and call only when `n >= 1`.

133. gen/src/logic.lua:2118 — `Player[c].getHandObjects(h)` — Real guard: `getHandCount()` at 2114 and loop bounded by the returned count.

134. gen/src/logic.lua:2899 — `Player[c].getHandTransform(2)` — Real invariant gate: `c` comes from the fixed ten-colour `RTT_ALL_COLORS` allowlist; Grey and Black are absent, and the stated table invariant gives each listed colour hand 2.

135. gen/src/logic.lua:2910 — `Player[c].setHandTransform(t, 2)` — Real invariant gate: entries exist only from the same fixed ten-colour snapshot.

136. gen/src/logic.lua:3843 — `Player[color].getHandObjects(h)` — Real internal guard: `h` is bounded by `getHandCount()` at 3839; normal entry is also through `rttMoveHand`, which rejects Grey/Black.

137. gen/src/logic.lua:3864 — `c.deal(1, color, e.hand)` — Real guards: `c` is re-resolved by GUID and nil-checked; `e.hand` was produced by the count-bounded scan at 3839–3843; the normal caller excludes Grey/Black.

138. gen/src/logic.lua:3884 — `Player[color].setHandTransform(...,1)` — Real colour guard: `rttMoveHand` rejects nil, Grey, and Black at 3876.

139. gen/src/logic.lua:3888 — `Player[color].setHandTransform(transform,1)` — Same real colour guard at 3876.

140. gen/src/logic.lua:8014 — `p.getHandTransform()` — Real colour gate: the loop requires `p.seated` and explicitly excludes Grey and Black at 8012.

141. gen/src/observer.lua:616 — `o.getCustomObject()` — Real type/class gate: `OBS_ART_OK[ty]` permits only relevant cardboard types and `OBS_PLAIN[cls]` rejects known plain Tile, Token, Card, and Deck classes before the call.

142. gen/src/logic.lua:10539 — `o.getCustomObject()` — Real shipped-data name gate: the call occurs only after `o.getName() == "Relic"`, and the source states all shipped objects with that unique name are custom relics. A user-renamed plain object named exactly `Relic` would defeat the gate, so this remains theoretical rather than an unconditional type guard.

143. gen/src/logic.lua:6003, embedded `tokenURL` — `m.getCustomObject()` — Partial name/GUID gate only: `m` is nil-checked and is expected to be the exact `"<row> VP"` marker, but there is no class/type check. Shipped markers are custom; an older save or a plain object renamed to that exact marker name reaches the null.

144. gen/src/logic.lua:5420 — `o.takeObject(...)` — Real container guard: each recursive step re-resolves `RTT_ORDER_DECK`, nil-checks it, and verifies via `getData().ContainedObjects` that it is still a Deck immediately before calling.

145. gen/src/logic.lua:11180 — `bag.putObject(hovered)` — Real practical guards: the bag is found through `rttFindByName`, whose `rttNameOf` checks `isDestroyed()`, and the hovered object is current. After the put, later work uses saved GUIDs and re-resolves both objects instead of touching the consumed handle.

146. gen/src/logic.lua:11247 — `bag.takeObject(...)` — Real practical guard: the bag came through the guarded name lookup, is nil-checked, and its positive quantity, position, and rotation are read synchronously before the call.

147. gen/src/logic.lua:11636 — `bag.takeObject(...)` — Same guarded name lookup, nil check, positive-quantity check, and synchronous use.

148. gen/src/logic.lua:1476, embedded `self.UI.setXml("")` and page `self.UI.setAttribute(...)` calls — Real contextual UI gate: these handlers can only be entered from that selector’s already-rendered object UI. Unlike the delayed `self.destruct()`, they do not cross a frame boundary.

149. gen/src/logic.lua:3531 — `board.UI.getAttributes(id)` — Real contextual UI gate: `board` is re-resolved from the relay’s GUID and nil-checked, and the handler is entered from that board’s rendered UI.

The ordinary main-board `self.UI.setAttribute` sites at 1385–1438, 1533–1538, 1608, and 3315–3316 are likewise UI-origin handlers on the persistent board; I found no normal-play unready-UI path to them.
