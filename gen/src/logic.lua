-- THE RECORD SURVIVES A SAVE, A RELOAD AND A CRASH. TTS Globals do not -- they are wiped on load --
-- but an object's own onSave state is written into the save file and handed back to onLoad. There was
-- no onSave here at all, so a resumed game came back with factions on the table and no idea who was
-- sitting where: the gizmo answered "no faction seated in your colour" and the box score silently
-- fell back to guessing rows from hand-zone geometry. Persisting the seats fixes both, and re-mirrors
-- them into the Globals so anything still reading those sees the same truth.
function onSave()
  local ok, enc = pcall(function()
    local seats = {}
    for i, s in ipairs(RTT_SEATS or {}) do
      if s ~= nil and s.pos ~= nil then
        -- KEY AND vagN ARE SAVED, NOT RECOMPUTED. They were left out, and rttSeatRecord rebuilds a
        -- missing key with rttFactionKey(faction) -- which answers "Vagabond" for EVERY vagabond. Two
        -- vagabonds in play therefore both republished under one key after a reload: the same Global
        -- entry written twice, last one wins, and the second vagabond lost its colour, its owner and
        -- its position while its marker on the table was still called "Vagabond 2 VP".
        seats[#seats + 1] = { i = i, pos = { s.pos[1], s.pos[2] }, color = s.color,
                              faction = s.faction, owner = s.owner, hand = s.hand,
                              key = s.key, vagN = s.vagN,
                              picker = s.picker, pickedAt = s.pickedAt }
      end
    end
    -- laid: which warriors numpad 2 put down, and what they looked like standing. Without this a
    -- reload leaves them cream and locked with nothing able to undo it.
    return JSON.encode({ v = 1, run = RTT_RUN_ID or 0, turnSeats = RTT_TURN_SEATS, seats = seats,
                         laid = RTT_LAID or {}, pickN = RTT_PICK_N or 0,
                         -- order: the draft's single shuffle, person -> seat number. It is not a
                         -- duplicate of the seats -- it is the INPUT that decides which seat each
                         -- person gets, and it is needed in the window between the order cards being
                         -- dealt and the players being seated. Lost on a reload in that window, the
                         -- draft could not be finished: rttBeginPick returns on an empty order and
                         -- rttSeatPlayers has nothing to match a human to a seat with.
                         order = RTT_ORDER or {} })
  end)
  if ok then return enc end
  return ""
end

function onLoad(state)
  -- Restore the seat record BEFORE anything else: the gizmo hotkey below and every later publish read
  -- it. Boards are not restored (the objects are re-created by TTS with their own guids and are found
  -- again by tag); position, colour, faction and owner are, which is everything the record is for.
  pcall(function()
    if type(state) ~= "string" or state == "" then return end
    local d = JSON.decode(state)
    if type(d) ~= "table" or type(d.seats) ~= "table" then return end
    RTT_SEATS = {}
    for _, e in ipairs(d.seats) do
      if type(e) == "table" and type(e.pos) == "table" then
        -- APPEND, NEVER INDEX BY THE SAVED NUMBER. onSave skips a seat with no position, so the
        -- numbers it writes can have holes -- and restoring into RTT_SEATS[e.i] reproduces the hole.
        -- Eight separate ipairs(RTT_SEATS) loops stop dead at the first one: the turn order, the
        -- published record, the free-colour search, the vagabond ordinal, rttSeatFaction. The array
        -- has to be contiguous, so the seats are appended in the order they were written.
        RTT_SEATS[#RTT_SEATS + 1] = { board = nil, pos = { e.pos[1], e.pos[2] },
                                      color = e.color, faction = e.faction,
                                      owner = e.owner, hand = e.hand,
                                      key = e.key, vagN = e.vagN,
                                      picker = e.picker, pickedAt = e.pickedAt }
      end
    end
    RTT_RUN_ID     = d.run or RTT_RUN_ID
    RTT_TURN_SEATS = d.turnSeats or RTT_TURN_SEATS
    if type(d.laid) == "table" then RTT_LAID = d.laid end
    RTT_PICK_N = d.pickN or RTT_PICK_N
    if type(d.order) == "table" then RTT_ORDER = d.order end
    if #RTT_SEATS > 0 then rttPublishSeats() end
  end)
  pcall(function() rttSnapshotHand2() end)  -- parked hand-2 transforms, restored on every new game
  -- The gizmo answers a TTS SCRIPTING BUTTON, which is numpad-bound by default -- and a MacBook has
  -- no numpad (maintainer, 2026-09-04: on a French Mac layout the top-row 0 needs Shift and never
  -- reaches it). One named hotkey does the same job and binds to any key in Options - Game Keys.
  pcall(function()
    addHotkey("Gizmo: send the hovered piece home", function(color) rttGizmoHome(color) end)
    addHotkey("Gizmo: take a warrior from your supply", function(color) rttGizmoTake(color) end)
    addHotkey("Gizmo: lay the hovered warrior down", function(color) rttGizmoLay(color) end)
    addHotkey("Gizmo: lay it down and light it up", function(color) rttGizmoGlow(color) end)
  end)
  assets = {}
  if self.getName() != "Faction Board" then
    assets = {

        {name = "ThemeArt", url = "https://steamusercontent-a.akamaihd.net/ugc/16316853328531788856/FE0894D6BBC40E7876FE4A683368A61FC1B35547/"},
        {name = "RankedArt", url = "https://steamusercontent-a.akamaihd.net/ugc/17736006513028835727/23F7EB2248073953C65D1AAD44636708E9E2DFE1/"},
        {name = "FivePlayerArt", url = "https://steamusercontent-a.akamaihd.net/ugc/10646501209524696434/622AC9B1FA1D4C6B239DF99C896C07640F449574/"},














        {name = "Marquise de Cat",url  = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739429295/F6CF523AAA7DCC91AF3812339EBB3354F6D9891A/"},
        {name = "Eyrie Dynasties",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755958213/960DFA43E52D99A3250863FC63F3BA3AE5104325/"},
        {name = "Woodland Alliance",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755956632/E99D3C9B246A94F6A898EC0D8098A05FA9467473/"},
        {name = "VagabondAndKnaves",url  = "https://steamusercontent-a.akamaihd.net/ugc/11747765109863371101/6EB77E31F0244DFD039474C19C18D49AD0C93DBD/"},
        {name = "Vagabond",url  = "https://steamusercontent-a.akamaihd.net/ugc/18029067728280360921/442E94C46A3882D69BD9CE83FAC257620EE84AEB/"},
        {name = "The Lizard Cult",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755960838/D88CBE9192488A678AF3EC6DFC45B4C728C9A169/"},
        {name = "Riverfolk Company",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755963912/C9589D96259534C6FB15DD91F78E7E90A073FDD8/"},
        {name = "Underground Duchy",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755961872/1E2748C8EDD0BDE039B81658AFD0B19C771569BD/"},
        {name = "Corvid Conspiracy",url  = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755959858/69B8EC707AD26EF2F558ACAB65B39163B812D3F6/"},
        {name = "Lord of the Hundreds",url  = "https://steamusercontent-a.akamaihd.net/ugc/1833522185818578726/CE952087E18A1C0B6B94E44EF53EB009A97A7122/"},
        {name = "Keepers in Iron",url  = "https://steamusercontent-a.akamaihd.net/ugc/1833522185818579404/C0D7197A109DBF0C2EFB34DF50AE2CA70A66C25B/"},
        {name = "Twilight Council",url  = "https://steamusercontent-a.akamaihd.net/ugc/2452866064845174396/6228F6A71DDC36CD883777CA958857CB123D7ECB/"},
        {name = "Lilypad Diaspora",url  = "https://steamusercontent-a.akamaihd.net/ugc/2508034524425991747/77C277526C0042FE2754C83836A1E2C3C03FAD38/"},
        {name = "Knaves of the Deepwood",url  = "https://steamusercontent-a.akamaihd.net/ugc/14468202139363768412/1012F7145C45B86F395C099B9AE80EA536529DD3/"},

        {name = "Adventurer",url="https://steamusercontent-a.akamaihd.net/ugc/1728793291756318712/DAB9CB5B2AA9CF5AF4BDD67CFED687B8595411CF/"},
        {name = "Arbiter",url="https://steamusercontent-a.akamaihd.net/ugc/1728793291756223555/8BB76979D215E9C042976005212DD7D0F9EBCDBD/"},
        {name = "Harrier",url="https://steamusercontent-a.akamaihd.net/ugc/1728793291756321980/D728E9E7523EF9917554681B8CCFA7A79D6E95DC/"},
        {name = "Ranger",url="https://steamusercontent-a.akamaihd.net/ugc/1728793291756323292/B5CDBACDB5E58637478F86047D574579AECBC763/"},
        {name = "Ronin",url="https://steamusercontent-a.akamaihd.net/ugc/1861696999739435936/8C15D8C6D58FAF51A22B66697740CBA5BAEBBEFB/"},
        {name = "Scoundrel",url="https://steamusercontent-a.akamaihd.net/ugc/1728793291756324621/71561324D23947260120C7F2EDF0A692986619EB/"},
        {name = "Thief",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756326469/AA4F3B6BF91AC337A240B582DF46C07DF9A374E5/"},
        {name = "Tinker",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756328063/25E9D54EAFE7A483877DECF1013DE57C96B0F214/"},
        {name = "Vagrant", url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756329310/FEBDC9CB90C879DFC4ECAE1BBDDA857DBF9CD95C/"},
        {name = "Gladiator", url = "https://steamusercontent-a.akamaihd.net/ugc/16433884667023926/65F0E372EB9EEF805369BB5F766846F066BD62AF/"},
        {name = "Jailor", url = "https://steamusercontent-a.akamaihd.net/ugc/10906121492486022753/B8147FE9BB8652380D0027EB4AF0C7FF8C7C66AE/"},
        {name = "Cheat", url = "https://steamusercontent-a.akamaihd.net/ugc/14685838847886183596/2F910C564507478E736E783C2B01011BF710E3D0/"},






        {name = "The Noxious Battery",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302166144247/F28FED589189A2A0EFFF6586F9A83E34840FC439/"},

        {name = "Black Creek Pirates",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754407173/8AE59004E86A18683681D2677C685D8C84B00E78/"},
        {name = "Workshop Marquise",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754408441/8EB77D6898CC9B9787C1C07870405CFAE0101509/"},
        {name = "Spinners of Mercy",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754416260/AE57D54645432C8981422F9051666710651D0A7B/"},
        {name = "Arachnid Association",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754417443/B754FCCED4E254960BE764B064689FC9A5DC63BA/"},
        {name = "Arachnid Association II",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526446511/9AE39070D94704577D502A7272E2C2BBA280EEB0/"},
        {name = "Necropossums Cabal",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754421552/0ECC6133A89142CFD3BB9C8DCE77DD80B42DAEFF/"},

        {name = "United Dove Corps",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754429271/C57C13B0F3F728DD0D45B09F7FB280173116DEDD/"},
        {name = "United Dove Corps II",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320725210985400/313DDA3DC787AD1250E67BEB6D15C9CC521F0CA2/"},

        {name = "The Law of Slug",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130778170/778A62D63760B4120D313DC353057CA33D462093/"},
        {name = "Grouch",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130982247/6DA4C7DB07CDE7A8816778BC17EB204D82525DBD/"},
        {name = "Bone Patrol",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130783070/891450842D245D61990A8B72A20DE9845CE8BF28/"},
        {name = "The Winged Menace",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130772512/5224E0C4368F481102D897EEBF414FA3C2D45028/"},
        {name = "Croakers Coven",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130781664/CFA0D3E4F26C6801C757C3353FE5DC5A41DC3464/"},
        {name = "Old Man Tinker",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130777020/80BF4930BB27FA1E2A7A239C0A7974063F5C2525/"},



        {name = "Dawn of the Marquistadors",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422718057/A8AAC9571CC9982B09392B55E9E751BE319BEA8B/"},
        {name = "Eyrie's End",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422738170/CF032C0C50839D92BE2F0A4A2FFACB24C5C3F005/"},

        {name = "Advanced Setup",url = "https://steamusercontent-a.akamaihd.net/ugc/1833522185814719458/237945A7E3C9DE1967AE096BD09BE1F7829476C0/"},
        {name = "Law of Root",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402719828856/442D99DF43D27564672F46E7B94389838E77EBB7/"},
        {name = "Hirelings",url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948809300312/E3C3019162AAD66652E8C4AB388D47FE777E5A9E/"},
        {name = "Landmarks",url = "https://steamusercontent-a.akamaihd.net/ugc/12936154875885790386/85439BAAE5C809A82FAF83A96E5232DFF4152DD0/"},
        {name = "Faction Select",url = "https://steamusercontent-a.akamaihd.net/ugc/1858304668138699983/C44EA2A82303E48DE0BF8014D328132B2254D498/"},

        {name = "Battle Mat",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872326632/BBBD16CCB2233145C130F362BD4772B701C7DF2D/"},
        {name = "Koffin Keeper",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872328873/9643C19226CC90278C43552680153DDF15418A5A/"},
        {name = "Lizard Wizard",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872331088/3CE6C8D9633EBD9DF25142BA43A97E9B35F01AE4/"},
        {name = "Mole Monger",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872336052/05940C3730A58F0B71A020D512486BB890F45550/"},
        {name = "Faction Selector Tool",url="https://steamusercontent-a.akamaihd.net/ugc/16420027251539310/A450741E43546370C6509D413D2CA3F1DABCBFAC/"},
        {name = "Mini-Mood Manager",url="https://steamusercontent-a.akamaihd.net/ugc/1782839567653163566/583C3FE604C4B4E943BD914071325274C515E9D8/"},
        {name = "Bat Bungler",url="https://steamusercontent-a.akamaihd.net/ugc/14651271115865573647/F4976C56FFA40862183EC055ED9F908FA96DC2B3/"},

        {name = "Items",url="https://steamusercontent-a.akamaihd.net/ugc/12996382395453116197/45486599501A1D46FA13087CA986ED5521F7835C/"},





        {name = "Autumn Map",url = "https://steamusercontent-a.akamaihd.net/ugc/9338841708247799860/688C6CB9F5A34B2A2B067C6DA493AD653B7D9C6A/"},
        {name = "Winter Map",url = "https://steamusercontent-a.akamaihd.net/ugc/12863190738702993416/F9C676622A48D6E15BB3AE235E26CE7BC8D11283/"},
        {name = "Lake Map",url = "https://steamusercontent-a.akamaihd.net/ugc/11224158918879846636/C034E1855CED11FD28D76E3020D629478FABD195/"},
        {name = "Mountain Map",url = "https://steamusercontent-a.akamaihd.net/ugc/17146621840035729417/55256EFBD832F89B16ADAF98A382D4BF09162487/"},
        {name = "Marsh Map",url = "https://steamusercontent-a.akamaihd.net/ugc/12189840401890527004/1A5500DF801E01874A28C059E04D049043948426/"},

        {name = "Summer Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224423110603/C3BC80DD5A0F72966665CAC14BECEEED1B02A692/"},

        {name = "Gorge Map",url = "https://steamusercontent-a.akamaihd.net/ugc/17163206417596942920/65DEC204EF54C27F6BAFE8202D3AE63F73D28DD3/"},
        
        {name = "Deep Woods Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755429411/8C1C77B62B18F620F24053812DC4B32DAE8FD86D/"},
        {name = "Wastelands Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755559172/F8B13B88C817D4BC1C4262DB09E109F84484148A/"},
        {name = "Narrows and Islets Map", url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755465538/44001F9D0FA1F134FE63DE2720B367CF00F17D24/"},
        {name = "Tropics Map", url = "https://steamusercontent-a.akamaihd.net/ugc/1782840088903024368/D45A2DD6DA43C27CAA47C56305C8E1B0A053F881/"},

        {name = "Blighted Grove Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16430283484922818/2C537178499FF02869872FC4CEE2493C089026E8/"},

        {name = "Standard Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1791848789393178780/9438FC204F346D081D3E66A95BBEAC918288004A/"},
        {name = "Exiles and Partisans Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1791848789393180099/504416827060BE54A0038F2C9BCF5D5A9475367F/"},
        {name = "Squires and Disciples Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/16423108253239612/4B2CC3EBFD87C25AD92E61110CF80A5C0E461BD6/"},
        {name = "Dark Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1759199733286355061/7CC669574FB8C2836047540B51419475D35EA270/"},



        {name = "Tools", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721070945/3B57F7CCBEDB396CEB70481769051D7CD491CAFB/"},









        {name = "Root Logo", url="https://steamusercontent-a.akamaihd.net/ugc/1859433104053130905/247FAE492208FF3BEFACE423A31B8D7644BA7B19/"},
        {name = "Credits",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872500988/79BC1C2E8411DCAFADF7C9B7D094F2273CC38E87/"},

        
        {name = "Ehss and Slug Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1782839103935392102/0927F44D64B56538A6E2A028FF30126D6652702C/"},
        {name = "JustinInExile Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635528179522/0F18B9473BA94C17D367FD9D79F35A0EC4D9C32E/"},
        {name = "Nevakanezah Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793799439302485/F46D00FF0354D5F24AFCFB7FFFAC2EA4DDA28A11/"},
        {name = "Nevakanezah and Slug Info", url= "https://steamusercontent-a.akamaihd.net/ugc/1704036430908662468/83E53F32BC1C2149747AF4C5B35EDF2B1F5F4717/"},








        {name = "Official Content Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416136412842797/8C16959C043FF934C5D88C583AD957EE85D4B7FE/"},
        {name = "Blank Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526111266/638962CD65D3760A1FD61D0AA78EE4C496C5487E/"},





        {name = "Lost City", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239172517/D920C1D6AF1EB2D20AC4C645BA54FA5603ACB0C6/"},
        {name = "Mousehold", url="https://steamusercontent-a.akamaihd.net/ugc/11208216119893423521/6899825B194B4AE1C272FD70C8A67292943B3E06/"},
        {name = "Foxburrow", url="https://steamusercontent-a.akamaihd.net/ugc/14325117635732818978/AB011F3096FD8FDCD48FC9589DCDE8EF30A76560/"},
        {name = "Rabbit-Town", url = "https://steamusercontent-a.akamaihd.net/ugc/13209270657155809146/E83807902465C87971D45F55BE9FEF59ABA98312/"},







        
        






        {name = "Xmark",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500279761/E8108BE85DEBE1F569D9FDF951FA0D2DEA769CB8/"},











        -- Tournament Assets



        {name = "Warriors Wake",url="https://steamusercontent-a.akamaihd.net/ugc/1786233211086912182/563B6D9C9AFC31863D36B443728319131A2B4E03/"},
        {name = "Woodland Revolution", url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818215151/BD81EFECC6902E60CAFE69E4D0097FDE9B1C86EB/"},


        {name = "Black Creek Pirates II",url="https://steamusercontent-a.akamaihd.net/ugc/1874056202036022996/426F024995C896F8DFB53D5F51BA8100A213AB64/"},

        {name = "Mob Lobber",url="https://steamusercontent-a.akamaihd.net/ugc/1871806044359108580/ED91771BFC667788679555DC9F9E7E175E5A2346/"},
        {name = "Supply Knight",url="https://steamusercontent-a.akamaihd.net/ugc/16420027239829921/595B9928F56465239300E6A54C4A27E53F6E04F5/"},

        {name = "Urban Map", url="https://steamusercontent-a.akamaihd.net/ugc/1856049403360886234/7DACC2ADA249351AA203BD55EEABE021F13D7AB5/"},






        -- New Fan Factions // 11/11/2024



        {name = "Host of Light",url = "https://steamusercontent-a.akamaihd.net/ugc/16420027245496603/0CEAE160AA06FE2B5EBF9C9586CDD385368F0A21/"},





    }

    _G['Roster'] = {}
    _G['DraftedFactions'] = {"","","","","",""}
    _G['TurnOrder'] = {}
    _G['ColorsTaken'] = {}
    vagabondChosen = false
    -- THE SIX-COLOUR LITERAL IS GONE. It sat here assigning a turn order on every single load, after
    -- the seat record had already been restored and published a line above -- so a resumed game
    -- briefly ran an order that contradicted its own record. It is also the line the commit that
    -- first switched the turn system on identified as the reason nothing worked: Turns.enable was
    -- never assigned anywhere, so this was the only Turns statement in the file and it did nothing
    -- but overwrite. rttEnableTurns owns the order now, and it derives it from the seats.


    -- RTT m640: onLoad setCustomAssets removed (cold-load blank fix). The saved
    -- CustomUIAssets carries only the icons referenced by the retained setup UI, so the
    -- setup UI renders from them directly; this frame-100 table-replace fired before
    -- the Steam assets finished downloading on a cold cache and blanked the buttons
    -- with no re-render (only a 2nd/warm load recovered).

  end

end

local lastSuccess = 10

local draftBotNames = {"draftCatBot","draftBirdBot","draftWABot","draftVagaBot","draftLizBot","draftOtterBot","draftMoleBot","draftCrowBot"}
local draftBotDefaultColor = "#DDDDFF"

local draftBotColors = {}
draftBotColors["draftCatBot"] = "#d77435"
draftBotColors["draftBirdBot"] = "#4776b6"
draftBotColors["draftWABot"] = "#6bb659"
draftBotColors["draftVagaBot"] = "#808080"
draftBotColors["draftLizBot"] = "#DFD835"
draftBotColors["draftOtterBot"] = "#54ABA6"
draftBotColors["draftMoleBot"] = "#DBB89B"
draftBotColors["draftCrowBot"] = "#512870"

local inactiveLandmarkColor = "#222222"
local activeLandmarkColor = "#DDDDDD"
local landmarkNames = {"draftLegendaryForge","draftTheFerry","draftLostCity","draftTheTower","draftBlackMarket","draftElderTreetop","draftFoxburrow","draftRabbit-Town","draftMousehold"}
_G['DraftedLandmarks'] = {}

local draftedFactions = {}
local vagabondCards = {}
local overallPlayerCount
local draftedHirelings = {}

local hirelingsSelected = false

local draftCardOptions = {}

local selectedHirelings = {}

local redTaken = false

function startingReset()
  self.reload()
end


_G['BotRoster'] = {}












local handScale = {20,6,4}
local handRotations = {{0,0,0},{0,180,0}}
local handPositions = {{52.00,14.62,-64.00},{0.00,14.62,-64.00},{-52.00,14.62,-64.00},{-52.00,14.62,64.00},{0.00,14.62,64.00},{52.00,14.62,64.00}}




local setupColors = {"Red","Yellow","Orange","Teal","Green","Brown"}










local priorityClearingMarkerLocations = {
  {-- Autumn
    {-23.02, 11.70, 17.09},{21.78, 11.63, 11.88},{15.39, 11.63, -14.30},{-22.06, 11.69, -15.88},{1.91, 11.66, 21.41},{20.49, 11.63, -4.76},
    {1.18, 11.65, -15.25},{-6.23, 11.66, -14.21},{-23.95, 11.69, 5.44},{-1.48, 11.67, 12.02},{3.65, 11.66, 1.30},{-9.18, 11.67, 1.52}
  },
  {-- Winter
    {-21.79, 11.72, 18.71},{21.23, 11.64, 15.45},{16.46, 11.63, -13.11},{-22.44, 11.69, -12.69},{-6.23, 11.67, 19.64},{4.84, 11.66, 16.07},
    {24.20, 11.63, -4.37},{1.12, 11.65, -10.71},{-6.55, 11.66, -13.24},{-19.97, 11.69, 0.16},{-7.23, 11.67, 4.44},{8.84, 11.65, -0.09}
  },
  {-- Lake
    {18.20, 11.63, -13.44},{-18.33, 11.69, 18.58},{-23.42, 11.69, -14.65},{23.84, 11.63, 9.19},{22.98, 11.63, -1.33},{12.14, 11.65, 15.14},
    {-1.57, 11.67, 21.56},{-22.90, 11.69, 5.10},{-6.04, 11.66, -16.63},{-11.59, 11.68, 10.20},{11.31, 11.64, 2.68},{-11.31, 11.67, -7.41}
  },
  { -- Mountain
    {-19.56, 11.69, 19.37},{20.22, 11.64, 15.43},{21.28, 11.63, -11.86},{-20.33, 11.68, -16.71},{4.28, 11.66, 18.60},{23.77, 11.63, -0.81},
    {0.38, 11.65, -14.64},{-22.93, 11.69, 0.09},{-13.78, 11.68, 10.17},{1.91, 11.66, 7.39},{9.67, 11.64, -7.80},{-10.84, 11.67, -3.57},
  },
  { -- Gorge -- nitrorev helped
    {-21.19, 11.72, 17.05},{21.12, 11.64, 17.43},{15.24, 11.63, -17.04},{-15.53, 11.68, -14.91},
    {4.14, 11.66, 18.88},{16.74, 11.64, 8.59},{-3.78, 11.66, -12.57},{-17.83, 11.68, -2.40},
    {22.26, 11.63, -4.82},{-18.71, 11.69, 5.49},{0.32, 11.66, 11.18},{-0.60, 11.66, -3.02}
  },
  { -- Treasure Island -- has 13 clearings
    {-20.73, 11.69, 16.97},{23.46, 11.63, 13.58},{21.41, 11.63, -15.83},{-22.22, 11.69, -15.64},{8.05, 11.65, 14.15},{23.05, 11.63, 3.28},
    {0.80, 11.65, -18.52},{-21.82, 11.69, -2.32},{-3.88, 11.67, 20.09},{-7.16, 11.67, 6.62},{-2.28, 11.66, -8.29},{14.39, 11.64, -5.48},
    {-2.57, 11.66, 2.24}
  },
  { -- Deep Woods -- special setup

  },
  { -- Wastelands
    {15.55, 11.71, -16.84},{-17.72, 11.70, 13.97},{-18.21, 11.69, -13.34},{20.51, 11.72, 12.30},{1.77, 11.71, 21.80},{-9.76, 11.71, 21.58},
    {-24.42, 11.69, -6.27},{3.66, 11.71, -13.43},{24.18, 11.71, -4.04},{-4.87, 11.71, 9.32},{-6.86, 11.70, -5.23},{6.06, 11.71, -0.59}
  },
  { -- Australia -- nitrorev helped
    {-19.41, 11.69, 6.84},{21.01, 11.63, -3.45},{-19.85, 11.69, -1.84},{18.45, 11.64, 5.63},{-20.39, 11.69, -9.23},{17.20, 11.64, 14.11},
    {13.24, 11.64, -14.79},{-9.45, 11.68, 12.00},{7.05, 11.65, 11.47},{1.40, 11.66, -3.00},{-3.23, 11.66, -3.11},{-3.27, 11.67, 12.71}
  },
  { -- Narrows & Islets -- 15 clearings!
    {8.37, 11.65, 17.96},{-19.48, 11.68, -14.18},{-6.32, 11.67, 16.78},{12.50, 11.64, -9.50},{14.76, 11.64, 10.43},{-1.27, 11.65, -7.61},
    {-9.27, 11.66, -12.39},{-17.30, 11.68, -5.89},{0.54, 11.66, 11.46},{5.60, 11.65, -1.12},{-11.39, 11.67, -5.71},{-11.05, 11.67, 2.85},
    {-2.94, 11.66, -1.54},{4.41, 11.65, 13.19},{-5.48, 11.67, 8.62}

  },
  { -- Tunnel Unraveled -- Has its own clearings

  },
  { -- Tropics
    {-12.57, 11.68, 16.57},{16.40, 11.64, 13.49},{8.22, 11.64, -15.62},{-18.48, 11.68, -7.11},{-9.84, 11.67, 8.31},{10.55, 11.65, 4.19},
    {6.32, 11.65, -7.26},{-9.39, 11.67, -14.59},{-18.40, 11.69, 7.53},{2.92, 11.66, 13.49},{12.32, 11.64, -6.28},{-2.83, 11.66, -4.92}
  },
  {-- Summer
    {-23.02, 11.70, 17.09},{21.78, 11.63, 11.88},{15.39, 11.63, -14.30},{-22.06, 11.69, -15.88},{1.91, 11.66, 21.41},{20.49, 11.63, -4.76},
    {1.18, 11.65, -15.25},{-6.23, 11.66, -14.21},{-23.95, 11.69, 5.44},{-1.48, 11.67, 12.02},{3.65, 11.66, 1.30},{-9.18, 11.67, 1.52}
  },
  { -- Lost Woodland -- nitrorev helped
    {-18.73, 11.66, 22.07},{20.18, 11.66, 24.20},{21.91, 11.66, -13.88},{-22.86, 11.66, -15.13},{-10.87, 11.66, 22.48},{23.20, 11.66, 12.76},
    {-6.59, 11.66, -14.61},{-20.50, 11.66, 3.59},{8.08, 11.66, 23.68},{20.66, 11.66, -5.97},{2.85, 11.66, -9.86},{-11.13, 11.66, -1.15},
    {-15.54, 11.66, 14.22},{10.37, 11.66, 13.15},{0.67, 11.72, 7.72},{5.52, 11.66, 0.32}

  },
  { -- Legends -- nitrorev helped
    {-23.37, 11.68, 17.65},{23.42, 11.62, 18.74},{24.29, 11.63, -16.28},{-24.20, 11.69, -14.37},{-0.72, 11.65, 21.60},{22.35, 11.63, 3.31},
    {2.18, 11.65, -12.39},{-24.10, 11.68, -0.07},{-10.84, 11.67, 11.11},{12.73, 11.64, 13.54},{-10.49, 11.67, -3.31},{5.55, 11.65, 3.25}

  },
  { -- Urban -- nitrorev helped
    {-23.16, 11.70, 20.90},{17.57, 11.64, 17.17},{21.81, 11.63, -12.25},{-22.38, 11.69, -12.22},{-2.38, 11.65, 20.93},{23.65, 11.63, 2.01},
    {2.03, 11.65, -13.48},{-18.39, 11.69, 1.87},{3.66, 11.66, 18.09},{4.72, 11.65, 5.89},{-5.07, 11.67, -3.47},{-4.48, 11.67, 9.57}
  },
  {
    -- River Town
    {-12.35, 11.67, 6.07},{10.67, 11.64, 4.67},{4.77, 11.65, -2.67},{-4.81, 11.66, -5.80},{-23.08, 11.69, 18.43},{21.03, 11.63, 13.22},
    {17.30, 11.63, -13.46},{-15.71, 11.67, -16.52},{-22.60, 11.69, 2.51},{-4.33, 11.67, 19.44},{21.55, 11.63, 4.01},{1.87, 11.65, -15.70},
  },
  {
    -- Mountainside
    {11.89, 11.65, 12.91},{19.23, 11.65, -12.24},{-20.98, 11.65, -17.06},{-23.38, 11.65, 7.99},{18.12, 11.65, 3.66},{0.78, 11.65, -14.47},
    {-21.42, 11.65, -9.63},{-0.95, 11.65, 20.24},{9.05, 11.65, -1.22},{-8.88, 11.65, -6.11},{-14.76, 11.65, 2.71},{-1.44, 11.65, 10.30}
  },
  {-- Tidal Flats
    {-17.80, 11.69, 14.58},{21.85, 11.63, 13.94},{19.51, 11.63, -13.17},{-19.52, 11.68, -13.35},{4.56, 11.66, 19.03},{19.55, 11.64, 8.45},
    {21.73, 11.63, -8.47},{-2.69, 11.66, -13.19},{-21.26, 11.69, -1.05},{-19.92, 11.69, 9.45},{0.12, 11.66, 10.57},{10.52, 11.64, -7.05},
    {-13.67, 11.68, -5.95}
  },
  { -- Blighted City
    {-23.89, 11.70, 18.49},{18.75, 11.64, 19.95},{22.01, 11.63, -12.25},{-24.14, 11.69, -16.12},{0.09, 11.67, 21.55},{24.06, 11.63, 1.95},
    {-4.29, 11.66, -13.24},{-23.76, 11.69, -0.76},{-13.81, 11.68, 10.17},{9.65, 11.65, 12.28},{9.96, 11.64, -3.87},{-14.57, 11.68, -6.13},
    {-0.86, 11.66, -3.42}
  },
  { -- Taiga
    {-24.21, 11.69, 15.51},{22.13, 11.63, 14.21},{23.07, 11.62, -11.33},{-24.28, 11.68, -16.33},{-4.52, 11.67, 17.52},{22.23, 11.63, -1.54},
    {-23.63, 11.69, -1.74},{2.56, 11.65, 4.42},{2.56, 11.65, 4.42},{12.14, 11.64, -6.81},{-7.61, 11.66, -10.07},{-13.79, 11.67, 0.00}
  },
  { -- Gloom
      {-18.77, 11.69, 20.29},{23.43, 11.63, 16.11},{20.47, 11.63, -17.53},{-22.19, 11.69, -16.25},{1.97, 11.66, 19.70},{20.68, 11.63, -2.86},
      {5.21, 11.65, -18.11},{-7.32, 11.67, -13.22},{-21.59, 11.69, 0.41},{-9.60, 11.68, 9.16},{6.93, 11.65, 7.11},{-1.81, 11.66, -2.45}
  },
  { -- Klacar's Volcano Island
      {13.85, 11.64, -10.14},{-18.52, 11.69, 14.76},{18.12, 11.64, 12.62},{-21.94, 11.69, -8.40},{20.78, 11.63, 4.23},{-19.83, 11.69, 2.82},
      {5.78, 11.66, 16.35},{-4.74, 11.66, -12.26},{-10.31, 11.68, 9.49},{6.24, 11.65, -13.85},{-6.74, 11.67, -2.26},{2.33, 11.66, 4.59}
  },
  { -- SPACEBALLS -- Unknown
      {63.33, 11.56, -7.57},{65.43, 11.56, -7.57},{67.53, 11.56, -7.57},{63.33, 11.56, -9.40},{65.43, 11.56, -9.40},{67.53, 11.56, -9.40},
      {63.33, 11.56, -11.23},{65.43, 11.56, -11.23},{67.53, 11.56, -11.23},{63.33, 11.56, -13.07},{65.43, 11.56, -13.07},{67.53, 11.56, -13.07},
      {63.33, 11.56, -14.90},{65.43, 11.56, -14.90},{67.53, 11.56, -14.90}
  },
  { -- INFERNO -- Unknown
      {63.33, 11.56, -7.57},{65.43, 11.56, -7.57},{67.53, 11.56, -7.57},{63.33, 11.56, -9.40},{65.43, 11.56, -9.40},{67.53, 11.56, -9.40},
      {63.33, 11.56, -11.23},{65.43, 11.56, -11.23},{67.53, 11.56, -11.23},{63.33, 11.56, -13.07},{65.43, 11.56, -13.07},{67.53, 11.56, -13.07},
      {63.33, 11.56, -14.90},{65.43, 11.56, -14.90},{67.53, 11.56, -14.90}
  },

  { -- Blighted Grove
    {-22.79, 11.70, 17.47},{18.45, 11.64, 19.13},{21.65, 11.65, -17.43},{-22.56, 11.71, -15.57},{1.65, 11.67, 17.19},{21.24, 11.64, -0.31},
    {0.83, 11.67, -11.95},{-24.19, 11.71, 1.23},{-9.03, 11.68, 3.70},{0.24, 11.67, -2.27}
  },

  { -- Gorge Original -- nitrorev helped
    {-14.24, 11.69, 19.60},{20.20, 11.64, 16.05},{12.34, 11.64, -15.74},{-13.41, 11.67, -15.64},{4.86, 11.66, 18.32},{11.38, 11.65, 8.56},
    {-3.30, 11.66, -13.14},{-17.16, 11.68, -1.17},{15.58, 11.64, -0.91},{-13.05, 11.68, 8.56},{0.47, 11.66, 11.19},{4.80, 11.65, -0.65}
  },
  { -- Marsh -- Unknown
    {63.33, 11.56, -7.57},{65.43, 11.56, -7.57},{67.53, 11.56, -7.57},{63.33, 11.56, -9.40},{65.43, 11.56, -9.40},{67.53, 11.56, -9.40},
    {63.33, 11.56, -11.23},{65.43, 11.56, -11.23},{67.53, 11.56, -11.23},{63.33, 11.56, -13.07},{65.43, 11.56, -13.07},{67.53, 11.56, -13.07},
    {63.33, 11.56, -14.90},{65.43, 11.56, -14.90},{67.53, 11.56, -14.90}
  },

  


}







local redFactionTaken = false





local vagabondsTaken = 0




local allowedFactions = {false, false, false, false, false, false, false, false, false, false, false, false, false, false}

















function infoEhssAndSlug() setInfo("Ehss and Slug Info") end



function infoNevakanezah() setInfo("Nevakanezah Info") end
function infoNevakanezahAndSlug() setInfo("Nevakanezah and Slug Info") end



function infoOfficialContent() setInfo("Official Content Info") end



-- infoGinso removed with the Gizmo button (no hover, no button -- it is always on).







_G['WWLineUp'] = {}
_G['WWSelected'] = {"","","","","","","","","",""} -- 10 slots
_G['WWTimer'] = 50


function table.clone(org)
  return {table.unpack(org)}
end



_G['WWMaps'] = {}
_G['WWMaps']['Official'] = {'Autumn','Winter','Lake','Mountain'}
_G['WWMaps']['Homebrew'] = {'Australia','The Deep Woods','Gorge','Legends','Summer','Treasure Island','The Wastelands'}
_G['WWDecks'] = {}
_G['WWDecks']['Official'] = {'Standard','Exiles and Partisans'}
_G['WWDecks']['Homebrew'] = {'Action! Deck Booster','Dark','60 Card Master','Sorcery of the Enchanted Woods','Upstarts and Renegades'}
_G['WW54Decks'] = {'Standard','Exiles and Partisans','Upstarts and Renegades','Sorcery of the Enchanted Woods'}


----#CHECKPOINT------










_G['WWOfficialRed'] = {"Marquise de Cat", "Eyrie Dynasties", "Underground Duchy", "Lord of the Hundreds", "Keepers in Iron"}
_G['WWOfficialGray'] = {"Woodland Alliance", "Vagabond","The Lizard Cult", "Riverfolk Company", "Corvid Conspiracy"}
_G['WWHomebrewRed'] = {"Eyrie\'s End", "Dawn of the Marquistadors", "Workshop Marquise", "Warriors Wake"}
_G['WWHomebrewGray'] = {"Old Man Tinker", "Necropossums Cabal", "Arachnid Association II", "Croakers Coven", "The Noxious Battery",
                      "Bone Patrol", "Black Creek Pirates II", "Spinners of Mercy", "The Winged Menace", "Woodland Revolution",
                      "United Dove Corps II", "Doomed Swindler", "Grouch", "Doomed Berserker", "Doomed Bard", "Doomed Blacksmith",
                      "Doomed Zealot", "Doomed Barkeep"}
_G['WWVagabonds'] = {"Adventurer","Arbiter","Harrier","Ranger","Ronin","Scoundrel","Thief","Tinker","Vagrant"}
_G['WWHomebrewVagabonds'] = {"Grouch","Doomed Blacksmith","Doomed Swindler","Doomed Bard","Doomed Barkeep","Doomed Zealot", "Doomed Berserker"}

_G['WWOfficialRedSubset'] = {}
_G['WWOfficialGraySubset'] = {}
_G['WWHomebrewRedSubset'] = {}
_G['WWHomebrewGraySubset'] = {}
_G['WWFacSelector'] = 1
_G['WWVagabondsTaken'] = 0


_G["WWAdsetCardFaces"] = {}

_G["WWAdsetCardFaces"]["Marquise de Cat"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934562341/94B4D774E074EF5BEADCB464EEC7F919CE5D97D4/"
_G["WWAdsetCardFaces"]["Eyrie Dynasties"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934563069/3299BEBC4C3BBBFE460DEF47340A0B15B2EA4D3C/"
_G["WWAdsetCardFaces"]["Woodland Alliance"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934565089/1CABD8BB3B69ECBD33E3B26737DCCFA49B6F5E73/"
_G["WWAdsetCardFaces"]["Vagabond"] = "https://steamusercontent-a.akamaihd.net/ugc/1835787942529722117/BA5DC63CB14B76FE0B786AC2646C848A9A252BFD/"
_G["WWAdsetCardFaces"]["The Lizard Cult"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934567070/B8FF9D87E830C2046DA471192AAE30D349E55842/"
_G["WWAdsetCardFaces"]["Riverfolk Company"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934566692/C5C3A6295E2F6027FAC396F397105EB7C6F63811/"
_G["WWAdsetCardFaces"]["Underground Duchy"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934563504/7290C5EA6460B6272F606E7F2431DBC8E439358D/"
_G["WWAdsetCardFaces"]["Corvid Conspiracy"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934567421/7F3BBDAADF9B907E258264469E37D40299C156EE/"
_G["WWAdsetCardFaces"]["Lord of the Hundreds"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934563997/C48C8711373FAA1EC959B02DFCFA35CBAC608B04/"
_G["WWAdsetCardFaces"]["Keepers in Iron"] = "https://steamusercontent-a.akamaihd.net/ugc/1835788265934564418/C438F3D3D4CF77DACEBA32F3735FCC45285D25B2/"

_G["WWAdsetCardFaces"]["Adventurer"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920031568/9FDA298CAA9675B5DDAC29F1AA1C19DA44AC4BBF/"
_G["WWAdsetCardFaces"]["Arbiter"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920017905/80BF0B8B6BC138E676AF31B3055DF2124E7F2F4B/"
_G["WWAdsetCardFaces"]["Harrier"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920035989/3748A07E731D02DC842DFA4D3A92481E4B082D51/"
_G["WWAdsetCardFaces"]["Ranger"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920013866/D250C9591D68B83499A8952BCA5C684F04E13980/"
_G["WWAdsetCardFaces"]["Ronin"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920040196/8328799796E99F07C70A40E7672868F5167091DF/"
_G["WWAdsetCardFaces"]["Scoundrel"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920022394/8AD75E0065109B2350D989D473EBEC170E92BB60/"
_G["WWAdsetCardFaces"]["Thief"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920003055/2817F237F33C253197D96E9534C17004F2B3D661/"
_G["WWAdsetCardFaces"]["Tinker"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787920007980/31E9550DB276915F3EA1F27CD387ADCE81657B2E/"
_G["WWAdsetCardFaces"]["Vagrant"] = "https://steamusercontent-a.akamaihd.net/ugc/792008787919989189/87AA5C7CE4192FBC0900B24EC7DEAB95110CAB94/"

_G["WWAdsetCardFaces"]["Dawn of the Marquistadors"] = "https://steamusercontent-a.akamaihd.net/ugc/1830157803763364012/80D3E3F0DABD7DB5AD02576DE84C8D2C058E7DC9/"
_G["WWAdsetCardFaces"]["Eyrie's End"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602018545/D10E883DA9C8CA1D21A20107E8B3964B7C8FD6AF/"
_G["WWAdsetCardFaces"]["Workshop Marquise"] = "https://steamusercontent-a.akamaihd.net/ugc/1838030727459786230/1D6F97882D0CA488F872BED20BF15A0E1FFC3CBC/"
_G["WWAdsetCardFaces"]["Warriors Wake"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188598338285/D4B919631E3D2814A284A172AC724C8EBD97E638/"
_G["WWAdsetCardFaces"]["United Dove Corps II"] = "https://steamusercontent-a.akamaihd.net/ugc/1838031283911363609/889CEB9A6EF31B493D306636680400D1A27CDD83/"
_G["WWAdsetCardFaces"]["The Winged Menace"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188605443236/5430479DA59241216056C2DA927BA65654FC21AF/"
_G["WWAdsetCardFaces"]["The Noxious Battery"] = "https://steamusercontent-a.akamaihd.net/ugc/1838031731706445734/09D94A6A0FE64441B673ACD1FC5604D06B13E6E5/"
_G["WWAdsetCardFaces"]["Doomed Barkeep"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"
_G["WWAdsetCardFaces"]["Doomed Berserker"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"
_G["WWAdsetCardFaces"]["Arachnid Association II"] = "https://steamusercontent-a.akamaihd.net/ugc/1838030916025840794/8B1AFD7C2356027B4A7DB11275FFDBB26F92871B/"
_G["WWAdsetCardFaces"]["Spinners of Mercy"] = "https://steamusercontent-a.akamaihd.net/ugc/1867301389180149376/CA21C6BD3BD6BDDFC59E2FAB811A40EB16BC36F2/"
_G["WWAdsetCardFaces"]["Doomed Bard"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"
_G["WWAdsetCardFaces"]["Croakers Coven"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188605515942/3A871BCEA16174042234C178DEABD3B3F6BD0315/"
_G["WWAdsetCardFaces"]["Doomed Blacksmith"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"
_G["WWAdsetCardFaces"]["Necropossums Cabal"] = "https://steamusercontent-a.akamaihd.net/ugc/1838030916025950391/20D12721D649E0FB360DB443E290E6CB62768538/"
_G["WWAdsetCardFaces"]["Bone Patrol"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188604059656/45989E8388A73FB1BFC913EE09B77761BB00E702/"
_G["WWAdsetCardFaces"]["Woodland Revolution"] = "https://steamusercontent-a.akamaihd.net/ugc/1838030916025497145/5FEF49903F35C2B7DE82ABCAC195434C19F64C73/"
_G["WWAdsetCardFaces"]["Grouch"] = "https://steamusercontent-a.akamaihd.net/ugc/1835787942529722117/BA5DC63CB14B76FE0B786AC2646C848A9A252BFD/"
_G["WWAdsetCardFaces"]["Black Creek Pirates II"] = "https://steamusercontent-a.akamaihd.net/ugc/1829027562284717626/0B768C5CCE87116FB5C13A2CE0314A04C099C135/"
_G["WWAdsetCardFaces"]["Old Man Tinker"] = "https://steamusercontent-a.akamaihd.net/ugc/1871808701914097125/A1B303EAF2911FD003482BB2D511D2FBB4DCB403/"
_G["WWAdsetCardFaces"]["Doomed Zealot"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"
_G["WWAdsetCardFaces"]["Doomed Swindler"] = "https://steamusercontent-a.akamaihd.net/ugc/1799745188602019195/FFEDDC03F92F3690B27BE82B04E6B619A4474692/"

_G["WWHomebrewVagabondFaces"] = {}
_G["WWHomebrewVagabondFaces"]["Doomed Swindler"] = "https://steamusercontent-a.akamaihd.net/ugc/1697277908217697184/3797D6BBB63EBA15DB63AE6D6F15111A311D0F56/"
_G["WWHomebrewVagabondFaces"]["Doomed Zealot"] = "https://steamusercontent-a.akamaihd.net/ugc/1756947110726833658/F7591792EEC70DAA65F0202FC769E492EB014E53/"
_G["WWHomebrewVagabondFaces"]["Doomed Blacksmith"] = "https://steamusercontent-a.akamaihd.net/ugc/1755820943818624505/791BAE685873E062B8EB8359006BD90230DDEA9C/"
_G["WWHomebrewVagabondFaces"]["Doomed Berserker"] = "https://steamusercontent-a.akamaihd.net/ugc/1755820943820932760/09358C3415355BCD25C0B5204E48850ED250A451/"
_G["WWHomebrewVagabondFaces"]["Doomed Bard"] = "https://steamusercontent-a.akamaihd.net/ugc/1756947477064412199/F552281EEEB312E45FE5657766CA79853DC64886/"
_G["WWHomebrewVagabondFaces"]["Doomed Barkeep"] = "https://steamusercontent-a.akamaihd.net/ugc/1755820943820933573/EC1111A451825CAC4FF7942271ABA6D213EBEBAC/"
_G["WWHomebrewVagabondFaces"]["Grouch"] = "https://steamusercontent-a.akamaihd.net/ugc/1758065039320526659/10CFC98366787FBC60F26C949F487B7D29852822/"




_G['PlayerColors'] = {"#E53F36","#F5E850","#F68B57","#64BBBD","#6DBA5A","#A07641"}
_G['WWRosterSelector'] = 0
_G['WWPlayerSetupMode'] = false










function tableHasElement(table, element)
  for a = 0, #table do
    if table[a] == element then
      return true
    end
  end
  return false
end

function isDoomedVagabond(faction)
  local dvs = {"Doomed Swindler", "Grouch", "Doomed Berserker", "Doomed Bard", "Doomed Blacksmith", "Doomed Zealot", "Doomed Barkeep"}
  return tableHasElement(dvs,faction)
end













local hirelingMarkerLocations = {
   -- Autumn
   {{-4.74,11.66,-21.28},{-10.99,11.67,-21.29},{-17.23,11.68,-21.26}},
   -- Winter
   {{-4.68,11.66,-21.30},{-10.91,11.67,-21.36},{-17.18,11.68,-21.35}},
   -- Lake
   {{-4.74,11.66,-21.47},{-10.99,11.67,-21.47},{-17.25,11.68,-21.47}},
   -- Mountain
   {{-4.56,11.66,-21.32},{-10.81,11.67,-21.33},{-17.08,11.68,-21.34}},
   -- Gorge
   {{-4.69, 11.66, -21.36},{-10.97, 11.67, -21.36},{-17.25, 11.68, -21.36}},
   -- Treasure Island
   {{-4.62,11.66,-21.41},{-10.90,11.67,-21.41},{-17.16,11.68,-21.42}},
   -- Deep Woods
   {{-4.74,11.66,-21.32},{-10.92,11.67,-21.31},{-17.21,11.68,-21.35}},
   -- The Wastelands
   {{-4.74,11.70,-21.32},{-10.92,11.69,-21.31},{-17.21,11.69,-21.35}},
   -- Australia
   {{-4.80,11.66,-23.86},{-10.29,11.67,-23.86},{-15.78,11.67,-23.86}},
   -- Narrows & Islets
   {{-7.93,11.66,-20.67},{-13.42,11.67,-20.67},{-18.92,11.67,-20.67}},
   -- Tunnel Unraveled
   {{-8.41,11.67,-9.53},{-13.83,11.67,-9.53},{-19.26,11.68,-9.53}},
   -- Tropics
   {{-4.55,11.66,-20.19},{-10.59,11.67,-20.23},{-16.55,11.67,-20.20}},
   -- Summer
   {{-4.74,11.66,-21.28},{-10.99,11.67,-21.29},{-17.23,11.68,-21.26}},
   -- Lost Woodland
   {{-4.83,11.72,-24.16},{-11.11,11.72,-24.15},{-17.38,11.72,-24.14}},
   -- Legends
   {{-4.74,11.66,-21.28},{-10.99,11.67,-21.29},{-17.23,11.68,-21.26}},
   -- Urban
   {{-4.74,11.66,-21.28},{-10.99,11.67,-21.29},{-17.23,11.68,-21.26}},
   -- River Town
   {{-4.70, 11.65, -21.31},{-10.95, 11.66, -21.31},{-17.19, 11.67, -21.28}},
   -- Mountainside
   {{-4.70, 11.65, -21.31},{-10.95, 11.65, -21.31},{-17.20, 11.65, -21.28}},
   -- Tidal Flats
   {{-4.70, 11.66, -21.31},{-10.94, 11.67, -21.32},{-17.19, 11.68, -21.29}},
   -- Blighted City
   {{-4.70, 11.66, -21.11},{-10.93, 11.67, -21.07},{-17.18, 11.68, -21.08}},
   -- Taiga
   {{-4.72, 11.66, -21.30},{-10.97, 11.66, -21.30},{-17.21, 11.67, -21.27}},
   -- Gloom
   {{-4.70, 11.66, -21.31},{-10.94, 11.67, -21.32},{-17.19, 11.68, -21.29}},
   -- Klacar's Volcano Island
   {{-4.76, 11.66, -21.38},{-11.11, 11.67, -21.38},{-17.47, 11.68, -21.38}},
   -- SPACEBALLS
   {{-4.44, 11.66, -27.25},{-10.57, 11.67, -27.24},{-16.66, 11.68, -27.26}},
   -- INFERNO
   {{-1.94, 11.71, -24.82},{-8.07, 11.72, -24.81},{-14.16, 11.73, -24.82}},
   -- Blighted Grove
   {{-4.77, 11.69, -21.32},{-11.05, 11.69, -21.28},{-17.32, 11.70, -21.27}},
   -- Gorge Original
   {{-4.41,11.66,-22.99},{-10.40,11.67,-22.96},{-16.41,11.68,-22.96}},
   -- Marsh
   {{-4.67, 11.66, -21.31},{-10.92, 11.67, -21.32},{-17.16, 11.68, -21.29}},


}

local forestPatrolLocations = {
  { -- Autumn
    {-20.68,12.51,19.23},{20.73,12.45,13.13},{18.00,12.45,-15.49},{-21.48,12.50,-14.13},
    {4.20,12.48,18.59},{22.79,12.45,-0.26},{5.99,12.47,-14.33},{-8.55,12.49,-15.36},
    {-21.95,12.51,6.10},{-3.24,12.49,11.61},{8.49,12.47,2.23},{-10.69,12.49,-0.43},
  },
  { -- Winter
    {-19.78,12.51,19.56},{-7.93,12.49,17.32},{2.74,12.48,14.02},{17.33,12.46,13.69},
    {-20.81,12.51,5.17},{-5.31,12.49,2.04},{7.28,12.47,4.16},{23.11,12.45,-2.57},
    {-18.18,12.50,-16.71},{-8.22,12.49,-14.59},{5.76,12.47,-8.86},{18.84,12.45,-14.66},
  },
  { -- Lake
    {-20.38,12.51,17.29},{-3.52,12.49,20.51},{10.06,12.47,15.56},{21.24,12.45,10.48},
    {-22.79,12.51,2.52},{-12.37,12.50,7.96},{9.67,12.47,-0.05},{17.38, 11.63, -4.74},
    {-18.04,12.50,-12.16},{-6.16,12.49,-5.46},{-3.84,12.48,-15.39},{20.31,12.45,-14.43},
  },
  { -- Mountain
    {-21.93,12.51,16.58},{-9.14,12.49,9.87},{1.83,12.48,18.41},{17.89,12.46,16.02},
    {-23.34,12.51,-2.22},{-0.46,12.48,7.47},{8.25,12.47,-2.86},{19.13,12.45,2.42},
    {-16.37,12.50,-12.74},{-11.00,12.49,-6.47},{5.65,12.47,-13.92},{16.49,12.45,-15.25},
  },
  { -- Gorge
    {-19.68, 11.69, 18.87},{6.14, 11.66, 20.06},{18.53, 11.64, 17.80},
    {-14.80, 11.68, 8.12},{-1.56, 11.66, 10.91},{13.30, 11.64, 9.15},
    {-14.08, 11.68, -4.41},{-2.22, 11.66, -3.98},{21.43, 11.63, -2.50},
    {-20.28, 11.68, -16.99},{-5.57, 11.66, -13.69},{13.61, 11.64, -16.36}
  },
  { -- Treasure Island
    {-20.55,12.51,15.70},{-8.48,12.50,15.99},{4.70,12.48,10.84},{16.24,12.46,12.41},
    {-19.94,12.51,-2.50},{-9.57,12.50,7.94},{7.73,12.47,-4.72},{19.75,12.45,-0.44},
    {-15.98,12.50,-13.59},{-3.36,12.48,-10.17},{6.04,12.47,-17.67},{19.77,12.45,-15.23},
  },
  { -- Deep Woods
    {-17.98,12.51,19.31},{6.03,12.48,20.45},{19.86,12.46,14.45},
    {-6.17,12.49,11.35},{7.38,12.47,8.78},
    {-17.79,12.51,3.65},{-6.41,12.49,-3.44},{9.05,12.47,-3.34},{21.31,12.45,1.46},
    {-17.07,12.05,-12.18},{1.63,12.47,-13.10},{20.40,12.45,-12.78},
  },
  { -- Wastelands
    {-22.01,12.52,12.76},{-5.76,12.53,21.15},{3.98,12.53,20.98},{22.27,12.53,6.90},
    {-17.86,12.52,-4.45},{-6.08,12.52,4.16},{-4.39,12.52,-3.18},{3.37,12.53,1.51},{22.75,12.53,-1.55},
    {-16.92,12.51,-17.60},{9.67,12.52,-14.88},{21.68,12.53,-14.27},
  },
  { -- Australia
    {-8.53,12.53,16.08},{-2.66,12.52,10.50},{5.71,12.47,10.29},{15.12,12.46,13.25},
    {-16.24,12.50,8.19},{-14.84,12.50,-0.69},{14.49,12.52,2.11},{16.43,12.51,-6.16},
    {-16.77,12.53,-13.23},{-6.07,12.49,-4.75},{3.68,12.47,-5.76},{16.11,12.51,-17.86},
  },
  { -- Narrows & Islets
    {-2.48,12.48,18.23},{12.41,12.51,15.86},
    {-12.51,12.49,6.11},{1.90,12.47,5.49},{14.97,12.46,4.62},
    {-23.20,12.50,-7.29},{-8.26,12.49,-1.69},{10.62,12.46,-1.89},
    {-20.36,12.50,-15.54},{-10.59,12.52,-14.52},{2.57,12.47,-8.65},{12.16,12.45,-14.02},
  },
  { -- Tunnel Unraveled
    {-22.90,12.53,2.43},{-15.54,12.50,5.29},{-18.27,12.50,-1.10},
    {-10.61,12.49,5.29},{-10.51,12.49,-1.33},{-4.41,12.48,2.11},
    {0.59,12.48,-3.19},{6.03,12.47,-0.35},{6.82,12.47,-6.91},
    {14.97,12.46,4.62},{17.60,12.50,-3.36},{21.77,12.45,4.42},
  },
  { -- Tropics
    {-14.96,12.50,15.24},{-21.22,12.51,4.73},{-4.54,12.49,7.55},
    {6.88,12.47,14.47},{12.56,12.47,11.68},{15.77,12.46,2.35},
    {-18.13,12.53,-9.14},{-4.55,12.52,-3.43},{-5.02,12.48,-16.32},
    {2.52,12.47,-8.80},{15.03,12.46,-10.40},{12.73,12.46,-15.71},
  },
  { -- Summer
    {-20.68,12.51,19.23},{20.73,12.45,13.13},{18.00,12.45,-15.49},{-21.48,12.50,-14.13},
    {4.20,12.48,18.59},{22.79,12.45,-0.26},{5.99,12.47,-14.33},{-8.55,12.49,-15.36},
    {-21.95,12.51,6.10},{-3.24,12.49,11.61},{8.49,12.47,2.23},{-10.69,12.49,-0.43},
  },
  { -- Lost Woodland
    {-4.58, 12.50, -19.36},{7.54, 12.50, -8.23},
    {-22.49, 12.50, -2.72},{-13.26, 12.50, -6.14},{-1.15, 12.50, 0.50},{16.12, 12.50, -0.86},
    {-14.98, 12.50, 7.11},{-0.53, 12.50, 11.01},{10.07, 12.50, 11.90},{24.01, 12.50, 8.85},
    {-7.19, 12.50, 22.05},{4.57, 12.50, 23.62},
  },
  { -- Legends
    {-18.07, 11.67, 12.62},{-2.64, 11.65, 15.88},{19.00, 11.63, 14.64},
    {-18.36, 11.68, 2.17},{-5.95, 11.66, 7.02},{10.07, 11.64, 11.90},{18.36, 11.63, 3.33},
    {-9.34, 11.67, -4.97},{0.78, 11.65, -1.34},
    {-17.78, 11.68, -13.25},{2.26, 11.65, -14.64},{21.47, 11.63, -12.39}
  },
  { -- Urban
    {-23.07, 11.70, 19.42},{-4.61, 11.67, 20.86},{4.62, 11.66, 16.83},{19.72, 11.64, 17.41},
    {-21.08, 11.69, 0.73},{-9.43, 11.68, 8.40},{6.49, 11.65, 5.75},{19.59, 11.63, 0.78},
          {-3.36, 11.66, -4.24},
    {-20.78, 11.69, -13.04},{-2.88, 11.66, -14.47},{18.27, 11.63, -12.97}
  },
  { -- River town
    {-18.93, 11.69, 18.00},{-1.89, 11.67, 18.90},{18.12, 11.64, 15.88},{-19.99, 11.68, 1.50},
    {-8.09, 11.67, 8.35},{4.73, 11.65, 8.93},{-10.53, 11.67, -2.18},{10.77, 11.64, -3.40},
    {21.85, 11.63, -0.02},{-16.77, 11.67, -13.21},{18.22, 11.62, -17.62},{1.64, 11.65, -17.60}

  },
  { -- Mountainside
    {-4.83, 11.65, 20.37},{-20.23, 11.65, 11.35},{-12.06, 11.65, 5.77},{0.09, 11.65, 7.08},
    {16.07, 11.65, 12.44},{24.07, 11.65, 1.82},{5.24, 11.65, -4.75},{14.10, 11.65, -12.42},
    {-18.20, 11.65, -6.94},{-7.98, 11.65, -10.29},{-2.18, 11.65, -18.38},{-14.63, 11.65, -16.75}
  },
  { -- Tidal Flats
    {-21.34, 11.72, 19.34},{2.52, 11.66, 19.98},{22.13, 11.63, 18.51},{-19.34, 11.69, 6.98},
    {15.70, 11.64, 8.01},{-23.02, 11.69, -5.36},{-10.57, 11.67, -3.93},{17.83, 11.63, -3.84},
    {8.24, 11.65, -3.88},{-18.30, 11.68, -15.53},{-1.93, 11.66, -17.06},{18.11, 11.63, -14.87},
  },
  { -- Blighted City
    {-23.11, 11.70, 18.18},{0.81, 11.66, 20.98},{19.56, 11.64, 18.87},{-9.00, 11.68, 11.32},
    {5.78, 11.65, 8.06},{-22.96, 11.69, 1.12},{21.75, 11.63, 2.40},{-8.98, 11.67, -4.54},
    {10.03, 11.64, -5.71},{-21.70, 11.69, -13.50},{-1.67, 11.66, -13.38},{17.46, 11.63, -13.58}
  },
  { -- Taiga
    {-21.70, 11.69, 17.27},{-2.23, 11.66, 18.57},{18.24, 11.64, 18.18},{-9.36, 11.67, 8.78},
    {3.81, 11.65, 8.27},{-22.96, 11.69, 1.12},{16.93, 11.64, 3.51},{-22.48, 11.68, -15.38},
    {-9.21, 11.70, -1.90},{-1.01, 11.65, -8.95},{9.39, 11.64, -4.74},{21.08, 11.62, -12.29}
  },
  { -- Gloom
    {-15.91, 11.69, 18.44},{4.84, 11.66, 16.70},{21.23, 11.64, 16.65},{-6.75, 11.67, 11.21},
    {-22.00, 11.69, 2.84},{4.71, 11.70, 6.33},{18.96, 11.63, 1.07},{-22.90, 11.69, -14.24},
    {-1.16, 11.66, -8.00},{-11.48, 11.67, -17.54},{6.78, 11.65, -15.27},{20.90, 11.63, -15.55}
  },
  {-- Klacar's Volcano Island
    {-20.45, 11.69, 8.88},{-17.57, 11.68, 2.80},{-17.24, 11.68, -11.49},{-6.39, 11.67, 14.41},
    {-3.90, 11.66, -8.26},{-5.50, 11.66, -14.54},{1.68, 11.66, 16.69},{5.76, 11.65, 9.27},
    {4.72, 11.65, -9.36},{14.12, 11.64, 16.61},{15.73, 11.64, 0.81},{15.13, 11.64, -4.83},
  },
  {-- SPACEBALLS
    {-22.08, 11.70, 18.66},{0.57, 11.67, 26.73},{2.01, 11.67, 26.73},{20.52, 11.64, 21.11},
    {-3.98, 11.67, 13.53},{-14.32, 11.68, -3.99},{-12.88, 11.68, -3.99},{8.83, 11.65, 0.49},
    {-20.23, 11.68, -19.77},{8.37, 11.64, -22.63},{9.81, 11.64, -22.63},{23.38, 11.62, -19.13},

  },
  {-- INFERNO
    {-21.53, 11.75, 17.55},{0.08, 11.72, 24.72},{28.54, 11.68, 15.71},{-8.92, 11.73, 14.25},
    {13.17, 11.70, 14.67},{-18.00, 11.74, 3.05},{15.83, 11.69, -4.62},{30.06, 11.67, -7.25},
    {-24.52, 11.75, -7.14},{-4.63, 11.72, -10.12},{-11.18, 11.72, -16.08},{16.84, 11.68, -17.12},
  },

  {-- BLIGHTED GROVE
    {-20.79, 11.70, 18.34},{-2.79, 11.67, 18.78},{16.42, 11.64, 19.04},{-6.23, 11.68, 8.90},
    {-18.54, 11.70, 3.19},{16.80, 11.65, 2.44},{5.42, 11.67, -4.42},{-23.34, 11.71, -13.30},
    {2.44, 11.67, -13.70},{19.31, 11.65, -11.67},{27.19, 11.56, -3.07},{28.62, 11.56, -3.07}
  },

  { -- Gorge original
    {-9.97,12.50,20.61},{6.14,12.48,20.06},{20.00,12.46,20.22},
    {-16.04,12.50,5.32},{3.15,12.48,9.63},{15.48,12.46,8.40},
    {-17.80,12.50,-6.19},{0.61,12.48,-5.29},{15.05,12.46,-2.76},
    {-16.36,12.50,-17.06},{0.87,12.47,-14.34},{14.51,12.45,-17.82},
  },

  { -- Marsh
    {-21.68, 11.70, 19.27},{-4.14, 11.67, 20.53},{22.51, 11.63, 16.34},{0.92, 11.56, 28.42},
    {0.92, 11.56, 27.77},{0.92, 11.56, 27.12},{1.65, 11.66, 8.93},{-2.28, 11.66, -0.85},
    {19.79, 11.63, -3.96},{16.11, 11.63, -15.82},{-8.60, 11.67, -10.39},{-19.47, 11.68, -14.36}

  },



}

local warmSunProphetLocations = {
  { -- Autumn
    {-7.66, 11.67, -0.69},{-1.32, 11.66, 7.66},{7.13, 11.65, -1.13},{20.97, 11.63, 2.07}
  },
  { -- Winter
    {-9.46, 11.67, 1.55},{3.24, 11.66, 3.41},{-8.81, 11.67, -17.65},{3.46, 11.65, -8.49}
  },
  { -- Lake
    {-7.24, 11.67, 8.82},{6.87, 11.65, 3.97},{21.83, 11.63, -5.47},{-10.31, 11.67, -9.84}
  },
  { -- Mountain
    {-11.20, 11.68, 9.51},{1.91, 11.66, 4.63},{-10.74, 11.67, -10.01},{4.56, 11.65, -3.49}
  },
  { -- Gorge
    {2.13, 11.66, 6.95},{14.56, 11.64, 2.90},{-15.52, 11.68, -2.66},{2.85, 11.65, -7.97}
  },
  { -- Treasure Island
    {-7.48, 11.67, 14.72},{-4.48, 11.66, -12.63},{15.12, 11.64, 14.35},{-12.10, 11.68, 7.97}
  },
  { -- Deep Woods
    {-10.91, 11.68, 10.01},{-10.14, 11.67, -4.37},{2.87, 11.66, 7.67},{4.80, 11.65, -4.54}
  },
  { -- Wastelands
    {-21.37, 11.70, -3.92},{-0.03, 11.71, 7.44},{-0.38, 11.70, -3.32},{6.55, 11.70, -12.90}
  },
  { -- Australia
    {-4.80, 11.67, 7.78},{-8.77, 11.67, -1.36},{4.38, 11.70, 9.33},{3.77, 11.65, -1.41}
  },
  { -- Narrows & Islets
    {-7.93, 11.67, 6.96},{2.15, 11.66, 9.73},{11.70, 11.64, 0.36},{-7.28, 11.66, -4.65}
  },
  { -- Tunnel Unraveled
    {-7.71, 11.67, 2.61},{-7.28, 11.67, -2.03},{5.61, 11.65, 2.70},{6.65, 11.65, -3.60}
  },
  { -- Tropics
    {-6.20, 11.67, 9.12},{-17.14, 11.68, -11.14},{12.35, 11.64, 5.60},{6.28, 11.65, -8.78}
  },
  { -- Summer
    {-7.66, 11.67, -0.69},{-1.32, 11.66, 7.66},{7.13, 11.65, -1.13},{20.97, 11.63, 2.07}
  },
  { -- Lost Woodland
    {-12.42, 11.72, 9.08},{-8.70, 11.72, -7.47},{7.04, 11.72, 10.50},{9.69, 11.72, -10.91}
  },
  { -- Legends
    {-12.42, 11.72, 9.08},{7.04, 11.72, 10.50},{-8.70, 11.72, -7.47},{9.69, 11.72, -10.91}
  },
  { -- Urban
    {-18.88, 11.69, -4.41},{-11.49, 11.68, 6.93},{7.08, 11.65, 1.17},
    {1.40, 11.66, -6.94},{-6.91, 11.68, 21.25},{22.70, 11.64, 17.35},{22.41, 11.62, -14.22}
  },
  {-- River town
    {-22.64, 11.68, -1.91},{-8.82, 11.67, 3.81},{7.25, 11.65, 4.28},{17.90, 11.63, 2.50}
  },
  {--Mountainside
    {-18.56, 11.65, -18.57},{3.04, 11.65, 10.38},{2.82, 11.65, -3.83},{22.46, 11.65, 3.10}
  },
  {--Tidal Flats
    {0.88, 11.66, 19.78},{-9.83, 11.67, -8.09},{4.32, 11.65, -4.09},{2.10, 11.65, -14.74}
  },
  {--Blighted City
    {9.99, 11.64, -10.21},{-12.73, 11.68, -6.07},{-10.84, 11.71, 11.43},{5.89, 11.70, 9.51}
  },
  { --Taiga
    {-11.03, 11.67, 8.52},{7.65, 11.65, 8.92},{5.97, 11.65, -5.41},{0.00, 11.65, -11.91}
  },
  {--Gloom
    {5.81, 11.65, 2.70},{-4.56, 11.66, -5.69},{-11.72, 11.71, -14.61},{8.63, 11.64, -15.60}
  },
  {--Klacar's Volcano Island
    {-18.02, 11.68, -1.87},{3.45, 11.66, 10.07},{14.90, 11.64, 2.47},{-5.39, 11.67, -7.17}
  },
  {--SPACEBALLS
    {0.14, 11.66, 10.94},{13.12, 11.64, 2.89},{-8.08, 11.67, -0.33},{-0.06, 11.66, -12.06}
  },
  {--INFERNO
    {5.59, 11.71, 25.25},{15.88, 11.70, 13.73},{20.05, 11.68, -5.54},{-18.51, 11.74, -1.54}
  },
  {--Blighted Grove
    {-0.54, 11.67, 13.27},{-10.40, 11.68, 9.27},{6.68, 11.66, -0.60},{-4.08, 11.68, -13.37}
  },
  -- Gorge Original
  {{-17.11, 11.68, -2.66},{-1.66, 11.66, 6.51},{3.76, 11.65, -5.98},{15.88, 11.64, 4.95}},
  -- Marsh
  {{0.94, 11.56, 25.19},{0.94, 11.56, 24.51},{5.40, 11.66, 9.08},{-2.05, 11.66, -2.36}},



}


function dist(o,x,z)

  return math.sqrt(math.pow(o.getPosition().x - x,2) + (math.pow(o.getPosition().z - z,2)))
end











function contains(tbl, item)
  for key, value in pairs(tbl) do
      if value == item then return key end
  end
  return false
end



-- CLEAR ALL RESETS STATE, NOT JUST OBJECTS. This is base-mod code: it destroys almost everything on
-- the table and touched none of RTT's bookkeeping, which is the root of three separate bugs found by
-- the 2026-09-06 audit:
--   * RTT_FAC_TAKEN survived, so every faction picked before a Clear All became PERMANENTLY
--     unpickable -- "Marquise de Cat is already in play." on a completely empty table, forever;
--   * RTT_PRIO_MAP survived while its markers were destroyed, so re-clicking the same map spawned
--     no clearing-priority markers (rttClearPriority now clears that flag itself, which covers every
--     other path that destroys them too);
--   * the seat record and the published Globals survived, so the gizmo and the box score kept
--     answering for a game that no longer exists.
-- rttResetRunState is the ONE list of everything a new game resets that is not an object, so Clear
-- All calls exactly that rather than growing its own copy -- the drift that list exists to prevent.
function clearAll()
  for _, c in ipairs(getObjects()) do
      if c.name != "HandTrigger"
        and c.hasTag("Table Piece") == false
        and c.hasTag("Landmark Object") == false
        and c.getName() != "Flex Table Control"
        and c.getName() != "Faction Selection"
        and c.getName() != "Master Instructions"
        then c.destruct()
        end
  end
  pcall(function() rttResetRunState() end)
  pcall(function() rttClearPriority() end)   -- the markers are gone; drop the flag and the handles
end

redTaken = false
_G['vagabondAlreadySpawned'] = false

_G['DraftableFactions'] = {"Marquise de Cat","Eyrie Dynasties","Woodland Alliance","Vagabond1",
                            "Vagabond2","The Lizard Cult","Riverfolk Company",
                            "Underground Duchy","Corvid Conspiracy",
                            "Lord of the Hundreds","Keepers in Iron",
                            "Twilight Council","Lilypad Diaspora","Knaves of the Deepwood"
                          }




--###############################################
--###############################################
--###############################################
--###############################################




tournamentMapSelected = false







local banFactionNames = {"BanCats","BanBirds","BanGreen","BanVagabond1","BanVagabond2","BanLizards","BanOtters","BanMoles","BanCrows","BanRats","BanBadgers","BanBats","BanFrogs","BanKnaves"}

local banFactionColors = {"#d77435","#4776b6","#6bb659","#ffffff","#ffffff",
"#e8e138","#5cbab4","#e4c0a2","#542c75","#f3461b",
"#acadb1","#964E30","#B09804","#808080"}









function getPosition(color,playerCount)
  if playerCount == 1 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00) end
  elseif playerCount == 2 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00)
    elseif color == "Yellow" then return Vector(-52.00, 11.56, -46.00) end
  elseif playerCount == 3 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00)
    elseif color == "Yellow" then return Vector(0.00, 11.56, -46.00)
    elseif color == "Orange" then return Vector(-52.00, 11.56, -46.00) end
  elseif playerCount == 4 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00)
    elseif color == "Yellow" then return Vector(-52.00, 11.56, -46.00)
    elseif color == "Orange" then return Vector(-52.00, 11.56, 46.00)
    elseif color == "Teal" then return Vector(52.00, 11.56, 46.00) end
  elseif playerCount == 5 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00)
    elseif color == "Yellow" then return Vector(0.00, 11.56, -46.00)
    elseif color == "Orange" then return Vector(-52.00, 11.56, -46.00)
    elseif color == "Teal" then return Vector(-52.00, 11.56, 46.00)
    elseif color == "Green" then return Vector(52.00, 11.56, 46.00) end
  elseif playerCount == 6 then
    if color == "Red" then return Vector(52.00, 11.56, -46.00)
    elseif color == "Yellow" then return Vector(0.00, 11.56, -46.00)
    elseif color == "Orange" then return Vector(-52.00, 11.56, -46.00)
    elseif color == "Teal" then return Vector(-52.00, 11.56, 46.00)
    elseif color == "Green" then return Vector(0.00, 11.56, 46.00)
    elseif color == "Brown" then return Vector(52.00, 11.56, 46.00) end
  end

end

function flipSide(color,playerCount)

  if color == "Red" or color == "Yellow" then return false end
  if color == "Teal" or color == "Green" or color =="Brown" then return true end
  if color == "Orange" then
    if playerCount == 3 then return false end
    if playerCount == 4 then return true end
  end
end



function makeVagabondLayout(i,faction,color)
  spawnDraftFaction(i,faction,color)
  spawnDraftFaction(i,"Vagabond Dice and VP",color)
end





-- ---- WHERE THINGS GO: A CONSTANT, NEVER A QUESTION ------------------------------------------
-- Every move_to in content.lua was recorded against a board of scale 15.5, and the ten spawn paths
-- below turn one into a world position with "move_to / this board's scale * 15.5". That asked the
-- board how big it was, every single time -- and the board is a Custom_Tile with WidthScale 0, which
-- means TTS works its shape out FROM ITS PICTURE. On a cold load the picture has not arrived yet, so
-- the mod was asking a board how big it is while the thing that decides how big it is was still
-- downloading. The maintainer can watch it happen: objects come up one size and then resize
-- ("we see the full sized one then the resized one and it looks clunky", 2026-09-07).
--
-- Anything placed inside that window lands scaled about the world origin -- which is what "the map
-- and items loaded all over the place" looks like, and why a second load of the mod always fixes it:
-- the picture is cached by then and the size is settled before anyone can click a button.
--
-- The question was pointless anyway. All three objects that run this code -- bab7e1 and both spawned
-- selectors -- are authored at 15.5, they are locked, and nothing in the mod resizes them, so
-- 15.5/scale is 1 by construction. Now it is 1 by definition, and placement no longer waits on a
-- download. If a board ever genuinely needs a different scale, change this constant, not the callers.
RTT_BOARD_SCALE = 15.5

function rttPlaceScale()
  return Vector({ 1 / RTT_BOARD_SCALE, 1, 1 / RTT_BOARD_SCALE })
end

function spawnDraftFaction(i,faction,color)

  local pos = getPosition(color,#_G["FullRoster"])

  -- makes vagabond basics board

  if isVagabond(faction) then
    makeVagabondLayout(i,"Vagabond Layout",color)
  end

  local objects = {}

  objects = EVERYTHING['Standard'][faction]['data']
  local scale = rttPlaceScale()
  function callback(o)

    if flipSide(color,#_G['FullRoster']) then
      o.setRotation({o.getRotation().x, o.getRotation().y + 180, o.getRotation().z})
    else
      o.setRotation({o.getRotation().x, o.getRotation().y, o.getRotation().z})
    end

    if tableHasElement(_G['BotRoster'], "draftVagaBot") then
      if o.hasTag("Quest") and o.name != "Custom_Tile" then
        o.destroy()
      end
    elseif _G['vagabondAlreadySpawned'] then
      if o.hasTag("Quest") then o.destroy() end
    else
      if o.hasTag("Ruin Set") then o.destroy() end
    end



      if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
  end
  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      if flipSide(color,#_G['FullRoster']) then
        vec = vec * Vector(-15.5 , 1, -15.5)
      else
          vec = vec * Vector(15.5, 1, 15.5)
      end
      local new_pos = pos + vec
      new_pos.y = new_pos.y - 0.1
      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          callback_function = callback
      })
  end
end












function allButtonsOff()
  self.UI.setAttribute("creditsPanel","active","False")
  self.UI.setAttribute("standardButtons","active","False")
  self.UI.setAttribute("toolsButtons","active","False")
  self.UI.setAttribute("mapButtonsStandard","active","False")
  self.UI.setAttribute("tools1","active","False")
  self.UI.setAttribute("decksButtonsStandard","active","False")
  self.UI.setAttribute("setupButtons", "active", "False")
end


-- ---- Credits ---------------------------------------------------------------------------------
-- The board used to carry a baked credit in its top-right corner. It is gone from the wood, and the
-- attributions live here instead: one rendered parchment page that takes the place of the buttons,
-- with a Back button to return. Rendered as an IMAGE rather than UI text on purpose -- TTS draws UI
-- text into a fixed-resolution texture, so small type is unavoidably blurry (the same reason the old
-- corner credit was an image).
function rttShowCredits(player, value, id)
  allButtonsOff()
  self.UI.setAttribute("creditsPanel", "active", "True")
end

function rttHideCredits(player, value, id)
  self.UI.setAttribute("creditsPanel", "active", "False")
  setup()                                     -- back to the normal menu
end

local RTT_FACTION_GRID = {
  {"Marquise de Cat", "-90 45 -20"},
  {"Eyrie Dynasties", "-30 45 -20"},
  {"Woodland Alliance", "30 45 -20"},
  {"Knaves of the Deepwood", "90 45 -20"},
  {"The Lizard Cult", "-90 -5 -20"},
  {"Riverfolk Company", "-30 -5 -20"},
  {"Underground Duchy", "30 -5 -20"},
  {"Corvid Conspiracy", "90 -5 -20"},
  {"Lord of the Hundreds", "-90 -55 -20"},
  {"Keepers in Iron", "-30 -55 -20"},
  {"Twilight Council", "30 -55 -20"},
  {"Lilypad Diaspora", "90 -55 -20"}
}

-- THE ART ON THESE TWO BOARDS IS DOWNLOADED WITH THE TABLE, NOT WHEN THE BOARD APPEARS.
-- Neither selector exists in the save: both are built here and spawned mid-game. TTS resolves an
-- object's XmlUI icon references ONCE, at the instant the object is instantiated, and never
-- re-composites as downloads finish -- the cold-load finding of 2026-08-29 (WORK_QUEUE_ARCHIVE).
-- So an icon that is not already on the player's disk when the board is spawned is an icon that
-- never appears: the board renders its wood (CustomImage is a separate pipeline) and not one
-- button, and only a SECOND load of the mod fixes it.
--
-- The twelve faction icons used to be the setup board's own files, so the table fetched them at load
-- and these boards found them warm. Re-rendering every setup label in Luminari (74cefe8) moved the
-- setup board onto new art and left these blueprints on the old Steam URLs, which nothing else in the
-- mod asks for -- and the blank faction board came back for anyone loading the mod for the first
-- time. Maintainer, 2026-09-07: "faction board showed no buttons ... it was resolved by reloading the
-- mod ... still there for people loading the mod the first time".
--
-- The fix is in the BLUEPRINT: gen/src/save.json lists all 35 of these URLs on the table surface
-- (4ee1f2, locked, permanent, no UI of its own), so TTS downloads them while the table loads and the
-- spawned board finds every one of them on disk. Add an icon to either board below and you must add
-- it there too -- t_every_selector_icon_is_downloaded_with_the_table fails if you forget.
MANUAL_FACTION_SELECTOR_JSON = [===[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.56,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":15.5,"scaleY":1.0,"scaleZ":15.5},"Nickname":"Faction Board","Description":"","GMNotes":"","Locked":false,"Grid":false,"Snap":true,"IgnoreFoW":false,"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/board/board_clean_v4.png","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1725416402718254700/C6F00394AFEE245DFFA53CD358F5F966AA754BC9/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"MANUAL_FACTION_COORD_GUID = \"bab7e1\"\nfunction manualFactionRelay(player, value, id)\n  local coordinator = getObjectFromGUID(MANUAL_FACTION_COORD_GUID)\n  if coordinator ~= nil then\n    coordinator.call(\"manualFactionPick\", { color = player.color, id = id, board = self.getGUID() })\n  end\nend\nfunction deleteThis()\n  -- clear the UI before going: deleting an object that still has XML UI attached can\n  -- leave TTS unable to hand out player colours until the server restarts\n  pcall(function() self.UI.setXml(\"\") end)\n  Wait.frames(function() self.destruct() end, 1)\nend\nfunction vagabondPage()\n  self.UI.setAttribute(\"factionPage\",\"active\",\"False\")\n  self.UI.setAttribute(\"vagabondPage\",\"active\",\"True\")\nend\nfunction vagabondBack()\n  self.UI.setAttribute(\"vagabondPage\",\"active\",\"False\")\n  self.UI.setAttribute(\"factionPage\",\"active\",\"True\")\nend\n","XmlUI":"<Button id=\"xButton\" onclick=\"deleteThis\" icon=\"CloseX\" position=\"112 82 -20\" width=\"18\" height=\"18\" color=\"#bd2608\"/><ToggleGroup id=\"factionPage\" active=\"True\"><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Marquise de Cat\" position=\"-90 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Marquise de Cat\" color=\"#d77435\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Eyrie Dynasties\" position=\"-30 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Eyrie Dynasties\" color=\"#4776b6\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Woodland Alliance\" position=\"30 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Woodland Alliance\" color=\"#6bb659\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"The Lizard Cult\" position=\"-90 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"The Lizard Cult\" color=\"#e8e138\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Riverfolk Company\" position=\"-30 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Riverfolk Company\" color=\"#5cbab4\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Underground Duchy\" position=\"30 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Underground Duchy\" color=\"#e4c0a2\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Corvid Conspiracy\" position=\"90 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Corvid Conspiracy\" color=\"#542c75\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Lord of the Hundreds\" position=\"-90 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Lord of the Hundreds\" color=\"#f3461b\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Keepers in Iron\" position=\"-30 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Keepers in Iron\" color=\"#acadb1\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Twilight Council\" position=\"30 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Twilight Council\" color=\"#964E30\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Lilypad Diaspora\" position=\"90 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Lilypad Diaspora\" color=\"#B09804\"/><Button onclick=\"vagabondPage\" id=\"VagabondAndKnaves\" position=\"90 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"VagabondAndKnaves\" color=\"#ffffff\"/></ToggleGroup><ToggleGroup id=\"vagabondPage\" active=\"False\"><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Adventurer\" position=\"-100 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Adventurer\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Arbiter\" position=\"-50 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Arbiter\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Cheat\" position=\"0 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Cheat\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Gladiator\" position=\"50 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Gladiator\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Harrier\" position=\"-100 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Harrier\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Jailor\" position=\"-50 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Jailor\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Ranger\" position=\"0 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Ranger\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Ronin\" position=\"50 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Ronin\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Scoundrel\" position=\"-100 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Scoundrel\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Thief\" position=\"-50 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Thief\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Tinker\" position=\"0 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Tinker\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Vagrant\" position=\"50 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Vagrant\" color=\"gray\"/><Button onclick=\"vagabondBack\" id=\"vbBack\" position=\"100 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"VagabondAndKnaves\" color=\"#ffffff\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Knaves of the Deepwood\" position=\"100 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Knaves of the Deepwood\" color=\"gray\"/></ToggleGroup>","CustomUIAssets":[{"Type":0,"Name":"Marquise de Cat","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739429295/F6CF523AAA7DCC91AF3812339EBB3354F6D9891A/"},{"Type":0,"Name":"Eyrie Dynasties","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755958213/960DFA43E52D99A3250863FC63F3BA3AE5104325/"},{"Type":0,"Name":"Woodland Alliance","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755956632/E99D3C9B246A94F6A898EC0D8098A05FA9467473/"},{"Type":0,"Name":"Knaves of the Deepwood","URL":"https://steamusercontent-a.akamaihd.net/ugc/14468202139363768412/1012F7145C45B86F395C099B9AE80EA536529DD3/"},{"Type":0,"Name":"The Lizard Cult","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755960838/D88CBE9192488A678AF3EC6DFC45B4C728C9A169/"},{"Type":0,"Name":"Riverfolk Company","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755963912/C9589D96259534C6FB15DD91F78E7E90A073FDD8/"},{"Type":0,"Name":"Underground Duchy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755961872/1E2748C8EDD0BDE039B81658AFD0B19C771569BD/"},{"Type":0,"Name":"Corvid Conspiracy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755959858/69B8EC707AD26EF2F558ACAB65B39163B812D3F6/"},{"Type":0,"Name":"Lord of the Hundreds","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818578726/CE952087E18A1C0B6B94E44EF53EB009A97A7122/"},{"Type":0,"Name":"Keepers in Iron","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818579404/C0D7197A109DBF0C2EFB34DF50AE2CA70A66C25B/"},{"Type":0,"Name":"Twilight Council","URL":"https://steamusercontent-a.akamaihd.net/ugc/2452866064845174396/6228F6A71DDC36CD883777CA958857CB123D7ECB/"},{"Type":0,"Name":"Lilypad Diaspora","URL":"https://steamusercontent-a.akamaihd.net/ugc/2508034524425991747/77C277526C0042FE2754C83836A1E2C3C03FAD38/"},{"Type":0,"Name":"CloseX","URL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/close_x.png"},{"Type":0,"Name":"Adventurer","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756318712/DAB9CB5B2AA9CF5AF4BDD67CFED687B8595411CF/"},{"Type":0,"Name":"Arbiter","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756223555/8BB76979D215E9C042976005212DD7D0F9EBCDBD/"},{"Type":0,"Name":"Cheat","URL":"https://steamusercontent-a.akamaihd.net/ugc/14685838847886183596/2F910C564507478E736E783C2B01011BF710E3D0/"},{"Type":0,"Name":"Gladiator","URL":"https://steamusercontent-a.akamaihd.net/ugc/16433884667023926/65F0E372EB9EEF805369BB5F766846F066BD62AF/"},{"Type":0,"Name":"Harrier","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756321980/D728E9E7523EF9917554681B8CCFA7A79D6E95DC/"},{"Type":0,"Name":"Jailor","URL":"https://steamusercontent-a.akamaihd.net/ugc/10906121492486022753/B8147FE9BB8652380D0027EB4AF0C7FF8C7C66AE/"},{"Type":0,"Name":"Ranger","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756323292/B5CDBACDB5E58637478F86047D574579AECBC763/"},{"Type":0,"Name":"Ronin","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739435936/8C15D8C6D58FAF51A22B66697740CBA5BAEBBEFB/"},{"Type":0,"Name":"Scoundrel","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756324621/71561324D23947260120C7F2EDF0A692986619EB/"},{"Type":0,"Name":"Thief","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756326469/AA4F3B6BF91AC337A240B582DF46C07DF9A374E5/"},{"Type":0,"Name":"Tinker","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756328063/25E9D54EAFE7A483877DECF1013DE57C96B0F214/"},{"Type":0,"Name":"Vagrant","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756329310/FEBDC9CB90C879DFC4ECAE1BBDDA857DBF9CD95C/"},{"Type":0,"Name":"VagabondAndKnaves","URL":"https://steamusercontent-a.akamaihd.net/ugc/11747765109863371101/6EB77E31F0244DFD039474C19C18D49AD0C93DBD/"}]}]===]

local function spawnManualFactionSelector(position, rotation, locked)
  return spawnObjectJSON({
    json = MANUAL_FACTION_SELECTOR_JSON,
    position = position,
    rotation = rotation,
    callback_function = function(board)
      board.setName("Faction Board")
      board.addTag("RTT Manual Selector")   -- tear these down by TAG, never by the shared name (audit)
      board.setLock(locked)
    end
  })
end

function setupFactionBoards(player, value, id)
  -- This path is SYNCHRONOUS -- it destructs and spawns in one pass, with no animation and no Wait
  -- chain -- so the busy flag only has to cover the few frames the spawns take. It is cleared at the
  -- bottom of this function; the 3s here is just a safety net if a spawn throws. (It used to sit on the
  -- 10s fallback alone, which held the buttons dead for ten seconds after an instant action.)
  rttBusyBegin(3)
  local count = 4
  if id == "fivePlayerSetup" then count = 5 end
  -- THE BUTTON IS THE TRUTH ABOUT THE BOARD. 4-Player Setup is a four-player game, so it leaves the
  -- 5-player Marsh variant behind. rttSetup (the ranked path) has always cleared this; setupFactionBoards
  -- never did -- harmless while a new game left the map alone, and a live bug the moment rttNewGame
  -- started refreshing it, because the refresh goes through the INTERNAL path ("" for player) and so
  -- deliberately does not clear the flag itself. Pressing 4-Player Setup after a 5-player Marsh
  -- therefore rebuilt the FIVE-player board: flood tiles parked under the table, towns re-spawned.
  -- 5P Setup is left alone: it is a five-player game, so keeping the five-player Marsh is right.
  if id ~= "fivePlayerSetup" then RTT_5P_MARSH = false end

  -- clear PRIOR manual selectors AND every faction board/piece already spawned (RTT Faction) -- re-clicking
  -- the player-count button starts over, so tear the old boards down first (maintainer request). Still NOT
  -- by name "Faction Board" (which also matched the solo faction board and coordinator clones) (audit).
  -- ONE new-game path, shared with rttSetup: teardown, run-state reset, and the turn system for
  -- `count` seats. This path used to do all three itself, and drifted from the ranked path four
  -- separate times (teardown tags, run-state reset, busy release, turn order).
  rttNewGame(count)

  local xs = {52,-52,52,-52,0,52}
  local ys = {11.56,11.56,11.56,11.56,11.56,11.56}
  local zs = {-46,-46,46,46,-46,46}

  for i = 1, count do
    spawnManualFactionSelector(
      {xs[i],ys[i],zs[i]},
      {0, (zs[i] > 0) and 180 or 0, 0},
      true
    )
  end
  Wait.frames(function() RTT_BUSY = false end, 5)   -- boards are up: buttons live again immediately
end


function setup()
  allButtonsOff()
  self.UI.setAttribute("setupButtons", "active", "True")
  self.UI.setAttribute("mapButtonsStandard", "active", "True")
  self.UI.setAttribute("decksButtonsStandard", "active", "True")
  self.UI.setAttribute("toolsButtons", "active", "True")
  self.UI.setAttribute("tools1", "active", "True")
end

























function makeFactionSelector()
  spawnManualFactionSelector({54.81,11.56,0}, {0,90,0}, false)
end








_G['TurnOrder'] = {}



local vagabondChosen = false










function deleteThis()
  Global.call('ImGone', {self})
  self.destruct()
end

function setInfo(name)
    --[[ hover credit removed ]]
end

function clearInfo()
  self.UI.setAttribute("info","image","Blank Info")
end

function isDoomedVagabond(name)
  if (name == "Doomed Berserker" or name == "Doomed Barkeep" or name == "Doomed Blacksmith" or name == "Doomed Swindler" or
  name == "Doomed Bard" or name == "Doomed Zealot") then
    return true
  else
    return false
  end
end

function isVagabond(id)
  if (id == "Adventurer" or id == "Arbiter" or id == "Harrier" or id == "Ranger" or id == "Ronin" or id == "Scoundrel" or id == "Thief" or id == "Tinker" or id == "Vagrant" or id == "Gladiator" 
      or id == "Cheat" or id == "Jailor") then
    return true
  else
    return false
  end

end


RTT_MIL_CARDS = {[309]=[==[{"GUID":"39be49","Name":"Card","Transform":{"posX":-1.66627669,"posY":1.05879366,"posZ":-4.028566,"rotX":-0.0006826586,"rotY":179.990768,"rotZ":-0.00112713769,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":309,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[307]=[==[{"GUID":"e8f093","Name":"Card","Transform":{"posX":-1.05922115,"posY":0.9735951,"posZ":-3.99652,"rotX":4.55595364e-05,"rotY":179.990768,"rotZ":-0.000284563663,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":307,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[310]=[==[{"GUID":"ed28df","Name":"Card","Transform":{"posX":-1.00858307,"posY":1.15495336,"posZ":-3.80439377,"rotX":1.40676332,"rotY":179.996048,"rotZ":5.81672975e-05,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":310,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[301]=[==[{"GUID":"8df1be","Name":"Card","Transform":{"posX":-0.282207727,"posY":1.04952276,"posZ":-3.6216743,"rotX":0.00066678843,"rotY":179.990768,"rotZ":-0.0006546988,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":301,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[73200]=[==[{"GUID":"35b81a","Name":"CardCustom","Transform":{"posX":57.3735352,"posY":11.6722345,"posZ":22.0381832,"rotX":0.0005990316,"rotY":269.986877,"rotZ":-0.0033355006,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":73200,"SidewaysCard":false,"CustomDeck":{"732":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/10042992881391430383/BAE426B4F4BD70FF7A6084DFA55961800C0F83DF/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[300]=[==[{"GUID":"c8f4ed","Name":"Card","Transform":{"posX":-1.57336509,"posY":1.015244,"posZ":-3.802666,"rotX":0.000971112,"rotY":179.990768,"rotZ":-0.00130566931,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":300,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]}
RTT_INS_CARDS = {[305]=[==[{"GUID":"bdce9c","Name":"Card","Transform":{"posX":-34.3895874,"posY":11.6095686,"posZ":27.29517,"rotX":359.7493,"rotY":180.002716,"rotZ":359.870728,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":305,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[302]=[==[{"GUID":"c7b1d4","Name":"Card","Transform":{"posX":5.14010143,"posY":2.063494,"posZ":-4.39241171,"rotX":359.8631,"rotY":179.974548,"rotZ":-0.002107894,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":302,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[73000]=[==[{"GUID":"9be262","Name":"CardCustom","Transform":{"posX":65.30026,"posY":11.7010155,"posZ":22.1271057,"rotX":0.000114221068,"rotY":269.986877,"rotZ":-0.0006956121,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":73000,"SidewaysCard":false,"CustomDeck":{"730":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/17156148149837033890/98EA362B4304B9B9E5825AAE0D213A17FC4BBB7C/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[304]=[==[{"GUID":"201005","Name":"Card","Transform":{"posX":-34.0781059,"posY":11.6981983,"posZ":27.2413673,"rotX":0.0345823355,"rotY":180.00032,"rotZ":0.0251624361,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":304,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[308]=[==[{"GUID":"06ace2","Name":"Card","Transform":{"posX":49.28753,"posY":11.5751371,"posZ":22.6206779,"rotX":5.08970043e-05,"rotY":269.9901,"rotZ":-0.000322228385,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":308,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],[73300]=[==[{"GUID":"e88b64","Name":"CardCustom","Transform":{"posX":49.4498253,"posY":11.6168051,"posZ":23.0559349,"rotX":0.00105606078,"rotY":269.9901,"rotZ":-0.00123060483,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":73300,"SidewaysCard":false,"CustomDeck":{"733":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/10654530041309384819/5D0D59497688830C050F1BA44431CAB1104B7F3F/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]}
RTT_ORDER_JSON_4 = [==[{"GUID":"88257f","Name":"Deck","Transform":{"posX":64.33211,"posY":11.60173,"posZ":-25.0888042,"rotX":-1.91315461e-08,"rotY":270.0,"rotZ":-7.529847e-07,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":false,"SidewaysCard":true,"DeckIDs":[805,802,801,800],"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","ContainedObjects":[{"GUID":"8491fb","Name":"Card","Transform":{"posX":64.0154,"posY":11.5751534,"posZ":-32.2374573,"rotX":3.13927535e-06,"rotY":270.0,"rotZ":9.9273886e-05,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":805,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"bacbbf","Name":"Card","Transform":{"posX":64.60444,"posY":11.6144962,"posZ":-31.4052162,"rotX":-0.002876776,"rotY":270.0,"rotZ":359.994,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":802,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"7557a4","Name":"Card","Transform":{"posX":65.741,"posY":11.6480627,"posZ":-32.8092346,"rotX":359.991364,"rotY":270.0,"rotZ":0.002321583,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":801,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"17843f","Name":"Card","Transform":{"posX":64.41976,"posY":11.65809,"posZ":-32.54536,"rotX":0.001989416,"rotY":270.0,"rotZ":-0.00265754061,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":800,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]}],"Tags":["RTT Order Card"]}]==]
RTT_ORDER_JSON_5 = [==[{"GUID":"fdb993","Name":"Deck","Transform":{"posX":55.35494,"posY":11.6065445,"posZ":-24.9285755,"rotX":-6.83371937e-09,"rotY":270.0,"rotZ":-3.07726573e-08,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":false,"SidewaysCard":true,"DeckIDs":[806,805,802,801,800],"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","ContainedObjects":[{"GUID":"811ad9","Name":"Card","Transform":{"posX":55.44372,"posY":11.5751438,"posZ":-24.79723,"rotX":2.30794358e-05,"rotY":270.0,"rotZ":-0.0001306939,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":806,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"8491fb","Name":"Card","Transform":{"posX":64.0154,"posY":11.5751534,"posZ":-32.2374573,"rotX":3.13927535e-06,"rotY":270.0,"rotZ":9.9273886e-05,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":805,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"bacbbf","Name":"Card","Transform":{"posX":64.60444,"posY":11.6144962,"posZ":-31.4052162,"rotX":-0.002876776,"rotY":270.0,"rotZ":359.994,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":802,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"7557a4","Name":"Card","Transform":{"posX":65.741,"posY":11.6480627,"posZ":-32.8092346,"rotX":359.991364,"rotY":270.0,"rotZ":0.002321583,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":801,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]},{"GUID":"17843f","Name":"Card","Transform":{"posX":64.41976,"posY":11.65809,"posZ":-32.54536,"rotX":0.001989416,"rotY":270.0,"rotZ":-0.00265754061,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":800,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","Tags":["RTT Order Card"]}],"Tags":["RTT Order Card"]}]==]
RTT_MILITANT = {309,307,310,301,73200,300}
RTT_INSURGENT = {305,302,73000,304,308,73300}
-- five landing slots, centred on z=0; slot 5 (z=14) is the LEFT end.
RTT_SLOTS = {{63.9,11.6,-14},{63.9,11.6,-7},{63.9,11.6,0},{63.9,11.6,7},{63.9,11.6,14}}
-- the draft deck sits past the LEFT-most slot (z=14) with a ~10-unit gap: left of
-- the cards, but not stranded far out.
RTT_DECK = {63.9,11.6,24}
RTT_SPAWNED = {}
-- CardID -> faction name (matches EVERYTHING['Standard'][name]); used by the faction draft
RTT_CARD_FACTION = {
  [300]="Marquise de Cat", [301]="Eyrie Dynasties", [307]="Underground Duchy",
  [309]="Lord of the Hundreds", [310]="Keepers in Iron", [73200]="Lilypad Diaspora",
  [302]="Woodland Alliance", [304]="Riverfolk Company", [305]="The Lizard Cult",
  [308]="Corvid Conspiracy", [73000]="Twilight Council", [73300]="Knaves of the Deepwood",
}

function rttShuffle(t)
  for i=#t,2,-1 do local j=math.random(i) t[i],t[j]=t[j],t[i] end
  return t
end


--------------------------------------------------------------- wipe confirm --
-- The setup buttons are destructive. Maintainer's spec: the BUTTON ITSELF turns red and asks; a second
-- click goes ahead; 3 seconds of silence reverts it. Two refinements he added after seeing it:
--   * only ask when something would ACTUALLY be wiped -- on a clean table the button just works;
--   * the red state must be the SAME button, same size, same position -- so it is mutated in place
--     (colour/text/icon swapped via setAttribute) rather than swapped for a separate wide plaque.
-- Only attributes with precedent on this board are touched (color/text/icon/fontSize); textColor has
-- none, and an unsupported attribute makes TTS silently drop the element.
-- `warn` is the ARMED art. Do NOT blank the icon instead: TTS renders icon="" as a WHITE placeholder
-- drawn OVER the button, which hid the red state entirely (maintainer: "the red button appears below a
-- white version of the button art so not visible"). Swapping to real art keeps it one button, same
-- size, same position -- the art itself turns red and asks.
-- The asset NAMES are historical; the art they point at now carries the maintainer's captions:
--   RankedArt     -> "4-Player Draft"     FourBoardsArt -> "4-Player Setup"
--   FivePlayerArt -> "5-Player Draft"     FivePlayerSetupArt -> "5-Player Setup"
RTT_WIPE_BTN = {
  rttRankedBtn     = { fn = "rttSetup",              color = "#030411", icon = "RankedArt",          warn = "WipeConfirmArt", warnMap = "WipeConfirmMapArt" },
  rttThemeBtn      = { fn = "rttTheme",              color = "#49514b", icon = "ThemeArt",           warn = "WipeConfirmArt", warnMap = "WipeConfirmMapArt" },
  rttFourBoardsBtn = { fn = "setupFactionBoards",    color = "#3a2f22", icon = "FourBoardsArt",      warn = "WipeConfirmArt", warnMap = "WipeConfirmMapArt" },
  Marsh5P          = { fn = "rttFivePStart",         color = "#463221", icon = "FivePlayerArt",      warn = "WipeConfirmArtWide", warnMap = "WipeConfirmMapArtWide" },
  Marsh5PSetup     = { fn = "setupFivePlayerBoards", color = "#463221", icon = "FivePlayerSetupArt", warn = "WipeConfirmArtWide", warnMap = "WipeConfirmMapArtWide" },
  -- 5-Players Marsh places the Marsh map and nothing else, so it can only ever cost you the map.
  -- BUTTONS.md used to say it "is not destructive, so it does not prompt"; it goes through
  -- rttPlaceMap -> makeMap -> removeMapItems like any other map placement, so that was simply wrong.
  Marsh5PMap       = { fn = "rttPlaceMarsh5P",       color = "#81745b", icon = "Marsh5PLabel",       warn = "WipeConfirmMapArtWide" },
  -- THE MAP BUTTONS. Maintainer, 2026-09-06: they should warn like the faction buttons do. They are
  -- destructive -- makeMap clears everything tagged "Map Object" (the map, the battle mat, the
  -- priority markers, the timer, the counter, the box score) and on the Marsh re-rolls the flood and
  -- the suits -- and until now they did it on a single click with no prompt.
  -- `map` instead of `fn`: rttArmOrGo's other entries name a no-argument function, but makeMap needs
  -- the map id, so the dispatch branches on this field.
  ["Summer Map"]   = { map = "Summer Map",   color = "#4b4d35", icon = "Autumn Map",   warn = "WipeConfirmMapArt" },
  ["Lake Map"]     = { map = "Lake Map",     color = "#42a0c2", icon = "Lake Map",     warn = "WipeConfirmMapArt" },
  ["Marsh Map"]    = { map = "Marsh Map",    color = "#9b8551", icon = "Marsh Map",    warn = "WipeConfirmMapArt" },
  ["Winter Map"]   = { map = "Winter Map",   color = "#6b8a8f", icon = "Winter Map",   warn = "WipeConfirmMapArt" },
  ["Mountain Map"] = { map = "Mountain Map", color = "#764a52", icon = "Mountain Map", warn = "WipeConfirmMapArt" },
  ["Gorge Map"]    = { map = "Gorge Map",    color = "#61746b", icon = "Gorge Map",    warn = "WipeConfirmMapArt" },
}
RTT_ARM = { id = nil, token = 0 }

-- BUSY GUARD. The setup chain is ~6-10 seconds of Wait.time/Wait.frames (rttSpawnDeck -> rttSlideOut ->
-- rttFlipAll -> rttDealOrder -> rttBeginPick -> rttSeatPlayers/rttStartFactionDraft -> rttShowFactions).
-- Clicking again during it used to start a SECOND chain whose predecessor's callbacks then fired against
-- objects the new run had destroyed. Maintainer: "while there is the animation or it's loading clicking
-- again should not do anything" -- so clicks are DROPPED, never queued. Cleared when the selector boards
-- light up (rttShowFactions), with a timed fallback so a chain that dies cannot lock the buttons forever.
RTT_BUSY = false
RTT_BUSY_TOKEN = 0

-- GENERATION TOKEN. A setup is ~6-10s of chained Wait.time/Wait.frames. The busy guard stops a SECOND
-- run from STARTING, but a chain already in flight keeps firing -- against objects the new run has since
-- destroyed, and against the new run's state. Every new game bumps RTT_RUN_ID (in rttClearGameObjects,
-- which both setup paths call); each chain step is scheduled through these, which capture the id at
-- schedule time and simply do not run if the game has moved on. Same argument order as Wait.time /
-- Wait.frames deliberately, so a call site converts by swapping the name and nothing else.
RTT_RUN_ID = 0
RTT_MAP_GEN = 0    -- bumped by every map build; deferred map hooks check it before firing
RTT_HOME = {}      -- [guid] = {n=name, f=faction, p={x,y,z}, r={x,y,z}} where a piece spawned
function rttAfter(fn, sec)
  local id = RTT_RUN_ID
  Wait.time(function() if RTT_RUN_ID == id then fn() end end, sec)
end
function rttAfterFrames(fn, n)
  local id = RTT_RUN_ID
  Wait.frames(function() if RTT_RUN_ID == id then fn() end end, n)
end

-- Everything a game puts on the table, in one place. Both setup paths call this, so a new tag can
-- never again be swept by one path and leaked by the other. Two leaks this fixes: the Pond tagged
-- itself "RTT Pond" and nothing cleared it, and the Lizard Wizard was tagged plain "Faction" -- one
-- word off "RTT Faction" -- so the sweep walked straight past it. Deliberately NOT cleared here:
-- "Map Object" and "RTT Priority" belong to the MAP (makeMap owns those), and "Deck Object" to the deck.
-- Dice that ARE faction components and must survive the faction spawn's dice filter.
RTT_KEEP_DICE = { ["dc8eb3"] = true, ["81f2b2"] = true }   -- bats: one of two; rats: the Mob Die

-- TTS bug, community-reported: deleting an object that still has XML UI attached can leave the
-- server unable to hand out player colours -- arrivals get only Grey, and a colour you have LEFT
-- cannot be taken again, while the hand zones all still look fine. That is exactly the maintainer's
-- report (2026-09-05): "I was in that color, then I changed color to another seat, and then I'm not
-- able to go back to the previous seat."
--
-- This mod deletes XmlUI objects constantly -- every manual selector board when you pick from it,
-- every ranked selector, the box score on each respawn -- so it would trigger this often. Clearing
-- the UI first and destroying a frame later gives TTS a chance to release it. It is a mitigation for
-- an engine bug, not a proven cure: nothing here can verify TTS's internal state.
function rttDestroyUI(o)
  if o == nil then return end
  pcall(function() o.UI.setXml("") end)
  Wait.frames(function() pcall(function() o.destruct() end) end, 1)
end

-- "RTT Order Card" is baked into the turn-order deck AND into each of its cards. The deck alone was
-- tracked, by GUID, in RTT_SPAWNED -- but rttDealOrderCards TAKES the cards OUT of it into players'
-- hands, and a card taken from a deck is its own object with its own guid, on no list and (until
-- now) carrying no tag at all. So a new game destroyed the deck and left everybody holding last
-- game's seat number. Zaandaa: "old seat number cards remain if you start a new draft."
-- Tagging the CARDS rather than tracking them is what makes this hold: a card keeps its own tags
-- when it leaves the deck, so the sweep finds it in a hand, on the table, or as the leftover
-- nobody was dealt -- and any future path that deals one is covered without knowing about it.
RTT_TEARDOWN_TAGS = { "RTT Selector", "RTT Manual Selector", "RTT Faction", "RTT Pond",
                      "RTT Order Card" }

-- Hand 2 (the Alliance supporters hand) is a PERSISTENT per-colour zone, not an object, so tearing down
-- objects never reset it. Across several games in one session it stayed wherever the last Alliance put
-- it, and after re-seating into a different colour the maintainer ended up with supporters hands
-- scattered over old seats -- his report: "the bug happens when I reset several games in the same
-- session and I was seated in another seat". Snapshot the parked transforms once at load and put them
-- back on every new game.
RTT_ALL_COLORS = { "Red","Yellow","Orange","Teal","Green","Brown","Blue","Purple","Pink","White" }
RTT_HAND2_PARKED = nil

function rttSnapshotHand2()
  if RTT_HAND2_PARKED ~= nil then return end
  RTT_HAND2_PARKED = {}
  for _, c in ipairs(RTT_ALL_COLORS) do
    pcall(function()
      local h = Player[c].getHandTransform(2)
      if h ~= nil and h.position ~= nil then
        RTT_HAND2_PARKED[c] = { position = h.position, rotation = h.rotation, scale = h.scale }
      end
    end)
  end
end

function rttResetHands2()
  if RTT_HAND2_PARKED == nil then return end
  for c, t in pairs(RTT_HAND2_PARKED) do
    pcall(function() Player[c].setHandTransform(t, 2) end)
  end
end
-- ONE turn-system setup, used by BOTH setup paths. It lived inside rttSeatPlayers, which only the
-- RANKED draft calls -- so on the manual 4-board path the turn system was never configured at all and
-- the maintainer saw TTS's own ten-colour default order. Same class of bug as the teardown list and the
-- run-state reset: two setup paths that must agree and did not share code.
-- Players actually sitting at the table. Grey and Black are the spectator/GM seats in this mod and
-- never count as a player.
function rttSeatedCount()
  local n = 0
  pcall(function()
    for _, p in ipairs(Player.getPlayers()) do
      if p.seated and p.color ~= "Grey" and p.color ~= "Black" then n = n + 1 end
    end
  end)
  return n
end

function rttEnableTurns(nseats, keepTurn)
  nseats = math.max(1, nseats or 4)
  -- The order is the SEATS' OWN COLOURS, clockwise from the bottom-right corner -- read off the
  -- table rather than tabulated. It used to be RTT_SETUP_COLORS[1..nseats], which forced both the
  -- colours AND the going-round order to a fixed list, and was the reason a wrong seat/spot index
  -- could put a player in someone else's turn slot. rttSeatOrderIdx is geometric, so it is right for
  -- any seat count and for boards a player placed by hand.
  -- Falls back to the fixed list only when there is no seat record at all (a map/deck button pressed
  -- before any game is set up), which preserves the old pre-game behaviour the tests pin.
  local torder = {}
  for _, i in ipairs(rttSeatOrderIdx()) do
    local c = RTT_SEATS[i] and RTT_SEATS[i].color
    if c ~= nil and c ~= "" then torder[#torder + 1] = c end
  end
  if #torder == 0 then
    for i = 1, nseats do torder[#torder + 1] = RTT_SETUP_COLORS[i] end
  end
  if #torder == 0 then return end
  RTT_TURN_SEATS = nseats               -- remembered so a later seat change can re-apply the order

  -- Do nothing at all when nothing would change. TTS plays its turn notification whenever the turn
  -- system is switched on, so re-asserting an identical state on every seat change made it chime
  -- again for no reason (maintainer: "the sound trigger is annoying"). There is no documented way to
  -- silence that notification, so the fix is to stop causing it.
  -- Turns LATCH ON. Once a game is running, somebody standing up for a moment must not switch the
  -- turn system off and hand the turn back to seat 1 -- and switching it on again would re-fire the
  -- notification. So seating can only ever start it, never stop it.
  local on = false
  pcall(function() on = (Turns.enable == true) end)
  local want = on or (rttSeatedCount() > 0)

  -- The shortcut is ONLY for the re-apply path (keepTurn given, i.e. somebody changed seat). A
  -- setup call must always write, or starting a new game while turns were already running would
  -- leave the turn wherever the last game left it instead of back at seat 1.
  if keepTurn ~= nil then
    local same = false
    pcall(function()
      if Turns.enable == want and Turns.type == 2 and Turns.order ~= nil and #Turns.order == #torder then
        same = true
        for i = 1, #torder do if Turns.order[i] ~= torder[i] then same = false end end
      end
    end)
    if same then return end
  end

  pcall(function()
    Turns.type = 2                       -- the custom order below
    Turns.order = torder
    Turns.reverse_order = false
    Turns.skip_empty_hands = false       -- step through every seat, occupied or not
    Turns.pass_turns = true
    -- Only actually START the turn system once somebody is sitting down. Setting up four boards is
    -- not the start of a game -- the maintainer, 2026-09-05: "the turn order should get started only
    -- when a player is seated, now it also starts when I select 4 player setup". The order is still
    -- written here, so the moment a seat is taken onPlayerChangeColor turns it on with the right
    -- order already in place.
    Turns.enable = want
    -- keepTurn is the colour whose turn it already was. Re-applying the order mid-game must NOT
    -- hand the turn back to seat 1, so it is restored when it is still one of the seats.
    -- (This was a second `local want`, shadowing the boolean above -- correct only by accident of
    -- ordering, and exactly the kind of thing that breaks on the next edit.)
    local startAt = torder[1]
    if keepTurn ~= nil and keepTurn ~= "" then
      for _, c in ipairs(torder) do if c == keepTurn then startAt = keepTurn end end
    end
    Turns.turn_color = startAt
  end)
end

-- Maintainer 2026-09-05: "set up automatically when players get seated and readjust each time a
-- player gets seated, but do not force all the time so one could change it manually if need be."
-- Before this, rttEnableTurns ran ONCE per setup and nothing ever touched Turns again, so the
-- second half was already true and the first half was missing. This is the only place that
-- re-applies, so a manual reorder still survives everything except somebody taking a seat.
-- A colour change does NOT move anybody's seat. In TTS the hand, its cards and the slot in
-- Turns.order all belong to the COLOUR, so a player changing colour has picked up a different seat,
-- not relabelled themselves -- and the mod deliberately does not chase them. Their old seat keeps its
-- faction, its cards and its turn slot, waiting for them to take that colour back. That is exactly
-- what makes a disconnect/reconnect work with no special handling.
-- All this does is re-assert the order (a colour freed or taken can change what TTS will step
-- through) and re-publish, so the box score sees the same truth the board holds.
function onPlayerChangeColor(player_color)
  if RTT_TURN_SEATS == nil then return end          -- no game set up yet: nothing to re-apply
  local keep = nil
  pcall(function() keep = Turns.turn_color end)
  pcall(function() rttEnableTurns(RTT_TURN_SEATS, keep) end)
  pcall(function() rttPublishSeats() end)
end

function rttClearGameObjects()
  RTT_RUN_ID = RTT_RUN_ID + 1                      -- invalidates every in-flight setup callback
  for _, t in ipairs(RTT_TEARDOWN_TAGS) do
    for _, o in ipairs(getObjectsWithTag(t)) do rttDestroyUI(o) end
  end
  -- The draft deck and the turn-order cards are tracked by GUID rather than by tag, so the tag sweep
  -- above cannot see them. Only the ranked path used to clear them, which meant starting a manual game
  -- on top of a ranked draft left the faction cards and order cards lying on the table.
  for _, g in ipairs(RTT_SPAWNED) do
    local o = getObjectFromGUID(g)
    if o then pcall(function() o.destruct() end) end
  end
  RTT_SPAWNED = {}
  rttResetHands2()                                 -- hand zones are state too, not objects
end

-- ONE list of everything a new game resets that is NOT an object. Objects are torn down by tag (above);
-- this is the counterpart for state, which teardown cannot see. Both setup paths used to carry their
-- own copy of this block, and every value added to one and forgotten in the other became a bug: the VP
-- index, the taken-factions set, the cached score track, the seat map. RTT_CAP_SPAWNED was in NEITHER
-- copy -- it was cleared only when a Knaves board spawned -- so a captain seen in one game still counted
-- as "already spawned" in the next.
function rttResetRunState()
  RTT_VP_PLACED      = 0
  RTT_FAC_TAKEN      = {}
  RTT_TRACK          = nil
  RTT_MANUAL_PICKING = {}
  RTT_VP_PENDING     = {}
  RTT_ALLY_SUP_DONE  = {}
  RTT_CAP_SPAWNED    = {}
  RTT_CAP_SLOT       = {}
  RTT_CAP_SPAWN_N    = 0
  RTT_CAP_ITEM_N     = 0
  RTT_CAP_WARRIOR_N  = 0
  RTT_HOME           = {}      -- where every faction piece spawned; a new game re-records it
  RTT_PRIO_MAP       = nil     -- "which map's priority markers are out"; a new game holds none
  RTT_PRIO_PIECES    = {}
  -- What the LAST draft offered. rttCaptainsAreDrafted reads this, and rttSpawnFaction filters the
  -- Knaves' own 12-card captain deck out of the spawn when it says yes -- because the ranked draft
  -- deals captains itself. It was never cleared, so after ANY draft that merely OFFERED the Knaves,
  -- picking them manually gave a Captains board with three empty slots and no deck anywhere: the
  -- blueprint copy filtered out, and rttDraftKnavesCaptains only ever runs from the ranked chain.
  -- The faction was unplayable. Clearing it here restores the documented manual behaviour -- "when I
  -- don't do the ranked or theme button that drafts the captain cards, the deck of all captains still
  -- spawns on the faction board".
  RTT_DRAFT_FACTIONS = {}
  -- The seat record itself, not just its publication. The ranked path happened to clear RTT_SEATS in
  -- rttSpawnSelectors, but the manual path never did, so seats piled up across games in one session.
  RTT_SEATS      = {}
  RTT_PICK_N     = 0           -- pick ordering belongs to this game only
  -- The draft's shuffle was NEVER cleared: it only ever got overwritten by the next rttDealOrder, so
  -- a manual game started after a draft still carried the previous draft's person-to-seat mapping,
  -- and anything reading it got last game's answer.
  RTT_ORDER      = {}
  RTT_TURN_SEATS = nil         -- the seat COUNT outlived the seats and rebuilt orders out of nothing
  for _, k in ipairs({ "RTT_SEAT_POS", "RTT_SEAT_COLOR", "RTT_SEAT_PLAYER", "RTT_SEAT_RECORD" }) do
    pcall(function() Global.setVar(k, JSON.encode({})) end)
  end
end

-- ONE new-game entry point, called by BOTH setup paths instead of each keeping its own copy of the
-- teardown + reset sequence. `seats` is how many seats to configure the turn system for, or nil to
-- leave the turn system alone -- the ranked draft sets it later, from the real seating.
-- Re-place the map a new game is starting on, KEEPING the board itself.
--
-- Maintainer, 2026-09-06: "reset the clearing makers the landmarks everything that goes on the board
-- because anyway they are reshuffled, reset the board itself and the clearing numbers only if it is
-- another map." Choosing a different map is a map-button click, which is a full rebuild already, so
-- the only case this covers is the SAME map -- hence the board always stays.
--
-- It matters most on the Marsh, which is the only map that is not the same board twice: every build
-- re-rolls which three clearings flood, which suits stand where and where the ruins go, AND it has two
-- different layouts behind one button (4-player flooded, 5-player with town landmarks). Without this,
-- starting a 4-player game after a 5-player Marsh game left the FIVE-player board on the table --
-- towns still standing, no flooding -- because the map id had not changed so nothing rebuilt.
-- Maintainer, twice: "spawning marsh 4 players after marsh 5 players still does not span the flooded
-- clearings properly and keep the landmarks."
function rttRefreshMap()
  local id = RTT_CURRENT_MAP
  if id == nil or id == "" then return end        -- no map down yet: nothing to refresh
  if EVERYTHING["Maps"] == nil or EVERYTHING["Maps"][id] == nil then return end
  makeMap("", "", id, true)                       -- "" = internal path, so it never clears RTT_5P_MARSH
end

function rttNewGame(seats)
  -- A NEW GAME gets a NEW SHEET. The fixtures survive a map change (see RTT_FIXTURE_TAG), and the box
  -- score is one of them -- but its whole point is to hold THIS game, so starting one drops it and the
  -- map refresh below spawns a fresh one.
  pcall(function() for _, o in ipairs(getObjectsWithTag(RTT_BOXSCORE_TAG)) do rttDestroyUI(o) end end)
  rttClearGameObjects()                            -- objects, hand zones, run-id bump
  rttResetRunState()                               -- everything teardown cannot see
  -- ONE FRAME LATER, because the 5-player Marsh flag is set by rttFivePStart immediately AFTER
  -- rttSetup returns -- and rttSetup is what called us. Refreshing here and now would read the flag
  -- as false and build the four-player Marsh for a five-player game.
  Wait.frames(function() pcall(function() rttRefreshMap() end) end, 1)
  -- HOW MANY SEATS THIS GAME HAS. RTT_DN was written in exactly one place -- rttSetup, the ranked
  -- path -- so a manual game inherited whatever the last draft left: 5P Draft then 4-Player Setup
  -- gave a box score pre-formatted for FIVE rows in a four-player game, and 5P Setup from a cold
  -- table gave four rows for five players. It means "cards this draft dealt" = seats + 1, which is
  -- what rttSpawnBoxScore reads back as RTT_BOXSCORE_MIN. The ranked path still overwrites it moments
  -- later with its own draft size; this only fills the gap the manual path left.
  if seats ~= nil then RTT_DN = seats + 1 end
  rttRemoveFrogsFromDeck()                         -- the deck survives teardown; its frog cards must not
  if seats ~= nil then rttEnableTurns(seats) end
end
function rttBusyBegin(sec)
  RTT_BUSY = true
  RTT_BUSY_TOKEN = RTT_BUSY_TOKEN + 1
  local t = RTT_BUSY_TOKEN
  Wait.time(function() if RTT_BUSY_TOKEN == t then RTT_BUSY = false end end, sec or 15)
end

-- would this click actually destroy anything? A SETUP click tears down the tags rttSetup owns; a MAP
-- click tears down "Map Object" instead, so the first map of a session still places instantly with no
-- prompt -- the same rule the setup buttons already follow.
-- What a rebuild would actually DESTROY. Not simply "a Map Object": the battle mat, the box score and
-- the turn panel all carry that tag and all SURVIVE, because removeMapItems keeps anything tagged as
-- a fixture. Counting them made every setup button demand confirmation on a table holding nothing but
-- its own furniture -- maintainer, 2026-09-07: "a warning of wipe all factions appeared while there
-- was no faction to wipe." This is the same test removeMapItems applies, so the warning appears
-- exactly when something is going to be taken away.
function rttLoseableMapItems()
  local n = 0
  for _, o in ipairs(getObjectsWithTag("Map Object")) do
    local fixture = false
    pcall(function() fixture = o.hasTag(RTT_FIXTURE_TAG) end)
    if not fixture then n = n + 1 end
  end
  return n
end

function rttWouldWipe(isMap)
  if isMap then return rttLoseableMapItems() > 0 end
  if rttFactionsOnTable() then return true end
  -- A SETUP CLICK NOW TAKES THE MAP TOO. rttNewGame re-places it (rttRefreshMap), so starting a game
  -- on a table that has a map is destructive even with no faction on it -- and it used to go through
  -- with no prompt at all. Maintainer, 2026-09-06: "the options buttons should also have the warnings
  -- when they reset factions or maps."
  return rttLoseableMapItems() > 0
end

-- Is there anything of a GAME on the table, as opposed to just a map?
function rttFactionsOnTable()
  for _, t in ipairs({ "RTT Faction", "RTT Selector", "RTT Manual Selector" }) do
    if #getObjectsWithTag(t) > 0 then return true end
  end
  return false
end

-- WHICH WARNING TO SHOW: the one that belongs to the BUTTON, always. This used to switch wording by
-- what happened to be on the table -- a setup button said "reset the map" when no faction was down
-- yet -- and in practice that read as the faction warning having been deleted. Maintainer,
-- 2026-09-07: "you changed all warnings on the buttons to This will reset the map. and erased the
-- previous warning This will reset all factions. Put back the appropriate warning to the appropriate
-- buttons! since some buttons reset the map others the factions."
--
-- So: the setup buttons say factions, because clearing the factions is what they are for; the map row
-- and 5-Players Marsh say map. A button's warning no longer depends on the state of the table.
function rttWarnArt(d)
  -- ...BUT NEVER A WARNING FOR SOMETHING IT WILL NOT DO. The setup buttons clear the factions AND
  -- re-place the map, so which of the two is at stake depends on the table: with factions out they
  -- cost you the factions, and with none they cost you only the map. Saying "reset all factions" to a
  -- table that has none is what the maintainer hit twice -- 2026-09-07: "still have a warning about
  -- wiping factions while the only thing I spawned is a map", and then "This will reset the map BUT
  -- ONLY IF IT INDEED DOES!!! some buttons do not".
  --
  -- Only the buttons that really do both carry warnMap. A map button has one effect and one wording,
  -- and can never claim to touch a faction. This is not the old adaptive rule that swapped every
  -- button's wording by table state: the faction warning still appears in every case where a faction
  -- would actually be lost.
  if d.warnMap ~= nil and not rttFactionsOnTable() then return d.warnMap end
  return d.warn
end

function rttDisarm()
  local id = RTT_ARM.id
  RTT_ARM.id = nil
  RTT_ARM.token = RTT_ARM.token + 1              -- invalidates any pending revert timer
  local d = id and RTT_WIPE_BTN[id]
  if d == nil then return end
  pcall(function()
    self.UI.setAttribute(id, "icon", d.icon)
    self.UI.setAttribute(id, "color", d.color)
  end)
end

-- one handler for every destructive button: go / arm / commit.
-- `player` is carried through so an armed COMMIT still reaches makeMap as a HUMAN click. makeMap
-- swallows clicks while busy and clears RTT_5P_MARSH only for a player carrying a colour; committing
-- with nil would quietly keep 5-player mode alive through a map change, which is the bug fixed
-- earlier the same day.
-- The one place a wipe-button's action is named. It used to be written out TWICE inside rttArmOrGo,
-- once for the armed commit and once for the nothing-to-lose shortcut, so every new button had to be
-- added in both -- exactly the drift the rest of this file keeps warning about.
function rttRunBtn(d, player)
  if     d.map ~= nil                    then makeMap(player, "", d.map)
  elseif d.fn == "rttSetup"              then rttSetup()
  elseif d.fn == "rttTheme"              then rttTheme()
  elseif d.fn == "rttFivePStart"         then rttFivePStart()
  elseif d.fn == "rttPlaceMarsh5P"       then rttPlaceMarsh5P()
  elseif d.fn == "setupFactionBoards"    then setupFactionBoards()
  elseif d.fn == "setupFivePlayerBoards" then setupFivePlayerBoards()
  end
end

function rttArmOrGo(id, player)
  local d = RTT_WIPE_BTN[id]
  if d == nil then return end
  if RTT_BUSY then return end                    -- a setup is still running: swallow the click
  if RTT_ARM.id == id then                       -- SECOND click on the armed button: commit
    rttDisarm()
    rttRunBtn(d, player)
    return
  end
  if not rttWouldWipe(d.map ~= nil) then         -- clean table: nothing to lose, just run
    rttRunBtn(d, player)
    return
  end
  rttDisarm()                                    -- a different button was armed: revert it first
  RTT_ARM.id = id
  RTT_ARM.token = RTT_ARM.token + 1
  local tok = RTT_ARM.token
  pcall(function()
    self.UI.setAttribute(id, "icon", rttWarnArt(d))  -- the art itself becomes the red question
    self.UI.setAttribute(id, "color", "#a83226") -- matches the plaque so the rounded corners blend
  end)
  Wait.time(function() if RTT_ARM.token == tok then rttDisarm() end end, 3.0)
end

-- the map buttons all come through here; the button's own id IS the map id
function rttArmMap(player, value, id) rttArmOrGo(id, player) end

function rttArmRanked(player, value, id)  rttArmOrGo("rttRankedBtn", player) end
function rttArmTheme(player, value, id)   rttArmOrGo("rttThemeBtn", player) end
function rttArmFour(player, value, id)    rttArmOrGo("rttFourBoardsBtn", player) end
function rttArmMarsh5P(player, value, id) rttArmOrGo("Marsh5P", player) end
function rttArmFiveSetup(player, value, id) rttArmOrGo("Marsh5PSetup", player) end
function rttArmMarsh5PMap(player, value, id) rttArmOrGo("Marsh5PMap", player) end

-- Five manual selector boards and nothing else -- the 5-player counterpart of the 4-Player Setup
-- button. setupFactionBoards keys the seat count off the BUTTON id, so it is passed explicitly here
-- rather than relying on which button was clicked.
function setupFivePlayerBoards()
  setupFactionBoards(nil, nil, "fivePlayerSetup")
end

-- Ginso's Gizmo is part of every game now (maintainer: "spawn the gizmo at beginning of game always"),
-- so setup spawns it instead of relying on someone clicking its toggle. Guarded on the tool's own GUID
-- so a second game does not stack a second copy.


function rttSetup(player, value, id)
  rttBusyBegin(15)
  RTT_5P_MARSH = false
  -- clear BOTH selector kinds (ranked AND manual) plus any faction boards, so starting a ranked draft on
  -- top of a manual-4-player setup (or vice versa) never stacks the two -- the manual selectors are tagged
  -- "RTT Manual Selector", NOT "RTT Selector", so they were surviving the ranked reset (maintainer clutter).
  -- ONE new-game path, shared with setupFactionBoards. No seat count here: the ranked draft configures
  -- the turn system later, in rttSeatPlayers, once it knows who actually sat down.
  rttNewGame(nil)
  -- NO os.time re-seed: the RNG is seeded once at load and advances per call, so each draft is
  -- independent (see rtt-rng-bug). Re-seeding to os.time() made same-second launches identical.
  local mil = {}
  for _,c in ipairs(RTT_MILITANT) do mil[#mil+1]=c end
  rttShuffle(mil)
  local first = mil[1]
  local pool = {}
  if not RTT_THEME then for i=2,#mil do pool[#pool+1]=mil[i] end end RTT_THEME = nil
  for _,c in ipairs(RTT_INSURGENT) do pool[#pool+1]=c end
  rttShuffle(pool)
  -- the 5 dealt (Militant first); the rest stay as the deck so EVERY faction card is
  -- on the table. The full random order is fixed here, up front.
  RTT_DN = RTT_DRAFT_N or 5 RTT_DRAFT_N = nil local draft = {first} for _di = 1, RTT_DN - 1 do draft[#draft + 1] = pool[_di] end
  -- the 5 drafted faction NAMES, for the reverse-order faction draft (phase 3)
  RTT_DRAFT_FACTIONS = {}
  for _,cid in ipairs(draft) do RTT_DRAFT_FACTIONS[#RTT_DRAFT_FACTIONS+1] = RTT_CARD_FACTION[cid] end
  -- ONLY the 5 drafted cards are put on the table (no leftover faction deck). The
  -- draft empties these as factions are placed in the faction phase.
  RTT_NLEFT = 0
  local jsons = {}
  for _,cid in ipairs(draft) do jsons[#jsons+1] = RTT_MIL_CARDS[cid] or RTT_INS_CARDS[cid] end
  rttSpawnDeck(jsons, 1, {})
end

-- 1) a real face-down DECK resting ON the table at RTT_DECK: cards spawn in a tight
--    stack at table height (y offsets are tiny) and are locked so it sits like a deck.
function rttSpawnDeck(jsons, i, cards)
  if i > #jsons then
    rttAfter(function() rttSlideOut(cards, 1) end, 0.9)   -- let the deck sit, then deal
    return
  end
  spawnObjectJSON({
    json = jsons[i],
    position = {RTT_DECK[1], RTT_DECK[2] + 0.05 * i, RTT_DECK[3]},
    rotation = {0, 270, 180},
    callback_function = function(o)
      o.setLock(true)
      RTT_SPAWNED[#RTT_SPAWNED+1] = o.getGUID()
      cards[i] = o
      rttAfter(function() rttSpawnDeck(jsons, i+1, cards) end, 0.1)
    end
  })
end

-- 2) deal from the deck: each card flies up in a small ARC (raised mid-point) to its
--    slot. Card 1 (always the Militant) lands LEFT-most, each later card one right.
function rttSlideOut(cards, k)
  if k > (#cards - RTT_NLEFT) then                     -- deal ALL the drafted cards
    rttAfter(function() rttFlipAll(cards, 1) end, 0.6)
    return
  end
  local c = cards[RTT_NLEFT + k]                        -- the k-th draft card (top of the deck)
  if c ~= nil then
    c.setLock(false)
    local _nd = #cards - RTT_NLEFT local _sp = (_nd > 1) and (28.0 / (_nd - 1)) or 0 local s = {63.9, 11.6, -14 + (_nd - k) * _sp}
    local mid = {s[1], s[2] + 4, (RTT_DECK[3] + s[3]) / 2}   -- lift over -> arc
    c.setPositionSmooth(mid, false, false)
    rttAfter(function()
      if c ~= nil then c.setPositionSmooth({s[1], s[2], s[3]}, false, true) end
    end, 0.35)
  end
  rttAfter(function() rttSlideOut(cards, k+1) end, 0.6)
end

-- 3) flip face-up with the REAL flip mechanism (a natural flip, not a rotate that
--    clips through the table), one card at a time so they all flip the same way.
function rttFlipAll(cards, k)
  if k > (#cards - RTT_NLEFT) then                     -- flip ALL the dealt cards
    for i = 1, RTT_NLEFT do                            -- unlock the leftover deck so it's movable
      if cards[i] ~= nil then cards[i].setLock(false) end
    end
    -- Captains FIRST, then the turn order (maintainer: "draft the captains before the turn order
    -- cards not after"). rttDraftKnavesCaptains needs ~0.5s to deal its four once it starts, so the
    -- order deck is held back far enough that the captains are down before it appears.
    rttAfter(rttDraftKnavesCaptains, 1.0)             -- captains spawn AFTER every draft card has flipped
    rttAfter(rttDealOrder, 2.2)
    return
  end
  local c = cards[RTT_NLEFT + k]
  if c ~= nil then c.flip() end
  rttAfter(function() rttFlipAll(cards, k+1) end, 0.12)
end

function rttDealOrder()
  spawnObjectJSON({
    json = ((RTT_DN and RTT_DN >= 6) and RTT_ORDER_JSON_5 or RTT_ORDER_JSON_4),  -- 5-card deck only for 5p
    position = {63.9, 13, -25},          -- on the table (turn order isn't secret); the leftover deck rests here
    rotation = {0, 270, 0},
    callback_function = function(ord)
      ord.setLock(false)                 -- unlock so it isn't left floating
      RTT_SPAWNED[#RTT_SPAWNED+1] = ord.getGUID()
      rttAfter(function()
        if ord ~= nil and ord.shuffle then ord.shuffle() end
        rttAfter(function()
          local seated = {}
          for _,p in ipairs(Player.getPlayers()) do
            if p.seated and p.color ~= "Grey" and p.color ~= "Black" then seated[#seated+1]=p end
          end
          -- joined players keep THEIR chosen colours; give each a RANDOM SEAT among the N fixed seats
          -- (draft size = RTT_DN-1, independent of how many humans joined). This must randomise the SEAT
          -- itself, not just the order among the joined players -- otherwise a SOLO player (only 1 seated,
          -- nothing to permute) always lands in seat 1. So shuffle the seat SLOTS and drop players in.
          local plist = {}
          for _,p in ipairs(seated) do plist[#plist+1] = {color=p.color, name=p.steam_name} end
          local _N = (RTT_DN or 5) - 1
          RTT_ORDER = {}
          for i=1,_N do RTT_ORDER[i] = {color=nil, name=''} end
          local slots = {}
          for i=1,_N do slots[i] = i end
          for i=#slots,2,-1 do local j=math.random(i) slots[i],slots[j]=slots[j],slots[i] end
          for k=1,#plist do if slots[k] ~= nil then RTT_ORDER[slots[k]] = plist[k] end end
          RTT_ORDER_DECK = (ord ~= nil) and ord.getGUID() or nil   -- rttSeatAndDeal deals from it
          rttAfter(function() rttBeginPick() end, 1.0)
        end, 0.6)
      end, 0.5)
    end
  })
end

function manualFactionPick(params)
  if params == nil then return end
  local board = getObjectFromGUID(params.board or "")
  if board == nil then return end
  makeFaction({ color = params.color }, "", params.id, board)
end

function makeFaction(player,value,id,source)
  if player.color == "Grey" then return end
  local board = source or self
  -- Double-click guard: this board is destroyed on pick, but two fast clicks can both enter before it
  -- goes -> the faction spawns twice. Lock the board GUID once (audit: selector double-spawn).
  RTT_MANUAL_PICKING = RTT_MANUAL_PICKING or {}
  local _bg = board.getGUID()
  if RTT_MANUAL_PICKING[_bg] then return end
  RTT_MANUAL_PICKING[_bg] = true
  -- ...and block a SECOND COPY OF THE SAME FACTION. The guard above is per-BOARD, so it stops one board
  -- double-firing but not the same faction being picked from two different boards. That spawned the
  -- faction twice and threw "Value cannot be null. Parameter name: key" (maintainer's screenshot), since
  -- everything keyed by faction name -- VP marker, seat map, extras -- assumes one copy. The draft path
  -- has always had this guard (rttCoordFaction); the manual path did not.
  RTT_FAC_TAKEN = RTT_FAC_TAKEN or {}
  if RTT_FAC_TAKEN[id] then
    RTT_MANUAL_PICKING[_bg] = nil                  -- let this board be used for a different faction
    pcall(function()
      broadcastToColor(id .. " is already in play.", player.color, { r = 1, g = 0.75, b = 0.3 })
    end)
    return
  end
  RTT_FAC_TAKEN[id] = true
  local attrs = board.UI.getAttributes(id)
  local category = attrs.category
  local cp = board.getPosition()
  local br = board.getRotation()
  local flip = cp.z > 0
  local expectedRy = flip and 180 or 0
  local deltaRy = ((br.y - expectedRy + 180) % 360) - 180
  local spawnRy = (math.abs(deltaRy) > 0.01) and br.y or nil

  rttDestroyUI(board)

  -- Seat the player's MAIN HAND FIRST. spawnSupportersHand (inside rttPlaceFaction) derives the
  -- supporters hand from hand 1's CURRENT position, so with the old order it was computed from the
  -- player's PREVIOUS seat -- the maintainer: "picking the Woodland Alliance in another seat draws
  -- three cards... to the old previous supporter area". The ranked path was never affected because
  -- rttSeatPlayers moves hand 1 at draft start, long before any faction is picked.
  -- setupFaction used to configure the manual player's main hand as a side effect.
  -- Keep that manual-only behavior without giving the ranked path a new visual change.
  local direction = Vector(0, 4, -18)
  direction:rotateOver("y", br.y)
  local seatHand = {
    position = Vector(cp.x, 10.62, cp.z) + direction,
    rotation = { 0, br.y, 0 },
    scale = { 16, 6, 4 }
  }
  Player[player.color].setHandTransform(seatHand, 1)

  -- Hand the seat DOWN rather than letting rttPlaceFaction read it back: same values, but now the
  -- result no longer depends on whether hand 1 has finished moving.
  rttPlaceFaction(id, cp.x, cp.z, flip, player.color, false, category, spawnRy, player.color, seatHand)
  -- A Vagabond is a CHARACTER, not a whole faction: the character data is just the pawn, its items and
  -- its VP marker. The shared board, dice and quest kit come from two more blueprint entries, which the
  -- draft paths already pull in via makeVagabondLayout. The manual selector needs the same, placed at
  -- this seat with the faction's own geometry rather than the base mod's roster positions.
  if isVagabond(id) then
    pcall(function() rttSpawnFaction("Vagabond Layout", cp.x, cp.z, flip, "Standard", spawnRy) end)
    -- ONE VP marker, not eleven: white for the first vagabond, black for the second -- the pair the
    -- printed game ships for exactly this. The second is named "Vagabond 2 VP" so the box score gives
    -- it its own row; keyed off the seat rttPlaceFaction just wrote, so the two cannot disagree.
    pcall(function()
      local si = rttSeatAt(cp.x, cp.z, false, id)
      local seat = si and RTT_SEATS[si] or nil
      local n = (seat and seat.vagN) or 1
      local tint = RTT_VAGABOND_VP_ORDER[n] or "White"
      rttSpawnFaction("Vagabond Dice and VP", cp.x, cp.z, flip, "Standard", spawnRy,
                      { vpKeep = RTT_VAGABOND_VP[tint],
                        vpName = rttVPName(rttVagabondKey(n)) })
    end)
  end
  Global.call("spawned", { character })

  if id == "The Winged Menace" then
    spawnWingedMenaceExtraHand(player.color)
  end
  -- Corvid plots + Lizard are owned by the shared rttFactionExtras (rttCrowsPlots / rttLizardSetup) for
  -- BOTH manual and ranked -- do NOT also run shufflePlots here (it double-ran plot setup on manual).
  if id == "Warriors Wake" then
    summonSaltyOldStan()
  end

  if (id == "Host of Light") then

    for i, object in pairs(getObjects()) do
      if object.hasTag("Pillar of Faith Cards") then
        local GUID = object.getGUID()
        local deck = getObjectFromGUID(GUID)
        deck.randomize()

        shuffleAssets("Firebrand Fox")
        shuffleAssets("Firebrand Rabbit")
        shuffleAssets("Firebrand Mouse")


        deck.removeTag("Pillar of Faith Cards")
        Wait.time(
            function()

              shuffleAssets("Firebrand Fox")
              shuffleAssets("Firebrand Rabbit")
              shuffleAssets("Firebrand Mouse")

              removeTagFromAssets("Firebrand Fox")
              removeTagFromAssets("Firebrand Rabbit")
              removeTagFromAssets("Firebrand Mouse")

              local distance = 24.4794138
              local deckPos = deck.getPosition()
              -- wonky math that makes radians, goes the right way with clockwise/counterclockwise, and adjusts for angle offset
              local angle = -1 *  (deck.getRotation()[2] * math.pi/180) - math.pi * 2 * 0.0565

              local xPos = deckPos[1] - distance * math.cos(angle)
              local yPos = deckPos[2] + 1
              local zPos = deckPos[3] - distance * math.sin(angle)

              deck.takeObject({position = {xPos, yPos, zPos}})

            end,
            3
        )

        shuffleAssets("Firebrand Fox")
        shuffleAssets("Firebrand Rabbit")
        shuffleAssets("Firebrand Mouse")


      end
    end
  end

end



function distance(p1,p2)
  local xDist = p1[1] - p2[1]
  local yDist = p1[2] - p2[2]
  local zDist = p1[3] - p2[3]

  local distanceSum = xDist * xDist + yDist * yDist + zDist * zDist

  return math.sqrt(distanceSum)

end

function summonSaltyOldStan()
  lizardBlocker = find_object_by_gm_note("Dragon God")
  if lizardBlocker != nil then
    lizardBlocker.destruct()
  end

  lizardBlocker = find_object_by_gm_note("Discard Blocking Dan")
  if lizardBlocker != nil then
    lizardBlocker.destruct()
  end

  makeSpecial("Tools","Salty Old Stan",-31.09 + 2.24,5,2.31,nil,"RTT Faction")

end

function summonLizardBlocker()
  stan = find_object_by_gm_note("Salty Old Stan")
  if stan == nil then
    makeSpecial("Tools","Lizard Blocker",-31.09,5,2.31,nil,"RTT Faction")
  end
end

-- The Dragon God (the Lizard Blocker) used to reach the table ONLY through the Lizard Wizard BUTTON,
-- and that button is gone -- so picking the lizards spawned the Lost Souls board with no blocker on
-- the discard. Two things make it reliable now:
--   * it is spawned by the lizards' own setup, whether or not a deck is on the table;
--   * makeDeck re-seats it afterwards, so a deck chosen LATER does not leave it stranded.
-- makeSpecial is a TOGGLE (it destroys the object if it already exists), so this never calls it on a
-- Dragon God that is already out -- it repositions that one instead.
RTT_DRAGON_GOD = { -31.09, 5, 2.31 }

-- Where makeSpecial actually PUTS the blocker. Those three numbers are an offset added on top of the
-- blueprint's own move_to, so re-seating a blocker to them directly would drop it somewhere else
-- entirely. This repeats makeSpecial's arithmetic so "put it back" means the spot it first landed on.
function rttDragonGodSpot()
  local def = EVERYTHING["Tools"] and EVERYTHING["Tools"]["Lizard Blocker"]
  local piece = def and def['data'] and def['data'][1]
  if piece == nil or piece.move_to == nil then
    return { RTT_DRAGON_GOD[1], RTT_DRAGON_GOD[2], RTT_DRAGON_GOD[3] }
  end
  local sc = Vector({ RTT_BOARD_SCALE, 1, RTT_BOARD_SCALE })
  local m = piece.move_to
  return { m[1] * 15.5 / sc.x + RTT_DRAGON_GOD[1],
           m[2] * sc.y - 0.1 + 10.01 + RTT_DRAGON_GOD[2],
           m[3] * 15.5 / sc.z + RTT_DRAGON_GOD[3] }
end

function rttPlaceDragonGod()
  if find_object_by_gm_note("Salty Old Stan") ~= nil then return end   -- Stan replaces the blocker
  local dg = find_object_by_gm_note("Dragon God")
  if dg ~= nil then
    local at = rttDragonGodSpot()
    pcall(function() if dg.getLock() then dg.setLock(false) end end)
    pcall(function() dg.setPosition({ at[1], at[2], at[3] }) end)
    -- ADOPT an untagged blocker: one summoned by the Lizard Wizard button, or restored from a save
    -- written before the spawns carried a tag, is invisible to teardown and would leak one more game.
    pcall(function() if not dg.hasTag("RTT Faction") then dg.addTag("RTT Faction") end end)
    return
  end
  makeSpecial("Tools", "Lizard Blocker", RTT_DRAGON_GOD[1], RTT_DRAGON_GOD[2], RTT_DRAGON_GOD[3],
              nil, "RTT Faction")
end


function spawnWingedMenaceExtraHand(color)
  local angleY = Player[color].getHandTransform(1).rotation.y
  local posX = Player[color].getHandTransform(1).position.x
  local posZ = Player[color].getHandTransform(1).position.z

  local angle = 1.07 * 2 * math.pi/6 - (math.pi/180 * angleY)

  local offsetX = math.cos(angle) * 13.53
  local offsetZ = math.sin(angle) * 13.53

  local posy = Vector({posX + offsetX,12.56,posZ + offsetZ})
  local roty = Player[color].getHandTransform(1).rotation

  Player[color].setHandTransform({
      position = posy,
      rotation = roty,
      scale    = {5.99, 5.4, 5.50},
  }, 2)
end

-- Where the supporters zone (hand 2) sits for a seat whose MAIN hand is `hand1`. A PURE function of
-- its argument: the same seat in gives the same answer out, whatever the table happens to look like at
-- the moment it runs. Accepts both transform shapes the mod uses -- named (position.x, rotation.y, as
-- getHandTransform returns) and plain arrays ({0,180,0}, as RTT_SEAT_HAND stores).
function rttSupportersTransform(hand1)
  local pos = (hand1 or {}).position or {}
  local rot = (hand1 or {}).rotation or {}
  local posX   = pos.x or pos[1] or 0
  local posZ   = pos.z or pos[3] or 0
  local angleY = rot.y or rot[2] or 0

  local angle = 2.517 - (math.pi/180 * angleY)

  local offsetX = math.cos(angle) * 14.73
  local offsetZ = math.sin(angle) * 14.73

  return {
      position = Vector({posX + offsetX, 12.56, posZ + offsetZ}),
      rotation = rot,
      scale    = {12, 5.4, 5.50},
  }
end

-- Marker for the test harness: this build takes the seat explicitly.
RTT_SUPPORTERS_EXPLICIT = true

-- `hand1` is the seat's MAIN hand transform. Pass it whenever the caller knows where the seat is --
-- a function that is GIVEN the seat cannot be called too early. Reading hand 1 instead is what made
-- this depend on call order: makeFaction ran it before moving hand 1, so the supporters hand was built
-- from the player's PREVIOUS seat and the Alliance drew its three cards into the old supporter area.
-- The fallback read stays for callers that genuinely have no seat to hand over.
function spawnSupportersHand(color, hand1)
  hand1 = hand1 or Player[color].getHandTransform(1)
  Player[color].setHandTransform(rttSupportersTransform(hand1), 2)
end


function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function starts_with(str, start)
   return str:sub(1, #start) == start or start == str
end

function makeDeck(player,value,id)
  clearInfo()
  removeDeckItems()
  local my_rot = self.getRotation()
  local objects = {}
  local scale = rttPlaceScale()

  -- The DARK DECK branch is gone with its data. makeDeck can only ever be handed one of three ids --
  -- the three deck buttons in the board XmlUI, and the same three in RTT_PICK_DEFS -- so nothing could
  -- ever reach it, and it was the only thing keeping 216 KB of Dark Deck blueprint alive.
  if (ends_with(id,"2")) then
    allObjects = {EVERYTHING["Decks"]['Refill Card']['data'],EVERYTHING["Decks"][id]['data']}
  else
    allObjects = {EVERYTHING["Decks"]['Refill Card']['data'],EVERYTHING["Decks"]["Dominance Track Card"]['data'],EVERYTHING["Decks"][id]['data']}
  end

  for _,n in ipairs(allObjects) do
    for _,v in ipairs(n) do
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1

      vec = vec * Vector({15.5, 1, 15.5})

      local newVec = Vector({0,1,0})
      newVec.x = vec.z * -1
      newVec.y = vec.y + 10.01
      newVec.z = vec.x


      local new_pos = newVec
      new_pos.y = new_pos.y+10-8.5+0.05
      new_pos.x = new_pos.x - 45 + 8.01
      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          callback_function = function(o)
            o.setRotation({o.getRotation().x, o.getRotation().y-90, o.getRotation().z})
            local _tg=o.getTags(); table.insert(_tg,"Deck Object"); o.setTags(_tg)
            if o.name == "Deck" then
              o.shuffle()
            end

            for _,i in ipairs(getObjects()) do
              if i.name == "Deck" and i.hasTag("Deck Object") then
                for _,m in ipairs(i.getObjects()) do
                  --m.addTag("Deck Object")
                end
              end
            end
          end
      })
    end
  end
  -- A deck chosen AFTER the lizards were set up drops a fresh draw/discard pile where the blocker
  -- sits, so put the Dragon God back on top of it. Does nothing when there is no blocker out.
  if find_object_by_gm_note("Dragon God") ~= nil then
    Wait.frames(function() pcall(function() rttPlaceDragonGod() end) end, 2)
  end
end





function makeMapTool(id)
  local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING["Tools"][id]['data']
  local scale = rttPlaceScale()

  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1

      vec = vec * Vector({-15.5, 1, 15.5})

      local newVec = Vector({0,1,0})
      newVec.x = vec.z
      newVec.y = vec.y + 10.01
      newVec.z = vec.x

      local new_pos = newVec
      new_pos.y = new_pos.y + 10 - 8.5 + 0.05
      new_pos.x = new_pos.x - 45 - 8.31 - 7.82
      new_pos.z = new_pos.z -1.38
      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          callback_function = function(o)
            local _tg=o.getTags(); table.insert(_tg,"Map Object"); o.setTags(_tg)
            o.setRotation({o.getRotation().x, o.getRotation().y, o.getRotation().z})
          end
      })

  end

end










function makeTool(player,value,id)
  local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING["Tools"][id]['data']
  local scale = rttPlaceScale()

  function callback(o)
      o.setRotation({o.getRotation().x, o.getRotation().y+90, o.getRotation().z})
      if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
  end
  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1

      vec = vec * Vector({15.5, 1, 15.5})

      local newVec = Vector({0,1,0})
      newVec.x = vec.z
      newVec.y = vec.y + 10.01
      newVec.z = vec.x * -1

      local new_pos = newVec
      new_pos.y = new_pos.y+10-8.5+0.05
      new_pos.x = new_pos.x + 45 + 8.31
      new_pos.z = new_pos.z -1.38

      if id == "Advanced Setup" then
        new_pos.x = new_pos.x + 10 - 2.53
        new_pos.z = new_pos.z + 20 + 4.37 - 0.55
      end

      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          callback_function = callback
      })
  end
end















function toggleSpecial(id)
  local guids = {}
  local names = {}

  -- if id == "Lizard Wizard" then guids = {""} names = {"Outcast Marker","Lizard Wizard"} end
  if id == "Lizard Blocker" then guids = {""} names = {"Dragon God"} end
  if id == "Koffin Keeper" then names = {"Koffin Keeper"} end
  if id == "Battle Mat" then names = {"Battle Mat"} end

  local found = false

  for i, object in pairs(getObjects()) do
    for j, name in pairs(names) do

      if object.getName() == name then

        object.destruct()
        found = true
      end
    end
  end

  return found
end

function makeSpecial(category,name,x,y,z,rotation,tag)

  if toggleSpecial(name) == true then return end

  local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING[category][name]['data']
  local scale = rttPlaceScale()

  local alterRotation = 180
  if rotation != nil then
    alterRotation = rotation
  end

  function callback(o)
      o.setRotation({o.getRotation().x, o.getRotation().y + alterRotation, o.getRotation().z})
      -- optional tag so map-scoped spawns are cleared by removeMapItems (single-spawn guarantee)
      if tag ~= nil then local _tg = o.getTags(); table.insert(_tg, tag); o.setTags(_tg) end
  end
  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1

      vec = vec * Vector({15.5, 1, 15.5})

      local newVec = Vector({0,1,0})
      newVec.x = vec.x
      newVec.y = vec.y + 10.01
      newVec.z = vec.z

      local new_pos = newVec
      new_pos.x = new_pos.x + x
      new_pos.y = new_pos.y + y
      new_pos.z = new_pos.z + z

      local new_rot = Vector({0,0,0})
      new_rot.x = new_rot.x
      new_rot.y = new_rot.y
      new_rot.z = new_rot.z

      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          rotation          = new_rot,
          callback_function = callback
      })
  end
end

function makeSpecialWithTag(category,name,x,y,z,tag,rotationY)
  local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING[category][name]['data']
  local scale = rttPlaceScale()

  function callback(o)
      o.setRotation({o.getRotation().x, o.getRotation().y, o.getRotation().z})
  end
  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1

      vec = vec * Vector({15.5, 1, 15.5})

      local newVec = Vector({0,1,0})
      newVec.x = vec.x
      newVec.y = vec.y + 10.01
      newVec.z = vec.z

      local new_pos = newVec
      new_pos.x = new_pos.x + x
      new_pos.y = new_pos.y + y
      new_pos.z = new_pos.z + z
      spawnObjectJSON({
          json              = v.json,
          position          = new_pos,
          rotation          = rotationY and {0, rotationY, 0} or nil,   -- spawn FINAL facing (no delayed rotate)
          callback_function = function(spawned_object)
            local _tg=spawned_object.getTags(); table.insert(_tg,tag); spawned_object.setTags(_tg)
          end
      })
  end
end

















function find_object_by_gm_note(gm_note)
   local objects = {}
   for _, obj in ipairs(getAllObjects()) do
      if obj.getName() == gm_note then
         table.insert(objects, obj)
      end
   end
   return objects[1]
end




-- 9 always-present Marsh clearings: world x, y, z, rotY
RTT_MARSH_SUIT9 = {
  { 21.347, 11.684, -16.915, 75 }, { -11.094, 11.719, -16.054, 225 }, { -17.962, 11.719, -13.523, 30 },
  { 22.784, 11.719, -11.850, 165 }, { -0.718, 11.719, -0.272, 75 }, { 6.024, 11.719, 2.893, 135 },
  { 16.941, 11.719, 11.653, 240 }, { -23.584, 11.719, 19.613, 300 }, { -2.042, 11.719, 21.443, 30 },
}
-- 2 fixed ruin clearings: world x, y, z
RTT_MARSH_RUIN_FIXED = { { 4.435, 11.656, 7.056 }, { -4.046, 11.665, -2.435 } }
-- each marker's two candidate clearings, world positions:
--   flood = { x, y, z, rotZ } (where the marker sits when this side floods)
--   suit  = { x, y, z, rotY } (where a suit sits on this side when it is DRY)
--   ruin  = { x, y, z }       (where a ruin sits when DRY; markers B and C only)
RTT_MARSH = {
  { key = "A", tag = "53E4E9F1",
    up   = { flood = { -11.380, 11.720, 7.150, 0 },   suit = { -13.504, 11.739, 5.340, 225 } },
    down = { flood = { -20.930, 11.790, -2.720, 180 }, suit = { -17.795, 11.742, -5.680, 135 } } },
  { key = "B", tag = "C5C35E37",
    up   = { flood = { 15.910, 11.639, 3.730, 0 },   suit = { 17.342, 11.695, 0.101, 165 }, ruin = { 14.323, 11.641, 3.736 } },
    down = { flood = { 7.200, 11.750, -7.210, 180 }, suit = { 3.811, 11.711, -8.597, 240 }, ruin = { 6.153, 11.649, -6.705 } } },
  { key = "C", tag = "B37C9A48",
    up   = { flood = { 7.700, 11.654, 16.860, 0 },   suit = { 5.947, 11.717, 20.588, 345 }, ruin = { 8.081, 11.653, 15.388 } },
    down = { flood = { 0.880, 11.750, -16.920, 180 }, suit = { 3.512, 11.710, -14.611, 45 }, ruin = { 0.461, 11.654, -19.318 } } },
}

-- correct single-pass Fisher-Yates; NO os.time re-seed
function rttShuffleList(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

function rttMarshPlan(objects)
  -- NO os.time re-seed here: it made rapid re-clicks land in the same second -> same flood
  -- (see rtt-rng-bug). The RNG is seeded once at load; each call advances it, so every click
  -- re-randomises instantly.

  -- world (x,z) of each clearing that floods this build; m460 uses this to drop the
  -- priority-number token on each flooded (submerged, no-suit) clearing.
  RTT_MARSH_FLOODED = {}
  -- world (x,z) of the CLEARING CENTRE (suit position) that is inactive this build. m460's
  -- number logic matches these against RTT_MARSH_RANK to skip the excluded clearings. The
  -- flood MARKER sits ~2.8u off the clearing centre, so this is the suit slot, not the marker.
  RTT_MARSH_EXCLUDED = {}

  local floodIx = {}
  local ruinIx = {}
  local suitIx = {}
  for idx, v in ipairs(objects) do
    local j = v.json
    if     string.find(j, "53E4E9F1", 1, true) then floodIx["A"] = idx
    elseif string.find(j, "C5C35E37", 1, true) then floodIx["B"] = idx
    elseif string.find(j, "B37C9A48", 1, true) then floodIx["C"] = idx
    elseif string.find(j, "RUIN", 1, true) then ruinIx[#ruinIx + 1] = idx
    elseif string.find(j, "Clearing Marker", 1, true) then suitIx[#suitIx + 1] = idx
    end
  end

  local ov = {}
  local drySuits = {}
  local dryRuins = {}
  for _, m in ipairs(RTT_MARSH) do
    local flooded, dry
    if math.random(2) == 1 then flooded = m.up; dry = m.down else flooded = m.down; dry = m.up end
    RTT_MARSH_FLOODED[#RTT_MARSH_FLOODED + 1] = { flooded.flood[1], flooded.flood[3] }
    RTT_MARSH_EXCLUDED[#RTT_MARSH_EXCLUDED + 1] = { flooded.suit[1], flooded.suit[3] }
    local fi = floodIx[m.key]
    if fi ~= nil then
      local f = flooded.flood
      ov[fi] = { world = { f[1], f[2], f[3] }, rot = { 0, 180, f[4] } }
    end
    local s = dry.suit
    drySuits[#drySuits + 1] = { s[1], s[2], s[3], s[4] }
    if dry.ruin ~= nil then
      local r = dry.ruin
      dryRuins[#dryRuins + 1] = { r[1], r[2], r[3] }
    end
  end

  -- RUINS: 2 fixed + 2 dry world slots; shuffle across the 4 ruin entries (items randomised)
  local ruinSlots = {}
  for _, p in ipairs(RTT_MARSH_RUIN_FIXED) do ruinSlots[#ruinSlots + 1] = { p[1], p[2], p[3] } end
  for _, p in ipairs(dryRuins) do ruinSlots[#ruinSlots + 1] = p end
  rttShuffleList(ruinSlots)
  for i, idx in ipairs(ruinIx) do
    local p = ruinSlots[i]
    if p ~= nil then ov[idx] = { world = { p[1], p[2], p[3] }, rot = nil } end
  end

  -- SUITS: all 12 clearings randomised (4 of each colour) across 9 fixed + 3 dry
  local suitTargets = {}
  for _, p in ipairs(RTT_MARSH_SUIT9) do suitTargets[#suitTargets + 1] = { p[1], p[2], p[3], p[4] } end
  for _, p in ipairs(drySuits) do suitTargets[#suitTargets + 1] = p end
  rttShuffleList(suitTargets)
  for i, idx in ipairs(suitIx) do
    local t = suitTargets[i]
    if t ~= nil then ov[idx] = { world = { t[1], t[2], t[3] }, rot = { 0, t[4], 0 } } end
  end

  return ov
end


RTT_PRIO_PIECES = RTT_PRIO_PIECES or {}
RTT_PRIO_MAP = RTT_PRIO_MAP or nil

-- clear the current priority/number markers. They are tagged "RTT Priority" (NOT "Map Object") so
-- makeMap's removeMapItems does NOT wipe them every click — we manage them here instead.
function rttClearPriority()
  for _, o in ipairs(getObjectsWithTag("RTT Priority")) do pcall(function() o.destruct() end) end
  RTT_PRIO_PIECES = {}
  -- and forget WHICH map's markers we were holding. RTT_PRIO_MAP means two things -- "which map's
  -- marker objects are on the table" and "which map was last built" -- and rttSpawnPriority's
  -- same-map guard reads the first. Leaving it set after destroying the objects is what made
  -- Summer -> Clear All -> Summer come back with no priority markers at all: the guard saw
  -- RTT_PRIO_MAP == "Summer Map" and returned before spawning anything.
  RTT_PRIO_MAP = nil
end

-- Non-Marsh maps: the priority markers are FIXED, so on a SAME-map re-click leave them alone (no
-- delete/respawn flicker). Only re-spawn when the map actually changed.
function rttSpawnPriority(id, jsons)
  if RTT_PRIO_MAP == id then return end
  rttClearPriority()
  for _, j in ipairs(jsons) do
    local ob = spawnObjectJSON({
      json = j,
      callback_function = function(o)
        o.setLock(true)
        o.addTag("RTT Priority")
      end
    })
    RTT_PRIO_PIECES[#RTT_PRIO_PIECES + 1] = ob
  end
  RTT_PRIO_MAP = id
end

-- Marsh number tokens (priority order, skip-excluded-and-renumber).
--
-- The 15 Marsh clearings have a FIXED priority RANK (RTT_MARSH_RANK, world x,y,z, rank 1
-- first — recorded by the maintainer, cross-checked against m440's suit positions). Exactly 3 are
-- inactive each game: the flooded sides in 4-player, the town-landmark clearings in
-- 5-player. Both mods export the 3 inactive clearing CENTRES as RTT_MARSH_EXCLUDED (world
-- x,z). We walk the ranks; an excluded clearing gets NO token and does NOT consume a
-- number — every ACTIVE clearing takes the next consecutive number 1..12 in rank order.
-- So the numbers stay consecutive across the 12 active clearings and "shift up" past any
-- excluded clearing, exactly per the maintainer's rule.
--
-- RTT_MARSH_NUMJSON[n] is a full number-token JSON with number n's art baked in; we spawn
-- it at the clearing's centre, upright (rotY 180, uniform so every number reads the same
-- way), locked, tagged "Map Object" so the next map build clears it.
-- each entry: { suitX, suitY, suitZ,  tokenX, tokenZ } — the SUIT centre is used only for the
-- flood/landmark skip test; the number token is placed at the maintainer's deliberate TOKEN position
-- (offset beside the clearing so the suit stays visible), recorded per-clearing like every map.
-- the number tokens' true resting height on the (flat) Marsh board — recorded ~11.63-11.66;
-- 11.635 = map surface (~11.61) + half token thickness, so they sit ON the board, not floating.
RTT_MARSH_TOKEN_Y = 11.635

RTT_MARSH_RANK = {
  { -23.584, 11.719,  19.613,  -22.723,  15.732 },   -- 1  FIX7
  {  -2.042, 11.719,  21.443,   -6.780,  15.272 },   -- 2  FIX8
  {   5.947, 11.717,  20.588,   10.119,  13.567 },   -- 3  C.up
  {  16.941, 11.719,  11.653,   22.373,  17.238 },   -- 4  FIX6
  { -13.504, 11.739,   5.340,  -10.991,  11.491 },   -- 5  A.up
  {   6.024, 11.719,   2.893,    6.420,   8.630 },   -- 6  FIX5
  {  17.342, 11.695,   0.101,   14.726,   6.362 },   -- 7  B.up
  { -17.795, 11.742,  -5.680,  -23.281,   0.501 },   -- 8  A.down
  {  -0.718, 11.719,  -0.272,   -3.829,   3.173 },   -- 9  FIX4
  {   3.811, 11.711,  -8.597,    5.948,  -3.427 },   -- 10 B.down
  {  22.784, 11.719, -11.850,   17.876,  -4.877 },   -- 11 FIX3
  { -17.962, 11.719, -13.523,  -23.483, -13.564 },   -- 12 FIX2
  { -11.094, 11.719, -16.054,  -10.851,  -9.377 },   -- 13 FIX1
  {   3.512, 11.710, -14.611,   -0.883, -13.135 },   -- 14 C.down
  {  21.347, 11.684, -16.915,   15.435, -13.961 },   -- 15 FIX0
}

function rttSpawnMarshNumbers()
  rttClearPriority()                    -- Marsh ALWAYS re-places: the flood shifts which clearings get a number
  local excl = RTT_MARSH_EXCLUDED or {}
  local n = 0
  for _, cl in ipairs(RTT_MARSH_RANK) do
    local isEx = false
    for _, e in ipairs(excl) do
      local dx, dz = cl[1] - e[1], cl[3] - e[2]                 -- SUIT centre vs the excluded clearing
      if dx * dx + dz * dz < 4.0 then isEx = true break end     -- within 2u = this clearing
    end
    if not isEx then
      n = n + 1
      local j = RTT_MARSH_NUMJSON[n]
      if j ~= nil then
        local ob = spawnObjectJSON({
          json = j,
          -- the maintainer's TOKEN x,z; Y = the tokens' true resting height on the (flat) Marsh board.
          -- (cl[2] is the SUIT marker's Y; number tokens rest ~0.05 lower, so cl[2]+0.10 floated.)
          position = { cl[4], RTT_MARSH_TOKEN_Y, cl[5] },
          rotation = { 0, 180, 0 },
          callback_function = function(o)
            o.setLock(true)
            o.addTag("RTT Priority")
          end
        })
        RTT_PRIO_PIECES[#RTT_PRIO_PIECES + 1] = ob
      end
    end
  end
  RTT_PRIO_MAP = "Marsh Map"
end

RTT_PRIO_SUMMERMAP = {
[==[{"Name":"Custom_Tile","Transform":{"posX":19.4757576,"posY":11.6273184,"posZ":-18.6938076,"rotX":0.005635698,"rotY":179.989914,"rotZ":0.03719062,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":23.3396435,"posY":11.62777,"posZ":1.06880569,"rotX":0.016964,"rotY":179.98999,"rotZ":0.0796116,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-2.73508215,"posY":11.6417341,"posZ":-18.65656,"rotX":0.005637319,"rotY":179.989853,"rotZ":0.0371895619,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":7.180888,"posY":11.6464376,"posZ":-11.7091885,"rotX":0.016964579,"rotY":179.98996,"rotZ":0.0796767,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-21.743782,"posY":11.6861992,"posZ":-13.15774,"rotX":0.0169652123,"rotY":179.98999,"rotZ":0.0796188042,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":9.632904,"posY":11.6476526,"posZ":3.90398622,"rotX":0.0169640817,"rotY":179.98999,"rotZ":0.0796179548,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-11.0734482,"posY":11.67535,"posZ":0.2815354,"rotX":0.016962165,"rotY":179.98999,"rotZ":0.07961434,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-2.37778473,"posY":11.6667957,"posZ":12.2024059,"rotX":0.0169569813,"rotY":179.989975,"rotZ":0.0796125159,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":1.64489985,"posY":11.6640606,"posZ":21.8496723,"rotX":0.0169646889,"rotY":179.990021,"rotZ":0.0796202347,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-23.28659,"posY":11.6941137,"posZ":6.34996939,"rotX":0.0169601422,"rotY":179.98996,"rotZ":0.079614535,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":21.8361168,"posY":11.6290245,"posZ":14.2142534,"rotX":0.005636237,"rotY":179.990021,"rotZ":0.03718929,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-20.2646275,"posY":11.6939926,"posZ":20.1305485,"rotX":0.0169394929,"rotY":179.999969,"rotZ":0.07961516,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

RTT_PRIO_LAKEMAP = {
[==[{"Name":"Custom_Tile","Transform":{"posX":20.72045,"posY":11.6269884,"posZ":-14.075,"rotX":0.01707049,"rotY":179.980621,"rotZ":0.07928706,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":17.20348,"posY":11.63603,"posZ":-0.0392068624,"rotX":0.01706977,"rotY":179.980621,"rotZ":0.07928523,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-11.6628141,"posY":11.6736336,"posZ":-7.893329,"rotX":0.01707028,"rotY":179.980637,"rotZ":0.07928673,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-6.53558969,"posY":11.664403,"posZ":-15.0769644,"rotX":0.0170617625,"rotY":179.980621,"rotZ":0.07928014,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-23.1215343,"posY":11.6882038,"posZ":-12.2128506,"rotX":0.0170709752,"rotY":179.9806,"rotZ":0.07928791,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":7.31433249,"posY":11.6512995,"posZ":5.29380369,"rotX":0.0170678366,"rotY":179.980621,"rotZ":0.07928414,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-10.6409292,"posY":11.6777563,"posZ":10.7174692,"rotX":0.01707013,"rotY":179.980591,"rotZ":0.07928907,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":22.6365871,"posY":11.6314344,"posZ":9.784296,"rotX":0.0170676541,"rotY":179.980637,"rotZ":0.07928429,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-3.76704073,"posY":11.6710424,"posZ":20.1207924,"rotX":0.0170686953,"rotY":179.980682,"rotZ":0.0792811,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-22.8958645,"posY":11.6924343,"posZ":3.05817413,"rotX":0.0170696452,"rotY":179.980621,"rotZ":0.07928663,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":10.2253971,"posY":11.65028,"posZ":15.4044313,"rotX":0.0170671344,"rotY":179.980621,"rotZ":0.079255186,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-19.7764969,"posY":11.6924505,"posZ":17.6140862,"rotX":0.0170700829,"rotY":179.98056,"rotZ":0.0792297,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

RTT_PRIO_MOUNTAINMAP = {
[==[{"Name":"Custom_Tile","Transform":{"posX":21.884304,"posY":11.6631622,"posZ":-11.543458,"rotX":-0.00303634955,"rotY":179.982666,"rotZ":0.0071030343,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-10.2404976,"posY":11.666153,"posZ":-4.12470961,"rotX":-0.004594014,"rotY":179.971451,"rotZ":0.00683123572,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-16.25037,"posY":11.6674938,"posZ":-11.9075613,"rotX":-0.005424547,"rotY":180.179626,"rotZ":0.006536457,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":0.07380072,"posY":11.6662464,"posZ":-17.7458229,"rotX":-0.00540374964,"rotY":179.951675,"rotZ":0.0065832925,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":3.74582529,"posY":11.6644344,"posZ":-3.1141448,"rotX":-0.00408026,"rotY":179.990463,"rotZ":0.00595906563,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-24.3214741,"posY":11.667593,"posZ":-0.434426934,"rotX":-0.005161778,"rotY":180.179077,"rotZ":0.0072455043,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":17.6621685,"posY":11.6627684,"posZ":2.43875885,"rotX":-0.00175636751,"rotY":179.97435,"rotZ":0.00843545049,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-14.5032682,"posY":11.668087,"posZ":8.235988,"rotX":0.0008922803,"rotY":180.0274,"rotZ":0.008705587,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":3.66186762,"posY":11.6655617,"posZ":18.9243889,"rotX":0.00267338054,"rotY":180.0508,"rotZ":0.0087387925,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-4.656818,"posY":11.6647377,"posZ":2.88496566,"rotX":359.9924,"rotY":180.023514,"rotZ":0.00467696646,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":14.3778887,"posY":11.6628695,"posZ":16.1211967,"rotX":-0.001728588,"rotY":180.085632,"rotZ":0.007958697,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-17.3411045,"posY":11.66811,"posZ":18.3029881,"rotX":0.00438719941,"rotY":179.776474,"rotZ":0.011177633,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

RTT_PRIO_WINTERMAP = {
[==[{"Name":"Custom_Tile","Transform":{"posX":13.1429644,"posY":11.6360836,"posZ":-18.0989914,"rotX":0.01725648,"rotY":179.997,"rotZ":0.0783196,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":17.53493,"posY":11.635251,"posZ":-0.928741932,"rotX":0.0172520317,"rotY":179.996964,"rotZ":0.07831473,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-9.196553,"posY":11.6679935,"posZ":-13.5150642,"rotX":0.0172522459,"rotY":179.996964,"rotZ":0.0783165246,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":0.9956113,"posY":11.6556015,"posZ":-8.410915,"rotX":0.0172554348,"rotY":179.996948,"rotZ":0.0783173144,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-21.30375,"posY":11.685112,"posZ":-11.6129856,"rotX":0.0172520019,"rotY":179.996964,"rotZ":0.0783166438,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":2.47328329,"posY":11.6574059,"posZ":4.287547,"rotX":0.0172535349,"rotY":179.996948,"rotZ":0.07831349,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-4.83030224,"posY":11.6670837,"posZ":3.27984762,"rotX":0.0172490049,"rotY":180.000656,"rotZ":0.078317,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":21.48837,"posY":11.634676,"posZ":15.1060982,"rotX":0.017253736,"rotY":179.997025,"rotZ":0.0783196762,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-3.2374208,"posY":11.669322,"posZ":17.9463711,"rotX":0.0172648039,"rotY":179.996933,"rotZ":0.07831443,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-22.1138458,"posY":11.6915245,"posZ":5.9496,"rotX":0.0173868928,"rotY":180.003479,"rotZ":0.07773717,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":7.699822,"posY":11.6536627,"posZ":15.5816736,"rotX":0.0172642227,"rotY":179.996918,"rotZ":0.07831384,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-17.4910069,"posY":11.6894283,"posZ":20.02479,"rotX":0.0172506,"rotY":179.996964,"rotZ":0.07830751,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

RTT_PRIO_GORGEMAP = {
[==[{"Name":"Custom_Tile","Transform":{"posX":15.2794857,"posY":11.6335535,"posZ":-17.3521748,"rotX":0.0169799142,"rotY":180.00119,"rotZ":0.07935182,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-1.36980677,"posY":11.6612177,"posZ":-1.80235875,"rotX":0.0169796534,"rotY":180.001221,"rotZ":0.07935352,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-15.59134,"posY":11.6772356,"posZ":-14.201973,"rotX":0.0169804189,"rotY":180.0012,"rotZ":0.07935612,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-6.058814,"posY":11.6645575,"posZ":-12.4414024,"rotX":0.0169744249,"rotY":180.001266,"rotZ":0.07934895,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":21.7972431,"posY":11.6292524,"posZ":-1.40007865,"rotX":0.0169818923,"rotY":180.001221,"rotZ":0.079445906,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-19.65621,"posY":11.6867771,"posZ":-1.00397861,"rotX":0.01698038,"rotY":180.001221,"rotZ":0.07935612,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":12.952342,"posY":11.6448812,"posZ":9.99319649,"rotX":0.0169803649,"rotY":180.001236,"rotZ":0.0793563649,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-17.92166,"posY":11.68724,"posZ":8.662028,"rotX":0.01696891,"rotY":180.001221,"rotZ":0.0793511346,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":7.404812,"posY":11.6554928,"posZ":19.8760548,"rotX":0.0169815477,"rotY":180.001251,"rotZ":0.0793575,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-1.65581763,"posY":11.66551,"posZ":11.357152,"rotX":0.0169833116,"rotY":180.0012,"rotZ":0.07945639,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":20.0446281,"posY":11.6377363,"posZ":19.021677,"rotX":0.0169724859,"rotY":180.001144,"rotZ":0.07935147,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"Name":"Custom_Tile","Transform":{"posX":-19.01597,"posY":11.6920776,"posZ":19.8693466,"rotX":0.016982127,"rotY":180.001236,"rotZ":0.0793578,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

RTT_MARSH_NUMJSON = {
[1] = [==[{"Name":"Custom_Tile","Transform":{"posX":-22.8256683,"posY":11.6962337,"posZ":15.0386505,"rotX":0.016887866,"rotY":180.005692,"rotZ":0.07977283,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.12941125,"g":0.12941125,"b":0.12941125},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388728/5C589936BB09A04B26C29FD602219A1C24318F94/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[2] = [==[{"Name":"Custom_Tile","Transform":{"posX":-6.936001,"posY":11.6743279,"posZ":15.7647591,"rotX":0.0168983359,"rotY":180.005615,"rotZ":0.07977534,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735390584/A5F4904F8845C55E96472FB9D6B81C72D8CCFF74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[3] = [==[{"Name":"Custom_Tile","Transform":{"posX":3.86553,"posY":11.658967,"posZ":14.6660137,"rotX":0.0168985724,"rotY":180.005615,"rotZ":0.07977536,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735391630/1D520705DC560E7D5D8FF7BABC8310879513DBA4/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[4] = [==[{"Name":"Custom_Tile","Transform":{"posX":23.1922112,"posY":11.6326418,"posZ":16.6250629,"rotX":0.0168937836,"rotY":180.005539,"rotZ":0.0797789,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735392271/B6E7F63F7F1271386331507F3198D2B7BAE69223/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[5] = [==[{"Name":"Custom_Tile","Transform":{"posX":-15.101325,"posY":11.683238,"posZ":7.438606,"rotX":0.0169268027,"rotY":179.984329,"rotZ":0.07976854,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393030/9033BAB1D546F62067327382403806E3B097D915/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[6] = [==[{"Name":"Custom_Tile","Transform":{"posX":6.93981743,"posY":11.652935,"posZ":8.72676,"rotX":0.016900504,"rotY":180.00563,"rotZ":0.0797798261,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735393877/344FFF8AFA261E092936662D8124C9DBCF32B159/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[7] = [==[{"Name":"Custom_Tile","Transform":{"posX":14.5138464,"posY":11.6417446,"posZ":6.53542757,"rotX":0.016899284,"rotY":180.00563,"rotZ":0.07977588,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735394618/1C7937D88E8A996D14647B20DFF10A6202A69044/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[8] = [==[{"Name":"Custom_Tile","Transform":{"posX":-23.3667736,"posY":11.692584,"posZ":0.1327615,"rotX":0.0169014316,"rotY":180.0056,"rotZ":0.07986645,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735395411/679034452BE6FA8F601CB172FA2C3168BFCDB7BE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[9] = [==[{"Name":"Custom_Tile","Transform":{"posX":-8.586024,"posY":11.6709509,"posZ":-3.46062636,"rotX":0.0168996248,"rotY":180.005646,"rotZ":0.07977662,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735396376/B30D28410D62CA39D329D63A29467BC3CA075A3D/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[10] = [==[{"Name":"Custom_Tile","Transform":{"posX":6.003087,"posY":11.6505346,"posZ":-3.82328582,"rotX":0.0168997254,"rotY":180.005585,"rotZ":0.07977611,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397129/76BA556B9D32B4C3C78D5ABF2A2A5BAB9749D814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[11] = [==[{"Name":"Custom_Tile","Transform":{"posX":18.10021,"posY":11.6334057,"posZ":-4.80220127,"rotX":0.0168997757,"rotY":180.00563,"rotZ":0.079775244,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735397926/DE6E0673828A0A7F634540A2B6ACBEAB5AAE216C/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[12] = [==[{"Name":"Custom_Tile","Transform":{"posX":-23.08647,"posY":11.6879168,"posZ":-14.3724012,"rotX":0.0168999266,"rotY":180.005646,"rotZ":0.07977729,"scaleX":1.0,"scaleY":1.0,"scaleZ":1.0},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.129411221,"g":0.129411221,"b":0.129411221},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735398757/2E2A197DCA52CB92E02E340E04872DFD58E42814/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1723164680735388314/65B14443B80555C739C57BBACC5E57EFB6E263D1/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":1,"Thickness":0.1,"Stackable":false,"Stretch":false}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

function rttTheme(player, value, id)
  -- RTM THEME (this month) = the ranked-draft 5-player MARSH setup -- a normal ranked draft (NOT the old
  -- Militant+Insurgents pool), 5 players (draft 6), on the Marsh map. Same path as the 5-player button.
  RTT_THEME = false
  rttFivePStart(player, value, id)
end

-- ===== RTT lightweight per-player selectors + P1/P2 map/deck pick =====
RTT_SELECTOR_TAG = "RTT Selector"
RTT_ORDER = RTT_ORDER or {}
RTT_PICKED = { map = nil, deck = nil }
RTT_SOLO = false
-- Same rule as MANUAL_FACTION_SELECTOR_JSON above: every icon here is pre-fetched by the table
-- surface's CustomUIAssets in gen/src/save.json, or this board spawns with no buttons on a cold load.
RTT_SELECTOR_JSON = [===[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.56,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":15.5,"scaleY":1.0,"scaleZ":15.5},"Nickname":"","Description":"","GMNotes":"","Locked":true,"Grid":false,"Snap":false,"IgnoreFoW":false,"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/board/board_clean_v4.png","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1725416402718254700/C6F00394AFEE245DFFA53CD358F5F966AA754BC9/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"RTT_COORD_GUID = \"bab7e1\"\nfunction rttFacRelay(player, value, id)\n  local c = getObjectFromGUID(RTT_COORD_GUID)\n  if c ~= nil then c.call(\"rttCoordFaction\", { color = player.color, id = id, board = self.getGUID() }) end\nend","XmlUI":"<ToggleGroup id=\"rttFactions\" active=\"false\"><Text id=\"rttFacTitle\" text=\"\" position=\"0 64 -20\" width=\"260\" height=\"26\" fontSize=\"20\" color=\"#F9E6BB\"/><Button id=\"rttFac1\" onclick=\"rttFacRelay\" position=\"-46 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac2\" onclick=\"rttFacRelay\" position=\"0 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac3\" onclick=\"rttFacRelay\" position=\"46 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac4\" onclick=\"rttFacRelay\" position=\"-46 -18 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac5\" onclick=\"rttFacRelay\" position=\"0 -18 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac6\" onclick=\"rttFacRelay\" position=\"46 -18 -20\" width=\"42\" height=\"42\"/></ToggleGroup>","CustomUIAssets":[{"Type":0,"Name":"Marquise de Cat","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739429295/F6CF523AAA7DCC91AF3812339EBB3354F6D9891A/"},{"Type":0,"Name":"Eyrie Dynasties","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755958213/960DFA43E52D99A3250863FC63F3BA3AE5104325/"},{"Type":0,"Name":"Woodland Alliance","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755956632/E99D3C9B246A94F6A898EC0D8098A05FA9467473/"},{"Type":0,"Name":"The Lizard Cult","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755960838/D88CBE9192488A678AF3EC6DFC45B4C728C9A169/"},{"Type":0,"Name":"Riverfolk Company","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755963912/C9589D96259534C6FB15DD91F78E7E90A073FDD8/"},{"Type":0,"Name":"Underground Duchy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755961872/1E2748C8EDD0BDE039B81658AFD0B19C771569BD/"},{"Type":0,"Name":"Corvid Conspiracy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755959858/69B8EC707AD26EF2F558ACAB65B39163B812D3F6/"},{"Type":0,"Name":"Lord of the Hundreds","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818578726/CE952087E18A1C0B6B94E44EF53EB009A97A7122/"},{"Type":0,"Name":"Keepers in Iron","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818579404/C0D7197A109DBF0C2EFB34DF50AE2CA70A66C25B/"},{"Type":0,"Name":"Twilight Council","URL":"https://steamusercontent-a.akamaihd.net/ugc/2452866064845174396/6228F6A71DDC36CD883777CA958857CB123D7ECB/"},{"Type":0,"Name":"Lilypad Diaspora","URL":"https://steamusercontent-a.akamaihd.net/ugc/2508034524425991747/77C277526C0042FE2754C83836A1E2C3C03FAD38/"},{"Type":0,"Name":"Knaves of the Deepwood","URL":"https://steamusercontent-a.akamaihd.net/ugc/14468202139363768412/1012F7145C45B86F395C099B9AE80EA536529DD3/"}],"Tags":["RTT Selector"]}]===]
RTT_BOXSCORE_JSON = [====[{"Name":"BlockSquare","Transform":{"posX":0.0,"posY":2.0,"posZ":0.0,"rotX":0.0,"rotY":270.0,"rotZ":0.0,"scaleX":33.18,"scaleY":0.18,"scaleZ":9.07},"Nickname":"Root Box Score","Description":"Automatic box score for Root - Ultimate Collection.\nReads each faction's VP marker on the map's score track and records a per-round box score, following the TTS turn system. The INFO button on the sheet is the manual.","GMNotes":"","AltLookAngle":{"x":0.0,"y":180.0,"z":0.0},"ColorDiffuse":{"r":0.17,"g":0.1,"b":0.05},"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":false,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"LuaScript":"-- Root Box Score\n-- Automated per-turn scorekeeping for Root - Ultimate Collection (workshop 2516434159).\n--\n-- Score reading (no vision): every faction's VP marker is a named object\n-- (\"Marquise VP\", ...). The map token carries the printed 0-30 track as snap\n-- points (31 columns x 3 sub-rows on every map checked), found geometrically\n-- in the map's LOCAL coordinates - any map, anywhere, any rotation. A marker's\n-- score is the nearest track column to positionToLocal(marker position).\n--\n-- Turn integration: row order follows each faction's physical seat position, the\n-- active faction follows Turns.turn_color, and every turn pass locks the score\n-- of the faction whose turn just ended. RTT publishes faction-keyed seats; other\n-- tables fall back to the faction supply/board anchor itself. Hand zones are used\n-- only to associate factions with player colors and live display names. Without\n-- the turn system, END TURN cycles the rows manually.\n--\n-- The object IS the sheet: the walnut slab resizes itself to exactly match\n-- the rendered scoresheet (TTS object UI renders at 250 px per world unit),\n-- and every non-interactive element lets clicks through, so grabbing anywhere\n-- that is not a button drags the cardboard.\n--\n-- Silent by design: nothing is written to chat in normal play. DIAGNOSE\n-- (right-click menu) is the only thing that ever broadcasts.\n\n------------------------------------------------------------------ constants --\n-- NO VERSION AND NO SIGNATURE HERE. The sheet used to sign itself \"made by MrDrouf . <BUILD>\", from\n-- a build string of its own. The box score ships inside the mod now, so both live on the setup\n-- board's top right corner as one line, \"by MrDrouf v<n>\" -- the maintainer, 2026-09-07: \"remove the\n-- boxscore version ... now they are the same\", then \"remove the made by MrDrouf in the boxscore\".\n-- See tools/bump_version.py in the RTT repo.\n-- log() is NOT editor-only: it also lands in the in-game chat log, so every\n-- debug message must stay behind this gate (the sheet is silent by contract).\n-- Flip at runtime with boxDebug(true) over the External Editor API.\nlocal DEBUG = false\nlocal function dbg(m) if DEBUG then log(m) end end\nfunction boxDebug(v)\n  if type(v) == \"table\" then v = v[1] end\n  DEBUG = (v == true)\nend\nlocal POLL_SECONDS   = 1.2\nlocal SNAP_MIN       = 40\nlocal ROW_TOL        = 0.13\nlocal COL_TOL        = 0.45\nlocal MIN_CELLS      = 28\nlocal MAX_CELLS      = 60\nlocal PX_PER_UNIT    = 100    -- TTS object-UI render density (measured on a\n                              -- live table: the sheet drew 2.5x larger than a\n                              -- slab sized with the documented 250)\nlocal BASE_SCALE     = 5.4    -- sheet size multiplier at size 1.0\n\n-- NO custom font here. TTS's setCustomAssets only accepts image formats -- a .ttf is rejected with\n-- \"Load image failed unsupported format: UNKNOWN\" and the error repeats on every rebuild. A custom UI\n-- font has to be registered through the Custom UI Assets PANEL, which a script cannot do, so the sheet\n-- stays on TTS's default face.\n\n-- palette: walnut board, parchment sheet, ink, rust and wax-seal gold\n-- the single notebook tab the export writes; declared here so uiExport can see it\nlocal NOTEBOOK_TAB = \"BoxScore\"\n\nlocal WALNUT  = \"#2B1A0C\"\nlocal PARCH   = \"#F9E6BB\"   -- ONE cream for the whole mod: the crafted card's own ground\nlocal PARCH2  = \"#E7D8B4\"\nlocal GOLD    = \"#C9A05C\"\nlocal GOLDHI  = \"#E4C88E\"\nlocal INKTXT  = \"#26170B\"\nlocal RUST    = \"#7E4A1E\"\n\nlocal DECKS = { \"Base Deck\", \"Exiles and Partisans\", \"Squires and Disciples\" }\n\n-- Every standard dominance card in the mod is a Card named \"Dominance\" whose\n-- description is its suit. Frog dominance cards also exist, but Root's normal\n-- VP-marker dominance play uses only these four suits.\nlocal DOM_SUITS = { fox = true, mouse = true, rabbit = true, bird = true }\n\n-- the group's map pool, offered as one-click chips in setup\nlocal MAPS = { \"Summer\", \"Winter\", \"Lake\", \"Mountain\", \"Marsh\", \"Gorge\" }\n\n-- card-back artwork -> deck (extracted from the mod's own deck definitions)\nlocal DECK_BACKS = {\n  [\"CAF7209CF51CE857\"] = \"Base Deck\",\n  [\"2EEC952526C7E80D\"] = \"Exiles and Partisans\",\n  [\"CD47EFAA7F885F2A\"] = \"Squires and Disciples\",\n}\n\n-- vagabond characters / captains, for the per-row variant auto-detect\nlocal CHARS = { \"Thief\", \"Tinker\", \"Ranger\", \"Vagrant\", \"Arbiter\", \"Scoundrel\",\n  \"Adventurer\", \"Ronin\", \"Harrier\", \"Jailor\", \"Cheat\", \"Gladiator\" }\n\n-- TWO VAGABONDS ARE TWO ROWS. Root allows two, and the faction ships two score markers -- a white one\n-- and a black one -- for exactly that. A box-score row IS its marker's name, so the second vagabond's\n-- marker is named \"Vagabond 2 VP\" and its row is \"Vagabond 2\"; anything else and both players collapse\n-- onto one row, with the second showing no score at all and both markers reading into the first.\n-- Every rule that asks \"is this a vagabond?\" therefore has to ask about the BASE faction.\nlocal function baseFac(fac)\n  if type(fac) ~= \"string\" then return fac end\n  return (fac:gsub(\"%s+%d+$\", \"\"))\nend\n\n-- which factions carry a pickable detail, and its options\nlocal LEADERS = { \"Builder\", \"Charismatic\", \"Commander\", \"Despot\" }\nlocal function variantOptions(fac)\n  fac = baseFac(fac)\n  if fac == \"Eyrie\" then return LEADERS end\n  if fac == \"Vagabond\" or fac == \"Knaves\" then return CHARS end\n  return nil\nend\n\n-- toggle one item inside a comma-joined selection, keeping the list's order\nlocal function toggleCSV(csv, item, order)\n  local set = {}\n  for w in (csv or \"\"):gmatch(\"[^,]+\") do\n    set[w:match(\"^%s*(.-)%s*$\")] = true\n  end\n  if set[item] then set[item] = nil else set[item] = true end\n  local out = {}\n  for _, c in ipairs(order) do\n    if set[c] then table.insert(out, c) end\n  end\n  return table.concat(out, \", \")\nend\n\n-- the full faction roster (short names = VP marker names in the mod)\nlocal ROSTER = { \"Marquise\", \"Eyrie\", \"Alliance\", \"Vagabond\", \"Riverfolk\",\n  \"Lizard\", \"Duchy\", \"Crows\", \"Rats\", \"Badgers\", \"Knaves\", \"Council\", \"Diaspora\" }\n\n-- image-URL tail -> map name (extracted from the mod's own content registry)\nlocal MAP_NAMES = {\n  [\"gurcomPgXS0oWpng\"] = \"Tidal Flats\",   [\"BC18C7488CACA234\"] = \"Blighted City\",\n  [\"gurcombfYkkjcpng\"] = \"Mountainside\",  [\"FEDD130951792687\"] = \"River Town\",\n  [\"05CCC6DAE105DB80\"] = \"Taiga\",         [\"F09464EE61C0DEF8\"] = \"Gloom\",\n  [\"3FE895F51EC40B24\"] = \"Autumn\",        [\"7210583BE261317B\"] = \"Summer\",\n  [\"06452B5C93B62E68\"] = \"Winter\",        [\"4CFA846E1B68EB75\"] = \"Lake\",\n  [\"93D8213D360FBA8F\"] = \"Mountain\",      [\"5F33E4FEEE8089AB\"] = \"The Deep Woods\",\n  [\"664D1C3ABA5F3913\"] = \"The Wastelands\",[\"9BE9CA5E53B4C887\"] = \"Gorge\",\n  [\"D75950B3E5643325\"] = \"Gorge\",         [\"2D67B5C0F7D82E46\"] = \"Treasure Island\",\n  [\"3BBF750AB82C04EE\"] = \"Narrows and Islets\", [\"C2F717CB7259B659\"] = \"Australia\",\n  [\"27FB3B5790E593C9\"] = \"Tunnel Unraveled\",   [\"3AFD6922B0E9466F\"] = \"Tropics\",\n  [\"E183A0B6769D4C69\"] = \"Marsh\",         [\"7C8340140D11A8F2\"] = \"Lost Woodland\",\n  [\"D17AC01A7B9FA8C4\"] = \"Legends\",       [\"EF774E3AECED67F1\"] = \"Urban\",\n  [\"6A1B83F0415249F8\"] = \"Inferno\",       [\"A21F7344C4FEF62D\"] = \"Spaceballs\",\n  [\"78DE2047BA1B663E\"] = \"Blighted Grove\",\n}\n\n-- Whether attached UI inherits the object's scale is machine-dependent; both\n-- interpretations ship (right-click \"panel scale mode\" toggles). Mode 1\n-- (inherit) is the default and self-cancels so the sheet always matches the\n-- slab the script sizes for itself.\nlocal UI_POSES = {\n  { pos = \"0 0 -60\", rot = \"0 0 0\" },\n  { pos = \"0 0 -60\", rot = \"0 0 180\" },\n  { pos = \"0 0 -60\", rot = \"180 180 0\" },\n  { pos = \"0 0 -60\", rot = \"180 180 180\" },\n}\n-- 100% preserves the sheet's historical default footprint (the old size index\n-- used 0.7).  The legacy values remain only to migrate existing saved sheets.\nlocal LEGACY_SIZE_MULS = { 0.55, 0.7, 0.85, 1.05, 1.3, 1.6 }\nlocal LEGACY_BASE_MUL = 0.7\nlocal SIZE_MIN_PCT, SIZE_MAX_PCT = 50, 200\n\n----------------------------------------------------------------------- state --\nlocal S = {\n  rows      = {},   -- { fac, player, nameAuto, color, tintHex, iconUrl, guid,\n                    --   score, locks={}, edits={},\n                    --   dom={turn,round,suit,score,won,kind,frozen,markerGuid} }\n  active    = 1,\n  turns     = 0,\n  -- THE ROUND, declared rather than divided out. It used to be computed everywhere as\n  -- floor(S.turns / #S.rows) + 1, which makes the CURRENT row count a divisor of the WHOLE history:\n  -- a row appearing or disappearing mid-game retroactively re-maps every past and future lock, so a\n  -- column comes out blank or two rounds show the same numbers. The same formula also assumes\n  -- \"locks per round == #S.rows\", which is false the moment one seat's colour never gets a turn --\n  -- then every round after it lags a column behind for the rest of the game. Both of the reported\n  -- box-score symptoms (\"it skipped or omitted a number\", \"it tracked things weirdly\") come out of\n  -- that one expression. The round now only ever moves when a row that has ALREADY locked this round\n  -- locks again, which is the actual definition of the table having come round.\n  round     = 1,\n  -- One-shot latch: until a turn is actually recorded the pointer is held on\n  -- the FIRST SEAT. Cleared by the first lock or by any explicit pointer move\n  -- (row select / undo), never re-armed mid-game. Persisted with the rest of S,\n  -- so a pre-first-turn save reloads still pinned and an older save reads nil\n  -- (falsy) and is correctly left alone.\n  pinFirst  = true,\n  cols      = 10,   -- round columns always shown: fixed size during the game,\n                    -- growing only past round 10 (setup-editable)\n  flip      = false,\n  hidden    = false,\n  setup     = false,\n  pose      = 1,\n  scaleMode = 1,\n  sizePct   = 100,\n  meta      = { map = \"\", deck = \"\", hook = \"\", thread = \"\", game = \"\" },\n  unpicked  = {},   -- fac -> true (picked by hand from the roster)\n  unpickedVar = {}, -- fac -> \"cap1, cap2\" (captains available in the draft)\n  varRow    = 1,\n  experimental = false,\n  lastExport = \"\",\n  log       = {},\n  undo      = {},   -- faction NAMES (row order can change underneath)\n}\n\n-- ONE reader for the round, so no caller can invent its own definition again.\nlocal function currentRound()\n  local r = math.floor(tonumber(S.round) or 1)\n  if r < 1 then r = 1 end\n  return r\nend\n\n-- Which round a lock for THIS row would land in. The wrap is detected per row -- a row asked to lock\n-- when it has already locked this round means the table has come round again -- and that decision is\n-- made in ONE place so the column the sheet HIGHLIGHTS and the column lockRow actually WRITES cannot\n-- disagree. They did: S.round only moved when the first seat's turn ENDED, so from the moment the\n-- last seat passed until the first seat finished, the sheet highlighted the round that had just\n-- closed. Reported from the table, 2026-09-07: \"turn just stays on the current round when last\n-- player's turn ends\".\nlocal function roundForRow(row)\n  local r = currentRound()\n  if row ~= nil and (row.lastRound or 0) >= r then return r + 1 end\n  return r\nend\n\n-- The round the TABLE is on: the one the row about to play will write into. S.round deliberately\n-- stays lazy -- it is the base the per-row wrap is measured from, and moving it eagerly is what\n-- re-mapped everyone's columns in earlier versions -- so the live round is derived, never stored.\nlocal function liveRound()\n  return roundForRow(S.rows and S.rows[S.active or 1] or nil)\nend\n\nlocal TRACK = nil\nlocal lastTrackLogged = nil\nlocal pollCount = 0\n\n------------------------------------------------------------------- utilities --\nlocal function now() return os.time() end\n\n-- A turn length as m:ss, or blank when the player has not finished one yet. Minutes are not capped: a\n-- long think reads 12:07 rather than wrapping.\nlocal function mmss(secs)\n  local n = tonumber(secs)\n  if n == nil or n < 0 then return \" \" end\n  return string.format(\"%d:%02d\", math.floor(n / 60), n % 60)\nend\n\nlocal function clampSizePct(value)\n  return math.max(SIZE_MIN_PCT, math.min(SIZE_MAX_PCT,\n    math.floor((tonumber(value) or 100) + 0.5)))\nend\n\n-- RTT destroys and recreates the sheet when its map/ranked/tool buttons spawn\n-- one.  The saved S.sizePct handles normal reloads; this Global is only the\n-- in-session hand-off between the old object and its freshly spawned copy.\nlocal function rememberSizePct()\n  pcall(function() Global.setVar(\"RTT_BOXSCORE_SIZE_PCT\", S.sizePct) end)\nend\n\nlocal function logev(ev, fac, a, b)\n  table.insert(S.log, { t = now(), ev = ev, fac = fac, a = a, b = b })\n  if #S.log > 3000 then table.remove(S.log, 1) end\nend\n\nlocal function esc(s)\n  -- No ampersand survives TTS's XML pipeline (&amp; and &#38; both render as\n  -- literal \"&amp;\", raw & is a parse error) - substitute \"+\" and be done\n  s = tostring(s or \"\")\n  s = s:gsub(\"&\", \"+\"):gsub(\"<\", \"&#60;\"):gsub(\">\", \"&#62;\"):gsub('\"', \"&#34;\")\n  return s\nend\n\nlocal function spaced(s)\n  return (s:gsub(\"(.)\", \"%1 \"):gsub(\" $\", \"\"))\nend\n\nlocal function tintHex(o)\n  local ok, c = pcall(function() return o.getColorTint() end)\n  if not ok or c == nil then return \"888888\" end\n  return string.format(\"%02X%02X%02X\",\n    math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))\nend\n\nlocal function markerImage(o)\n  local ok, co = pcall(function() return o.getCustomObject() end)\n  if not ok or co == nil then return nil end\n  return co.image or co.face or co.diffuse\nend\n\nlocal function urlTail(u)\n  if u == nil then return \"\" end\n  u = u:gsub(\"[^A-Za-z0-9]\", \"\")\n  return u:sub(-16)\nend\n\nlocal function turnsRunning()\n  return Turns.enable and Turns.order ~= nil and #Turns.order > 0\nend\n\n-- TTS exposes the active color but no monotonic turn number. S.turns is the\n-- persisted count of completed turns, so the turn in progress is the next one.\nlocal function currentTurnNumber()\n  return math.max(1, math.floor(tonumber(S.turns) or 0) + 1)\nend\n\nlocal function assetName(fac)\n  return \"vp\" .. fac:gsub(\"%W\", \"\")\nend\n\n--------------------------------------------------------------- track finding --\nlocal function detectTrackOn(obj)\n  local ok, sp = pcall(function() return obj.getSnapPoints() end)\n  if not ok or sp == nil or #sp < SNAP_MIN then return nil end\n  local bandsFound = {}\n  for _, axis in ipairs({ \"x\", \"z\" }) do\n    local other = (axis == \"x\") and \"z\" or \"x\"\n    local pts = {}\n    for _, s in ipairs(sp) do\n      table.insert(pts, { a = s.position[axis], b = s.position[other] })\n    end\n    table.sort(pts, function(p, q) return p.b < q.b end)\n    local bands, cur = {}, {}\n    for _, p in ipairs(pts) do\n      if #cur > 0 and (p.b - cur[#cur].b) > 0.03 then table.insert(bands, cur); cur = {} end\n      table.insert(cur, p)\n    end\n    if #cur > 0 then table.insert(bands, cur) end\n    for _, band in ipairs(bands) do\n      if #band >= 25 then\n        local xs = {}\n        for _, p in ipairs(band) do table.insert(xs, p.a) end\n        table.sort(xs)\n        local diffs = {}\n        for i = 2, #xs do table.insert(diffs, xs[i] - xs[i - 1]) end\n        table.sort(diffs)\n        local s = diffs[math.ceil(#diffs / 2)]\n        local even = s > 0.01\n        if even then\n          for _, d in ipairs(diffs) do\n            local m = math.floor(d / s + 0.5)\n            if m < 1 or m > 2 or math.abs(d - m * s) > 0.25 * s then even = false end\n          end\n        end\n        if even then\n          local n = math.floor((xs[#xs] - xs[1]) / s + 0.5) + 1\n          if n >= MIN_CELLS and n <= MAX_CELLS and #xs >= 0.85 * n then\n            table.insert(bandsFound, { axis = axis, other = other,\n              a0 = xs[1], s = s, n = n, b = band[1].b })\n          end\n        end\n      end\n    end\n  end\n  if #bandsFound == 0 then return nil end\n  local best = nil\n  for _, band in ipairs(bandsFound) do\n    if best == nil then\n      best = { axis = band.axis, other = band.other, a0 = band.a0, s = band.s,\n               n = band.n, rows = { band.b } }\n    elseif band.axis == best.axis\n      and math.abs(band.s - best.s) < 0.1 * best.s\n      and math.abs(band.a0 - best.a0) < 0.5 * best.s then\n      table.insert(best.rows, band.b)\n      if band.n > best.n then best.n = band.n end\n    end\n  end\n  table.sort(best.rows)\n  -- keep the raw snap coordinates belonging to the track: markers are placed\n  -- exactly ON the mod's own snap points, so centering matches TTS snapping\n  best.pts = {}\n  local bmin, bmax = best.rows[1] - 0.05, best.rows[#best.rows] + 0.05\n  for _, s2 in ipairs(sp) do\n    local a = (best.axis == \"x\") and s2.position.x or s2.position.z\n    local b = (best.axis == \"x\") and s2.position.z or s2.position.x\n    if b >= bmin and b <= bmax then\n      table.insert(best.pts, { a = a, b = b })\n    end\n  end\n  best.guid = obj.getGUID()\n  return best\nend\n\nlocal function findTrack()\n  local best, bestSnaps = nil, 0\n  for _, o in ipairs(getAllObjects()) do\n    local ok, sp = pcall(function() return o.getSnapPoints() end)\n    if ok and sp and #sp >= SNAP_MIN and #sp > bestSnaps then\n      local t = detectTrackOn(o)\n      if t then best, bestSnaps = t, #sp end\n    end\n  end\n  TRACK = best\n  if TRACK then\n    local mapObj = getObjectFromGUID(TRACK.guid)\n    if mapObj and S.mapAuto ~= false then\n      -- read the board's identity from its artwork; a manual chip click\n      -- (uiRowBtn \"map\") turns this off for the session\n      local okc, co = pcall(function() return mapObj.getCustomObject() end)\n      local img = okc and co and (co.image or co.diffuse) or nil\n      local auto = MAP_NAMES[urlTail(img)]\n      if auto and auto ~= \"\" then S.meta.map = auto end\n    end\n    if TRACK.guid ~= lastTrackLogged then\n      lastTrackLogged = TRACK.guid\n      dbg(\"BoxScore: track on \" .. TRACK.guid .. \" axis=\" .. TRACK.axis\n        .. \" cells=\" .. TRACK.n .. \" rows=\" .. #TRACK.rows)\n    end\n  else\n    dbg(\"BoxScore: no score track found on any snap holder\")\n  end\nend\n\n---------------------------------------------------------------- score reads --\nlocal function readCell(markerObj)\n  if TRACK == nil then return nil end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then TRACK = nil; return nil end\n  if markerObj.held_by_color ~= nil then return nil end\n  local okm, moving = pcall(function() return markerObj.isSmoothMoving() end)\n  if okm and moving then return nil end\n  local lp = mapObj.positionToLocal(markerObj.getPosition())\n  local a, b = lp[TRACK.axis], lp[TRACK.other]\n  local nearRow = false\n  for _, rb in ipairs(TRACK.rows) do\n    if math.abs(b - rb) <= ROW_TOL + 0.12 then nearRow = true end\n  end\n  if not nearRow then return nil end\n  local idx = math.floor((a - TRACK.a0) / TRACK.s + 0.5)\n  if idx < 0 or idx > TRACK.n - 1 then return nil end\n  if math.abs(a - (TRACK.a0 + idx * TRACK.s)) > COL_TOL * TRACK.s then return nil end\n  return idx\nend\n\n-- Printed 0 sits at the track's MAXIMUM local coordinate (established three\n-- ways: markers parked on the printed 0 cell sit at local max; the on-table\n-- world view shows 0 bottom-left with the token's usual 180 rotation; and the\n-- map artwork places 0 at the image edge that maps to local max). So scores\n-- DESCEND along the local axis. S.flip reverses this for exotic maps only.\nlocal function cellToScore(idx)\n  if S.flip then return idx end\n  return TRACK.n - 1 - idx\nend\n\nlocal function scoreToCell(score)\n  if S.flip then return score end\n  return TRACK.n - 1 - score\nend\n\nlocal function findMarker(row)\n  local o = row.guid and getObjectFromGUID(row.guid) or nil\n  if o ~= nil and (o.getName() or \"\") == (row.fac .. \" VP\") then return o end\n  -- cached marker gone: re-find by name. Some kits spawn a spare copy (the\n  -- Vagabond's does), so prefer the one standing on the score track.\n  local loose = nil\n  for _, c in ipairs(getAllObjects()) do\n    if (c.getName() or \"\") == (row.fac .. \" VP\") then\n      if readCell(c) ~= nil then\n        row.guid = c.getGUID()\n        return c\n      end\n      if loose == nil then loose = c end\n    end\n  end\n  if loose ~= nil then row.guid = loose.getGUID() end\n  return loose\nend\n\nlocal function dominanceCardSuit(o)\n  if o == nil or (o.type ~= \"Card\" and o.tag ~= \"Card\") then return nil end\n  local okn, name = pcall(function() return o.getName() end)\n  if not okn or tostring(name or \"\"):lower() ~= \"dominance\" then return nil end\n  local okd, desc = pcall(function() return o.getDescription() end)\n  if not okd then return nil end\n  local suit = tostring(desc or \"\"):match(\"^%s*(.-)%s*$\"):lower()\n  return DOM_SUITS[suit] and suit or nil\nend\n\n-- Dominance is declared by physically putting the VP marker on the card. Use\n-- the card's live bounds (rather than CardIDs, which differ among deck copies)\n-- and require both objects to have settled before accepting the placement.\nlocal function objectSettled(o)\n  if o == nil or o.held_by_color ~= nil then return false end\n  local okm, moving = pcall(function() return o.isSmoothMoving() end)\n  if okm and moving then return false end\n  local okr, resting = pcall(function() return o.resting end)\n  if okr and resting == false then return false end\n  return true\nend\n\nlocal function markerSitsOnCard(marker, card)\n  if not objectSettled(marker) or not objectSettled(card) then return false end\n  local okb, b = pcall(function() return card.getBounds() end)\n  if not okb or b == nil or b.center == nil or b.size == nil then return false end\n  local mp = marker.getPosition()\n  local cx, cy, cz = b.center.x or b.center[1], b.center.y or b.center[2],\n    b.center.z or b.center[3]\n  local sx, sy, sz = b.size.x or b.size[1], b.size.y or b.size[2],\n    b.size.z or b.size[3]\n  if not cx or not cy or not cz or not sx or not sy or not sz then return false end\n  local dy = mp.y - cy\n  return math.abs(mp.x - cx) <= sx * 0.5 + 0.2\n    and math.abs(mp.z - cz) <= sz * 0.5 + 0.2\n    and dy >= -0.25 and dy <= math.max(3.0, sy + 2.0)\nend\n\nlocal function dominanceAt(marker, cards)\n  for _, c in ipairs(cards) do\n    if markerSitsOnCard(marker, c.obj) then return c.suit end\n  end\n  return nil\nend\n\n-- Count every copy of this faction's VP marker by settled location. This is\n-- deliberately independent of row.guid: Brazen Demagogue leaves the cached\n-- original on the score track and puts a copied marker on a dominance card.\nlocal function dominanceMarkerState(row, cards, objects)\n  local state = { domCount = 0, trackCount = 0, looseCount = 0,\n    unsettledCount = 0, suit = nil, domMarker = nil,\n    trackMarker = nil, trackIdx = nil }\n  if row == nil then return state end\n  local markerName = row.fac .. \" VP\"\n  for _, marker in ipairs(objects or getAllObjects()) do\n    if (marker.getName() or \"\") == markerName then\n      if not objectSettled(marker) then\n        state.unsettledCount = state.unsettledCount + 1\n      else\n        local suit = dominanceAt(marker, cards)\n        if suit ~= nil then\n          state.domCount = state.domCount + 1\n          if state.domMarker == nil then\n            state.domMarker, state.suit = marker, suit\n          end\n        else\n          local idx = readCell(marker)\n          if idx ~= nil then\n            state.trackCount = state.trackCount + 1\n            -- Prefer the already-cached original if more than one marker has\n            -- somehow been left on the track.\n            if state.trackMarker == nil or marker.getGUID() == row.guid then\n              state.trackMarker, state.trackIdx = marker, idx\n            end\n          else\n            state.looseCount = state.looseCount + 1\n          end\n        end\n      end\n    end\n  end\n  if state.trackMarker ~= nil then row.guid = state.trackMarker.getGUID() end\n  return state\nend\n\n-- Coalition (Root, Vagabond, 4+ players): a Vagabond cannot rule, so instead of activating a\n-- dominance card for dominance it forms a coalition -- its score marker leaves the track onto an\n-- ally's board, it stops scoring, and it wins if that ally wins. The ally must be the player with\n-- the FEWEST points (choose among ties) and must not have activated a dominance card themselves.\n-- The fewest-points part is a judgement at the moment of play, so the button offers the eligible\n-- rows rather than picking for you; ineligible ones are simply not offered.\nlocal COALITION_FACTIONS = { Vagabond = true, Knaves = true }\n\nlocal function canCoalition(row)\n  return row ~= nil and COALITION_FACTIONS[baseFac(row.fac)] == true\nend\n\n-- A row's place in the live turn order, by its colour. nil when there is no turn system running or\n-- the colour is not in it -- the caller falls back to the row's printed position.\nlocal function turnSlot(row)\n  if row == nil or row.color == nil or row.color == \"\" then return nil end\n  local o = Turns.order\n  if not turnsRunning() or type(o) ~= \"table\" then return nil end\n  for i = 1, #o do\n    if o[i] == row.color then return i end\n  end\n  return nil\nend\n\nlocal function coalitionCandidates(row)\n  local out = {}\n  for _, other in ipairs(S.rows) do\n    -- not yourself, not another vagabond, and not someone who has already activated dominance\n    -- baseFac, or \"Vagabond 2\" slips through: COALITION_FACTIONS is keyed by the BASE name, so the\n    -- second vagabond was offered as a coalition partner to the first.\n    if other.fac ~= row.fac and not COALITION_FACTIONS[baseFac(other.fac)] and other.dom == nil then\n      table.insert(out, other.fac)\n    end\n  end\n  return out\nend\n\nlocal function dominanceFrozen(row)\n  return row ~= nil and row.dom ~= nil and row.dom.frozen ~= false\nend\n\nlocal function dominanceKindLabel(dom)\n  if dom ~= nil and dom.kind == \"brazen_demagogue\" then\n    return \"Brazen Demagogue (still scoring)\"\n  end\n  return \"standard (frozen)\"\nend\n\nlocal function registerDominance(row, state)\n  local suit = state and state.suit or nil\n  if row == nil or row.dom ~= nil or not DOM_SUITS[suit] then return false end\n  local brazen = (state.trackCount or 0) > 0\n  row.dom = { turn = currentTurnNumber(),\n    round = roundForRow(row),\n    suit = suit, score = row.score, won = false,\n    kind = brazen and \"brazen_demagogue\" or \"standard\",\n    frozen = not brazen,\n    markerGuid = state.domMarker and state.domMarker.getGUID() or nil }\n  logev(\"dominance\", row.fac, row.dom.turn, suit)\n  return true\nend\n\nlocal function cancelDominance(row)\n  if row == nil or row.dom == nil then return false end\n  local dom = row.dom\n  -- Standard dominance restores its declaration-time score. Brazen has kept\n  -- reading the original track marker, so rewinding here would discard VP.\n  if dom.frozen ~= false then row.score = tonumber(dom.score) or row.score end\n  row.dom = nil\n  if S.winner == row.fac and S.winnerReason == \"dominance\" then\n    S.winner = nil\n    S.winnerReason = nil\n    S.winnerLock = nil\n  end\n  logev(\"dominance-undo\", row.fac, dom.turn, dom.suit)\n  return true\nend\n\n-- true = the declaration marker is still on a card; false = it settled away;\n-- nil = it is currently held/moving, so do not make a transient state change.\nlocal function dominanceMarkerActive(row, state, cards)\n  if row == nil or row.dom == nil then return false end\n  local guid = row.dom.markerGuid\n  if guid ~= nil and guid ~= \"\" then\n    local marker = getObjectFromGUID(guid)\n    if marker == nil or (marker.getName() or \"\") ~= (row.fac .. \" VP\") then\n      return false\n    end\n    if not objectSettled(marker) then return nil end\n    return dominanceAt(marker, cards) ~= nil\n  end\n  -- Migrate an already-active declaration saved by a pre-markerGuid build.\n  if state.domMarker ~= nil then\n    row.dom.markerGuid = state.domMarker.getGUID()\n    return true\n  end\n  if state.unsettledCount > 0 then return nil end\n  return false\nend\n\nlocal function syncDominance(row, cards, objects)\n  local state = dominanceMarkerState(row, cards, objects)\n  local changed = false\n  if row.dom ~= nil and dominanceMarkerActive(row, state, cards) == false then\n    changed = cancelDominance(row) or changed\n  end\n  if row.dom == nil and state.domCount > 0 then\n    changed = registerDominance(row, state) or changed\n  end\n  -- Re-classify a STILL-ACTIVE declaration when the track copy changes. Brazen Demagogue needs a marker\n  -- on the track AND one on a dominance card. If the maintainer copied a marker onto the card (registered\n  -- brazen, still scoring) and then ERASED the original track marker, it is now a STANDARD dominance play:\n  -- freeze the score and show the hyphen. The reverse (a standard play that later gains a track copy)\n  -- becomes brazen and resumes scoring.\n  if row.dom ~= nil and dominanceMarkerActive(row, state, cards) == true then\n    local wantBrazen = (state.trackCount or 0) > 0\n    if wantBrazen and row.dom.kind ~= \"brazen_demagogue\" then\n      row.dom.kind = \"brazen_demagogue\"; row.dom.frozen = false\n      changed = true; logev(\"dominance-reclass\", row.fac, \"brazen\")\n    elseif (not wantBrazen) and row.dom.kind == \"brazen_demagogue\" then\n      row.dom.score = row.score; row.dom.kind = \"standard\"; row.dom.frozen = true\n      changed = true; logev(\"dominance-reclass\", row.fac, \"standard\")\n    end\n  end\n  return state, changed\nend\n\n-- Track orientation is NOT inferred: on every map in this mod the printed 0\n-- sits at the track's minimum local coordinate and 30 at the maximum\n-- (verified against the artwork of all cached maps - the mod's authoring is\n-- uniform, matching the table rule \"bottom-left is 0, bottom-right is 30\").\n-- S.flip stays false unless manually toggled for some exotic future map.\n\n------------------------------------------------------- players and factions --\nlocal function rowByFac(fac)\n  for i, r in ipairs(S.rows) do\n    if r.fac == fac then return i end\n  end\n  return nil\nend\n\nlocal function rowByColor(color)\n  for i, r in ipairs(S.rows) do\n    if r.color == color then return i end\n  end\n  return nil\nend\n\nlocal function addRow(fac, obj)\n  table.insert(S.rows, { fac = fac, player = \"\", nameAuto = false, color = nil,\n    variant = \"\", variantAuto = true,\n    tintHex = tintHex(obj), iconUrl = markerImage(obj), guid = obj.getGUID(),\n    score = -1, locks = {}, edits = {} })\n  logev(\"join\", fac)\n  S.unpicked[fac] = nil   -- a playing faction cannot be the unpicked one\nend\n\n-- The point that marks a faction's play area: its supply bag when one\n-- exists. Some kits name theirs differently (the Rats play from the\n-- \"Hundreds Supply\", the Crows from the \"Corvid Supply\", the Badgers from\n-- the \"Keeper Supply\" - verified against the mod's own spawn data). The\n-- Vagabond has no supply at all: his FACTION BOARD anchors him, identified\n-- by its artwork since boards carry no usable name - the board never moves\n-- once set up, unlike his pawn, which wanders the map (and can do so before\n-- the VP marker ever reaches the track). The named pawn figurine\n-- (\"Vagabond - Thief\", ...) is only a last resort.\nlocal SUPPLY_ALIAS = { Rats = \"Hundreds\", Crows = \"Corvid\", Badgers = \"Keeper\" }\nlocal BOARD_ART = {\n  Vagabond = \"E9FFF39312426A1A13695C984510BB94B663436F\",\n}\n\nlocal function facAnchor(fac, byName)\n  byName = byName or {}   -- defensive: never index a nil table (audit: seat-box crash)\n  fac = baseFac(fac)      -- \"Vagabond 2\" has no pieces of its own; it uses the vagabond's\n  local o = byName[fac .. \" Supply\"]\n  if o == nil and SUPPLY_ALIAS[fac] ~= nil then\n    o = byName[SUPPLY_ALIAS[fac] .. \" Supply\"]\n  end\n  if o == nil and BOARD_ART[fac] ~= nil then\n    for _, c in ipairs(getAllObjects()) do\n      -- markerImage returns NIL for anything with no custom object -- a die, a bag, a scripting zone,\n      -- and for a custom object carrying none of image/face/diffuse. `nil ~= \"\"` is TRUE, so the old\n      -- test fell straight through to img:find and crashed on the first such object on the table.\n      -- Only the Vagabond reaches this branch (it is the one entry in BOARD_ART), which is why it\n      -- showed up as an error the moment a Vagabond row was created.\n      local img = markerImage(c)\n      if img ~= nil and img ~= \"\" and img:find(BOARD_ART[fac], 1, true) then\n        o = c\n        break\n      end\n    end\n  end\n  if o == nil then\n    local pre = fac .. \" - \"\n    for _, c in ipairs(getAllObjects()) do\n      local n = c.getName() or \"\"\n      if n:sub(1, #pre) == pre or n:sub(1, #pre - 1) == (fac .. \" -\") then\n        o = c\n        break\n      end\n    end\n  end\n  return o\nend\n\n-- Assigned further down, once rttFieldMap exists. Declared HERE because refreshVariants is above it\n-- and a `local` referenced before its declaration compiles to a nil GLOBAL -- the \"local declared\n-- after use\" trap this file has shipped twice.\nlocal rttCharOf = nil\n\n-- Best effort: find the chosen vagabond character / captain card standing\n-- near the faction's supply. Fills the variant only while it is auto-managed;\n-- a hand-typed variant always wins.\nlocal function refreshVariants(byName)\n  local changed = false\n  for _, row in ipairs(S.rows) do\n    if row.variantAuto ~= false then\n      -- RTT knows exactly which character each seat is playing, so ask it before measuring anything.\n      -- Geometry cannot separate two vagabonds: they share one board ART, so facAnchor hands BOTH\n      -- rows the same object and the nearest-pawn search would give them the same character.\n      local told = rttCharOf ~= nil and rttCharOf(row.fac) or nil\n      if told ~= nil and told ~= \"\" and row.variant ~= told then\n        row.variant = told; changed = true\n      end\n      local bag = (told == nil or told == \"\") and facAnchor(row.fac, byName) or nil\n      if bag then\n        local bp = bag.getPosition()\n        local best, bestD = nil, 18 * 18\n        for _, ch in ipairs(CHARS) do\n          local o = byName[ch] or byName[\"Vagabond - \" .. ch]\n            or byName[\"Vagabond -\" .. ch]\n          if o then\n            local op = o.getPosition()\n            local dx, dz = op.x - bp.x, op.z - bp.z\n            local d = dx * dx + dz * dz\n            if d < bestD then best, bestD = ch, d end\n          end\n        end\n        if row.fac == \"Knaves\" then\n          local caps = {}\n          for _, ch in ipairs(CHARS) do\n            local o = byName[\"Captain - \" .. ch] or byName[\"Captain -\" .. ch]\n            if o then\n              local op = o.getPosition()\n              local dx, dz = op.x - bp.x, op.z - bp.z\n              if dx * dx + dz * dz < 18 * 18 then table.insert(caps, ch) end\n            end\n          end\n          best = (#caps > 0 and #caps <= 4) and table.concat(caps, \", \") or nil\n        end\n        if best and row.variant ~= best then\n          row.variant = best\n          changed = true\n        end\n      end\n    end\n  end\n  return changed\nend\n\n-- read the deck in play from the draw pile's card back; a manual chip click\n-- (uiRowBtn \"deck\") turns the automation off\nlocal function refreshDeck()\n  if S.deckAuto == false then return false end\n  -- several decks can sit on the table (draft leftovers, spares): trust the\n  -- one closest to the map, which is where the draw pile lives\n  local mapObj = TRACK and getObjectFromGUID(TRACK.guid) or nil\n  if mapObj == nil then return false end\n  local mp = mapObj.getPosition()\n  local best, bestD = nil, math.huge\n  for _, o in ipairs(getAllObjects()) do\n    if o.type == \"Deck\" then\n      local q = 0\n      pcall(function() q = o.getQuantity() end)\n      if q >= 15 then\n        local ok, data = pcall(function() return o.getData() end)\n        if ok and data and data.CustomDeck then\n          for _, cd in pairs(data.CustomDeck) do\n            local name = DECK_BACKS[urlTail(cd.BackURL)]\n            if name then\n              local op = o.getPosition()\n              local dx, dz = op.x - mp.x, op.z - mp.z\n              local d = dx * dx + dz * dz\n              if d < bestD then best, bestD = name, d end\n            end\n          end\n        end\n      end\n    end\n  end\n  if best and S.meta.deck ~= best then\n    S.meta.deck = best\n    return true\n  end\n  return false\nend\n\nlocal function seatedHands()\n  local hands = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated and p.color ~= \"Black\" and p.color ~= \"Grey\" then\n      local ok, ht = pcall(function() return p.getHandTransform() end)\n      if ok and ht then\n        table.insert(hands, { color = p.color, name = p.steam_name, pos = ht.position })\n      end\n    end\n  end\n  return hands\nend\n\n-- TTS's ten playable colors are stable even when nobody occupies them. Query\n-- each color directly: getHandTransform returns its hand-zone geometry without\n-- requiring a live Player entry. Some tables omit colors/hand zones, so every\n-- lookup is guarded. If this API yields nothing at all, retain the old live-seat\n-- behavior as a safe fallback.\nlocal PLAYER_COLORS = {\n  \"White\", \"Brown\", \"Red\", \"Orange\", \"Yellow\",\n  \"Green\", \"Teal\", \"Blue\", \"Purple\", \"Pink\",\n}\n\n-- ==== RTT'S SEAT RECORD ====================================================\n-- RTT keeps ONE record of who sits where, in what colour, playing what, and PUSHES it here whenever\n-- it changes -- seating, a faction placed, a colour change. It arrives as a JSON string (raw Lua\n-- tables do not cross object-script boundaries) and is kept in S, so onSave carries it through a\n-- reload and a crash.\n--\n-- This replaces re-reading three TTS Globals every six seconds. Globals are WIPED on load, so after a\n-- reload the sheet silently fell back to guessing each row's colour from the nearest hand zone --\n-- rows re-tinted to colours nobody occupies, and turns attributed to the wrong row. The pushed record\n-- survives, so there is nothing to fall back to.\n--\n-- The Globals are still read, but only as a fallback: an older RTT bake that does not push, or a\n-- plain Root table with no RTT at all, where the geometric pass is the only thing there is.\n-- Declared HERE, above its only writer and its only reader. `dirty` is a local several hundred lines\n-- below; assigning to it from up here would silently compile to a GLOBAL and never reach the poll --\n-- the same \"local declared after use\" trap that has already broken this file twice.\nlocal seatPushPending = false\n\n-- THE RECORD CARRIES A RUN NUMBER AND IT WAS NEVER READ. RTT bumps it on every new game, so it is\n-- exactly the signal for \"this is a different game now\" -- and without it a record restored from a\n-- save was indistinguishable from a live one, and rows kept the colours they were bound to in the\n-- game before. When the run changes, every AUTO-assigned row colour is dropped so the new record\n-- binds them from scratch; a colour a human set by hand is left alone.\nlocal function rttRunChanged(d)\n  local was = S.rttRun\n  local now_ = (type(d) == \"table\") and d.run or nil\n  if now_ == nil or was == nil or now_ == was then S.rttRun = now_ or was return false end\n  S.rttRun = now_\n  for _, row in ipairs(S.rows or {}) do\n    if row.colorAuto ~= false then row.color = nil end\n  end\n  logev(\"reseat\", \"run \" .. tostring(was) .. \" -> \" .. tostring(now_))\n  return true\nend\n\nfunction rttSeatPush(enc)\n  local ok, d = pcall(function() return JSON.decode(enc) end)\n  if not ok or type(d) ~= \"table\" or type(d.seats) ~= \"table\" then return end\n  rttRunChanged(d)\n  S.rttSeats = d\n  seatPushPending = true          -- picked up on the very next poll tick, not up to six seconds later\nend\n\n-- The record, from wherever it can be had: what was pushed to us first, then RTT's mirror Global.\nlocal function rttRecord()\n  if type(S.rttSeats) == \"table\" and type(S.rttSeats.seats) == \"table\"\n     and #S.rttSeats.seats > 0 then return S.rttSeats end\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_RECORD\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, d = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(d) == \"table\" and type(d.seats) == \"table\" and #d.seats > 0 then\n      S.rttSeats = d\n      return d\n    end\n  end\n  return nil\nend\n\n-- ROW NAME -> field, straight off the record.\n--\n-- Keyed by the seat's `key`, NOT its `faction`. They differ for exactly the case this whole section\n-- exists for: a vagabond seat's `faction` is the CHARACTER it is playing (\"Ranger\") while its `key`\n-- is the row the sheet shows (\"Vagabond\", or \"Vagabond 2\" for the second). Keying by faction here\n-- built a map nothing could look itself up in -- refreshSeats asks for rttCol[\"Vagabond\"] and would\n-- have found only rttCol[\"Ranger\"], so a vagabond row silently lost its colour, its owner and its\n-- position and fell back to the geometric guess. `faction` is still readable through this, which is\n-- how the character reaches the variant column.\n-- `row` FIRST, and it is RTT's answer to \"what does the sheet call this seat\". RTT publishes the row\n-- name outright now -- it owns the same short-name map this file kept a copy of -- so the entry is\n-- filed under BOTH names: the row name it will be looked up by, and the key, which older bakes and\n-- the Global mirrors still use. Filing both means a record from either side works, and the\n-- twelve-entry RTT_FACTION_ID bridge below stops being load-bearing.\nlocal function rttFieldMap(field)\n  local rec = rttRecord()\n  if rec == nil then return nil end\n  local m, any = {}, false\n  for _, e in ipairs(rec.seats) do\n    if type(e) == \"table\" and e[field] ~= nil and e[field] ~= \"\" then\n      local k = (e.key ~= nil and e.key ~= \"\") and e.key or e.faction\n      if k ~= nil and k ~= \"\" then m[k] = e[field]; any = true end\n      if type(e.row) == \"string\" and e.row ~= \"\" then m[e.row] = e[field]; any = true end\n    end\n  end\n  if not any then return nil end\n  return m\nend\n\n-- The character RTT recorded for a seat -- \"Thief\", \"Ranger\" -- looked up by the row's name. Only a\n-- vagabond (or the Knaves) has one; every other faction's `faction` field is its own name, which is\n-- not a character, so it is filtered against the known list.\nrttCharOf = function(fac)\n  local m = rttFieldMap(\"faction\")\n  if m == nil then return nil end\n  local v = m[fac]\n  if v == nil then return nil end\n  for _, c in ipairs(CHARS) do if c == v then return v end end\n  return nil\nend\n\n-- RTT publishes each faction's exact seat position (faction id -> {x,z}) via\n-- Global \"RTT_SEAT_POS\" as factions are placed. It stays a JSON string because\n-- raw Lua tables cannot cross object-script boundaries.\nlocal function rttSeatPosMap()\n  -- The pushed record first; the Global is only RTT's mirror of it, and mirrors are wiped on load.\n  local m = rttFieldMap(\"pos\")\n  if m ~= nil then return m end\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_POS\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- RTT also publishes each faction's real SEAT COLOUR (Global \"RTT_SEAT_COLOR\"), written only from its\n-- draft path where the colour is the seat's own. This is authoritative and beats the hand-zone guess\n-- below: Player[c].getHandTransform() returns a position for EVERY colour, seated or not, so the guess\n-- happily binds rows to colours nobody occupies.\nlocal function rttSeatColorMap()\n  -- The pushed record first; the Global is only RTT's mirror of it, and mirrors are wiped on load.\n  local m = rttFieldMap(\"color\")\n  if m ~= nil then return m end\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_COLOR\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- RTT also publishes WHO OWNS each faction (Global \"RTT_SEAT_PLAYER\", faction -> steam name),\n-- separately from the seat colour. The two are not the same thing: on RTT's manual 4-board path\n-- players keep the colour they joined with while the rows are coloured by SEAT, so matching a row's\n-- colour against seated players finds nobody and the row shows no name. This is authoritative for the\n-- NAME; the colour still drives the turn order.\nlocal function rttSeatPlayerMap()\n  -- The pushed record first; the Global is only RTT's mirror of it, and mirrors are wiped on load.\n  local m = rttFieldMap(\"owner\")\n  if m ~= nil then return m end\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_PLAYER\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- These color positions are only for associating a row with TTS's turn/player\n-- color. They are deliberately not an input to box-score row ordering.\nlocal function colorSeatPositions()\n  local positions, count = {}, 0\n  for _, color in ipairs(PLAYER_COLORS) do\n    local ok, ht = pcall(function() return Player[color].getHandTransform() end)\n    local pos = ok and ht and ht.position or nil\n    if pos ~= nil and pos.x ~= nil and pos.z ~= nil then\n      positions[color] = pos\n      count = count + 1\n    end\n  end\n  if count == 0 then\n    for _, h in ipairs(seatedHands()) do\n      if h.pos ~= nil and h.pos.x ~= nil and h.pos.z ~= nil then\n        positions[h.color] = h.pos\n        count = count + 1\n      end\n    end\n  end\n  return positions, count\nend\n\n-- Color -> faction: the faction's supply/board game piece remains in its player\n-- area after the VP marker moves to the score track. Match that physical anchor\n-- to the nearest color hand zone, greedily one-to-one. Live occupancy is used\n-- only to attach a Steam name; it never controls the row's color/seat.\n-- RTT uses full placement ids while box-score rows use the short VP-marker ids.\n-- Keep the direct row.fac lookup authoritative and bridge only those known names.\nlocal RTT_FACTION_ID = {\n  Marquise = \"Marquise de Cat\", Eyrie = \"Eyrie Dynasties\",\n  Alliance = \"Woodland Alliance\", Riverfolk = \"Riverfolk Company\",\n  Lizard = \"The Lizard Cult\", Duchy = \"Underground Duchy\",\n  Crows = \"Corvid Conspiracy\", Rats = \"Lord of the Hundreds\",\n  Badgers = \"Keepers in Iron\", Knaves = \"Knaves of the Deepwood\",\n  Council = \"Twilight Council\", Diaspora = \"Lilypad Diaspora\",\n}\n\n-- (moved above refreshSeats: it is a `local`, so any use EARLIER in the file resolves to a nil\n-- GLOBAL and throws 'attempt to index a nil value', killing the whole poll pass.)\nlocal function refreshSeats(byName)\n  local positions, seatCount = colorSeatPositions()\n  if seatCount == 0 then return false end\n  local liveNames = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated and p.color ~= \"Black\" and p.color ~= \"Grey\" then\n      liveNames[p.color] = p.steam_name\n    end\n  end\n  local cand, anchored = {}, {}\n  for _, row in ipairs(S.rows) do\n    local bag = facAnchor(row.fac, byName)\n    if bag then\n      anchored[row.fac] = true\n      local bp = bag.getPosition()\n      for ci, color in ipairs(PLAYER_COLORS) do\n        local pos = positions[color]\n        if pos ~= nil then\n          local dx, dz = pos.x - bp.x, pos.z - bp.z\n          table.insert(cand, { d = dx * dx + dz * dz, fac = row.fac,\n                               color = color, ci = ci })\n        end\n      end\n    end\n  end\n  table.sort(cand, function(x, y)\n    if math.abs(x.d - y.d) > 0.000001 then return x.d < y.d end\n    if x.fac ~= y.fac then return x.fac < y.fac end\n    return x.ci < y.ci\n  end)\n  local usedC, usedF, assigned, changed = {}, {}, {}, false\n  -- AUTHORITATIVE FIRST: any row RTT has named a seat colour for is bound directly, and both its colour\n  -- and its faction are marked used so the greedy geometric pass cannot reassign either.\n  local rttCol = rttSeatColorMap()\n  local rttOwner = rttSeatPlayerMap()\n  if rttCol ~= nil then\n    for _, row in ipairs(S.rows) do\n      local fid = RTT_FACTION_ID and RTT_FACTION_ID[row.fac] or nil\n      local c = rttCol[row.fac] or (fid ~= nil and rttCol[fid] or nil)\n      if c ~= nil and c ~= \"\" and not usedC[c] then\n        usedC[c], usedF[row.fac] = true, true\n        assigned[row.fac] = { fac = row.fac, color = c }\n      end\n    end\n  end\n  for _, c in ipairs(cand) do\n    if not usedC[c.color] and not usedF[c.fac] then\n      usedC[c.color], usedF[c.fac] = true, true\n      assigned[c.fac] = c\n    end\n  end\n  -- Clear a stale color only when this pass actually found the row's anchor but\n  -- could not assign it. If an anchor is temporarily absent, keep the last\n  -- known color instead of throwing away a valid physical-seat match.\n  for _, row in ipairs(S.rows) do\n    local c = assigned[row.fac]\n    if c then\n      -- colorAuto == false means a human set this row's colour deliberately; leave it alone, the same\n      -- way nameAuto / mapAuto / deckAuto / variantAuto protect every other hand-set field. Until this\n      -- existed, row.color was the ONE thing on the sheet that was rewritten every poll with no way to\n      -- correct it -- and it was the thing that was wrong.\n      if row.colorAuto ~= false and row.color ~= c.color then row.color = c.color; changed = true end\n      local name = liveNames[c.color]\n      local owned = rttOwner and (rttOwner[row.fac] or rttOwner[RTT_FACTION_ID[row.fac]])\n      if owned ~= nil and owned ~= \"\" then name = owned end   -- RTT knows who picked it\n      if name ~= nil and (row.player == \"\" or row.nameAuto) then\n        if row.player ~= name then row.player = name; changed = true end\n        row.nameAuto = true\n      end\n    elseif anchored[row.fac] and row.color ~= nil and row.colorAuto ~= false then\n      row.color = nil\n      changed = true\n    end\n  end\n  return changed\nend\n\nlocal function resort(cmp)\n  local activeRow = S.rows[S.active]\n  table.sort(S.rows, cmp)\n  for i, r in ipairs(S.rows) do\n    if r == activeRow then S.active = i end\n  end\nend\n\n-- The turn system can only drive the sheet when every faction row belongs to\n-- a seated color. Solo and hotseat games (one player running several\n-- factions) fall back to the manual END TURN button.\nlocal function fullTurnCoverage()\n  -- ONE rule, identical at every player count: if the TTS turn system is running\n  -- and the sheet has rows, the turn system drives the sheet. Otherwise the\n  -- manual END TURN button does.\n  --\n  -- This used to additionally require >= 2 seated players AND every row's colour\n  -- to be seated right now. Both made the behaviour depend on WHO happened to be\n  -- sitting down: a solo game (and any hotseat game where one player runs several\n  -- factions) silently fell back to manual mode, so the turn system could not be\n  -- tested or used at all, and a single disconnect mid-game flipped a running\n  -- table into a different mode. The maintainer asked for the same logic to work\n  -- the same way regardless of player count, so those two conditions are gone.\n  --\n  -- Nothing downstream needs them: followTurns() looks the turn colour up with\n  -- rowByColor and simply does nothing when there is no such row, and\n  -- onPlayerTurn still refuses to lock unless the PREVIOUS colour was really\n  -- seated -- so toggling the turn system, or TTS stepping through empty\n  -- colours, still records nothing.\n  return turnsRunning() and #S.rows > 0\nend\n\n\n-- Object-name index of each faction's supply anchor, refreshed by the poll (see ~line 1434) just\n-- before seatOrder. Declared HERE, ABOVE factionSeatPosition, so the function captures this upvalue\n-- rather than a nil GLOBAL -- otherwise the physical-anchor fallback threw 'index a nil value' on any\n-- non-RTT / Vagabond row and aborted the whole poll pass (audit: seat-box).\nlocal seatAnchorByName = {}\nlocal function factionSeatPosition(row, rtt)\n  local p = nil\n  if rtt ~= nil then p = rtt[row.fac] or rtt[RTT_FACTION_ID[row.fac]] end\n  if p ~= nil then\n    local x, z = (p[1] or p.x), (p[2] or p.z)\n    if x ~= nil and z ~= nil then return { x = x, z = z } end\n  end\n  local anchor = facAnchor(row.fac, seatAnchorByName)\n  if anchor == nil then return nil end\n  local ok, pos = pcall(function() return anchor.getPosition() end)\n  if ok and pos ~= nil and pos.x ~= nil and pos.z ~= nil then return pos end\n  return nil\nend\n\n-- (seatAnchorByName is declared above factionSeatPosition; the poll assigns it before seatOrder.)\n\n-- Row order is always physical faction-seat order, even while RTT's TTS turn\n-- system is running. The faction-keyed RTT map wins; a missing entry falls back\n-- to that row's physical faction anchor. Unknown rows stay last. Original\n-- indices make every pass stable, and the manual up-arrow disables this sorter.\nlocal function seatOrder()\n  if S.manualOrder then return false end\n  local rtt = rttSeatPosMap()\n  local before, original = {}, {}\n  local positions, seatCount = {}, 0\n  for i, r in ipairs(S.rows) do\n    before[i], original[r] = r, i\n    positions[r] = factionSeatPosition(r, rtt)\n    if positions[r] ~= nil then seatCount = seatCount + 1 end\n  end\n  if seatCount == 0 then return false end\n  resort(function(x, y)\n    local px, py = positions[x], positions[y]\n    if px == nil or py == nil then\n      if px ~= nil then return true end\n      if py ~= nil then return false end\n      return original[x] < original[y]\n    end\n    -- clockwise from directly-right (+X): seat 1 is first, proceeding to the left\n    local ax = math.atan2(-px.z, px.x); if ax < 0 then ax = ax + 2 * math.pi end\n    local ay = math.atan2(-py.z, py.x); if ay < 0 then ay = ay + 2 * math.pi end\n    if math.abs(ax - ay) > 0.000001 then return ax < ay end\n    return original[x] < original[y]\n  end)\n  for i, r in ipairs(S.rows) do\n    if before[i] ~= r then return true end\n  end\n  return false\nend\n\n-- Turns controls only the live pointer and automatic locks. It deliberately\n-- does not control row order; physical seat geometry above is authoritative.\nlocal function followTurns()\n  if not fullTurnCoverage() then return false end\n  local tc = Turns.turn_color\n  -- The FIRST turn of the game is ALWAYS the first player. Until a turn has\n  -- actually been recorded (S.turns == 0), pin the pointer to Turns.order[1]\n  -- - the first player - regardless of how late that faction's row joined the\n  -- sheet or whether turn_color was momentarily empty or nudged during setup.\n  -- Once real turns start recording, follow the live turn_color normally, so\n  -- every later round's first turn lands on the first player by itself too.\n  -- ...BUT ONLY WHERE THE COLOURS ARE KNOWN, NOT GUESSED. Resolving Turns.order[1] through\n  -- rowByColor is the same construct that put the opening pointer on seat 2: row.color comes from a\n  -- nearest-hand-zone match when RTT has published nothing, so \"Red\" bound itself to whichever\n  -- faction happened to sit closest and the pin landed on that row. pinFirstSeat had this taken out\n  -- for exactly that reason -- \"geometry is authoritative here; colour is not\" -- and the same\n  -- exposure was left here.\n  -- With a record in hand the colours ARE authoritative, so the colour is the right way to find the\n  -- first player. Without one, row order is physical seat order and row 1 is the first seat.\n  if (S.turns or 0) == 0 then\n    if rttRecord() == nil then\n      if S.active ~= 1 then S.active = 1 return true end\n      return false\n    end\n    local first = Turns.order and Turns.order[1] or nil\n    if first and first ~= \"\" then tc = first end\n  end\n  if tc and tc ~= \"\" then\n    local i = rowByColor(tc)\n    if i and i ~= S.active then S.active = i; return true end\n  end\n  return false\nend\n\n-- The FIRST turn of a game belongs to the FIRST SEAT. followTurns() already\n-- says so, but its pin sits behind fullTurnCoverage() -> Turns.enable, and RTT\n-- ships the TTS turn system off, so that path never runs there. This is the\n-- manual-mode equivalent and it runs on every poll while the latch is set,\n-- which also means it self-corrects as rows appear: resort() re-pins S.active\n-- onto whichever row object it was on, and rows are appended in the order the\n-- VP markers become readable, so without this the pointer settles on the\n-- first faction DISCOVERED rather than seat 1.\n-- Target: ROW 1, and deliberately NOT a colour lookup.\n-- seatOrder() sorts rows clockwise from +X (angle = atan2(-z, x)), and RTT's\n-- seat slots are RTT_POS = {(52,-46),(-52,-46),(52,46),(-52,46)} -> angles\n-- 0.724 / 2.417 / 5.559 / 3.866, so the row order is seat 1, 2, 4, 3 and row 1\n-- is ALWAYS seat 1.\n-- An earlier version of this preferred rowByColor(Turns.order[1]) (\"Red\" =\n-- RTT's seat-1 colour) and fell back to row 1. That was WRONG and shipped a\n-- regression: row.color is assigned by refreshSeats() from the NEAREST HAND\n-- ZONE, not from RTT's seating, and rttSeatPlayers only recolours SEATED\n-- humans. With empty seats (a solo tester, or fewer humans than seats) \"Red\"\n-- binds to an arbitrary faction -- in the maintainer's 4-faction solo test the\n-- rows came out Marquise=White, Riverfolk=Red, Alliance=Orange, Duchy=Pink, so\n-- the pin jumped to Riverfolk (row 2, seat 2) instead of Marquise (row 1,\n-- seat 1). Geometry is authoritative here; colour is not.\nlocal function pinFirstSeat()\n  if not S.pinFirst or #S.rows == 0 then return false end\n  -- MANUAL MODE ONLY. When the TTS turn system is actually driving the sheet,\n  -- followTurns() owns the pointer and has its own first-player pin, and it runs\n  -- immediately before this in the poll -- so without this guard we overwrote it\n  -- every tick and the sheet stopped following turn order altogether (and\n  -- onPlayerTurn's immediate S.active was clobbered 1.2s later too). Regression\n  -- reported by the maintainer; this is the fix.\n  if fullTurnCoverage() then return false end\n  if S.active ~= 1 then S.active = 1; return true end\n  return false\nend\n\n--------------------------------------------------------------------- export --\nlocal function unpickedList()\n  local out = {}\n  for _, fac in ipairs(ROSTER) do\n    if S.unpicked[fac] == true then\n      local v = S.unpickedVar and S.unpickedVar[fac] or \"\"\n      table.insert(out, v ~= \"\" and (fac .. \" (\" .. v .. \")\") or fac)\n    end\n  end\n  return out\nend\n\n-- The tournament site's schema (root_boxscore/EXPORT_FIELDS.md). Every field in the developer's\n-- example is emitted, so the shape is always the same: the ones this object cannot know come out as\n-- null rather than being dropped, because a missing key and an unknown value are not the same thing\n-- to whoever ingests this.\nlocal FACTION_SLUG = {\n  Marquise = \"marquise-de-cat\",   Eyrie    = \"eyrie-dynasties\",  Alliance = \"woodland-alliance\",\n  Vagabond = \"vagabond\",          Riverfolk= \"riverfolk-company\", Lizard  = \"lizard-cult\",\n  Duchy    = \"underground-duchy\", Crows    = \"corvid-conspiracy\", Rats    = \"lord-of-the-hundreds\",\n  Badgers  = \"keepers-in-iron\",   Knaves   = \"knaves-of-the-deepwood\",\n  Council  = \"twilight-council\",  Diaspora = \"lilypad-diaspora\",\n}\n\n-- JSON.encode drops a nil and writes {} for an empty table, so null and [] need placeholders that\n-- are swapped back once the string exists.\nlocal JNULL, JLIST = \"@@null@@\", \"@@list@@\"\n\nlocal function slug(v)\n  v = tostring(v or \"\"):lower()\n  v = v:gsub(\"&\", \" \"):gsub(\"%f[%w]and%f[%W]\", \" \")   -- \"Squires and Disciples\" -> squires-disciples\n  v = v:gsub(\"[^%w]+\", \"-\"):gsub(\"^%-+\", \"\"):gsub(\"%-+$\", \"\")\n  return v\nend\n\n-- \\uXXXX-escape anything outside ASCII so the payload survives being pasted through Discord, a web\n-- form or a terminal. Still the same JSON: the observed export carried a raw U+2122 in a player name.\nfunction asciiOnly(str)\n  local out, i, n = {}, 1, #str\n  while i <= n do\n    local b = str:byte(i)\n    if b < 128 then out[#out + 1] = str:sub(i, i); i = i + 1\n    else\n      local len, cp\n      if     b >= 240 then len, cp = 4, b - 240\n      elseif b >= 224 then len, cp = 3, b - 224\n      elseif b >= 192 then len, cp = 2, b - 192\n      else                 len, cp = 1, b end\n      for k = 1, len - 1 do cp = cp * 64 + ((str:byte(i + k) or 0) % 64) end\n      if cp < 0x10000 then\n        out[#out + 1] = string.format(\"\\\\u%04X\", cp)\n      else\n        cp = cp - 0x10000\n        out[#out + 1] = string.format(\"\\\\u%04X\\\\u%04X\",\n          0xD800 + math.floor(cp / 0x400), 0xDC00 + (cp % 0x400))\n      end\n      i = i + len\n    end\n  end\n  return table.concat(out)\nend\n\n-- A display name is a poor key: people rename themselves and it will not match a Discord handle.\n-- The Steam id is stable and unique, so the site can map it to an account once. Only available while\n-- that colour is actually seated, same as the name.\nlocal function steamIdFor(color)\n  if color == nil or color == \"\" then return nil end\n  local id = nil\n  pcall(function()\n    for _, pl in ipairs(Player.getPlayers()) do\n      if pl.seated and pl.color == color and pl.steam_id ~= nil then id = tostring(pl.steam_id) end\n    end\n  end)\n  if id == \"\" then return nil end\n  return id\nend\n\nfunction tournamentPayload()\n  local p = {\n    board_map          = S.meta.map  ~= \"\" and slug(S.meta.map)  or JNULL,\n    deck               = S.meta.deck ~= \"\" and slug(S.meta.deck) or JNULL,\n    undrafted_faction  = JNULL,\n    undrafted_vagabond = JNULL,\n    undrafted_captains = JLIST,\n    participants       = {},\n  }\n  for _, fac in ipairs(ROSTER) do\n    if S.unpicked[fac] == true then\n      p.undrafted_faction = FACTION_SLUG[baseFac(fac)] or slug(baseFac(fac))\n      local v = S.unpickedVar and S.unpickedVar[fac] or \"\"\n      if v ~= \"\" and (baseFac(fac) == \"Vagabond\" or baseFac(fac) == \"Knaves\") then p.undrafted_vagabond = slug(v) end\n      break\n    end\n  end\n  -- The site reads tournament_score as the result: 1 or 0.5 is a win, 0 a loss. The object knows the\n  -- winner both ways a game of Root ends -- S.winner is set when a marker reaches 30 (S.winnerReason\n  -- \"score\") and by the DOM WIN button (\"dominance\"). While no winner is recorded the game is\n  -- unfinished and every score stays null, rather than claiming a table of losses.\n  --\n  -- A coalition makes the win SHARED: a vagabond allied to the winner wins with them, so both take\n  -- 0.5 rather than the winner taking 1 alone.\n  local shared = false\n  for _, row in ipairs(S.rows) do\n    if S.winner ~= nil and row.coalition == S.winner then shared = true end\n  end\n  for i, row in ipairs(S.rows) do\n    local won = JNULL\n    if S.winner ~= nil then\n      local isWinner = (row.fac == S.winner) or (row.coalition ~= nil and row.coalition == S.winner)\n      won = isWinner and (shared and 0.5 or 1) or 0\n    end\n    local e = {\n      player            = (row.player ~= nil and row.player ~= \"\") and row.player or JNULL,\n      player_steam_id   = steamIdFor(row.color) or JNULL,\n      coalition         = (row.coalition ~= nil) and (FACTION_SLUG[row.coalition] or slug(row.coalition)) or JNULL,\n      -- baseFac: two vagabonds are two ROWS but ONE faction. The export must say \"vagabond\" for\n      -- both -- the character and the player name are what distinguish them.\n      faction           = FACTION_SLUG[baseFac(row.fac)] or slug(baseFac(row.fac)),\n      dominance         = JNULL,\n      vagabond          = JNULL,\n      captains          = JLIST,              -- not tracked\n      discarded_captain = JNULL,              -- not tracked\n      starting_leader   = JNULL,\n      brazen_demagogue  = false,\n      tournament_score  = won,                -- 1 winner, 0 loser, null while the game is unfinished\n      -- WHERE THEY SAT IN THE TURN ORDER, not where their row happens to be printed. Row order is\n      -- physical seat order and the turn order is what Turns.order says; the two agree only because\n      -- both are derived clockwise today, and nothing keeps them in step. Recorded as a defect once\n      -- already -- \"on the manual setup path it records where a player sat, not the order they\n      -- played\" -- ticked done, and the line never changed. Falls back to the row index when the turn\n      -- system is not running, which is the manual END TURN mode where row order IS the play order.\n      turn_order        = turnSlot(row) or i,\n      turns             = {},\n    }\n    if row.variant ~= nil and row.variant ~= \"\" then\n      if row.fac == \"Eyrie\" then e.starting_leader = row.variant\n      elseif baseFac(row.fac) == \"Vagabond\" or baseFac(row.fac) == \"Knaves\" then e.vagabond = slug(row.variant) end\n    end\n    if row.dom ~= nil then\n      if row.dom.suit ~= nil then\n        e.dominance = row.dom.suit:sub(1, 1):upper() .. row.dom.suit:sub(2)\n      end\n      e.brazen_demagogue = (row.dom.kind == \"brazen_demagogue\")\n    end\n    for r, sc in ipairs(row.locks or {}) do\n      if type(sc) == \"number\" and sc >= 0 then\n        local t = { turn = r, score = sc }\n        if row.dom ~= nil and row.dom.round ~= nil and r >= row.dom.round then t.dominance = true end\n        table.insert(e.turns, t)\n      end\n    end\n    if #e.turns == 0 then e.turns = JLIST end\n    table.insert(p.participants, e)\n  end\n  if #p.participants == 0 then p.participants = JLIST end\n  return p\nend\n\n-- The one JSON this object produces.\nfunction exportJson()\n  local text = \"\"\n  pcall(function()\n    text = asciiOnly(JSON.encode(tournamentPayload()))\n      :gsub('\"' .. JNULL .. '\"', \"null\")\n      :gsub('\"' .. JLIST .. '\"', \"[]\")\n  end)\n  return text\nend\n\n-- Post straight to a Discord webhook - no companion program needed. The URL\n-- is pasted once into EDIT's DISCORD field (or baked into GMNotes) and\n-- then travels with the object inside every save.\nlocal function postDiscord(chunks)\n  local hook = S.meta.hook or \"\"\n  if hook == \"\" or #chunks == 0 then return false end\n  local thread = (S.meta.thread or \"\"):match(\"(%d%d%d%d%d%d+)%s*$\")\n  hook = hook .. (hook:find(\"%?\") and \"&\" or \"?\") .. \"wait=true\"\n  if thread then hook = hook .. \"&thread_id=\" .. thread end\n  local idx = 0\n  local function sendNext()\n    idx = idx + 1\n    local text = chunks[idx]\n    if text == nil then\n      S.lastExport = os.date(\"%H:%M\") .. \" &#183; confirmed with Discord\"\n        .. (#chunks > 1 and (\" (\" .. #chunks .. \" msgs)\") or \"\")\n      rebuildUI()\n      return\n    end\n    local body = JSON.encode({ content = text })\n    local function report(req)\n      if req and (req.is_error or (req.response_code or 0) >= 300) then\n        S.lastExport = os.date(\"%H:%M\") .. \" &#183; Discord failed (msg \" .. idx .. \")\"\n        dbg(\"BoxScore discord error: \" .. tostring(req.error) .. \" code=\"\n          .. tostring(req.response_code) .. \" body=\" .. tostring(req.text):sub(1, 200))\n        rebuildUI()\n      else\n        sendNext()\n      end\n    end\n    local ok = pcall(function()\n      WebRequest.custom(hook, \"POST\", false, body,\n        { [\"Content-Type\"] = \"application/json\" }, report)\n    end)\n    if not ok then\n      pcall(function() WebRequest.post(hook, { content = text }, report) end)\n    end\n  end\n  sendNext()\n  return true\nend\n\n-- split lines into fenced messages under Discord's 2000-char limit\n-- The same 1800-char split as fencedChunks, but for one long unbroken string, tagged ```json so\n-- Discord highlights it and a bot can find it.\nlocal function jsonChunks(text)\n  local out, i, n = {}, 1, #text\n  while i <= n do\n    out[#out + 1] = \"```json\\n\" .. text:sub(i, i + 1749) .. \"\\n```\"\n    i = i + 1750\n  end\n  return out\nend\n\nlocal function fencedChunks(lines)\n  local chunks, cur, len = {}, {}, 0\n  for _, l in ipairs(lines) do\n    if len + #l + 10 > 1800 and #cur > 0 then\n      table.insert(chunks, \"```\\n\" .. table.concat(cur, \"\\n\") .. \"\\n```\")\n      cur, len = {}, 0\n    end\n    table.insert(cur, l)\n    len = len + #l + 1\n  end\n  if #cur > 0 then\n    table.insert(chunks, \"```\\n\" .. table.concat(cur, \"\\n\") .. \"\\n```\")\n  end\n  return chunks\nend\n\n--------------------------------------------------- experimental: crafting --\n-- Watch the craftable-item supply on the map (the edge opposite the score\n-- track). An item leaving the map = a craft: attributed to whoever carried\n-- it (or the active faction), with the VP taken from that faction's next\n-- score change within 30 seconds.\n-- craftable-item artwork -> item name (the tokens are unnamed in this mod)\nlocal ITEMS = {\n  [\"4C4E490133888321E24E3F77DC20E1A4A7369B6E\"] = \"Coins\",\n  [\"FF9D60BC2A7E6A38BE74773188B30F57C14E9FB5\"] = \"Tea\",\n  [\"366FF0B1EDD8B091B881287CF72CFBAA584B742B\"] = \"Sword\",\n  [\"0BEAA5BC0CC9AA3ADB7BEB4A59C124603DA73CD7\"] = \"Hammer\",\n  [\"639F7EE379C0EBF83B49BF9BE165BBD7345E7F5C\"] = \"Crossbow\",\n  [\"81AC7B7422C963CCFB711E0134FF957117DC1528\"] = \"Boot\",\n  [\"459F031CFC2B05BFD5597460610B20DD58D14843\"] = \"Bag\",\n}\nlocal ITEM_NAMES = { \"Coins\", \"Tea\", \"Sword\", \"Hammer\", \"Crossbow\", \"Boot\", \"Bag\" }\nlocal function itemTail(u)\n  if u == nil then return \"\" end\n  return (u:gsub(\"[^A-Za-z0-9]\", \"\")):sub(-40)\nend\n\nlocal ITEMWATCH = nil     -- guid -> { name, holder, img }\nlocal INFLIGHT = {}       -- guid -> { name, img, holder, tLeft }\nlocal SUPPLYPOS = {}      -- fac -> world position of its supply bag\nlocal CATCHUP = false     -- one adopt-existing-crafts sweep after (re)arming\n\nlocal function initItemWatch()\n  ITEMWATCH = {}\n  if TRACK == nil then return end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then return end\n  local trackB = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local count = 0\n  for _, o in ipairs(getAllObjects()) do\n    if o ~= self and o.getGUID() ~= TRACK.guid then\n      local n = o.getName() or \"\"\n      -- the item tokens are UNNAMED small tiles; named map furniture (VP\n      -- markers, ruins, landmarks) is excluded, everything else small in the\n      -- supply region is an item\n      local excluded = n:match(\" VP$\") or n:match(\"Supply$\") or n:match(\"Board$\")\n        or n == \"RUIN\" or o.type == \"Deck\" or o.type == \"Card\"\n      local sc = o.getScale()\n      if not excluded and sc.x < 1.0 then\n        local ok, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n        if ok and lp and math.abs(lp.x) < 1.95 and math.abs(lp.z) < 1.95 then\n          local b = (TRACK.axis == \"x\") and lp.z or lp.x\n          if b * trackB < 0 and math.abs(b) > 0.85 then\n            local img = markerImage(o)\n            local nm = ITEMS[itemTail(img)] or ((n ~= \"\") and n or \"Item\")\n            if ITEMS[itemTail(img)] and img ~= \"\" then S.itemImgs[nm] = img end\n            ITEMWATCH[o.getGUID()] = { name = nm, holder = nil, img = img }\n            count = count + 1\n          end\n        end\n      end\n    end\n  end\n  dbg(\"BoxScore experimental: watching \" .. count .. \" supply items\")\nend\n\n-- the item's crafting VP: the faction's first score increase since the item\n-- left the supply (the marker usually moves at craft time even when the item\n-- is moved to the board later)\nlocal function inferCraftVP(fac, tLeft)\n  for k = #S.log, 1, -1 do\n    local e = S.log[k]\n    if e.t ~= nil and e.t < tLeft then break end\n    if e.ev == \"score\" and e.fac == fac and type(e.a) == \"number\"\n      and type(e.b) == \"number\" and e.b > e.a and e.a >= 0 then\n      return e.b - e.a\n    end\n  end\n  return 0\nend\n\nlocal function inferRound(fac, t, activeFac)\n  local n = 0\n  for _, e in ipairs(S.log) do\n    if e.ev == \"lock\" and e.fac == fac and (e.t or 0) <= t then n = n + 1 end\n  end\n  if activeFac ~= nil and activeFac ~= fac then\n    -- the item moved while another faction was playing: it belongs to the\n    -- crafting faction's last noted turn, not their upcoming one\n    return math.max(1, n)\n  end\n  return n + 1\nend\n\n-- is this object back in the map's item-supply region?\nlocal function inSupplyRegion(mapObj, o)\n  if TRACK == nil then return false end\n  local ok, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n  if not (ok and lp) then return false end\n  if math.abs(lp.x) >= 1.95 or math.abs(lp.z) >= 1.95 then return false end\n  local trackB = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local b = (TRACK.axis == \"x\") and lp.z or lp.x\n  return b * trackB < 0 and math.abs(b) > 0.85\nend\n\nlocal function attributeCraft(i, entry, guid)\n  local row = S.rows[i]\n  if row == nil then return end\n  row.crafts = row.crafts or {}\n  table.insert(row.crafts, { item = entry.name, img = entry.img, guid = guid,\n    vp = inferCraftVP(row.fac, entry.tLeft),\n    r = inferRound(row.fac, entry.tLeft, entry.activeFac) })\n  if entry.img and entry.img ~= \"\" then S.itemImgs[entry.name] = entry.img end\n  logev(\"craft\", row.fac, entry.name)\n  refreshAssets()\nend\n\n-- items already sitting beside a faction board when the watch (re)starts are\n-- adopted as crafts, so late activation or missed flights still count\nlocal function catchUpCrafts(mapObj)\n  local counted = {}\n  for _, row in ipairs(S.rows) do\n    for _, c in ipairs(row.crafts or {}) do\n      if c.guid then counted[c.guid] = true end\n    end\n  end\n  for _, o in ipairs(getAllObjects()) do\n    local guid = o.getGUID()\n    if not counted[guid] and ITEMWATCH[guid] == nil and o.type == \"Tile\" then\n      local img = markerImage(o)\n      local nm = ITEMS[itemTail(img)]\n      if nm then\n        local okl, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n        local offMap = not (okl and lp and math.abs(lp.x) < 2.0 and math.abs(lp.z) < 2.0)\n        if offMap then\n          local op = o.getPosition()\n          local bestFac, bestD = nil, 30 * 30\n          for fac, sp2 in pairs(SUPPLYPOS) do\n            local dx, dz = op.x - sp2.x, op.z - sp2.z\n            local d = dx * dx + dz * dz\n            if d < bestD then bestFac, bestD = fac, d end\n          end\n          local i2 = bestFac and rowByFac(bestFac) or nil\n          if i2 then\n            attributeCraft(i2, { name = nm, img = img, tLeft = now(),\n              activeFac = S.rows[S.active] and S.rows[S.active].fac or nil }, guid)\n          end\n        end\n      end\n    end\n  end\nend\n\nfunction uiCraftMenu()\n  S.overlay = (S.overlay == \"craft\") and nil or \"craft\"\n  S.craftAdd = nil\n  S.craftPick = nil\n  rebuildUI()\nend\n\nfunction uiCraftBtn(player, _, id)\n  local i, k = id:match(\"^cfr_(%d+)_(%d+)$\")\n  if i then\n    -- clicking a craft's T# opens the round row below; clicking again closes\n    if S.craftPick ~= nil and S.craftPick.i == tonumber(i)\n      and S.craftPick.k == tonumber(k) then\n      S.craftPick = nil\n    else\n      S.craftPick = { i = tonumber(i), k = tonumber(k) }\n      S.craftAdd = nil\n    end\n    rebuildUI()\n    return\n  end\n  local pr = id:match(\"^cfpick_(%d+)$\")\n  if pr then\n    if S.craftPick ~= nil then\n      local row = S.rows[S.craftPick.i]\n      local c = row and (row.crafts or {})[S.craftPick.k] or nil\n      if c then c.r = tonumber(pr) end\n      S.craftPick = nil\n    end\n    rebuildUI()\n    return\n  end\n  i, k = id:match(\"^cfx_(%d+)_(%d+)$\")\n  if i then\n    local row = S.rows[tonumber(i)]\n    if row and row.crafts then\n      table.remove(row.crafts, tonumber(k))\n      refreshAssets()\n    end\n    rebuildUI()\n    return\n  end\n  i = id:match(\"^cfadd_(%d+)$\")\n  if i then\n    S.craftAdd = (S.craftAdd == tonumber(i)) and nil or tonumber(i)\n    S.craftPick = nil\n    rebuildUI()\n    return\n  end\n  k = id:match(\"^cfnew_(%d+)$\")\n  if k then\n    local row = S.rows[S.craftAdd or 0]\n    local nm = ITEM_NAMES[tonumber(k)]\n    if row and nm then\n      row.crafts = row.crafts or {}\n      table.insert(row.crafts, { item = nm, img = S.itemImgs[nm] or \"\",\n        vp = 0, r = roundForRow(row) })\n      logev(\"craft\", row.fac, nm)\n      S.craftAdd = nil\n      refreshAssets()\n    end\n    rebuildUI()\n  end\nend\n\nfunction uiExperimental()\n  S.experimental = not S.experimental\n  ITEMWATCH = nil\n  INFLIGHT = {}\n  if S.overlay == \"craft\" then S.overlay = nil end\n  rebuildUI()\nend\n\n------------------------------------------------------------------- the poll --\nlocal dirty = false\n\n-- forward declaration, so anything above lockRow's definition can call it\nlocal lockRow\n\nlocal function poll()\n  pollCount = pollCount + 1\n  -- Track detection does no steady-state work. The every-poll scan runs\n  -- only until the first map is found; afterwards the sole periodic cost\n  -- is one object lookup every 25th poll, and a full re-detection happens\n  -- only when the mapped object has actually been deleted (a map swap).\n  -- A stale map NAME is acceptable - the MAP chip in EDIT corrects it.\n  if TRACK ~= nil and pollCount % 25 == 0\n    and getObjectFromGUID(TRACK.guid) == nil then\n    TRACK = nil\n  end\n  if TRACK == nil then\n    findTrack()\n    if TRACK ~= nil then dirty = true end\n  end\n  if TRACK == nil then return end\n\n  local objects = getAllObjects()\n  local domCards = {}\n  local vpMarkers = {}\n  for _, o in ipairs(objects) do\n    local n = o.getName() or \"\"\n    local fac = n:match(\"^(.+) VP$\")\n    if fac then\n      vpMarkers[fac] = vpMarkers[fac] or {}\n      table.insert(vpMarkers[fac], o)\n      if rowByFac(fac) == nil and readCell(o) ~= nil then\n        addRow(fac, o)\n        refreshAssets()\n        dirty = true\n      end\n    end\n    local suit = dominanceCardSuit(o)\n    if suit then table.insert(domCards, { obj = o, suit = suit }) end\n  end\n\n  -- PRUNE rows whose VP marker no longer exists. The sheet's memory must FOLLOW THE TABLE: rows were\n  -- only ever added, never removed, and S is persisted whole (onSave encodes S, onLoad replaces it), so\n  -- loading an old save re-imported every faction it had ever seen and a reset left the sheet still\n  -- believing in markers that were gone -- which is also why VP positions came out in odd slots. The\n  -- maintainer: \"the only memory of which factions are present should be the vp score markers on the\n  -- board\". A row with no guid was added by hand in EDIT mode and is never pruned; a held or moving\n  -- marker still resolves, so only a genuinely destroyed one prunes.\n  -- A faction leaves the table in more ways than \"its marker was destroyed\". It can be dropped into a\n  -- bag, or removed while a spare copy of the same marker still sits somewhere -- and findMarker\n  -- re-points row.guid at that spare, so the guid keeps resolving and the row never left. Prune on\n  -- whether the FACTION is still present at all: no marker by name, and no supply/board anchor.\n  -- Two consecutive polls are required so a marker in hand or mid-throw never drops a row.\n  local present, presentObj = {}, {}\n  for _, o in ipairs(getAllObjects()) do\n    local n = o.getName() or \"\"\n    if n ~= \"\" then present[n] = true; if presentObj[n] == nil then presentObj[n] = o end end\n  end\n  for i = #S.rows, 1, -1 do\n    local r = S.rows[i]\n    -- RTT_VP_SHORT lives in RTT's own script, never in this object's scope, so this was always the\n    -- plain row name. Saying so rather than reading a global that cannot exist here.\n    local vpName   = r.fac .. \" VP\"\n    local anchor   = facAnchor(r.fac, presentObj)   -- byName is not in scope this early; build our own\n    local factionGone = (not present[vpName]) and anchor == nil\n    if factionGone then r.gone = (r.gone or 0) + 1 else r.gone = 0 end\n    -- THE CACHED GUID GOING AWAY IS NOT A REASON TO PRUNE. It used to be its own trigger --\n    --     if guidGone or (r.guid ~= nil and r.guid ~= \"\" and r.gone >= 2)\n    -- -- and it short-circuited BOTH protections above: the faction-presence test and the two-poll\n    -- grace that exists so \"a marker in hand or mid-throw never drops a row\". Dropping a VP marker\n    -- into a bag DESTROYS the object in TTS, so its guid stops resolving instantly, and the row --\n    -- with every round it had recorded -- was gone on the very next poll while the faction's supply\n    -- was still sitting on the table. It came back empty when the marker did. Prune on the faction\n    -- being ABSENT, which is what the comment above always said, and let findMarker re-point a stale\n    -- guid at the marker when it reappears.\n    if r.guid ~= nil and r.guid ~= \"\" and r.gone >= 2 then\n      logev(\"leave\", r.fac)\n      table.remove(S.rows, i)\n      if S.active > #S.rows then S.active = math.max(1, #S.rows) end\n      dirty = true\n    end\n  end\n\n  for _, row in ipairs(S.rows) do\n    -- Count all same-faction copies. The declaration follows its specific\n    -- settled card marker; held/moving markers cause no transient change.\n    local markerState, domChanged = syncDominance(row, domCards,\n      vpMarkers[row.fac] or {})\n    if domChanged then dirty = true end\n    -- Standard dominance freezes. Brazen keeps reading the separate settled\n    -- marker on the VP track and locks ordinary numeric scores.\n    local idx = (not dominanceFrozen(row)) and markerState.trackIdx or nil\n    if idx ~= nil then\n      local sc = cellToScore(idx)\n      if sc ~= row.score then\n        logev(\"score\", row.fac, row.score, sc)\n        row.score = sc\n        dirty = true\n      end\n      -- Reaching 30 ends the game: the 30 is printed into the CURRENT\n      -- round column and the world stops - the turn does NOT pass, the\n      -- pointer does not move, nothing locks any more. Moving that marker\n      -- off 30 to a lower score means it was a mistake: the cell returns\n      -- to exactly what it held before and play resumes.\n      if S.winner == nil and sc >= 30 then\n        local r = roundForRow(row)\n        S.winnerLock = { fac = row.fac, r = r,\n          prevLock = row.locks[r], prevEdit = row.edits[tostring(r)] }\n        row.edits[tostring(r)] = nil\n        while #row.locks < r - 1 do table.insert(row.locks, -1) end\n        row.locks[r] = sc\n        S.winner = row.fac\n        S.winnerReason = \"score\"\n        logev(\"gameover\", row.fac, r, sc)\n        dirty = true\n      elseif S.winner == row.fac and S.winnerLock ~= nil and sc < 30 then\n        local wl = S.winnerLock\n        if wl ~= nil and wl.fac == row.fac then\n          if wl.prevLock ~= nil then\n            row.locks[wl.r] = wl.prevLock\n          else\n            row.locks[wl.r] = -1\n            while #row.locks > 0\n              and (row.locks[#row.locks] == -1 or row.locks[#row.locks] == nil) do\n              table.remove(row.locks)\n            end\n          end\n          if wl.prevEdit ~= nil then row.edits[tostring(wl.r)] = wl.prevEdit end\n        end\n        S.winner = nil\n        S.winnerReason = nil\n        S.winnerLock = nil\n        logev(\"resume\", row.fac)\n        dirty = true\n      end\n    end\n  end\n\n  if S.experimental and TRACK ~= nil then\n    if ITEMWATCH == nil then\n      initItemWatch()\n      CATCHUP = true\n    end\n    local mapObj = getObjectFromGUID(TRACK.guid)\n    -- the catch-up sweep needs the supply anchors, which fill on the first\n    -- fifth-poll scan; run it once they exist\n    if CATCHUP and mapObj and ITEMWATCH and next(SUPPLYPOS) ~= nil then\n      catchUpCrafts(mapObj)\n      CATCHUP = false\n      dirty = true\n    end\n    if mapObj and ITEMWATCH then\n      for guid, w in pairs(ITEMWATCH) do\n        local o = getObjectFromGUID(guid)\n        if o ~= nil and o.held_by_color ~= nil then w.holder = o.held_by_color end\n        local gone = (o == nil)\n        if not gone then\n          local okl, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n          if okl and lp and (math.abs(lp.x) > 2.1 or math.abs(lp.z) > 2.1) then gone = true end\n        end\n        if gone then\n          ITEMWATCH[guid] = nil\n          INFLIGHT[guid] = { name = w.name, img = w.img, holder = w.holder,\n            tLeft = now(),\n            activeFac = S.rows[S.active] and S.rows[S.active].fac or nil }\n          dbg(\"EXP leave: \" .. w.name .. \" \" .. guid)\n        end\n      end\n      -- a crafted item put BACK in the supply was a mistake: undo the craft\n      -- and watch the item again as if it had never been taken\n      for _, row in ipairs(S.rows) do\n        if row.crafts then\n          for ci3 = #row.crafts, 1, -1 do\n            local c = row.crafts[ci3]\n            if c.guid then\n              local o2 = getObjectFromGUID(c.guid)\n              if o2 and o2.held_by_color == nil and inSupplyRegion(mapObj, o2) then\n                logev(\"uncraft\", row.fac, c.item)\n                table.remove(row.crafts, ci3)\n                ITEMWATCH[c.guid] = { name = c.item, holder = nil, img = c.img }\n                dirty = true\n              end\n            end\n          end\n        end\n      end\n      -- items in flight settle where they were crafted: the faction board\n      -- whose supply they end up beside claims them\n      for guid, fl in pairs(INFLIGHT) do\n        local o = getObjectFromGUID(guid)\n        if o ~= nil then\n          if o.held_by_color ~= nil then fl.holder = o.held_by_color end\n          if o.held_by_color == nil and inSupplyRegion(mapObj, o) then\n            -- returned to the supply: never crafted\n            INFLIGHT[guid] = nil\n            ITEMWATCH[guid] = { name = fl.name, holder = nil, img = fl.img }\n          elseif o.held_by_color == nil then\n            local op = o.getPosition()\n            local bestFac, bestD = nil, 30 * 30\n            for fac, sp2 in pairs(SUPPLYPOS) do\n              local dx, dz = op.x - sp2.x, op.z - sp2.z\n              local d = dx * dx + dz * dz\n              if d < bestD then bestFac, bestD = fac, d end\n            end\n            dbg(\"EXP inflight \" .. guid .. \" bestFac=\" .. tostring(bestFac)\n              .. \" supplies=\" .. tostring((function() local c = 0\n                for _ in pairs(SUPPLYPOS) do c = c + 1 end\n                return c end)()))\n            if bestFac then\n              local i2 = rowByFac(bestFac)\n              if i2 then\n                INFLIGHT[guid] = nil\n                attributeCraft(i2, fl, guid)\n                dirty = true\n              end\n            elseif now() - fl.tLeft > 300 then\n              INFLIGHT[guid] = nil\n            end\n          end\n        else\n          -- object vanished (bagged): fall back to whoever carried it last\n          INFLIGHT[guid] = nil\n          local i2 = fl.holder and rowByColor(fl.holder) or nil\n          if i2 then\n            attributeCraft(i2, fl, guid)\n            dirty = true\n          end\n        end\n      end\n    end\n  end\n\n  -- Normally the seat work is every 5th pass (~6s). A push from RTT is an EVENT, so it is taken on\n  -- the very next tick instead of waiting for the cycle to come round.\n  if pollCount % 5 == 1 or seatPushPending then\n    seatPushPending = false\n    local byName = {}\n    for _, o in ipairs(getAllObjects()) do\n      byName[o.getName() or \"\"] = o\n    end\n    SUPPLYPOS = {}\n    for _, row in ipairs(S.rows) do\n      local bag = facAnchor(row.fac, byName)\n      if bag then SUPPLYPOS[row.fac] = bag.getPosition() end\n    end\n    seatAnchorByName = byName\n    if refreshSeats(byName) then dirty = true end\n    if seatOrder() then dirty = true end\n    if refreshDeck() then dirty = true end\n    if refreshVariants(byName) then dirty = true end\n    if followTurns() then dirty = true end\n    if pinFirstSeat() then dirty = true end\n  end\n\n  if dirty then\n    dirty = false\n    rebuildUI()\n  end\nend\n\n------------------------------------------------------------------ turn flow --\nfunction lockRow(i)\n  local row = S.rows[i]\n  if row == nil then return end\n  S.pinFirst = false          -- a turn is being recorded: stop holding seat 1\n  -- A quick turn pass can beat the poll in either direction, so count every\n  -- settled copy here too before the turn number advances.\n  local objects = getAllObjects()\n  local domCards = {}\n  local rowMarkers = {}\n  for _, o in ipairs(objects) do\n    local suit = dominanceCardSuit(o)\n    if suit then table.insert(domCards, { obj = o, suit = suit }) end\n    if (o.getName() or \"\") == (row.fac .. \" VP\") then\n      table.insert(rowMarkers, o)\n    end\n  end\n  local markerState = syncDominance(row, domCards, rowMarkers)\n  -- the game is over once someone reached 30: nothing locks any more\n  if S.winner ~= nil then return end\n  -- re-read the marker right now: the polled score can be a beat stale, and a\n  -- lock is forever (it is what gets exported)\n  if not dominanceFrozen(row) then\n    local idx = markerState.trackIdx\n    if idx ~= nil then\n      local sc = cellToScore(idx)\n      if sc ~= row.score then\n        logev(\"score\", row.fac, row.score, sc)\n        row.score = sc\n      end\n    end\n  end\n  -- The HIGHLIGHTED round column is the single truth for where a lock\n  -- lands: the lock goes exactly there, overwriting whatever the cell\n  -- holds (lock or hand edit). A wrong column is corrected by clicking\n  -- the right column number in EDIT, never by the sheet second-guessing.\n  -- THE WRAP, detected per row: being asked to lock a row that has already locked this round means\n  -- the table has come round, so the round advances. Nothing divides by #S.rows any more, so a row\n  -- joining or leaving mid-game cannot re-map anybody's columns, and a seat whose colour never gets a\n  -- turn no longer drags every other row a column to the left.\n  local prevRound, prevLast = currentRound(), row.lastRound\n  S.round = roundForRow(row)\n  local r = currentRound()\n  row.edits[tostring(r)] = nil\n  while #row.locks < r - 1 do\n    table.insert(row.locks, -1)\n  end\n  row.locks[r] = row.score\n  row.lastRound = r\n  table.insert(S.undo, { fac = row.fac, r = r, prevRound = prevRound, prevLast = prevLast })\n  logev(\"lock\", row.fac, r, row.score)\n  S.turns = S.turns + 1\nend\n\n-- lockRow RECORDS; the caller REPAINTS. It used to rebuild the sheet itself, but the pointer moves\n-- AFTER the lock on the turn-system path -- so that rebuild drew the outgoing seat and a second one\n-- was needed regardless. Both callers now repaint exactly once, and there is one place to look for it.\n\n-- With full coverage the TTS turn system locks turns; otherwise END TURN.\nlocal function lockActive()\n  if S.winner ~= nil then return end\n  if #S.rows == 0 or fullTurnCoverage() then return end\n  if S.active > #S.rows then S.active = 1 end\n  local i = S.active\n  S.active = (S.active % #S.rows) + 1     -- the pointer moves BEFORE the lock on this path\n  lockRow(i)\n  rebuildUI()\nend\n\nfunction uiEndTurn() lockActive() end\n\n-- ---- called by the table's TURN PANEL (RTT_TURN_PANEL_JSON) ------------------------------------\n-- The panel is a separate object, so it reaches the sheet the way RTT does: obj.call by name.\n\n-- Which round the sheet believes it is on. The panel displays THIS rather than counting itself, so\n-- the two can never drift apart -- the maintainer asked for the panel to use \"the boxscore turn\n-- counter\", not a second one.\nfunction rttRound() return liveRound() end\n\n-- Is there a game recorded here worth warning about before it is thrown away? The panel's START button\n-- asks first when this is true. Maintainer, 2026-09-07: \"if pressing on start while there is data in\n-- the boxscore that will be wiped, warning with This resets boxscore.\"\n-- THE LIVE SCORE IS NOT THE TEST. Two wrong versions before this one: >= 0 was true on a fresh sheet,\n-- because the poll reads every VP marker the moment it appears and they all read zero; then > 0 was\n-- wrong the other way -- maintainer, 2026-09-07: \"no data is fresh, data could be actually 0\". A game\n-- in progress where nobody has scored yet is still a game.\n--\n-- So this asks what has been RECORDED, never what the markers currently say: a turn has passed, a\n-- round's score is locked, a cell was edited by hand, or a dominance card is out.\n-- The panel calls this immediately before it moves the turn to seat 1. Maintainer, 2026-09-07: \"I\n-- guess pressing start skips the turn of the given player and therefore records the score\" -- exactly\n-- so. Moving the pointer IS a pass as far as TTS is concerned, and a pass locks the outgoing row, so\n-- START was writing a completed turn nobody played. Waiting a few frames and wiping afterwards was a\n-- race; refusing the one lock is not.\nRTT_SKIP_LOCK = false\nfunction rttSuppressNextLock() RTT_SKIP_LOCK = true return true end\n\nfunction rttHasData()\n  -- NOT S.turns. A turn PASS is not a turn RECORDED: the pass that START itself provokes bumps that\n  -- counter, so keying on it made the very next START warn about a sheet holding nothing. Maintainer,\n  -- 2026-09-07: \"when someone presses start the first time you should not give the reset warning. in\n  -- general do not give the reset warning if there are no turn 1 completed on the boxscore.\" A locked\n  -- cell IS a completed turn, which is exactly the line he drew.\n  for _, row in ipairs(S.rows or {}) do\n    if row.dom ~= nil then return true end\n    for _, v in pairs(row.locks or {}) do\n      if v ~= nil and v ~= -1 then return true end\n    end\n    for _, v in pairs(row.edits or {}) do\n      if v ~= nil then return true end\n    end\n  end\n  return false\nend\n\n-- WIPE THE SCORES AND START AT TURN 1. Maintainer, 2026-09-07: \"start needs to wipe all scores and\n-- setup at turn 1 of player 1.\"\n--\n-- Deliberately NOT uiReset: that empties S.rows and lets the poll rediscover them, which also throws\n-- away the player NAMES, and those are typed in by hand. This clears what belongs to the game just\n-- played -- every lock, edit, score, dominance, coalition and turn length -- and keeps the table that\n-- was set up.\nfunction rttResetAndStart()\n  logev(\"panel start\")\n  -- BELT AND BRACES ON THE ONE-SHOT. RTT_SKIP_LOCK is consumed in exactly one place, inside\n  -- onPlayerTurn, so an arming that never produced a pass used to leave it set until it swallowed the\n  -- first real turn of the game. The panel no longer arms it unless a pass really is coming; clearing\n  -- it here as well means a stale flag cannot outlive the START that set it whatever the panel does.\n  RTT_SKIP_LOCK = false\n  for _, row in ipairs(S.rows or {}) do\n    row.locks, row.edits = {}, {}\n    row.score = -1\n    row.dom, row.coalition, row.crafts = nil, nil, nil\n    row.lastTurn, row.lastRound = nil, nil\n  end\n  S.turns = 0\n  S.round = 1\n  S.active = 1\n  S.turnHolder = nil\n  S.winner, S.winnerReason, S.winnerLock = nil, nil, nil\n  S.undo = {}\n  S.turnStart = now()\n  pcall(function() rebuildUI() end)\n  return true\nend\n\n\nfunction onPlayerTurn(player, previous)\n  dbg(\"BoxScore onPlayerTurn: now=\" .. tostring(player and player.color)\n    .. \" prev=\" .. tostring(previous and previous.color)\n    .. \" coverage=\" .. tostring(fullTurnCoverage()))\n  -- ONE lock source per mode: with full coverage the event locks; in every\n  -- other situation the END TURN button is visible and is the only source.\n  if not fullTurnCoverage() then return end\n  -- A pass counts when the colour that just finished HAS A ROW -- i.e. it is one of the seats in play.\n  -- This used to require previous.seated, so an unoccupied seat's turn recorded nothing: in a solo game\n  -- every faction but one is on an empty seat, so ending a turn did nothing at all. Keying on \"has a\n  -- row\" keeps the original protection (toggling the turn system bursts through colours that have no\n  -- row, and those still lock nothing) while letting a seat's turn count whether or not a human sits\n  -- in it. In a full game every seat is occupied, so nothing changes there.\n  -- HOW LONG THAT TURN TOOK. Maintainer, 2026-09-06: he wants each seated player's previous turn\n  -- duration on the sheet, \"at the right of the player s name\". The turn system already says exactly\n  -- when one turn ends and the next begins, so the sheet times itself and needs nothing from the table\n  -- panel. Second resolution (now() is os.time), which is all a turn length needs.\n  local tNow = now()\n  if previous == nil or previous.color == nil then S.turnStart = tNow return end\n  -- STALE AND DUPLICATE EVENTS. With full coverage this is the only lock source, and lockRow's wrap\n  -- detection reads \"this row has already locked this round\" as proof the table has come round again.\n  -- So a pass event delivered twice does not merely lock twice -- it INVENTS A ROUND: that faction\n  -- gets a second cell in the next column, exports one more turn than anybody else, and the round\n  -- counter runs ahead of the table.\n  --\n  -- The discriminator is who was holding the turn. A real pass is always handed over by the colour\n  -- that HAD it, so `previous` must be the colour this object last saw take the turn. A duplicate or\n  -- a late re-delivery names a colour that has already handed over. Refusing on that alone would be\n  -- too broad -- the pointer can be moved by START or by an edited turn order without an event -- so\n  -- it only refuses when the pass would ALSO invent a round, which is the case that corrupts the\n  -- record. Anything else is allowed through exactly as before.\n  local prevRow = rowByColor(previous.color)   -- the row whose turn just ended, resolved ONCE\n\n  -- START'S ONE-SHOT IS CONSUMED FIRST, before any refusal below can return. The panel arms it\n  -- immediately before it moves the pointer, so the very next pass is always the one it means. When\n  -- the refusal below sat in front of this, a rejected pass left the flag armed and it went on to\n  -- swallow the next REAL lock -- a silently missing round, caused by two guards in the wrong order.\n  local suppressed = RTT_SKIP_LOCK\n  RTT_SKIP_LOCK = false\n\n  if not suppressed and prevRow ~= nil and S.turnHolder ~= nil\n     and previous.color ~= S.turnHolder\n     and (S.rows[prevRow].lastRound or 0) >= currentRound() then\n    dbg(\"BoxScore: ignoring a pass from \" .. tostring(previous.color)\n      .. \" -- \" .. tostring(S.turnHolder) .. \" holds the turn and it would invent a round\")\n    return\n  end\n  S.turnHolder = player and player.color or nil\n  -- A pass by a seated color with no faction row (an observer) locks nothing.\n  if not suppressed and prevRow ~= nil then\n    lockRow(prevRow)\n    if S.turnStart ~= nil and tNow >= S.turnStart then\n      S.rows[prevRow].lastTurn = tNow - S.turnStart\n    end\n  end\n  S.turnStart = tNow\n  -- sync the pointer immediately instead of waiting for the next poll\n  local j = player and player.color and rowByColor(player.color) or nil\n  if j then S.active = j end\n  -- ...AND REPAINT, once, here at the end -- lockRow records but does not draw. The pointer moves\n  -- AFTER the lock on this path, and nothing else marks the sheet dirty: poll() only rebuilds when\n  -- one of its checks reports a change, and followTurns() finds S.active already correct and reports\n  -- none. Without this the sheet kept showing the FINISHED seat's round until some unrelated change\n  -- happened to trigger a rebuild.\n  rebuildUI()\nend\n\n------------------------------------------------------------ marker movement --\n-- +/- moves the faction's marker along the track: a fast glide with a small\n-- hop, so rapid clicks load several points in a couple of seconds. Sub-row\n-- rule so every marker stays visible: an empty cell takes the marker dead\n-- centre; an occupied cell pushes the newcomer one step up, then down, then\n-- two up - never on top of another marker.\nlocal function subRowSequence()\n  local byB = {}\n  for _, b in ipairs(TRACK.rows) do table.insert(byB, b) end\n  table.sort(byB)\n  local mid = byB[math.ceil(#byB / 2)]\n  local step = 0.11\n  if #byB >= 2 then step = (byB[#byB] - byB[1]) / (#byB - 1) end\n  return { mid, mid - step, mid + step, mid - 2 * step, mid + 2 * step }\nend\n\nlocal function nudge(i, delta)\n  local row = S.rows[i]\n  if row == nil or dominanceFrozen(row) or TRACK == nil then return end\n  local m = findMarker(row)\n  if m == nil then dbg(\"BoxScore: cannot find \" .. row.fac .. \" VP\") return end\n  if m.held_by_color ~= nil then return end\n  local base = row.score >= 0 and row.score or 0\n  local target = row.score >= 0 and (base + delta) or 0\n  target = math.max(0, math.min(TRACK.n - 1, target))\n  if target == row.score then return end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then return end\n  local cellA = TRACK.a0 + scoreToCell(target) * TRACK.s\n\n  -- candidate positions = the map's own snap points in this column, tried\n  -- centre-first so a lone marker sits exactly on the printed number\n  local mid = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local cands = {}\n  for _, p in ipairs(TRACK.pts or {}) do\n    if math.abs(p.a - cellA) < 0.45 * TRACK.s then\n      table.insert(cands, p)\n    end\n  end\n  table.sort(cands, function(p, q)\n    return math.abs(p.b - mid) < math.abs(q.b - mid)\n  end)\n  -- extrapolated overflow spots keep every marker visible past 3 stacked\n  local seq = subRowSequence()\n  table.insert(cands, { a = cellA, b = seq[4] })\n  table.insert(cands, { a = cellA, b = seq[5] })\n\n  local chosen = cands[#cands]\n  for _, c in ipairs(cands) do\n    local free = true\n    for _, other in ipairs(S.rows) do\n      if other ~= row then\n        local om = other.guid and getObjectFromGUID(other.guid) or nil\n        if om then\n          local lp2 = mapObj.positionToLocal(om.getPosition())\n          if math.abs(lp2[TRACK.axis] - c.a) < 0.5 * TRACK.s\n            and math.abs(lp2[TRACK.other] - c.b) < 0.09 then free = false end\n        end\n      end\n    end\n    if free then chosen = c break end\n  end\n\n  local lp = { x = 0, y = 2.0, z = 0 }\n  lp[TRACK.axis] = chosen.a\n  lp[TRACK.other] = chosen.b\n  local wp = mapObj.positionToWorld(lp)\n  m.setPositionSmooth({ wp.x, wp.y + 0.12, wp.z }, false, true)\n  logev(\"score\", row.fac, row.score, target)\n  row.score = target\n  rebuildUI()\nend\n\n-------------------------------------------------------------------- buttons --\nfunction uiUndo()\n  if #S.undo == 0 then return end\n  local entry = table.remove(S.undo)\n  local fac = type(entry) == \"table\" and entry.fac or entry\n  local col = type(entry) == \"table\" and entry.r or nil\n  local i = rowByFac(fac)\n  local row = i and S.rows[i] or nil\n  if row and #row.locks > 0 then\n    col = col or #row.locks\n    logev(\"undo\", row.fac, col, row.locks[col])\n    row.locks[col] = -1\n    while #row.locks > 0 and (row.locks[#row.locks] == -1 or row.locks[#row.locks] == nil) do\n      table.remove(row.locks)\n    end\n    S.turns = math.max(0, S.turns - 1)\n    -- and the round bookkeeping this lock changed, so undoing the first lock of a round steps the\n    -- round back with it instead of leaving the sheet a column ahead of itself.\n    local u = S.undo[#S.undo]\n    if u ~= nil and u.fac == row.fac and u.r == col then\n      if u.prevRound ~= nil then S.round = u.prevRound end\n      row.lastRound = u.prevLast\n      table.remove(S.undo)\n    end\n    S.pinFirst = false        -- undo positions the pointer deliberately\n    if not fullTurnCoverage() then S.active = i end\n    rebuildUI()\n  end\nend\n\nfunction uiInfo()\n  S.overlay = (S.overlay == \"info\") and nil or \"info\"\n  rebuildUI()\nend\n\nfunction uiSetup()\n  S.setup = not S.setup\n  S.overlay = nil\n  rebuildUI()\nend\n\nfunction uiReset()\n  logev(\"reset\")\n  S.rows = {}\n  S.active = 1\n  S.turns = 0\n  S.round = 1\n  S.turnHolder = nil\n  S.pinFirst = true\n  S.winner = nil\n  S.winnerReason = nil\n  S.winnerLock = nil\n  S.undo = {}\n  S.log = {}\n  S.unpicked = {}\n  S.unpickedVar = {}\n  S.meta.map = \"\"\n  S.meta.deck = \"\"\n  S.mapAuto = nil\n  S.deckAuto = nil\n  S.flip = false\n  S.manualOrder = nil\n  S.lastExport = \"\"\n  TRACK = nil\n  findTrack()\n  refreshAssets()\n  rebuildUI()\nend\n\nfunction uiPicker()\n  S.overlay = \"picker\"\n  rebuildUI()\nend\n\nfunction uiMapMenu()\n  S.overlay = \"map\"\n  rebuildUI()\nend\n\nfunction uiGameMenu()\n  S.overlay = \"game\"\n  rebuildUI()\nend\n\nfunction uiDeckMenu()\n  S.overlay = \"deck\"\n  rebuildUI()\nend\n\nfunction uiDiscord()\n  S.overlay = \"discord\"\n  rebuildUI()\nend\n\nfunction uiOverlayClose()\n  S.overlay = nil\n  rebuildUI()\nend\n\n-- COPY: TTS Lua has no OS-clipboard access, so the closest honest thing is\n-- a selectable box holding the JSON - one Ctrl+A + Ctrl+C away. The text is\n-- injected via setAttribute AFTER the rebuild because entities in XML\n-- attributes never decode (a JSON quote would wreck the parse).\nfunction uiExport(player)\n  S.exportBy = player and player.steam_name or \"\"\n  local json = exportJson()\n  writeExportNotebook(json)\n  -- The readable table first, then the SAME json in its own ```json fence. That answers the site's\n  -- \"how would an API work\" directly: a Discord webhook needs no API and no callback, because the\n  -- destination is baked into the URL -- the sheet POSTs out, nothing has to reach back in. A bot\n  -- reading the channel gets a machine-readable record for free, beside the human one.\n  local msgs = fencedChunks(boxText())\n  for _, chunk in ipairs(jsonChunks(json)) do table.insert(msgs, chunk) end\n  local toDiscord = postDiscord(msgs)\n  S.lastExport = (toDiscord and \"exported &#183; sent to Discord\"\n                             or (\"exported &#183; JSON in TTS Notebook &#8220;\" .. NOTEBOOK_TAB .. \"&#8221;\"))\n  dbg(\"BoxScore: exported \" .. #json .. \" chars\" .. (toDiscord and \" (discord)\" or \" (notebook)\"))\n  rebuildUI()\nend\n\nfunction uiFlip()\n  S.flip = not S.flip\n  for _, row in ipairs(S.rows) do\n    if row.dom == nil then row.score = -1 end\n  end\n  rebuildUI()\nend\n\nfunction uiSpin()\n  S.pose = (S.pose % #UI_POSES) + 1\n  rebuildUI()\nend\n\nfunction uiScaleMode()\n  S.scaleMode = (S.scaleMode % 2) + 1\n  rebuildUI()\nend\n\nlocal function changeSizePct(delta)\n  S.sizePct = clampSizePct((S.sizePct or 100) + delta)\n  rememberSizePct()\n  rebuildUI()\nend\n\nfunction uiSizeDown() changeSizePct(-10) end\nfunction uiSizeUp() changeSizePct(10) end\n\nfunction uiHide()\n  S.hidden = not S.hidden\n  rebuildUI()\nend\n\nfunction uiDiag()\n  local lines = {}\n  if TRACK then\n    lines[1] = \"map=\" .. TRACK.guid .. \" (\" .. (S.meta.map ~= \"\" and S.meta.map or \"?\")\n      .. \") cells 0-\" .. (TRACK.n - 1) .. \", \" .. #TRACK.rows .. \" sub-rows, flip=\" .. tostring(S.flip)\n  else\n    lines[1] = \"NO TRACK FOUND - is a map on the table?\"\n  end\n  table.insert(lines, \"turn system: \" .. (turnsRunning() and \"following\" or \"manual\"))\n  table.insert(lines, \"unpicked: \" .. table.concat(unpickedList(), \", \"))\n  for _, row in ipairs(S.rows) do\n    local m = findMarker(row)\n    local idx = m and readCell(m) or nil\n    table.insert(lines, row.fac .. \" [\" .. tostring(row.color) .. \"/\" .. row.player\n      .. \"]: score=\" .. tostring(row.score) .. \" cell=\" .. tostring(idx)\n      .. \" locks=\" .. #row.locks)\n  end\n  broadcastToAll(\"Box Score diagnose:\\n\" .. table.concat(lines, \"\\n\"), { 0.91, 0.86, 0.74 })\n  log(\"BoxScore diagnose: \" .. JSON.encode({ track = TRACK, state = S }))\nend\n\nfunction uiRowBtn(player, _, id)\n  local uvF, uvC = id:match(\"^uv_(%d+)_(%d+)$\")\n  if uvF then\n    local fac = ROSTER[tonumber(uvF)]\n    local opts = fac and variantOptions(fac) or nil\n    if opts and opts[tonumber(uvC)] then\n      S.unpickedVar[fac] = toggleCSV(S.unpickedVar[fac], opts[tonumber(uvC)], opts)\n      rebuildUI()\n    end\n    return\n  end\n  local kind, i = id:match(\"^(%a+)_(%d+)$\")\n  i = tonumber(i)\n  if kind == \"plus\" then nudge(i, 1)\n  elseif kind == \"minus\" then nudge(i, -1)\n  elseif kind == \"up\" then\n    if i > 1 then\n      S.rows[i], S.rows[i - 1] = S.rows[i - 1], S.rows[i]\n      if S.active == i then S.active = i - 1 elseif S.active == i - 1 then S.active = i end\n      S.manualOrder = true\n      rebuildUI()\n    end\n  elseif kind == \"del\" then\n    local row = S.rows[i]\n    if row then\n      logev(\"leave\", row.fac)\n      table.remove(S.rows, i)\n      if i < S.active then S.active = S.active - 1 end\n      if S.active > #S.rows or S.active < 1 then S.active = 1 end\n      refreshAssets()\n      rebuildUI()\n    end\n  elseif kind == \"pick\" then\n    local fac = ROSTER[i]\n    if fac then\n      S.unpicked[fac] = (S.unpicked[fac] ~= true) and true or nil\n      rebuildUI()\n    end\n  elseif kind == \"act\" then\n    if S.rows[i] then\n      S.pinFirst = false      -- deliberate row pick: do not snap it back\n      S.active = i\n      rebuildUI()\n    end\n  elseif kind == \"coal\" then\n    local row = S.rows[i]\n    if row and canCoalition(row) then\n      local cands = coalitionCandidates(row)\n      local at = 0\n      for k, fac in ipairs(cands) do if fac == row.coalition then at = k end end\n      row.coalition = cands[at + 1]          -- nil past the end: cycles back to no coalition\n      logev(\"coalition\", row.fac, row.coalition or \"none\")\n      rebuildUI()\n    end\n  elseif kind == \"domwin\" then\n    local row = S.rows[i]\n    if row and row.dom then\n      local won = row.dom.won == true\n      for _, other in ipairs(S.rows) do\n        if other.dom then other.dom.won = false end\n      end\n      if won then\n        if S.winner == row.fac and S.winnerReason == \"dominance\" then\n          S.winner = nil\n          S.winnerReason = nil\n        end\n        logev(\"domwin-undo\", row.fac, row.dom.turn, row.dom.suit)\n      else\n        row.dom.won = true\n        S.winner = row.fac\n        S.winnerReason = \"dominance\"\n        S.winnerLock = nil\n        logev(\"domwin\", row.fac, row.dom.turn, row.dom.suit)\n      end\n      rebuildUI()\n    end\n  elseif kind == \"fv\" then\n    S.varRow = i\n    S.overlay = \"var\"\n    rebuildUI()\n  elseif kind == \"vc\" then\n    local row = S.rows[S.varRow]\n    if row then\n      local opts = variantOptions(row.fac)\n      if opts and opts[i] then\n        row.variant = toggleCSV(row.variant, opts[i], opts)\n        row.variantAuto = false\n        rebuildUI()\n      end\n    end\n  elseif kind == \"deck\" then\n    local d = DECKS[i]\n    S.meta.deck = (S.meta.deck == d) and \"\" or d\n    S.deckAuto = false\n    S.overlay = nil\n    rebuildUI()\n  elseif kind == \"map\" then\n    local m = MAPS[i]\n    S.meta.map = (S.meta.map == m) and \"\" or m\n    S.mapAuto = false\n    S.overlay = nil\n    rebuildUI()\n  elseif kind == \"colh\" then\n    -- clicking a round-column number in setup declares \"we are in round i\";\n    -- locks always land in the declared (highlighted) column.\n    -- It used to say so by writing a FABRICATED turn count, (i-1) * #S.rows, which silently reset the\n    -- within-round position to zero: every row that had already played round i was then treated as\n    -- not having played it, so half the table's next lock landed in the round they had just finished.\n    -- Declaring the round now says exactly that and nothing else.\n    S.round = math.max(1, i)\n    for _, r in ipairs(S.rows) do r.lastRound = nil end\n    logev(\"setround\", nil, S.round)\n    rebuildUI()\n  end\nend\n\n--------------------------------------------------------------- text editing --\nfunction uiCellEdit(player, value, id)\n  local i, r = id:match(\"^cl_(%d+)_(%d+)$\")\n  i, r = tonumber(i), tonumber(r)\n  local row = S.rows[i]\n  if row == nil then return end\n  value = tostring(value or \"\"):gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n  -- an emptied cell stays empty: \"\" is an explicit blank that overrides the\n  -- locked value (it would otherwise reappear on the next rebuild)\n  if value == \"\" and row.locks[r] == nil then\n    row.edits[tostring(r)] = nil\n  else\n    row.edits[tostring(r)] = value\n    logev(\"edit\", row.fac, r, value)\n  end\nend\n\nfunction uiLiveEdit(player, value, id)\n  value = tostring(value or \"\")\n  local ni = id:match(\"^nm_(%d+)$\")\n  if ni then\n    local row = S.rows[tonumber(ni)]\n    if row then row.player = value; row.nameAuto = false end\n  else\n    local ci, r = id:match(\"^cl_(%d+)_(%d+)$\")\n    if ci then\n      local row = S.rows[tonumber(ci)]\n      if row then row.edits[tostring(tonumber(r))] = value end\n    elseif id == \"mt_hook\" then S.meta.hook = value\n    elseif id == \"mt_thread\" then S.meta.thread = value\n    elseif id == \"mt_game\" then\n      S.meta.game = value:gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n    end\n  end\n  -- push the keystroke to every client without rebuilding the sheet\n  pcall(function() self.UI.setAttribute(id, \"text\", value) end)\nend\n\nfunction uiNameEdit(player, value, id)\n  local i = tonumber(id:match(\"^nm_(%d+)$\"))\n  if S.rows[i] then\n    S.rows[i].player = tostring(value or \"\")\n    S.rows[i].nameAuto = false\n  end\nend\n\n\nfunction uiMetaEdit(player, value, id)\n  local key = id:match(\"^mt_(%a+)$\")\n  value = tostring(value or \"\"):gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n  if key == \"turns\" then\n    S.turns = math.max(0, math.floor(tonumber(value) or S.turns))\n    rebuildUI()\n  elseif key and S.meta[key] ~= nil then\n    S.meta[key] = value\n  end\nend\n\n--------------------------------------------------------------------- the UI --\nfunction refreshAssets()\n  local assets = {}\n  local seen = {}\n  for _, row in ipairs(S.rows) do\n    if row.iconUrl and row.iconUrl ~= \"\" then\n      table.insert(assets, { name = assetName(row.fac), url = row.iconUrl })\n    end\n    for _, c in ipairs(row.crafts or {}) do\n      if c.img and c.img ~= \"\" then\n        local nm = \"it\" .. urlTail(c.img)\n        if not seen[nm] then\n          seen[nm] = true\n          table.insert(assets, { name = nm, url = c.img })\n        end\n      end\n    end\n  end\n  for _, url in pairs(S.itemImgs or {}) do\n    if url ~= \"\" then\n      local an = \"it\" .. urlTail(url)\n      if not seen[an] then\n        seen[an] = true\n        table.insert(assets, { name = an, url = url })\n      end\n    end\n  end\n  self.UI.setCustomAssets(assets)\nend\n\nlocal function fieldText(v)\n  if v == nil or v == \"\" then return \" \" end\n  return esc(v)\nend\n\nlocal function cellText(row, r)\n  local e = row.edits[tostring(r)]\n  -- Keep numeric locks internally so cancel can reveal the ordinary score\n  -- history again, but never print a dominance-era score while dom is active.\n  if dominanceFrozen(row) and r >= row.dom.round\n    and (e ~= nil or r <= #row.locks) then return \"-\" end\n  if e ~= nil then return e end\n  local v = row.locks[r]\n  if v == nil or v < 0 then return \"\" end\n  return tostring(v)\nend\n\n-- fenced plain-text box score, as posted to Discord (global on purpose:\n-- uiExport is defined above and resolves it at call time)\nfunction boxText()\n  local bits = {}\n  if S.meta.map ~= \"\" then table.insert(bits, S.meta.map) end\n  if S.meta.deck ~= \"\" then table.insert(bits, S.meta.deck) end\n  local unp = unpickedList()\n  if #unp > 0 then table.insert(bits, \"Unpicked: \" .. table.concat(unp, \", \")) end\n  local R = 0\n  for _, row in ipairs(S.rows) do\n    R = math.max(R, #row.locks)\n    for k, v in pairs(row.edits or {}) do\n      local rn = tonumber(k)\n      if rn and v ~= \"\" and rn > R then R = rn end\n    end\n  end\n  local round = liveRound()\n  local title = \"ROOT BOX SCORE\"\n  if S.meta.game ~= nil and S.meta.game ~= \"\" then\n    title = title .. \" - \" .. S.meta.game\n  end\n  local stamp = \"round \" .. round .. \" - \" .. os.date(\"%Y-%m-%d %H:%M\")\n  if S.exportBy ~= nil and S.exportBy ~= \"\" then\n    stamp = stamp .. \" - by \" .. S.exportBy\n  end\n  local lines = { title .. \" - \" .. table.concat(bits, \" / \"), stamp }\n  local head = string.format(\"%-11s %-17s\", \"faction\", \"player\")\n  for r = 1, R do head = head .. string.format(\"%4d\", r) end\n  table.insert(lines, head)\n  for _, row in ipairs(S.rows) do\n    local line = string.format(\"%-11s %-17s\", row.fac:sub(1, 11),\n      (row.player or \"\"):sub(1, 17))\n    for r = 1, R do line = line .. string.format(\"%4s\", cellText(row, r)) end\n    table.insert(lines, line)\n    if row.variant ~= nil and row.variant ~= \"\" then\n      table.insert(lines, \"  > \" .. row.variant)\n    end\n    if row.dom ~= nil then\n      table.insert(lines, \"  > dominance: \" .. dominanceKindLabel(row.dom)\n        .. \", turn \" .. tostring(row.dom.turn)\n        .. \", \" .. tostring(row.dom.suit)\n        .. \", won: \" .. ((row.dom.won == true) and \"yes\" or \"no\"))\n    end\n    if S.experimental and row.crafts ~= nil and #row.crafts > 0 then\n      local cs = {}\n      for _, c in ipairs(row.crafts) do\n        local tags = {}\n        if c.r then table.insert(tags, \"T\" .. c.r) end\n        if c.vp and c.vp > 0 then table.insert(tags, \"+\" .. c.vp) end\n        table.insert(cs, c.item\n          .. (#tags > 0 and (\" (\" .. table.concat(tags, \", \") .. \")\") or \"\"))\n      end\n      table.insert(lines, \"  > crafted: \" .. table.concat(cs, \", \"))\n    end\n  end\n  return lines\nend\n\n-- fields are invisible until touched: transparent at rest, white while hovered\n-- or being edited, so SETUP reads exactly like the printed sheet\nlocal IF_COLORS = 'placeholder=\" \" colors=\"#00000000|#FFFFFFC0|#FFFFFF|#00000000\"'\nlocal BTN_DARK = 'colors=\"' .. WALNUT .. '|' .. RUST .. '|' .. GOLD .. '|#00000000\" textColor=\"' .. PARCH .. '\"'\nlocal BTN_GOLD = 'colors=\"' .. GOLD .. '|' .. GOLDHI .. '|' .. RUST .. '|#00000000\" textColor=\"' .. INKTXT .. '\"'\nlocal BTN_SOFT = 'colors=\"' .. PARCH2 .. '|' .. GOLDHI .. '|' .. GOLD .. '|#00000000\" textColor=\"' .. RUST .. '\"'\nlocal NOClick = ' raycastTarget=\"false\"' \n\nlocal lastScaleKey = \"\"\n\nlocal function renderMinRows()\n  local n = tonumber(Global.getVar(\"RTT_BOXSCORE_MIN\"))\n  if not n then\n    local dn = tonumber(Global.getVar(\"RTT_DN\"))\n    if dn then n = dn - 1 end\n  end\n  return math.max(1, n or 4)\nend\n\n-- One TTS Notebook tab, rewritten on every export. TTS has no clipboard API and an InputField here\n-- cannot be filled from script (measured: it renders a placeholder but never text set by the\n-- script, in any container, by any of attribute / inner text / setAttribute / setValue). The\n-- notebook body is a native text area that never touches the XML layer, so that is where the JSON\n-- goes -- and it is the SAME single payload that would go to Discord, never a second copy.\nfunction writeExportNotebook(text)\n  local done = false\n  for _, t in ipairs(Notes.getNotebookTabs()) do\n    if t.title == NOTEBOOK_TAB then\n      Notes.editNotebookTab({ index = t.index, title = NOTEBOOK_TAB, body = text })\n      done = true\n    end\n  end\n  if not done then Notes.addNotebookTab({ title = NOTEBOOK_TAB, body = text }) end\nend\n\nfunction rebuildUI()\n  if S.hidden then\n    self.UI.setXml(\"\")\n    return\n  end\n  local maxLocks = 0\n  for _, row in ipairs(S.rows) do maxLocks = math.max(maxLocks, #row.locks) end\n  -- Width follows the card track only. Growing it with maxLocks made the\n  -- sheet widen silently as the game went on.\n  local showR = math.min((S.cols or 10) + 1, 41)\n  local cellW = showR > 14 and 36 or 44\n  -- timeW is the previous-turn column, taken OUT of domW rather than added to the sheet's width: the\n  -- dominance column is 70 wide and empty in most rows, which is the gap the maintainer pointed at --\n  -- \"a lot of space between faction name and players name\".\n  local iconW, facW, domW, nameW, liveW, timeW = 30, 118, 52, 130, 48, 44\n  local btnW = 117\n  local W = 54 + iconW + facW + domW + nameW + timeW + (showR - 1) * cellW + liveW + btnW\n  local rowH, headH = 40, 26\n  local nMin = renderMinRows()\n  local H = 56 + headH + math.max(nMin, #S.rows) * (rowH + 3) + 42\n  local mul = clampSizePct(S.sizePct) / 100\n\n  -- The walnut cardboard extends FRAME px beyond the sheet on every side.\n  -- That rim is bare object surface - outside the UI canvas entirely - so it\n  -- is grabbable by construction, no matter how the UI treats clicks. The\n  -- parchment area additionally lets clicks through via raycastTarget.\n  local FRAME = 5\n  local k = BASE_SCALE * LEGACY_BASE_MUL / PX_PER_UNIT\n  local ww = (W + 2 * FRAME) * k\n  local wh = (H + 2 * FRAME) * k\n  ww = 31.80 wh = 10.42  -- FIXED to the maintainer 4-card box-score rectangle\n  ww, wh = ww * mul, wh * mul\n  local key = string.format(\"%.2f|%.2f\", ww, wh)\n  if key ~= lastScaleKey and self.held_by_color == nil then\n    lastScaleKey = key\n    self.setScale({ ww, 0.18, wh })\n  end\n  local sx, sy\n  if S.scaleMode == 1 then\n    sx, sy = PX_PER_UNIT / (W + 2 * FRAME), PX_PER_UNIT / (H + 2 * FRAME)\n  else\n    sx, sy = BASE_SCALE * LEGACY_BASE_MUL * mul, BASE_SCALE * LEGACY_BASE_MUL * mul\n  end\n  local pose = UI_POSES[S.pose]\n\n  local seatedNow = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated then seatedNow[p.color] = true end\n  end\n\n  local x = {}\n  local function add(s) table.insert(x, s) end\n\n  -- a Button whose label lives in a child Text: entities render correctly\n  -- there (attribute strings do not decode them), and the label can be bold\n  local function chip(id, handler, style, w, fs, textColor, label)\n    local wattr = (w == 0) and 'flexibleWidth=\"1\"' or ('preferredWidth=\"' .. w .. '\"')\n    add('<Button id=\"' .. id .. '\" ' .. wattr .. ' ' .. style .. ' onClick=\"' .. handler .. '\">'\n      .. '<Text fontSize=\"' .. fs .. '\" fontStyle=\"Bold\" color=\"' .. textColor\n      .. '\" raycastTarget=\"false\">' .. label .. '</Text></Button>')\n  end\n\n  add(string.format(\n    '<Panel position=\"%s\" rotation=\"%s\" scale=\"%.4f %.4f 1\" width=\"%d\" height=\"%d\" color=\"%s\"%s>',\n    pose.pos, pose.rot, sx, sy, W, H, PARCH, NOClick))\n  add('<VerticalLayout padding=\"12 12 8 8\" spacing=\"4\">')\n\n  -- header band: the printed title and game facts in play; the map / deck /\n  -- unpicked / discord choices in setup - same height either way\n  add('<HorizontalLayout preferredHeight=\"34\" spacing=\"6\">')\n  local unp = unpickedList()\n  if S.setup then\n    add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleLeft\"'\n      .. ' preferredWidth=\"44\"' .. NOClick .. '>EDIT</Text>')\n    add('<InputField id=\"mt_game\" fontSize=\"13\" preferredWidth=\"130\" preferredHeight=\"20\"'\n      .. ' placeholder=\"GAME NAME\" colors=\"' .. WALNUT .. '|#52381E|#52381E|#00000000\"'\n      .. ' textColor=\"' .. PARCH .. '\" onValueChanged=\"uiLiveEdit\" text=\"' .. esc(S.meta.game)\n      .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    chip(\"mpbtn\", \"uiMapMenu\", (S.overlay == \"map\") and BTN_GOLD or BTN_DARK, 84, 11,\n      (S.overlay == \"map\") and INKTXT or PARCH,\n      S.meta.map ~= \"\" and esc(S.meta.map) or \"MAP\")\n    add('<Button id=\"dkbtn\" preferredWidth=\"112\" '\n      .. ((S.overlay == \"deck\") and BTN_GOLD or BTN_DARK) .. ' onClick=\"uiDeckMenu\">'\n      .. '<Text fontSize=\"11\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"8\"'\n      .. ' resizeTextMaxSize=\"11\" fontStyle=\"Bold\" color=\"'\n      .. ((S.overlay == \"deck\") and INKTXT or PARCH) .. '\" raycastTarget=\"false\">'\n      .. (S.meta.deck ~= \"\" and esc(S.meta.deck) or \"DECK\") .. '</Text></Button>')\n    chip(\"pkbtn\", \"uiPicker\", (S.overlay == \"picker\") and BTN_GOLD or BTN_DARK, 92, 11,\n      (S.overlay == \"picker\") and INKTXT or PARCH, \"UNPICKED\")\n    chip(\"dcbtn\", \"uiDiscord\", (S.overlay == \"discord\") and BTN_GOLD or BTN_DARK, 70, 10,\n      (S.overlay == \"discord\") and INKTXT or PARCH, \"DISCORD\")\n    chip(\"xpbtn\", \"uiExperimental\", S.experimental and BTN_GOLD or BTN_DARK, 62, 10,\n      S.experimental and INKTXT or PARCH, \"CRAFT\")\n    if S.experimental then\n      chip(\"cebtn\", \"uiCraftMenu\", (S.overlay == \"craft\") and BTN_GOLD or BTN_DARK, 58, 10,\n        (S.overlay == \"craft\") and INKTXT or PARCH, \"ITEMS\")\n    end\n    add('<Text fontSize=\"10\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleRight\"'\n      .. ' preferredWidth=\"62\"' .. NOClick .. '>SIZE ' .. clampSizePct(S.sizePct) .. '%</Text>')\n    chip(\"szdn\", \"uiSizeDown\", BTN_DARK, 26, 13, PARCH, \"&#8722;\")\n    chip(\"szup\", \"uiSizeUp\", BTN_DARK, 26, 13, PARCH, \"+\")\n    chip(\"rsbtn\", \"uiReset\", BTN_DARK, 56, 10, PARCH, \"RESET\")\n  else\n    add('<Text fontSize=\"18\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" alignment=\"MiddleLeft\"'\n      .. ' preferredWidth=\"330\"' .. NOClick .. '>' .. spaced(\"ROOT\") .. '&#160;&#160;&#183;&#160;&#160;'\n      .. spaced(\"BOX SCORE\") .. '</Text>')\n    local bits = {}\n    if S.meta.game ~= \"\" then table.insert(bits, esc(S.meta.game)) end\n    if S.meta.map ~= \"\" then table.insert(bits, esc(S.meta.map)) end\n    if S.meta.deck ~= \"\" then table.insert(bits, esc(S.meta.deck)) end\n    if #unp > 0 then table.insert(bits, \"Unpicked: \" .. esc(table.concat(unp, \", \"))) end\n    add('<Text fontSize=\"15\" fontStyle=\"Italic\" color=\"' .. RUST .. '\" alignment=\"MiddleRight\"'\n      .. ' flexibleWidth=\"1\"' .. NOClick .. '>' .. table.concat(bits, \"&#160;&#160;&#183;&#160;&#160;\") .. '</Text>')\n  end\n  add('</HorizontalLayout>')\n\n  add('<Panel preferredHeight=\"2\" color=\"' .. GOLD .. '\"' .. NOClick .. '/>')\n\n  -- column headers; in setup the round numbers are buttons that set the turn\n  add('<HorizontalLayout preferredHeight=\"' .. headH .. '\" spacing=\"3\">')\n  add('<Text preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. facW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. domW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. nameW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. timeW .. '\"' .. NOClick .. '> </Text>')\n  local curRound = liveRound()\n  for r = 1, showR - 1 do\n    local isCur = (r == curRound)\n    if S.setup then\n      add('<Button id=\"colh_' .. r .. '\" fontSize=\"15\" fontStyle=\"Bold\" preferredWidth=\"' .. cellW\n        .. '\" colors=\"' .. (isCur and GOLD or \"#00000000\") .. '|#FFFFFFC0|' .. GOLDHI\n        .. '|#00000000\" textColor=\"' .. (isCur and INKTXT or RUST)\n        .. '\" text=\"' .. r .. '\" onClick=\"uiRowBtn\"/>')\n    elseif isCur then\n      add('<Panel preferredWidth=\"' .. cellW .. '\" color=\"' .. GOLD .. '\"' .. NOClick\n        .. '><Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. INKTXT\n        .. '\" alignment=\"MiddleCenter\"' .. NOClick .. '>' .. r .. '</Text></Panel>')\n    else\n      add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleCenter\" preferredWidth=\"'\n        .. cellW .. '\"' .. NOClick .. '>' .. r .. '</Text>')\n    end\n  end\n  add('<Text preferredWidth=\"10\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. liveW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n  add('</HorizontalLayout>')\n\n  -- faction rows\n  local EMPTY_ROW = { fac=\"\", player=\"\", tintHex=\"3A2A1A\", iconUrl=\"\", variant=\"\", score=-1, locks={}, edits={}, crafts=nil }\n  for i = 1, math.max(nMin, #S.rows) do\n    local row = S.rows[i] or EMPTY_ROW\n    local placeholder = (S.rows[i] == nil)\n    local isActive = (not placeholder) and (i == S.active) and (fullTurnCoverage() or not turnsRunning())\n    if #S.rows == 0 then isActive = false end\n    local bg = isActive and GOLDHI or ((i % 2 == 1) and \"#00000000\" or PARCH2)\n    add('<HorizontalLayout preferredHeight=\"' .. rowH .. '\" spacing=\"3\" color=\"' .. bg .. '\"' .. NOClick .. '>')\n    if S.setup and not placeholder then\n      add('<Button id=\"act_' .. i .. '\" preferredWidth=\"' .. iconW\n        .. '\" colors=\"#00000000|#FFFFFFC0|' .. GOLDHI .. '|#00000000\" onClick=\"uiRowBtn\">')\n      if row.iconUrl and row.iconUrl ~= \"\" then\n        add('<Image image=\"' .. assetName(row.fac) .. '\" width=\"26\" height=\"26\"' .. NOClick .. '/>')\n      else\n        add('<Panel width=\"16\" height=\"16\" color=\"#' .. row.tintHex .. '\"' .. NOClick .. '/>')\n      end\n      add('</Button>')\n    elseif row.iconUrl and row.iconUrl ~= \"\" then\n      add('<Panel preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '><Image image=\"' .. assetName(row.fac)\n        .. '\" width=\"26\" height=\"26\"' .. NOClick .. '/></Panel>')\n    else\n      add('<Panel preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '><Panel width=\"20\" height=\"20\" color=\"'\n        .. WALNUT .. '\"' .. NOClick .. '><Panel width=\"16\" height=\"16\" color=\"#' .. row.tintHex .. '\"' .. NOClick .. '/></Panel></Panel>')\n    end\n    add('<VerticalLayout preferredWidth=\"' .. facW .. '\" spacing=\"0\">')\n    local facName = esc(row.fac)\n    add('<HorizontalLayout preferredHeight=\"22\" spacing=\"2\" childForceExpandWidth=\"false\">')\n    add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" preferredWidth=\"'\n      .. (facW - 30) .. '\" alignment=\"MiddleLeft\"' .. NOClick .. '>' .. facName .. '</Text>')\n    if S.setup and not placeholder and variantOptions(row.fac) then\n      chip(\"fv_\" .. i, \"uiRowBtn\", 'colors=\"#00000000|#FFFFFFC0|' .. GOLDHI .. '|#00000000\"',\n        26, 18, \"#8A7A64\", \"&#9660;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    add('</HorizontalLayout>')\n    if row.variant ~= nil and row.variant ~= \"\" then\n      add('<Text fontSize=\"11\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"6\"'\n        .. ' resizeTextMaxSize=\"11\" fontStyle=\"Italic\" color=\"' .. RUST .. '\" preferredHeight=\"14\"'\n        .. ' alignment=\"UpperLeft\"' .. NOClick .. '>' .. esc(row.variant) .. '</Text>')\n    end\n    add('</VerticalLayout>')\n    if row.dom ~= nil then\n      add('<VerticalLayout preferredWidth=\"' .. domW\n        .. '\" spacing=\"1\" childForceExpandHeight=\"false\">')\n      -- 14, not 16: the button below now takes two lines and the row is still 40 tall.\n      add('<Text fontSize=\"9\" fontStyle=\"Bold\" color=\"' .. RUST\n        .. '\" preferredHeight=\"14\" alignment=\"MiddleCenter\"' .. NOClick .. '>dom '\n        .. esc(row.dom.suit) .. ' T' .. tostring(row.dom.turn) .. '</Text>')\n      if canCoalition(row) then\n        -- a vagabond's dominance card buys a coalition, never a dominance win\n        add('<Button id=\"coal_' .. i .. '\" fontSize=\"10\" fontStyle=\"Bold\" preferredHeight=\"18\" '\n          .. ((row.coalition ~= nil) and BTN_GOLD or BTN_SOFT)\n          .. ' text=\"' .. esc(row.coalition and (\"+\" .. row.coalition) or \"coalition\") .. '\" onClick=\"uiRowBtn\"/>')\n      else\n        -- TWO LINES. Maintainer, 2026-09-06: \"the boxscore should write dom win on two line not only\n        -- on 1 line\". It stopped fitting on one when this column went from 70 wide to 52 to make room\n        -- for the turn-time column, so the label was being clipped. &#xA; is the line break TTS's XML\n        -- takes; 24 tall holds two lines of 10pt, and 14 + 24 + 1 spacing still sits inside rowH 40.\n        add('<Button id=\"domwin_' .. i .. '\" fontSize=\"10\" fontStyle=\"Bold\" preferredHeight=\"24\" '\n          .. ((row.dom.won == true) and BTN_GOLD or BTN_SOFT)\n          .. ' text=\"dom&#xA;win\" onClick=\"uiRowBtn\"/>')\n      end\n      add('</VerticalLayout>')\n    else\n      add('<Text preferredWidth=\"' .. domW .. '\"' .. NOClick .. '> </Text>')\n    end\n    if S.setup and not placeholder then\n      add('<InputField id=\"nm_' .. i .. '\" fontSize=\"15\" textAlignment=\"MiddleCenter\"'\n        .. ' preferredWidth=\"' .. nameW\n        .. '\" ' .. IF_COLORS .. ' textColor=\"' .. RUST\n        .. '\" text=\"' .. fieldText(row.player) .. '\" onValueChanged=\"uiLiveEdit\" onEndEdit=\"uiNameEdit\"/>')\n    else\n      add('<Text fontSize=\"15\" color=\"' .. RUST .. '\" alignment=\"MiddleCenter\" preferredWidth=\"' .. nameW\n        .. '\"' .. NOClick .. '>' .. esc(row.player) .. '</Text>')\n    end\n    -- that player's PREVIOUS turn, m:ss. Blank until they have finished one.\n    add('<Text fontSize=\"13\" color=\"' .. INKTXT .. '\" alignment=\"MiddleCenter\" preferredWidth=\"' .. timeW\n      .. '\"' .. NOClick .. '>' .. mmss(row.lastTurn) .. '</Text>')\n    local craftIcons = {}\n    if S.experimental then\n      for _, c in ipairs(row.crafts or {}) do\n        if c.r and c.img and c.img ~= \"\" then\n          craftIcons[c.r] = craftIcons[c.r] or {}\n          table.insert(craftIcons[c.r], c.img)\n        end\n      end\n    end\n    for r = 1, showR - 1 do\n      add('<Panel preferredWidth=\"' .. cellW .. '\"' .. NOClick .. '>')\n      if S.setup and not placeholder then\n        add('<InputField id=\"cl_' .. i .. '_' .. r .. '\" fontSize=\"15\" textAlignment=\"MiddleCenter\"'\n          .. ' width=\"' .. cellW .. '\" height=\"' .. (rowH - 6)\n          .. '\" characterLimit=\"3\" ' .. IF_COLORS .. ' textColor=\"' .. INKTXT\n          .. '\" text=\"' .. fieldText(cellText(row, r)) .. '\" onValueChanged=\"uiLiveEdit\" onEndEdit=\"uiCellEdit\"/>')\n      else\n        add('<Text fontSize=\"15\" color=\"' .. INKTXT\n          .. '\" alignment=\"MiddleCenter\" width=\"' .. cellW .. '\" height=\"' .. rowH .. '\"' .. NOClick .. '>'\n          .. esc(cellText(row, r)) .. '</Text>')\n      end\n      -- crafted-item figures climb the cell's right edge, clear of the number\n      local ic = craftIcons[r]\n      if ic then\n        for k = 1, math.min(#ic, 6) do\n          local col = math.floor((k - 1) / 3)\n          local rw = (k - 1) % 3\n          add('<Image image=\"it' .. urlTail(ic[k]) .. '\" width=\"13\" height=\"13\"'\n            .. ' rectAlignment=\"LowerRight\" offsetXY=\"' .. (-1 - col * 13) .. ' ' .. (1 + rw * 13)\n            .. '\"' .. NOClick .. '/>')\n        end\n      end\n      add('</Panel>')\n    end\n    local live = row.score >= 0 and tostring(row.score) or \"&#8211;\"\n    local liveFont = 16\n    if dominanceFrozen(row) then\n      live = (row.dom.won == true) and \"dom win\" or \"-\"\n      liveFont = 10\n    end\n    add('<Text preferredWidth=\"10\"' .. NOClick .. '> </Text>')\n    add('<Panel preferredWidth=\"' .. liveW .. '\" color=\"' .. GOLD .. '\"' .. NOClick .. '>'\n      .. '<Text fontSize=\"' .. liveFont .. '\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" alignment=\"MiddleCenter\"' .. NOClick .. '>'\n      .. live .. '</Text></Panel>')\n    if placeholder or dominanceFrozen(row) then\n      add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n      add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n    else\n      chip(\"minus_\" .. i, \"uiRowBtn\", BTN_SOFT, 28, 14, RUST, \"&#8722;\")\n      chip(\"plus_\" .. i, \"uiRowBtn\", BTN_SOFT, 28, 14, RUST, \"+\")\n    end\n    if S.setup and i > 1 and not placeholder then\n      chip(\"up_\" .. i, \"uiRowBtn\", BTN_SOFT, 26, 11, RUST, \"&#9650;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    if S.setup and not placeholder then\n      chip(\"del_\" .. i, \"uiRowBtn\", BTN_SOFT, 26, 11, RUST, \"&#215;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    add('</HorizontalLayout>')\n  end\n\n  -- footer\n  add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\" childForceExpandWidth=\"false\">')\n  if #S.rows > 0 and not fullTurnCoverage() then\n    add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"84\" ' .. BTN_GOLD\n      .. ' text=\"END TURN\" onClick=\"uiEndTurn\"/>')\n  end\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"66\" ' .. BTN_SOFT .. ' text=\"EXPORT\" onClick=\"uiExport\"/>')\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"56\" ' .. (S.setup and BTN_GOLD or BTN_SOFT)\n    .. ' text=\"' .. (S.setup and \"DONE\" or \"EDIT\") .. '\" onClick=\"uiSetup\"/>')\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"52\" '\n    .. ((S.overlay == \"info\") and BTN_GOLD or BTN_SOFT) .. ' text=\"INFO\" onClick=\"uiInfo\"/>')\n  -- The export result goes to the RIGHT of INFO, in bold. It sat on the left for one build and that\n  -- shoved every button along when it appeared: this row is childForceExpandWidth=\"false\", so a\n  -- flexible element added BEFORE the buttons takes its width out of them. After INFO there is\n  -- nothing but the credit to share with, so the buttons never move.\n  if S.lastExport ~= \"\" then\n    add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleLeft\"'\n      .. ' flexibleWidth=\"1\"' .. NOClick .. '>&#160;&#160;' .. S.lastExport .. '</Text>')\n  end\n  -- THE CREDIT IS GONE FROM THE SHEET. It reads \"by MrDrouf v<n>\" on the setup board's top right\n  -- corner instead, once for the whole mod -- the maintainer, 2026-09-07. What stays is an empty\n  -- flexible cell: the row is childForceExpandWidth=\"false\", so something after the buttons has to\n  -- soak up the leftover width or the export text starts shoving them along.\n  add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n  add('</HorizontalLayout>')\n\n  add('</VerticalLayout>')\n\n  -- overlays float over the rows, so the sheet never changes size\n  local PICK_DARK = 'colors=\"#57402A|' .. RUST .. '|' .. GOLD .. '|#00000000\"'\n  if S.setup and S.overlay == \"picker\" then\n    -- character chips flow in rows of six so long names never wrap; the\n    -- panel is pinned by its TOP edge, so selecting a faction only grows\n    -- it downward - nothing shifts or recenters\n    -- the Eyrie is excluded: its leader is chosen in play, never in the\n    -- draft, so an unpicked Eyrie has no leader options to note (captains\n    -- and vagabond characters ARE distinct unpicked cards)\n    local extra = 0\n    for _, fac in ipairs(ROSTER) do\n      local opts = (S.unpicked[fac] == true and fac ~= \"Eyrie\")\n        and variantOptions(fac) or nil\n      if opts then extra = extra + math.ceil(#opts / 6) end\n    end\n    local baseH = 118\n    local topY = math.max(8, math.floor((H - baseH) / 2))\n    add('<Panel width=\"' .. (W - 80) .. '\" height=\"' .. (baseH + extra * 30)\n      .. '\" rectAlignment=\"UpperCenter\" offsetXY=\"0 -' .. topY .. '\"'\n      .. ' color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"10 10 10 10\" spacing=\"6\" childForceExpandHeight=\"false\">')\n    for half = 1, 2 do\n      add('<HorizontalLayout preferredHeight=\"46\" spacing=\"5\">')\n      local from = (half - 1) * 7 + 1\n      for ri = from, math.min(from + 6, #ROSTER) do\n        local fac = ROSTER[ri]\n        local sel = (S.unpicked[fac] == true)\n        chip(\"pick_\" .. ri, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK,\n          0, 12, sel and INKTXT or PARCH, esc(fac))\n      end\n      if half == 2 then\n        chip(\"pkdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n      end\n      add('</HorizontalLayout>')\n    end\n    for fi, fac in ipairs(ROSTER) do\n      local opts = variantOptions(fac)\n      if S.unpicked[fac] == true and fac ~= \"Eyrie\" and opts then\n        local chosen = {}\n        for w in (S.unpickedVar[fac] or \"\"):gmatch(\"[^,]+\") do\n          chosen[w:match(\"^%s*(.-)%s*$\")] = true\n        end\n        for from = 1, #opts, 6 do\n          add('<HorizontalLayout preferredHeight=\"24\" spacing=\"4\">')\n          add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"64\"'\n            .. ' alignment=\"MiddleRight\"' .. NOClick .. '>'\n            .. (from == 1 and (esc(fac) .. ':') or ' ') .. '</Text>')\n          for ci2 = from, math.min(from + 5, #opts) do\n            chip(\"uv_\" .. fi .. \"_\" .. ci2, \"uiRowBtn\",\n              chosen[opts[ci2]] and BTN_GOLD or PICK_DARK, 0, 10,\n              chosen[opts[ci2]] and INKTXT or PARCH, esc(opts[ci2]))\n          end\n          add('</HorizontalLayout>')\n        end\n      end\n    end\n    add('</VerticalLayout></Panel>')\n  elseif S.overlay == \"info\" then\n    add('<Panel width=\"' .. (W - 110) .. '\" height=\"430\" color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"20 20 14 10\" spacing=\"3\">')\n    local function section(t, h, b, last)\n      add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredHeight=\"17\"'\n        .. ' alignment=\"MiddleLeft\"' .. NOClick .. '>' .. t .. '</Text>')\n      add('<Text fontSize=\"11\" color=\"' .. PARCH .. '\" preferredHeight=\"' .. h .. '\"'\n        .. ' alignment=\"UpperLeft\"' .. NOClick .. '>' .. b .. '</Text>')\n      if not last then\n        add('<Panel preferredHeight=\"1\" color=\"#C9A05C50\"' .. NOClick .. '/>')\n      end\n    end\n    section(\"SCORES\", 30,\n      \"Read automatically from VP markers. A settled marker on a fox, mouse, rabbit or bird Dominance card records turn and suit and offers dom win. With no same-faction marker on the score track this is standard dominance and freezes at -; with a second marker still on the track it is Brazen Demagogue and keeps scoring. Removing the card marker cancels either kind. A track marker reaching 30 ends the game.\")\n    section(\"TURNS\", 44,\n      \"Everything runs automatically once the TTS turn order is set and every faction has its seated player: each turn pass records the finishing faction by itself. Without that, END TURN records the highlighted faction. A lock always writes the highlighted round column, overwriting whatever it holds.\")\n    section(\"EDIT\", 44,\n      \"Correct anything: scores (click a cell), the round (click a column number), whose turn it is (click a portrait), faction order (&#9650;), player names, the Eyrie commander / Knaves captains / vagabond character (&#9660;), map, deck, game name and the unpicked faction.\")\n    section(\"EXPORT\", 44,\n      \"Writes the game as JSON to the TTS Notebook, tab &#8220;\" .. NOTEBOOK_TAB .. \"&#8221; &#8211; open the Notebook at the top of the screen, click that tab, Ctrl+A, Ctrl+C. Set a webhook under EDIT &#8594; DISCORD and the same record is posted there too; the footer then reads sent to Discord. One record either way, never two.\")\n    section(\"CRAFT\", 44,\n      \"Watches the map's item supply. An item taken from it and placed by a faction's board is recorded as crafted that round, with its picture on the round's score cell. Returning an item to the supply cancels the craft. In EDIT, the ITEMS button corrects or adds crafts: click T# to pick the round, &#215; removes, + adds. Turning CRAFT off hides all crafts, exports included.\")\n    section(\"RESET\", 16,\n      \"Clears the sheet for a new game and re-detects map, deck, seats and markers.\", true)\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\" childForceExpandWidth=\"false\">')\n    add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"80\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  elseif S.setup and S.overlay == \"game\" then\n    add('<Panel width=\"' .. (W - 420) .. '\" height=\"66\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"12 12 12 12\" spacing=\"6\">')\n    add('<Text fontSize=\"13\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"90\"'\n      .. ' alignment=\"MiddleRight\"' .. NOClick .. '>game name</Text>')\n    add('<InputField id=\"mt_game\" fontSize=\"13\" flexibleWidth=\"1\"'\n      .. ' colors=\"#F9E6BB|#FFFFFF|#FFFFFF|#00000000\" textColor=\"' .. INKTXT\n      .. '\" onValueChanged=\"uiLiveEdit\" text=\"' .. fieldText(S.meta.game)\n      .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"map\" then\n    add('<Panel width=\"' .. (W - 200) .. '\" height=\"64\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"10 10 10 10\" spacing=\"5\">')\n    for mi, m in ipairs(MAPS) do\n      local sel = (S.meta.map == m)\n      chip(\"map_\" .. mi, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK, 0, 12,\n        sel and INKTXT or PARCH, esc(m))\n    end\n    chip(\"mpdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"deck\" then\n    add('<Panel width=\"' .. (W - 200) .. '\" height=\"64\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"10 10 10 10\" spacing=\"5\">')\n    for di, d in ipairs(DECKS) do\n      local sel = (S.meta.deck == d)\n      chip(\"deck_\" .. di, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK, 0, 12,\n        sel and INKTXT or PARCH, esc(d))\n    end\n    chip(\"dkdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"var\" then\n    local row = S.rows[S.varRow]\n    local opts = row and variantOptions(row.fac) or nil\n    if row and opts then\n      local chosen = {}\n      for w in (row.variant or \"\"):gmatch(\"[^,]+\") do\n        chosen[w:match(\"^%s*(.-)%s*$\")] = true\n      end\n      add('<Panel width=\"' .. (W - 140) .. '\" height=\"118\" color=\"' .. WALNUT .. '\">')\n      add('<VerticalLayout padding=\"10 10 10 10\" spacing=\"6\" childForceExpandHeight=\"false\">')\n      add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredHeight=\"18\"' .. NOClick .. '>'\n        .. esc(row.fac) .. ' &#8211; pick the character(s)</Text>')\n      for half = 1, 2 do\n        add('<HorizontalLayout preferredHeight=\"34\" spacing=\"4\">')\n        local from = (half - 1) * 6 + 1\n        for oi = from, math.min(from + 5, #opts) do\n          chip(\"vc_\" .. oi, \"uiRowBtn\", chosen[opts[oi]] and BTN_GOLD or PICK_DARK,\n            0, 10, chosen[opts[oi]] and INKTXT or PARCH, esc(opts[oi]))\n        end\n        if half == 2 then\n          chip(\"vcdone\", \"uiOverlayClose\", BTN_GOLD, 0, 11, INKTXT, \"DONE\")\n        end\n        add('</HorizontalLayout>')\n      end\n      add('</VerticalLayout></Panel>')\n    end\n  elseif S.setup and S.experimental and S.overlay == \"craft\" then\n    -- pinned by the top edge like the picker: opening the round or add row\n    -- grows the panel downward without shifting what is already there\n    local baseH = 64 + #S.rows * 32\n    local hh = baseH + ((S.craftAdd or S.craftPick) and 30 or 0)\n    local topY = math.max(8, math.floor((H - baseH) / 2))\n    add('<Panel width=\"' .. (W - 120) .. '\" height=\"' .. hh\n      .. '\" rectAlignment=\"UpperCenter\" offsetXY=\"0 -' .. topY .. '\"'\n      .. ' color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"10 10 8 8\" spacing=\"4\" childForceExpandHeight=\"false\">')\n    add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredHeight=\"16\"'\n      .. ' alignment=\"MiddleLeft\"' .. NOClick\n      .. '>CRAFTED ITEMS &#8211; click T# to set the round, &#215; removes, + adds</Text>')\n    for ci3, row in ipairs(S.rows) do\n      add('<HorizontalLayout preferredHeight=\"28\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>' .. esc(row.fac) .. '</Text>')\n      for k, c in ipairs(row.crafts or {}) do\n        if c.img and c.img ~= \"\" then\n          add('<Panel preferredWidth=\"20\"' .. NOClick .. '><Image image=\"it' .. urlTail(c.img)\n            .. '\" width=\"18\" height=\"18\"' .. NOClick .. '/></Panel>')\n        end\n        add('<Text fontSize=\"11\" color=\"' .. PARCH .. '\" preferredWidth=\"56\" alignment=\"MiddleLeft\"'\n          .. NOClick .. '>' .. esc(c.item) .. '</Text>')\n        local selT = S.craftPick ~= nil and S.craftPick.i == ci3 and S.craftPick.k == k\n        chip(\"cfr_\" .. ci3 .. \"_\" .. k, \"uiCraftBtn\", selT and BTN_GOLD or PICK_DARK, 32, 10,\n          selT and INKTXT or PARCH, \"T\" .. tostring(c.r or \"?\"))\n        chip(\"cfx_\" .. ci3 .. \"_\" .. k, \"uiCraftBtn\", PICK_DARK, 24, 10, PARCH, \"&#215;\")\n        add('<Text preferredWidth=\"4\"' .. NOClick .. '> </Text>')\n      end\n      chip(\"cfadd_\" .. ci3, \"uiCraftBtn\", (S.craftAdd == ci3) and BTN_GOLD or PICK_DARK, 26, 12,\n        (S.craftAdd == ci3) and INKTXT or PARCH, \"+\")\n      add('</HorizontalLayout>')\n    end\n    if S.craftPick ~= nil then\n      add('<HorizontalLayout preferredHeight=\"26\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"11\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>round:</Text>')\n      for r2 = 1, math.max(1, S.cols or 10) do\n        chip(\"cfpick_\" .. r2, \"uiCraftBtn\", PICK_DARK, 34, 10, PARCH, \"T\" .. r2)\n      end\n      add('</HorizontalLayout>')\n    end\n    if S.craftAdd ~= nil and S.rows[S.craftAdd] ~= nil then\n      add('<HorizontalLayout preferredHeight=\"26\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"11\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>add:</Text>')\n      for k, nm in ipairs(ITEM_NAMES) do\n        chip(\"cfnew_\" .. k, \"uiCraftBtn\", PICK_DARK, 74, 10, PARCH, esc(nm))\n      end\n      add('</HorizontalLayout>')\n    end\n    add('<HorizontalLayout preferredHeight=\"26\" spacing=\"6\" childForceExpandWidth=\"false\">')\n    add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n    add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  elseif S.setup and S.overlay == \"discord\" then\n    add('<Panel width=\"' .. (W - 160) .. '\" height=\"118\" color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"12 12 10 10\" spacing=\"6\">')\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\">')\n    add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"72\" alignment=\"MiddleRight\"' .. NOClick .. '>webhook</Text>')\n    add('<InputField id=\"mt_hook\" fontSize=\"13\" flexibleWidth=\"1\" colors=\"#F9E6BB|#FFFFFF|#FFFFFF|#00000000\"'\n      .. ' textColor=\"' .. INKTXT .. '\" placeholder=\"Discord webhook URL\"'\n      .. ' text=\"' .. fieldText(S.meta.hook) .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('</HorizontalLayout>')\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\">')\n    add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"72\" alignment=\"MiddleRight\"' .. NOClick .. '>thread</Text>')\n    add('<InputField id=\"mt_thread\" fontSize=\"13\" flexibleWidth=\"1\" colors=\"#F9E6BB|#FFFFFF|#FFFFFF|#00000000\"'\n      .. ' textColor=\"' .. INKTXT .. '\" placeholder=\"thread link (optional)\"'\n      .. ' text=\"' .. fieldText(S.meta.thread) .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  end\n\n  add('</Panel>')\n  self.UI.setXml(table.concat(x))\nend\n\n---------------------------------------------------------------- persistence --\nfunction onSave()\n  return JSON.encode(S)\nend\n\n-- Throw away everything known about seats and start again: the record RTT pushed, and every row's\n-- hand-set colour. The next poll re-reads RTT's record, or falls back to hand-zone geometry on a table\n-- with no RTT. This is the escape hatch for a sheet that has somehow ended up with the wrong rows --\n-- there is no per-row colour picker, because adding one costs 26px of sheet width and the slab size\n-- is pinned by the RTT bake.\nfunction uiReseat()\n  S.rttSeats = nil\n  for _, row in ipairs(S.rows) do row.colorAuto = nil; row.color = nil end\n  logev(\"reseat\")\n  broadcastToAll(\"Box score: seats will be re-detected.\", {0.9, 0.8, 0.5})\n  rebuildUI()\nend\n\nfunction onLoad(saved)\n  local loadedState = false\n  if saved ~= nil and saved ~= \"\" then\n    local ok, d = pcall(function() return JSON.decode(saved) end)\n    if ok and d ~= nil and d.rows ~= nil then S = d; loadedState = true end\n  end\n  S.meta = S.meta or { map = \"\", deck = \"\", hook = \"\", thread = \"\" }\n  S.meta.deck = S.meta.deck or \"\"\n  -- old builds stored pre-escaped text; normalize once so it can never\n  -- round-trip into the display again\n  S.meta.deck = S.meta.deck:gsub(\"&amp;\", \"+\"):gsub(\"&#38;\", \"+\"):gsub(\"&\", \"+\")\n  S.meta.map = (S.meta.map or \"\"):gsub(\"&amp;\", \"&\"):gsub(\"&#38;\", \"&\")\n  S.meta.hook = S.meta.hook or \"\"\n  S.meta.thread = S.meta.thread or \"\"\n  S.meta.game = S.meta.game or \"\"\n  -- a webhook baked into GMNotes (by build.py) is the default\n  if S.meta.hook == \"\" then\n    local gm = self.getGMNotes() or \"\"\n    if gm:match(\"^https?://\") then S.meta.hook = gm:gsub(\"%s+$\", \"\") end\n  end\n  S.undo = S.undo or {}\n  S.log = S.log or {}\n  S.unpicked = S.unpicked or {}\n  S.unpickedVar = S.unpickedVar or {}\n  S.varRow = S.varRow or 1\n  S.experimental = S.experimental or false\n  S.itemImgs = S.itemImgs or {}\n  S.turns = S.turns or 0\n  -- LIVE TURN STATE DOES NOT SURVIVE A RELOAD, because it describes a moment, not a game.\n  --   turnHolder is the colour holding the turn RIGHT NOW; it arms the duplicate-pass guard, so a\n  --   value from before the reload made the first pass after loading look stale and swallowed it.\n  --   turnStart is an absolute os.time. Kept across a save it measured the previous turn from\n  --   whenever the game was put away -- a turn \"lasting\" as long as the save sat on disk, printed\n  --   without a cap on minutes.\n  -- Both are re-established by the first real pass; the locks, the rounds and the names all persist\n  -- as before.\n  S.turnHolder = nil\n  S.turnStart = now()\n  -- A game saved before the round became explicit carries only S.turns and the locks. Recover the\n  -- round from the locks themselves -- the highest column anybody actually filled -- rather than from\n  -- the old division, which is the thing that was wrong. Each row's lastRound is seeded the same way,\n  -- so a resumed game keeps locking exactly where it left off.\n  if S.round == nil then\n    local maxr = 0\n    for _, row in ipairs(S.rows or {}) do\n      local last = 0\n      for r = 1, #(row.locks or {}) do\n        if row.locks[r] ~= nil and row.locks[r] ~= -1 then last = r end\n      end\n      row.lastRound = (last > 0) and last or nil\n      if last > maxr then maxr = last end\n    end\n    S.round = math.max(1, maxr)\n  end\n  S.active = S.active or 1\n  if S.active > math.max(1, #S.rows) then S.active = 1 end\n  local domWinner = nil\n  for _, row in ipairs(S.rows) do\n    row.locks = row.locks or {}\n    row.edits = row.edits or {}\n    row.crafts = row.crafts or nil\n    row.score = row.score or -1\n    row.player = row.player or \"\"\n    if row.dom ~= nil then\n      row.dom.turn = math.max(1, math.floor(tonumber(row.dom.turn) or 1))\n      row.dom.round = math.max(1, math.floor(tonumber(row.dom.round) or 1))\n      row.dom.suit = tostring(row.dom.suit or \"\"):lower()\n      row.dom.score = tonumber(row.dom.score) or row.score\n      row.dom.won = row.dom.won == true\n      local brazen = row.dom.kind == \"brazen_demagogue\" or row.dom.frozen == false\n      row.dom.kind = brazen and \"brazen_demagogue\" or \"standard\"\n      row.dom.frozen = not brazen\n      if row.dom.markerGuid == \"\" then row.dom.markerGuid = nil end\n      if row.dom.won then domWinner = row.fac end\n    end\n  end\n  if domWinner ~= nil then\n    S.winner = domWinner\n    S.winnerReason = \"dominance\"\n    S.winnerLock = nil\n  elseif S.winner ~= nil and S.winnerReason == nil then\n    S.winnerReason = \"score\"\n  end\n  S.cols = S.cols or 10\n  S.scaleMode = S.scaleMode or 1\n  if S.sizePct == nil then\n    local oldIdx = math.floor(tonumber(S.sizeIdx) or 2)\n    local oldMul = LEGACY_SIZE_MULS[oldIdx] or LEGACY_BASE_MUL\n    S.sizePct = math.floor(oldMul / LEGACY_BASE_MUL * 10 + 0.5) * 10\n  end\n  -- A brand-new RTT spawn has no LuaScriptState, so recover the percentage\n  -- remembered by the prior copy.  A real saved state always wins.\n  if not loadedState then\n    local ok, remembered = pcall(function()\n      return Global.getVar(\"RTT_BOXSCORE_SIZE_PCT\")\n    end)\n    if ok and tonumber(remembered) ~= nil then S.sizePct = tonumber(remembered) end\n  end\n  S.sizePct = clampSizePct(S.sizePct)\n  S.sizeIdx = nil\n  rememberSizePct()\n  S.setup = S.setup or false\n  S.overlay = nil\n  S.lastExport = S.lastExport or \"\"\n\n  self.addContextMenuItem(\"setup / done\", uiSetup, false)\n  self.addContextMenuItem(\"reset box score\", uiReset, false)\n  self.addContextMenuItem(\"hide / show\", uiHide, false)\n  self.addContextMenuItem(\"export\", uiExport, false)\n  self.addContextMenuItem(\"flip track\", uiFlip, false)\n  self.addContextMenuItem(\"spin panel\", uiSpin, false)\n  self.addContextMenuItem(\"size +10%\", uiSizeUp, false)\n  self.addContextMenuItem(\"size -10%\", uiSizeDown, false)\n  self.addContextMenuItem(\"panel scale mode\", uiScaleMode, false)\n  self.addContextMenuItem(\"diagnose\", uiDiag, false)\n  self.addContextMenuItem(\"re-detect seats\", uiReseat, false)\n\n  -- BUILD AS SOON AS THE MAP IS THERE, not after a flat two seconds.\n  --\n  -- findTrack reads the printed 0-30 score track off the map board's snap points, so it needs the map\n  -- to exist. That was waited for with Wait.time(..., 2), which left the sheet BLANK for two seconds\n  -- on every spawn -- maintainer, 2026-09-06: \"do you know why landmarks and also the boxscore takes\n  -- a bit of time to load?\" -- and was still only a guess: on a slow load two seconds is too SHORT,\n  -- and the track then stays unfound until the first poll a further 1.2s later.\n  --\n  -- Polled every 5 frames, not every frame: findTrack walks every object on the table asking for snap\n  -- points and runs detectTrackOn over the plausible ones, which is not cheap. RTT spawns this sheet\n  -- three frames after the map is requested, so the usual case is one or two looks. After ~5s it\n  -- gives up and builds anyway; the sheet is then live and poll picks the track up when it appears.\n  local tries = 0\n  local function build()\n    tries = tries + 1\n    findTrack()\n    if TRACK == nil and tries < 60 then Wait.frames(build, 5) return end\n    for _, row in ipairs(S.rows) do\n      local m = findMarker(row)\n      if m then row.iconUrl = markerImage(m) end\n    end\n    refreshAssets()\n    rebuildUI()\n    Wait.time(poll, POLL_SECONDS, -1)\n  end\n  Wait.frames(build, 1)\nend\n","LuaScriptState":"","XmlUI":""}]====]
RTT_BOXSCORE_TAG = "RTT BoxScore"
-- The battle mat, the box score, the clock and the counter are the SAME OBJECTS whatever map is down.
-- Maintainer, 2026-09-06: "when resetting a map for another map no need to reset battle mat boxscore
-- clock counter since they are the same objects." They used to be torn down and respawned on every
-- map build, which cost more than a flicker: rttSpawnBoxScore destructs the old sheet, so changing map
-- mid-session THREW AWAY the recorded game. They are spared by removeMapItems and only spawned when
-- actually missing; a new game still gets a fresh sheet, because rttNewGame drops it explicitly.
RTT_FIXTURE_TAG = "RTT Fixture"

-- BY TAG, NOT BY NAME. The clock and the counter ship with a BLANK Nickname, and TTS's getName()
-- returns the nickname -- so matching on "Digital_Clock" found nothing in the game and the panel could
-- not remove them: the maintainer got both on top of each other. The harness hid it, because the stub
-- falls back to the object's Name when the nickname is empty. Every fixture now carries its own tag.
RTT_TAG_CLOCK, RTT_TAG_COUNTER, RTT_TAG_PANEL, RTT_TAG_MAT =
  "RTT Clock", "RTT Counter", "RTT Panel", "RTT Mat"

function rttFixture(tag)
  local t = getObjectsWithTag(tag)
  return (t ~= nil and #t > 0) and t[1] or nil
end

RTT_MAP_BTNS  = { "rttPickMap1", "rttPickMap2", "rttPickMap3", "rttPickMap4", "rttPickMap5", "rttPickMap6" }
RTT_DECK_BTNS = { "rttPickDeck1", "rttPickDeck2", "rttPickDeck3" }
-- the six board positions (from the old 6-board spawner)
RTT_POS = { { 52, -46 }, { -52, -46 }, { 52, 46 }, { -52, 46 }, { 0, -46 }, { 0, 46 } }
-- counterclockwise seating: P4 sits across from P1 (pos3 vs pos1), P3 across from P2
-- (pos4 vs pos2). RTT_POS: 1=(52,-46) 2=(-52,-46) 3=(52,46) 4=(-52,46).
RTT_LAYOUT = {
  [1] = { 1 }, [2] = { 1, 3 }, [3] = { 1, 2, 3 },
  [4] = { 1, 2, 4, 3 }, [5] = { 1, 5, 2, 4, 3 }, [6] = { 1, 2, 5, 6, 4, 3 },
}

-- hand transform for each board position (base handPositions/handRotations, by x,z sign): the
-- player's hand sits just behind their board (z=±64 behind the board at z=±46).
RTT_SEAT_HAND = {
  { pos = { 52, 14.62, -64 }, rot = { 0, 0, 0 } },     -- pos1 (52,-46)
  { pos = { -52, 14.62, -64 }, rot = { 0, 0, 0 } },    -- pos2 (-52,-46)
  { pos = { 52, 14.62, 64 }, rot = { 0, 180, 0 } },    -- pos3 (52,46)
  { pos = { -52, 14.62, 64 }, rot = { 0, 180, 0 } },   -- pos4 (-52,46)
  { pos = { 0, 14.62, -64 }, rot = { 0, 0, 0 } },      -- pos5 (0,-46)
  { pos = { 0, 14.62, 64 }, rot = { 0, 180, 0 } },     -- pos6 (0,46)
}
RTT_SEATS = {}          -- [seat] = { board=obj, color=<colour|nil>, pos={x,z}, hand=<RTT_SEAT_HAND entry> }
-- HOW MANY PICKS HAVE HAPPENED. A seat records which press created it (seat.picker, seat.pickedAt),
-- which is what the gizmo needs and what a separate table used to hold: the first faction you pick
-- takes your colour and every later pick is handed a FREE one, so seat COLOUR cannot answer "which
-- faction is mine" -- "I am changing seats by selecting new factions but the gizmo numpad 1 does not
-- seem to understand that" (2026-09-07).
--
-- It lives on the seat now rather than beside it. One record answering every question about a seat is
-- the point: it persists with the seats, it is cleared with the seats, and it cannot drift from them.
RTT_PICK_N = 0
-- WHICH SEAT A SELECTOR BOARD BELONGS TO, and which board a seat has. These were two tables beside
-- the seats, each indexing by a different key a fact the seat already holds in s.board. Neither
-- survived a save, and s.board is deliberately not restored (TTS re-creates the objects with new
-- guids), so a reload in the middle of the faction pick left BOTH empty: the pick handler found no
-- seat and returned, rttShowFactions skipped every seat and never re-lit the menus, and the draft
-- could not be finished while the record still said the game was live.
--
-- Derived from the seats now, and re-attached from the table when the record has lost the handle: a
-- selector board standing at a seat's position IS that seat's board. That makes the pick survive a
-- reload, which it never has.
-- Is this object standing at that seat? Twelve units, the same tolerance rttSeatAt matches a board to
-- a seat with, so "which seat is this board at" has one answer everywhere.
local function rttAtSeat(obj, seat)
  if obj == nil or seat == nil or seat.pos == nil then return false end
  local p = nil
  pcall(function() p = obj.getPosition() end)
  if p == nil then return false end
  local dx, dz = p.x - seat.pos[1], p.z - seat.pos[2]
  return dx * dx + dz * dz <= 144
end

-- THE ONE PLACE A SEAT IS GIVEN ITS BOARD. Both lookups below lost the handle in the same way and
-- re-found it in the same way, and I wrote that search out twice -- which is exactly the drift this
-- whole pass is about.
local function rttAttachBoard(seat, obj)
  if seat == nil or obj == nil then return nil end
  seat.board = obj
  return obj
end

function rttSeatOfBoard(guid)
  if guid == nil or guid == "" then return nil end
  for i, s in ipairs(RTT_SEATS or {}) do
    local g = nil
    if s ~= nil and s.board ~= nil then pcall(function() g = s.board.getGUID() end) end
    if g == guid then return i end
  end
  local obj = getObjectFromGUID(guid)
  if obj == nil then return nil end
  for i, s in ipairs(RTT_SEATS or {}) do
    if rttAtSeat(obj, s) then rttAttachBoard(s, obj) return i end
  end
  return nil
end

-- The selector board at the seat wearing this colour, re-found from the table if the handle is gone.
function rttCloneFor(color)
  if color == nil or color == "" then return nil end
  for _, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.color == color then
      if s.board ~= nil then return s.board end
      for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do
        if rttAtSeat(o, s) then return rttAttachBoard(s, o) end
      end
      return nil
    end
  end
  return nil
end

-- ==== seat-by-turn-order-card tables (RTT seating restore) ==================
RTT_SETUP_COLORS   = { "Red", "Yellow", "Orange", "Teal", "Green", "Brown" }   -- base setupColors: seat N -> colour N
RTT_HAND_SCALE     = { 20, 6, 4 }                                              -- base handScale (RTT had dropped it)
RTT_CARDID_FOR_N   = { 800, 801, 802, 805, 806 }                              -- seat N -> "Player N" order-card CardID
RTT_ORDER_CARD_NUM = { [800]=1, [801]=2, [802]=3, [805]=4, [806]=5 }           -- inverse: order-card CardID -> its number

-- ==== THE SEAT RECORD ======================================================
-- ONE record answers "who sits where, in what colour, playing what", and it is written when
-- something actually happens -- never re-derived on a timer, never guessed from geometry.
--
-- What this replaced got the mapping WRONG, deterministically, in every 4- and 5-player draft
-- (tester, 2026-09-05: "it's assuming player 4 is player 3 since they were able to spawn p3
-- warriors with 0"). Two different numberings existed: RTT_POS numbers the six board SPOTS, and
-- RTT_SETUP_COLORS was indexed by PLAYER NUMBER, with RTT_LAYOUT mapping one to the other.
-- rttPlaceFaction found the nearest SPOT and then indexed the colour table with that spot number,
-- never undoing RTT_LAYOUT -- so the published colour was right only where the layout happens to be
-- the identity (1 and 3 players) and wrong at 2, 4, 5 and 6. Both consumers read that note: the
-- gizmo to decide which faction you control, and the box score, which treats it as authoritative and
-- marks the colour used so its own geometry cannot repair it.
--
-- The fix is not a corrected lookup, it is deleting the lookup. A seat's position is READ from where
-- its board actually stands; nothing is matched against a table of expected spots. That also makes
-- the manual paths work for free: a Faction Select board dragged anywhere is just a seat at that
-- position, not a special case.
--
-- WHY COLOUR IS STORED, and is the seat rather than a label on a person (maintainer, 2026-09-05):
-- in TTS the HAND belongs to the COLOUR, not to the player -- so do the cards in it, and so does the
-- slot in Turns.order. Changing colour is therefore not relabelling somebody, it is picking up a
-- different seat, with different cards. That is exactly why a disconnect/reconnect works: the player
-- comes back, takes their colour again, and their hand, their cards and their turn slot are all
-- still there. So the seat owns the colour, and the mod never chases a player who moves.

-- Clockwise around the table from the BOTTOM-RIGHT corner, which is +x/-z = RTT_POS[1]. This is the
-- single definition of turn order (maintainer: "turn order is decided clockwise by the position from
-- the first player who's the closest to the bottom right corner"). Computing it from real positions
-- rather than tabulating it means it is right for any number of seats and for boards placed by hand
-- -- and it silently fixes RTT_LAYOUT[6], which is NOT clockwise ({1,2,5,6,4,3} where clockwise is
-- {1,5,2,4,6,3}); that entry is unreachable today (no button asks for 6 seats) but was a trap.
-- TTS runs Lua 5.2, where math.atan2 exists; the test harness is 5.5, where it was removed.
local function rttAtan2(y, x)
  if math.atan2 ~= nil then return math.atan2(y, x) end
  return math.atan(y, x)
end

function rttSeatClockwise(x, z)
  local a = rttAtan2(RTT_POS[1][2], RTT_POS[1][1]) - rttAtan2(z, x)
  local two = 2 * math.pi
  a = a % two
  if a < 0 then a = a + two end
  return a
end

-- seat indices in turn order. Ties (two boards at the same angle) fall back to the index so the
-- order is total and stable -- an unstable comparator makes table.sort's result undefined.
function rttSeatOrderIdx()
  local idx = {}
  for i, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.pos ~= nil then idx[#idx + 1] = i end
  end
  local ang = {}
  for _, i in ipairs(idx) do ang[i] = rttSeatClockwise(RTT_SEATS[i].pos[1], RTT_SEATS[i].pos[2]) end
  table.sort(idx, function(a, b)
    if math.abs(ang[a] - ang[b]) > 1e-9 then return ang[a] < ang[b] end
    return a < b
  end)
  return idx
end

-- Find the seat whose board stands at (x,z), or make one there. The tolerance is generous because
-- the six spawn spots are >= 92 apart and a selector board is wide: anything within 12 is the same
-- seat, anything else is a new one. This is what lets the draft, the 4/5-player setup boards and a
-- single Faction Select board dragged to an arbitrary spot all travel the same code path.
-- `faction` matters because A SEAT HOLDS EXACTLY ONE FACTION. The manual Faction Select board is not
-- destroyed when you pick on it, so several factions can be placed from the same spot; matching on
-- position alone would have let the second overwrite the first and lose a whole seat.
function rttSeatAt(x, z, create, faction)
  RTT_SEATS = RTT_SEATS or {}
  local best, bd = nil, nil
  for i, s in ipairs(RTT_SEATS) do
    if s ~= nil and s.pos ~= nil
       and (faction == nil or s.faction == nil or s.faction == faction) then
      local d = (s.pos[1] - x) ^ 2 + (s.pos[2] - z) ^ 2
      if bd == nil or d < bd then best, bd = i, d end
    end
  end
  if best ~= nil and bd <= 144 then return best end
  if not create then return nil end
  RTT_SEATS[#RTT_SEATS + 1] = { board = nil, pos = { x, z }, color = nil, faction = nil, owner = nil,
                                hand = rttHandForPos(x, z) }
  return #RTT_SEATS
end

-- The hand transform for a seat at (x,z). The six spawn spots have baked transforms (RTT_SEAT_HAND);
-- a board somewhere else gets one derived the same way the baked ones were -- 18 further out from the
-- table on its own side, facing in.
function rttHandForPos(x, z)
  for i, p in ipairs(RTT_POS) do
    if (p[1] - x) ^ 2 + (p[2] - z) ^ 2 <= 144 then return RTT_SEAT_HAND[i] end
  end
  return { pos = { x, 14.62, z + ((z > 0) and 18 or -18) }, rot = { 0, (z > 0) and 180 or 0, 0 } }
end

-- A colour no human is sitting in and no other seat has taken. An empty seat still holds a faction
-- and still takes a turn, so it needs one; 10 colours against at most 6 seats means this cannot run
-- out. Deterministic order, so the same table always produces the same assignment.
-- A COLOUR THE REST OF THE SYSTEM CAN ACTUALLY MATCH. The audit read this as a live defect -- an
-- unclaimed seat handed Blue, Purple, Pink or White, colours the turn-card order does not use and the
-- sheet's own colour pass does not know, leaving that row unable to bind. IT WAS NOT ONE:
-- RTT_ALL_COLORS already begins with exactly the six seating colours, in the same order, so the walk
-- reached them first anyway. This changes no behaviour. It states the rule outright instead of
-- leaving it resting on the order of a list nobody would think to keep, and a test pins it.
function rttFreeSeatColor()
  local taken = {}
  pcall(function()
    for _, pl in ipairs(Player.getPlayers()) do
      if pl.color ~= nil then taken[pl.color] = true end
    end
  end)
  for _, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.color ~= nil then taken[s.color] = true end
  end
  for _, c in ipairs(RTT_SETUP_COLORS) do
    if not taken[c] then return c end
  end
  for _, c in ipairs(RTT_ALL_COLORS) do
    if not taken[c] then return c end
  end
  return nil
end

-- THE ONE PLACE A SEAT'S COLOUR IS WRITTEN.
--
-- It was assigned in four: the draft's seating loop, the empty-seat filler beside it, the faction
-- pick, and the gap-filler below. Each carried its own version of the same two rules, and each was
-- the site of a bug -- at four players P3 and P4 held each other's colour in every game, and a manual
-- board placing two factions from one spot let the second silently take the first's colour, owner and
-- turn slot.
--
-- The rules, once:
--   * NO TWO SEATS SHARE A COLOUR. The colour owns the hand, the cards and the slot in Turns.order,
--     so a duplicate does not merely confuse a lookup, it hands one player another's cards.
--   * A SEAT THAT HAS ONE KEEPS IT unless the caller says otherwise. Reassigning takes a player's
--     hand away.
-- Returns the colour actually set, or nil if it refused.
-- WHO IS SITTING IN A COLOUR, asked in one place. Four separate loops over Player.getPlayers() were
-- asking it, each with its own idea of what counts -- seated or not, Grey and Black or not.
function rttPersonIn(color)
  if color == nil or color == "" then return nil end
  local who = nil
  pcall(function()
    for _, pl in ipairs(Player.getPlayers()) do
      if pl.color == color and pl.seated then who = pl.steam_name end
    end
  end)
  return who
end

-- THE ONE PLACE A SEAT'S OWNER IS WRITTEN. It was two: the draft's seating loop, which knows the name
-- it just seated, and the faction pick, which reads it off the colour that clicked. Refreshing rather
-- than filling a gap is the rule -- a seat kept the first name it ever saw, and the sheet PREFERS this
-- name over the live occupant, so a game finished by one player in another's seat was credited to
-- whoever had left. An empty name never overwrites a real one.
function rttSetSeatOwner(seat, name)
  if seat == nil or name == nil or name == "" then return seat and seat.owner or nil end
  seat.owner = name
  return name
end

function rttSetSeatColor(seat, color, replace)
  if seat == nil or color == nil or color == "" then return nil end
  if seat.color ~= nil and not replace then return seat.color end
  for _, o in ipairs(RTT_SEATS or {}) do
    if o ~= nil and o ~= seat and o.color == color then return nil end
  end
  seat.color = color
  return color
end

-- Give every seat a colour: the colour of the human sitting at it, or a free one if nobody is. Only
-- ever FILLS a gap -- a seat that already has a colour keeps it, because that colour owns the hand,
-- the cards and the turn slot, and reassigning it would take a player's cards away.
function rttBindSeatColors()
  for _, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.color == nil then rttSetSeatColor(s, rttFreeSeatColor()) end
  end
end

-- The canonical record, in turn order. This is what leaves the board: published to Globals for
-- anything that reads them and pushed straight at the box score.
function rttSeatRecord()
  local out = { run = RTT_RUN_ID or 0, seats = {} }
  for _, i in ipairs(rttSeatOrderIdx()) do
    local s = RTT_SEATS[i]
    -- TWO names, because they answer different questions.
    --   faction : the blueprint name, e.g. "Ranger". The gizmo needs it to find that faction's
    --             supply bag and warrior.
    --   key     : the name everything DOWNSTREAM knows the faction by, via rttFactionKey. A Vagabond
    --             is picked as a CHARACTER but scores as a FACTION -- its marker is "Vagabond VP",
    --             never "Ranger VP" -- so the box score's row is "Vagabond" and a record published
    --             under "Ranger" matches nothing on the sheet. Publishing the raw name is exactly
    --             the regression this comment exists to stop coming back.
    --   row     : what the SHEET calls it -- its VP marker's name minus " VP". The sheet's rows are
    --             short ("Marquise"), the key is long ("Marquise de Cat"), and the sheet bridged the
    --             two with a hand-written twelve-entry table of its own. A thirteenth faction, or a
    --             rename on either side, silently cost that seat its colour, its owner and its
    --             position -- with no error, because a missing bridge entry just means "no match".
    --             We already own the map that table duplicates (RTT_VP_SHORT), so we publish the
    --             answer instead of making the other end guess it.
    local key = s.key or ((s.faction ~= nil) and rttFactionKey(s.faction) or "")
    out.seats[#out.seats + 1] = {
      pos = { s.pos[1], s.pos[2] },
      color = s.color or "",
      faction = s.faction or "",
      key = key,
      row = (key ~= "") and ((rttVPName(key):gsub(" VP$", ""))) or "",
      owner = s.owner or "",
    }
  end
  return out
end

-- Publish. The three Globals stay because other objects (and older box-score bakes) read them, but
-- they are now WRITTEN FROM THE ONE RECORD instead of being three independently-derived guesses.
-- The push is what actually matters: the sheet stores what it is given and stops re-deriving.
function rttPublishSeats()
  local rec = rttSeatRecord()
  local pos, col, own = {}, {}, {}
  for _, e in ipairs(rec.seats) do
    local k = (e.key ~= nil and e.key ~= "") and e.key or e.faction
    if k ~= "" then
      pos[k] = { e.pos[1], e.pos[2] }
      if e.color ~= "" then col[k] = e.color end
      if e.owner ~= "" then own[k] = e.owner end
    end
  end
  pcall(function() Global.setVar("RTT_SEAT_POS", JSON.encode(pos)) end)
  pcall(function() Global.setVar("RTT_SEAT_COLOR", JSON.encode(col)) end)
  pcall(function() Global.setVar("RTT_SEAT_PLAYER", JSON.encode(own)) end)
  pcall(function() Global.setVar("RTT_SEAT_RECORD", JSON.encode(rec)) end)
  -- Fire-and-forget at the sheet. It may not exist yet (the box score spawns with the map, factions
  -- come later), which is why the sheet also PULLS this record on its own onLoad.
  -- As a JSON STRING, not a table: raw Lua tables do not cross object-script boundaries in TTS, which
  -- is the same reason the three mirrors above are strings.
  local enc = JSON.encode(rec)
  pcall(function()
    for _, o in ipairs(getObjectsWithTag(RTT_BOXSCORE_TAG)) do
      pcall(function() o.call("rttSeatPush", enc) end)
    end
  end)
end

function rttSpawnSelectors()
  for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do rttDestroyUI(o) end
  RTT_SEATS = {}
  local n = #RTT_ORDER                          -- the FIXED N seats (built in rttDealOrder)
  local layout = RTT_LAYOUT[n] or RTT_LAYOUT[4]
  for i = 1, n do
    local pi = layout[i] or i
    local p = RTT_POS[pi] or RTT_POS[1]
    local board = spawnObjectJSON({
      json = RTT_SELECTOR_JSON,
      position = { p[1], 11.56, p[2] },
      rotation = { 0, (p[2] > 0) and 180 or 0, 0 },
      callback_function = function(o) o.setLock(true) o.addTag(RTT_SELECTOR_TAG) end
    })
    -- pos is a COPY: `p` is RTT_POS[pi] itself, and a seat that aliased the spot table would
    -- corrupt it for every later game the moment anything wrote through s.pos.
    RTT_SEATS[i] = { board = board, color = nil, pos = { p[1], p[2] }, hand = RTT_SEAT_HAND[pi],
                     faction = nil, owner = nil }
  end
end

-- Seat by TURN-ORDER CARD. ONE shuffle sets the order; each player is assigned the seat matching
-- their card's number and handed the matching "Player N" card, so it lands in their own hand.
--
-- NOBODY IS RECOLOURED (maintainer, 2026-09-05: "players join the game, they can pick their color,
-- this should never be forced"). This used to copy the base mod's own seating: kick the whole table
-- to Grey, then changeColor everyone into RTT_SETUP_COLORS[seat]. In TTS the HAND -- and the cards in
-- it, and the slot in Turns.order -- belongs to the COLOUR, so forcing a colour takes a player's hand
-- away from them and hands it to whoever gets that colour next. What the draft actually needs to
-- assign is a SEAT, not a colour: the seat then takes the colour its player already has, and that
-- player's own hand zone is moved behind their board. Nothing is taken from anyone.
--
-- The kick is gone with it, and so is the stale-ref hazard that made it necessary: without a
-- changeColor, a Player ref captured before this loop is still valid afterwards.
function rttSeatPlayers()
  -- real humans. Grey and Black are the spectator seats in this mod and never play.
  local humans = {}
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then humans[#humans + 1] = p.steam_name end
  end
  -- Assign each human a RANDOM seat NUMBER out of ALL N seats, so the turn-order card is random for
  -- everyone -- including a lone tester, who previously always landed in seat 1 / "First Player".
  -- Seat NUMBER = each human's position in RTT_ORDER (the SINGLE shuffle done once in rttDealOrder,
  -- which also drives the Roster and box-score order). So the "Player N" turn-order card a person is
  -- dealt MATCHES the order they are shown in.
  local seatOf = {}                                      -- steam_name -> seat number
  for k, e in ipairs(RTT_ORDER or {}) do
    if e.name ~= nil and e.name ~= "" then seatOf[e.name] = k end
  end
  local usedSeat = {}
  for _, k in pairs(seatOf) do usedSeat[k] = true end
  local freeN = 1
  for _, name in ipairs(humans) do                       -- safety net: a human not found in RTT_ORDER
    if seatOf[name] == nil then
      while usedSeat[freeN] do freeN = freeN + 1 end
      seatOf[name] = freeN; usedSeat[freeN] = true
    end
  end
  -- THE SEAT'S COLOUR IS ITS TURN NUMBER. Maintainer, 2026-09-06: "Force color of seat to be color of
  -- turn card order. That means that when player are seated they change color; only affects the draft
  -- since that s the only time turn card order are dealt." So whoever is dealt "Player 1" is Red,
  -- "Player 2" Yellow, and so on down RTT_SETUP_COLORS: a player's colour states their turn order.
  --
  -- This reverses 2026-09-05 ("players join the game, they can pick their color, this should never be
  -- forced"), and the reason behind that rule still holds everywhere else -- in TTS the hand and the
  -- cards in it belong to the COLOUR, so forcing one mid-game takes a player's cards away. It is safe
  -- HERE and nowhere else, because seating runs before a single card is dealt, so every hand is empty
  -- at this moment. The manual path still never recolours anybody, which is what "only affects the
  -- draft" asks for.
  local want = {}                                        -- the players who have a seat, and its colour
  for _, p in ipairs(Player.getPlayers()) do
    local sN = seatOf[p.steam_name]
    if sN ~= nil then
      local seat = RTT_SEATS[sN]
      if seat ~= nil and seat.board ~= nil and seat.hand ~= nil then
        want[#want + 1] = { p = p, n = sN, name = p.steam_name, c = RTT_SETUP_COLORS[sN] }
      end
    end
  end
  -- TWO PHASES, because a straight swap cannot work: when Red must become Yellow while Yellow becomes
  -- Red, each changeColor is refused for a colour somebody still holds. Park everyone who is standing
  -- on a colour that is not theirs in Grey first -- the base mod's own kick-everyone-to-Grey trick --
  -- and then every target is free. Grey is this mod's spectator seat and holds any number of players.
  local target = {}
  for _, w in ipairs(want) do if w.c ~= nil then target[w.c] = true end end
  for _, p in ipairs(Player.getPlayers()) do
    local mine = nil
    for _, w in ipairs(want) do if w.name == p.steam_name then mine = w.c end end
    if p.color ~= "Grey" and p.color ~= "Black" and p.color ~= mine and target[p.color] then
      pcall(function() p.changeColor("Grey") end)
    end
  end
  for _, w in ipairs(want) do
    if w.c ~= nil and w.p.color ~= w.c then pcall(function() w.p.changeColor(w.c) end) end
  end

  local seated = {}                                      -- [seat N] = seat colour, for the deferred card
  for _, w in ipairs(want) do
    local seat  = RTT_SEATS[w.n]
    local color = w.c or w.p.color
    -- replace: the draft DOES reassign, deliberately -- seat N wears turn-card N's colour, and the
    -- players were parked in Grey a moment ago precisely so this can happen without a clash.
    rttSetSeatColor(seat, color, true)
    rttSetSeatOwner(seat, w.name)
    pcall(function()
      Player[color].setHandTransform(
        { position = seat.hand.pos, rotation = seat.hand.rot, scale = RTT_HAND_SCALE }, 1)
    end)
    seated[w.n] = color
  end
  -- A seat nobody is sitting in takes its own turn number's colour as well, so the scheme reads the
  -- same all the way round the table instead of breaking at the first empty chair.
  for i, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.color == nil then rttSetSeatColor(s, RTT_SETUP_COLORS[i]) end
  end
  -- Seats nobody is sitting in still hold a faction and still take a turn, so they need a colour no
  -- human holds. Done AFTER the humans, so a free colour is never one somebody is wearing.
  rttBindSeatColors()

  -- SWITCH THE TTS TURN SYSTEM ON, with the real seat order.
  -- Nothing in this mod ever did. The scene ships Turns.Enable = false and onLoad only assigns a
  -- hardcoded Turns.order; Turns.enable was never set anywhere in 4,800 lines. So the turn system was
  -- off in every game, which is why the box score sat permanently in manual mode showing END TURN --
  -- it was reporting the truth, there was nothing to follow.
  -- The order is now the seats' own colours CLOCKWISE from the bottom-right corner (rttEnableTurns
  -- reads rttSeatOrderIdx), so it follows the physical table instead of a fixed colour list.
  rttEnableTurns((RTT_DN or 5) - 1)
  rttPublishSeats()

  -- base pattern: seat, ~20-frame settle, THEN deliver the matching order card.
  rttAfterFrames(function() rttDealOrderCards(seated) end, 20)
end

-- world point just above seat N's hand zone: a card dropped here falls into the owned hand.
function rttSeatHandWorld(N)
  local h = RTT_SEATS[N].hand.pos
  return { h[1], (h[2] or 14.62) + 2, h[3] }
end

-- Give each seated player the "Player N" card that MATCHES their seat, addressed by intrinsic CardID
-- (robust to runtime GUID reassignment), delivered into their hand. Seat colour was forced to
-- RTT_SETUP_COLORS[N] and the card is RTT_CARDID_FOR_N[N], so card number == seat by construction.
function rttDealOrderCards(seated)
  local deck = getObjectFromGUID(RTT_ORDER_DECK or "")
  if deck == nil then return end
  -- map CardID -> contained-card GUID ONCE, up front (guids stay stable as others are taken; the
  -- guid of the last card survives even after the deck collapses to a single Card).
  local guidFor = {}
  local ok, d = pcall(function() return deck.getData() end)
  if ok and d ~= nil then
    if d.ContainedObjects ~= nil then
      for _, c in ipairs(d.ContainedObjects) do guidFor[c.CardID] = c.GUID end
    elseif d.CardID ~= nil then
      guidFor[d.CardID] = deck.getGUID()
    end
  end
  local order = {}
  for N in pairs(seated) do order[#order + 1] = N end
  table.sort(order)
  local function deliver(i)
    if i > #order then return end
    local N     = order[i]
    local color = seated[N]
    local cid   = RTT_CARDID_FOR_N[N]
    local g     = (cid ~= nil) and guidFor[cid] or nil
    if g ~= nil and color ~= nil then
      local hp = rttSeatHandWorld(N)
      local o  = getObjectFromGUID(RTT_ORDER_DECK or "")
      local isDeck = false
      if o ~= nil then
        local ok2, dd = pcall(function() return o.getData() end)
        if ok2 and dd ~= nil and dd.ContainedObjects ~= nil then isDeck = true end
      end
      if isDeck then
        pcall(function()
          o.takeObject({ guid = g, position = hp, rotation = RTT_SEATS[N].hand.rot, smooth = false })
        end)
      else                                               -- deck collapsed: the card is loose now
        local c = getObjectFromGUID(g)
        if c ~= nil then pcall(function() c.setPositionSmooth(hp, false, false) end) end
      end
    end
    rttAfter(function() deliver(i + 1) end, 0.25)       -- one at a time = no deck-busy / collapse race
  end
  deliver(1)
end

function rttBeginPick()
  if #RTT_ORDER < 1 then return end
  RTT_PICKED = { map = nil, deck = nil }
  if RTT_5P_MARSH then rttPlaceMap("Marsh Map") end   -- the 5-player button still auto-places its Marsh map
  rttSpawnSelectors()
  rttAfterFrames(function() rttSeatPlayers() rttStartFactionDraft() end, 10)
end


RTT_TURN_PANEL_JSON = [====[{"Name":"BlockSquare","Transform":{"posX":0.0,"posY":11.56,"posZ":0.0,"rotX":0.0,"rotY":180.0,"rotZ":0.0,"scaleX":8.3545,"scaleY":0.18,"scaleZ":5.929},"Nickname":"Turn Panel","Description":"Round, turn clock, and the start-of-game buttons.","GMNotes":"","ColorDiffuse":{"r":0.169,"g":0.102,"b":0.047},"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"LuaScript":"PANEL_FRAME_URL = \"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/turn_panel_frame_015b64ac.png\"\n\n-- RTT TURN PANEL. Optional replacement for the clock and counter (its board button toggles it).\n--\n-- RENDERED THE WAY THE BOX SCORE IS: the object is a plain slab and everything visible is an object\n-- XmlUI drawn on it, with the slab resized to match the UI. Three earlier versions placed createButton\n-- widgets at hand-computed local coordinates over a baked picture and nothing ever lined up, because\n-- that mapping cannot be measured from outside the game. A layout engine needs no measuring.\n--\n-- The only baked part is the FRAME: the real Crafted Improvements border, 9-sliced, carried as a UI\n-- image behind the layout. Text cannot use Luminari -- setCustomAssets takes images only and a script\n-- cannot register a font (boxscore.lua: \"NO custom font here\") -- so it is TTS's default face.\n\nlocal PX_PER_UNIT = 100        -- object-UI render density, measured on a live table by the box score\nlocal BASE        = 3.85 * 0.7\nlocal FRAME       = 5\nlocal W, H        = 300, 210\n\nlocal PARCH2 = \"#F9E6BB\"   -- the crafted card's own ground, measured\nlocal GOLD, GOLDHI = \"#C9A05C\", \"#E4C88E\"\nlocal INKTXT, RUST = \"#26170B\", \"#7E4A1E\"\nlocal WARN, WARNHI = \"#A83226\", \"#C4503F\"\n-- Both readouts, one size. 56 is about what \"0:00\" can be in a half-width field (the content box is\n-- 240 wide, two columns and a 10 gutter, so ~115 each); resizeTextForBestFit below is the safety net,\n-- so a wider string shrinks to fit rather than clipping.\nlocal RO_FS = 50\n\n-- A TURN RUNNING LONG. Maintainer, 2026-09-07: \"when a turn gets to 20 mins, have the board background\n-- flash red like avery second or so as a soft warning that it has been 20 min.\" Soft is the point --\n-- it tints the parchment, it does not interrupt anyone or make a sound.\nlocal ALARM_SECS = 20 * 60\n-- A REAL RED, and the text goes white on it. Maintainer, 2026-09-07: \"make it more red, now it s\n-- pinkish and flash a bit faster. and have the text appear in white to contrast.\" The pinkness was the\n-- old wash: a light red at 40% alpha laid OVER everything, which tinted the dark type instead of\n-- replacing the ground. The alarm is a solid panel UNDER the content now, so the type sits ON the red.\nlocal ALARM_BG   = \"#A83226\"     -- the same red the buttons warn in (rttArmOrGo)\nlocal ALARM_TEXT = \"#FFFFFF\"\nlocal FLASH_STEP = 0.75          -- \"a tad slower blink\"\n-- To SEE it without waiting twenty minutes: press DEAL 5 CARDS three times inside three seconds and it\n-- flashes for fifteen. His request, so the look could be checked: \"if I press 3 times deal 5 cards in\n-- less than 3 seconds have that warning trigger so I can check how it looks.\"\nlocal DEMO_PRESSES, DEMO_WINDOW, DEMO_SECS = 3, 3, 15\nlocal NOClick = ' raycastTarget=\"false\"'\n\nPANEL_START = nil\nPANEL_TURN  = nil\nPANEL_ARMED = false            -- START asked, waiting for the confirming press\nPANEL_DEMO  = nil              -- os.time the demo flash ends\nPANEL_TAPS  = {}               -- recent DEAL presses, for the three-in-three-seconds trigger\nPANEL_ALARM = false            -- is the red ground up this instant\n-- PAUSE. Once the game has started, DEAL 5 CARDS has done its job and its half of the row becomes\n-- the clock control -- the maintainer, 2026-09-07: \"after start game, the button deal 5 cards\n-- become pause to pause the clock/ then the button becomes continue / then back again to pause\".\n-- Holds the os.time the clock was stopped; nil means running. Resuming does not reset anything, it\n-- pushes PANEL_START forward by however long the pause lasted, so the turn keeps its elapsed time.\nPANEL_PAUSED = nil\n-- THE LAST VALUES SHOWN. buildUI has to re-emit the readouts with what they currently say, not with\n-- their placeholders: every flash frame is a rebuild, so hardcoding \"-\" and \"0:00\" blanked the round\n-- and the clock until the next tick repainted them. Maintainer, 2026-09-07: \"the flash makes turn 1\n-- flicker to - symbol for some reason.\"\nPANEL_RTXT  = \"-\"\nPANEL_TTXT  = \"0:00\"\n\nfunction onSave() return JSON.encode({ s = PANEL_START, t = PANEL_TURN, p = PANEL_PAUSED }) end\n\nfunction onLoad(state)\n  pcall(function()\n    if state ~= nil and state ~= \"\" then\n      local d = JSON.decode(state)\n      if type(d) == \"table\" then PANEL_START = d.s; PANEL_TURN = d.t; PANEL_PAUSED = d.p end\n    end\n  end)\n  pcall(function() self.UI.setCustomAssets({ { name = \"pnlframe\", url = PANEL_FRAME_URL } }) end)\n  buildUI()\n  Wait.time(panelTick, 0.25, -1)\nend\n\nfunction sheet()\n  local t = getObjectsWithTag(\"RTT BoxScore\")\n  return (t ~= nil and #t > 0) and t[1] or nil\nend\n\nlocal function readout(id, caption, value, fs)\n  local capCol   = PANEL_ALARM and ALARM_TEXT or RUST\n  local fieldCol = PANEL_ALARM and \"#00000000\" or PARCH2   -- clear, so the red ground shows through\n  local numCol   = PANEL_ALARM and ALARM_TEXT or INKTXT\n  return '<VerticalLayout spacing=\"2\" childForceExpandHeight=\"false\">'\n      .. '<Text fontSize=\"20\" fontStyle=\"Bold\" color=\"' .. capCol .. '\" preferredHeight=\"24\"'\n      .. ' alignment=\"MiddleCenter\"' .. NOClick .. '>' .. caption .. '</Text>'\n      .. '<Panel color=\"' .. fieldCol .. '\" preferredHeight=\"70\"' .. NOClick .. '>'\n      .. '<Text id=\"' .. id .. '\" fontSize=\"' .. fs .. '\" fontStyle=\"Bold\" color=\"' .. numCol\n      .. '\" alignment=\"MiddleCenter\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"34\"'\n      .. ' resizeTextMaxSize=\"' .. fs .. '\"' .. NOClick .. '>' .. value .. '</Text></Panel>'\n      .. '</VerticalLayout>'\nend\n\nlocal function button(id, handler, fill, hi, press, textColor, label, fs)\n  return '<Button id=\"' .. id .. '\" colors=\"' .. fill .. '|' .. hi .. '|' .. press\n      .. '|#00000000\" onClick=\"' .. handler .. '\">'\n      .. '<Text fontSize=\"' .. fs .. '\" fontStyle=\"Bold\" color=\"' .. textColor\n      .. '\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"9\" resizeTextMaxSize=\"' .. fs .. '\"'\n      .. NOClick .. '>' .. label .. '</Text></Button>'\nend\n\nfunction buildUI()\n  local k  = BASE / PX_PER_UNIT\n  pcall(function() self.setScale({ (W + 2 * FRAME) * k, 0.18, (H + 2 * FRAME) * k }) end)\n  local sx = PX_PER_UNIT / (W + 2 * FRAME)\n  local sy = PX_PER_UNIT / (H + 2 * FRAME)\n\n  local x = {}\n  local function add(s) x[#x + 1] = s end\n  add(string.format('<Panel position=\"0 0 -60\" rotation=\"0 0 180\" scale=\"%.4f %.4f 1\"'\n      .. ' width=\"%d\" height=\"%d\" color=\"#00000000\"%s>', sx, sy, W, H, NOClick))\n  add('<Image id=\"pnlbg\" image=\"pnlframe\" width=\"' .. W .. '\" height=\"' .. H .. '\"' .. NOClick .. '/>')\n  if PANEL_ALARM then\n    -- UNDER the content, over the parchment: the type then reads white on red rather than being\n    -- tinted by a film laid over the top of it.\n    -- THE WHOLE BOARD, not an inset: W-34 left a cream margin showing all round it. Maintainer,\n    -- 2026-09-07: \"the red of the flash should take the whole clockcounter board it leaves a border\n    -- cream.\"\n    add('<Panel color=\"' .. ALARM_BG .. '\" width=\"' .. W .. '\" height=\"' .. H .. '\"'\n      .. NOClick .. '/>')\n  end\n  -- childForceExpandHeight=\"false\" is the whole reason this lines up. Without it TTS shares the\n  -- leftover height OUT INTO the children, so nothing is the height it asks for and the row moves when\n  -- a sibling changes -- the maintainer's \"position of buttons inside the swuares, all is still off\".\n  -- The box score sets the width analogue for the same reason (boxscore.lua, the overlay rows).\n  -- Padding is symmetric and the bands sum EXACTLY to the content box: 210 - 2*30 = 150 = 96 + 10 + 44.\n  add('<VerticalLayout padding=\"30 30 30 30\" spacing=\"10\" childForceExpandHeight=\"false\">')\n  add('<HorizontalLayout preferredHeight=\"96\" spacing=\"10\" childForceExpandHeight=\"false\">')\n  -- ONE SIZE FOR BOTH. Maintainer, 2026-09-07: \"Make the size of the number of the round and the\n  -- size of the time the same size I guess. Otherwise it looks a little bit off not on purpose.\"\n  -- 44/38 read as a mistake rather than a hierarchy; the clock is the wider string, so a single size\n  -- has to be one the four characters of \"0:00\" still clear in a half-width field.\n  add(readout(\"pnlRound\", \"ROUND\", PANEL_RTXT or \"-\", RO_FS))\n  add(readout(\"pnlTime\",  \"TIME\",  PANEL_TTXT or \"0:00\", RO_FS))\n  add('</HorizontalLayout>')\n  -- SIDE BY SIDE, and neither goes away. Maintainer, 2026-09-07: \"maybe deal 5 cards, and button start\n  -- (instead of start turn 1) can be next to each other and not disappear after employ; this is a\n  -- design issue I guess button disappearing maybbe not best.\"\n  -- The confirm replaces START ONLY, in START's own half. Maintainer, 2026-09-07: \"the warning button\n  -- should only take the siwe of the start button.\" Two lines, because \"THIS RESETS BOXSCORE\" cannot\n  -- be read across half a 240px row on one.\n  add('<HorizontalLayout preferredHeight=\"44\" spacing=\"10\">')\n  -- Before the game starts this half deals the opening hands; after it, it runs the clock.\n  if PANEL_START == nil then\n    add(button(\"pnlDeal\", \"panelDeal\", PARCH2, GOLDHI, GOLD, RUST, \"DEAL 5 CARDS\", 14))\n  else\n    add(button(\"pnlDeal\", \"panelPause\", PARCH2, GOLDHI, GOLD, RUST,\n               (PANEL_PAUSED ~= nil) and \"CONTINUE\" or \"PAUSE\", 14))\n  end\n  if PANEL_ARMED then\n    add(button(\"pnlStart\", \"panelStart\", WARN, WARNHI, WARN, \"#F9E6BB\",\n               \"THIS RESETS&#xA;BOXSCORE\", 12))\n  else\n    add(button(\"pnlStart\", \"panelStart\", GOLD, GOLDHI, RUST, INKTXT, \"START\", 14))\n  end\n  add('</HorizontalLayout>')\n  add('</VerticalLayout></Panel>')\n  pcall(function() self.UI.setXml(table.concat(x)) end)\nend\n\n-- The preview drives ITSELF, one step a second, instead of relying on the 0.25s tick. If the tick ever\n-- stops the twenty-minute warning stops with it, but the thing the maintainer presses to LOOK at the\n-- warning will still work, and that is the one that has to be trustworthy.\nfunction panelFlashStep(n)\n  if n <= 0 then\n    PANEL_ALARM = false\n    buildUI()\n    return\n  end\n  PANEL_ALARM = (n % 2 == 0)\n  buildUI()\n  Wait.time(function() panelFlashStep(n - 1) end, FLASH_STEP)\nend\n\nfunction panelTick()\n  local r = \"-\"\n  pcall(function()\n    local s = sheet()\n    if s ~= nil then local v = s.call(\"rttRound\"); if v ~= nil then r = tostring(v) end end\n  end)\n  PANEL_RTXT = r\n  pcall(function() self.UI.setValue(\"pnlRound\", r) end)\n  local cur = nil\n  pcall(function() cur = Turns.turn_color end)\n  if cur ~= nil and cur ~= \"\" and cur ~= PANEL_TURN then\n    PANEL_TURN = cur\n    -- a turn change while paused starts the new turn at zero AND leaves it stopped, so coming back\n    -- from a break does not hand the next player a clock that has been running without them\n    if PANEL_START ~= nil then\n      PANEL_START = os.time()\n      if PANEL_PAUSED ~= nil then PANEL_PAUSED = PANEL_START end\n    end\n  end\n  local txt = \"0:00\"\n  if PANEL_START ~= nil then\n    -- while paused the clock reads the moment it stopped, so it neither advances nor jumps on resume\n    local n = (PANEL_PAUSED or os.time()) - PANEL_START\n    if n < 0 then n = 0 end\n    txt = string.format(\"%d:%02d\", math.floor(n / 60), n % 60)\n  end\n  PANEL_TTXT = txt\n  pcall(function() self.UI.setValue(\"pnlTime\", txt) end)\n\n  -- FLASH when the turn has run past twenty minutes, or while the demo is up. os.time is whole\n  -- seconds, so its parity IS the once-a-second beat -- no counter to drift.\n  local secs = (PANEL_START ~= nil) and ((PANEL_PAUSED or os.time()) - PANEL_START) or 0\n  local alarm = (secs >= ALARM_SECS) or (PANEL_DEMO ~= nil and os.time() < PANEL_DEMO)\n  if PANEL_DEMO ~= nil and os.time() >= PANEL_DEMO then PANEL_DEMO = nil end\n  -- the tick is every 0.25s, so two ticks is the half-second beat; os.time only has whole seconds\n  PANEL_TICKS = (PANEL_TICKS or 0) + 1\n  local want = alarm and (math.floor(PANEL_TICKS / 3) % 2 == 0)   -- 3 ticks x 0.25s = FLASH_STEP\n  if want ~= PANEL_ALARM then\n    PANEL_ALARM = want\n    buildUI()\n  end\nend\n\n-- START wipes the scores and begins at turn 1 of the first seat. It ASKS FIRST when the sheet holds a\n-- game -- maintainer: \"if pressing on start while there is data in the boxscore that will be wiped,\n-- warning with This resets boxscore.\" Same two-press shape as the board's own wipe buttons, and it\n-- disarms itself after four seconds so a stray click cannot leave it primed.\nfunction panelStart()\n  if not PANEL_ARMED then\n    local has = false\n    pcall(function()\n      local s = sheet()\n      if s ~= nil then has = (s.call(\"rttHasData\") == true) end\n    end)\n    if has then\n      PANEL_ARMED = true\n      buildUI()\n      Wait.time(function()\n        if PANEL_ARMED then PANEL_ARMED = false; buildUI() end\n      end, 4)\n      return\n    end\n  end\n  PANEL_ARMED = false\n  PANEL_START = os.time()\n  PANEL_PAUSED = nil                -- a fresh game always starts running\n  -- ONE shuffle, here, because starting the game is the moment the deck should be random and nobody\n  -- should have to remember to do it -- the maintainer, 2026-09-07: \"pushing start on the clock\n  -- should shuffle the deck once as a well\". Silent if there is no deck out yet: START's job is the\n  -- clock and the turn, and it must not fail over a pile that has not been placed.\n  pcall(function()\n    local d = panelDeck()\n    if d ~= nil then d.shuffle() end\n  end)\n  -- Turn the system ON before naming the colour: Turns.turn_color does not stick while Turns.enable is\n  -- false, so on a table where nobody has triggered seating yet START would have set the sheet to round\n  -- 1 and left the turn pointer wherever it was. Hotseat is the case that exposed this -- the mod only\n  -- enables turns when a player SITS, and in hotseat one person holds every colour.\n  pcall(function()\n    local o = Turns.order\n    if o ~= nil and #o > 0 then\n      if Turns.enable ~= true then Turns.enable = true end\n      -- ONLY IF IT IS NOT ALREADY THEIRS. Assigning turn_color makes TTS fire onPlayerTurn even when\n      -- the colour does not change, and the sheet answers that by locking the outgoing row -- so\n      -- pressing START on player 1's turn recorded a completed turn at 0. Maintainer, 2026-09-07:\n      -- \"when I press start it makes player 1 pass its turn then it goes to player 1 so it registers a\n      -- first turn at 0.\"\n      if Turns.turn_color ~= o[1] then\n        -- ARM THE ONE-SHOT ONLY WHEN A PASS IS ACTUALLY ABOUT TO HAPPEN. It used to be armed\n        -- unconditionally, one line above this block -- and START is normally pressed when it is\n        -- ALREADY seat 1's turn, because rttEnableTurns has just set turn_color to seat 1. No pass\n        -- fires, nothing consumes the flag, and it sits armed until it swallows the first REAL turn of\n        -- the game. That is the missing round the maintainer kept reporting, and it was in the code\n        -- the whole time the five START fixes were being written: the flag is cleared in exactly one\n        -- place, inside onPlayerTurn.\n        pcall(function() local s = sheet() if s ~= nil then s.call(\"rttSuppressNextLock\") end end)\n        Turns.turn_color = o[1]\n      end\n      -- REMEMBER WHERE WE ARE SENDING IT, not what it reads back as. Assigning turn_color does not\n      -- take effect immediately, so reading it here still returns the OUTGOING colour -- and then the\n      -- real change lands a moment later, panelTick sees a colour it does not recognise, and restarts\n      -- the clock a second time. Maintainer, 2026-09-07: \"the turn moves to first seat player which\n      -- retriggers the clock. the lags makes the clock fires twice.\"\n      PANEL_TURN = o[1]\n    else\n      PANEL_TURN = Turns.turn_color\n    end\n  end)\n  -- THE WIPE COMES LAST, AND A FEW FRAMES LATE. Setting Turns.turn_color above changes whose turn it\n  -- is, and TTS fires onPlayerTurn for that as an EVENT rather than inline -- the box score answers it\n  -- by LOCKING the outgoing row at its current score. Wiping first therefore left a freshly written 0\n  -- sitting in round 1: maintainer, 2026-09-07, \"the reset of boxscore actually does not remove the 0s\n  -- in any score\". Letting the turn event land first and clearing afterwards is the only order in which\n  -- the sheet ends up empty.\n  Wait.frames(function()\n    pcall(function() local s = sheet() if s ~= nil then s.call(\"rttResetAndStart\") end end)\n  end, 4)\n  buildUI()\n  broadcastToAll(\"Turn 1.\", { r = 0.85, g = 0.75, b = 0.55 })\nend\n\n-- PAUSE / CONTINUE, one button. Pausing records the moment; continuing moves the turn's start\n-- forward by the length of the break, which leaves the elapsed time exactly where it was.\nfunction panelPause()\n  if PANEL_START == nil then return end\n  if PANEL_PAUSED ~= nil then\n    PANEL_START = PANEL_START + (os.time() - PANEL_PAUSED)\n    PANEL_PAUSED = nil\n  else\n    PANEL_PAUSED = os.time()\n  end\n  buildUI()\nend\n\n-- The shared deck: the one tagged pile with a real number of cards in it. Named once, because START\n-- shuffles it and DEAL 5 draws from it and the two must never disagree about which pile that is.\nfunction panelDeck()\n  for _, o in ipairs(getObjectsWithTag(\"Deck Object\")) do\n    local ok, n = pcall(function() return o.getQuantity() end)\n    if ok and n ~= nil and n > 20 then return o end\n  end\n  return nil\nend\n\nfunction panelDeal()\n  -- three presses inside three seconds puts the twenty-minute flash up for fifteen, so it can be\n  -- looked at on demand. The cards are still dealt each time; this only rides along.\n  local t = os.time()\n  local keep = {}\n  for _, v in ipairs(PANEL_TAPS) do\n    if t - v < DEMO_WINDOW then keep[#keep + 1] = v end\n  end\n  keep[#keep + 1] = t\n  PANEL_TAPS = keep\n  if #PANEL_TAPS >= DEMO_PRESSES then\n    PANEL_TAPS = {}\n    PANEL_DEMO = t + DEMO_SECS\n    panelFlashStep(DEMO_SECS)\n    broadcastToAll(\"Turn-length warning, \" .. DEMO_SECS .. \"s preview.\",\n                   { r = 0.91, g = 0.42, b = 0.35 })\n  end\n  local deck = panelDeck()\n  if deck == nil then\n    broadcastToAll(\"Deal 5: no deck on the table.\", { r = 1, g = 0.6, b = 0.2 }) return\n  end\n  local n = 0\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated and p.color ~= \"Grey\" and p.color ~= \"Black\" then\n      pcall(function() deck.deal(5, p.color) end); n = n + 1\n    end\n  end\n  if n == 0 then broadcastToAll(\"Deal 5: nobody is seated.\", { r = 1, g = 0.6, b = 0.2 }) return end\n  broadcastToAll(\"Dealt 5 cards to \" .. n .. \" player(s).\", { r = 0.85, g = 0.75, b = 0.55 })\nend\n","LuaScriptState":"","XmlUI":""}]====]


-- THE TURN PANEL, in place of the old clock and counter. Maintainer, 2026-09-06: "in stead of the
-- current clock and counter I would like a nice beautifully designed ... rectangle that show which
-- turn it is now, using the boxscore turn counter, a clock that measur the time of each player turn",
-- with a START TURN 1 button and a DEAL 5 CARDS button above it that disappears once used. Confirmed
-- "yes replace", so the Digital_Clock and Counter are gone rather than joined.
--
-- It sits where the clock stood. Like the other fixtures it survives a map change and is only spawned
-- when missing, so the running clock is not reset by picking a different board.
-- WHERE THE MAINTAINER PUT IT. He moved the panel by hand and saved the table as 'save'
-- (TS_Save_36.json, 2026-09-07: "check on the save called \"save\" for the actual position I picked"),
-- so these are read out of that save rather than reasoned about. My own guess had it centred on the
-- battle mat at 32.04 / -18.90; his sits about 1.5 to the left and 1.4 nearer the map's edge.
-- The scale in that save is 8.3545 x 5.9290, which is exactly what buildUI computes, so the object no
-- longer resizes itself on load.
RTT_PANEL_POS = { 30.5759, 11.6515, -20.3423 }
RTT_PANEL_ROT = { 0.0000, 180.0000, 0.0000 }

function rttSpawnMapExtras()
  pcall(function() rttSpawnBoxScore() end)         -- keeps an existing sheet; see rttSpawnBoxScore
  -- THE PANEL IS THE DEFAULT. Maintainer, 2026-09-07: "make this clock qnd counter the one by
  -- default". Its button still swaps back to the old digital clock and counter, which are kept for
  -- exactly that: nothing is deleted, the roles are reversed.
  if rttFixture(RTT_TAG_CLOCK) ~= nil or rttFixture(RTT_TAG_COUNTER) ~= nil then return end
  if rttFixture(RTT_TAG_PANEL) ~= nil then return end
  rttSpawnPanel()
end

function rttSpawnPanel()
  spawnObjectJSON({
    json = RTT_TURN_PANEL_JSON,
    position = RTT_PANEL_POS,
    rotation = RTT_PANEL_ROT,
    callback_function = function(o)
      pcall(function()
        local t = o.getTags(); table.insert(t, "Map Object"); table.insert(t, RTT_FIXTURE_TAG)
        table.insert(t, RTT_TAG_PANEL)
        o.setTags(t)
      end)
      pcall(function() o.setLock(true) end)
    end
  })
end

-- The turn panel is simply what the table has now. It shipped as an OPTION, with a button that
-- swapped it for the old digital clock and counter while it was still being shaped -- that is
-- finished, and the maintainer asked for the button on 2026-09-07: "remove the button turn panel".
-- Gone with it: rttToggleTurnPanel, and rttSpawnOldClock, which nothing else ever called.
-- The clock and counter blueprints went with it. Their TAGS did not: rttSpawnMapExtras still refuses
-- to spawn a panel onto a table that already has the old pair, so a save from before the panel does
-- not end up with both stacked on the same spot.

function rttPlaceMap(mapId)
  makeMap("", "", mapId)      -- makeMap spawns the battle mat itself now
end

function rttPlaceDeck(deckId)
  local id = deckId
  if #RTT_ORDER <= 2 then id = id .. " 2" end
  makeDeck("", "", id)
end

-- runs on the COORDINATOR (relayed from a selector)
-- THE MAP/DECK PICK IS GONE, not merely switched off. rttBeginPick set RTT_PICK_STAGE = 0 and the
-- handler returned immediately while it was 0 -- and the ONLY place that ever set it non-zero was
-- inside that same handler, past its own guard. It could not start, so rttShowPick, rttCoordPick
-- and RTT_PICK_DEFS were unreachable from any press, and the selector board's relay called a
-- function that always returned. Removed rather than left looking live -- along with the relay
-- and the always-inactive button group in the selector's own blueprint. The maintainer places
-- the map and the deck himself, which is what rttBeginPick has said since the pick was dropped.

RTT_FAC_STAGE = 0
RTT_FAC_TAKEN = {}
RTT_FAC_CURRENT = {}

-- spawn the Root Box Score sheet at the maintainer's placed spot (read from his TTS save),
-- rotated 270 to face the camera, sized to fill the board-design rectangle (scale up
-- ~1.3x wide / ~1.1x tall baked into _boxscore.json), locked to the table.
function rttSpawnBoxScore(force)
  -- A sheet already on the table is KEPT unless this is a new game: it is the same object whatever map
  -- is down, and it carries the recorded game in its own state. Replacing it on a map change silently
  -- lost that.
  if not force and #getObjectsWithTag(RTT_BOXSCORE_TAG) > 0 then return end
  for _, o in ipairs(getObjectsWithTag(RTT_BOXSCORE_TAG)) do rttDestroyUI(o) end
  -- tell the box score how many player rows to pre-format for (4 ranked / 5 for 5p Marsh); it reads
  -- this Global each rebuild and grows past it only if more players are added.
  Global.setVar("RTT_BOXSCORE_MIN", (RTT_DN or 5) - 1)
  spawnObjectJSON({
    json = RTT_BOXSCORE_JSON,
    position = { -58.36, 11.652, -0.05 },   -- centre of the maintainer's 4-card box-score rectangle
    rotation = { 0, 270, 0 },
    callback_function = function(o) o.addTag(RTT_BOXSCORE_TAG) o.addTag(RTT_FIXTURE_TAG) o.setLock(true) end
  })
end

function rttStartFactionDraft()
  -- NB: do NOT clear "RTT Faction" here -- the 4 draft-time Knave captains are tagged "RTT Faction" and
  -- spawn DURING this flow, so clearing here wiped them ("captains appear then vanish"). Prior-game faction
  -- boards are already cleared at game start by rttSetup (which also clears RTT Manual Selector).
  RTT_FAC_TAKEN = {}
  RTT_VP_PLACED = 0
  -- Box score is NOT spawned here any more. It comes with the map, alongside the battle mat, timer and
  -- counter (rttSpawnMapExtras) -- one place, one time, no redundancy. The maintainer: "that's the only
  -- time... you need to kind of clean up the code so that there is no redundancy."
  _G['Roster'] = {}
  for i = 1, #RTT_ORDER do _G['Roster'][i] = RTT_ORDER[i].name or "" end
  if _G['vagabondAlreadySpawned'] == nil then _G['vagabondAlreadySpawned'] = false end
  -- (the maintainer: never auto-deal starting hands. rttDealHands removed.)
  -- (Knaves captains now spawn from rttFlipAll, AFTER every draft card has flipped -- not here.)
  rttAfterFrames(function() rttShowFactions() end, 40) -- light EVERY board at once (simultaneous pick)
end

-- Knaves: if Knaves is one of the drafted factions, spawn its 12-card Captain deck directly under
-- the faction-card row DURING the draft, RANDOMISE 4 (the player picks 3 among them), discard the
-- rest. (No longer spawned with the faction board.) The deck blob lives in the Knaves faction data.
-- the 4 randomised Knave captains, laid FACE UP in a line below the draft cards (the maintainer's placed spots)
-- draft-time display spots: the draft RANDOMISES 4 captains, the player PICKS 3 among them (Law of
-- Root Knaves setup Step 2). Tagged "RTT Knave Captain" and relocated into a pick-pool beside the
-- Captains board when the Knaves faction is placed (rttSpawnCaptainsFor).
RTT_KNAVE_CAP = {
  { 53.495, 11.7, -7.992 },
  { 53.495, 11.7, -2.870 },
  { 53.495, 11.7,  2.253 },
  { 53.495, 11.7,  7.375 },
}

-- ---- Knaves Captains board (a 2nd "Crafted Improvements"-style board) -----------------------------
-- Portrait parchment board (Crafted-Improvements style, ink+gold frame) with 3 card slots. The draft
-- RANDOMISES 4 captains; the player PICKS 3 (Law of Root Step 2) — nothing is auto-filled.
-- The board is PART of the Knaves faction: it spawns from the faction blueprint's own rules-board
-- callback (rttSpawnCaptainsFor), at RTT_CAP_OFF_* in that board's LOCAL frame, so it lands at the
-- correct seat (never a global search), at the same time as the faction, and is cleared with it.
-- The tile's scaleX:scaleZ matches the art's imgW:imgH so the portrait slots keep card aspect; the
-- scale is BAKED and the board LOCKED (no resize panel). To retune: unlock in-game, resize, save,
-- tell me the new scale and I rebake RTT_CAPTAIN_BOARD_JSON. Snaps land on the 3 slot centres.
RTT_KNAVE_BOARD_IMG = "84529E736BDD4EF6B70CA79E3F99E2D07FA75A2C"  -- Knaves rules board face (the maintainer's anchor)
-- SWAPPED 2026-09-05, Zaandaa's call: the crafted-improvements board sits at dx +15.8 from the rules
-- board on all ELEVEN other factions, and the Knaves were the only exception -- the captains board
-- held that spot and the crafted board was mirrored to -15.6. Measured across every faction before
-- moving anything. The captains board now takes the mirror side and crafted takes the standard one,
-- each keeping the distance the maintainer had tuned rather than snapping to the modal +15.84.
-- The maintainer's counter (you move the captain card to the active slot, so the reaching side felt
-- natural) is real but he chose consistency. His original placement was worldoff (+15.84,+4.80) from
-- his save; the spawn formula gives worldoff = (-OFF_X, -OFF_Z), so OFF_X is now POSITIVE to put the
-- board on the other side, and OFF_Z stays negative to keep it raised.
-- Recovered from the maintainer's save 'knaves' (TS_Save_21), seat 2: he nudged the captains board,
-- so these are solved from where he left it relative to the Knaves rules board.
-- Read out of the maintainer's save 'knaves' (TS_Save_29, 2026-09-05 22:38), which he took AFTER the
-- swap and the recentre and then nudged the board closer: captains at dx -15.7569, dz +4.4790 from
-- the Knaves rules board.
--
-- I had put it at 17.5 to clear the supply bag, having measured an overlap of -0.88. That measurement
-- was WRONG: it treated an object's `scale` as its world footprint, which holds for a flat Custom_Tile
-- but not for a Custom_Model_Bag, whose mesh is much smaller than its scale number. The supply bag at
-- "4.65" is nothing like 4.65 units across, so the collision I was avoiding did not exist -- his own
-- save has the two at exactly this spacing and looks right.
RTT_CAP_OFF_X    =  15.7569
RTT_CAP_OFF_Z    = -4.4790
-- (snaps are BAKED into RTT_CAPTAIN_BOARD_JSON now; the old slot-fraction / self-size constants are gone)
-- The real Crafted Improvements art, cropped to its TOP 3 overlapping card slots (+ its real title
-- repainted to "Captains" and its real bottom border). 3 snaps for 3 captains stacked ON TOP of each
-- other (the crafted board's overlap look, just 3 instead of 5). Snaps computed with the verified
-- local_z = 2*py/H - 1 for the cropped H=1560; scale dropped to 7.59394 = 9.516764*(1560/1955) so a card
-- stays the same physical size as the full board. See [[rtt-tile-snap-geometry]].
  -- ColorDiffuse BLACK, like the real crafted board's own: on a Custom_Tile it tints the 3D SIDES, not
  -- the imaged face, so white left this board with pale edges beside a black-edged crafted board.
  -- Maintainer, 2026-09-07: "knaves captain board on the side is not black as the crafted improvememnt,
  -- the 3D side of the board, so looking sideway we can see the difference".
RTT_CAPTAIN_BOARD_JSON = [==[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.5,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":13.24558,"scaleY":1.0,"scaleZ":13.24558},"Nickname":"Knaves Captains","Description":"","ColorDiffuse":{"r":0.0,"g":0.0,"b":0.0},"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"AttachedSnapPoints":[{"Position":{"x":0.0,"y":0.2,"z":-0.52}},{"Position":{"x":0.0,"y":0.2,"z":0.0614}},{"Position":{"x":0.0,"y":0.2,"z":0.6428}}],"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/knaves_captains_v8.png","ImageSecondaryURL":"","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}}}]==]

-- Spawn the Captains board from the JUST-SPAWNED Knaves rules board (passed in by rttSpawnFaction's
-- callback), LEFT of it at the maintainer's faction-local offset. Because it is anchored to THIS
-- faction's own rules board, it always lands at the right seat (never a global search -> seat 1),
-- spawns in the faction's own flow (not a delayed extras call), and is tagged "RTT Faction" so it is
-- cleared together with the faction. The board is LOCKED at its baked aspect-correct scale (no resize
-- panel); snaps land on the 3 card slots. To change the size: unlock in-game, resize, save, tell me
-- the new scale and I rebake RTT_CAPTAIN_BOARD_JSON.
function rttSpawnCaptainsFor(rulesBoard)
  if RTT_CAPTAIN_BOARD_JSON == nil or rulesBoard == nil then return end
  -- one frame so the rules board's flip rotation (spawnRy) has settled before we read its transform
  Wait.frames(function()
    if rulesBoard == nil then return end
    local fp = rulesBoard.getPosition()
    local fry = rulesBoard.getRotation().y
    local ang = math.rad(fry)
    -- board centre = rules-board pos + Ry(fry)*(OFF_X,OFF_Z) so it rotates WITH the seat (flip-safe)
    local wx = fp.x + RTT_CAP_OFF_X * math.cos(ang) + RTT_CAP_OFF_Z * math.sin(ang)
    local wz = fp.z - RTT_CAP_OFF_X * math.sin(ang) + RTT_CAP_OFF_Z * math.cos(ang)
    spawnObjectJSON({
      json = RTT_CAPTAIN_BOARD_JSON,                       -- baked aspect-correct scale (locked)
      position = { wx, fp.y, wz },
      rotation = { 0, fry, 0 },
      callback_function = function(board)
        pcall(function() board.addTag("RTT Faction") end) -- goes out WITH the faction on re-draft
        pcall(function() board.addTag("RTT Captains") end)
        pcall(function() board.setLock(true) end)          -- LOCKED at the baked size (no resize panel)
        -- Snaps are BAKED into the board JSON (AttachedSnapPoints, from the crafted board's own
        -- coordinate system) -- no runtime snap maths. The drafted captains are deliberately NOT moved
        -- here: they stay at RTT_KNAVE_CAP, where rttDraftKnavesCaptains deals them. There used to be a
        -- rttPoolCaptains that slid them into a grid beside this board, but it read a positional
        -- {x,y,z} array as base.x/base.z -- nil -- so it threw on every call and the pcall swallowed it.
        -- It had therefore never run once, and the maintainer confirmed the ranked layout is what he
        -- wants, so it was removed rather than repaired.
        -- start the captain DETECTOR for this board: when a captain card lands in a slot, spawn that
        -- captain's meeple above the Knaves board (items TODO once the item-supply source is known).
        RTT_CAP_BOARD_GUID = board.getGUID()
        RTT_CAP_KNAVE_GUID = rulesBoard.getGUID()
        RTT_CAP_SLOT = {}; RTT_CAP_SPAWN_N = 0; RTT_CAP_ITEM_N = 0
        RTT_CAP_SPAWNED = {}; RTT_CAP_WARRIOR_N = 0
        pcall(function() rttBuildCaptainMeeples() end)
        Wait.time(rttCaptainDetect, 2.0)
      end
    })
  end, 1)
end

-- ===== Knaves Captain DETECTION ==================================================================
-- The Knaves blueprint carries all 12 "Captain - <Name>" meeples (Custom_Model) + their card deck.
-- rttSpawnFaction SKIPS spawning the 12 meeples; this detector spawns ONLY the chosen captains' meeples
-- (above the Knaves board) when their card lands in a captain-board slot. A captain is spawned ONCE --
-- a leave-then-return of the SAME captain in a slot does nothing (tracked per-slot in RTT_CAP_SLOT). Items are TODO:
-- they are NOT in the Knaves blueprint (they come from the shared item supply), so rttSpawnCaptainMeeple
-- has a hook to add RTT_CAP_ITEMS[name] to the Stash once that source is identified.
RTT_CAP_CARDID = { [73400]="Arbiter",[73401]="Cheat",[73402]="Gladiator",[73403]="Adventurer",
  [73404]="Harrier",[73405]="Jailor",[73406]="Ranger",[73407]="Tinker",[73408]="Ronin",
  [73409]="Scoundrel",[73410]="Thief",[73411]="Vagrant" }
RTT_CAP_ITEMS = { Arbiter={"Sword","Coins"}, Cheat={"Boot","Tea"}, Gladiator={"Sword","Hammer"},
  Adventurer={"Hammer","Coins"}, Harrier={"Boot","Crossbow"}, Jailor={"Crossbow","Bag"},
  Ranger={"Sword","Crossbow"}, Tinker={"Bag","Hammer"}, Ronin={"Boot","Sword"},
  Scoundrel={"Crossbow","Tea"}, Thief={"Boot","Bag"}, Vagrant={"Tea","Coins"} }
-- each item's unique token image (read off the Knaves item supply): maps item name -> its Custom_Tile
-- blueprint, so the chosen captains' items can be spawned into the Stash.
RTT_CAP_ITEM_IMG = { Hammer="659FC4CB06EB0B0D", Tea="EBD306D267C01CDF", Crossbow="F8D6F48DD0ABEEA7",
  Sword="5C28A04F83536BEE", Coins="C4D891F4DF65BFE6", Bag="1C4D9EF6DB4497F8", Boot="4C9DEE88ED9F3B02" }
RTT_CAP_ITEM_JSON   = nil
RTT_CAP_MEEPLE_JSON = nil
RTT_CAP_BOARD_GUID  = nil
RTT_CAP_KNAVE_GUID  = nil
RTT_CAP_SLOT        = {}   -- [slotN] = the captain currently sitting in that board slot
RTT_CAP_SPAWNED     = {}   -- [captain name] = true once spawned. Keyed by CAPTAIN, not by slot: a
                           -- captain is spawned AT MOST ONCE per game, wherever it is dragged.
RTT_CAP_WARRIOR_N   = 0    -- Knaves warriors spawned by the captain flow. HARD CAP of 3.
RTT_CAP_SPAWN_N     = 0
RTT_CAP_ITEM_N      = 0   -- running count of items dropped into the stash (for a clean grid)
RTT_CAP_WARRIOR_JSON = nil -- one "Knaves Warrior" blueprint (captain warriors below the meeple row)

function rttBuildCaptainMeeples()
  if RTT_CAP_MEEPLE_JSON ~= nil then return end
  RTT_CAP_MEEPLE_JSON = {}
  local def = EVERYTHING["Standard"] and EVERYTHING["Standard"]["Knaves of the Deepwood"]
  if def == nil or def.data == nil then return end
  for _, v in ipairs(def.data) do
    local m = string.match(v.json or "", '"Nickname":%s*"Captain %-%s*(%a+)"')
    if m then RTT_CAP_MEEPLE_JSON[m] = v.json end
  end
end

-- read one blueprint of each item token (matched by its unique image) so the chosen captains' items
-- can be spawned fresh into the Stash (the item supply itself is left untouched -- used as the base).
function rttBuildCaptainItems()
  if RTT_CAP_ITEM_JSON ~= nil then return end
  RTT_CAP_ITEM_JSON = {}
  local def = EVERYTHING["Standard"] and EVERYTHING["Standard"]["Knaves of the Deepwood"]
  if def == nil or def.data == nil then return end
  for iname, hash in pairs(RTT_CAP_ITEM_IMG) do
    for _, v in ipairs(def.data) do
      if RTT_CAP_ITEM_JSON[iname] == nil and string.find(v.json or "", hash, 1, true) then
        RTT_CAP_ITEM_JSON[iname] = v.json
      end
    end
  end
end

-- spawn this captain's TWO items near its meeple's column (ox = the meeple's local-X offset).
-- drop this captain's items into the Knaves STASH (board-local grid, via positionToWorld so it follows
-- the seat's rotation). RTT_CAP_ITEM_N accumulates so items from different captains tile cleanly.
-- (Stash board-local spot is an estimate -- tell me the exact one and I bake it.)
-- Each captain = one COLUMN of the 3x2 stash rectangle (idx 0 = left, 1 = middle, 2 = right); its 2 items
-- stack TOP then BOTTOM. Board-local grid from the maintainer's last save: x {-0.313,-0.153,0.007} (step
-- 0.16), z {0.619 top, 0.759 bottom} (step 0.14). positionToWorld carries the seat rotation.
function rttSpawnCaptainItems(name, idx)
  if RTT_CAP_ITEM_JSON == nil then rttBuildCaptainItems() end
  local kb = getObjectFromGUID(RTT_CAP_KNAVE_GUID or "")
  if kb == nil or RTT_CAP_ITEMS[name] == nil then return end
  local fry = kb.getRotation().y; local by = kb.getPosition().y
  local colx = -0.313 + (idx or 0) * 0.16
  for k, iname in ipairs(RTT_CAP_ITEMS[name]) do
    local blob = RTT_CAP_ITEM_JSON and RTT_CAP_ITEM_JSON[iname]
    if blob ~= nil then
      local rowz = 0.619 + (k - 1) * 0.14           -- item 1 = top row, item 2 = bottom row
      local wp = kb.positionToWorld({ colx, 0, rowz })
      spawnObjectJSON({ json = blob, position = { wp.x, by + 1.2, wp.z }, rotation = { 0, fry, 0 },
        callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end })
    end
  end
end

-- extract one "Knaves Warrior" blueprint from the faction data (for the captain warriors).
function rttBuildCaptainWarrior()
  local def = EVERYTHING and EVERYTHING["Standard"] and EVERYTHING["Standard"]["Knaves of the Deepwood"]
  if def == nil or def.data == nil then return end
  for _, v in ipairs(def.data) do
    if string.find(v.json, '"Nickname": "Knaves Warrior"', 1, true)
       and not string.find(v.json, '"ContainedObjects"', 1, true) then RTT_CAP_WARRIOR_JSON = v.json; return end
  end
end

-- spawn one captain's meeple in the maintainer's hand-placed row on the Knaves board (idx 0,1,2,...).
-- Reference (board-local, from his save): 3 captains at z=-1.349, x = -0.551, -0.279, -0.007 (step 0.272).
function rttSpawnCaptainMeeple(name, idx)
  if RTT_CAP_MEEPLE_JSON == nil then rttBuildCaptainMeeples() end
  local blob = RTT_CAP_MEEPLE_JSON and RTT_CAP_MEEPLE_JSON[name]
  local kb = getObjectFromGUID(RTT_CAP_KNAVE_GUID or "")
  if blob == nil or kb == nil then return end
  local fry = kb.getRotation().y; local by = kb.getPosition().y
  local wp = kb.positionToWorld({ -0.551 + idx * 0.272, 0, -1.349 })
  spawnObjectJSON({
    json = blob,
    position = { wp.x, by + 1.6, wp.z },
    rotation = { 0, fry, 0 },
    callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end
  })
  -- one Knaves warrior below the captain, HARD-CAPPED at 3 for the whole game: a switcheroo that brings
  -- in the 4th drafted captain must not add a 4th warrior (only 3 captains are ever in play).
  if (RTT_CAP_WARRIOR_N or 0) < 3 then
    RTT_CAP_WARRIOR_N = (RTT_CAP_WARRIOR_N or 0) + 1
    pcall(function() rttSpawnCaptainWarrior(idx) end)
  end
  pcall(function() rttSpawnCaptainItems(name, idx) end)  -- this captain's 2 items = its column (top+bottom)
end

-- one Knaves warrior below the captain row, board-local z=-1.137 from his save.
-- The X IS THE CAPTAIN'S, deliberately. Both rows were measured off his save separately and came out
-- with different starts AND different steps -- meeples -0.551 step 0.272, warriors -0.510 step 0.250 --
-- so each warrior sat a little to the side of its own captain, and by a different amount per column:
-- +0.36 world units under the first, +0.17 under the second, -0.03 under the third. Sharing the
-- captain's x makes every warrior land directly beneath its captain; the z stays where he put it.
function rttSpawnCaptainWarrior(idx)
  if RTT_CAP_WARRIOR_JSON == nil then rttBuildCaptainWarrior() end
  local kb = getObjectFromGUID(RTT_CAP_KNAVE_GUID or "")
  if RTT_CAP_WARRIOR_JSON == nil or kb == nil then return end
  local fry = kb.getRotation().y; local by = kb.getPosition().y
  local wp = kb.positionToWorld({ -0.551 + idx * 0.272, 0, -1.137 })   -- captain's x, warrior's z
  spawnObjectJSON({ json = RTT_CAP_WARRIOR_JSON, position = { wp.x, by + 1.4, wp.z }, rotation = { 0, fry, 0 },
    callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end })
end

-- CAPTAIN-based detector. The committed set is keyed by the CAPTAIN'S NAME (RTT_CAP_SPAWNED), not by
-- the slot it happens to be sitting in, so a captain is spawned AT MOST ONCE per game no matter how it
-- is dragged around. The previous version committed per SLOT, so moving a captain from slot 1 to slot 2
-- made slot 2 see a "different" captain than it had committed and spawn it a SECOND time -- the
-- maintainer's report: swapping cards between slots duplicated captains, while returning one to the
-- SAME slot did not. Warriors are additionally hard-capped at 3 (RTT_CAP_WARRIOR_N), so even a
-- switcheroo that brings in the 4th drafted captain cannot add a 4th warrior.
function rttCaptainDetect()
  local board = getObjectFromGUID(RTT_CAP_BOARD_GUID or "")
  if board == nil then return end        -- board gone (faction cleared) -> stop polling
  local snaps = board.getSnapPoints() or {}
  -- gather captain cards resting on the board
  local bb = board.getBounds()
  local cards = {}
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Card" or o.name == "CardCustom" then
      local p = o.getPosition()
      if math.abs(p.x - bb.center.x) <= bb.size.x / 2 + 1.5
         and math.abs(p.z - bb.center.z) <= bb.size.z / 2 + 1.5
         and math.abs(p.y - bb.center.y) <= 3.0 then
        local ok, dt = pcall(function() return o.getData() end)
        if ok and dt ~= nil and dt.CardID ~= nil and RTT_CAP_CARDID[dt.CardID] ~= nil then
          cards[#cards + 1] = { p = p, name = RTT_CAP_CARDID[dt.CardID] }
        end
      end
    end
  end
  -- match each slot (snap) to the nearest resting captain card
  for i, sp in ipairs(snaps) do
    local wp = board.positionToWorld(sp.position)
    local best, bd = nil, 9.0                          -- within ~3u of the slot centre
    for _, c in ipairs(cards) do
      local d = (c.p.x - wp.x) ^ 2 + (c.p.z - wp.z) ^ 2
      if d < bd then bd = d; best = c end
    end
    local key = "slot" .. i
    if best ~= nil then
      RTT_CAP_SLOT[key] = best.name                       -- record where it is (display/debug only)
      if not RTT_CAP_SPAWNED[best.name] then              -- FIRST time this captain is seen anywhere
        RTT_CAP_SPAWNED[best.name] = true
        rttSpawnCaptainMeeple(best.name, i - 1)           -- column follows the SLOT (0..2), not a counter
      end
    end
    -- empty slot: nothing to do. A captain that leaves and returns is already in RTT_CAP_SPAWNED.
  end
  Wait.time(rttCaptainDetect, 1.5)
end

-- lay the 4 drafted captains in a 2x2 grid beside the board (side away from the faction board),
-- face up and PORTRAIT, so the player sees all 4 and drags 3 onto the (snap-pointed) slots
-- Is a draft going to hand out the captains? True only during a ranked/theme draft that dealt the
-- Knaves; on a manual selector pick nothing drafts them, so the faction keeps its own captain deck.
function rttCaptainsAreDrafted()
  for _, f in ipairs(RTT_DRAFT_FACTIONS or {}) do
    if f == "Knaves of the Deepwood" then return true end
  end
  return false
end

-- The Knaves' captain deck, out of the faction blueprint (found by its art hash).
function rttKnaveCaptainDeckJSON()
  local kd = EVERYTHING['Standard']['Knaves of the Deepwood']
  if kd == nil or kd['data'] == nil then return nil end
  for _, v in ipairs(kd['data']) do
    if string.find(v.json, "FA78C0F952724D77A33BECEC0651802808037E95", 1, true) then return v.json end
  end
  return nil
end

function rttDraftKnavesCaptains()
  if not rttCaptainsAreDrafted() then return end
  local blob = rttKnaveCaptainDeckJSON()
  if blob == nil then return end
  spawnObjectJSON({
    json = blob,
    position = { 53.495, -50, 0 },                  -- BELOW the table: only the 4 drafted captains show
    rotation = { 0, 270, 0 },
    callback_function = function(deck)
      deck.setLock(true)
      pcall(function() deck.shuffle() end)
      Wait.time(function()
        if deck == nil then return end
        for i = 1, 4 do                                    -- randomise 4; the player picks 3 (Law of Root)
          pcall(function() deck.takeObject({
            position = RTT_KNAVE_CAP[i],
            rotation = { 0, 270, 0 }, smooth = false,        -- face up (as before), NOT locked
            callback_function = function(o) o.setLock(false) o.addTag("RTT Faction") o.addTag("RTT Knave Captain") end }) end)
        end
        Wait.time(function() if deck ~= nil then pcall(function() deck.destruct() end) end end, 0.8)
      end, 0.5)
    end
  })
end

function rttDealHands()
  local d = nil
  for _, p in ipairs(getObjectsWithTag("Deck Object")) do
    if p.name == "Deck" then d = p end
  end
  if d == nil then return end
  local seated = {}
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then seated[#seated + 1] = p.color end
  end
  if #seated == 0 then return end        -- real players only; never deal into the void
  rttDealOne(d, seated, 1, 1)            -- one card at a time, around the table
end

function rttDealOne(d, seated, card, who)
  if card > 5 then return end
  if who > #seated then rttDealOne(d, seated, card + 1, 1) return end
  if d ~= nil and d.deal then d.deal(1, seated[who]) end
  Wait.time(function() rttDealOne(d, seated, card, who + 1) end, 0.15)
end

-- light the faction menu on EVERY live board at once (simultaneous pick). Factions keep FIXED
-- button positions (slot i = RTT_DRAFT_FACTIONS[i]); a taken faction's slot just goes inactive, so
-- a click's button index always resolves to the same faction even as others are taken (no race).
function rttShowFactions()
  RTT_BUSY = false                                -- setup finished: buttons live again
  for _, seat in ipairs(RTT_SEATS or {}) do
    local clone = seat.board
    if clone ~= nil then
      clone.UI.setAttribute("rttPickMapDeck", "active", "false")
      clone.UI.setAttribute("rttFactions", "active", "true")
      for i = 1, 6 do
        local f = (RTT_DRAFT_FACTIONS or {})[i]
        if f ~= nil and not RTT_FAC_TAKEN[f] then
          clone.UI.setAttribute("rttFac" .. i, "icon", f)
          clone.UI.setAttribute("rttFac" .. i, "active", "true")
        else
          clone.UI.setAttribute("rttFac" .. i, "active", "false")
        end
      end
    end
  end
end

-- a player clicked a faction on some board. Resolve by the BOARD they clicked (not by whose turn
-- it is — all boards are live at once). First click on a faction takes it; the board is removed and
-- the faction spawns at that seat; the other boards refresh so the taken faction disappears.
function rttCoordFaction(args)
  if args.color == "Grey" or args.color == "Black" then return end   -- spectators can't pick (match makeFaction)
  local seat = rttSeatOfBoard(args.board or "")
  if seat == nil then return end
  local s = RTT_SEATS[seat]
  if s == nil or s.board == nil then return end        -- board already drafted
  if s.color ~= nil and args.color ~= s.color then return end   -- only YOUR own seat's board (no seat conflicts)
  local idx = tonumber(string.sub(args.id, -1))
  if idx == nil then return end
  local faction = (RTT_DRAFT_FACTIONS or {})[idx]
  if faction == nil or RTT_FAC_TAKEN[faction] then return end
  RTT_FAC_TAKEN[faction] = true                        -- lock immediately (guards double-clicks)
  local clone = s.board
  local bp = clone.getPosition()
  s.board = nil
  clone.destruct()                                     -- board gone first, then the faction spawns there
  -- s.hand is this seat's RTT_SEAT_HAND entry -- exactly what rttSeatPlayers put on hand 1.
  local seatHand = s.hand and { position = s.hand.pos, rotation = s.hand.rot } or nil
  rttPlaceFaction(faction, bp.x, bp.z, bp.z > 0, s.color or args.color, true, nil, nil, args.color, seatHand)
  rttAfterFrames(function() rttShowFactions() end, 10) -- refresh remaining boards
  -- rttAfterFrames, not Wait.frames: this clears RTT_BUSY, and a copy left in flight by the
  -- PREVIOUS game was unlocking the NEXT game's buttons mid-setup. A second destructive click
  -- then started a second setup on top of the first, whose chain died at the next RTT_RUN_ID
  -- check -- faction cards half dealt, no boards lit, no faction menu. Guarding on the run id
  -- makes the stale copy a no-op.
end

-- spawn a faction's pieces at (cx,cz), WITHOUT dice (m060). Warrior placements (m290
-- Lizard, m300 Duchy) are baked into the faction data, so they come along. flip rotates
-- the setup 180 for a far-side (z>0) seat. Mirrors tournamentSpawnDraftFaction's math.
-- `opts` is only used by the vagabond kit: { vpKeep = <tile guid>, vpName = <nickname> } keeps that
-- ONE VP tile out of the eleven and spawns it under the given name. Rewriting the blueprint's
-- Nickname before the spawn is deliberate -- renaming the object afterwards would be exactly the
-- spawn-then-patch this codebase forbids.
function rttSpawnFaction(faction, cx, cz, flip, category, rotationY, opts)
  category = category or "Standard"
  local def = EVERYTHING[category] and EVERYTHING[category][faction]
  if def == nil then return false end
  local objects = {}
  for _, v in ipairs(def['data']) do
    -- Faction spawns drop dice (the battle dice are shared, not per-faction), but two are part of the
    -- faction and must survive that filter -- maintainer 2026-09-04: "when spawning the bats, still
    -- spawn one of the two dice"; "when spawning the rats, still spawn the mob dice that you removed".
    -- Keyed by GUID so it cannot catch the wrong die: dc8eb3 is one of the Twilight Council's pair
    -- (89f44e, its twin, stays dropped), 81f2b2 is the Lord of the Hundreds' "Mob Die".
    local isDice = string.find(v.json, '"Name": "Custom_Dice"', 1, true)
    if isDice then
      for g in pairs(RTT_KEEP_DICE) do
        if string.find(v.json, '"GUID": "' .. g .. '"', 1, true) then isDice = false break end
      end
    end
    -- Knaves: do NOT spawn the 12 "Captain - <Name>" meeples NOR the item supply with the faction; the
    -- captain DETECTOR spawns only the CHOSEN captains' meeples + items. Blueprints are read from def.data.
    local isCap = false
    if faction == "Knaves of the Deepwood" then
      if string.find(v.json, '"Nickname": "Captain -', 1, true) then isCap = true end
      for _, h in pairs(RTT_CAP_ITEM_IMG or {}) do if string.find(v.json, h, 1, true) then isCap = true break end end
      -- skip the 3 LONE warrior FIGURES (top-level Knaves Warrior, no ContainedObjects) -- they respawn
      -- WITH the captains now. The 7-warrior SUPPLY BAG has ContainedObjects, so it is kept.
      if string.find(v.json, '"Nickname": "Knaves Warrior"', 1, true)
         and not string.find(v.json, '"ContainedObjects"', 1, true) then isCap = true end
      -- ...and the CAPTAIN DECK itself (guid 59530d in the blueprint, 12 cards, CardIDs 73400-73411),
      -- but ONLY when the captains are actually being drafted. rttDraftKnavesCaptains spawns its own
      -- copy of this deck, deals 4 and destroys it, so during a ranked/theme draft the board copy is a
      -- pure duplicate. Skipping it unconditionally meant that picking the Knaves from a manual
      -- selector -- where nothing drafts the captains -- left NO captain deck anywhere. The maintainer:
      -- "when I don't do the ranked or theme button that drafts the captain cards, the deck of all
      -- captains still spawns on the faction board". Matched on the deck's face texture, the same
      -- identifier the draft uses.
      if rttCaptainsAreDrafted() and string.find(v.json, "FA78C0F952724D77A33BECEC0651802808037E95", 1, true) then
        isCap = true
      end
    end
    -- the vagabond kit: keep the one VP tile this seat was given, drop the other ten
    local piece = v
    if opts ~= nil and opts.vpKeep ~= nil then
      local g = v.json:match('"GUID": "([0-9a-f]+)"')
      if g ~= nil and RTT_VAGABOND_VP_ALL[g] then
        if g ~= opts.vpKeep then
          isDice = true                       -- reuse the skip flag; this piece is not spawned
        elseif opts.vpName ~= nil and opts.vpName ~= "Vagabond VP" then
          piece = { json = (v.json:gsub('"Nickname": "Vagabond VP"',
                                        '"Nickname": "' .. opts.vpName .. '"', 1)) }
        end
      end
    end
    if not isDice and not isCap then objects[#objects + 1] = piece end
  end
  local scale = rttPlaceScale()
  local spawnRy = rotationY or (flip and 180 or 0)
  -- Which extra return slots this spawn has already recorded, so the first piece of a given name
  -- claims them and later pieces of the same name do not redo the work. See rttAddHomeExtras.
  local extrasDone = {}
  local function cb(o)
    o.addTag("RTT Faction")
    -- Tag THIS spawn's own fresh VP marker. Two of the same faction on the table (solo testing) share
    -- the marker name "<short> VP", so a name-only search grabbed the FIRST (already-placed) marker and
    -- moved it again. The tag lets rttPlaceVP move the marker THIS spawn just created, then clears it.
    local vpWant = (opts ~= nil and opts.vpName ~= nil) and opts.vpName or rttVPName(faction)
    if (o.getName() or "") == vpWant then o.addTag("RTT VP Unplaced") end
    if spawnRy ~= 0 then o.setRotation({ o.getRotation().x, o.getRotation().y + spawnRy, o.getRotation().z }) end
    if o.hasTag("Ruin Set") then o.destroy() end
    if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
    -- WHERE THIS PIECE CAME FROM, recorded LAST -- after spawnRy has been applied. A spawn callback is
    -- the only moment the position is known for certain, but reading it before that rotation stores a
    -- facing the piece never had: spawnRy is 180 on a far-row seat, so a building sent home would come
    -- back a half-turn out. Maintainer, 2026-09-06: "do not forget to rotate them in the right
    -- direction so they are not upside down."
    pcall(function()
      local p, r = o.getPosition(), o.getRotation()
      RTT_HOME[o.getGUID()] = { n = o.getName() or "", f = faction,
                                p = { p.x, p.y, p.z }, r = { r.x, r.y, r.z } }
      -- THIS is also the only moment the extra return slots can learn their facing: they have no
      -- piece of their own, so they copy it from a real piece of the same name -- and that piece
      -- only exists here, inside its own spawn callback.
      rttAddHomeExtras(faction, cx, cz, flip, rotationY,
                       o.getName() or "", { r.x, r.y, r.z }, extrasDone)
    end)
  end
  for _, v in ipairs(objects) do
    local vec = Vector(v.move_to) * scale
    if rotationY ~= nil then
      vec = vec * Vector(15.5, 1, 15.5)
      vec:rotateOver("y", rotationY)
    elseif flip then
      vec = vec * Vector(-15.5, 1, -15.5)
    else
      vec = vec * Vector(15.5, 1, 15.5)
    end
    local new_pos = Vector(cx, 11.56, cz) + vec
    new_pos.y = new_pos.y - 0.1
    -- Knaves: this piece IS the rules board (its blueprint json carries the board image). Spawn the
    -- Captains board FROM this exact board -> correct seat, same spawn flow, cleared with the faction.
    -- Detected on the blueprint DATA (deterministic), not a runtime getCustomObject (timing-safe).
    local isKnaveBoard = (faction == "Knaves of the Deepwood") and string.find(v.json, RTT_KNAVE_BOARD_IMG, 1, true)
    -- Corvid: same pattern -- when THIS faction's crow board spawns, place the 12 plots + hidden zone
    -- FROM it, in the faction's own flow (spawn-together), passing the board so it never picks a wrong one.
    local isCrowBoard = (faction == "Corvid Conspiracy") and string.find(v.json, RTT_CROW_BOARD_IMG, 1, true)
    -- Rats: same pattern again. The mood cards used to go down in the same instant as the board,
    -- so they were falling before the board had a collider. Spawning them FROM the board means the
    -- surface they land on already exists -- still the same pass, nothing deferred or moved.
    local isRatsBoard = (faction == "Lord of the Hundreds") and string.find(v.json, RTT_RATS_BOARD_IMG, 1, true)
    local myCb = cb
    if isKnaveBoard then myCb = function(o) cb(o); rttSpawnCaptainsFor(o) end
    elseif isCrowBoard then myCb = function(o) cb(o); Wait.frames(function() rttCrowsPlots(cx, cz, flip, false, o) end, 1) end
    elseif isRatsBoard then myCb = function(o) cb(o); Wait.frames(function() pcall(function() rttRatsMoodManager(cx, cz, flip) end) end, 1) end end
    spawnObjectJSON({ json = v.json, position = new_pos, callback_function = myCb })
  end
  -- The rats' Mini-Mood Manager is spawned from the rats BOARD's own callback above, not here --
  -- see RTT_RATS_BOARD_IMG. It is part of the rats' OWN setup, not an "extra". It used to run from
  -- rttFactionExtras, which is deferred half a second, so it visibly landed after the board
  -- (maintainer: "they all need to spawn at the same time"). Spawned here it goes down in the same
  -- pass as the faction's own pieces. The duplicate it used to sit on top of -- the 8-card mood deck
  -- baked into the rats blueprint at almost exactly this spot -- is removed from the blueprint.
  -- Same rule for the moles: the Mole Monger belongs to the Duchy's own setup, so it goes down with
  -- the faction rather than being a button the maintainer has to remember.
  if faction == "Underground Duchy" then
    pcall(function() rttMoleMonger(cx, cz, flip) end)
  end
  -- The gizmo's extra return slots are NOT added here. They used to be, and it looked right -- the
  -- loop above has finished, so "every piece has spawned" seemed true. It is not: the loop only ASKS
  -- for the pieces. spawnObjectJSON's callback, the only place a piece's real facing is known, runs a
  -- frame or more later, so the copy always found an empty RTT_HOME and fell back to a flat 180.
  -- The pieces' own blueprint facing IS 180, so that fallback was right by luck on a near-row seat and
  -- a half turn out on every FAR-row one, where spawnRy adds 180 and they land at 0. Maintainer,
  -- 2026-09-06: "some gardens still return upside
  -- down with gizmo 0; I think it s only the first ones" -- the first, because the extra slot sorts
  -- ahead of the spawned ones and so is the first slot filled. They are recorded from cb instead.
  return true
end

-- Both ranked and manual faction selectors come through this one automation path:
-- spawn the blueprint (including its single base VP marker), publish the faction's
-- physical seat, run the faction extras, then MOVE that marker onto score zero.
function rttPlaceFaction(faction, cx, cz, flip, color, isDraft, category, rotationY, pickerColor, seatHand)
  if not rttSpawnFaction(faction, cx, cz, flip, category, rotationY) then return false end

  -- THE SEAT RECORD. One write, from facts, at the moment the faction actually lands.
  --
  -- What this replaced published three Globals from three separately-derived guesses, and the middle
  -- one was wrong: it found the nearest of the six board SPOTS and then indexed RTT_SETUP_COLORS --
  -- a PLAYER-NUMBER table -- with that SPOT number, never undoing RTT_LAYOUT. Right at 1 and 3
  -- players, wrong at 2, 4, 5 and 6; at four players P3 and P4 held each other's colour all game.
  --
  -- There is no lookup here any more. The board's real position IS the seat: rttSeatAt finds the seat
  -- standing there or opens one, so the ranked draft, the 4/5-player setup boards and a single
  -- Faction Select board dragged anywhere all arrive the same way, with no special case.
  local si = rttSeatAt(cx, cz, true, faction)
  local seat = RTT_SEATS[si]
  seat.faction = faction
  -- The key everything downstream knows this seat by, decided ONCE here rather than recomputed by
  -- each reader. For a vagabond it also carries WHICH vagabond: two of them are two rows on the box
  -- score, two different marker names, and two different markers out of the kit's eleven.
  if isVagabond(faction) then
    seat.vagN = rttVagabondOrdinal(si)
    seat.key  = rttVagabondKey(seat.vagN)
  else
    seat.vagN = nil
    seat.key  = rttFactionKey(faction)
  end
  -- The seat's colour is the colour of whoever took it. On the draft path rttSeatPlayers has already
  -- set it from the seated human (and rttCoordFaction only lets you pick on your own seat, so the
  -- picker IS that human). On the manual paths nobody is seated, so the picker's colour is what the
  -- seat is worth -- unless that colour is already another seat's, which is what happens when one
  -- person sets out several boards: those later seats take a free colour instead of stealing one.
  rttSetSeatColor(seat, pickerColor)
  if seat.color == nil then rttSetSeatColor(seat, rttFreeSeatColor()) end
  -- WHO OWNS it is the person who clicked, and is deliberately NOT the same thing as the seat colour.
  -- Conflating them broke naming before: the manual path never recolours anyone, so a player keeps
  -- the colour they joined with while the row is coloured by seat, and matching the row's colour
  -- against seated players then found nobody and the row showed no name at all.
  -- EVERY pick by this person, deliberately. The maintainer chose it when asked: "I am changing seats
  -- by selecting new factions but the gizmo numpad 1 does not seem to understand that", and picked
  -- "follow your last pick" over the alternative. So this is written even when the seat itself was
  -- handed a free colour, because that is exactly the case where the seat record cannot answer.
  --
  -- What IS recorded alongside it is WHO made the claim. Keyed by colour alone it was never
  -- invalidated, so a colour that changed hands carried the claim with it -- Alice picks the Marquise
  -- as Red and leaves, Bob takes Red, Bob's numpad 1 hands him Marquise warriors.
  -- WHO MADE THIS PICK, AND WHEN. Both belong to the seat: the gizmo reads the most recent seat this
  -- person made, which is "the faction I last picked" without a second table to keep in step.
  if pickerColor ~= nil and pickerColor ~= "" then
    RTT_PICK_N = (RTT_PICK_N or 0) + 1
    seat.picker, seat.pickedAt = pickerColor, RTT_PICK_N
  end
  -- REFRESHED, NOT WRITTEN ONCE. `if seat.owner == nil` meant a seat kept the first name it ever saw:
  -- Alice drafts the Marquise, disconnects, Bob takes her colour, and the sheet -- which PREFERS this
  -- name over the live occupant -- credits the whole game to Alice.
  if pickerColor ~= nil and pickerColor ~= "" then
    rttSetSeatOwner(seat, rttPersonIn(pickerColor))
  end
  rttPublishSeats()
  -- Re-apply the turn order from the seats as they now stand. This is what makes the MANUAL paths
  -- work: nobody is seated there, so the order set at setup time was the fallback colour list, and it
  -- has to become the real seat colours as factions are picked. keepTurn is passed so rttEnableTurns
  -- takes its no-change shortcut and does not re-fire the TTS turn chime on every pick.
  pcall(function()
    local keep = nil
    pcall(function() keep = Turns.turn_color end)
    rttEnableTurns(RTT_TURN_SEATS or #RTT_SEATS, keep or "")
  end)

  local extraFaction, extraX, extraZ, extraFlip, extraDraft = faction, cx, cz, flip, isDraft == true
  Wait.time(function() rttFactionExtras(extraFaction, extraX, extraZ, extraFlip, extraDraft) end, 0.5)

  RTT_VP_PLACED = (RTT_VP_PLACED or 0) + 1
  -- by the seat's KEY, not the faction: "Vagabond 2" resolves to "Vagabond 2 VP", so the second
  -- vagabond's marker is the one that gets found and walked onto the score track.
  local vpN, vpF = RTT_VP_PLACED, (seat.key or faction)
  Wait.time(function() rttPlaceVPRetry(vpF, vpN, 6) end, 1.2)

  -- The supporters hand belongs to THE PLAYER WHO PICKED the Alliance, not to the seat's colour.
  -- One rule at every player count, not a solo exception: in a real game the picker IS the seat's
  -- player (rttCoordFaction only lets you pick on your own seat), so nothing changes there. Solo that
  -- restriction is bypassed, so the maintainer could place the Alliance on a seat whose colour is not
  -- his -- and the hand, being owned by that colour, was invisible to him. His report: "sometimes it
  -- looks like I cannot see the card in the supporter area, even though I'm seated there".
  local supColor = pickerColor or color
  if faction == "Woodland Alliance" and supColor ~= nil then
    -- Capture where hand 2 is BEFORE moving it. setHandTransform is not instant, so "has it moved yet?"
    -- is the only exact readiness test -- and until it has, the zone is still parked at x=-75, which is
    -- where the supporters were landing on the runs the maintainer saw fail.
    local before = nil
    pcall(function() local h = Player[supColor].getHandTransform(2) if h then before = h.position end end)
    -- seatHand is this seat's main-hand transform, handed down by the caller that placed the seat.
    spawnSupportersHand(supColor, seatHand)
    rttDealAllianceSupporters(supColor, before, 12)
  end
  return true
end

-- Knaves: draw 4 random Captains from the Knave board's captain deck (best-effort by name)

-- ===== RTT: move drafted-faction VP markers onto the map score track (col 0) =====
-- Ports the box-score tool's proven track detection + geometry.
RTT_TRACK          = RTT_TRACK or nil
RTT_SCORE0_AT_MIN  = false              -- score 0 sits at the track's LOCAL MAX (base-mod convention)
RTT_VP_PLACED      = RTT_VP_PLACED or 0

RTT_VP_SHORT = {
  ["Marquise de Cat"]        = "Marquise",
  ["Eyrie Dynasties"]        = "Eyrie",
  ["Woodland Alliance"]      = "Alliance",
  ["The Lizard Cult"]        = "Lizard",
  ["Riverfolk Company"]      = "Riverfolk",
  ["Underground Duchy"]      = "Duchy",
  ["Corvid Conspiracy"]      = "Crows",
  ["Lord of the Hundreds"]   = "Rats",
  ["Keepers in Iron"]        = "Badgers",
  ["Twilight Council"]       = "Council",
  ["Lilypad Diaspora"]       = "Diaspora",
  ["Knaves of the Deepwood"] = "Knaves",
}

-- ONE source for the VP marker's object name, used by BOTH the fresh-marker tagger (rttSpawnFaction)
-- and rttFindVPMarker, so the two can never drift and silently re-grab the wrong marker (audit).
-- A Vagabond is picked as a CHARACTER -- "Tinker", "Ranger" -- but everything downstream is named
-- for the FACTION. Its score marker is "Vagabond VP", never "Tinker VP", and the box score's roster
-- knows "Vagabond" too. Without this the marker was never tagged, so it never reached the score
-- track, and the seat published under "Tinker" matched nothing on the sheet: the faction simply did
-- not appear. Maintainer, 2026-09-05: "the victory marker didn't go on the tracker, and the faction
-- didn't get detected."
function rttFactionKey(faction)
  if isVagabond(faction) then return "Vagabond" end
  if faction == "Vagabond Dice and VP" or faction == "Vagabond Layout" then return "Vagabond" end
  return faction
end

-- THE VAGABOND'S TWO VP MARKERS. The kit "Vagabond Dice and VP" spawns exactly two Custom_Tiles, both
-- nicknamed "Vagabond VP":
--   068b0a  BLACK, a plain tile
--   765187  WHITE, and it carries the nine TTS player colours as STATES, so a player can recolour it
-- That pair is what the printed game provides so TWO vagabonds can be told apart, and it is the whole
-- solution here (maintainer, 2026-09-05: "vagabonds comes with two vp markers to handle two vagabonds,
-- one white one black, so that might be part of the solution").
--
-- Both used to spawn for every vagabond -- so one vagabond left an orphan marker on the table and two
-- put out four. And because a box-score row IS its marker's NAME, two vagabonds collapsed onto ONE
-- row: the second player had no score line at all, and both markers read into the first, whose score
-- jumped about as the marker search re-pointed between them.
--
-- A vagabond seat now takes ONE: white for the first, black for the second. The second is renamed
-- "Vagabond 2 VP", which is the only thing that can give it its own row.
--
-- Renaming only ever touches the BLACK tile, and that matters: the white one carries the nickname ten
-- times over (itself plus nine states), so renaming it would have to hit all ten or it would rename
-- itself back the moment somebody switched colour. Ordering white first makes that impossible.
RTT_VAGABOND_VP = { White = "765187", Black = "068b0a" }
RTT_VAGABOND_VP_ORDER = { "White", "Black" }        -- first vagabond, second vagabond

RTT_VAGABOND_VP_ALL = {}
for _, g in pairs(RTT_VAGABOND_VP) do RTT_VAGABOND_VP_ALL[g] = true end

-- How many vagabond seats already hold one, counting only seats BEFORE this one so the answer does
-- not change when a later seat is filled.
function rttVagabondOrdinal(si)
  local n = 0
  for i, s in ipairs(RTT_SEATS or {}) do
    if i ~= si and s ~= nil and s.faction ~= nil and isVagabond(s.faction) then
      if i < si then n = n + 1 end
    end
  end
  return n + 1
end

-- "Vagabond" for the first, "Vagabond 2" for the second. This is the seat's published key AND the
-- stem of its marker name, so rttVPName, rttFindVPMarker and the box-score row all agree by
-- construction rather than by three tables that can drift.
function rttVagabondKey(ordinal)
  if ordinal == nil or ordinal <= 1 then return "Vagabond" end
  return "Vagabond " .. tostring(ordinal)
end

function rttVPName(faction)
  local key = rttFactionKey(faction)
  return (RTT_VP_SHORT[key] or key) .. " VP"
end

function rttDetectTrackOn(obj)
  local ok, sp = pcall(function() return obj.getSnapPoints() end)
  if not ok or sp == nil or #sp < 40 then return nil end
  local bandsFound = {}
  for _, axis in ipairs({ "x", "z" }) do
    local other = (axis == "x") and "z" or "x"
    local pts = {}
    for _, s in ipairs(sp) do table.insert(pts, { a = s.position[axis], b = s.position[other] }) end
    table.sort(pts, function(p, q) return p.b < q.b end)
    local bands, cur = {}, {}
    for _, p in ipairs(pts) do
      if #cur > 0 and (p.b - cur[#cur].b) > 0.03 then table.insert(bands, cur); cur = {} end
      table.insert(cur, p)
    end
    if #cur > 0 then table.insert(bands, cur) end
    for _, band in ipairs(bands) do
      if #band >= 25 then
        local xs = {}
        for _, p in ipairs(band) do table.insert(xs, p.a) end
        table.sort(xs)
        local diffs = {}
        for i = 2, #xs do table.insert(diffs, xs[i] - xs[i - 1]) end
        table.sort(diffs)
        local s = diffs[math.ceil(#diffs / 2)]
        local even = s and s > 0.01
        if even then
          for _, d in ipairs(diffs) do
            local mrep = math.floor(d / s + 0.5)
            if mrep < 1 or mrep > 2 or math.abs(d - mrep * s) > 0.25 * s then even = false end
          end
        end
        if even then
          local n = math.floor((xs[#xs] - xs[1]) / s + 0.5) + 1
          if n >= 28 and n <= 60 and #xs >= 0.85 * n then
            table.insert(bandsFound, { axis = axis, other = other, a0 = xs[1], s = s, n = n, b = band[1].b })
          end
        end
      end
    end
  end
  if #bandsFound == 0 then return nil end
  local best = nil
  for _, band in ipairs(bandsFound) do
    if best == nil then
      best = { axis = band.axis, other = band.other, a0 = band.a0, s = band.s, n = band.n, rows = { band.b } }
    elseif band.axis == best.axis
      and math.abs(band.s - best.s) < 0.1 * best.s
      and math.abs(band.a0 - best.a0) < 0.5 * best.s then
      table.insert(best.rows, band.b)
      if band.n > best.n then best.n = band.n end
    end
  end
  table.sort(best.rows)
  best.pts = {}
  local bmin, bmax = best.rows[1] - 0.05, best.rows[#best.rows] + 0.05
  for _, s2 in ipairs(sp) do
    local a = (best.axis == "x") and s2.position.x or s2.position.z
    local b = (best.axis == "x") and s2.position.z or s2.position.x
    if b >= bmin and b <= bmax then table.insert(best.pts, { a = a, b = b }) end
  end
  best.guid = obj.getGUID()
  return best
end

function rttFindScoreTrack()
  if RTT_TRACK ~= nil then
    local o = getObjectFromGUID(RTT_TRACK.guid)
    if o ~= nil then return o end
    RTT_TRACK = nil
  end
  local best, bestSnaps = nil, 0
  for _, o in ipairs(getAllObjects()) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp >= 40 and #sp > bestSnaps then
      local t = rttDetectTrackOn(o)
      if t then best, bestSnaps = t, #sp end
    end
  end
  RTT_TRACK = best
  if best == nil then return nil end
  return getObjectFromGUID(best.guid)
end

function rttZeroColumnSlots()
  if rttFindScoreTrack() == nil then return {} end
  local t = RTT_TRACK
  local cellIdx = RTT_SCORE0_AT_MIN and 0 or (t.n - 1)
  local cellA   = t.a0 + cellIdx * t.s
  local mid     = t.rows[math.ceil(#t.rows / 2)]
  -- the score-0 column's REAL snap rows (the maintainer places the VP markers exactly on these).
  local real = {}
  for _, p in ipairs(t.pts or {}) do
    if math.abs(p.a - cellA) < 0.45 * t.s then real[#real + 1] = p.b end
  end
  table.sort(real)
  -- centre-out ladder over the real snaps: zero (centre), then up, then down, then
  -- further up/down (the maintainer's requested stack order), extending past the ends by the
  -- exact row spacing only when more factions than snap rows.
  local step = 0.11
  if #real >= 2 then step = (real[#real] - real[1]) / (#real - 1)
  elseif #t.rows >= 2 then step = (t.rows[#t.rows] - t.rows[1]) / (#t.rows - 1) end
  local cidx = 1
  for i = 2, #real do if math.abs(real[i] - mid) < math.abs(real[cidx] - mid) then cidx = i end end
  local order = { real[cidx] }
  local up, dn = cidx + 1, cidx - 1
  while up <= #real or dn >= 1 do
    if up <= #real then order[#order + 1] = real[up]; up = up + 1 end
    if dn >= 1 then order[#order + 1] = real[dn]; dn = dn - 1 end
  end
  local top, bot = real[#real], real[1]
  local ext = { top + step, bot - step, top + 2 * step, bot - 2 * step }
  local slots = {}
  for _, b in ipairs(order) do slots[#slots + 1] = { a = cellA, b = b } end
  for _, b in ipairs(ext) do
    slots[#slots + 1] = { a = cellA, b = b }
  end
  return slots
end

function rttSlotWorld(slot)
  if RTT_TRACK == nil or slot == nil then return nil end
  local map = getObjectFromGUID(RTT_TRACK.guid)
  if map == nil then return nil end
  local lp = { x = 0, y = 2.0, z = 0 }
  lp[RTT_TRACK.axis]  = slot.a
  lp[RTT_TRACK.other] = slot.b
  return map.positionToWorld(lp)
end

function rttFindVPMarker(faction)
  local want  = rttVPName(faction)
  local fresh, free, held = nil, nil, nil
  for _, o in ipairs(getAllObjects()) do
    if o ~= nil and (o.getName() or "") == want then
      if o.held_by_color ~= nil then held = held or o
      elseif o.hasTag("RTT VP Unplaced") then fresh = fresh or o   -- a spawn's marker not yet placed
      else free = free or o end
    end
  end
  return fresh or free or held   -- always prefer the freshly-spawned, not-yet-placed marker
end

-- rttPlaceVP can early-return (score track not readable yet on a slow map spawn, marker not found).
-- Retry a few times so a slow map still gets its marker placed; on final give-up, CLEAR the fresh-marker
-- tag so a stranded "RTT VP Unplaced" marker cannot poison a later same-faction placement (audit: vp-track).
-- Markers that could not be placed yet, faction -> its zero-column index. VP placement used to be a
-- pure TIME BOX: 1.2s, then 6 retries at 0.6s, then give up and strip the "unplaced" tag. If the MAP was
-- spawned after the factions, the score track did not exist inside that ~4.8s window and the marker was
-- abandoned -- which is exactly why the maintainer saw it happen to the EARLIEST-placed factions every
-- time. Now an unplaced marker stays pending and makeMap finishes the job when a track appears.
RTT_VP_PENDING = {}

function rttPlaceVPRetry(faction, n, tries)
  if rttPlaceVP(faction, n) then
    RTT_VP_PENDING[faction] = nil
    return
  end
  RTT_VP_PENDING[faction] = n                      -- remember it, whatever happens below
  if tries and tries > 0 then
    Wait.time(function() rttPlaceVPRetry(faction, n, tries - 1) end, 0.6)
  end
  -- deliberately no give-up branch: the tag stays on, and rttPlaceUnplacedVPs retries when a map lands.
end

-- called after a map spawns: place every marker still waiting for a score track.
function rttPlaceUnplacedVPs()
  if rttFindScoreTrack() == nil then return end
  for faction, n in pairs(RTT_VP_PENDING) do
    pcall(function() rttPlaceVPRetry(faction, n, 4) end)
  end
end

function rttPlaceVP(faction, n)
  if faction == nil then return false end
  if rttFindScoreTrack() == nil then return false end
  local m = rttFindVPMarker(faction)
  if m == nil then return false end
  local slots = rttZeroColumnSlots()
  if #slots == 0 then return false end
  local idx = math.max(1, math.min(#slots, n or 1))
  local wp  = rttSlotWorld(slots[idx])
  if wp == nil then return false end
  if m.getLock and m.getLock() then m.setLock(false) end
  -- Orientation fix: VP markers spawn at their faction board, and a far-side (z>0) seat
  -- spawns flipped 180, so its marker lands upside-down on the track. Normalise every
  -- placed marker to the score track's own facing so they all read the same way.
  local trackRy = 0
  local map = getObjectFromGUID(RTT_TRACK.guid)
  if map ~= nil then trackRy = map.getRotation().y end
  m.setRotationSmooth({ 0, trackRy, 0 }, false, true)
  m.setPositionSmooth({ wp.x, wp.y + 0.12, wp.z }, false, true)
  pcall(function() m.removeTag("RTT VP Unplaced") end)   -- placed now; don't let a later call re-grab it
  return true
end


-- ===== RTT per-faction setup extras =====
-- Seed the RNG ONCE at load. Everything random (floods, landmark, draft) then just advances this
-- stream per call, so rapid re-clicks always differ. Never re-seed with os.time() per action —
-- that made same-second clicks collide (see rtt-rng-bug).
math.randomseed(os.time())
for _rw = 1, 5 do math.random() end
RTT_FOREST_UV = {
  ["Summer Map"] = { {-0.0119,0.3133}, {-0.2622,0.1541}, {0.1303,0.0818}, {0.0918,-0.1710}, {0.2914,-0.1245}, {-0.3226,-0.0941}, {-0.1570,-0.2591} },
  ["Winter Map"] = { {-0.0014,0.2102}, {-0.2874,0.1472}, {-0.2859,-0.0771}, {0.3033,0.0681}, {0.1848,-0.1880}, {-0.2064,-0.2222}, {-0.0119,-0.1395}, {0.2912,-0.1394} },
  ["Lake Map"] = { {0.2982,-0.1413}, {-0.1985,0.2776}, {-0.3180,0.1555}, {-0.2027,-0.2886}, {0.2872,0.1004}, {0.1029,0.2260}, {-0.2866,-0.0828}, {-0.0255,0.1771}, {0.0432,-0.3023} },
  ["Marsh Map"] = { {-0.1656,0.2634}, {-0.2773,0.1135}, {0.3171,-0.0629}, {0.1611,0.2492}, {0.0420,-0.2351}, {-0.2695,-0.1750}, {0.0338,0.0396} },
  ["Mountain Map"] = { {-0.3392,0.1382}, {0.2882,0.0603}, {0.1637,0.1715}, {0.3020,-0.1292}, {0.1001,-0.2291}, {-0.2885,-0.1012}, {0.0524,0.1094}, {-0.0613,0.1989}, {-0.1274,0.0278}, {-0.0138,-0.0616} },
  ["Gorge Map"] = { {-0.0901,0.3034}, {0.2470,0.2817}, {0.0620,-0.2785}, {-0.2465,-0.2728}, {-0.2369,0.2194}, {-0.1792,-0.1109}, {0.2202,-0.1168}, {0.1241,0.2268} }
}
RTT_RELIC_POS = {
  -- Winter was the ONLY map with no recorded spots, so it alone fell through to rttForestWorldCenters
  -- -- forest CENTROIDS, not relic spots, and that fallback also rotates with the opposite sign to
  -- positionToWorld. The maintainer placed these by hand on the "winter" save and they are read back
  -- out of it in the map's LOCAL frame (map ec2372, rotY 180, scale 12.979; round-trip exact to 1e-15).
  ["Winter Map"] = { {0.0666,-0.6063}, {1.1375,-0.5004}, {-1.1128,-0.2377}, {1.1820,0.2656}, {0.0398,0.3889}, {-1.1061,0.5499}, {-0.5825,0.6303}, {0.7314,0.6679} },
  ["Mountain Map"] = { {-1.2752,0.4425}, {1.0450,0.1418}, {0.5335,-0.2283}, {1.3380,-0.4530}, {0.2831,-0.6898}, {-1.1410,-0.2198}, {0.0122,0.2455}, {-0.0305,0.7701}, {-0.6567,-0.7852}, {-0.2753,-0.4889} },
  ["Marsh Map"] = { {-0.0678,0.8178}, {-1.1516,0.3882}, {1.2343,-0.2220}, {1.0673,0.5145}, {0.5968,-0.9808}, {-0.6581,-0.8845}, {-0.2989,0.0212} },
  ["Summer Map"] = { {0.7320,0.8958}, {-0.0560,0.4389}, {1.2627,0.3846}, {-1.1418,0.4037}, {0.9997,-0.5831}, {-0.3121,-0.3603}, {0.2862,-1.1748} },
  ["Lake Map"] = { {-1.1211,-0.2959}, {-0.9108,0.3943}, {-0.2940,-0.9465}, {-0.0594,0.8413}, {0.0996,-0.7737}, {0.7977,-1.0885}, {0.8064,1.1831}, {1.3309,-0.5795}, {1.3855,0.5549} },
  ["Gorge Map"] = { {1.0178,1.0612}, {-0.3196,1.0236}, {0.7935,0.2055}, {-0.8134,0.1114}, {0.7317,-0.6841}, {-0.5279,-0.7138}, {-0.9583,-0.9725}, {0.2890,-1.1669} }
}


RTT_LIZ_WIZ = { -29.878, 1.552, 9.915 }
RTT_LIZ_WIZ_ROTY = 90
RTT_LIZ_OUTCAST = { -29.220, 11.760, 15.020 }
RTT_POND_SHIFT = { -31.217, 11.562, 21.567 }
RTT_POND_FROG = { -30.882, 11.562, 10.661 }

function rttFactionExtras(faction, cx, cz, flip, isDraft)
  if faction == "The Lizard Cult" then rttLizardSetup()
  elseif faction == "Lilypad Diaspora" then rttFrogsSetup()
  elseif faction == "Keepers in Iron" then rttBadgerRelics()
  -- Twilight Council (bats) now spawns from the baked blueprint (m560) — no runtime setup
  -- Corvid plots + hidden zone now spawn FROM the crow board's own callback (rttSpawnFaction), together
  -- with the faction -- not here on a delay. (No blueprint plots/bot to replace anymore either.)
  -- Underground Duchy (moles) now spawns 7 loose + 13 bagged from the blueprint (m300) — no tuck
  -- Knaves: the Captains board + its pooled captains now spawn FROM the faction blueprint's own
  -- rules-board callback (see rttSpawnFaction), so they appear WITH the faction at the CORRECT seat.
  elseif faction == "Marquise de Cat" then rttMarquiseCats(cx, cz, flip)
  end
end







-- ---- Marquise de Cat: one warrior in the CENTRE of every clearing -------------------------
-- The 3 staging warriors + buildings + Keep are baked (m570/m550) so they spawn in place. Here
-- we only handle the 12 cats on the map: taken STRAIGHT from the Marquise Supply bag onto each
-- clearing CENTRE, so they appear at their spot directly (no default-then-move).
--
-- RTT_CLEARING_CENTRES[map] = the world (x,z) centre of every clearing, converted from the eyes
-- tile-local geometry (root_engine/eyes + maps_data/*_geometry.json) via the shared map transform
-- (scale 12.97936, rotY 180, origin ~0). 12 clearings on the standard maps; 15 positions on Marsh
-- (9 dry + both sides of the 3 flood pairs), of which the 3 inactive ones are skipped so exactly
-- 12 cats land — matched to RTT_MARSH_EXCLUDED (the inactive clearing centres from m440/m500).
-- CALIBRATED 2026-08-28: my raw eyes centres were rotated 180deg the wrong way (systematic error).
-- Flipping x,z (verified against the maintainer's placed cats on Gorge: mean error 3.9u -> 1.0u) fixes every
-- map. Gorge uses the maintainer's exact recorded cat positions (0 residual). Other maps can be swapped to
-- exact recorded positions the same way if the maintainer places cats on them.
RTT_CLEARING_CENTRES = {
  ["Summer Map"] = {
    {-19.93,17.20},{18.64,12.35},{16.63,-16.88},{-19.64,-14.75},{2.61,19.06},{20.57,-0.96},
    {4.35,-12.68},{-7.15,-17.75},{-19.97,4.46},{-3.86,9.80},{6.98,0.73},{-9.48,-2.60},
  },
  ["Winter Map"] = {
    {-18.44,17.15},{19.13,11.93},{17.29,-16.97},{-18.21,-14.11},{-6.15,15.14},{5.33,13.16},
    {20.40,-3.59},{4.25,-10.36},{-6.29,-16.89},{-18.38,3.32},{-6.94,0.25},{6.45,1.36},
  },
  ["Lake Map"] = {
    {17.60,-16.47},{-18.05,14.78},{-19.77,-14.57},{20.53,8.42},{19.38,-3.77},{9.91,13.41},
    {-2.61,17.40},{-20.76,0.44},{-3.08,-17.80},{-9.60,6.61},{8.23,0.81},{-8.05,-7.53},
  },
  ["Mountain Map"] = {
    {-19.90,15.43},{16.43,13.40},{18.52,-13.08},{-18.60,-14.71},{1.80,15.93},{20.73,0.39},
    {3.35,-16.20},{-21.00,-3.24},{-10.72,7.35},{-0.48,4.73},{6.54,-5.15},{-8.25,-7.98},
  },
  ["Marsh Map"] = {
    {-19.09,17.22},{20.91,13.56},{16.19,-17.23},{-20.63,-16.61},{-5.29,17.90},{7.54,16.61},
    {20.53,-6.91},{0.28,-16.65},{-8.35,-12.21},{-20.89,-2.52},{-11.46,7.53},{15.31,3.58},
    {7.21,-7.24},{-4.84,-0.88},{2.18,6.55},
  },
  ["Gorge Map"] = {
    {-19.39,16.52},{-18.72,-4.28},{-18.52,-17.16},{-15.54,5.94},{-2.33,-14.98},{-0.95,-4.64},
    {-0.21,7.80},{4.71,17.37},{11.38,-17.08},{14.73,6.66},{17.98,-3.87},{18.48,16.10},
  },
}

-- Three supporters into the Alliance's supporters hand. Two races made this intermittent -- the
-- maintainer: "sometimes it works, but sometimes it bugs a bit":
--   1. setHandTransform is not instant. Reading getHandTransform(2) too early returns the PARKED zone
--      (all ten sit at x=-75), so the cards were placed way off to the side. Fixed by waiting until the
--      position actually CHANGES from what it was before spawnSupportersHand ran.
--   2. Three takeObject calls in one frame hit the deck-busy / collapse race this file already documents
--      elsewhere ("one at a time = no deck-busy / collapse race"). Fixed by taking one per 0.25s.
-- deck.deal(3, color, 2) is not used: it does not honour the hand index. Dropping a card inside a hand
-- volume is what puts it in that hand.
RTT_ALLY_SUP_SPREAD = { -3.5, 0.0, 3.5 }
RTT_ALLY_SUP_DONE   = {}         -- [colour] = true once dealt this game; cleared with the run state

function rttDealAllianceSupporters(color, before, tries)
  if color == nil or color == "" then return end
  if RTT_ALLY_SUP_DONE[color] then return end
  local h2 = nil
  pcall(function() h2 = Player[color].getHandTransform(2) end)
  local ready = h2 ~= nil and h2.position ~= nil
  if ready and before ~= nil then
    local d = (h2.position.x - before.x) ^ 2 + (h2.position.z - before.z) ^ 2
    ready = d > 0.25                                   -- it has actually moved off the parked spot
  end
  if not ready then
    if (tries or 0) > 0 then
      Wait.time(function() rttDealAllianceSupporters(color, before, tries - 1) end, 0.25)
    end
    return
  end
  local deck = rttFindMainDeck()
  if deck == nil then return end                       -- no deck: draw nothing
  RTT_ALLY_SUP_DONE[color] = true
  -- A hand zone's rotation.y points the way the OWNER faces; a card laid at that same y reads upside
  -- down to them, so the card facing is the zone's y turned 180. (The spread still runs along the
  -- zone's own right vector, which is computed from the zone's y, not the card's.)
  local zy = h2.rotation.y
  local ry = (zy + 180) % 360
  local rx, rz = math.cos(math.rad(zy)), -math.sin(math.rad(zy))
  local function place(i)
    if i > 3 then return end
    local off = RTT_ALLY_SUP_SPREAD[i]
    pcall(function()
      deck.takeObject({
        position = { h2.position.x + rx * off, h2.position.y + 0.6, h2.position.z + rz * off },
        rotation = { 0, ry, 0 },
        -- Animate it. takeObject with no index takes the TOP card, and smooth makes it visibly travel
        -- from the deck to the supporters stack, so it reads as coming off the top rather than simply
        -- appearing there (maintainer request).
        smooth   = true,
        -- "sometimes he throws the three cards upside down": rotation alone is not enough, because a
        -- card's own face-up sense depends on how it sat in the deck. Check and flip.
        callback_function = function(c)
          pcall(function() if c.is_face_down then c.flip() end end)
          pcall(function() c.addTag("RTT Faction") end)
        end,
      })
    end)
    Wait.time(function() place(i + 1) end, 0.6)        -- one at a time: no deck-busy / collapse race,
                                                       -- and long enough that each card's flight is seen
  end
  place(1)
end

-- ---- Faction Cards: the maintainer's "Hoot Draft" saved object -------------------------------
-- FIVE decks laid out in a row on the right of the table. Four are exactly as he saved them; the
-- fifth is the twelve VAGABOND CHARACTER CARDS, which used to need their own button.
-- Zaandaa: picking a Vagabond manually already gives you that character's meeple AND its card
-- (verified -- every character blueprint carries both), so the old "Vagabond Cards" tool was 21
-- duplicate meeples wrapped around one useful deck. Only the deck comes along; the button is gone and
-- its slot on the tools row is free.
-- Its spot is the maintainer's own, read out of his save 'faction' (TS_Save_30, 2026-09-05 22:50):
-- (50.225, 11.640, 28.681), a SECOND ROW behind the captains deck rather than a fifth along the first.
-- I had guessed x 34.3 continuing the row; he put it back where he wanted it.
-- The tool itself stays in EVERYTHING, unreferenced -- it is base-mod content, not RTT's to delete.
-- Not tagged for teardown -- like the other tool buttons, this is a reference aid that survives a
-- new game rather than faction kit that goes out with it.
RTT_HOOT = {
  { pos = { 66.140, 11.610, 23.260 }, json = [===[{"GUID": "403b02","Name": "Deck","Transform": {"posX": 66.13635,"posY": 11.6113586,"posZ": 23.2569218,"rotX": -4.18478443e-08,"rotY": 269.989532,"rotZ": -1.441599e-08,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"Tags": ["Shuffleable"],"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [309,307,310,301,73200,300],"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"732": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10042992881391430383/BAE426B4F4BD70FF7A6084DFA55961800C0F83DF/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "39be49","Name": "Card","Transform": {"posX": -1.66627669,"posY": 1.05879366,"posZ": -4.028566,"rotX": -0.0006826586,"rotY": 179.990768,"rotZ": -0.00112713769,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 309,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e8f093","Name": "Card","Transform": {"posX": -1.05922115,"posY": 0.9735951,"posZ": -3.99652,"rotX": 4.55595364e-05,"rotY": 179.990768,"rotZ": -0.000284563663,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 307,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "ed28df","Name": "Card","Transform": {"posX": -1.00858307,"posY": 1.15495336,"posZ": -3.80439377,"rotX": 1.40676332,"rotY": 179.996048,"rotZ": 5.81672975e-05,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 310,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "8df1be","Name": "Card","Transform": {"posX": -0.282207727,"posY": 1.04952276,"posZ": -3.6216743,"rotX": 0.00066678843,"rotY": 179.990768,"rotZ": -0.0006546988,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 301,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "35b81a","Name": "CardCustom","Transform": {"posX": 57.3735352,"posY": 11.6722345,"posZ": 22.0381832,"rotX": 0.0005990316,"rotY": 269.986877,"rotZ": -0.0033355006,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73200,"SidewaysCard": false,"CustomDeck": {"732": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10042992881391430383/BAE426B4F4BD70FF7A6084DFA55961800C0F83DF/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "c8f4ed","Name": "Card","Transform": {"posX": -1.57336509,"posY": 1.015244,"posZ": -3.802666,"rotX": 0.000971112,"rotY": 179.990768,"rotZ": -0.00130566931,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 300,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
  { pos = { 58.220, 11.610, 23.175 }, json = [===[{"GUID": "9957df","Name": "Deck","Transform": {"posX": -7.920185,"posY": 0.0,"posZ": -0.08452225,"rotX": -5.06577758e-09,"rotY": 269.9901,"rotZ": 2.459669e-08,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"Tags": ["Shuffleable"],"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [305,302,73000,304,308,73300],"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"730": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/17156148149837033890/98EA362B4304B9B9E5825AAE0D213A17FC4BBB7C/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"733": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10654530041309384819/5D0D59497688830C050F1BA44431CAB1104B7F3F/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "bdce9c","Name": "Card","Transform": {"posX": -34.3895874,"posY": 11.6095686,"posZ": 27.29517,"rotX": 359.7493,"rotY": 180.002716,"rotZ": 359.870728,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 305,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "c7b1d4","Name": "Card","Transform": {"posX": 5.14010143,"posY": 2.063494,"posZ": -4.39241171,"rotX": 359.8631,"rotY": 179.974548,"rotZ": -0.002107894,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 302,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "9be262","Name": "CardCustom","Transform": {"posX": 65.30026,"posY": 11.7010155,"posZ": 22.1271057,"rotX": 0.000114221068,"rotY": 269.986877,"rotZ": -0.0006956121,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73000,"SidewaysCard": false,"CustomDeck": {"730": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/17156148149837033890/98EA362B4304B9B9E5825AAE0D213A17FC4BBB7C/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "201005","Name": "Card","Transform": {"posX": -34.0781059,"posY": 11.6981983,"posZ": 27.2413673,"rotX": 0.0345823355,"rotY": 180.00032,"rotZ": 0.0251624361,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 304,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "06ace2","Name": "Card","Transform": {"posX": 49.28753,"posY": 11.5751371,"posZ": 22.6206779,"rotX": 5.08970043e-05,"rotY": 269.9901,"rotZ": -0.000322228385,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 308,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e88b64","Name": "CardCustom","Transform": {"posX": 49.4498253,"posY": 11.6168051,"posZ": 23.0559349,"rotX": 0.00105606078,"rotY": 269.9901,"rotZ": -0.00123060483,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73300,"SidewaysCard": false,"CustomDeck": {"733": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10654530041309384819/5D0D59497688830C050F1BA44431CAB1104B7F3F/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
  { pos = { 50.219, 11.610, 23.191 }, json = [===[{"GUID": "e8dd4b","Name": "Deck","Transform": {"posX": -15.9210091,"posY": 0.028883934,"posZ": -0.0693779,"rotX": -7.1069195e-07,"rotY": 270.004669,"rotZ": -3.43679e-08,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [73409,73407,73410,73408,73406,73405,73404,73403,73402,73401,73400,73411],"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "acbc3d","Name": "Card","Transform": {"posX": -37.2867622,"posY": 12.70675,"posZ": -46.94957,"rotX": 0.0173129272,"rotY": 179.077057,"rotZ": 0.00480428524,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73409,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "252650","Name": "Card","Transform": {"posX": -37.3049927,"posY": 12.8145609,"posZ": -46.84961,"rotX": 0.00737715652,"rotY": 181.983322,"rotZ": -0.00153741566,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73407,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "f1926e","Name": "Card","Transform": {"posX": -37.341568,"posY": 12.73394,"posZ": -46.7927475,"rotX": 0.0169589818,"rotY": 178.502319,"rotZ": 0.00245550717,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73410,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "29250a","Name": "Card","Transform": {"posX": -37.3842278,"posY": 12.7875166,"posZ": -46.9959221,"rotX": 0.00554778334,"rotY": 180.2782,"rotZ": 0.00505224941,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73408,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e68a7c","Name": "Card","Transform": {"posX": -37.3187027,"posY": 12.8410263,"posZ": -46.89997,"rotX": -0.00189985591,"rotY": 179.827484,"rotZ": 359.9936,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73406,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "1c0bd9","Name": "Card","Transform": {"posX": -37.41384,"posY": 12.8680658,"posZ": -47.0249023,"rotX": 359.9936,"rotY": 179.62326,"rotZ": -0.00395905,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73405,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "3cdb77","Name": "Card","Transform": {"posX": -37.33973,"posY": 12.975421,"posZ": -46.9574242,"rotX": 359.986328,"rotY": 180.108688,"rotZ": 359.991821,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73404,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "4101c5","Name": "Card","Transform": {"posX": -37.39057,"posY": 12.9484282,"posZ": -46.90895,"rotX": 359.9878,"rotY": 180.0682,"rotZ": -0.00543547142,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73403,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "5e03db","Name": "Card","Transform": {"posX": -37.342495,"posY": 12.92145,"posZ": -46.90487,"rotX": 359.9891,"rotY": 179.892639,"rotZ": -0.000873302342,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73402,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "27c9f0","Name": "Card","Transform": {"posX": -37.37935,"posY": 12.8945646,"posZ": -46.88789,"rotX": 359.98468,"rotY": 179.929886,"rotZ": -0.00236153952,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73401,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "2fa5dc","Name": "Card","Transform": {"posX": -37.5073051,"posY": 12.760704,"posZ": -47.0255,"rotX": 0.0113861654,"rotY": 180.72403,"rotZ": 0.00426952168,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73400,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "aefc79","Name": "Card","Transform": {"posX": 47.41141,"posY": 11.7373362,"posZ": 5.35248375,"rotX": 0.000762851967,"rotY": 270.004669,"rotZ": -0.002081007,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73411,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
  -- the VAGABOND FACTION card (CardID 303), on the vagabond row to the right of the 12 character
  -- cards and in line with the first 6-card faction deck below it. It is on the same 6x2 faction
  -- sheet as the others but belongs to neither deck: they hold twelve factions between them and
  -- 303 is not among them, so Faction Cards laid out every faction EXCEPT the vagabond.
  -- (306 is missing too and is probably the second vagabond card -- Root ships one per vagabond.
  -- Not added: the maintainer asked for this one.)
  { pos = { 58.220, 11.640, 28.681 }, json = [===[{"GUID":"304b65","Name":"Card","Transform":{"posX":58.22,"posY":11.64,"posZ":28.681,"rotX":0.0,"rotY":270.0,"rotZ":0.0,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":303,"SidewaysCard":false,"CustomDeck":{"3":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth":6,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]===] },
  { pos = { 50.225, 11.640, 28.681 }, json = [===[{"GUID":"7dcfee","Name":"Deck","Transform":{"posX":34.3,"posY":11.61,"posZ":23.3,"rotX":0.0,"rotY":270.0,"rotZ":0.0,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"Tags":["Shuffleable"],"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":false,"SidewaysCard":false,"DeckIDs":[15500,15100,15200,15300,15400,13500,15600,15700,15800,15900,16000,16100],"CustomDeck":{"155":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518354213/87AA5C7CE4192FBC0900B24EC7DEAB95110CAB94/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"151":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518329159/8328799796E99F07C70A40E7672868F5167091DF/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"152":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518340482/8AD75E0065109B2350D989D473EBEC170E92BB60/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"153":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518351843/2817F237F33C253197D96E9534C17004F2B3D661/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"154":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518347391/31E9550DB276915F3EA1F27CD387ADCE81657B2E/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"135":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518344983/D250C9591D68B83499A8952BCA5C684F04E13980/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"156":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518338312/9FDA298CAA9675B5DDAC29F1AA1C19DA44AC4BBF/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"157":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/9715137049291250258/F30E61793E905F6E1533FE9EDC0F1A56BDFA4599/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"158":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518335622/3748A07E731D02DC842DFA4D3A92481E4B082D51/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"159":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/17054253170673223723/1A60EF6DD0BD8F3D5C4E6C3CFA599D10D1CF5964/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"160":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518342845/80BF0B8B6BC138E676AF31B3055DF2124E7F2F4B/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0},"161":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/16412665468354300121/A39A52FCDB29E80B91771D6C1C975A2AB8B4B79C/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","ContainedObjects":[{"GUID":"2ee6a8","Name":"CardCustom","Transform":{"posX":6.01742935,"posY":11.6004028,"posZ":-2.72917485,"rotX":359.768036,"rotY":152.557449,"rotZ":0.09890346,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15500,"SidewaysCard":false,"CustomDeck":{"155":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518354213/87AA5C7CE4192FBC0900B24EC7DEAB95110CAB94/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"00de27","Name":"CardCustom","Transform":{"posX":5.85394573,"posY":11.6534891,"posZ":-3.12999964,"rotX":359.8967,"rotY":179.563187,"rotZ":0.0333842635,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15100,"SidewaysCard":false,"CustomDeck":{"151":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518329159/8328799796E99F07C70A40E7672868F5167091DF/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"b87bdc","Name":"CardCustom","Transform":{"posX":-0.246929169,"posY":12.63769,"posZ":-2.177077,"rotX":-0.000507983146,"rotY":179.985336,"rotZ":359.441681,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15200,"SidewaysCard":false,"CustomDeck":{"152":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518340482/8AD75E0065109B2350D989D473EBEC170E92BB60/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"2b7dad","Name":"CardCustom","Transform":{"posX":-3.33066964,"posY":12.5851746,"posZ":-4.81101847,"rotX":6.829838e-05,"rotY":180.006744,"rotZ":-0.000494616048,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15300,"SidewaysCard":false,"CustomDeck":{"153":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518351843/2817F237F33C253197D96E9534C17004F2B3D661/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"e6959b","Name":"CardCustom","Transform":{"posX":5.95957756,"posY":12.5852194,"posZ":-6.465284,"rotX":-5.974894e-05,"rotY":180.006836,"rotZ":0.0006464634,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15400,"SidewaysCard":false,"CustomDeck":{"154":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518347391/31E9550DB276915F3EA1F27CD387ADCE81657B2E/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"2099b3","Name":"CardCustom","Transform":{"posX":15.3654165,"posY":12.5851936,"posZ":-2.16720343,"rotX":-2.04235455e-08,"rotY":0.006672732,"rotZ":-6.902665e-08,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":13500,"SidewaysCard":false,"CustomDeck":{"135":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518344983/D250C9591D68B83499A8952BCA5C684F04E13980/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"2099b3","Name":"CardCustom","Transform":{"posX":-12.5090246,"posY":11.5976706,"posZ":-6.30794239,"rotX":359.8891,"rotY":180.089844,"rotZ":359.9683,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15600,"SidewaysCard":false,"CustomDeck":{"135":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518338312/9FDA298CAA9675B5DDAC29F1AA1C19DA44AC4BBF/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"b039e6","Name":"CardCustom","Transform":{"posX":-12.0997181,"posY":11.6730814,"posZ":-6.400945,"rotX":359.9706,"rotY":179.747772,"rotZ":0.0175035931,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15700,"SidewaysCard":false,"CustomDeck":{"154":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/9715137049291250258/F30E61793E905F6E1533FE9EDC0F1A56BDFA4599/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"e128a2","Name":"CardCustom","Transform":{"posX":-12.0702095,"posY":11.7152653,"posZ":-6.25792646,"rotX":359.97403,"rotY":179.919113,"rotZ":0.0377025828,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15800,"SidewaysCard":false,"CustomDeck":{"155":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518335622/3748A07E731D02DC842DFA4D3A92481E4B082D51/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"75541a","Name":"CardCustom","Transform":{"posX":-11.4748478,"posY":11.7109194,"posZ":-6.48400831,"rotX":359.9555,"rotY":179.4938,"rotZ":0.04511651,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":15900,"SidewaysCard":false,"CustomDeck":{"156":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/17054253170673223723/1A60EF6DD0BD8F3D5C4E6C3CFA599D10D1CF5964/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"7599de","Name":"CardCustom","Transform":{"posX":-13.187829,"posY":12.6111717,"posZ":-8.794435,"rotX":359.98703,"rotY":180.027328,"rotZ":359.9822,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":16000,"SidewaysCard":false,"CustomDeck":{"152":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518342845/80BF0B8B6BC138E676AF31B3055DF2124E7F2F4B/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"27a118","Name":"CardCustom","Transform":{"posX":-10.814064,"posY":12.585206,"posZ":-9.697414,"rotX":-0.000102966325,"rotY":180.043289,"rotZ":0.00119236554,"scaleX":2.33,"scaleY":1.0,"scaleZ":2.33},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":16100,"SidewaysCard":false,"CustomDeck":{"153":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/16412665468354300121/A39A52FCDB29E80B91771D6C1C975A2AB8B4B79C/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/16030719257570838189/A3D1E15FC5407337440A4BB4B5875ACD65A3E7F7/","NumWidth":1,"NumHeight":1,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]}]===] },
  { pos = { 42.267, 11.610, 23.326 }, json = [===[{"GUID": "375d27","Name": "Deck","Transform": {"posX": -23.8734283,"posY": -0.009628296,"posZ": 0.0658226,"rotX": -2.18906511e-08,"rotY": 269.991058,"rotZ": -2.48258829e-07,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": true,"DeckIDs": [806,802,805,801,800],"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "f5c1a1","Name": "Card","Transform": {"posX": 54.033844,"posY": 11.5751276,"posZ": 41.93617,"rotX": 9.637025e-05,"rotY": 269.986145,"rotZ": -0.000609488867,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 806,"SidewaysCard": true,"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "1f115c","Name": "Card","Transform": {"posX": 54.2405319,"posY": 11.6167641,"posZ": 41.7797546,"rotX": -0.0013511132,"rotY": 269.9779,"rotZ": -0.000457857968,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 802,"SidewaysCard": true,"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "8491fb","Name": "Card","Transform": {"posX": 54.0117874,"posY": 11.650692,"posZ": 41.05148,"rotX": -0.000351022172,"rotY": 269.987885,"rotZ": -0.00249138731,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 805,"SidewaysCard": true,"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "7557a4","Name": "Card","Transform": {"posX": 54.3442,"posY": 11.6602964,"posZ": 42.1546669,"rotX": 0.00148005283,"rotY": 269.986145,"rotZ": -0.00120903924,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 801,"SidewaysCard": true,"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "17843f","Name": "Card","Transform": {"posX": 54.033844,"posY": 11.5751276,"posZ": 41.93617,"rotX": 9.637025e-05,"rotY": 269.986145,"rotZ": -0.000609488867,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 800,"SidewaysCard": true,"CustomDeck": {"8": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth": 5,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
}

function rttSpawnHootDraft()
  for _, e in ipairs(RTT_HOOT) do
    spawnObjectJSON({
      json = e.json,
      position = { e.pos[1], e.pos[2], e.pos[3] },
      rotation = { 0, 270, 0 },
      callback_function = function(o) pcall(function() o.setLock(false) end) end,
    })
  end
end

-- ---- Underground Duchy: the Mole Monger, beside the mole player's own seat --------------------
-- SEAT-LOCAL offsets, mirrored for the far row like every other seat-relative placement. Recovered
-- from the saves "moles" (Duchy in 4p seat 2) and "moles b" (4p seat 1, and 5p seat 2).
-- The maintainer said the "moles" position covers seats 2 AND 4. Those two seats are diagonal
-- opposites, so that can only mean a seat-LOCAL offset that mirrors -- read as one absolute spot it
-- put the Monger at seat 2's side of the table while he was playing seat 4, which is exactly what he
-- reported. Same for "moles b" covering seats 1 and 3.
-- Two offsets because the two columns need opposite inward directions: a left-hand seat puts the
-- Monger to its right, a right-hand seat to its left. Both land it between the board and the table
-- centre, on the player's own side.
RTT_MONGER_LEFT  = {  25.7250, 11.562, -8.5300 }   -- seats on the LEFT  of the table: (-52,-46), (52,46)
RTT_MONGER_RIGHT = { -19.1480, 11.562, -8.5210 }   -- seats on the RIGHT, and the centre seats

-- A seat is "left" when its x and z share a sign -- that is the far row's mirror of the near row's
-- left-hand seat. The centre seats (x = 0) have no side and take the RIGHT offset, which is the case
-- the maintainer pinned with 5p seat 2.
function rttMongerSpot(cx, cz, flip)
  local o = ((cx < 0 and cz < 0) or (cx > 0 and cz > 0)) and RTT_MONGER_LEFT or RTT_MONGER_RIGHT
  local s = flip and -1 or 1
  return { cx + o[1] * s, o[2], cz + o[3] * s }
end

function rttMoleMonger(cx, cz, flip)
  local def = EVERYTHING["Tools"] and EVERYTHING["Tools"]["Mole Monger"]
  if def == nil or def['data'] == nil or def['data'][1] == nil then return end
  local p = rttMongerSpot(cx, cz, flip)
  spawnObjectJSON({
    json = def['data'][1].json,
    position = { p[1], p[2], p[3] },
    rotation = { 0, flip and 0 or 180, 0 },        -- both saved copies face the near row at rotY 180
    callback_function = function(o)
      pcall(function() o.addTag("RTT Faction") end)   -- goes out WITH the faction on a reset
      pcall(function() o.setLock(true) end)           -- parked reference tile; he locked his own copy
    end
  })
end

-- ---- Lord of the Hundreds: the Mini-Mood Manager, on the rats board --------------------------
-- Maintainer 2026-09-04: it is no longer an option button; it spawns with the rats, at the spot he
-- placed it in the save named "rats" (TS_Save_19). Layout recovered from that save, seat 2 (near row),
-- as seat-local offsets in the tool's own blueprint order -- the board tile first, then the eight mood
-- cards -- so it mirrors correctly for a far-side seat like every other seat-relative placement.
RTT_MOOD_LOCAL = {
  {   3.0223, 11.7502,  -9.1637 },
  {   6.4260, 11.9038, -10.0789 },
  {   6.4257, 11.9044,  -8.2196 },
  {   6.4340, 11.9049,  -6.4019 },
  {   3.0233, 11.9088,  -9.1709 },
  {  -0.4239, 11.9127, -11.9238 },
  {  -0.4199, 11.9133, -10.0783 },
  {  -0.4162, 11.9138,  -8.2331 },
  {  -0.4258, 11.9144,  -6.3879 },
}

function rttRatsMoodManager(cx, cz, flip)
  local def = EVERYTHING["Tools"] and EVERYTHING["Tools"]["Mini-Mood Manager"]
  if def == nil or def['data'] == nil then return end
  local ry = flip and 0 or 180                      -- his save is rotY 180 at a near-row seat
  for i, v in ipairs(def['data']) do
    local l = RTT_MOOD_LOCAL[i]
    if l ~= nil then
      local lx, lz = l[1], l[3]
      if flip then lx, lz = -lx, -lz end
      -- i == 1 was the manager BOARD tile. It is now PRINTED INTO the rats board art itself
      -- (assets/board/rats_board_mood.png), so there is no second object to stack, lock or wipe --
      -- only the eight mood cards still spawn, and they land on the printed slots.
      if i > 1 then
        spawnObjectJSON({
          json = v.json,
          position = { cx + lx, l[2], cz + lz },
          rotation = { 0, ry, 0 },
          callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end
        })
      end
    end
  end
end

function rttMarquiseCats(cx, cz, flip)
  -- resolve the current map (same fallback chain as rttBadgerRelics: clone -> main board bab7e1)
  local mapId = RTT_CURRENT_MAP or (RTT_PICKED or {}).map
  if mapId == nil then
    local mb = getObjectFromGUID("bab7e1")
    if mb ~= nil then
      local ok, mid = pcall(function() return mb.call("rttGetCurrentMap") end)
      if ok and type(mid) == "string" then mapId = mid end
    end
  end
  local centres = RTT_CLEARING_CENTRES[mapId]
  if centres == nil then return end
  local bag = nil
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == "Marquise Supply" then bag = o break end
  end
  if bag == nil then return end
  -- Marsh clearings depend on player count: 4-player floods 3 clearings (skip them -> 12 cats);
  -- 5-player has no floods, all 15 clearings are active (place 15). Every other map is 12.
  local excl = {}
  if mapId == "Marsh Map" then
    local is5p = RTT_5P_MARSH
    if is5p == nil then
      local mb = getObjectFromGUID("bab7e1")
      if mb ~= nil then
        local ok, v = pcall(function() return mb.call("rttGet5pMarsh") end)
        if ok then is5p = v end
      end
    end
    if not is5p then                               -- 4-player: skip the 3 flooded clearing centres
      excl = RTT_MARSH_EXCLUDED
      if excl == nil then
        local mb = getObjectFromGUID("bab7e1")
        if mb ~= nil then
          local ok, ex = pcall(function() return mb.call("rttGetMarshExcluded") end)
          if ok and type(ex) == "table" then excl = ex end
        end
      end
      excl = excl or {}
    end
  end
  for _, c in ipairs(centres) do
    local skip = false
    for _, e in ipairs(excl) do                    -- Marsh: skip the 3 inactive clearing centres
      local dx, dz = c[1] - e[1], c[2] - e[2]
      if dx * dx + dz * dz < 20.0 then skip = true break end   -- ~4.5u = same clearing
    end
    if not skip then
      pcall(function() bag.takeObject({ position = { c[1], 12.6, c[2] }, rotation = { 0, 180, 0 }, smooth = false,
        callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end }) end)  -- upright (standing)
    end
  end
end

-- ---- Knaves of the Deepwood: draft 4 RANDOM captains, remove the other 8 -----------------
-- The faction spawns a 12-card Captain deck (DeckIDs 73400-73411, shared face sheet
-- FA78C0...037E95) with an EMPTY nickname, so the base rttKnavesCaptains name-match never
-- fires and all 12 just sit there. the maintainer wants only 4 random captains kept, laid out in a
-- visible row where the deck spawned; the rest are discarded. Identify the deck by its face
-- sheet (nickname/GMNotes are all blank), scoped to this seat.
-- find the 12-card Captain deck near the seat. Prefer the deck whose face sheet is the Captain
-- sheet (FA78C0...), but fall back to the nearest Deck within 20u of the seat (the Knaves faction
-- has only one deck near its board), so a getData() quirk can't leave all 12 captains in play.

-- keep polling until the faction spawn has produced the Captain deck, then keep 4 random


-- pick the big faction-board tile that just spawned nearest a seat (cx,cz)
function rttFindSeatBoard(cx, cz)
  local board, bestD = nil, 1e9
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Custom_Tile" then
      local s = o.getScale()
      if s ~= nil and s.x >= 7.5 then
        local p = o.getPosition()
        local d = (p.x - cx) ^ 2 + (p.z - cz) ^ 2
        if d < bestD and d < 900 then bestD = d; board = o end
      end
    end
  end
  return board
end

-- ---- Corvid Conspiracy (crows): 12 plots, 3 of each type, in a clean 4x3 grid --------
RTT_CROW_BOARD_IMG = "91D872F5EEF83D8BA244B2EFB04D155D97C88F43"  -- crow rules board face (spawn-trigger anchor)
RTT_RATS_BOARD_IMG = "rats_board_mood_v3.png"                    -- rats board face, mood manager printed in
RTT_CROW_COLS = { -0.400, -0.577, -0.754, -0.931 }
RTT_CROW_ROWS = { -1.166, -1.353, -1.540 }
-- the 4 starting Corvid warriors, board-local (recorded from the maintainer's save): a row by the supply
RTT_CROW_WAR = { { 0.330, -1.157 }, { 0.499, -1.157 }, { 0.668, -1.157 }, { 0.837, -1.157 } }

function rttCrowsPlots(cx, cz, flip, isDraft, board)
  board = board or rttFindSeatBoard(cx, cz)
  if board == nil then return end
  -- THE HIDDEN ZONE FIRST, because the plots now go INSIDE it and take their positions from it.
  -- They used to be laid face DOWN on the crow board's own 4x3 grid, which meant the crow player could
  -- not read their own plots without picking each one up in front of everybody. The zone is fogged to
  -- that player's colour, so face UP inside it they read at a glance and opponents see a blank block.
  -- (Face down in a zone would gain nothing: a face-down tile is unreadable to its owner too.)
  local hz = rttCrowsHiddenZone(board, cx, cz, isDraft)
  local ry = board.getRotation().y
  for i, blob in ipairs(RTT_CROW_PLOTS or {}) do
    local idx = i - 1
    local col = math.floor(idx / 3) + 1
    local row = (idx % 3) + 1
    local w, rz
    if hz ~= nil then
      -- 4 x 3 centred on the zone. Spacing is world units, not board-local: the grid is 4.7 x 3.3
      -- against a 13.3 x 9.5 zone, so it sits well inside with room to grab a tile.
      local dx = (col - 2.5) * RTT_CROW_PLOT_GAP
      local dz = (row - 2.0) * RTT_CROW_PLOT_GAP
      local ca, sa = math.cos(math.rad(ry)), math.sin(math.rad(ry))
      w  = { x = hz.x + dx * ca + dz * sa, y = hz.y, z = hz.z - dx * sa + dz * ca }
      rz = 0                              -- FACE UP: the zone is what hides them
    else
      -- no zone (an older bake, or the blob missing): the original on-board grid, face down
      w  = board.positionToWorld({ RTT_CROW_COLS[col], 0.03, RTT_CROW_ROWS[row] })
      w.y = w.y + 0.2
      rz = 180
    end
    spawnObjectJSON({
      json = blob,
      position = { w.x, w.y, w.z },
      rotation = { 0, ry, rz },
      callback_function = function(o) o.setLock(false) o.addTag("RTT Faction") end   -- cleared with the faction
    })
  end
end

-- the maintainer's hidden-plot cover: a Hidden Zone (FogOfWarTrigger) parked to the RIGHT of the plot grid.
-- Its FogColor decides who can see inside; grey/White = everyone, so we recolour it to the crow
-- player's own colour (the seated player nearest the crow board) so only they can see their plots.
function rttCrowsHiddenZone(board, cx, cz, isDraft)
  if board == nil or RTT_CROW_HZ_JSON == nil then return end
  -- (spawns on BOTH the ranked draft AND the manual faction-selector path -- the hidden area was
  --  missing on manual because it used to early-return here when not a draft.)
  -- Every seat gets one, at 5 players too. There used to be an exception that skipped seats 1-3 in a
  -- 5-player game; the maintainer asked for the hidden box in ALL seats.
  -- crow player's colour = the seated player nearest the crow board
  local color, best = "White", nil
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then
      local ht = nil
      pcall(function() ht = p.getHandTransform().position end)
      if ht ~= nil then
        local d = (ht.x - cx) ^ 2 + (ht.z - cz) ^ 2
        if best == nil or d < best then best = d; color = p.color end
      end
    end
  end
  -- Maintainer's rule: hidden box on the player's LEFT for seats 1 & 3 (table +x side), RIGHT for seats
  -- 2 & 4 (table -x side). TWO things decide the board-local x, and BOTH matter:
  --   (1) WHICH visual side the player wants -- read from the board's own world x (cx): cx>0 -> left.
  --   (2) how board-local +x MAPS to a visual side -- this FLIPS with the board's row rotation: on a
  --       near-row board (rotY~0) +x is the player's LEFT, on a far-row board (rotY~180) +x is their
  --       RIGHT. (This is what inverted the far-row seats 3 & 4 when I used cx alone.)
  -- Using cx (not RTT_SEATS) keeps it working for the manual 4-player selector, which never sets seats.
  -- NB the crow FACTION board's rotY is 0 on the far row (cz>0) and 180 on the near row (cz<0) -- opposite
  -- of the selector boards -- so board-local +x reads as the player's LEFT when rotY~180, RIGHT when rotY~0.
  local ry = board.getRotation().y % 360
  local leftSign = (ry > 90 and ry < 270) and 1 or -1   -- board-local x that reads as the player's LEFT
  -- cx >= 0, not cx > 0: the CENTRE seats sit at cx == 0 and fell through to the -x side, putting the
  -- box on the wrong side of the board. They now match seat 1 -- the box to the player's LEFT, at the
  -- same offset from the board -- which is what the maintainer asked for for 5-player seat 2.
  local sideSign = (cx >= 0) and leftSign or -leftSign   -- the box's board-local side (the correct L/R side)
  -- Closeness follows the box's SIDE, not cx: the +x side is the player's LEFT AND is opposite the crafted
  -- board (at ~ -1.79), so it comes in CLOSER; the -x side is the crafted side, so it stays FARTHER to
  -- clear the crafted. (Keying this on cx put the closer box on the wrong far-row seat -- 4 instead of 3.)
  local mag = (sideSign > 0) and RTT_CROW_HZ_LX_LEFT or RTT_CROW_HZ_LX
  local lx = sideSign * mag
  local w = board.positionToWorld({ lx, 0.30, RTT_CROW_HZ_LZ })
  local blob = string.gsub(RTT_CROW_HZ_JSON, '"FogColor":"White"', '"FogColor":"' .. color .. '"')
  spawnObjectJSON({
    json = blob,
    position = { w.x, 14.11, w.z },
    rotation = { 0, board.getRotation().y, 0 },        -- straightened: aligned to the crow board
    scale = { RTT_CROW_HZ_SX, RTT_CROW_HZ_SY, RTT_CROW_HZ_SZ },  -- uniform dimensions for every seat
    callback_function = function(o) o.setLock(true) o.addTag("RTT Faction") end
  })
  -- Where it went, so rttCrowsPlots can lay the plots inside it. Returning this rather than having the
  -- caller recompute the same arithmetic is what keeps the two in step: if the zone is moved -- and the
  -- maintainer has asked Zaandaa whether this spot is right -- only RTT_CROW_HZ_LX/_LZ change, and the
  -- plots follow on the next spawn with nothing else to update.
  return { x = w.x, y = 14.11 + RTT_CROW_PLOT_Y, z = w.z }
end

-- ---- Lizard Cult ----------------------------------------------------------
function rttLizardSetup()
  -- if the frog's Pond is already on the table (frog picked BEFORE the lizard), push it to the shifted
  -- spot so the Lizard Wizard doesn't land on top of it. (Lizard-FIRST already spawns the pond shifted,
  -- because rttSpawnPond checks RTT_FAC_TAKEN; this handles the OTHER order.)
  for _, o in ipairs(getObjectsWithTag("RTT Pond")) do
    pcall(function() o.setLock(false) end)
    pcall(function() o.setPosition({ RTT_POND_SHIFT[1], RTT_POND_SHIFT[2], RTT_POND_SHIFT[3] }) end)
    pcall(function() o.setRotation({ 0, 90, 0 }) end)
    pcall(function() o.setLock(true) end)
  end
  -- keep the Outcast Marker (it belongs ON the Lizard Wizard) — do NOT destruct it.
  -- spawn the wizard already FACING RTT_LIZ_WIZ_ROTY (90) -- no delayed rotate (audit: spawn-final).
  makeSpecialWithTag("Tools", "Lizard Wizard",
    RTT_LIZ_WIZ[1], RTT_LIZ_WIZ[2], RTT_LIZ_WIZ[3], "RTT Faction", RTT_LIZ_WIZ_ROTY)
  -- The Outcast Marker spawns from the same "Lizard Wizard" blueprint at its own offset; nudge it onto
  -- the wizard (position only -- facing is already correct at spawn). TODO: bake this offset in the
  -- blueprint so no move is needed either.
  Wait.frames(function()
    for _, o in ipairs(getAllObjects()) do
      if (o.getName() or "") == "Outcast Marker" then
        if o.getLock and o.getLock() then o.setLock(false) end
        o.setPosition({ RTT_LIZ_OUTCAST[1], RTT_LIZ_OUTCAST[2], RTT_LIZ_OUTCAST[3] })
      end
    end
  end, 3)
  -- the discard blocker belongs to the lizards, not to a button: always, deck or no deck
  pcall(function() rttPlaceDragonGod() end)
end

-- ---- Lilypad Diaspora (frogs) --------------------------------------------
function rttFrogsSetup()
  rttShuffleFrogsIntoDeck()
  rttSpawnPond()
end

-- The Pond is MAP-relative (a fixed world spot, independent of the frog's seat), so it can't be a
-- seat-local blueprint move_to. m580 removes it from the frog blueprint and hands its object JSON
-- here as RTT_POND_JSON; we spawn it DIRECTLY at its world spot — no seat-relative default, no
-- reposition, no below-table trick.
function rttSpawnPond()
  if RTT_POND_JSON == nil then return end
  local lizard = (RTT_FAC_TAKEN or {})["The Lizard Cult"] == true
  local p = lizard and RTT_POND_SHIFT or RTT_POND_FROG
  spawnObjectJSON({
    json = RTT_POND_JSON,
    position = { p[1], p[2], p[3] },
    rotation = { 0, 90, 0 },
    -- tag it so the Lizard setup can find + shift it if the frog was picked FIRST (see rttLizardSetup)
    callback_function = function(o) o.setLock(true) o.addTag("RTT Pond") end,
  })
end

-- How many of a deck's cards are the Lilypad Diaspora's, and how many cards it holds.
function rttFrogCount(deck)
  local cards = deck.getObjects() or {}
  local frog = 0
  for _, c in ipairs(cards) do if (c.description or "") == "Frog" then frog = frog + 1 end end
  return frog, #cards
end

-- THE shared clearing-card deck. A deck that is ENTIRELY frog cards is the frogs' own and must not be
-- mistaken for it -- but a deck that merely CONTAINS frog cards is the shared deck after
-- rttShuffleFrogsIntoDeck has merged them in. The old test demanded zero frog cards, so once the frogs
-- were in play NOTHING matched: the Alliance supporters draw found no deck and silently dealt nothing
-- (maintainer: "supporters fail to draft when there are the frogs card on top").
function rttFindMainDeck()
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Deck" then
      local frog, total = rttFrogCount(o)
      if total >= 20 and frog < total then return o end
    end
  end
  return nil
end

-- The frog cards live in the SHARED deck once the Lilypad Diaspora has been picked, and the deck is
-- tagged "Deck Object", which teardown deliberately never sweeps. So they outlived the game that added
-- them and a later game without the frogs still drew them. Pull them back out on every new game; if the
-- frogs are picked again, rttShuffleFrogsIntoDeck re-adds them from that faction's own blueprint.
function rttRemoveFrogsFromDeck()
  local deck = rttFindMainDeck()
  if deck == nil then return end
  local guids = {}
  for _, c in ipairs(deck.getObjects() or {}) do
    if (c.description or "") == "Frog" and c.guid ~= nil then guids[#guids + 1] = c.guid end
  end
  if #guids == 0 then return end
  local dp = deck.getPosition()
  local function pull(i)
    if i > #guids then return end
    pcall(function()
      deck.takeObject({
        guid              = guids[i],
        position          = { dp.x, dp.y + 3, dp.z },
        smooth            = false,
        callback_function = function(o) pcall(function() o.destruct() end) end,
      })
    end)
    Wait.time(function() pull(i + 1) end, 0.1)   -- one at a time: no deck-busy / collapse race
  end
  pull(1)
end

function rttShuffleFrogsIntoDeck()
  local mainDeck, frogObjs = rttFindMainDeck(), {}
  for _, o in ipairs(getAllObjects()) do
    local nm = o.name
    if nm == "Deck" and o ~= mainDeck then
      local frog, total = rttFrogCount(o)
      if total > 0 and frog == total then frogObjs[#frogObjs + 1] = o end
    elseif (nm == "Card" or nm == "CardCustom") and (o.getDescription() or "") == "Frog" then
      frogObjs[#frogObjs + 1] = o
    end
  end
  if mainDeck == nil then return end
  for _, f in ipairs(frogObjs) do pcall(function() mainDeck.putObject(f) end) end
  Wait.time(function() if mainDeck ~= nil then pcall(function() mainDeck.shuffle() end) end end, 1.0)
end

-- ---- Keepers in Iron (badgers): relics onto the maintainer's recorded per-map spots -----------
-- Find the game MAP board. Every spawned map piece carries tag "Map Object" (makeMap), and among them
-- the board has the most snap points. Scanning ALL objects by snap-count returned bab7e1 (the score
-- grid) or a faction board instead, so badger relics / forest centres landed on the wrong board (audit).
-- The map board among the objects TAGGED as map pieces: the one with the most snap points. Cheap --
-- it looks at a handful of objects -- and safe to call repeatedly, which rttWhenMapReady does.
function rttMapBoardTagged()
  local best, bestN = nil, 0
  for _, o in ipairs(getObjectsWithTag("Map Object")) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp > bestN then best, bestN = o, #sp end
  end
  return best
end

function rttFindMapObject()
  local best = rttMapBoardTagged()
  if best ~= nil then return best end
  -- FALLBACK, for a table this board did not lay out: scan everything. Only reachable when no tagged
  -- map piece has snap points, which also means it runs during a map TEARDOWN, when removeMapItems has
  -- just destroyed them all. getGUID was called bare here, and a handle that getAllObjects returned a
  -- moment before can be gone by the time it is asked -- "Object reference not set to an instance of an
  -- object", which the maintainer hit once just after a button press on 2026-09-06. Every call to a
  -- possibly-dead object is protected now.
  local bestN = 0
  for _, o in ipairs(getAllObjects()) do
    local guid = nil
    pcall(function() guid = o.getGUID() end)
    if guid ~= nil and guid ~= "bab7e1" then   -- exclude the coordinator/score board
      local ok, sp = pcall(function() return o.getSnapPoints() end)
      if ok and sp and #sp > bestN then best, bestN = o, #sp end
    end
  end
  return best
end

function rttForestWorldCenters(mapId)   -- fallback for maps with no recorded relic spots
  local cents = RTT_FOREST_UV[mapId]
  if cents == nil then return {} end
  local m = rttFindMapObject()
  if m == nil then return {} end
  local b = m.getBounds()
  local a = math.rad(m.getRotation().y)
  local sx, sz = b.size.x, b.size.z
  local out = {}
  for _, uv in ipairs(cents) do
    local lx, lz = uv[1] * sx, uv[2] * sz
    out[#out + 1] = {
      b.center.x + lx * math.cos(a) - lz * math.sin(a),
      b.center.z + lx * math.sin(a) + lz * math.cos(a),
    }
  end
  return out
end

-- the map buttons + makeMap live on the MAIN board (bab7e1); clones (the solo/standard faction
-- selectors) have their own Lua globals, so a clone's RTT_CURRENT_MAP is nil. This getter lets
-- any clone read the main board's current map by GUID.
function rttGetCurrentMap() return RTT_CURRENT_MAP end

function rttGetMarshExcluded() return RTT_MARSH_EXCLUDED end
function rttGet5pMarsh() return RTT_5P_MARSH end

function rttBadgerRelics()
  -- RTT_PICKED.map is only set by the ranked-draft coordinator; on the solo/standard faction
  -- board it is nil. Fall back to RTT_CURRENT_MAP (this board's last makeMap); and if THIS
  -- object is a selector clone (its own RTT_CURRENT_MAP is nil), read the main board bab7e1.
  local mapId = RTT_CURRENT_MAP or (RTT_PICKED or {}).map
  if mapId == nil then
    local mb = getObjectFromGUID("bab7e1")
    if mb ~= nil then
      local ok, mid = pcall(function() return mb.call("rttGetCurrentMap") end)
      if ok and type(mid) == "string" then mapId = mid end
    end
  end
  if mapId == nil then return end
  local bag = nil
  for _, o in ipairs(getAllObjects()) do
    if o.name == "Bag" and (o.getName() or "") == "Relics" then bag = o break end
  end
  if bag == nil then return end
  pcall(function() bag.shuffle() end)              -- placement is ALWAYS random (per the maintainer)
  local targets = {}
  local recorded = RTT_RELIC_POS[mapId]
  if recorded ~= nil then                          -- the maintainer's exact per-map spots (map-local)
    local m = rttFindMapObject()
    if m == nil then return end
    for _, lc in ipairs(recorded) do
      local w = m.positionToWorld({ lc[1], 0.05, lc[2] })
      targets[#targets + 1] = { w.x, w.z }
    end
  else
    targets = rttForestWorldCenters(mapId)          -- fallback: forest centroids
  end
  if #targets == 0 then return end
  for _, c in ipairs(targets) do
    pcall(function()
      bag.takeObject({ position = { c[1], 12.0, c[2] }, rotation = { 0, 180, 0 }, smooth = false,
        -- tag "RTT Faction" so the relics go out WITH the badger faction on re-draft (not orphaned on the map)
        callback_function = function(o) pcall(function() o.addTag("RTT Faction") end) end })
    end)
  end
end

-- ---- Twilight Council (bats) ---------------------------------------------
RTT_BATS_ASM = { -0.032, -0.253 }
RTT_BATS_WAR = {
  { 0.657, -1.241 }, { 0.657, -1.167 }, { 0.797, -1.167 }, { 0.797, -1.241 },  -- pack of 4
  { 0.375, -1.167 }, { 0.375, -1.241 },                                        -- pack of 2
}


-- ---- Mountain: read the centre-clearing suit, then stand a landmark there ---------------
-- suit textures on the "Clearing Marker" mesh (verified by eye): yellow=rabbit, orange=mouse,
-- red=fox. Matched by the steam UGC handle in the marker's diffuse URL.
RTT_SUIT_TEX = {
  ["1725416554252055237"] = "rabbit",
  ["1725416554252058449"] = "mouse",
  ["1725416554252050523"] = "fox",
}
RTT_SUIT_LM = { rabbit = "Rabbit-Town", fox = "Foxburrow", mouse = "Mousehold" }
RTT_MTN_LM = { -0.116, 11.660, 0.187 }
RTT_MTN_CARD = { -29.303, 11.575, -19.899 }
RTT_MTN_CARD_SCALE = 2.299

RTT_MTN_LM_PIECES = RTT_MTN_LM_PIECES or {}

-- spawn a landmark's model (standing) + its rules card (rules side up) DIRECTLY at their
-- final transforms, so they appear in place and just settle onto the board like the other
-- map pieces — no visible slide/rotate. spawnObjectJSON's position/rotation override the
-- data's baked (flat) transform. EVERYTHING is on this board (self), so it's in scope.
-- mrotY  = standing-model world rotY (Mountain=165; Marsh towns pass the clearing's suit rotY)
-- crotZ  = rules-card rotZ; 180 = RULES/BackURL face up (Mountain=180, Marsh towns=180)
-- cscale = rules-card XZ scale, or nil to leave the card at its blueprint scale (Marsh towns)
-- both the model and the card spawn LOCKED (the maintainer wants landmarks + their cards fixed).
function rttSpawnLandmarkAt(name, mx, my, mz, cx, cy, cz, mrotY, crotZ, cscale)
  mrotY = mrotY or 165
  crotZ = crotZ or 0
  local pieces = {}
  local lm = EVERYTHING['Landmarks'][name]
  if lm == nil or lm['data'] == nil then return pieces end
  for _, v in ipairs(lm['data']) do
    local ob
    if string.find(v.json, "CardID", 1, true) ~= nil then
      ob = spawnObjectJSON({
        json = v.json,
        position = { cx, cy, cz },
        rotation = { 0, 180, crotZ },
        callback_function = function(o)
          o.setLock(true)
          o.addTag("Map Object")
          if cscale ~= nil then pcall(function() o.setScale({ cscale, 1.0, cscale }) end) end
        end
      })
    else
      ob = spawnObjectJSON({
        json = v.json,
        position = { mx, my, mz },
        rotation = { 0, mrotY, 0 },                 -- standing signpost, in place
        callback_function = function(o)
          o.setLock(true)
          o.addTag("Map Object")
        end
      })
    end
    pieces[#pieces + 1] = ob
  end
  return pieces                                     -- caller (rttMountainLandmark) tracks these to clear on re-click
end

RTT_CROW_PLOTS = {
[==[{"GUID":"21305a","Name":"Custom_Tile","Transform":{"posX":-0.3543687,"posY":11.5615435,"posZ":-35.416317,"rotX":-1.21530479e-06,"rotY":180.000351,"rotZ":1.37646862e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518131475/4ADB942FAFC5E1B1B8944104EE78BCC49D314E74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"e59fb6","Name":"Custom_Tile","Transform":{"posX":-0.603453934,"posY":11.5615435,"posZ":-36.994133,"rotX":4.16742978e-07,"rotY":180.015182,"rotZ":-9.556643e-07,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518131475/4ADB942FAFC5E1B1B8944104EE78BCC49D314E74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"0546e8","Name":"Custom_Tile","Transform":{"posX":-0.3954289,"posY":11.5615435,"posZ":-33.8944244,"rotX":2.263754e-08,"rotY":180.000015,"rotZ":-1.62602646e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518131475/4ADB942FAFC5E1B1B8944104EE78BCC49D314E74/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"ca3fff","Name":"Custom_Tile","Transform":{"posX":-2.01368332,"posY":11.5615435,"posZ":-35.4446754,"rotX":-2.17247452e-06,"rotY":179.998016,"rotZ":-3.34748984e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518126214/F1899491A241A1C0D2B675B376D2CE214EB9F09E/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"f1b260","Name":"Custom_Tile","Transform":{"posX":-2.07250881,"posY":11.5615435,"posZ":-37.2397423,"rotX":-2.30690011e-06,"rotY":179.999435,"rotZ":-3.11298777e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518126214/F1899491A241A1C0D2B675B376D2CE214EB9F09E/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"36116f","Name":"Custom_Tile","Transform":{"posX":-1.8903209,"posY":11.5615435,"posZ":-33.8944244,"rotX":-1.601876e-06,"rotY":179.992828,"rotZ":-1.19916251e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518126214/F1899491A241A1C0D2B675B376D2CE214EB9F09E/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"39035d","Name":"Custom_Tile","Transform":{"posX":1.14516747,"posY":11.5615444,"posZ":-35.4543076,"rotX":1.19232618e-06,"rotY":179.972031,"rotZ":-5.448114e-07,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518129410/B4639216F003288DDA4A03229C73008EEABCABCE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"134809","Name":"Custom_Tile","Transform":{"posX":1.16691959,"posY":11.5615435,"posZ":-37.17794,"rotX":-1.41008577e-05,"rotY":180.031372,"rotZ":3.91094272e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518129410/B4639216F003288DDA4A03229C73008EEABCABCE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"edd824","Name":"Custom_Tile","Transform":{"posX":1.09946644,"posY":11.5615435,"posZ":-33.8944244,"rotX":2.987837e-06,"rotY":180.002747,"rotZ":-1.87574437e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518129410/B4639216F003288DDA4A03229C73008EEABCABCE/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"6c25d9","Name":"Custom_Tile","Transform":{"posX":2.68634152,"posY":11.5615435,"posZ":-37.33003,"rotX":-5.253496e-07,"rotY":179.997269,"rotZ":-2.14995e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518134114/5AC4FA97221C50C053365BA874BA837016D5C4DA/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"ef396f","Name":"Custom_Tile","Transform":{"posX":2.6341083,"posY":11.5615435,"posZ":-35.4670753,"rotX":2.09103382e-06,"rotY":180.003647,"rotZ":-3.06159359e-06,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518134114/5AC4FA97221C50C053365BA874BA837016D5C4DA/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==],
[==[{"GUID":"d87fa8","Name":"Custom_Tile","Transform":{"posX":2.59436,"posY":11.5615435,"posZ":-33.8944244,"rotX":1.47051026e-07,"rotY":180.000031,"rotZ":7.15139436e-07,"scaleX":0.703911364,"scaleY":1.0,"scaleZ":0.703911364},"Nickname":"Plot","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.539603055,"g":0.391118348,"b":0.632404268},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"CustomImage":{"ImageURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518134114/5AC4FA97221C50C053365BA874BA837016D5C4DA/","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1807607729518125572/1C3B0C57CFFD05BB8AF1B9412849D054E6D7131E/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":2,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
}

-- Hidden-box placement, read from the maintainer's hand-placed save (the SAME board-local spot + size for
-- every seat -- straightened and uniform, per his instruction). Past the crafted board, near depth-centre.
RTT_CROW_HZ_LX = 3.074    -- board-local X magnitude on the RIGHT side (seats 2 & 4) -- clears the crafted.
RTT_CROW_HZ_LX_LEFT = 2.26 -- LEFT side (seats 1 & 3): closer to the faction board by the crafted board's
                          -- width (7.2 world / 8.82 = 0.82 board-local) since no crafted sits on that side.
RTT_CROW_HZ_LZ = -0.565   -- board-local Z: near the crow board's depth centre
-- plot layout INSIDE the hidden zone: world-unit spacing, and how far above the zone's own y they
-- sit so they rest visibly in it rather than at its floor.
RTT_CROW_PLOT_GAP = 1.60
RTT_CROW_PLOT_Y   = -2.20
RTT_CROW_HZ_SX = 13.29    -- uniform box dimensions for every seat (his hand-placed size)
RTT_CROW_HZ_SY = 5.10
RTT_CROW_HZ_SZ = 9.50

RTT_CROW_HZ_JSON = [==[{"GUID":"8719cd","Name":"FogOfWarTrigger","Transform":{"posX":-27.8318653,"posY":14.1115437,"posZ":-46.7588654,"rotX":0.0,"rotY":359.8908,"rotZ":0.0,"scaleX":14.3045025,"scaleY":5.1,"scaleZ":12.5832348},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":1.0,"g":1.0,"b":1.0,"a":0.25},"LayoutGroupSortIndex":0,"Value":0,"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"FogColor":"White","FogHidePointers":false,"FogReverseHiding":false,"FogSeethrough":true,"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]

-- ===== RTT 5-player Marsh draft =====
RTT_5P_MARSH = RTT_5P_MARSH or false

function rttFivePStart(player, value, id)
  RTT_DRAFT_N = 6               -- 5 players draft 6 faction cards (players + 1 leftover)
  rttSetup(player, value, id)   -- resets RTT_5P_MARSH=false at its start; we set it after
  RTT_5P_MARSH = true
end

-- place the 5-player Marsh MAP only (no draft/selectors/seating). Sets the flag that the makeMap
-- Marsh branch + landmark hook + number-token hook all read, then reuses the base rttPlaceMap path
-- exactly like a plain map button. RTT_5P_MARSH is left true (the async landmark/number hooks
-- early-return on false); rttSetup resets it on the next ranked/5p launch.
function rttPlaceMarsh5P(player, value, id)
  RTT_5P_MARSH = true
  rttPlaceMap("Marsh Map")
end

-- 5-player Marsh plan: no flooding; all 15 clearings active; 3 random -> town landmarks,
-- the other 12 -> the 12 suit markers. Reuses m440's RTT_MARSH_SUIT9 / RTT_MARSH data.
-- ---- Marsh: town landmarks must never be ADJACENT ------------------------------------------
-- The rules forbid two town landmarks in adjacent clearings; rttMarshPlan5P used to shuffle the 15
-- clearing positions and take the first three, with no constraint at all.
--
-- The mapping was the hard part and it turned out to already be in the file. RTT identifies clearings
-- by world position, not number, so the adjacency table could not be applied -- but
-- RTT_CLEARING_CENTRES["Marsh Map"] holds all 15 TRUE clearing centres in world coordinates (it is what
-- rttMarquiseCats drops a cat into), and its order IS the printed clearing number: dividing each centre
-- by root_engine's tile-local uv gives scale x 50.65 +/- 0.15 and z 46.37 +/- 0.52, whose ratio 1.0922
-- matches the board art's aspect 1.0910. So the mapping is the identity, no fitting required.
-- (Fitting the SUIT-MARKER positions instead never worked, and could not: those sit offset inside their
-- clearing, and the closest two are 5.26 apart where the closest two real centres are 10.48.)
--
-- RTT_MARSH_CLEARING is then just each planner position matched to its nearest true centre, in the
-- exact order rttMarshPlan5P builds them: the 9 fixed suits, then A.up, A.down, B.up, B.down, C.up,
-- C.down. Bijective, no collisions, every match a clear winner over the runner-up.
-- Which clearing-marker mesh is which suit, read off the marker textures themselves (fox face on red,
-- rabbit ears on yellow, mouse on orange). Used to place a marker on a clearing of its own suit.
RTT_SUIT_TEX = {
  fox    = "BF0F13D634B3B535D470396151B8A2F456507526",
  rabbit = "195F0F3DFD439596DE7A5D941E93DE07BF820D11",
  mouse  = "AF3D10F25ABE87305AF3F9A77B4C04B7761FBDDA",
}
RTT_SUIT_TOWN = { fox = "Foxburrow", rabbit = "Rabbit-Town", mouse = "Mousehold" }

RTT_MARSH_CLEARING = { 3, 9, 4, 7, 14, 15, 2, 1, 5, 11, 10, 12, 13, 6, 8 }

-- clearing adjacency, from root_engine/maps_data/marsh.json
RTT_MARSH_ADJ = {
  [1] = { 5, 10, 11 },
  [2] = { 6, 7, 12 },
  [3] = { 7, 8, 13 },
  [4] = { 9, 10 },
  [5] = { 1, 6, 15 },
  [6] = { 2, 5 },
  [7] = { 2, 3 },
  [8] = { 3, 9 },
  [9] = { 4, 8, 14 },
  [10] = { 1, 4, 14 },
  [11] = { 1, 14, 15 },
  [12] = { 2, 13, 15 },
  [13] = { 3, 12, 14 },
  [14] = { 9, 10, 11, 13 },
  [15] = { 5, 11, 12 },
}

function rttMarshAdjacent(a, b)
  if a == nil or b == nil then return false end
  for _, n in ipairs(RTT_MARSH_ADJ[a] or {}) do if n == b then return true end end
  return false
end

function rttMarshPlan5P(objects)
  -- NO os.time re-seed (see rtt-rng-bug): seeded once at load, advance per call so fast re-clicks
  -- re-randomise instantly.

  local floodIx, ruinIx, suitIx = {}, {}, {}
  for idx, v in ipairs(objects) do
    local j = v.json
    if string.find(j, "53E4E9F1", 1, true) or string.find(j, "C5C35E37", 1, true)
       or string.find(j, "B37C9A48", 1, true) then floodIx[#floodIx + 1] = idx
    elseif string.find(j, "RUIN", 1, true) then ruinIx[#ruinIx + 1] = idx
    elseif string.find(j, "Clearing Marker", 1, true) then suitIx[#suitIx + 1] = idx
    end
  end

  -- SUIT-DRIVEN LAYOUT (the maintainer's rule, 2026-09-04). The Marsh has 15 clearings, FIVE of each
  -- suit, and the box has 12 clearing markers, FOUR of each -- because exactly one clearing per suit
  -- becomes that suit's TOWN. So the suits are drafted first and the towns are drawn from them:
  --   1. shuffle the 15 clearings and deal them 5 fox / 5 rabbit / 5 mouse;
  --   2. for each suit in a random order, take one of ITS five as that suit's town
  --      (Foxburrow on a fox clearing, Rabbit-Town on a rabbit one, Mousehold on a mouse one);
  --   3. the only constraint: a town may not be adjacent to a town already chosen;
  --   4. the remaining 12 clearings keep their drafted suit and take a marker OF THAT SUIT -- which
  --      comes out to exactly the 4 fox / 4 rabbit / 4 mouse markers the map actually has.
  -- The previous version picked three arbitrary clearings as towns and then dropped the 12 markers on
  -- whatever was left, so a town could sit on a clearing of the wrong suit.
  local clearings = {}
  local function add(q)
    local n = #clearings + 1
    clearings[n] = { q[1], q[2], q[3], q[4], cl = RTT_MARSH_CLEARING[n] }
  end
  for _, p in ipairs(RTT_MARSH_SUIT9) do add(p) end
  for _, m in ipairs(RTT_MARSH) do add(m.up.suit) add(m.down.suit) end

  -- group the 12 markers by suit, read from their mesh texture
  local bySuit = { fox = {}, rabbit = {}, mouse = {} }
  for _, idx in ipairs(suitIx) do
    local j = objects[idx].json
    if     string.find(j, RTT_SUIT_TEX.fox,    1, true) then table.insert(bySuit.fox, idx)
    elseif string.find(j, RTT_SUIT_TEX.rabbit, 1, true) then table.insert(bySuit.rabbit, idx)
    elseif string.find(j, RTT_SUIT_TEX.mouse,  1, true) then table.insert(bySuit.mouse, idx) end
  end

  local suitOf, towns, ok = {}, {}, false
  for _ = 1, 60 do
    rttShuffleList(clearings)
    suitOf = {}
    for i = 1, 15 do                                  -- 1..5 fox, 6..10 rabbit, 11..15 mouse
      suitOf[i] = (i <= 5) and "fox" or ((i <= 10) and "rabbit" or "mouse")
    end
    -- EXACTLY UNIFORM over the valid town triples. Picking one suit at a time and filtering as you go
    -- is biased -- an early pick changes what is still legal for the later suits. There are only
    -- 5 x 5 x 5 = 125 candidate triples, so enumerate the legal ones and draw one at random; that is
    -- uniform by construction, and the suit draft above is already a fair shuffle.
    local fox, rab, mou = {}, {}, {}
    for i = 1, 15 do
      if     suitOf[i] == "fox"    then fox[#fox + 1] = i
      elseif suitOf[i] == "rabbit" then rab[#rab + 1] = i
      else                              mou[#mou + 1] = i end
    end
    local legal = {}
    for _, f in ipairs(fox) do
      for _, r in ipairs(rab) do
        if not rttMarshAdjacent(clearings[f].cl, clearings[r].cl) then
          for _, m in ipairs(mou) do
            if not rttMarshAdjacent(clearings[f].cl, clearings[m].cl)
               and not rttMarshAdjacent(clearings[r].cl, clearings[m].cl) then
              legal[#legal + 1] = { fox = f, rabbit = r, mouse = m }
            end
          end
        end
      end
    end
    if #legal > 0 then
      towns = legal[math.random(#legal)]
      ok = true
      break
    end
  end

  RTT_MARSH_LANDMARKS = {}
  RTT_MARSH_FLOODED = {}    -- the 3 "no-number" clearings (m460 drops their number tokens)
  RTT_MARSH_EXCLUDED = {}   -- same 3 clearing centres, for m460's rank-walk skip logic
  local isTown = {}
  if ok then
    local n = 0
    for suit, i in pairs(towns) do
      n = n + 1
      isTown[i] = true
      local c = clearings[i]
      RTT_MARSH_LANDMARKS[n] = { x = c[1], z = c[3], name = RTT_SUIT_TOWN[suit], rotY = c[4] }
      RTT_MARSH_FLOODED[n]  = { c[1], c[3] }
      RTT_MARSH_EXCLUDED[n] = { c[1], c[3] }
    end
  end

  local ov = {}
  -- each of the 12 markers onto a clearing OF ITS OWN SUIT (the town clearing of that suit is skipped,
  -- which is exactly why 5 clearings per suit need only 4 markers)
  local nextOf = { fox = 1, rabbit = 1, mouse = 1 }
  for i = 1, 15 do
    if not isTown[i] then
      local suit = suitOf[i]
      local list = bySuit[suit]
      local idx = list and list[nextOf[suit]]
      if idx ~= nil then
        nextOf[suit] = nextOf[suit] + 1
        local c = clearings[i]
        ov[idx] = { world = { c[1], c[2], c[3] }, rot = { 0, c[4], 0 } }
      end
    end
  end
  -- no flooding: send the 3 flood tiles below the table
  for _, idx in ipairs(floodIx) do
    ov[idx] = { world = { 0, -50, 0 }, rot = nil }
  end
  -- RUINS: the four CENTRAL clearings only, never the rim. Maintainer, 2026-09-06: "for 5P Marsh the
  -- ruins need to spawn only in the center clearing, never in the ones at the edge" -- clearings
  -- 6, 7, 9 and 10.
  --
  -- This used to offer SIX slots -- 2 fixed plus all four pair spots -- and deal the four ruins across
  -- them, so two ruins a game landed on the rim. The two rim slots are marker C's pair: C.up is
  -- clearing 3 at the top edge and C.down is clearing 14 at the bottom. Marker B's pair is clearings
  -- 7 and 10, both inland, and the two fixed spots are clearings 6 and 9. Dropping C leaves exactly
  -- four slots for four ruins, so placement is now fixed and only WHICH ruin (and so which item) goes
  -- where is still random.
  --
  -- NOTE the numbering: clearing numbers here are RTT_MARSH_RANK's, which is the printed 1-15 order.
  -- RTT_CLEARING_CENTRES["Marsh Map"] is a DIFFERENT order and reading clearing numbers off it gives
  -- the wrong answer -- which is how I first mis-read this.
  -- The flooding Marsh (rttMarshPlan) is untouched: there only two pair spots are ever dry.
  local ruinSlots = {}
  for _, p in ipairs(RTT_MARSH_RUIN_FIXED) do ruinSlots[#ruinSlots + 1] = { p[1], p[2], p[3] } end
  for _, m in ipairs(RTT_MARSH) do
    if m.key == "B" then                       -- B only: C's pair is the two edge clearings
      if m.up.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.up.ruin end
      if m.down.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.down.ruin end
    end
  end
  rttShuffleList(ruinSlots)
  for i, idx in ipairs(ruinIx) do
    local p = ruinSlots[i]
    if p ~= nil then ov[idx] = { world = { p[1], p[2], p[3] }, rot = nil } end
  end
  return ov
end

-- each town's rules card has its OWN fixed spot (the maintainer placed + locked them in the save);
-- keyed by town name so a card always lands in the same place regardless of which clearing
-- the town landmark spawns on. All three: y 11.575, z -19.135, rotZ 180, unscaled.
RTT_MARSH_CARD_POS = {
  ["Rabbit-Town"] = { -40.156, 11.575, -19.135 },
  ["Foxburrow"]   = { -35.098, 11.575, -19.135 },
  ["Mousehold"]   = { -45.214, 11.575, -19.135 },
}

-- spawn each town standing on its clearing (model rotY = the clearing's suit rotY) + its
-- rules card at that town's fixed locked spot, all DIRECTLY at their final transforms
-- (rttSpawnLandmarkAt, from m490) so they appear in place and settle — no slide/rotate.
function rttMarshLandmarks()
  if not RTT_5P_MARSH then return end
  for _, lm in ipairs(RTT_MARSH_LANDMARKS or {}) do
    local slot = RTT_MARSH_CARD_POS[lm.name] or { -40.156, 11.575, -19.135 }
    rttSpawnLandmarkAt(lm.name, lm.x, 11.66, lm.z, slot[1], slot[2], slot[3],
                       lm.rotY or 165, 180, nil)
  end
end

-- Mountain: the Tower is never used (a landmark replaces it), so spawn it BELOW the table
-- from frame one instead of spawning it on the board and destroying it (no visible flash).
-- rttMountainLandmark still destroys the (hidden) tower via its "Tower" tag afterwards.
-- ---- Mountain: deal the suits, then the centre's suit picks the town ----------------------
-- The Mountain PRINTS NO SUITS. Its clearings are suited by dealing the 12 suit markers at setup
-- (root_engine maps_data/mountain.json: "the Mountain deals its 12 suit markers at setup"), and the
-- maintainer's group plays the centre as a suited TOWN landmark rather than the Pass/tower
-- (root_engine HOUSE_RULES M1_mountain_centre: "Which town is set at setup by clearing 10's DEALT
-- suit ... fox -> Foxburrow, rabbit -> Rabbittown, mouse -> Mousehold").
--
-- What this used to do was pick one of four landmarks uniformly at random and stand it in the
-- centre. The eleven markers WERE already being shuffled -- shuffleMaps runs for every map but Marsh
-- -- but shuffling only permutes their positions, and the eleven are a fixed multiset of
-- 4 fox / 4 rabbit / 3 mouse. So the suit missing from the board was ALWAYS mouse, the centre could
-- only ever legally be Mousehold, and the other three draws gave 5/4/3, 4/5/3, or 4/4/3 with an
-- unsuited centre. Legal one game in four.
--
-- Dealing here does something shuffling cannot: it swaps WHICH suit's marker stands in each slot, so
-- the eleven are no longer locked to 4/4/3 and the centre's suit genuinely varies.
--
-- Now: twelve suits (4/4/4) are shuffled across the eleven marker slots and the centre. Each slot
-- spawns the marker of ITS dealt suit at its own position and facing, and the centre's dealt suit
-- chooses the town. The board is 4/4/4 every time, and every clearing's suit is random.
RTT_MTN_MARKER_MESH = "5D8406B85EC590BEAB7FC5AF9DA99F32175FDFF4"
RTT_MTN_SUIT_DIFFUSE = {
  fox    = "BF0F13D634B3B535D470396151B8A2F456507526",
  rabbit = "195F0F3DFD439596DE7A5D941E93DE07BF820D11",
  mouse  = "AF3D10F25ABE87305AF3F9A77B4C04B7761FBDDA",
}
RTT_MTN_TOWN = { fox = "Foxburrow", rabbit = "Rabbit-Town", mouse = "Mousehold" }
RTT_MTN_CENTRE_SUIT = nil
-- Maintainer 2026-09-05: one board in four takes the LOST CITY instead of the matching town.
-- This is a house call, not documented HOOT: root_engine HOOT_RULES records the Lost City as the
-- WINTER TOURNAMENT's Mountain substitution, where HOOT "swaps in the matching TOWN". Mixing them
-- is his to decide; it is recorded here so nobody later reads it as the HOOT rule.
--
-- It does NOT leave the centre unsuited. The Lost City clearing counts as ALL THREE suits (rules kb:
-- "all three for the Lost City", Guerric Samples, OFFICIAL), so the eleven markers still carry their
-- dealt suits and the centre is wild rather than the suit it drew.
RTT_MTN_LOST_CITY_CHANCE = 0.25
RTT_MTN_CENTRE_LOST = false

function rttMountainPlan(objects)
  local ov, slots, jsonForSuit = {}, {}, {}
  for idx, v in ipairs(objects) do
    -- the Tower is not part of this group's setup at all, so it is never spawned. It used to be
    -- parked 60 units under the table, which left a real object on the table for anything that
    -- scans by name or tag to trip over.
    if string.find(v.json, "\"Tower\"", 1, true) ~= nil then
      ov[idx] = { skip = true }
    elseif string.find(v.json, RTT_MTN_MARKER_MESH, 1, true) ~= nil then
      local rotY = tonumber(v.json:match('"rotY":%s*(-?[%d.]+)')) or 180
      slots[#slots + 1] = { idx = idx, mt = v.move_to, rotY = rotY }
      for suit, dif in pairs(RTT_MTN_SUIT_DIFFUSE) do
        if jsonForSuit[suit] == nil and string.find(v.json, dif, 1, true) ~= nil then
          jsonForSuit[suit] = v.json
        end
      end
    end
  end
  if #slots == 0 then return ov end

  -- one marker per clearing: the slots plus the centre, which takes a town instead of a marker
  local bag = {}
  for _, suit in ipairs({ "fox", "rabbit", "mouse" }) do
    for _ = 1, (#slots + 1) / 3 do bag[#bag + 1] = suit end
  end
  for i = #bag, 2, -1 do                                  -- Fisher-Yates
    local j = math.random(1, i)
    bag[i], bag[j] = bag[j], bag[i]
  end

  for i, sl in ipairs(slots) do
    local suit = bag[i]
    local j = jsonForSuit[suit]
    if j ~= nil then
      -- position and facing stay the SLOT's own; only which suit stands there changes. makeMap's
      -- own move_to arithmetic, inlined, because the override path skips it.
      ov[sl.idx] = {
        json  = j,
        world = { sl.mt[1], sl.mt[2] + 11.46, sl.mt[3] },
        rot   = { 0, sl.rotY, 0 },
      }
    end
  end
  RTT_MTN_CENTRE_SUIT = bag[#slots + 1]
  -- rolled once per deal, with the suits, so re-running the landmark spawn cannot re-roll it
  RTT_MTN_CENTRE_LOST = (math.random() < RTT_MTN_LOST_CITY_CHANCE)
  return ov
end

function rttMountainLandmark()
  -- clear the PREVIOUS landmark first, so a fast re-click replaces it (no stacking, no stale piece)
  for _, o in ipairs(RTT_MTN_LM_PIECES or {}) do
    if o ~= nil then pcall(function() o.destruct() end) end
  end
  RTT_MTN_LM_PIECES = {}
  -- the town is decided by the centre clearing's DEALT suit, not drawn separately -- except for the
  -- one board in four that takes the Lost City instead, which makes the centre all three suits
  local name = RTT_MTN_TOWN[RTT_MTN_CENTRE_SUIT or ""]
  if RTT_MTN_CENTRE_LOST then name = "Lost City" end
  if name == nil then return end
  RTT_MTN_LM_PIECES = rttSpawnLandmarkAt(name, RTT_MTN_LM[1], RTT_MTN_LM[2], RTT_MTN_LM[3],
                     RTT_MTN_CARD[1], RTT_MTN_CARD[2], RTT_MTN_CARD[3],
                     165, 180, RTT_MTN_CARD_SCALE)  -- crotZ 180 = RULES face up (BackURL)
end

RTT_POND_JSON = [==[{"GUID": "347917","Name": "Custom_Tile","Transform": {"posX": -20.61854,"posY": 35.8698158,"posZ": -58.718235,"rotX": 0.016451491,"rotY": 179.94725,"rotZ": 0.08010805,"scaleX": 4.238119,"scaleY": 1.0,"scaleZ": 4.238119},"Nickname": "The Pond","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.6901961,"g": 0.5960784,"b": 0.0156862754},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": false,"Hands": false,"CustomImage": {"ImageURL": "https://steamusercontent-a.akamaihd.net/ugc/12393369561771611633/E59B2DE66EC1B0F68F19F6E7C071F8B8D38718B8/","ImageSecondaryURL": "https://steamusercontent-a.akamaihd.net/ugc/12393369561771611633/E59B2DE66EC1B0F68F19F6E7C071F8B8D38718B8/","ImageScalar": 1.0,"WidthScale": 0.0,"CustomTile": {"Type": 0,"Thickness": 0.2,"Stackable": false,"Stretch": true}},"LuaScript": "","LuaScriptState": "","XmlUI": "","AttachedSnapPoints": [{"Position": {"x": -0.000120528261,"y": 0.200000748,"z": -0.08064375},"Rotation": {"x": 3.824257E-06,"y": 0.00134896243,"z": 180.0}}]
  }]==]
-- Run fn once the MAP BOARD is actually on the table, instead of guessing how long that takes.
--
-- The 5-player Marsh landmarks used to go down on a flat Wait.time(..., 1.4) while every other map
-- hook was measured in frames, so they visibly arrived a second and a half after everything else --
-- maintainer, 2026-09-06: "do you know why landmarks and also the boxscore takes a bit of time to
-- load?" A fixed delay is wrong in both directions: too slow on a normal load, and still too short on
-- a slow one, where the pieces would land before the board existed.
--
-- Polled every 3 frames rather than every frame: rttFindMapObject walks every object asking for its
-- snap points, which is not free. In practice the board is already there on the first look, because
-- the map's own pieces are requested earlier in the same makeMap call. Gives up after ~3s and runs
-- anyway, so a map that never appears cannot silently swallow the landmarks.
function rttWhenMapReady(fn, tries)
  tries = tries or 60
  local n = 0
  local function tick()
    n = n + 1
    local ready = false
    -- rttMapBoardTagged, NOT rttFindMapObject: the latter falls back to walking every object on the
    -- table, and this polls during a teardown when nothing is tagged yet, so it would do that on every
    -- tick over a table full of objects being destroyed. We only ever want THIS board's own map here.
    pcall(function() ready = (rttMapBoardTagged() ~= nil) end)
    if ready or n >= tries then pcall(fn) return end
    Wait.frames(tick, 3)
  end
  Wait.frames(tick, 1)
end

function makeMap(player,value,id,keepBoard)
  -- A HUMAN CLICKING A MAP BUTTON MEANS "GIVE ME THIS MAP, PLAINLY", so it leaves 5-player mode.
  --
  -- RTT_5P_MARSH is the 5-player Marsh variant's mode flag. It was SET by its own two entry points
  -- and cleared in exactly ONE place -- inside rttSetup, the ranked-draft path -- so after using
  -- 5-Players Marsh, clicking the plain Marsh button still built the FIVE-player board: rttMarshPlan5P
  -- instead of rttMarshPlan, which means no flooded clearings, and the town landmarks placed and left
  -- behind. Maintainer, 2026-09-06. Every other map was affected too, just less visibly: the flag
  -- stayed true across Summer, Lake, Winter and so on, so the next Marsh click was still 5-player.
  --
  -- The discriminator is the PLAYER argument. A real button click passes a Player table; the internal
  -- path (rttPlaceMap -> makeMap("", "", id)) passes "", which is how the 5-player flow sets the flag
  -- and then places its own map without clearing it a line later.
  -- A HUMAN CLICK IS SWALLOWED WHILE A SETUP IS RUNNING. RTT_BUSY was consulted only in rttArmOrGo,
  -- so the map buttons ignored it: clicking Marsh during the 5-player draft's 6-10s chain landed that
  -- game on the FOUR-player board, because rttFivePStart sets RTT_5P_MARSH at t=0 but its map is not
  -- placed until rttBeginPick seconds later. The internal path passes no player and is never blocked.
  -- A REAL CLICK IS ONE THAT CARRIES A COLOUR. This used to read type(player) == "table" -- and in
  -- Tabletop Simulator a Player is USERDATA, not a table, so the test was false for every human click
  -- ever made and RTT_5P_MARSH was never cleared. The 5-player flag therefore survived, the Marsh
  -- button rebuilt the FIVE-player board every time, and the maintainer reported the same bug three
  -- times while the test suite stayed green: the stub's Player is a plain Lua table, so type() said
  -- "table" and the guard ran in the harness and only in the harness.
  -- The internal path (rttPlaceMap -> makeMap("", "", id)) passes "", which has no .color, so it
  -- still places the 5-player map without clearing the flag a line later.
  local byHuman = false
  pcall(function() byHuman = (player ~= nil and player ~= "" and player.color ~= nil) end)
  if byHuman then
    if RTT_BUSY then return end
    RTT_5P_MARSH = false
  end
  -- EVERY MAP BUILD GETS A GENERATION. Deferred map hooks below fire later than the click and used a
  -- bare Wait, so a second map click inside that window left two in flight and both ran: two 5-Players
  -- Marsh clicks 1.4s apart gave TWO of every town landmark. RTT_RUN_ID cannot cover this -- it bumps
  -- on a new GAME, and a map click is not one -- so the map needs its own counter.
  RTT_MAP_GEN = (RTT_MAP_GEN or 0) + 1
  local gen = RTT_MAP_GEN
  if id == "Marsh Map" and RTT_5P_MARSH then
    rttWhenMapReady(function() if RTT_MAP_GEN == gen then rttMarshLandmarks() end end)
  end
  RTT_CURRENT_MAP = id
  if id == "Mountain Map" then Wait.frames(function() rttMountainLandmark() end, 2) end
  if id == "Summer Map" then Wait.frames(function() rttSpawnPriority("Summer Map", RTT_PRIO_SUMMERMAP) end, 2) end
  if id == "Lake Map" then Wait.frames(function() rttSpawnPriority("Lake Map", RTT_PRIO_LAKEMAP) end, 2) end
  if id == "Mountain Map" then Wait.frames(function() rttSpawnPriority("Mountain Map", RTT_PRIO_MOUNTAINMAP) end, 2) end
  if id == "Winter Map" then Wait.frames(function() rttSpawnPriority("Winter Map", RTT_PRIO_WINTERMAP) end, 2) end
  if id == "Gorge Map" then Wait.frames(function() rttSpawnPriority("Gorge Map", RTT_PRIO_GORGEMAP) end, 2) end
  if id == "Marsh Map" then Wait.frames(function() rttSpawnMarshNumbers() end, 3) end
  -- A SAME-MAP REBUILD KEEPS THE BOARD. rttNewGame re-places the current map so a new game never
  -- inherits the last one's layout -- most visibly the Marsh, which re-rolls its flooding, its suits
  -- and its ruins on every build, and which has two different boards (4-player flooded, 5-player with
  -- towns) behind one button. Destroying and respawning the board underneath all that is pure churn,
  -- so it stays put and only what sits on it is cleared.
  local RTT_KEEP_BOARD = nil
  if keepBoard then pcall(function() RTT_KEEP_BOARD = rttFindMapObject() end) end
  removeMapItems(RTT_KEEP_BOARD)
  Wait.time(function() pcall(function() rttPlaceUnplacedVPs() end) end, 2.0)  -- markers that had no track yet
  -- The battle mat belongs to the map, so it spawns HERE, with every map placement -- the map BUTTONS
  -- call makeMap directly and so never got one; only the draft's rttPlaceMap did. Tagged "Map Object",
  -- so removeMapItems above clears the previous one and there is never a second. Maintainer 2026-09-04:
  -- "spawn automatically when any map is selected... remove the battle map option button".
  Wait.frames(function()
    if rttFixture(RTT_TAG_MAT) == nil then
      makeSpecialWithTag("Tools", "Battle Mat", 33.17, 1.55, 9.21, "Map Object")
      Wait.frames(function()
        for _, o in ipairs(getObjectsWithTag("Map Object")) do
          pcall(function()
            if o.getName() == "Battle Mat" then o.addTag(RTT_FIXTURE_TAG) o.addTag(RTT_TAG_MAT) end
          end)
        end
      end, 2)
    end
  end, 2)
  Wait.frames(function() pcall(function() rttSpawnMapExtras() end) end, 3)   -- timer + counter, with the map
  if id == "The Wastelands Map" or id == "The Deep Woods Map" then
    makeMapTool("The Law of Slug")
  end

  if id == "Narrows and Islets Map" then
    makeMapTool("Narrows and Islets Instructions")
  end

  if id == "Tropics Map" then
    makeMapTool("Tropics Instructions")
  end


  --local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING["Maps"][id]['data']
  local RTT_OV = nil
  if id == "Marsh Map" then
    for _,o in ipairs(RTT_MARSH_PIECES or {}) do if o ~= nil then pcall(function() o.destruct() end) end end
    RTT_MARSH_PIECES = {}
    if RTT_5P_MARSH then RTT_OV = rttMarshPlan5P(objects) else RTT_OV = rttMarshPlan(objects) end
  end
  if id == "Mountain Map" then RTT_OV = rttMountainPlan(objects) end
  local scale = rttPlaceScale()

  local boardIdx = (RTT_KEEP_BOARD ~= nil) and rttMapBoardIndex(objects) or nil
  for idx,v in ipairs(objects) do
    local rtt_rot = nil
    local rtt_ov = false
    local new_pos
    local ovJson = nil
    local skip = (boardIdx ~= nil and idx == boardIdx)   -- the board is already on the table
    if RTT_OV ~= nil and RTT_OV[idx] ~= nil then
      skip = skip or (RTT_OV[idx].skip == true)   -- `or`: never un-skip the board we kept
      ovJson = RTT_OV[idx].json
    end
    if RTT_OV ~= nil and RTT_OV[idx] ~= nil and RTT_OV[idx].world ~= nil then
      rtt_rot = RTT_OV[idx].rot
      rtt_ov = true
      new_pos = RTT_OV[idx].world
    else
      local vec = Vector(v.move_to) * scale
      vec.y = vec.y - 0.1
      vec = vec * Vector({15.5, 1, 15.5})
      new_pos = vec
      new_pos.y = new_pos.y+10-8.5+0.05-0.07+10.08
    end
    local ob = nil
    if not skip then
    ob = spawnObjectJSON({
        json              = ovJson or v.json,
        position          = new_pos,
        rotation          = rtt_rot,
        callback_function = function(spawned_object)

        if rtt_ov then spawned_object.setLock(true) end
        if spawned_object.name == "Bag" then spawned_object.shuffle() end
        -- Treasure Island Treasure
        if spawned_object.getName() == "Treasure" then
          spawned_object.shuffle()
          spawned_object.addTag("Map Object")
          end
        spawned_object.addTag("Map Object")
        end
    })
    end
    if rtt_ov and ob ~= nil and RTT_MARSH_PIECES ~= nil then RTT_MARSH_PIECES[#RTT_MARSH_PIECES + 1] = ob end
  end
  if id ~= "Marsh Map" then shuffleMaps(id) end
end

function shuffleMaps(id)

  -- shuffle and remove random swords from Urban Map
  local ruins = getObjectsWithTag("Dummy")

  if #ruins > 1 then
    local n = math.random(4) -- gets number 1 through four

    for i=1, #ruins do
      if i != n then
        ruins[i].destroy()
      else
        ruins[i].removeTag("Dummy")
      end
    end
  end

  -- Blighted Grove Map Setup
  if id == "Blighted Grove Map" then
    local deletables = getObjectsWithTag("BlightedPair" .. tostring(math.random(2)))

    for i = 1, #deletables do
      deletables[i].destroy()
    end

  end


  local ruins = getObjectsWithTag("Ruin")
  local positions = {}
  for x, ruin in ipairs(ruins) do
    positions[x] = ruin.getPosition()
  end
  -- ONCE. shuffle() is a correct Fisher-Yates, so one pass is already a uniform permutation and
  -- composing thirty of them just gives another uniform permutation -- 29 wasted passes per map build.
  ruins = shuffle(ruins)
  for x=1, #ruins do
    ruins[x].setPosition(positions[x])
  end

  local clearingMarkers = getObjectsWithTag("Clearing Marker")
  local positions = {}
  local rotations = {}
  for x, clearingMarker in ipairs(clearingMarkers) do
    positions[x] = clearingMarker.getPosition()
    rotations[x] = clearingMarker.getRotation()
  end
  -- ONCE, for the same reason. What was here read `i=1,10 do ... end` with no `for`, which Lua parses
  -- as the assignment `i = 1, 10` (the 10 discarded) followed by a bare do-block -- so it shuffled
  -- exactly once, which is the right number, by accident, and leaked a global `i`. Written properly it
  -- says what it does; the missing `for` was deliberately NOT restored, since that would have turned
  -- an accidentally-correct line into a genuinely wasteful one to match its neighbour above.
  clearingMarkers = shuffle(clearingMarkers)
  for x=1, #clearingMarkers do
    clearingMarkers[x].setPosition(positions[x])
    clearingMarkers[x].setRotation(rotations[x])
  end

  local shuffleableDecks = getObjectsWithTag("Shuffleable")
  for x=1, #shuffleableDecks do
      shuffleableDecks[x].shuffle()
      shuffleableDecks[x].removeTag("Shuffleable")
  end


  local tools = getObjectsWithTag("Tool")
  local cityMarkers = getObjectsWithTag("City Marker")

  if #cityMarkers != 0 and #tools != 0 then
    local chance = math.random(1,6)
    if chance == 1 then
      -- nothing
    elseif chance == 2 then
      local tp1 = tools[1].getPosition()
      local tp2 = tools[2].getPosition()

      tools[1].setPosition(tp2)
      tools[2].setPosition(tp1)

      local mp1 = cityMarkers[1].getPosition()
      local mp2 = cityMarkers[2].getPosition()
      local mr1 = cityMarkers[1].getRotation()
      local mr2 = cityMarkers[2].getRotation()

      cityMarkers[1].setPosition(mp2)
      cityMarkers[2].setPosition(mp1)
      cityMarkers[1].setRotation(mr2)
      cityMarkers[2].setRotation(mr1)
    elseif chance == 3 then
      local tp1 = tools[1].getPosition()
      local tp2 = tools[3].getPosition()

      tools[1].setPosition(tp2)
      tools[3].setPosition(tp1)

      local mp1 = cityMarkers[1].getPosition()
      local mp2 = cityMarkers[3].getPosition()
      local mr1 = cityMarkers[1].getRotation()
      local mr2 = cityMarkers[3].getRotation()

      cityMarkers[1].setPosition(mp2)
      cityMarkers[3].setPosition(mp1)
      cityMarkers[1].setRotation(mr2)
      cityMarkers[3].setRotation(mr1)
    elseif chance == 4 then
      local tp1 = tools[2].getPosition()
      local tp2 = tools[3].getPosition()

      tools[2].setPosition(tp2)
      tools[3].setPosition(tp1)

      local mp1 = cityMarkers[2].getPosition()
      local mp2 = cityMarkers[3].getPosition()
      local mr1 = cityMarkers[2].getRotation()
      local mr2 = cityMarkers[3].getRotation()

      cityMarkers[2].setPosition(mp2)
      cityMarkers[3].setPosition(mp1)
      cityMarkers[2].setRotation(mr2)
      cityMarkers[3].setRotation(mr1)
    elseif chance == 5 then
      local tp1 = tools[1].getPosition()
      local tp2 = tools[2].getPosition()
      local tp3 = tools[3].getPosition()

      tools[1].setPosition(tp2)
      tools[2].setPosition(tp3)
      tools[3].setPosition(tp1)

      local mp1 = cityMarkers[1].getPosition()
      local mp2 = cityMarkers[2].getPosition()
      local mp3 = cityMarkers[3].getPosition()
      local mr1 = cityMarkers[1].getRotation()
      local mr2 = cityMarkers[2].getRotation()
      local mr3 = cityMarkers[3].getRotation()

      cityMarkers[1].setPosition(mp2)
      cityMarkers[2].setPosition(mp3)
      cityMarkers[3].setPosition(mp1)
      cityMarkers[1].setRotation(mr2)
      cityMarkers[2].setRotation(mr3)
      cityMarkers[3].setRotation(mr1)
    elseif chance == 6 then
      local tp1 = tools[1].getPosition()
      local tp2 = tools[2].getPosition()
      local tp3 = tools[3].getPosition()

      tools[1].setPosition(tp3)
      tools[2].setPosition(tp1)
      tools[3].setPosition(tp2)

      local mp1 = cityMarkers[1].getPosition()
      local mp2 = cityMarkers[2].getPosition()
      local mp3 = cityMarkers[3].getPosition()
      local mr1 = cityMarkers[1].getRotation()
      local mr2 = cityMarkers[2].getRotation()
      local mr3 = cityMarkers[3].getRotation()

      cityMarkers[1].setPosition(mp3)
      cityMarkers[2].setPosition(mp1)
      cityMarkers[3].setPosition(mp2)
      cityMarkers[1].setRotation(mr3)
      cityMarkers[2].setRotation(mr1)
      cityMarkers[3].setRotation(mr2)
    end
  end

  for i=1,5 do
    local clearingMarkers = getObjectsWithTag("Clearing "..i)

    if #clearingMarkers != 0 then
      if i == 3 then
        local freeCityMarkers = getObjectsWithTag("Lost City Marker")
        if math.random(1,2) == 2 then
          local n = 2

          local freeCity = getObjectsWithTag("Free City")
          local lcLoc = freeCity[1].getPosition()
          local lcRot = freeCity[1].getRotation()

          local mp1 = clearingMarkers[n].getPosition()
          local mr1 = clearingMarkers[n].getRotation()

          freeCity[1].setPosition(mp1)
          freeCity[1].setRotation(mr1)

          clearingMarkers[n].setPosition(lcLoc)
          clearingMarkers[n].setRotation(lcRot)

          freeCityMarkers[1].destroy()
        else
          freeCityMarkers[2].destroy()
        end
      end

      local chance = math.random(1,6)
      if chance == 1 then
        -- nothing
      elseif chance == 2 then
        local mp1 = clearingMarkers[1].getPosition()
        local mp2 = clearingMarkers[2].getPosition()
        local mr1 = clearingMarkers[1].getRotation()
        local mr2 = clearingMarkers[2].getRotation()

        clearingMarkers[1].setPosition(mp2)
        clearingMarkers[2].setPosition(mp1)
        clearingMarkers[1].setRotation(mr2)
        clearingMarkers[2].setRotation(mr1)

      elseif chance == 3 then
        local mp1 = clearingMarkers[1].getPosition()
        local mp2 = clearingMarkers[3].getPosition()
        local mr1 = clearingMarkers[1].getRotation()
        local mr2 = clearingMarkers[3].getRotation()

        clearingMarkers[1].setPosition(mp2)
        clearingMarkers[3].setPosition(mp1)
        clearingMarkers[1].setRotation(mr2)
        clearingMarkers[3].setRotation(mr1)
      elseif chance == 4 then
        local mp1 = clearingMarkers[2].getPosition()
        local mp2 = clearingMarkers[3].getPosition()
        local mr1 = clearingMarkers[2].getRotation()
        local mr2 = clearingMarkers[3].getRotation()

        clearingMarkers[2].setPosition(mp2)
        clearingMarkers[3].setPosition(mp1)
        clearingMarkers[2].setRotation(mr2)
        clearingMarkers[3].setRotation(mr1)
      elseif chance == 5 then

        local mp1 = clearingMarkers[1].getPosition()
        local mp2 = clearingMarkers[2].getPosition()
        local mp3 = clearingMarkers[3].getPosition()
        local mr1 = clearingMarkers[1].getRotation()
        local mr2 = clearingMarkers[2].getRotation()
        local mr3 = clearingMarkers[3].getRotation()

        clearingMarkers[1].setPosition(mp2)
        clearingMarkers[2].setPosition(mp3)
        clearingMarkers[3].setPosition(mp1)
        clearingMarkers[1].setRotation(mr2)
        clearingMarkers[2].setRotation(mr3)
        clearingMarkers[3].setRotation(mr1)

      elseif chance == 6 then
        local mp1 = clearingMarkers[1].getPosition()
        local mp2 = clearingMarkers[2].getPosition()
        local mp3 = clearingMarkers[3].getPosition()
        local mr1 = clearingMarkers[1].getRotation()
        local mr2 = clearingMarkers[2].getRotation()
        local mr3 = clearingMarkers[3].getRotation()

        clearingMarkers[1].setPosition(mp3)
        clearingMarkers[2].setPosition(mp1)
        clearingMarkers[3].setPosition(mp2)
        clearingMarkers[1].setRotation(mr3)
        clearingMarkers[2].setRotation(mr1)
        clearingMarkers[3].setRotation(mr2)
      end
    end
  end

end

function shuffleAssets(tag)
  local assets = getObjectsWithTag(tag)
  -- List of object GUIDs

   -- Get current positions of all objects
   local positions = {}
   for _, asset in pairs(assets) do
       local obj = asset
       if obj then
           table.insert(positions, obj.getPosition())
       else
           print("Object with GUID " .. guid .. " not found!")
           return
       end
   end

   -- Shuffle the positions
   for i = #positions, 2, -1 do
       local j = math.random(1, i) -- Random index
       positions[i], positions[j] = positions[j], positions[i] -- Swap positions
   end

   -- Reassign positions to objects
   for i, asset in pairs(assets) do
       local obj = asset
       if obj then
           obj.setPosition(positions[i])
       end
   end
end

function removeTagFromAssets(tag)
  local assets = getObjectsWithTag(tag)
  for x=1, #assets do
    assets[x].removeTag(tag)
  end
end






math.randomseed( os.time() )  -- Seed the pseudo-random number generator

function shuffle( t )
  if type(t) ~= "table" then return false end
  for i = #t, 2, -1 do
    local j = math.random( i )
    t[i], t[j] = t[j], t[i]
  end
  return t
end







-- `keep` spares ONE object, which is how a same-map rebuild leaves the board itself standing while
-- everything on it is cleared and re-rolled. Maintainer, 2026-09-06: "reset the clearing makers the
-- landmarks everything that goes on the board because anyway they are reshuffled, reset the board
-- itself and the clearing numbers only if it is another map."
function removeMapItems(keep)
    for _,v in ipairs(getObjectsWithTag("Map Object")) do
      local fixture = false
      pcall(function() fixture = v.hasTag(RTT_FIXTURE_TAG) end)
      if not fixture and (keep == nil or v ~= keep) then v.destruct() end
    end
end

-- Which blueprint entry IS the board. Same rule rttFindMapObject uses on the spawned objects -- the
-- piece with the most snap points -- applied to the json instead, so the two always agree on which
-- one to leave alone. Counting the entry TYPE does not work: the board is a Custom_Token on the
-- Marsh but Lake ships two of those and Mountain seven.
function rttMapBoardIndex(objects)
  local best, bestN = nil, -1
  for idx, v in ipairs(objects or {}) do
    local n = 0
    local sp = string.match(v.json, '"AttachedSnapPoints"%s*:%s*%[(.*)')
    if sp ~= nil then for _ in string.gmatch(sp, '"Position"') do n = n + 1 end end
    if n > bestN then best, bestN = idx, n end
  end
  return best
end


function removeDeckItems()
    for _,v in ipairs(getObjectsWithTag("Deck Object")) do
      v.destruct()
    end
end





function concat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]  --corrected bug. if t1[#t1+i] is used, indices will be skipped
    end
    return t1
end


------------------------------------------------------------------- gizmo --
-- Two keystrokes on the warriors of YOUR OWN faction, and nothing else. What used to be here was
-- the ported Ginso's Gizmo: ~390 lines of "return any hovered component to a supply you configured
-- first", with per-object destination tracks, saved state and its own error reporting. The
-- maintainer replaced that spec outright (2026-09-05):
--
--   hovering one of your warriors -> it goes back to your supply
--   hovering nothing              -> one warrior comes out of your supply, at your pointer
--   nothing in the supply         -> nothing happens
--
-- "Yours" is resolved from where you are SEATED. rttPlaceFaction publishes faction -> seat colour
-- for every faction it places, by both the draft and the manual path (the colour is derived from the
-- board's own position when the caller does not supply one), so the colour pressing the key
-- identifies the faction. The faction's blueprint then names its supply bag and its warrior, so
-- there is no hand-kept table to drift.

-- Which faction does this colour control? Straight off the seat record, which the board owns and
-- persists -- the Global is only a mirror of it for other objects.
--
-- The old version read the Global alone, and resolved a duplicate colour with `for faction, seat in
-- pairs(dec) ... found = faction`: last writer wins, in Lua's arbitrary pairs order. So a stale entry
-- from an earlier game, or two factions publishing the same colour, silently handed the key-presser
-- somebody else's supply -- and a different somebody from one press to the next.
function rttSeatFaction(color)
  if color == nil or color == "" then return nil end
  for _, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.color == color and s.faction ~= nil and s.faction ~= "" then return s.faction end
  end
  -- Fallback for a table this board did not set up (or a record lost with the script's state): read
  -- the mirror, but refuse an AMBIGUOUS answer rather than pick one at random.
  local hits = {}
  pcall(function()
    local raw = Global.getVar("RTT_SEAT_COLOR")
    if type(raw) ~= "string" or raw == "" then return end
    local dec = JSON.decode(raw)
    if type(dec) ~= "table" then return end
    for faction, seat in pairs(dec) do
      if seat == color then hits[#hits + 1] = faction end
    end
  end)
  if #hits == 1 then return hits[1] end
  return nil
end

-- The supply bag and warrior names come out of the faction's own blueprint: a Custom_Model_Bag
-- called "<something> Supply", and the piece whose name ends in "Warrior". Reading them beats a
-- hand-kept table, which would have to list every faction's naming quirk ("Hundreds Supply" for the
-- rats, "Lizard Cult Warrior" for the lizards) and would rot the moment a faction was added.
-- supply + warrior for one blueprint entry
local function rttPieceNamesFromDef(def)
  local supply, warrior, firstSupply = nil, nil, nil
  pcall(function()
    do
      if def ~= nil and def['data'] ~= nil then
        -- The warrior first, so the right bag can be recognised by what is inside it. Look at every
        -- Nickname in the blueprint, not just the top-level pieces: the Alliance keeps ALL of its
        -- warriors inside the bag, so a top-level-only scan found none for them.
        for _, v in ipairs(def['data']) do
          if warrior == nil then
            for nick in v.json:gmatch('"Nickname":%s*"([^"]*)"') do
              if warrior == nil and nick:match("Warrior$") then warrior = nick end
            end
          end
        end
        for _, v in ipairs(def['data']) do
          local nick = v.json:match('"Nickname":%s*"([^"]*)"')
          if nick ~= nil and nick:match("Supply$") then
            if firstSupply == nil then firstSupply = nick end
            -- A faction can have more than one bag: the Marquise keeps warriors in "Marquise Supply"
            -- and wood in "Wood Supply", and taking the first match handed out lumber. The warriors'
            -- bag is the one that CONTAINS a warrior.
            if supply == nil and warrior ~= nil
               and v.json:find('"Nickname": "' .. warrior .. '"', 1, true) then
              supply = nick
            end
          end
        end
      end
    end
  end)
  return supply or firstSupply, warrior
end

function rttFactionPieceNames(faction)
  if faction == nil then return nil, nil end
  for _, cat in pairs(EVERYTHING) do
    if cat[faction] ~= nil then return rttPieceNamesFromDef(cat[faction]) end
  end
  return nil, nil
end

-- warrior name -> its own supply bag, for EVERY faction in the mod. Hovering an enemy warrior sends
-- it home to ITS supply, which is the original gizmo's behaviour and the maintainer wants it kept --
-- so the piece decides the destination, not whoever pressed the key. Built once and cached: the
-- scan reads every blueprint's JSON.
RTT_WARRIOR_SUPPLY = nil
-- the first object on the table with this name. Declared HERE, above every user: it is a `local`, so
-- anything calling it EARLIER in the file would resolve a nil GLOBAL instead. (Deleted by accident
-- while restructuring the gizmo and restored -- the tests caught it immediately.)
local function rttFindByName(name)
  if name == nil or name == "" then return nil end
  for _, o in ipairs(getAllObjects()) do
    if (o.getName() or "") == name then return o end
  end
  return nil
end

-- piece name -> the BAG it belongs in, for every faction in the mod. Not just warriors: the
-- Marquise's "Wood" lives in "Wood Supply" the same way, and the maintainer wants NUMPAD 0 to send it
-- home too. Anything a blueprint stores inside a Custom_Model_Bag is covered by construction, so a
-- faction added later needs no table edited here. Built once and cached.
RTT_BAG_OF = nil
function rttBagOfMap()
  if RTT_BAG_OF ~= nil then return RTT_BAG_OF end
  local m = {}
  pcall(function()
    for _, cat in pairs(EVERYTHING) do
      for _, def in pairs(cat) do
        if type(def) == "table" and def['data'] ~= nil then
          for _, v in ipairs(def['data']) do
            local bag = v.json:match('"Nickname":%s*"([^"]*Supply)"')
            if bag ~= nil then
              for nick in v.json:gmatch('"Nickname":%s*"([^"]*)"') do
                if nick ~= "" and nick ~= bag and m[nick] == nil then m[nick] = bag end
              end
            end
          end
        end
      end
    end
  end)
  RTT_BAG_OF = m
  return m
end

-- kept for the warriors-only callers: the same map, narrowed to names ending in "Warrior".
RTT_WARRIOR_SUPPLY = nil
function rttWarriorSupplyMap()
  if RTT_WARRIOR_SUPPLY ~= nil then return RTT_WARRIOR_SUPPLY end
  local m = {}
  for nick, bag in pairs(rttBagOfMap()) do
    if nick:match("Warrior$") then m[nick] = bag end
  end
  RTT_WARRIOR_SUPPLY = m
  return m
end

-- EXTRA RETURN SLOTS -- where a piece goes back to, which is NOT always where it spawned.
--
-- Several factions park one piece well away from its row: a roost at move_to -17.5 against a row at
-- 3.7..11.7, an enclave at -3.0 against a grid at -16..-19, the sixth recruiter/workshop/saw mill,
-- each garden's fifth. The maintainer spawned the cats, birds and lizards and moved every one of them
-- into its row so I could read the positions off (TS_AutoSave, 2026-09-06 17:44) -- and was explicit
-- that this was for the GIZMO to return them to, NOT a change to where they spawn. The blueprint is
-- therefore untouched and these live here instead, in the same move_to frame, added to the slot list
-- when the faction spawns.
--
-- The rats are the exception and are NOT here: he asked for their sixth stronghold to join the row
-- outright, so that one IS a blueprint change, with the supply, the warlord and the four warriors all
-- shifted 1.4 to clear it.
RTT_HOME_EXTRA = {
  ["Marquise de Cat"]  = { { "Recruiter",     { -2.829, 0.2,  -7.484 } },
                           { "Workshop",      { -2.811, 0.2,  -5.637 } },
                           { "Saw Mill",      { -2.875, 0.2,  -3.675 } } },
  ["Eyrie Dynasties"]  = { { "Roost",         {  2.140, 0.2,  -4.330 } } },
  ["The Lizard Cult"]  = { { "Fox Garden",    { -6.756, 0.2, -12.144 } },
                           { "Rabbit Garden", { -6.733, 0.2, -10.538 } },
                           { "Mouse Garden",  { -6.752, 0.2,  -8.936 } } },
  ["Lilypad Diaspora"] = { { "Enclave",       { -19.615, 0.1,  3.568 } } },
}

-- Add a faction's extra return slots -- the spots the maintainer measured that are NOT spawn
-- positions -- transformed exactly as rttSpawnFaction transforms a piece's move_to.
--
-- Called FROM the spawn callback, once per piece, with the name and facing of the piece that just
-- landed. A slot has no piece of its own, so its facing has to be copied from a real one; the only
-- moment a real one exists with spawnRy already applied is inside its own callback. `done` is this
-- spawn's guard so the first Fox Garden to land claims the Fox Garden slot and the rest skip it.
function rttAddHomeExtras(faction, cx, cz, flip, rotationY, name, rot, done)
  local list = RTT_HOME_EXTRA[faction]
  if list == nil or name == nil or name == "" or rot == nil then return end
  done = done or {}
  local scale = rttPlaceScale()
  for i, e in ipairs(list) do
    if e[1] == name and not done[i] then
      done[i] = true
      local vec = Vector(e[2]) * scale
      if rotationY ~= nil then
        vec = vec * Vector(15.5, 1, 15.5)
        vec:rotateOver("y", rotationY)
      elseif flip then
        vec = vec * Vector(-15.5, 1, -15.5)
      else
        vec = vec * Vector(15.5, 1, 15.5)
      end
      RTT_HOME["x" .. faction .. e[1] .. i] = {
        n = e[1], f = faction,
        p = { cx + vec.x, 11.56 + vec.y - 0.1, cz + vec.z },
        r = { rot[1], rot[2], rot[3] },
      }
    end
  end
end

-- ---- SEND HOME: the home SLOTS of a repeated piece, and which are free ------------------------
-- Maintainer, 2026-09-06: a returning piece does not go back to its OWN spot, it goes to the
-- rightmost empty slot of its kind -- roosts, enclaves, the moles' buildings. Acclaim is a special
-- case he specified stack by stack. Tunnels go back to their own spot, having no row to speak of.
--
-- DIRECTION IS UNCONFIRMED. Board-local +x is the player's right on one row and their left on the
-- other, because faction boards carry rotY ~180 and the far row mirrors that -- the same trap that
-- inverted the crow hidden zone. The maintainer is checking at the table; RTT_HOME_RIGHT_IS_PLUS_X is
-- the ONE place to flip when he says. Everything else is direction-agnostic.
-- Kept for reference: +x is the player's right on the NEAR row. rttHomeSlots no longer reads it --
-- it derives the sign per seat, because one global sign is wrong for half the table.
RTT_HOME_RIGHT_IS_PLUS_X = true

-- Types that do NOT use a fill order: each piece returns to its own recorded spot.
RTT_HOME_OWN_SPOT = { ["Tunnel"] = true }

-- Acclaim fills stack by stack, in the maintainer's order: bottom-right, bottom-left, top-right,
-- top-left, two per stack.
RTT_HOME_STACKED = { ["Acclaim"] = 2 }

-- Every home slot recorded for one piece NAME, most-preferred first. Built from RTT_HOME, so it
-- reflects what actually spawned at this table rather than a table that could drift from it.
function rttHomeSlots(name)
  local out = {}
  for _, h in pairs(RTT_HOME or {}) do
    if h.n == name then out[#out + 1] = h end
  end
  if #out == 0 then return out end
  -- The PARKED ODD ONE OUT. Several types keep one piece well away from the neat group -- a roost at
  -- x -17.5 against a row at 3.7..11.7, an enclave at -3.0 against a grid at -16..-19. The maintainer
  -- has not said what those spots are yet and asked that nothing be sent there meanwhile, so they are
  -- dropped from the fill order: if the group is full, the key does nothing rather than guessing.
  --
  -- Found by NEAREST-NEIGHBOUR distance, not by a fixed window. A window has to be wide enough for a
  -- 12-slot grid and narrow enough to catch an outlier 22 away, and there is no such number. Every
  -- slot in a real group has a close neighbour -- 1.6 along a roost row, 1.8 across the enclave grid,
  -- 0.1 between two acclaim in a stack -- while a parked piece has none, so anything more than four
  -- times the typical spacing from its nearest fellow is the odd one out. That works for rows, grids
  -- and stacks without knowing which it is looking at.
  if #out > 2 then
    local near = {}
    for i, h in ipairs(out) do
      local best = nil
      for j, g in ipairs(out) do
        if i ~= j then
          local dx, dy, dz = h.p[1]-g.p[1], h.p[2]-g.p[2], h.p[3]-g.p[3]
          local d = dx*dx + dy*dy + dz*dz
          if best == nil or d < best then best = d end
        end
      end
      near[i] = math.sqrt(best or 0)
    end
    local sorted = {}
    for _, v in ipairs(near) do sorted[#sorted + 1] = v end
    table.sort(sorted)
    local med = sorted[math.max(1, math.ceil(#sorted / 2))]
    local keep = {}
    for i, h in ipairs(out) do
      if near[i] <= math.max(med * 4, 0.05) then keep[#keep + 1] = h end
    end
    if #keep > 0 then out = keep end
  end
  -- FROM THE PLAYER'S VIEW, NOT THE TABLE'S. Maintainer, 2026-09-06: "it look s like the issue is that
  -- you take the absolute direction for left or right ... but its rightmost for the player looking at
  -- his faction board. so for seat 1 and 2 its the opposite absolute direction than for seat 3 and 4",
  -- and the rule behind it: "everything is always referenced with respect to the vision of the player
  -- otherwise instructions would change depending on seat which makes no sense".
  --
  -- RTT_HOME_RIGHT_IS_PLUS_X was ONE sign for the whole table, so "the rightmost empty slot" meant the
  -- player's right on the near row and their LEFT on the far row -- which is what he saw with the
  -- Alliance's sympathy. A far-row seat is rotated 180, so BOTH axes invert together: the player's
  -- right becomes -x and "nearer me" becomes larger z. Multiplying both comparisons by the same sign
  -- is exactly that half-turn, so the comparator reads the row in the seat's own frame.
  --
  -- The sign comes from where the slots ARE, not from a table: every slot of one piece name belongs to
  -- one faction at one seat, and seats sit at z about -46 or +46.
  local sz = 0
  for _, h in ipairs(out) do sz = sz + h.p[3] end
  local s = (sz > 0) and -1 or 1
  local per = RTT_HOME_STACKED[name]
  table.sort(out, function(a, b)
    if per ~= nil then                       -- stacks: nearest row first, then right to left, then up
      if math.abs(a.p[3] - b.p[3]) > 0.2 then return a.p[3] * s < b.p[3] * s end
      if math.abs(a.p[1] - b.p[1]) > 0.2 then return a.p[1] * s > b.p[1] * s end
      return a.p[2] < b.p[2]
    end
    if math.abs(a.p[1] - b.p[1]) > 0.2 then return a.p[1] * s > b.p[1] * s end
    if math.abs(a.p[3] - b.p[3]) > 0.2 then return a.p[3] * s < b.p[3] * s end
    return a.p[2] < b.p[2]
  end)
  return out
end

-- is any piece of this name already sitting on that slot?
--
-- `ytol` matters for STACKS. Acclaim's two slots per stack differ only in height, by 0.1, so a fixed
-- 0.6 vertical tolerance made the upper slot read as occupied by the piece in the lower one -- the
-- stack never filled, and each returning acclaim skipped to the next empty stack instead. Maintainer,
-- 2026-09-06: "when two stacks of 2 are empty, you put 1 in the empty stack then the one after you put
-- it in the other empty stack instead of filling all stacks with 2 first." The caller passes half the
-- smallest height gap between slots sharing a spot, so the tolerance can never span a stack step.
function rttHomeSlotTaken(slot, name, ignore, ytol)
  ytol = ytol or 0.6
  local taken = false
  pcall(function()
    for _, o in ipairs(getAllObjects()) do
      if o ~= ignore and (o.getName() or "") == name then
        local p = o.getPosition()
        local dx, dy, dz = p.x - slot.p[1], p.y - slot.p[2], p.z - slot.p[3]
        if dx * dx + dz * dz < 0.36 and math.abs(dy) < ytol then taken = true return end
      end
    end
  end)
  return taken
end

-- half the smallest height step between two slots that share a spot, or 0.6 when none do.
function rttHomeYTol(slots)
  local best = nil
  for i, a in ipairs(slots) do
    for j, b in ipairs(slots) do
      if i ~= j then
        local dx, dz = a.p[1] - b.p[1], a.p[3] - b.p[3]
        if dx * dx + dz * dz < 0.36 then
          local dy = math.abs(a.p[2] - b.p[2])
          if dy > 0.001 and (best == nil or dy < best) then best = dy end
        end
      end
    end
  end
  if best == nil then return 0.6 end
  return best * 0.45
end

-- YOUR supply bag, or nil and the reason why not. The reason matters: this used to return a bare nil
-- and let the caller fall through to a geometric search of the whole table, so a Vagabond seat -- which
-- has no warriors AT ALL -- silently handed the player the NEAREST supply, which is an opponent's.
-- WHICH FACTION IS YOURS, for the gizmo only. Your last pick if you have made one, otherwise the seat
-- record. Both gizmo keys ask this, so switching faction moves the whole gizmo with you rather than
-- half of it.
function rttMyFaction(color)
  -- YOUR MOST RECENT PICK, read off the seats themselves. There is no side table any more: each seat
  -- remembers which press created it and in what order, so "the faction I last picked" is just the
  -- newest seat I made.
  --
  -- Matched on the PERSON where there is one -- a colour that changes hands must not carry the old
  -- claim with it: Alice picks the Marquise as Red and leaves, Bob takes Red, and Bob's numpad 1 used
  -- to hand him Marquise warriors. Where nobody is seated (hotseat, or a table nobody has joined) the
  -- pressing colour is the only identity there is, so it is used instead.
  local who = rttPersonIn(color)
  local best, bestN = nil, -1
  for _, s in ipairs(RTT_SEATS or {}) do
    if s ~= nil and s.faction ~= nil and s.faction ~= "" and (s.pickedAt or 0) > bestN then
      local mine = (who ~= nil and s.owner == who) or (who == nil and s.picker == color)
      if mine then best, bestN = s.faction, s.pickedAt or 0 end
    end
  end
  if best ~= nil then return best end
  return rttSeatFaction(color)
end

function rttMySupplyBag(color)
  local faction = rttMyFaction(color)
  if faction ~= nil then
    local supName, warName = rttFactionPieceNames(faction)
    if supName == nil or warName == nil then
      return nil, "the " .. faction .. " has no warrior supply."
    end
    local bag = rttFindByName(supName)
    if bag ~= nil then return bag end
    return nil, "could not find the " .. supName .. " on the table."
  end

  -- No seat record for this colour: a table this board did not set up, or a colour nobody drafted in.
  -- Fall back to the supply nearest your own hand -- but only if it is genuinely YOURS. The seats are
  -- 92 apart and a supply sits ~18 from its own hand, so anything past 50 belongs to somebody else.
  local hp = nil
  pcall(function() hp = Player[color].getHandTransform(1).position end)
  if hp == nil then return nil, "you are not seated at a hand." end

  local known = {}
  for _, sup in pairs(rttWarriorSupplyMap()) do known[sup] = true end
  local best, bestd = nil, nil
  for _, o in ipairs(getAllObjects()) do
    if known[o.getName() or ""] then
      local p = o.getPosition()
      local d = (p.x - hp.x) ^ 2 + (p.z - hp.z) ^ 2
      if bestd == nil or d < bestd then best, bestd = o, d end
    end
  end
  if best ~= nil and bestd <= 2500 then return best end
  if best ~= nil then return nil, "the nearest supply is not at your seat." end
  return nil, "no faction is seated in your colour."
end

-- NUMPAD 0 -- SEND HOME. Maintainer, 2026-09-06. It no longer spawns anything: hovering nothing does
-- nothing at all. What it does is put whatever you ARE hovering back where it belongs.
--   * a warrior, or the Marquise's wood -> back into its own supply bag (rttBagOfMap covers both, and
--     anything else a blueprint stores in a bag, without a hand-kept list);
--   * a building or token with a home -> the RIGHTMOST EMPTY slot of its kind, not its own spot, so
--     roosts, enclaves, strongholds and the moles' buildings refill a tidy row;
--   * Acclaim -> stack by stack, two per stack, in his order;
--   * a Tunnel -> its own spot, having no row;
--   * anything else -> nothing, silently. His call: a hireling or a card is not the gizmo's business
--     and a message every time would be noise.
function rttGizmoHome(color)
  local hovered = nil
  pcall(function() hovered = Player[color].getHoverObject() end)
  if hovered == nil then return end                    -- hovering nothing: NOT a spawn any more
  local name = hovered.getName() or ""
  if name == "" then return end

  -- NO PERMISSION CHECK. There was one for a few hours -- "gizmo 0 should not work on other player's
  -- warriors and token buildings" -- and it was removed the same day: "remove the player permission
  -- with numpad 0 so it s not broken when it s wrong about who is who". Deciding whose piece it is
  -- means deciding who YOU are, and when that answer is wrong the key silently does nothing, which is
  -- worse than moving somebody else's warrior to its own supply. The PIECE chooses its destination
  -- again, so being wrong about the player costs nothing.

  -- 1. does it live in a bag?
  local bag = rttFindByName(rttBagOfMap()[name])
  if bag ~= nil then
    pcall(function() bag.putObject(hovered) end)
    return
  end

  -- 2. its own spot, for the types that have no row
  local home = (RTT_HOME or {})[hovered.getGUID()]
  if RTT_HOME_OWN_SPOT[name] and home ~= nil then
    pcall(function()
      hovered.setPositionSmooth({ home.p[1], home.p[2], home.p[3] }, false, true)
      hovered.setRotation({ home.r[1], home.r[2], home.r[3] })
    end)
    return
  end

  -- 3. the rightmost empty slot of its kind
  local slots = rttHomeSlots(name)
  local ytol = rttHomeYTol(slots)
  for _, sl in ipairs(slots) do
    if not rttHomeSlotTaken(sl, name, hovered, ytol) then
      pcall(function()
        hovered.setPositionSmooth({ sl.p[1], sl.p[2], sl.p[3] }, false, true)
        hovered.setRotation({ sl.r[1], sl.r[2], sl.r[3] })
      end)
      return
    end
  end

  -- 4. its own recorded spot, if it has one and every slot was full
  if home ~= nil then
    pcall(function()
      hovered.setPositionSmooth({ home.p[1], home.p[2], home.p[3] }, false, true)
      hovered.setRotation({ home.r[1], home.r[2], home.r[3] })
    end)
  end
  -- 5. otherwise nothing, and nothing said
end

-- NUMPAD 1 -- TAKE A WARRIOR from your own supply, at your pointer. What numpad 0 used to do when it
-- was hovering nothing; now it is its own key and does NOT care what the pointer is over.
-- Which supply is yours comes from where you are SEATED, so a mis-hover cannot take somebody else's.
function rttGizmoTake(color)
  local bag, why = rttMySupplyBag(color)
  if bag == nil then
    broadcastToColor("Gizmo: " .. (why or "could not tell which supply is yours."), color,
                     { r = 1, g = 0.6, b = 0.2 })
    return
  end
  local n = 0
  pcall(function() n = bag.getQuantity() end)
  if n <= 0 then
    broadcastToColor("Gizmo: the supply is empty.", color, { r = 1, g = 0.6, b = 0.2 })
    return
  end
  local pos = nil
  pcall(function() pos = Player[color].getPointerPosition() end)
  local bp = bag.getPosition()
  if pos == nil then pos = { x = bp.x, y = bp.y + 2, z = bp.z }
  else pos = { x = pos.x, y = pos.y + 1.5, z = pos.z } end
  -- Stand it up. takeObject otherwise keeps whatever pose the piece had inside the bag, and the
  -- blueprints show plenty lying over. Fast, but still visibly from the supply: pop out AT THE BAG,
  -- then a fast smooth move to the pointer (takeObject has no speed control; setPositionSmooth does).
  local ry = 0
  pcall(function() ry = bag.getRotation().y or 0 end)
  pcall(function()
    bag.takeObject({
      position = { bp.x, bp.y + 1.2, bp.z }, rotation = { 0, ry, 0 }, smooth = false,
      callback_function = function(o)
        pcall(function() o.addTag("RTT Faction") end)
        pcall(function() o.setPositionSmooth(pos, false, true) end)
      end
    })
  end)
end

-- NUMPAD 2 -- LAY A WARRIOR DOWN. Maintainer, 2026-09-07: "pressing numpad 2 should put a warrior
-- laying down; change the color of the warrior cream white ... and lock it. repressing numpad 2 undoes
-- all of that."
--
-- ANY warrior, not only your own -- he was asked and said so plainly, unlike numpad 0 a line above.
-- Warriors only: a building or a token is not laid down, and hovering one does nothing.
--
-- Undo restores what the piece actually looked like, not a guess. Every faction's warrior carries its
-- own tint -- the Eyrie's is blue, the rats' red, and the Corvids, Keepers and Knaves are plain white
-- because their colour is in the texture -- so "put it back to white" would repaint half the mod. The
-- pose and tint are recorded on the way down and handed back on the way up, and the record rides in
-- onSave, so a reload in the middle of a game does not strand a warrior cream and locked.
-- A DISC UNDER THE PIECE, NOT A REPAINT. Laying a warrior down used to turn it cream, which loses the
-- faction's own colour and reads as damage to the piece -- the maintainer, 2026-09-07: "instead of
-- changing the color of the piece have a small circly be drawn under the piece, a little bit
-- transparent, and of the color of the player doing it". So the warrior keeps its own paint and the
-- marker says WHO laid it down, which the tint never could.
RTT_DISC_URL = "https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/disc_89666e66.png"
RTT_DISC_TAG = "RTT Laid Disc"
RTT_DISC_A   = 0.42            -- "a little bit more transparent" (was 0.55)
-- TTS's own player colours. Read from a table rather than Color.fromString so the answer is the same
-- in the harness as at the table, and so a colour TTS does not know cannot throw mid-press.
RTT_PLAYER_RGB = {
  White  = { 1, 1, 1 },              Brown  = { 0.443, 0.231, 0.09 },
  Red    = { 0.856, 0.1, 0.094 },    Orange = { 0.956, 0.392, 0.113 },
  Yellow = { 0.905, 0.898, 0.172 },  Green  = { 0.192, 0.701, 0.168 },
  Teal   = { 0.129, 0.694, 0.607 },  Blue   = { 0.118, 0.53, 1 },
  Purple = { 0.627, 0.125, 0.941 },  Pink   = { 0.96, 0.439, 0.807 },
  Grey   = { 0.5, 0.5, 0.5 },        Black  = { 0.25, 0.25, 0.25 },
}
RTT_LAID = {}      -- [guid] = { rot = {x,y,z}, pos = {x,y,z}, disc = <guid> } as it stood before the key

-- Is this piece down? The RECORD says so, and the record is in onSave, so it survives a reload. The
-- tint used to be the answer; it cannot be any more, because the piece keeps its own colour now.
function rttIsLaid(o)
  if o == nil then return false end
  local guid = nil
  pcall(function() guid = o.getGUID() end)
  return guid ~= nil and RTT_LAID[guid] ~= nil
end

-- The presser's colour as an r,g,b table, for whichever mark they used.
function rttMarkColor(color)
  local rgb = RTT_PLAYER_RGB[color] or { 1, 1, 1 }
  return { r = rgb[1], g = rgb[2], b = rgb[3] }
end

-- the disc: a thin circle on the board under the piece, in the presser's colour
function rttSpawnLaidDisc(color, x, y, z, d, onSpawned)
  local rgb = RTT_PLAYER_RGB[color] or { 1, 1, 1 }
  spawnObjectJSON({
    json = string.format(
      '{"Name":"Custom_Tile","Transform":{"posX":0,"posY":0,"posZ":0,"rotX":0,"rotY":0,"rotZ":0,'
      .. '"scaleX":%f,"scaleY":1.0,"scaleZ":%f},"Nickname":"","Locked":true,"Grid":false,'
      .. '"Snap":false,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":false,'
      .. '"Autoraise":false,"Sticky":false,"Tooltip":false,"GridProjection":false,'
      .. '"ColorDiffuse":{"r":%f,"g":%f,"b":%f,"a":%f},'
      .. '"CustomImage":{"ImageURL":"%s","ImageSecondaryURL":"","ImageScalar":1.0,"WidthScale":1.0,'
      .. '"CustomTile":{"Type":2,"Thickness":0.02,"Stackable":false,"Stretch":true}}}',
      d, d, rgb[1], rgb[2], rgb[3], RTT_DISC_A, RTT_DISC_URL),
    position = { x, y, z },
    rotation = { 0, 0, 0 },
    callback_function = function(o)
      pcall(function()
        local t = o.getTags()
        table.insert(t, "RTT Faction")     -- goes out with the game, like the warrior above it
        table.insert(t, RTT_DISC_TAG)
        o.setTags(t)
      end)
      pcall(function() o.interactable = false end)
      pcall(function() o.setLock(true) end)
      if onSpawned ~= nil then pcall(function() onSpawned(o) end) end
    end
  })
end

-- NUMPAD 2 draws a disc under the piece; NUMPAD 3 lights the piece itself. Same action otherwise --
-- down, locked, press again to undo -- because they are two ways of saying the same thing, and the
-- maintainer asked for the second as an option: "instead of the circle it does a highlight. its an
-- option that should exists. another way to emphasiwe the piece on the map" (2026-09-07).
-- The record remembers WHICH mark was used, so standing a piece up removes the right one however you
-- put it down, and a piece marked one way is never left with the other's leftovers.
function rttGizmoLay(color) rttGizmoMark(color, "disc") end
function rttGizmoGlow(color) rttGizmoMark(color, "glow") end

function rttGizmoMark(color, mark)
  local hovered = nil
  pcall(function() hovered = Player[color].getHoverObject() end)
  if hovered == nil then return end
  local name = hovered.getName() or ""
  if not name:match("Warrior$") then return end        -- warriors only, silently

  local guid = nil
  pcall(function() guid = hovered.getGUID() end)
  if guid == nil then return end

  if rttIsLaid(hovered) then                            -- second press: stand it back up
    local was = RTT_LAID[guid]
    RTT_LAID[guid] = nil
    pcall(function() hovered.setLock(false) end)
    pcall(function()
      local ry = hovered.getRotation().y
      hovered.setRotation({ was.rot[1], ry, was.rot[3] })
      if was.pos ~= nil then hovered.setPosition({ was.pos[1], was.pos[2], was.pos[3] }) end
    end)
    -- the disc goes with it, by GUID rather than by proximity, so two laid warriors side by side
    -- cannot take each other's marker away
    if was.disc ~= nil then
      pcall(function()
        local o = getObjectFromGUID(was.disc)
        if o ~= nil then o.destruct() end
      end)
    end
    if was.mark == "glow" then pcall(function() hovered.highlightOff() end) end
    return
  end

  local r, p, b = nil, nil, nil
  pcall(function() r = hovered.getRotation() end)
  pcall(function() p = hovered.getPosition() end)
  pcall(function() b = hovered.getBounds() end)
  if r == nil or p == nil then return end
  -- WHERE THE PIECE IS STANDING. A warrior tipped over keeps its position, and a position is the
  -- middle of a piece that was upright -- so it ends up lying in the air above the board, which is
  -- what the maintainer saw: "the warrior needs to be laying down and locked on the board now it s
  -- in the air". Record the height its FOOT is at, and put the foot back there once it is flat.
  local foot, wide = nil, 1.2
  if b ~= nil and b.center ~= nil and b.size ~= nil then
    foot = b.center.y - b.size.y / 2
    wide = math.max(b.size.x, b.size.z) * 1.275   -- 15% smaller than the 1.5 it shipped at
  end
  -- THE MARK KEEPS THE COLOUR IT WAS MADE IN. It followed the person for one build, so a colour change
  -- redrew every disc they had put down -- which in hotseat, where one person holds every colour, moved
  -- all of them at once. Maintainer, 2026-09-07: pin it "at the moment of the press".
  RTT_LAID[guid] = { rot = { r.x, r.y, r.z }, pos = { p.x, p.y, p.z }, disc = nil,
                     who = color, mark = mark or "disc" }
  pcall(function() hovered.setRotation({ 90, r.y, r.z }) end)   -- tips forward, away from the player
  -- The bounds only report the new shape once TTS has applied the rotation, so the drop and the lock
  -- wait a frame. Locking before that is what pinned it mid-air.
  Wait.frames(function()
    local rest = nil
    pcall(function()
      local np = hovered.getPosition()
      rest = np.y
      if foot ~= nil then
        local nb = hovered.getBounds()
        -- a hair above the foot, so the disc reads as being UNDER the piece rather than fighting it
        rest = np.y + (foot - (nb.center.y - nb.size.y / 2)) + 0.03
        hovered.setPosition({ np.x, rest, np.z })
      end
    end)
    pcall(function() hovered.setLock(true) end)
    if mark == "glow" then
      -- no duration: it stays lit until the piece is stood back up, which is the whole point
      pcall(function() hovered.highlightOn(rttMarkColor(color)) end)
    elseif foot ~= nil then
      pcall(function()
        local np = hovered.getPosition()
        rttSpawnLaidDisc(color, np.x, foot + 0.01, np.z, wide, function(o)
          if RTT_LAID[guid] ~= nil then RTT_LAID[guid].disc = o.getGUID() end
        end)
      end)
    end
  end, 2)
end

-- kept as the old name so nothing that calls it breaks; it is the TAKE half.
function rttGizmoWarrior(color) rttGizmoTake(color) end

function onScriptingButtonDown(idx, color)
  if     idx == 10 then pcall(function() rttGizmoHome(color) end)   -- numpad 0: send home
  elseif idx == 1  then pcall(function() rttGizmoTake(color) end)   -- numpad 1: take a warrior
  elseif idx == 2  then pcall(function() rttGizmoLay(color) end)    -- numpad 2: lay it down, disc
  elseif idx == 3  then pcall(function() rttGizmoGlow(color) end)   -- numpad 3: lay it down, glow
  end
end


