function onLoad(state)
  pcall(function() rttSnapshotHand2() end)  -- parked hand-2 transforms, restored on every new game
  pcall(function() rttGizmoLoad(state or "") end)   -- gizmo config; needs no object
  -- The gizmo answers TTS SCRIPTING BUTTONS, which are bound to the NUMPAD by default -- and a
  -- MacBook has no numpad (maintainer, 2026-09-04: on a French Mac layout the top-row 0 needs
  -- Shift and never reaches the gizmo). These two named hotkeys do the same two jobs and can be
  -- bound to ANY key in Options - Game Keys, so the gizmo is reachable on a laptop keyboard.
  pcall(function()
    addHotkey("Gizmo: return hovered piece to supply", function(color) onScriptingButtonDown(10, color) end)
    addHotkey("Gizmo: set supply / destination",       function(color) onScriptingButtonDown(1,  color) end)
  end)
  assets = {}
  if self.getName() != "Faction Board" then
    assets = {

        {name = "ThemeArt", url = "https://steamusercontent-a.akamaihd.net/ugc/16316853328531788856/FE0894D6BBC40E7876FE4A683368A61FC1B35547/"},
        {name = "RankedArt", url = "https://steamusercontent-a.akamaihd.net/ugc/17736006513028835727/23F7EB2248073953C65D1AAD44636708E9E2DFE1/"},
        {name = "FivePlayerArt", url = "https://steamusercontent-a.akamaihd.net/ugc/10646501209524696434/622AC9B1FA1D4C6B239DF99C896C07640F449574/"},
        {name = "WWDraftTool", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809540303472326/2081F779AB2B2A6FA9D15696F6920FE2067BC4C6/"},

        {name = "WWMapAndDeckLabel", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758457073/089EBACF82C9F5F6A57DE99BC4B039C26025C7DE/"},
        {name = "WWDeckPlus", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798762847395/53113D7B4CA59080584242196F2EA48B3FCA8D6E/"},
        {name = "WWFactionLabel", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758458688/3E0EB033B013FBF8DC17AB401A9CFC0C042C478B/"},
        {name = "WW1Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758602160/9AAC237742D5737D3BE4B82B05EA1068F5D48BA3/"},
        {name = "WW2Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758604829/DEE763FEACB81AA6A9B985EB633F1C08E55A51D7/"},
        {name = "WW3Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758605739/B59B238873159994857BB1B76264F05A5EA8F752/"},
        {name = "WW4Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758606547/AAF86B0FCA4C757CC8AACDE731C1708ADA40BA77/"},
        {name = "WW5Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758607233/A1B8CBA9BC61EFFF8FAA38FB9D519205E2C1CB7F/"},
        {name = "WW6Turn", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758607829/2975F869B1C9244D5B81BF05ED14466D65738C5F/"},

        {name = "WWExit", url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391476521209/314B380DED440A1EA71186A6E99FB3C59402C3C4/"},
        {name = "WWAreYouSure", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948805514871/4912582E0454C46654010394CDE4437FC873BB7B/"},
        {name = "WWForReal", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948805515438/3D111DD6A136933815806FBAA641A241F6852B11/"},
        {name = "WWReally", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948805515962/8A00A6741876FB854953900056B68F69953CEC43/"},
        {name = "WWYaChicken", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948805516454/B21AFB4D0FEF08B2B2E95DD1BE244BF7174007C5/"},

        {name = "WWSelectFaction", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758740795/3FB9174F6DAEDA6A39FA754A8158379865001AF7/"},
        {name = "WWSetupFaction", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758847572/52A3F4A7974F05A7A7696D4D0AED8F1545AA1834/"},
        {name = "WWDraftHands", url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798762823019/8F1F0B8448A78CEEB9D825F3680DFAE7F27A8172/"},

        {name = "WWBanner", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401538180590/45D17C1F9442D6215F3BB6C548CD07164E72991A/"},
        {name = "WWWarning",url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401538181099/B8139CFC01F8293E948DD07EDB9A86A7167E8AF8/"},
        {name = "WWWarning2",url = "https://steamusercontent-a.akamaihd.net/ugc/1862809798758614860/CFB938DF75CE98ADBD04EAEA77262474339F9829/"},
        {name = "WWWarning3",url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948809580211/1B23ADFB88AC5B28B87EAC9CEE094DE165CD9F2F/"},
        {name = "WWLeftMenu1", url="https://steamusercontent-a.akamaihd.net/ugc/1861696999739467549/E173D7232282E89F95CD5BD5212191AE2006434E/"},
        {name = "WWJoin", url="https://steamusercontent-a.akamaihd.net/ugc/1857179401538293879/330B576B2DD6F0795FC4CC02BD206FBA46F3697C/"},
        {name = "WWLeave", url="https://steamusercontent-a.akamaihd.net/ugc/1857179401538295235/5939B90F793DDBA86097052BE14FFFCDE58A32EE/"},
        {name = "WWCheckRoster", url="https://steamusercontent-a.akamaihd.net/ugc/1857179401538296267/EB0B3938A6F213DA0C18B0023478C1F8B95E2665/"},
        {name = "WWDone", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401538297317/C5B575BB0049489877DE5C13E071B5C95EA321C4/"},
        {name = "WW5050Ticket", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401541152150/F7AF1F3347F9DC8A055AA6E3F1BEA24E1BA5F709/"},
        {name = "WWHomebrewTicket", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401541897237/C2FB1A75D08974B34BB847F093C653B807CAB601/"},
        {name = "WWOfficialTicket", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401541899191/538766C95C53DF455C08AC20B80E9F10E9A9123A/"},

        {name = "WWLeftMenuSit", url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739462797/DD836A4FFCD21D0B8721B3C68437AAD79D5901FA/"},
        {name = "WWLeftMenuDot1", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433104053138769/0234EA080C02276650E4C047777DE044DD7AE3F8/"},
        {name = "WWLeftMenuDot2", url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739471432/6B0D0B26362825EE9846EA4F29CB72D4967CD662/"},
        {name = "WWLeftMenuDot3", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433104053140385/36A0512FAE850FE6CAF048CA3EF3F9282454E83F/"},
        {name = "WWLeftMenuFaction", url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739480088/5D023427404A0E3F7E81C7C1BCE1CF0A23691BBF/"},
        {name = "WWLeftMenuCards", url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739486161/9618E6DE2DA9392A6BFF61479302CE313B18A5A8/"},

        {name = "Marquise de Cat Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550009864/6E9B0A804DA5A91ECC0535F0392F4A34F24E06AE/"},
        {name = "Eyrie Dynasties Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550009319/049E94CDBFA5B150C865E01EA320220A326F331F/"},
        {name = "Woodland Alliance Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550001585/23C5DBFF72D7A03DA456759B0A36EB8CEF02A788/"},
        --{name = "VagabondIcon", url = ""},
        {name = "Adventurer Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550015803/48DC9EF391BC6B006E69BBCA8CEAFD4E67EAA4AC/"},
        {name = "Arbiter Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550016508/A471B257858AC918D854ABB36F5034AB1D195E0A/"},
        {name = "Harrier Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550017049/C332A30388CBC4A7E4C2AC2AF2EE54F6547AB756/"},
        {name = "Ranger Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550017564/2B6C5175DE1339B4449F57C906601B3EFA2E51B6/"},
        {name = "Ronin Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550018161/1D55A3293DB2F65D81FE227F901DA843130FA1CC/"},
        {name = "Scoundrel Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550018814/71CD81FEFBC311429C2C20616A7F62ADF68B02F6/"},
        {name = "Thief Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550019508/60F0E1E2F722EA3F26D3AE6CAB442C967C0F6DD7/"},
        {name = "Tinker Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550020017/C77584E4A6B380FD43840689FAA10C220E239156/"},
        {name = "Vagrant Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550020620/6BA52746C00824954AB919C156DC5EBC9B95CA7B/"},

        {name = "The Lizard Cult Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550007094/FAEE39697FC835E29610B861A4808C369FD06F85/"},
        {name = "Riverfolk Company Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550007733/624734933939460FB93EDC1E87661B7B0FD8BC17/"},
        {name = "Underground Duchy Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550010408/691D89719FEBDFBEF34B6D587EEDD591158B5BD9/"},
        {name = "Corvid Conspiracy Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550005663/F564BBDB4F798CF275D2C2AB4CE6456C869E8B5B/"},
        {name = "Lord of the Hundreds Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550011183/3723DA81DFFA11C6491D382E8101C9876BF352BF/"},
        {name = "Keepers in Iron Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550008429/895B9C8C8EB927DD1E515CB857F48A7C6730E036/"},

        {name = "Eyrie's End Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739457258/1A2351BCC8618DD1A9DF4C188A41C69A810E5BBF/"},
        {name = "Old Man Tinker Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550088526/8CA3A5C47E9B31A7F0B047846FCB65DB819B372F/"},
        {name = "Necropossums Cabal Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550087005/F56AE22AE7DB057892B518722DB8B3B2C819BD15/"},
        {name = "Dawn of the Marquistadors Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550072133/90B6CE3FB04284BA319B10ED3E8D85C604B60051/"},
        {name = "Workshop Marquise Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550080643/E5C63D11769B438FE155D49FE049C84E53925B0C/"},
        {name = "Arachnid Association II Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550081315/2EEEBE26BC6809490E0D8E54B2D4450A979BBC33/"},
        {name = "Croakers Coven Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550083528/27DD958986D8E0F977F784BC350BD18938C08A9C/"},
        {name = "The Noxious Battery Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550087819/FEE54AD3C8FD8501A24DCC61B672E21B612EE068/"},
        {name = "Bone Patrol Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550082699/9C394B84046A2A70F5D37CA5D8179274600224F7/"},
        {name = "Warriors Wake Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550076797/6E3E7DF36FBB1051DC6EA677C258E759576A6C03/"},

        {name = "Black Creek Pirates II Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550081971/FABC194CCAA0668987844114BC008A601704C4E3/"},
        {name = "Spinners of Mercy Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1920249469919849760/D2CF1773DD8589DCD09911AF0EA349324847B62F/"},
        {name = "The Winged Menace Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550085845/8C04BDDA697D7A2DE10F3D9E51FDADA7E081A21E/"},
        {name = "Woodland Revolution Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550089807/1EE10AF49AAD3962E9AAFB9B1E8813D2778CD079/"},
        {name = "United Dove Corps II Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550084912/1A39068A8FC659E440E87A32CFDA34A756CF9C29/"},
        {name = "Doomed Swindler Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550094665/F0363557F7D207986118F40C67D8E15B8D35A258/"},
        {name = "Grouch Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550094063/5B82F97B82D8C5532BABB7BEE9E53FA4A2E01375/"},
        {name = "Doomed Berserker Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550092503/A52FA339323BD25DE4B44AA03B861CA2EB6E9A9D/"},
        {name = "Doomed Bard Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1920249469919844619/ADF458CBDE9BE820DDEA64E2BB95B44B15205A2E/"},
        {name = "Doomed Blacksmith Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550093176/D9423ADE626A5038B11B9774EEEC23F4CD0A2826/"},
        {name = "Doomed Zealot Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550095449/3C52155CEE9AD2DA8D5B9E92B59A347ECCDB1C40/"},
        {name = "Doomed Barkeep Icon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401550091785/51839FE6ACD4BB803CF8B6F2CF82F35BE5C078BA/"},

        {name = "AutumnMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545559145/2195AD666798BBCB915DA39317949235295E82A7/"},
        {name = "WinterMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545566679/C3EB10215C5917643F5A98406D83EF3FF8EC974A/"},
        {name = "LakeMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545567379/E6023DB1078C0853ECC52AF6B2B290CE0E0F143E/"},
        {name = "MountainMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545562698/D662D39270730E70041FBD5F625258858AF18B67/"},

        {name = "The WastelandsMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545573259/8A8E4C8418B82E176D4607359D147FCDB49EE32A/"},
        {name = "Treasure IslandMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545574508/7DD827948F2AA06F03010B84CBEB29A242184D28/"},
        {name = "SummerMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545571231/D22D076DC9147535B9C9F31AD072C9108D3ABD47/"},
        {name = "LegendsMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545577556/F7AF1ED713481A3AE0DFBA1DBDE4DD8BD87E5950/"},
        {name = "GorgeMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545578515/DB4342B9BAA27D31ECC43EDFD348D547E4E51DAF/"},
        {name = "The Deep WoodsMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545579387/6B0D4B1D705223FE94DD9CF0D81870BF00575DC0/"},
        {name = "AustraliaMapIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545580292/DBEF949234DAF2857DE18B172ED45B8FC6307242/"},

        {name = "StandardDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545826011/4080587C766BB40FE5FDA3A4421A2382D9C07C79/"},
        {name = "Exiles and PartisansDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545826716/4E6FCAC53A99A571397113355569F01B28C33AD6/"},

        {name = "Action! Deck BoosterDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545831943/88FEA9D84DBD567A598C157CF753C14C5A61299C/"},
        {name = "DarkDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545831177/067E483842521EE487CEB01133DE9CE161B5F92E/"},
        {name = "60 Card MasterDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545830431/51A86BB9F8461512C24296C373DB53020214B414/"},
        {name = "Sorcery of the Enchanted WoodsDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545829283/25349508CF3204557D862AE7D016D39512B16877/"},
        {name = "Upstarts and RenegadesDeckIcon", url = "https://steamusercontent-a.akamaihd.net/ugc/1857179401545827523/4F032CC45504B87FBB2B64C9AF5E4E6CDFBE2FCD/"},

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

        {name = "Mechanical Marquise",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721131861/8DFCF422BF000F0D33F310771EC480209A1B2FB9/"},
        {name = "Electric Eyrie",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721129634/D808C0E7B301109F6DD575FF1490D6D87F6B8BC2/"},
        {name = "Automated Alliance",url = "https://steamusercontent-a.akamaihd.net/ugc/1861696999739432560/60BCFCAE3B311E5E8F1D5CB3501DE3866A7078EC/"},
        {name = "Vagabot",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416468779735395/C04D04E37CA20214E51DE0D29F25D9BEF5313301/"},
        {name = "Logical Lizards",url = "https://steamusercontent-a.akamaihd.net/ugc/1862805096112811713/49271C38EF97345F1771945C9889135873EAC47A/"},
        {name = "Riverfolk Robots",url = "https://steamusercontent-a.akamaihd.net/ugc/1862805096112812454/BD1ED64CA5FF7AB5A14CE0930BD8E18BEFE0305D/"},
        {name = "Drillbit Duchy",url = "https://steamusercontent-a.akamaihd.net/ugc/1862805096112813105/3DE8DFDA735083A2204632BB173EC4A9EF6F9ED9/"},
        {name = "Cogwheel Corvids",url = "https://steamusercontent-a.akamaihd.net/ugc/1862805096112813648/AAA583B6C664FBC673DFC00288CEE08C4D0CC465/"},

        {name = "Orange Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721123069/559A9AE0710087A6BBCC7222757960C83086EFA2/"},
        {name = "Blue Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721133627/ECD52C5CD057AB195970E9C4A65A3F32D48B436C/"},
        {name = "Green Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721121814/F441AAAA2A5048397E1685E324C87A4BB946B5B7/"},
        {name = "Gray Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416468779734881/4BCBD5DF5F7927EB2374776760DF37AF8F19A712/"},
        {name = "Yellow Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721123899/6AF30E9F551002970DB6F4FB5EEB7BCD65B31F17/"},
        {name = "Teal Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721125696/027507215C8F16B4E56BAAF7217012CFDB9DAB78/"},
        {name = "Brown Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416468779643667/7F9A4BA198E699336EDB20FCB3BB859716ACF2BC/"},
        {name = "Purple Meeple",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721146053/AB0C714CC7C938FF7B195A912D00D1149C4816F7/"},

        {name = "Corvid Interaction",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391475639768/27AE75B717985F9076DA10B9EE1BB03C4D9C2110/"},
        {name = "Riverfolk Interaction", url = "https://steamusercontent-a.akamaihd.net/ugc/1862805096113038687/C70605DF61D6855C6D8F350B0881D1C8CC284A36/"},

        {name = "Law of Robotics",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402719829914/4AF4CF62BEB439F9C672F2AAFA8C69EF53F8D83F/"},
        {name = "Better Bot Project Manual",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402719831731/6BF906A19B74952DC184CCBD35698E64F2070250/"},

        {name = "Bristling Brigade",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291752819250/E32A3794A37003D5533A598DDAA273F1DE4B1F1B/"},
        {name = "Farmlands Cooperative",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755371057/D571CBDEFED60B1BF42D7D065CC648F91F40468A/"},
        {name = "Fangus Khan",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130803332/E81932701AFF7E192093ECB0C0BA5646591C54B5/"},

        {name = "The Voracious Wyrm",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302166140473/D542A3C6EC16C45F11E4DB7B4E89B8E35F864167/"},
        {name = "The Noxious Battery",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302166144247/F28FED589189A2A0EFFF6586F9A83E34840FC439/"},
        {name = "Rockin' Robin",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130941006/435DD0C59C2EE2B396113A8D70E2998DC3A70FC7/"},
        {name = "Red Guard",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754385033/4889F99696960F1E40307210CE157C8F92B6162B/"},

        {name = "Black Creek Pirates",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754407173/8AE59004E86A18683681D2677C685D8C84B00E78/"},
        {name = "Workshop Marquise",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754408441/8EB77D6898CC9B9787C1C07870405CFAE0101509/"},
        {name = "Boarish Hoards",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754413659/E3E248FEC484C98C1180875D58D581D796C4AC8B/"},
        {name = "The Weekly Croak",url = "https://steamusercontent-a.akamaihd.net/ugc/1920249469919853693/93C5E539E5A02195D6C53032364390E20D6FA0F8/"},
        {name = "Spinners of Mercy",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754416260/AE57D54645432C8981422F9051666710651D0A7B/"},
        {name = "Arachnid Association",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754417443/B754FCCED4E254960BE764B064689FC9A5DC63BA/"},
        {name = "Arachnid Association II",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526446511/9AE39070D94704577D502A7272E2C2BBA280EEB0/"},
        {name = "Frosty Theocracy",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754418318/D0DC3EE0EE36563ABDCB26304AD2007CB5614995/"},
        {name = "Nocturnal Battalion",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754420021/99C8DA982CACE2CFD5C89B4FBEF9F2BB6B2E3EE1/"},
        {name = "Necropossums Cabal",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754421552/0ECC6133A89142CFD3BB9C8DCE77DD80B42DAEFF/"},
        {name = "Nomads of the Great Shell",url = "https://steamusercontent-a.akamaihd.net/ugc/1782839567653161783/2C982EB15D1B4E75247D015A9FC62BD106D356D8/"},

        {name = "The Shoreline Consortium",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416468780453986/961367964158C9E70428C8D060426B4E737689DD/"},
        {name = "The Great Aviators",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754424723/4EE841E28962FE10FFA399E2A8A2EAC0AAD693B4/"},
        {name = "The Wolf Pack",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754425599/73ED0E6AB92CD8D66E64047416AF703A6E7D8F8C/"},
        {name = "The Dark Forest",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754426330/C47ACE492461CB59DBF070B623911FCC159C273A/"},
        {name = "Temple Guard",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755375118/FE7BA21B53190482411E070D3585006DB1867FEE/"},
        {name = "Bad Skunk-pany",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754427899/5B13ACC3AB84A674FED340194EB0DD674D1B739D/"},
        {name = "United Dove Corps",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754429271/C57C13B0F3F728DD0D45B09F7FB280173116DEDD/"},
        {name = "United Dove Corps II",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320725210985400/313DDA3DC787AD1250E67BEB6D15C9CC521F0CA2/"},
        {name = "Ragoon",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291754430392/DB23332FE6CE88B19C00FCCAB81CD46C979092DB/"},
        {name = "The Canine Republic",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130971425/0DA397272C3C474980982593BDD684D935E7058D/"},
        {name = "The Shrewd Tribe",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291752822407/199392757C63C1535CE284B78CE28A75333C6578/"},

        {name = "The Law of Slug",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130778170/778A62D63760B4120D313DC353057CA33D462093/"},
        {name = "Grouch",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130982247/6DA4C7DB07CDE7A8816778BC17EB204D82525DBD/"},
        {name = "Bone Patrol",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130783070/891450842D245D61990A8B72A20DE9845CE8BF28/"},
        {name = "The Winged Menace",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130772512/5224E0C4368F481102D897EEBF414FA3C2D45028/"},
        {name = "Order of the Forest",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130780575/3571EAA5DD49A1F6180B2ECFC363A8DE0826E757/"},
        {name = "Croakers Coven",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130781664/CFA0D3E4F26C6801C757C3353FE5DC5A41DC3464/"},
        {name = "The Twelve Colonies",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130775406/36C0A03A168EF8AA32A4B75F9A8231364ADE93D9/"},
        {name = "Old Man Tinker",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793269130777020/80BF4930BB27FA1E2A7A239C0A7974063F5C2525/"},

        {name = "Woodland Guard",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755376126/8E5CFE7BBE1D87B21224375BBB9B9C7DD52ED034/"},
        {name = "Plague Doctors",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755374026/19E1D6C35762F91D9A66134E1F0CE671C2B8031C/"},
        {name = "The Eagle King's Court",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755372779/BE97463BFFB9D4C56EB0968A185E21D4D2F74E3D/"},

        {name = "Free Leaders of the Nest",url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949888466739/66D17CAC9116C759D2FE588D6963989D6E785563/"},
        {name = "Pig Troupe",url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949888467800/0FCE7164746B7954293848C89BEC70E398BD26FB/"},
        {name = "Invasion of the Tinklones",url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949888468626/B6D0B7FA8F8A64A176591B1834C6DC3781F28B6D/"},
        {name = "Upstart Packaging Service",url = "https://steamusercontent-a.akamaihd.net/ugc/1699529762863976318/137CC24C34978AB167383775ECC1547865D9C983/"},
        {name = "Rootjam 21", url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949886637620/D529CBE526DFF8D09732A90DC3B0F7D3AAC49D40/"},

        {name = "Dawn of the Marquistadors",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422718057/A8AAC9571CC9982B09392B55E9E751BE319BEA8B/"},
        {name = "Eyrie's End",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422738170/CF032C0C50839D92BE2F0A4A2FFACB24C5C3F005/"},
        {name = "Sagacious Scholars", url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422828679/61E18C178357D1182081FEC391C7F401C5A71905/"},
        {name = "The Pond Confederation", url = "https://steamusercontent-a.akamaihd.net/ugc/1696154635652941741/8FAA95E49E7654066B0F168D831426E73393B3B6/"},
        {name = "The North Clan", url = "https://steamusercontent-a.akamaihd.net/ugc/1696154635652943373/704AEA3C771A3F43A61653C49450D7D745E55805/"},

        {name = "Advanced Setup",url = "https://steamusercontent-a.akamaihd.net/ugc/1833522185814719458/237945A7E3C9DE1967AE096BD09BE1F7829476C0/"},
        {name = "Draft Tool",url = "https://steamusercontent-a.akamaihd.net/ugc/1859434258001794538/FC3DA4C98C6DC090A9D3890825B1BA17B39F06FA/"},
        {name = "Law of Root",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402719828856/442D99DF43D27564672F46E7B94389838E77EBB7/"},
        {name = "Learning to Play",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402719826329/7AC0B80B54F7A8AE83E6C1A1F0014EB83926DAB0/"},
        {name = "Hirelings",url = "https://steamusercontent-a.akamaihd.net/ugc/1862809948809300312/E3C3019162AAD66652E8C4AB388D47FE777E5A9E/"},
        {name = "New Landmarks",url = "https://steamusercontent-a.akamaihd.net/ugc/2452866064852475557/7281F83E30CAB4C8A6355289C2CE6E8785B5FEF3/"},
        {name = "Landmarks",url = "https://steamusercontent-a.akamaihd.net/ugc/12936154875885790386/85439BAAE5C809A82FAF83A96E5232DFF4152DD0/"},
        {name = "Fandmarks",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402718265355/D40F5A9F58E29970DD02DE3B668CD35920F4A4C0/"},
        {name = "Faction Select",url = "https://steamusercontent-a.akamaihd.net/ugc/1858304668138699983/C44EA2A82303E48DE0BF8014D328132B2254D498/"},

        {name = "Alliance Multi-State Warriors",url="https://steamusercontent-a.akamaihd.net/ugc/16420027239828392/D9A788A1356580F7B60B7D3D8507A50CA8A88A39/"},
        {name = "Battle Mat",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872326632/BBBD16CCB2233145C130F362BD4772B701C7DF2D/"},
        {name = "Koffin Keeper",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872328873/9643C19226CC90278C43552680153DDF15418A5A/"},
        {name = "Lizard Wizard",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872331088/3CE6C8D9633EBD9DF25142BA43A97E9B35F01AE4/"},
        {name = "Mighty Multi-State Warriors",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872333367/F2534D89EE4AF2F499B16CBF80B8F265A0119C80/"},
        {name = "Mole Monger",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872336052/05940C3730A58F0B71A020D512486BB890F45550/"},
        {name = "Swol Birbs",url="https://steamusercontent-a.akamaihd.net/ugc/1725416289813279001/63A7B0C8DC0B3592F93D530B90451CBEC07547F2/"},
        {name = "Battle Dice",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872340896/F217E92D8189385816ACC9A9EA44603D49B19865/"},
        {name = "Vagabond Cards",url="https://steamusercontent-a.akamaihd.net/ugc/13747817220151181841/9A47D69E9103B9502DBED36BEA4DA6F9C70C6EB8/"},
        {name = "Mighty Multi-State Ruins",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526481079/46982BC98D7F8D610F4F2CEAE92D987F20485862/"},
        {name = "Clearing Priorities Big",url = "https://steamusercontent-a.akamaihd.net/ugc/17343862070314210598/A5AFE2885F4656D394532C9DA4E260DAEBB5D271/"},
        {name = "Clearing Priorities Small",url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932694143/EE512EC6064B68F082466AEBEA087CA38B461B28/"},
        {name = "Faction Selector Tool",url="https://steamusercontent-a.akamaihd.net/ugc/16420027251539310/A450741E43546370C6509D413D2CA3F1DABCBFAC/"},
        {name = "Mini-Mood Manager",url="https://steamusercontent-a.akamaihd.net/ugc/1782839567653163566/583C3FE604C4B4E943BD914071325274C515E9D8/"},
        {name = "Bat Bungler",url="https://steamusercontent-a.akamaihd.net/ugc/14651271115865573647/F4976C56FFA40862183EC055ED9F908FA96DC2B3/"},

        {name = "Clearing Markers",url="https://steamusercontent-a.akamaihd.net/ugc/18105714333446016542/1C77868231CEA4360B4404A43211931D57921DC0/"},
        {name = "Items",url="https://steamusercontent-a.akamaihd.net/ugc/12996382395453116197/45486599501A1D46FA13087CA986ED5521F7835C/"},

        {name = "TournamentSetup",url="https://steamusercontent-a.akamaihd.net/ugc/1692779977932700444/9D69FB04BB032F7C266BF3F561BECED1E8A28247/"},

        {name = "Trick or Treat!",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756336066/1281B7F98C739BF9989F056FD6A632D3B47C20BB/"},
        {name = "The Tavern",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756347083/0C3EA962F017F73CCAB786B6DF8ED267CFBE4F98/"},
        {name = "The Chaos Contraptions",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291756375251/8649076A0F2345DFD5FD686FFA17B40516465A8C/"},
        {name = "Haunted Woodland",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793367872320860/04630EB9DF042364C651FF659CEA9C2A5BF68614/"},
        {name = "Eyrie Leaders",url = "https://steamusercontent-a.akamaihd.net/ugc/1704036262314927549/1634051CED6CB2268AAA54AB089F9E9CA9613FCA/"},

        {name = "Magenta Marquise",url = "https://steamusercontent-a.akamaihd.net/ugc/1871805410096211175/57E337F2E78C96BEA1B4ABD61D37CCBFC01A044F/"},
        {name = "Brown Birds",url="https://steamusercontent-a.akamaihd.net/ugc/1871805410096212710/E0B54F274CC0D03F687825059F5CAE06D0A0AA54/"},

        {name = "Riverfolk Markers", url = "https://steamusercontent-a.akamaihd.net/ugc/1704036262312748289/AB402F0842EE5E2CF9A2A4C591DB55A5EA03BA60/"},

        {name = "Autumn Map",url = "https://steamusercontent-a.akamaihd.net/ugc/9338841708247799860/688C6CB9F5A34B2A2B067C6DA493AD653B7D9C6A/"},
        {name = "Winter Map",url = "https://steamusercontent-a.akamaihd.net/ugc/12863190738702993416/F9C676622A48D6E15BB3AE235E26CE7BC8D11283/"},
        {name = "Lake Map",url = "https://steamusercontent-a.akamaihd.net/ugc/11224158918879846636/C034E1855CED11FD28D76E3020D629478FABD195/"},
        {name = "Mountain Map",url = "https://steamusercontent-a.akamaihd.net/ugc/17146621840035729417/55256EFBD832F89B16ADAF98A382D4BF09162487/"},
        {name = "Marsh Map",url = "https://steamusercontent-a.akamaihd.net/ugc/12189840401890527004/1A5500DF801E01874A28C059E04D049043948426/"},

        {name = "Summer Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224423110603/C3BC80DD5A0F72966665CAC14BECEEED1B02A692/"},
        {name = "Legends Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1871805410099132277/153EB97C3CCEC3B2AC8076C8DDC724F8E1165163/"},

        {name = "Gorge Map",url = "https://steamusercontent-a.akamaihd.net/ugc/17163206417596942920/65DEC204EF54C27F6BAFE8202D3AE63F73D28DD3/"},
        {name = "Gorge Original Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16433884666653740/C1766FAF41F0433D369D2181F92C7941B5D6C929/"},
        
        {name = "Treasure Island Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755436567/7A21720DB922FA3A0B05F0FF0E9FB0A4619D7D0A/"},
        {name = "Deep Woods Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755429411/8C1C77B62B18F620F24053812DC4B32DAE8FD86D/"},
        {name = "Wastelands Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755559172/F8B13B88C817D4BC1C4262DB09E109F84484148A/"},
        {name = "Australia Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755441446/16318E30B063A6E439E08728EAFF4963E7A17277/"},
        {name = "Narrows and Islets Map", url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755465538/44001F9D0FA1F134FE63DE2720B367CF00F17D24/"},
        {name = "Tropics Map", url = "https://steamusercontent-a.akamaihd.net/ugc/1782840088903024368/D45A2DD6DA43C27CAA47C56305C8E1B0A053F881/"},
        {name = "Tunnel Unraveled Map",url = "https://steamusercontent-a.akamaihd.net/ugc/1782840088903031238/69C85739BFF03016086DEBE20D49D6DE60314E20/"},

        {name = "River Town Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161232742/A4D7217C4526E93BB851080B0804F1C22BDC6A34/"},
        {name = "Mountainside Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161240148/A070DD5DCA35CA4A0C712934079FA5F0996A1044/"},
        {name = "Tidal Flats Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161036555/CC02B14ADD3A4C25950B866B0931551D334541FC/"},
        {name = "Blighted City Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161005481/0D14C349BE0ECF10D83DD948ECC46FF2A8E89CB7/"},
        {name = "Taiga Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161030312/C82A0C235A5FCD839E5242FD40FFB2654CBE1032/"},
        {name = "Gloom Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161032587/58BC5A336F1A3149766B9538B409D089BA172FBC/"},
        {name = "Klacar's Volcano Island Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16423272750590320/FA1BF0F9298AA3E23156A5F1B47153D81324B3F3/"},
        {name = "Spaceballs Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16429450331909207/2A1EBD3531ED5024A04E88ACF39A579FE5879EAC/"},
        {name = "Inferno Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16429450331983247/B0CB31F2A58C84985465986BE4ACD4073F310538/"},
        {name = "Blighted Grove Map",url = "https://steamusercontent-a.akamaihd.net/ugc/16430283484922818/2C537178499FF02869872FC4CEE2493C089026E8/"},

        {name = "Standard Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1791848789393178780/9438FC204F346D081D3E66A95BBEAC918288004A/"},
        {name = "Exiles and Partisans Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1791848789393180099/504416827060BE54A0038F2C9BCF5D5A9475367F/"},
        {name = "Squires and Disciples Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/16423108253239612/4B2CC3EBFD87C25AD92E61110CF80A5C0E461BD6/"},
        {name = "Sorcery of the Enchanted Woods Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755382878/F583CD37323A8CB18FAA1769158A70D09FA07102/"},
        {name = "Upstarts and Renegades Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755379437/7B5FD13E65EB5EEC2C15749E88A68748E1418E2A/"},
        {name = "60 Card Master Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793291755389308/494037551CA49B9B4BDE834ECBAD477A852C0EFB/"},
        {name = "Dark Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/1759199733286355061/7CC669574FB8C2836047540B51419475D35EA270/"},
        {name = "Dawn and Dusk Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161441770/32A810A7CE14B231C3D16A55CB4DE221BAC33AB8/"},

        {name = "Doomed Vagabonds",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154224422742579/AFE057743980A271EE1B308F1B2E44D23AB9E555/"},
        {name = "Hirelings Noir",url = "https://steamusercontent-a.akamaihd.net/ugc/1759199733284824390/0C20FDD76FB7E0E77833A6948C12DC931F9A0C30/"},
        {name = "Slug's Magic Bag", url = "https://steamusercontent-a.akamaihd.net/ugc/1699529762863980476/785BA878C983A54AC086E7A56D06BEC6037E6157/"},

        {name = "The Bumblebee Dominion",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154342833386558/5FD16D49B18B5465AB6B76DE94B44C5859BCE5DF/"},
        {name = "The Auspicious Augury",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154342833400459/C150BAEDD652C9DFFA64BEFB0F7AA588707997FD/"},
        {name = "Unearthed Duchy",url = "https://steamusercontent-a.akamaihd.net/ugc/1704036353781365999/9A0588E9306AB8EAA05F5E944DDD33749E10EEB9/"},

        {name = "Bots", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721084869/964BF0F573EDFD0380AD036C520F95955B27A811/"},
        {name = "Core Factions", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721086214/91112CA7A5B080B4E98EC71B0261A2687E09062E/"},
        {name = "Fan Factions", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721087204/95423490207D628D10A530AACF52998F9CC067B5/"},
        {name = "Maps and Decks", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721063731/939DF2074A31CAD355D03105EA90530671E275DE/"},
        {name = "Tools", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721070945/3B57F7CCBEDB396CEB70481769051D7CD491CAFB/"},
        {name = "Setups", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416402721072522/F96D33B2DA2FEC9AA603AFC14D63B34311F34915/"},
        {name = "Back Button",url="https://steamusercontent-a.akamaihd.net/ugc/1725416402721079676/65CDF0BE142456D54B25285390B4CCF0163B5903/"},
        {name = "More Button",url="https://steamusercontent-a.akamaihd.net/ugc/1725416402721081167/3E8A5E5A5806EE37F0C95F73AF9FC24D9F9E0AED/"},
        {name = "NextButton",url= "https://steamusercontent-a.akamaihd.net/ugc/1809859799003111170/04391B14EF07FBD13352AD45AA63DAE5EDDFD4DC/"},

        {name = "Big Back Button",url = "https://steamusercontent-a.akamaihd.net/ugc/1809859303953108083/DE8E54E2AAA576DBCFF1942FE96D79BAEF9FEF00/"},
        {name = "Big Exit Button",url = "https://steamusercontent-a.akamaihd.net/ugc/1809859303953109854/0E8E4F07F53C124137BD58D4211953DF6E3514DD/"},
        {name = "Big Random Button",url= "https://steamusercontent-a.akamaihd.net/ugc/1809859303953125137/85AEEA8FEA3B3E1E9E9695AAF5555FEAFD7A77D1/"},

        {name = "Tourn1PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932741607/D22A52DC8CED484B8BBDF2E985FABDFA3CA2A645/"},
        {name = "Tourn2PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932763041/FC23FE63411E212BA0E936B31690B9132BA58C35/"},
        {name = "Tourn3PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932763644/31EB4F30002DC7ABFD555BFDB9D9F6205FE8D2A7/"},
        {name = "Tourn4PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932764273/68CAA0AF3BC786725A575E4C6844CF1D3DFB1EAF/"},
        {name = "Tourn5PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932764728/032295901D0D70CCFF454ED48FFD0CB4BC14F95B/"},
        {name = "Tourn6PlayerButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932765525/04EFA5DB9E5D73EA1574D5739AB3EE712EAD5E5D/"},

        {name = "TournBackButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932766268/21F629C7094262B23084D723A4AA062732A0CDC1/"},
        {name = "TournCheckRosterButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932766857/A16731FA8B53847EFB65384E78C981B660FDA500/"},
        {name = "TournExitButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932767575/492ED6F9726FF88905AF6AF9DC9221A9DF39E345/"},
        {name = "TournJoinButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932768104/6738B469EA8D7AF916044D87212B8DAE9D4600B4/"},
        {name = "TournLeaveButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932768742/8602F7D800D7CD9621AB317E7EF75B1CBA609866/"},
        {name = "TournStartDraftButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932769529/E294E3BDCA6D8E5AA6BD2543191DA5CA81E25D0F/"},
        {name = "TournDraftPoolButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932770674/C3977F03EF0D5A472E49D4FF498C61E0117E0805/"},
        {name = "TournMountainButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731306410841935/F2DC34AF88DE208A2B895FAC8D1DAF22BA62741A/"},

        {name = "TournMapButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932771947/B3FF124D969ABD3F60EEF662615C3A438A2F6517/"},

        {name = "TournSideMenu1Button", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731306411064977/B7FD7E2F4BF5D07CB6DE80910A61CEB346F078A4/"},
        {name = "TournSideMenu2Button", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731306411066694/E86E658BA6796A012EE04D01B3C0DF7438F88D93/"},
        {name = "TournSideMenu3Button", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731306411067611/7AF64BEDD57C087E06BD1A8579A931381492FD78/"},
        {name = "TournSideMenu4Button", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731306411068885/5DD0AC1F3A2BFD9823720EFB1E2A27A82BFDDB25/"},
        {name = "TournTitleButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932776686/62CADED8D0C8A4F22CA85EFF72C625286A8D61D0/"},

        {name = "TournMapSelectMessage", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731543197726351/F3041972D3BB1E74F31912F30251F6B328F65898/"},
        {name = "TournFacSelectMessage", url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932773239/EF1B5CD14A27B687AF58DCCCF528742193BD79E2/"},
        {name = "TournOnceAllButton", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731624852901524/8BCA7C09432EA76145F3231F632997B8D8E25073/"},
        {name = "TournCompleteSetup", url = "https://steamusercontent-a.akamaihd.net/ugc/1629731624852894764/78AE061E5F01B984433BD4606E958F97EBE4D161/"},

        {name = "TournDoneButton",url="https://steamusercontent-a.akamaihd.net/ugc/1629731624852318441/26B77D1F7FD7F4EA25BA5E307D67AAF752AA5D43/"},
        {name = "TournDoneButtonWhite",url="https://steamusercontent-a.akamaihd.net/ugc/1629731624852319793/8E6D942B695A71A615BF1C0DE9AAF808052BA284/"},

        {name = "X Icon",url = "https://steamusercontent-a.akamaihd.net/ugc/1859433104053132366/2704A9C9AB1B047A1DC28B1B19E612B08F905940/"},

        {name = "Root Logo", url="https://steamusercontent-a.akamaihd.net/ugc/1859433104053130905/247FAE492208FF3BEFACE423A31B8D7644BA7B19/"},
        {name = "Credits",url="https://steamusercontent-a.akamaihd.net/ugc/1728793367872500988/79BC1C2E8411DCAFADF7C9B7D094F2273CC38E87/"},

        
        {name = "Ehss Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154342833457824/C8378F41BA886E94FBCD6CDC32DBEA32FE6796E8/"},
        {name = "slugfacekillah Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526371464/0DB00E235E0DA0EA7201674331D0AE7B8BCD47D1/"},
        {name = "Ehss and Slug Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1782839103935392102/0927F44D64B56538A6E2A028FF30126D6652702C/"},
        {name = "Ehss and Endgamer Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1692779977932665342/9AC806656AAED471C30FA206D84CD2E5C5E22F5F/"},
        {name = "JustinInExile Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635528179522/0F18B9473BA94C17D367FD9D79F35A0EC4D9C32E/"},
        {name = "Le Codex Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635528183632/1F52657746CCA823152BED2D9EDE275D074E6A6E/"},
        {name = "Milda Matilda Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635528228433/36B3365AA4ADDC92DD860358DC7A99F570C3C1DD/"},
        {name = "MarcustheCat Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1760320301172364599/8F6F0A03E0C90E33FE11AB9CC86ECBEF85CA9647/"},
        {name = "MarcustheCat and Supacatone Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727830262661/CC0DE39F8778AC1DEBEFBE051A51D7A7AFE51EC1/"},
        {name = "Chemical Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727830263065/CD4865518547492100E452A023BD05F802A784D8/"},
        {name = "Oranos.3408 Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727830286619/49D8A8CE4B78D19686DB4E3B0436F35DEE11B9BB/"},
        {name = "Vuorienpeikko Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727832869945/431423264320113A03A34D78D26E923E1782F306/"},
        {name = "S.P.Shaman Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727832880296/CFD0A34E8AAC66EE2E406C5F2652DA7E3699AA7E/"},
        {name = "Totgeboren Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727832881462/03A7FD1F96384B3B123C4AF7C67AB9D4506AD9DE/"},
        {name = "Esau Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793727832883476/6C3171B5D089EFA3602745BC2708B93B0AF99B50/"},
        {name = "J444 Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793799439301238/42584E05230B726880E018640DDB1D6D8BA52B9A/"},
        {name = "Nevakanezah Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793799439302485/F46D00FF0354D5F24AFCFB7FFFAC2EA4DDA28A11/"},
        {name = "Matchstick Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793799439303700/EB8E0B76EE3A6475B2033B7DC69597D9821FC6EA/"},
        {name = "MarcustheCat and Trashpanda8 Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793799439305020/FA757DED2F3A8B71389D6A295130BDC05F1ABCA4/"},
        {name = "LordOfTheBoard Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793799439331955/33C92E129FA9EB9D30B773021738391A736B120C/"},
        {name = "Creslin9 Info",url="https://steamusercontent-a.akamaihd.net/ugc/1728793822430780649/9808291C794CB564FFBCD1CDBCCA6CD4831667AF/"},
        {name = "GaborBoth and RedCheshireKate Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793822430800456/57A7EB3183970920332901DCF6BBA9144044AE3E/"},
        {name = "snowjedi6 Info",url="https://steamusercontent-a.akamaihd.net/ugc/1725416136412298173/FF2AD403F14FF46680CBF079A0A5B6ECCBA9010D/"},
        {name = "Velensk and Sid3run Info",url="https://steamusercontent-a.akamaihd.net/ugc/1725416136412299340/90CA325A0BB24342F4881C733D7A1A294E2842A8/"},
        {name = "Dewhurst Info", url ="https://steamusercontent-a.akamaihd.net/ugc/1725416136413184582/B8383703DD33F641106984A529949A781C1C15EE/"},
        {name = "kpackard Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1725416195554265462/D69A93D9FB6C499681F11642EE88F20373336304/"},
        {name = "Milda Matilda and Ehss Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1760320644483451110/1611C87B972B512E9EB0B5E882696ACCD07D32D2/"},
        {name = "Print and Play Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1782839633458571009/CBF6363D467FF60D4713CAD182E36A9DB0727B5A/"},
        {name = "Nevakanezah and Slug Info", url= "https://steamusercontent-a.akamaihd.net/ugc/1704036430908662468/83E53F32BC1C2149747AF4C5B35EDF2B1F5F4717/"},
        {name = "Original Supacatone Info", url="https://steamusercontent-a.akamaihd.net/ugc/1871809398613363241/B5FF21266CA2BCA4EDB0CAFB3419BAD7C7C73B8B/"},
        {name = "fkolouch Info", url="https://steamusercontent-a.akamaihd.net/ugc/16419302161271568/9750F9E81C3C339B7A108297BF9EA36D39051F01/"};
        {name = "Klacar Info",url = "https://steamusercontent-a.akamaihd.net/ugc/16423272750658596/A8D3FEB3736DB4D9900D34166E73FBF7110EE85D/"},

        {name = "Le Codex and Lijosu Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949886920161/1D02FAFD4A8C43AC9EC164F2AA7CDCB0380BAA50/"},
        {name = "GeneralMasterJake Info", url = "https://steamusercontent-a.akamaihd.net/ugc/1699529949886923998/AFAC8B0A8C50B71BA1E227434D0B198C103695A7/"},

        {name = "Norsehound Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391475275637/371429CC54867CA7064F05C5258C0E5503C9D00E/"},
        {name = "vatechman3 Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1699528634399457079/46FFE28F8E63C2B75B6CD1EE261D9DBA0FDEE069/"},
        {name = "Hierotitan and Leonatus Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1782839856362038803/D1A1331E2B11F6B9218D74DC7D7A0E7F4FE17F1E/"},
        {name = "Brooklyn Game Lab Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391475284598/BC4D2CE436CA4A24CE209DC52C6FFB31ED358B86/"},
        {name = "mine12king Info",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391475287888/242DB7A4ED993A83D5FF278EE88B8BB18259E035/"},
        {name = "adorablerocket Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1758072369107353185/7911CE2914C6DA96F3B28E141231372DE0CAA303/"},

        {name = "Azhdar and Supacatone Info",url="https://steamusercontent-a.akamaihd.net/ugc/1809859303950628984/979820A68EC7BB7CB0812856DAB8455966C21A10/"},
        {name = "Supacatone Info",url="https://steamusercontent-a.akamaihd.net/ugc/1809859303950632835/A47AA2904B4AFFE19648A9583C1AB5F872E84189/"},
        {name = "Magh and Supacatone Info",url="https://steamusercontent-a.akamaihd.net/ugc/1809859303950635072/B71340F7B3B6B8E30B491868B93CE13539463C4E/"},
        {name = "Luhnaire and Supacatone Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1809859303950636966/DD89D4857C4DB810D71F1ED80DD1ABE3548C5ED5/"},
        {name = "Tikette and Supacatone Info",url="https://steamusercontent-a.akamaihd.net/ugc/1809859303950638542/BD3C9002B06FA848A16378C5E168236F2755775A/"},
        {name = "Max Masque and Alex L'Arbe and Supacatone Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1809859303950641909/BD0B83895573607C967FA637052B486F9EDC37D8/"},
        {name = "Evan Lindeman and Magh and Supacatone Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1809859303950643011/84B0F5F2FC4ABE02610EC9DB069F0C87D123DA3D/"},
        {name = "OrigamiGoblin and Arkane Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154342833425148/BE33B9B499CCB8FB7444071B0493CCFE0808D4EE/"},
        {name = "McDougishole Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154342833429281/9378E5A5884B77B0C5FF3B4FA536C60979014ECA/"},
        {name = "Endgamer Info",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185819287693/7774219B8D50A4D4F2C9E616D14308F104490F68/"},
        {name = "RemiPipi Info",url="https://steamusercontent-a.akamaihd.net/ugc/1874056202036047917/8A54F1181C19277BFF5F99C61B33584AEA183A51/"},
        {name = "Marcus Tweak Info",url="https://steamusercontent-a.akamaihd.net/ugc/1874056202036053425/64A0BB73D3D79E9CB37C0FD70E0F8969CD10D3DA/"},

        {name = "Bdeink Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154635652923227/3213508DBB1889BE43B1B1B2B1AD36D6DC319257/"},
        {name = "Moloman Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1696154635652929772/891E44AC4C7A2CA025AAEB0F4E645171BEE4E23B/"},
        {name = "Ginso Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1862810258468082738/334D246CA9969A15F1C7A06FB6C54C65ECF316CD/"},

        {name = "Laterbot Info",url = "https://steamusercontent-a.akamaihd.net/ugc/18259687869223016796/FADAB2AEE28641D5E449CFD97C25D255214BCD69/"},

        --{name = "Inconmon Info",url="https://steamusercontent-a.akamaihd.net/ugc/1782838933582071523/D4EFF55361F7693F215FDF30E29BCB03E63FF20C/"},
        {name = "Inconmon Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1782839633458582396/169BD7654EE5AE1D88B8C8C2D6C17B31D90927F0/"},

        {name = "Tunnel Map Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635528454412/2D849386C6945557146B340A7A2E2EA9EB769D3C/"},

        {name = "Official Content Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1725416136412842797/8C16959C043FF934C5D88C583AD957EE85D4B7FE/"},
        {name = "Blank Info",url = "https://steamusercontent-a.akamaihd.net/ugc/1728793635526111266/638962CD65D3760A1FD61D0AA78EE4C496C5487E/"},

        {name = "Clockwork Expansion Tag", url="https://steamusercontent-a.akamaihd.net/ugc/1782838933579301205/7363CC92AB61C7B0BF4D93BFBC9892605BC20B80/"},
        {name = "Better Bot Project Tag",url = "https://steamusercontent-a.akamaihd.net/ugc/1782838933579299065/1BEF3249CB6CE2995650CD7B5B8B8807AEF6D0C2/"},

        {name = "Fan Tools Label", url = "https://steamusercontent-a.akamaihd.net/ugc/1782839685992682079/CCEED2B6B487D6964A435437F633C3AF3EE871F7/"},

        {name = "Scenarios Tag",url = "https://steamusercontent-a.akamaihd.net/ugc/1782838933579302036/CE6374FE0E23C9CF5497E9B67F5E6595A262FFA3/"},

        {name = "Player 0 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391476180248/5994F1680B98F561C4297AF0DD69C492A979EB2C/"},
        {name = "Player 1 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799003156760/E68BD984348439054963132BE9D1E9E708FFB08A/"},
        {name = "Player 2 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002798151/522376C833A9089E37B6E190423341DB948709AA/"},
        {name = "Player 3 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002799429/55AEE70FBD094EA29A99C1C4D1B1D12B3C43ED3A/"},
        {name = "Player 4 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002800397/C361CBE503FDE27C2CA0B277BB0B1A8B5B45E9D4/"},
        {name = "Player 5 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002801228/E66FF018000CC7B4CDA93A658193475F9112D996/"},
        {name = "Player 6 Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002802180/6CE35596C7C0354E7D5868C4B8DC286A2A0EEA36/"},

        {name = "TheHirelings",url="https://steamusercontent-a.akamaihd.net/ugc/12940714382263073688/392257681D14FA34B4848585A35811CEF23D685E/"},
        {name = "TheLandmarks",url="https://steamusercontent-a.akamaihd.net/ugc/1859433396458782841/B0C3F1F30DCCF711DA0EC2E5B48F5D410701B958/"},
        {name = "TheClockworkBots", url="https://steamusercontent-a.akamaihd.net/ugc/1859433396458784883/C7C6C929AAEFC026633CCB3888A72F0F279DD8A1/"},
        {name = "TheClockworkBotsSetup", url = "https://steamusercontent-a.akamaihd.net/ugc/1859434388164944196/474B48652298983416B1ACAC5253182B4B537D43/"},
        {name = "LandmarkSetup", url="https://steamusercontent-a.akamaihd.net/ugc/1859434388165714553/500BF78AFBB93A233F7101EF1F2EE117180170F5/"},
        {name = "HirelingsSetup", url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951585009/F33362E64934EFD20410F353BE64A5451FD4FB73/"},
        {name = "Black Market", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239170486/C20D52F3CC0751DAB42D2F4C6E86974B88447E31/"},
        {name = "The Ferry", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239171107/7A6B085D8EBE56E413B96F3591E6E9C46FD16B93/"},
        {name = "Legendary Forge", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239171843/7391D4BC9FEC71BBF02DDD3A36C434AC281D9232/"},
        {name = "Lost City", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239172517/D920C1D6AF1EB2D20AC4C645BA54FA5603ACB0C6/"},
        {name = "The Tower", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239172988/6B96F789BFD1EE4C781965012D42D82B8062E50C/"},
        {name = "Elder Treetop", url="https://steamusercontent-a.akamaihd.net/ugc/1859433736239173480/9836372381D050FC979324F569C82E4698B33A44/"},
        {name = "Mousehold", url="https://steamusercontent-a.akamaihd.net/ugc/11208216119893423521/6899825B194B4AE1C272FD70C8A67292943B3E06/"},
        {name = "Foxburrow", url="https://steamusercontent-a.akamaihd.net/ugc/14325117635732818978/AB011F3096FD8FDCD48FC9589DCDE8EF30A76560/"},
        {name = "Rabbit-Town", url = "https://steamusercontent-a.akamaihd.net/ugc/13209270657155809146/E83807902465C87971D45F55BE9FEF59ABA98312/"},

        {name = "Sure Label", url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951610005/FF4F77B450D2F32501E70CAF352DE257BDADCC05/"},
        {name = "No Thanks Label", url = "https://steamusercontent-a.akamaihd.net/ugc/1859434101951611900/514A5003AE63A6AC1FAEB5F68BE741226F779009/"},


        {name = "ContinueLabel", url="https://steamusercontent-a.akamaihd.net/ugc/1859433396459135062/253FCE248E26587FB9E4CE4F46FDADF821F9F1C4/"},
        {name = "SetupLabel", url="https://steamusercontent-a.akamaihd.net/ugc/1859433396459136343/34E362A154266CD60CAD440C7CA8CA8E36D7BC9C/"},
        {name = "SkipLabel", url="https://steamusercontent-a.akamaihd.net/ugc/1859434258003723744/420718C7006B759F3C04D418311F841412F8F81E/"},

        {name = "DraftClockworkLeft1", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433396458940483/7AAD94536429D22306C090309845DF953CC34532/"},
        {name = "DraftClockworkLeft2", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433736239233535/1E6EAAD16C69A68CFD5BDFB84411FA65FBD7F2C7/"},
        {name = "DraftLandmarksLeft1", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433736239338361/43B9B1D5FA66BC4A8DCA9BD72EC9BBD24F7DB2BF/"},
        {name = "DraftLandmarksLeft2", url = "https://steamusercontent-a.akamaihd.net/ugc/1859433736241079554/3E62827E84C53494BD3F30580E30EA0ABC4AB689/"},

        {name = "TheWarlord",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002976789/D911472850E01877B9C4D64578A98C8943430DAB/"},
        {name = "TheBadgers",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002978285/E82A012E48C4D8C29E06225C63E5DF056C1CD281/"},
        {name = "WouldYouLikeTo",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002995320/62E29F39304BB917BC7D6B2279023815C567E78B/"},

        {name = "Autumn Map Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391479011021/9E725254A1E8A5C7F52AC45587D20FE0D013B7BE/"},
        {name = "Winter Map Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391479013315/D70BD5B6EF8801AB463571F52CC69F3A450BF5E2/"},
        {name = "Lake Map Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391479014412/C558A70F5F54251C81131D10EFD090DEE6B421D7/"},
        {name = "Mountain Map Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391479015401/461D8051E173952BB8AA8516F1C97086973F791F/"},

        {name = "Gorge Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/14465139803514895819/7CE3CD6DD27F6313548E8E79111612058BEB0F01/"},
        {name = "Gorge Original Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16433884666649838/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        
        
        {name = "Marsh Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/9462082978453409298/2BC10CFF84D5ACFC833CF5DBF81D5A4246CE9396/"},
        {name = "Treasure Island Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479017185/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "The Deep Woods Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479018075/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "The Wastelands Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479018823/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Australia Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479019656/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Narrows and Islets Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479020655/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Tunnel Unraveled Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479021477/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Tropics Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479022298/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Summer Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1696154342827738629/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Lost Woodland Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1871805410096554660/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Legends Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1871805410096540515/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Urban Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1856049403360993432/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "River Town Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161430757/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Mountainside Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161431106/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Tidal Flats Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161431190/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Blighted City Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161431768/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Taiga Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161431735/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Gloom Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16419302161432264/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Klacar's Volcano Island Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16423272750663634/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Spaceballs Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16429450331905367/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Inferno Map Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16429450331978383/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Blighted Grove Map Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/16430283484958415/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},

        {name = "Standard Deck Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479023162/017FC34EB2A5461BA9907A6655C19031F88CBF46/"},
        {name = "Exiles and Partisans Deck Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479024026/F0F9819595316F0C4002C81902F616579B413F2C/"},
        {name = "Squires and Disciples Deck Tile",url="https://steamusercontent-a.akamaihd.net/ugc/16423272747872045/D2F069B918E0EFBC461DEA2920B5FFE3282BB053/"},

        {name = "Sorcery of the Enchanted Woods Deck Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479024813/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Upstarts and Renegades Deck Tile",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391479025626/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Dawn and Dusk Deck Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302161430663/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Offensive Deck Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/16423272747851258/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Crafty Tactics Deck Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/16423272747855386/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},


        {name = "60 Card Master Deck Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391479026649/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},
        {name = "Dark Deck Tile",url = "https://steamusercontent-a.akamaihd.net/ugc/1759199733284882024/177A27B5110AACB3297427BED28BFA8B5C9B990D/"},


        {name = "draftBackButton",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500249680/07F53AB05F97BFCD0B372B60ECCAC2534D03C9C0/"},
        {name = "draftJoinButton",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500252810/618CF62B03AC113700F5F3C82C6CC143BD7980CB/"},
        {name = "draftLeaveButton",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500254831/DCCA54261EE8176EA4D4A367CD6D510669EE36C7/"},
        {name = "draftOkayButton",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500256036/0B98A2667B87E1D56069A516C7467A2F3251C00E/"},
        {name = "draftCheckRosterButton",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500256753/7BE44363B3AB5E9B20DFFF21F9A8D1E8D157656D/"},
        {name = "Checkmark",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500339787/BCB16EAAD444C96B77E2DC230473C89086269CBF/"},
        {name = "Xmark",url="https://steamusercontent-a.akamaihd.net/ugc/1809859531500279761/E8108BE85DEBE1F569D9FDF951FA0D2DEA769CB8/"},

        {name = "Birdsong0",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951710722/B363F2041887AB57F90C594D7036F7FD1745086C/"},
        {name = "Birdsong1",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951712863/B1CD398C494BE01C9D4E4753E9F915D7EB54E460/"},
        {name = "Birdsong2",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951713498/B99906D69F79A91FFEEE4444152EA31E923FDA42/"},
        {name = "Birdsong3",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951714181/CAAC38556E5D2111DA5D75EB136635CA9645C52A/"},

        {name = "Birdsong5",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951715139/8ECE46813DCB1D48B3D36A419B88C24C80FAAD93/"},
        {name = "Birdsong6",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951715881/7927CA35AB21A6D5BCD9D1249027B258D82A2648/"},

        {name = "Birdsong8",url="https://steamusercontent-a.akamaihd.net/ugc/9782098988954605361/BA62008C2AF294CD69A76E2AACE1DB88923C85CF/"},
        {name = "Birdsong9",url="https://steamusercontent-a.akamaihd.net/ugc/1859434101951718461/65E9006F827C7FC2D5180838E6C4A49F8040D8F5/"},

        {name = "Daylight00",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002351912/627D5210E8BCE36A77E184822010EF2C61F7DEDC/"},
        {name = "Daylight0",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002352594/072F0CCC9D517E9FADC65F7BDE8256398266B047/"},
        {name = "Daylight1",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002353118/D1293E1872A2FF7B6CAF0B439AC7D4EE55D90224/"},
        {name = "Daylight2",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002353766/6F439F94DE0CB726A10D42931F22CF32D2A4D1CA/"},
        {name = "Daylight3",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002354394/01E665731D3A10966A85E4059731CBAAC99F661A/"},
        {name = "Daylight4",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002354943/AD7A3863BC48FE4CB38148457B42AC00D8BC8EBE/"},
        {name = "Daylight5",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002355565/BEA908D461229491144DC3CEE3047769C645D30E/"},
        {name = "Daylight6",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002356204/0253E139941420EA32CBF63EEB066962A30EE1E3/"},
        {name = "Evening1",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799002356838/C3AF19CCCD1E81E2422E82E60EA512AC12CE5C0C/"},

        {name = "DraftBanner",url="https://steamusercontent-a.akamaihd.net/ugc/1859434258001698297/806BC83B3E94AC2454A3E285AC67B90424959125/"},

        {name = "Random White",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391476513193/BC24B78DB0EB7F04B03D162BD7C9C4DC56F6BA30/"},
        {name = "Exit White",url = "https://steamusercontent-a.akamaihd.net/ugc/1760320391476521209/314B380DED440A1EA71186A6E99FB3C59402C3C4/"},
        {name = "StartDraftButton",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391476562674/F7F1CF96513DDEA45A8F3676A265A88E63C676A1/"},
        {name = "WhiteNext",url="https://steamusercontent-a.akamaihd.net/ugc/1809859799003114048/CF48A3023C92C86A4A3D145367AFD84F23681D07/"},

        {name = "HirelingSetupMessage", url = "https://steamusercontent-a.akamaihd.net/ugc/1782839166827486343/6117E1938803CFB27B9B5E11AE5211EA1D586847/"},

        {name = "StartGameButton",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391483979109/439A3ED93AA7CCEA361EE156603836D8D1AC6213/"},
        {name = "DoneButton",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391477467005/7C3F17A8356F03ED9959F45D9B75D4806753293D/"},

        {name = "RedOnlyText", url="https://steamusercontent-a.akamaihd.net/ugc/1859433104053128068/C897405AA4A79F6BB6BB1FCB437A7DCCE4816E5D/"},
        {name = "StayRed",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391478913266/D2EB4AB85F5F10C192BB144B002A32DCF92B3265/"},
        {name = "BringItOn",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391478914056/E3198ED7968E6049D0C66D8FB999C5CACC59DBCC/"},
        {name = "RootLogo",url="https://steamusercontent-a.akamaihd.net/ugc/1760320391484168782/6AB3B3D66178AF6937DE96321EB5E9898C6B088B/"},

        {name = "SixPack",url="https://steamusercontent-a.akamaihd.net/ugc/16420027251539438/5ACED6C71A4D2C7292355986C1279349C00BA49E/"},

        -- Tournament Assets
        {name = "GSGBanner",url="https://steamusercontent-a.akamaihd.net/ugc/1695030024164477202/952098BA4C12862A95CE19110B12227B85D86086/"},
        {name = "TournamentJoin",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024164509942/2152ADCBD171129717DE63FDA374C83BAF8FE11D/"},
        {name = "TournamentLeave",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024164511274/1E4D84852505A07139E4D43B2CF485CEBB7D206B/"},
        {name = "TournamentStartDraft",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024164512460/F7E49A635F4B70694FDAC469A384D12BE67DD16B/"},
        {name = "TournamentSide1",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024164513547/295D37261C5874179FFCE36C5433EC81C0B20EDD/"},

        {name = "TournamentSide2",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024165938810/12D932C8F3B369CF5DADB6716C431DF02EF0BDA6/"},
        {name = "TournamentMapLabel",url = "https://steamusercontent-a.akamaihd.net/ugc/1695030024165950555/18567DBC2FAF017705789C5493F5DB8E34F3AF09/"},

        {name = "ExtraChairsWhite",url = "https://steamusercontent-a.akamaihd.net/ugc/1786233211071686717/6EC913639AC72B7CE6D04A9BB36D715A218B1793/"},

        {name = "DoubleEntente",url="https://steamusercontent-a.akamaihd.net/ugc/1786233211086829774/D34DED7CBC4DDF71B6E3BD78C2DEBC90F3176531/"},
        {name = "ActionDeck",url="https://steamusercontent-a.akamaihd.net/ugc/1786233211086847220/627C599441E86F86731BEDF96B23634C36882F78/"},
        {name = "Lost Woodland Map",url="https://steamusercontent-a.akamaihd.net/ugc/1786233211086883130/5B96E0370A42D4CC2C97569EDFF7624621471EDF/"},
        {name = "Warriors Wake",url="https://steamusercontent-a.akamaihd.net/ugc/1786233211086912182/563B6D9C9AFC31863D36B443728319131A2B4E03/"},
        {name = "Woodland Revolution", url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818215151/BD81EFECC6902E60CAFE69E4D0097FDE9B1C86EB/"},

        {name = "DoomedBerzeker",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818575000/34288530419DF2000AB07BE9C6F76F4F390810E9/"},
        {name = "DoomedBarkeep",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818575539/E85CCE19EC8F6CDFAE22F78B30128A529EAE7BAD/"},
        {name = "DoomedBlacksmith",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818574236/99EEEF30B3667FB22F243008BCA1368EE3E05338/"},
        {name = "DoomedSwindler",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818573545/FC3E6F9A6C7EC90D212555F80BAB19A44BE34782/"},
        {name = "DoomedBard",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818576295/160397A5A0DC4B0CA28B90CFB07C0C005A153B44/"},
        {name = "DoomedZealot",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818570837/5AD9E0C3A070B225F367DA2D8B2FF19B45DE01AE/"},
        {name = "DoomedFate",url="https://steamusercontent-a.akamaihd.net/ugc/1833522185818445287/72392A96AED1472DDC31D3867B7742B316703314/"},

        {name = "Black Creek Pirates II",url="https://steamusercontent-a.akamaihd.net/ugc/1874056202036022996/426F024995C896F8DFB53D5F51BA8100A213AB64/"},

        {name = "Mob Lobber",url="https://steamusercontent-a.akamaihd.net/ugc/1871806044359108580/ED91771BFC667788679555DC9F9E7E175E5A2346/"},
        {name = "Quest Freshener",url="https://steamusercontent-a.akamaihd.net/ugc/1871806044359176221/007B74BEF5F41C8CF1E3BC6371B8746F85149C5B/"},

        {name = "Ginso's Gizmo",url="https://steamusercontent-a.akamaihd.net/ugc/1871808701913894000/9E9D2A27ADC818413936D98C3194E03E87A8726A/"},
        {name = "Supply Knight",url="https://steamusercontent-a.akamaihd.net/ugc/16420027239829921/595B9928F56465239300E6A54C4A27E53F6E04F5/"},
        {name = "Snow Kingdom ii",url="https://steamusercontent-a.akamaihd.net/ugc/1871808701913905742/C512B939A77659A639B338D3D7100B46D3B80078/"},
        {name = "Black Paw Bandits",url="https://steamusercontent-a.akamaihd.net/ugc/1871808701913909385/F2E9E01AA0ACFB1783D550FBC0578AD57B21E84F/"},

        {name = "Urban Map", url="https://steamusercontent-a.akamaihd.net/ugc/1856049403360886234/7DACC2ADA249351AA203BD55EEABE021F13D7AB5/"},
        {name = "MashUp", url="https://steamusercontent-a.akamaihd.net/ugc/1856049403372487506/800F1C1E00650FB92603080C3A95FD42E58BFD56/"},

        {name = "Robot Die", url="https://steamusercontent-a.akamaihd.net/ugc/1862805937564898964/DBFF836F27862D7E04DD45FE1D4FAEABDC02DDD5/"},

        {name = "Reach Cell", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080798164/0D2C17759DEFDC174D12198136404A7ECE05FC5F/"},
        {name = "Reach Cell 10", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080859685/DBC14BF55B906F73925CB99D2A48D8653A6E8655/"},
        {name = "Reach Cell 20", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080861783/D301E68CB89DCDF96782CDCCBFE22C1D0E2526C1/"},
        {name = "Reach Cell 30", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080862473/E48961307C71CBA6CA9189BDD625E8B84ED2C7F1/"},
        {name = "Reach Cell 40", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080863963/4EA3989FC5CAFDC6E584E2B1A0E7FCB232DE02D8/"},
        {name = "Reach Cell Dot", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080904939/F4D3FC049DECCCE5EF930CCDC003EA22C207459E/"},
        {name = "Reach Cell Dots", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225080905685/C05EF88D19BEF812487A9429502BD9071769B44E/"},


        {name = "DraftFactionPick", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225081613222/2464BDE6BF73D6522AA8BBDB37CB6B5EBD6A4B99/"},
        {name = "DraftFactionSetup", url="https://steamusercontent-a.akamaihd.net/ugc/1859434225081615866/317E175EE2E15A84723CA8510B3B0D74D0B19332/"},

        {name = "standardSelection", url="https://steamusercontent-a.akamaihd.net/ugc/1859434388160724128/3ACB262AA7620A4108D09D1437F9DFA3EE95A62F/"},
        {name = "adsetSelection", url="https://steamusercontent-a.akamaihd.net/ugc/1859434388160745758/EF66E3413945D78D73E0D27E4AD1F3038C687ACA/"},

        -- New Fan Factions // 11/11/2024
        {name = "Chameleander",url = "https://steamusercontent-a.akamaihd.net/ugc/14792217880038068722/443149AE6BAF4858C2C37624115DBB25B4CCD119/ "},
        {name = "Cirque du Goat",url = "https://steamusercontent-a.akamaihd.net/ugc/16419302165190285/136D31C871008C148D5C51EF9EA5462567AA8E2D/"},
        {name = "Thewy Info", url = "https://steamusercontent-a.akamaihd.net/ugc/16419302164246797/5919C074E0FD61B002BCF188F139EF40F5417A51/"},

        {name = "United Colonies", url = "https://steamusercontent-a.akamaihd.net/ugc/16419302165168501/BC91D59F9BB0F7A614600570FCCCF8C6ADA91C42/"},
        {name = "Disasterman52 and Mysteryboxx Info", url = "https://steamusercontent-a.akamaihd.net/ugc/16419302165171019/8CA7FDD0DAD03982F916C9CEB627921B7645D883/"},
        {name = "SP Shaman and Disasterman Info", url = "https://steamusercontent-a.akamaihd.net/ugc/16419302166075461/3AF848F2E28286CF03A65CAFEA159F312B1A3363/"},

        {name = "KnightMiner Info",url = "https://steamusercontent-a.akamaihd.net/ugc/16420027239835212/17EF891649EAC732AD14DB5F4BF5EEF86A8B40F0/"},
        {name = "Crafty Tactics Deck",url ="https://steamusercontent-a.akamaihd.net/ugc/16420027239845541/86839DB8FD22242FE6C266B180CBC112571E6D33/"},
        {name = "Phoenix1147 Info",url = "https://steamusercontent-a.akamaihd.net/ugc/16420027239840004/BE2E5831BF0712A048CE2DA1AF1034F44FD6F002/"},

        {name = "Borough Kings",url = "https://steamusercontent-a.akamaihd.net/ugc/16420027245499554/5D1F4D0E5757E0954CBA8DAD5A974770C0240A49/"},
        {name = "Host of Light",url = "https://steamusercontent-a.akamaihd.net/ugc/16420027245496603/0CEAE160AA06FE2B5EBF9C9586CDD385368F0A21/"},

        {name = "Nuanced Quest Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/16421205162192184/0EB23DE14DEEB692BC718D1995877FFEE0F308E6/"},
        {name = "Offensive Deck",url = "https://steamusercontent-a.akamaihd.net/ugc/16421205162192117/FE3156709F13ED9B46C72C676C938853FB60878D/"},

        {name = "Whisperers Guild", url = "https://steamusercontent-a.akamaihd.net/ugc/16423272747455615/99B53E84E6D62963A9E68ACBA0DA23B7827BF9A0/"},
        {name = "Doomsayers Union", url = "https://steamusercontent-a.akamaihd.net/ugc/16423272747453068/B48EB4FDFB2F15F821BB790DEFDA664305667245/"},

        {name = "New Hirelings", url = "https://steamusercontent-a.akamaihd.net/ugc/16427546922849855/F1FF06471CC23933E6353A97282366553F710C5A/"},

        {name = "The Ooze", url = "https://steamusercontent-a.akamaihd.net/ugc/16430083180899816/2B561DA929D17784EFA2AB394FC94DB30E865ABB/"},
        {name = "Bot Upgrade Button", url = "https://steamusercontent-a.akamaihd.net/ugc/9686778829007578801/50A4993C8E7C2A0F10AAFA38FD3C762EE6B672AE/"},

    }

    _G['Roster'] = {}
    _G['DraftedFactions'] = {"","","","","",""}
    _G['TurnOrder'] = {}
    _G['ColorsTaken'] = {}
    vagabondChosen = false
    Turns.order =   {"Red","Yellow","Orange","Teal","Green","Brown"}


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











function kickPlayersFromSeats()
  for _, p in pairs(Player.getPlayers()) do
    if p.color != "White" and p.color != "Black" then
      p.changeColor("Grey")
    end
  end
end

local handScale = {20,6,4}
local handRotations = {{0,0,0},{0,180,0}}
local handPositions = {{52.00,14.62,-64.00},{0.00,14.62,-64.00},{-52.00,14.62,-64.00},{-52.00,14.62,64.00},{0.00,14.62,64.00},{52.00,14.62,64.00}}


function placePlayer(player,color,pos,rot)

  player.changeColor(color)
 
  Player[color].setHandTransform({position = handPositions[pos],rotation = handRotations[rot],scale = handScale})

end


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
function infoJustin() setInfo("JustinInExile Info") end



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











local hirelings = {
  {"Marquise de Cat","Forest Patrol","Feline Physicians"},
  {"Eyrie Dynasties","Last Dynasty","Bluebird Nobles"},
  {"Woodland Alliance","Spring Uprising","Rabbit Scouts"},
  {"Vagabond","The Exile","The Brigand"},

  {"The Lizard Cult","Warm Sun Prophets","Lizard Envoys"},
  {"Riverfolk Company","Riverfolk Flotilla","Otter Divers"},
  {"Underground Duchy","Sunward Expedition","Mole Artisans"},
  {"Corvid Conspiracy","Corvid Spies","Raven Sentries"},

  {"Lord of the Hundreds","Flame Bearers","Rat Smugglers"},
  {"Keepers in Iron","Vault Keepers","Badger Bodyguards"},

  {"Woodland Band","Popular Band","Street Band"},
  {"Furious Protector","Furious Protector","Stoic Protector"},
  {"Highway Bandits","Highway Bandits","Bandit Gangs"},

  {"Twilight Council","Sunny Advocates","Bat Messengers"},
  {"Lilypad Diaspora","River Roamers","Frog Tinkers"},
  {"Prosperous Farmers","Prosperous Farmers","Struggling Farmers"},
  -- {"Knaves of the Deepwood","The Exile","The Brigand"}
}


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


function spawnTournamentDraftFaction(i,faction,color)

  local pos = getPosition(color,#_G["Roster"])

  -- makes vagabond basics board

  if isVagabond(faction) then
    makeVagabondLayout(i,"Vagabond Layout",color)
  end

  local objects = {}

  objects = EVERYTHING['Standard'][faction]['data']
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z
  function callback(o)

    if flipSide(color,#_G['Roster']) then
      o.setRotation({o.getRotation().x, o.getRotation().y + 180, o.getRotation().z})
    else
      o.setRotation({o.getRotation().x, o.getRotation().y, o.getRotation().z})
    end

    if _G['vagabondAlreadySpawned'] then
      if o.hasTag("Quest") then o.destroy() end
    else
      if o.hasTag("Ruin Set") then o.destroy() end
    end

      if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
  end
  for _,v in ipairs(objects) do
      local vec = Vector(v.move_to) * scale
      if flipSide(color,#_G['Roster']) then
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



function spawnDraftFaction(i,faction,color)

  local pos = getPosition(color,#_G["FullRoster"])

  -- makes vagabond basics board

  if isVagabond(faction) then
    makeVagabondLayout(i,"Vagabond Layout",color)
  end

  local objects = {}

  objects = EVERYTHING['Standard'][faction]['data']
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z
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

function standard()
  allButtonsOff()
  self.UI.setAttribute("standardButtons","active","True")
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

MANUAL_FACTION_SELECTOR_JSON = [===[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.56,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":15.5,"scaleY":1.0,"scaleZ":15.5},"Nickname":"Faction Board","Description":"","GMNotes":"","Locked":false,"Grid":false,"Snap":true,"IgnoreFoW":false,"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/board/board_clean_v4.png","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1725416402718254700/C6F00394AFEE245DFFA53CD358F5F966AA754BC9/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"MANUAL_FACTION_COORD_GUID = \"bab7e1\"\nfunction manualFactionRelay(player, value, id)\n  local coordinator = getObjectFromGUID(MANUAL_FACTION_COORD_GUID)\n  if coordinator ~= nil then\n    coordinator.call(\"manualFactionPick\", { color = player.color, id = id, board = self.getGUID() })\n  end\nend\nfunction deleteThis()\n  self.destruct()\nend\nfunction vagabondPage()\n  self.UI.setAttribute(\"factionPage\",\"active\",\"False\")\n  self.UI.setAttribute(\"vagabondPage\",\"active\",\"True\")\nend\nfunction vagabondBack()\n  self.UI.setAttribute(\"vagabondPage\",\"active\",\"False\")\n  self.UI.setAttribute(\"factionPage\",\"active\",\"True\")\nend\n","XmlUI":"<Button id=\"xButton\" onclick=\"deleteThis\" icon=\"CloseX\" position=\"112 82 -20\" width=\"18\" height=\"18\" color=\"#bd2608\"/><ToggleGroup id=\"factionPage\" active=\"True\"><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Marquise de Cat\" position=\"-90 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Marquise de Cat\" color=\"#d77435\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Eyrie Dynasties\" position=\"-30 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Eyrie Dynasties\" color=\"#4776b6\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Woodland Alliance\" position=\"30 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Woodland Alliance\" color=\"#6bb659\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"The Lizard Cult\" position=\"-90 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"The Lizard Cult\" color=\"#e8e138\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Riverfolk Company\" position=\"-30 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Riverfolk Company\" color=\"#5cbab4\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Underground Duchy\" position=\"30 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Underground Duchy\" color=\"#e4c0a2\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Corvid Conspiracy\" position=\"90 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Corvid Conspiracy\" color=\"#542c75\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Lord of the Hundreds\" position=\"-90 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Lord of the Hundreds\" color=\"#f3461b\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Keepers in Iron\" position=\"-30 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Keepers in Iron\" color=\"#acadb1\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Twilight Council\" position=\"30 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Twilight Council\" color=\"#964E30\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Lilypad Diaspora\" position=\"90 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Lilypad Diaspora\" color=\"#B09804\"/><Button onclick=\"vagabondPage\" id=\"VagabondAndKnaves\" position=\"90 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"VagabondAndKnaves\" color=\"#ffffff\"/></ToggleGroup><ToggleGroup id=\"vagabondPage\" active=\"False\"><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Adventurer\" position=\"-100 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Adventurer\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Arbiter\" position=\"-50 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Arbiter\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Cheat\" position=\"0 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Cheat\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Gladiator\" position=\"50 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Gladiator\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Harrier\" position=\"-100 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Harrier\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Jailor\" position=\"-50 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Jailor\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Ranger\" position=\"0 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Ranger\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Ronin\" position=\"50 -5 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Ronin\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Scoundrel\" position=\"-100 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Scoundrel\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Thief\" position=\"-50 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Thief\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Tinker\" position=\"0 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Tinker\" color=\"gray\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Vagrant\" position=\"50 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Vagrant\" color=\"gray\"/><Button onclick=\"vagabondBack\" id=\"vbBack\" position=\"100 45 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"VagabondAndKnaves\" color=\"#ffffff\"/><Button onclick=\"manualFactionRelay\" category=\"Standard\" id=\"Knaves of the Deepwood\" position=\"100 -55 -20\" width=\"40\" height=\"40\" fontSize=\"8\" icon=\"Knaves of the Deepwood\" color=\"gray\"/></ToggleGroup>","CustomUIAssets":[{"Type":0,"Name":"Marquise de Cat","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739429295/F6CF523AAA7DCC91AF3812339EBB3354F6D9891A/"},{"Type":0,"Name":"Eyrie Dynasties","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755958213/960DFA43E52D99A3250863FC63F3BA3AE5104325/"},{"Type":0,"Name":"Woodland Alliance","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755956632/E99D3C9B246A94F6A898EC0D8098A05FA9467473/"},{"Type":0,"Name":"Knaves of the Deepwood","URL":"https://steamusercontent-a.akamaihd.net/ugc/14468202139363768412/1012F7145C45B86F395C099B9AE80EA536529DD3/"},{"Type":0,"Name":"The Lizard Cult","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755960838/D88CBE9192488A678AF3EC6DFC45B4C728C9A169/"},{"Type":0,"Name":"Riverfolk Company","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755963912/C9589D96259534C6FB15DD91F78E7E90A073FDD8/"},{"Type":0,"Name":"Underground Duchy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755961872/1E2748C8EDD0BDE039B81658AFD0B19C771569BD/"},{"Type":0,"Name":"Corvid Conspiracy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755959858/69B8EC707AD26EF2F558ACAB65B39163B812D3F6/"},{"Type":0,"Name":"Lord of the Hundreds","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818578726/CE952087E18A1C0B6B94E44EF53EB009A97A7122/"},{"Type":0,"Name":"Keepers in Iron","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818579404/C0D7197A109DBF0C2EFB34DF50AE2CA70A66C25B/"},{"Type":0,"Name":"Twilight Council","URL":"https://steamusercontent-a.akamaihd.net/ugc/2452866064845174396/6228F6A71DDC36CD883777CA958857CB123D7ECB/"},{"Type":0,"Name":"Lilypad Diaspora","URL":"https://steamusercontent-a.akamaihd.net/ugc/2508034524425991747/77C277526C0042FE2754C83836A1E2C3C03FAD38/"},{"Type":0,"Name":"CloseX","URL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/close_x.png"},{"Type":0,"Name":"Adventurer","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756318712/DAB9CB5B2AA9CF5AF4BDD67CFED687B8595411CF/"},{"Type":0,"Name":"Arbiter","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756223555/8BB76979D215E9C042976005212DD7D0F9EBCDBD/"},{"Type":0,"Name":"Cheat","URL":"https://steamusercontent-a.akamaihd.net/ugc/14685838847886183596/2F910C564507478E736E783C2B01011BF710E3D0/"},{"Type":0,"Name":"Gladiator","URL":"https://steamusercontent-a.akamaihd.net/ugc/16433884667023926/65F0E372EB9EEF805369BB5F766846F066BD62AF/"},{"Type":0,"Name":"Harrier","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756321980/D728E9E7523EF9917554681B8CCFA7A79D6E95DC/"},{"Type":0,"Name":"Jailor","URL":"https://steamusercontent-a.akamaihd.net/ugc/10906121492486022753/B8147FE9BB8652380D0027EB4AF0C7FF8C7C66AE/"},{"Type":0,"Name":"Ranger","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756323292/B5CDBACDB5E58637478F86047D574579AECBC763/"},{"Type":0,"Name":"Ronin","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739435936/8C15D8C6D58FAF51A22B66697740CBA5BAEBBEFB/"},{"Type":0,"Name":"Scoundrel","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756324621/71561324D23947260120C7F2EDF0A692986619EB/"},{"Type":0,"Name":"Thief","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756326469/AA4F3B6BF91AC337A240B582DF46C07DF9A374E5/"},{"Type":0,"Name":"Tinker","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756328063/25E9D54EAFE7A483877DECF1013DE57C96B0F214/"},{"Type":0,"Name":"Vagrant","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291756329310/FEBDC9CB90C879DFC4ECAE1BBDDA857DBF9CD95C/"},{"Type":0,"Name":"VagabondAndKnaves","URL":"https://steamusercontent-a.akamaihd.net/ugc/11747765109863371101/6EB77E31F0244DFD039474C19C18D49AD0C93DBD/"}]}]===]

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













function tools1()
  self.UI.setAttribute("tools1","active","True")
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
RTT_ORDER_JSON_4 = [==[{"GUID":"88257f","Name":"Deck","Transform":{"posX":64.33211,"posY":11.60173,"posZ":-25.0888042,"rotX":-1.91315461e-08,"rotY":270.0,"rotZ":-7.529847e-07,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":false,"SidewaysCard":true,"DeckIDs":[805,802,801,800],"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","ContainedObjects":[{"GUID":"8491fb","Name":"Card","Transform":{"posX":64.0154,"posY":11.5751534,"posZ":-32.2374573,"rotX":3.13927535e-06,"rotY":270.0,"rotZ":9.9273886e-05,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":805,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"bacbbf","Name":"Card","Transform":{"posX":64.60444,"posY":11.6144962,"posZ":-31.4052162,"rotX":-0.002876776,"rotY":270.0,"rotZ":359.994,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":802,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"7557a4","Name":"Card","Transform":{"posX":65.741,"posY":11.6480627,"posZ":-32.8092346,"rotX":359.991364,"rotY":270.0,"rotZ":0.002321583,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":801,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"17843f","Name":"Card","Transform":{"posX":64.41976,"posY":11.65809,"posZ":-32.54536,"rotX":0.001989416,"rotY":270.0,"rotZ":-0.00265754061,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":800,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]}]==]
RTT_ORDER_JSON_5 = [==[{"GUID":"fdb993","Name":"Deck","Transform":{"posX":55.35494,"posY":11.6065445,"posZ":-24.9285755,"rotX":-6.83371937e-09,"rotY":270.0,"rotZ":-3.07726573e-08,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":false,"SidewaysCard":true,"DeckIDs":[806,805,802,801,800],"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":"","ContainedObjects":[{"GUID":"811ad9","Name":"Card","Transform":{"posX":55.44372,"posY":11.5751438,"posZ":-24.79723,"rotX":2.30794358e-05,"rotY":270.0,"rotZ":-0.0001306939,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":806,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"8491fb","Name":"Card","Transform":{"posX":64.0154,"posY":11.5751534,"posZ":-32.2374573,"rotX":3.13927535e-06,"rotY":270.0,"rotZ":9.9273886e-05,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":805,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"bacbbf","Name":"Card","Transform":{"posX":64.60444,"posY":11.6144962,"posZ":-31.4052162,"rotX":-0.002876776,"rotY":270.0,"rotZ":359.994,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":802,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"7557a4","Name":"Card","Transform":{"posX":65.741,"posY":11.6480627,"posZ":-32.8092346,"rotX":359.991364,"rotY":270.0,"rotZ":0.002321583,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":801,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""},{"GUID":"17843f","Name":"Card","Transform":{"posX":64.41976,"posY":11.65809,"posZ":-32.54536,"rotX":0.001989416,"rotY":270.0,"rotZ":-0.00265754061,"scaleX":2.29997349,"scaleY":1.0,"scaleZ":2.29997349},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.713235259,"g":0.713235259,"b":0.713235259},"LayoutGroupSortIndex":0,"Value":0,"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":true,"Hands":true,"CardID":800,"SidewaysCard":true,"CustomDeck":{"8":{"FaceURL":"https://steamusercontent-a.akamaihd.net/ugc/1835788265939406811/7679B10CF8ED042A245D14B569E9E3D9CDFE75BC/","BackURL":"https://steamusercontent-a.akamaihd.net/ugc/1799745188600310763/0C068F20F62D953FE96E73AB1E0014AABEECF74A/","NumWidth":5,"NumHeight":2,"BackIsHidden":true,"UniqueBack":false,"Type":0}},"LuaScript":"","LuaScriptState":"","XmlUI":""}]}]==]
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
  rttRankedBtn     = { fn = "rttSetup",              color = "#030411", icon = "RankedArt",          warn = "WipeConfirmArt" },
  rttThemeBtn      = { fn = "rttTheme",              color = "#49514b", icon = "ThemeArt",           warn = "WipeConfirmArt" },
  rttFourBoardsBtn = { fn = "setupFactionBoards",    color = "#3a2f22", icon = "FourBoardsArt",      warn = "WipeConfirmArt" },
  Marsh5P          = { fn = "rttFivePStart",         color = "#463221", icon = "FivePlayerArt",      warn = "WipeConfirmArtWide" },
  Marsh5PSetup     = { fn = "setupFivePlayerBoards", color = "#463221", icon = "FivePlayerSetupArt", warn = "WipeConfirmArtWide" },
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

RTT_TEARDOWN_TAGS = { "RTT Selector", "RTT Manual Selector", "RTT Faction", "RTT Pond" }

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
function rttEnableTurns(nseats)
  nseats = math.max(1, nseats or 4)
  local torder = {}
  for i = 1, nseats do torder[#torder + 1] = RTT_SETUP_COLORS[i] end
  if #torder == 0 then return end
  pcall(function()
    Turns.type = 2                       -- the custom order below
    Turns.order = torder
    Turns.reverse_order = false
    Turns.skip_empty_hands = false       -- step through every seat, occupied or not
    Turns.pass_turns = true
    Turns.turn_color = torder[1]         -- seat 1 starts
    Turns.enable = true
  end)
end

function rttClearGameObjects()
  RTT_RUN_ID = RTT_RUN_ID + 1                      -- invalidates every in-flight setup callback
  for _, t in ipairs(RTT_TEARDOWN_TAGS) do
    for _, o in ipairs(getObjectsWithTag(t)) do pcall(function() o.destruct() end) end
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
  for _, k in ipairs({ "RTT_SEAT_POS", "RTT_SEAT_COLOR", "RTT_SEAT_PLAYER" }) do
    pcall(function() Global.setVar(k, JSON.encode({})) end)
  end
end

-- ONE new-game entry point, called by BOTH setup paths instead of each keeping its own copy of the
-- teardown + reset sequence. `seats` is how many seats to configure the turn system for, or nil to
-- leave the turn system alone -- the ranked draft sets it later, from the real seating.
function rttNewGame(seats)
  rttClearGameObjects()                            -- objects, hand zones, run-id bump
  rttResetRunState()                               -- everything teardown cannot see
  rttRemoveFrogsFromDeck()                         -- the deck survives teardown; its frog cards must not
  if seats ~= nil then rttEnableTurns(seats) end
end
function rttBusyBegin(sec)
  RTT_BUSY = true
  RTT_BUSY_TOKEN = RTT_BUSY_TOKEN + 1
  local t = RTT_BUSY_TOKEN
  Wait.time(function() if RTT_BUSY_TOKEN == t then RTT_BUSY = false end end, sec or 15)
end

-- would a setup click actually destroy anything? These are exactly the tags rttSetup tears down.
function rttWouldWipe()
  for _, t in ipairs({ "RTT Faction", "RTT Selector", "RTT Manual Selector" }) do
    if #getObjectsWithTag(t) > 0 then return true end
  end
  return false
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
function rttArmOrGo(id)
  local d = RTT_WIPE_BTN[id]
  if d == nil then return end
  if RTT_BUSY then return end                    -- a setup is still running: swallow the click
  if RTT_ARM.id == id then                       -- SECOND click on the armed button: commit
    rttDisarm()
    if     d.fn == "rttSetup"           then rttSetup()
    elseif d.fn == "rttTheme"           then rttTheme()
    elseif d.fn == "rttFivePStart"      then rttFivePStart()
    elseif d.fn == "setupFactionBoards" then setupFactionBoards()
    elseif d.fn == "setupFivePlayerBoards" then setupFivePlayerBoards()
    end
    return
  end
  if not rttWouldWipe() then                     -- clean table: nothing to lose, just run
    if     d.fn == "rttSetup"           then rttSetup()
    elseif d.fn == "rttTheme"           then rttTheme()
    elseif d.fn == "rttFivePStart"      then rttFivePStart()
    elseif d.fn == "setupFactionBoards" then setupFactionBoards()
    elseif d.fn == "setupFivePlayerBoards" then setupFivePlayerBoards()
    end
    return
  end
  rttDisarm()                                    -- a different button was armed: revert it first
  RTT_ARM.id = id
  RTT_ARM.token = RTT_ARM.token + 1
  local tok = RTT_ARM.token
  pcall(function()
    self.UI.setAttribute(id, "icon", d.warn)     -- the art itself becomes the red question
    self.UI.setAttribute(id, "color", "#a83226") -- matches the plaque so the rounded corners blend
  end)
  Wait.time(function() if RTT_ARM.token == tok then rttDisarm() end end, 3.0)
end

function rttArmRanked(player, value, id)  rttArmOrGo("rttRankedBtn") end
function rttArmTheme(player, value, id)   rttArmOrGo("rttThemeBtn") end
function rttArmFour(player, value, id)    rttArmOrGo("rttFourBoardsBtn") end
function rttArmMarsh5P(player, value, id) rttArmOrGo("Marsh5P") end
function rttArmFiveSetup(player, value, id) rttArmOrGo("Marsh5PSetup") end

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

  board.destruct()

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
    pcall(function() rttSpawnFaction("Vagabond Layout",      cp.x, cp.z, flip, "Standard", spawnRy) end)
    pcall(function() rttSpawnFaction("Vagabond Dice and VP", cp.x, cp.z, flip, "Standard", spawnRy) end)
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

  makeSpecial("Tools","Salty Old Stan",-31.09 + 2.24,5,2.31)

end

function summonLizardBlocker()
  stan = find_object_by_gm_note("Salty Old Stan")
  if stan == nil then
    makeSpecial("Tools","Lizard Blocker",-31.09,5,2.31)
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
  local sc = self.getScale()
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
    return
  end
  makeSpecial("Tools", "Lizard Blocker", RTT_DRAGON_GOD[1], RTT_DRAGON_GOD[2], RTT_DRAGON_GOD[3])
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
  if id == "Dark Deck" or id == "Dark Deck 2" then
    makeDarkDeckSpecials()
  end
  removeDeckItems()
  local my_rot = self.getRotation()
  local objects = {}
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

  if (starts_with(id,"Dark Deck")) then
    if (ends_with(id,"2")) then
      allObjects = {EVERYTHING["Decks"]['Dark Refill Card']['data'],EVERYTHING["Decks"][id]['data']}
    else
      allObjects = {EVERYTHING["Decks"]['Dark Refill Card']['data'],EVERYTHING["Decks"]["Dark Dominance Track Card"]['data'],EVERYTHING["Decks"][id]['data']}
    end
  else
    if (ends_with(id,"2")) then
      allObjects = {EVERYTHING["Decks"]['Refill Card']['data'],EVERYTHING["Decks"][id]['data']}
    else
      allObjects = {EVERYTHING["Decks"]['Refill Card']['data'],EVERYTHING["Decks"]["Dominance Track Card"]['data'],EVERYTHING["Decks"][id]['data']}
    end
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
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

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






function toggleTool(player,value,id)
  local guid = ""

  if id == "Supply Knight" then guid = "740edf" end
  -- Ginso's Gizmo deliberately has NO branch here: the gizmo is no longer an OBJECT at all. Its script
  -- is ported into this board (see the gizmo section at the end of this file), so its NUMPAD hotkeys
  -- work with nothing on the table.

  for i, object in pairs(getObjects()) do
    if (object.getGUID() == guid) then
      object.destruct()
      return
    end
  end

  makeTool(player,value,id)

end




function makeTool(player,value,id)
  local my_rot = self.getRotation()
  local objects = {}
  objects = EVERYTHING["Tools"][id]['data']
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

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






function makeBattleMat(player,value,id)
  -- tagged "Map Object" so it is cleared by removeMapItems on the next map placement, exactly
  -- like the mat rttPlaceMap spawns. Without the tag the tool-spawned mat survived the clear and
  -- a second mat spawned on top of it. toggleSpecial (inside makeSpecial) keeps the click-to-remove.
  makeSpecial("Tools","Battle Mat",33.17,1.55,9.21,nil,"Map Object")
end





function makeLizardWizard(player,value,id)
  makeSpecial("Tools","Lizard Wizard",-29.79-0.73,1.55,10.03,180)
  summonLizardBlocker()
end

function makeDarkDeckSpecials()
  makeSpecialWithTag("Tools","Dark Side Card",31.6,1.55,22.57,"Deck Object")
  makeSpecialWithTag("Tools","Dark Deck Box",-71.18,1.56,9.24,"Deck Object")
  makeSpecialWithTag("Decks","Dark Deck Instructions",-41.84,1.7,-16.69,"Deck Object")
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
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

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
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

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
RTT_CLONES = {}
RTT_PICKED = { map = nil, deck = nil }
RTT_PICK_STAGE = 0
RTT_SOLO = false
RTT_SELECTOR_JSON = [===[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.56,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":15.5,"scaleY":1.0,"scaleZ":15.5},"Nickname":"","Description":"","GMNotes":"","Locked":true,"Grid":false,"Snap":false,"IgnoreFoW":false,"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/board/board_clean_v4.png","ImageSecondaryURL":"https://steamusercontent-a.akamaihd.net/ugc/1725416402718254700/C6F00394AFEE245DFFA53CD358F5F966AA754BC9/","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}},"LuaScript":"RTT_COORD_GUID = \"bab7e1\"\nfunction rttPickRelay(player, value, id)\n  local c = getObjectFromGUID(RTT_COORD_GUID)\n  if c ~= nil then c.call(\"rttCoordPick\", { color = player.color, id = id }) end\nend\nfunction rttFacRelay(player, value, id)\n  local c = getObjectFromGUID(RTT_COORD_GUID)\n  if c ~= nil then c.call(\"rttCoordFaction\", { color = player.color, id = id, board = self.getGUID() }) end\nend","XmlUI":"<ToggleGroup id=\"rttPickMapDeck\" active=\"false\"><Text id=\"rttPickTitle\" text=\"\" position=\"0 60 -20\" width=\"240\" height=\"14\" fontSize=\"11\" color=\"#f3e9cf\"/><Button id=\"rttPickMap1\" onclick=\"rttPickRelay\" icon=\"Autumn Map\"   color=\"#4b4d35\" position=\"-40 34 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickMap2\" onclick=\"rttPickRelay\" icon=\"Winter Map\"   color=\"#6b8a8f\" position=\"0 34 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickMap3\" onclick=\"rttPickRelay\" icon=\"Lake Map\"     color=\"#42a0c2\" position=\"40 34 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickMap4\" onclick=\"rttPickRelay\" icon=\"Marsh Map\"    color=\"#9b8551\" position=\"-40 -2 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickMap5\" onclick=\"rttPickRelay\" icon=\"Mountain Map\" color=\"#764a52\" position=\"0 -2 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickMap6\" onclick=\"rttPickRelay\" icon=\"Gorge Map\"    color=\"#61746b\" position=\"40 -2 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickDeck1\" onclick=\"rttPickRelay\" icon=\"Standard Deck\"              color=\"#8d7f81\" position=\"-40 -38 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickDeck2\" onclick=\"rttPickRelay\" icon=\"Exiles and Partisans Deck\"  color=\"#378f90\" position=\"0 -38 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/><Button id=\"rttPickDeck3\" onclick=\"rttPickRelay\" icon=\"Squires and Disciples Deck\" color=\"#AB6894\" position=\"40 -38 -20\" width=\"34\" height=\"34\" fontSize=\"8\"/></ToggleGroup><ToggleGroup id=\"rttFactions\" active=\"false\"><Text id=\"rttFacTitle\" text=\"\" position=\"0 64 -20\" width=\"260\" height=\"26\" fontSize=\"20\" color=\"#f3e9cf\"/><Button id=\"rttFac1\" onclick=\"rttFacRelay\" position=\"-46 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac2\" onclick=\"rttFacRelay\" position=\"0 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac3\" onclick=\"rttFacRelay\" position=\"46 30 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac4\" onclick=\"rttFacRelay\" position=\"-46 -18 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac5\" onclick=\"rttFacRelay\" position=\"0 -18 -20\" width=\"42\" height=\"42\"/><Button id=\"rttFac6\" onclick=\"rttFacRelay\" position=\"46 -18 -20\" width=\"42\" height=\"42\"/></ToggleGroup>","CustomUIAssets":[{"Type":0,"Name":"Marquise de Cat","URL":"https://steamusercontent-a.akamaihd.net/ugc/1861696999739429295/F6CF523AAA7DCC91AF3812339EBB3354F6D9891A/"},{"Type":0,"Name":"Eyrie Dynasties","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755958213/960DFA43E52D99A3250863FC63F3BA3AE5104325/"},{"Type":0,"Name":"Woodland Alliance","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755956632/E99D3C9B246A94F6A898EC0D8098A05FA9467473/"},{"Type":0,"Name":"The Lizard Cult","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755960838/D88CBE9192488A678AF3EC6DFC45B4C728C9A169/"},{"Type":0,"Name":"Riverfolk Company","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755963912/C9589D96259534C6FB15DD91F78E7E90A073FDD8/"},{"Type":0,"Name":"Underground Duchy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755961872/1E2748C8EDD0BDE039B81658AFD0B19C771569BD/"},{"Type":0,"Name":"Corvid Conspiracy","URL":"https://steamusercontent-a.akamaihd.net/ugc/1728793291755959858/69B8EC707AD26EF2F558ACAB65B39163B812D3F6/"},{"Type":0,"Name":"Lord of the Hundreds","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818578726/CE952087E18A1C0B6B94E44EF53EB009A97A7122/"},{"Type":0,"Name":"Keepers in Iron","URL":"https://steamusercontent-a.akamaihd.net/ugc/1833522185818579404/C0D7197A109DBF0C2EFB34DF50AE2CA70A66C25B/"},{"Type":0,"Name":"Twilight Council","URL":"https://steamusercontent-a.akamaihd.net/ugc/2452866064845174396/6228F6A71DDC36CD883777CA958857CB123D7ECB/"},{"Type":0,"Name":"Lilypad Diaspora","URL":"https://steamusercontent-a.akamaihd.net/ugc/2508034524425991747/77C277526C0042FE2754C83836A1E2C3C03FAD38/"},{"Type":0,"Name":"Knaves of the Deepwood","URL":"https://steamusercontent-a.akamaihd.net/ugc/14468202139363768412/1012F7145C45B86F395C099B9AE80EA536529DD3/"},{"Type":0,"Name":"Autumn Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/9338841708247799860/688C6CB9F5A34B2A2B067C6DA493AD653B7D9C6A/"},{"Type":0,"Name":"Winter Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/12863190738702993416/F9C676622A48D6E15BB3AE235E26CE7BC8D11283/"},{"Type":0,"Name":"Lake Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/11224158918879846636/C034E1855CED11FD28D76E3020D629478FABD195/"},{"Type":0,"Name":"Mountain Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/17146621840035729417/55256EFBD832F89B16ADAF98A382D4BF09162487/"},{"Type":0,"Name":"Marsh Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/12189840401890527004/1A5500DF801E01874A28C059E04D049043948426/"},{"Type":0,"Name":"Gorge Map","URL":"https://steamusercontent-a.akamaihd.net/ugc/17163206417596942920/65DEC204EF54C27F6BAFE8202D3AE63F73D28DD3/"},{"Type":0,"Name":"Standard Deck","URL":"https://steamusercontent-a.akamaihd.net/ugc/1791848789393178780/9438FC204F346D081D3E66A95BBEAC918288004A/"},{"Type":0,"Name":"Exiles and Partisans Deck","URL":"https://steamusercontent-a.akamaihd.net/ugc/1791848789393180099/504416827060BE54A0038F2C9BCF5D5A9475367F/"},{"Type":0,"Name":"Squires and Disciples Deck","URL":"https://steamusercontent-a.akamaihd.net/ugc/16423108253239612/4B2CC3EBFD87C25AD92E61110CF80A5C0E461BD6/"}],"Tags":["RTT Selector"]}]===]
RTT_BOXSCORE_JSON = [====[{"Name":"BlockSquare","Transform":{"posX":0.0,"posY":2.0,"posZ":0.0,"rotX":0.0,"rotY":270.0,"rotZ":0.0,"scaleX":33.18,"scaleY":0.18,"scaleZ":9.07},"Nickname":"Root Box Score","Description":"Automatic box score for Root - Ultimate Collection.\nReads each faction's VP marker on the map's score track and records a per-round box score, following the TTS turn system. The INFO button on the sheet is the manual.","GMNotes":"","AltLookAngle":{"x":0.0,"y":180.0,"z":0.0},"ColorDiffuse":{"r":0.17,"g":0.1,"b":0.05},"Locked":false,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":false,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"LuaScript":"-- Root Box Score\n-- Automated per-turn scorekeeping for Root - Ultimate Collection (workshop 2516434159).\n--\n-- Score reading (no vision): every faction's VP marker is a named object\n-- (\"Marquise VP\", ...). The map token carries the printed 0-30 track as snap\n-- points (31 columns x 3 sub-rows on every map checked), found geometrically\n-- in the map's LOCAL coordinates - any map, anywhere, any rotation. A marker's\n-- score is the nearest track column to positionToLocal(marker position).\n--\n-- Turn integration: row order follows each faction's physical seat position, the\n-- active faction follows Turns.turn_color, and every turn pass locks the score\n-- of the faction whose turn just ended. RTT publishes faction-keyed seats; other\n-- tables fall back to the faction supply/board anchor itself. Hand zones are used\n-- only to associate factions with player colors and live display names. Without\n-- the turn system, END TURN cycles the rows manually.\n--\n-- The object IS the sheet: the walnut slab resizes itself to exactly match\n-- the rendered scoresheet (TTS object UI renders at 250 px per world unit),\n-- and every non-interactive element lets clicks through, so grabbing anywhere\n-- that is not a button drags the cardboard.\n--\n-- Silent by design: nothing is written to chat in normal play. DIAGNOSE\n-- (right-click menu) is the only thing that ever broadcasts.\n\n------------------------------------------------------------------ constants --\nlocal BUILD = \"b03.2026\"\n-- log() is NOT editor-only: it also lands in the in-game chat log, so every\n-- debug message must stay behind this gate (the sheet is silent by contract).\n-- Flip at runtime with boxDebug(true) over the External Editor API.\nlocal DEBUG = false\nlocal function dbg(m) if DEBUG then log(m) end end\nfunction boxDebug(v)\n  if type(v) == \"table\" then v = v[1] end\n  DEBUG = (v == true)\nend\nlocal POLL_SECONDS   = 1.2\nlocal SNAP_MIN       = 40\nlocal ROW_TOL        = 0.13\nlocal COL_TOL        = 0.45\nlocal MIN_CELLS      = 28\nlocal MAX_CELLS      = 60\nlocal PX_PER_UNIT    = 100    -- TTS object-UI render density (measured on a\n                              -- live table: the sheet drew 2.5x larger than a\n                              -- slab sized with the documented 250)\nlocal BASE_SCALE     = 5.4    -- sheet size multiplier at size 1.0\n\n-- NO custom font: TTS setCustomAssets only accepts image formats, so a .ttf is rejected with\n-- \"Load image failed unsupported format: UNKNOWN\" on every rebuild.\n-- palette: walnut board, parchment sheet, ink, rust and wax-seal gold\nlocal WALNUT  = \"#2B1A0C\"\nlocal PARCH   = \"#F1E5C8\"\nlocal PARCH2  = \"#E7D8B4\"\nlocal GOLD    = \"#C9A05C\"\nlocal GOLDHI  = \"#E4C88E\"\nlocal INKTXT  = \"#26170B\"\nlocal RUST    = \"#7E4A1E\"\n\nlocal DECKS = { \"Base Deck\", \"Exiles and Partisans\", \"Squires and Disciples\" }\n\n-- Every standard dominance card in the mod is a Card named \"Dominance\" whose\n-- description is its suit. Frog dominance cards also exist, but Root's normal\n-- VP-marker dominance play uses only these four suits.\nlocal DOM_SUITS = { fox = true, mouse = true, rabbit = true, bird = true }\n\n-- the group's map pool, offered as one-click chips in setup\nlocal MAPS = { \"Summer\", \"Winter\", \"Lake\", \"Mountain\", \"Marsh\", \"Gorge\" }\n\n-- card-back artwork -> deck (extracted from the mod's own deck definitions)\nlocal DECK_BACKS = {\n  [\"CAF7209CF51CE857\"] = \"Base Deck\",\n  [\"2EEC952526C7E80D\"] = \"Exiles and Partisans\",\n  [\"CD47EFAA7F885F2A\"] = \"Squires and Disciples\",\n}\n\n-- vagabond characters / captains, for the per-row variant auto-detect\nlocal CHARS = { \"Thief\", \"Tinker\", \"Ranger\", \"Vagrant\", \"Arbiter\", \"Scoundrel\",\n  \"Adventurer\", \"Ronin\", \"Harrier\", \"Jailor\", \"Cheat\", \"Gladiator\" }\n\n-- which factions carry a pickable detail, and its options\nlocal LEADERS = { \"Builder\", \"Charismatic\", \"Commander\", \"Despot\" }\nlocal function variantOptions(fac)\n  if fac == \"Eyrie\" then return LEADERS end\n  if fac == \"Vagabond\" or fac == \"Knaves\" then return CHARS end\n  return nil\nend\n\n-- toggle one item inside a comma-joined selection, keeping the list's order\nlocal function toggleCSV(csv, item, order)\n  local set = {}\n  for w in (csv or \"\"):gmatch(\"[^,]+\") do\n    set[w:match(\"^%s*(.-)%s*$\")] = true\n  end\n  if set[item] then set[item] = nil else set[item] = true end\n  local out = {}\n  for _, c in ipairs(order) do\n    if set[c] then table.insert(out, c) end\n  end\n  return table.concat(out, \", \")\nend\n\n-- the full faction roster (short names = VP marker names in the mod)\nlocal ROSTER = { \"Marquise\", \"Eyrie\", \"Alliance\", \"Vagabond\", \"Riverfolk\",\n  \"Lizard\", \"Duchy\", \"Crows\", \"Rats\", \"Badgers\", \"Knaves\", \"Council\", \"Diaspora\" }\n\n-- image-URL tail -> map name (extracted from the mod's own content registry)\nlocal MAP_NAMES = {\n  [\"gurcomPgXS0oWpng\"] = \"Tidal Flats\",   [\"BC18C7488CACA234\"] = \"Blighted City\",\n  [\"gurcombfYkkjcpng\"] = \"Mountainside\",  [\"FEDD130951792687\"] = \"River Town\",\n  [\"05CCC6DAE105DB80\"] = \"Taiga\",         [\"F09464EE61C0DEF8\"] = \"Gloom\",\n  [\"3FE895F51EC40B24\"] = \"Autumn\",        [\"7210583BE261317B\"] = \"Summer\",\n  [\"06452B5C93B62E68\"] = \"Winter\",        [\"4CFA846E1B68EB75\"] = \"Lake\",\n  [\"93D8213D360FBA8F\"] = \"Mountain\",      [\"5F33E4FEEE8089AB\"] = \"The Deep Woods\",\n  [\"664D1C3ABA5F3913\"] = \"The Wastelands\",[\"9BE9CA5E53B4C887\"] = \"Gorge\",\n  [\"D75950B3E5643325\"] = \"Gorge\",         [\"2D67B5C0F7D82E46\"] = \"Treasure Island\",\n  [\"3BBF750AB82C04EE\"] = \"Narrows and Islets\", [\"C2F717CB7259B659\"] = \"Australia\",\n  [\"27FB3B5790E593C9\"] = \"Tunnel Unraveled\",   [\"3AFD6922B0E9466F\"] = \"Tropics\",\n  [\"E183A0B6769D4C69\"] = \"Marsh\",         [\"7C8340140D11A8F2\"] = \"Lost Woodland\",\n  [\"D17AC01A7B9FA8C4\"] = \"Legends\",       [\"EF774E3AECED67F1\"] = \"Urban\",\n  [\"6A1B83F0415249F8\"] = \"Inferno\",       [\"A21F7344C4FEF62D\"] = \"Spaceballs\",\n  [\"78DE2047BA1B663E\"] = \"Blighted Grove\",\n}\n\n-- Whether attached UI inherits the object's scale is machine-dependent; both\n-- interpretations ship (right-click \"panel scale mode\" toggles). Mode 1\n-- (inherit) is the default and self-cancels so the sheet always matches the\n-- slab the script sizes for itself.\nlocal UI_POSES = {\n  { pos = \"0 0 -60\", rot = \"0 0 0\" },\n  { pos = \"0 0 -60\", rot = \"0 0 180\" },\n  { pos = \"0 0 -60\", rot = \"180 180 0\" },\n  { pos = \"0 0 -60\", rot = \"180 180 180\" },\n}\n-- 100% preserves the sheet's historical default footprint (the old size index\n-- used 0.7).  The legacy values remain only to migrate existing saved sheets.\nlocal LEGACY_SIZE_MULS = { 0.55, 0.7, 0.85, 1.05, 1.3, 1.6 }\nlocal LEGACY_BASE_MUL = 0.7\nlocal SIZE_MIN_PCT, SIZE_MAX_PCT = 50, 200\n\n----------------------------------------------------------------------- state --\nlocal S = {\n  rows      = {},   -- { fac, player, nameAuto, color, tintHex, iconUrl, guid,\n                    --   score, locks={}, edits={},\n                    --   dom={turn,round,suit,score,won,kind,frozen,markerGuid} }\n  active    = 1,\n  turns     = 0,\n  -- One-shot latch: until a turn is actually recorded the pointer is held on\n  -- the FIRST SEAT. Cleared by the first lock or by any explicit pointer move\n  -- (row select / undo), never re-armed mid-game. Persisted with the rest of S,\n  -- so a pre-first-turn save reloads still pinned and an older save reads nil\n  -- (falsy) and is correctly left alone.\n  pinFirst  = true,\n  cols      = 10,   -- round columns always shown: fixed size during the game,\n                    -- growing only past round 10 (setup-editable)\n  flip      = false,\n  hidden    = false,\n  setup     = false,\n  pose      = 1,\n  scaleMode = 1,\n  sizePct   = 100,\n  meta      = { map = \"\", deck = \"\", hook = \"\", thread = \"\", game = \"\" },\n  unpicked  = {},   -- fac -> true (picked by hand from the roster)\n  unpickedVar = {}, -- fac -> \"cap1, cap2\" (captains available in the draft)\n  varRow    = 1,\n  experimental = false,\n  lastExport = \"\",\n  log       = {},\n  undo      = {},   -- faction NAMES (row order can change underneath)\n}\n\nlocal TRACK = nil\nlocal lastTrackLogged = nil\nlocal pollCount = 0\n\n------------------------------------------------------------------- utilities --\nlocal function now() return os.time() end\n\nlocal function clampSizePct(value)\n  return math.max(SIZE_MIN_PCT, math.min(SIZE_MAX_PCT,\n    math.floor((tonumber(value) or 100) + 0.5)))\nend\n\n-- RTT destroys and recreates the sheet when its map/ranked/tool buttons spawn\n-- one.  The saved S.sizePct handles normal reloads; this Global is only the\n-- in-session hand-off between the old object and its freshly spawned copy.\nlocal function rememberSizePct()\n  pcall(function() Global.setVar(\"RTT_BOXSCORE_SIZE_PCT\", S.sizePct) end)\nend\n\nlocal function logev(ev, fac, a, b)\n  table.insert(S.log, { t = now(), ev = ev, fac = fac, a = a, b = b })\n  if #S.log > 3000 then table.remove(S.log, 1) end\nend\n\nlocal function esc(s)\n  -- No ampersand survives TTS's XML pipeline (&amp; and &#38; both render as\n  -- literal \"&amp;\", raw & is a parse error) - substitute \"+\" and be done\n  s = tostring(s or \"\")\n  s = s:gsub(\"&\", \"+\"):gsub(\"<\", \"&#60;\"):gsub(\">\", \"&#62;\"):gsub('\"', \"&#34;\")\n  return s\nend\n\nlocal function spaced(s)\n  return (s:gsub(\"(.)\", \"%1 \"):gsub(\" $\", \"\"))\nend\n\nlocal function tintHex(o)\n  local ok, c = pcall(function() return o.getColorTint() end)\n  if not ok or c == nil then return \"888888\" end\n  return string.format(\"%02X%02X%02X\",\n    math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))\nend\n\nlocal function markerImage(o)\n  local ok, co = pcall(function() return o.getCustomObject() end)\n  if not ok or co == nil then return nil end\n  return co.image or co.face or co.diffuse\nend\n\nlocal function urlTail(u)\n  if u == nil then return \"\" end\n  u = u:gsub(\"[^A-Za-z0-9]\", \"\")\n  return u:sub(-16)\nend\n\nlocal function turnsRunning()\n  return Turns.enable and Turns.order ~= nil and #Turns.order > 0\nend\n\n-- TTS exposes the active color but no monotonic turn number. S.turns is the\n-- persisted count of completed turns, so the turn in progress is the next one.\nlocal function currentTurnNumber()\n  return math.max(1, math.floor(tonumber(S.turns) or 0) + 1)\nend\n\nlocal function assetName(fac)\n  return \"vp\" .. fac:gsub(\"%W\", \"\")\nend\n\n--------------------------------------------------------------- track finding --\nlocal function detectTrackOn(obj)\n  local ok, sp = pcall(function() return obj.getSnapPoints() end)\n  if not ok or sp == nil or #sp < SNAP_MIN then return nil end\n  local bandsFound = {}\n  for _, axis in ipairs({ \"x\", \"z\" }) do\n    local other = (axis == \"x\") and \"z\" or \"x\"\n    local pts = {}\n    for _, s in ipairs(sp) do\n      table.insert(pts, { a = s.position[axis], b = s.position[other] })\n    end\n    table.sort(pts, function(p, q) return p.b < q.b end)\n    local bands, cur = {}, {}\n    for _, p in ipairs(pts) do\n      if #cur > 0 and (p.b - cur[#cur].b) > 0.03 then table.insert(bands, cur); cur = {} end\n      table.insert(cur, p)\n    end\n    if #cur > 0 then table.insert(bands, cur) end\n    for _, band in ipairs(bands) do\n      if #band >= 25 then\n        local xs = {}\n        for _, p in ipairs(band) do table.insert(xs, p.a) end\n        table.sort(xs)\n        local diffs = {}\n        for i = 2, #xs do table.insert(diffs, xs[i] - xs[i - 1]) end\n        table.sort(diffs)\n        local s = diffs[math.ceil(#diffs / 2)]\n        local even = s > 0.01\n        if even then\n          for _, d in ipairs(diffs) do\n            local m = math.floor(d / s + 0.5)\n            if m < 1 or m > 2 or math.abs(d - m * s) > 0.25 * s then even = false end\n          end\n        end\n        if even then\n          local n = math.floor((xs[#xs] - xs[1]) / s + 0.5) + 1\n          if n >= MIN_CELLS and n <= MAX_CELLS and #xs >= 0.85 * n then\n            table.insert(bandsFound, { axis = axis, other = other,\n              a0 = xs[1], s = s, n = n, b = band[1].b })\n          end\n        end\n      end\n    end\n  end\n  if #bandsFound == 0 then return nil end\n  local best = nil\n  for _, band in ipairs(bandsFound) do\n    if best == nil then\n      best = { axis = band.axis, other = band.other, a0 = band.a0, s = band.s,\n               n = band.n, rows = { band.b } }\n    elseif band.axis == best.axis\n      and math.abs(band.s - best.s) < 0.1 * best.s\n      and math.abs(band.a0 - best.a0) < 0.5 * best.s then\n      table.insert(best.rows, band.b)\n      if band.n > best.n then best.n = band.n end\n    end\n  end\n  table.sort(best.rows)\n  -- keep the raw snap coordinates belonging to the track: markers are placed\n  -- exactly ON the mod's own snap points, so centering matches TTS snapping\n  best.pts = {}\n  local bmin, bmax = best.rows[1] - 0.05, best.rows[#best.rows] + 0.05\n  for _, s2 in ipairs(sp) do\n    local a = (best.axis == \"x\") and s2.position.x or s2.position.z\n    local b = (best.axis == \"x\") and s2.position.z or s2.position.x\n    if b >= bmin and b <= bmax then\n      table.insert(best.pts, { a = a, b = b })\n    end\n  end\n  best.guid = obj.getGUID()\n  return best\nend\n\nlocal function findTrack()\n  local best, bestSnaps = nil, 0\n  for _, o in ipairs(getAllObjects()) do\n    local ok, sp = pcall(function() return o.getSnapPoints() end)\n    if ok and sp and #sp >= SNAP_MIN and #sp > bestSnaps then\n      local t = detectTrackOn(o)\n      if t then best, bestSnaps = t, #sp end\n    end\n  end\n  TRACK = best\n  if TRACK then\n    local mapObj = getObjectFromGUID(TRACK.guid)\n    if mapObj and S.mapAuto ~= false then\n      -- read the board's identity from its artwork; a manual chip click\n      -- (uiRowBtn \"map\") turns this off for the session\n      local okc, co = pcall(function() return mapObj.getCustomObject() end)\n      local img = okc and co and (co.image or co.diffuse) or nil\n      local auto = MAP_NAMES[urlTail(img)]\n      if auto and auto ~= \"\" then S.meta.map = auto end\n    end\n    if TRACK.guid ~= lastTrackLogged then\n      lastTrackLogged = TRACK.guid\n      dbg(\"BoxScore: track on \" .. TRACK.guid .. \" axis=\" .. TRACK.axis\n        .. \" cells=\" .. TRACK.n .. \" rows=\" .. #TRACK.rows)\n    end\n  else\n    dbg(\"BoxScore: no score track found on any snap holder\")\n  end\nend\n\n---------------------------------------------------------------- score reads --\nlocal function readCell(markerObj)\n  if TRACK == nil then return nil end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then TRACK = nil; return nil end\n  if markerObj.held_by_color ~= nil then return nil end\n  local okm, moving = pcall(function() return markerObj.isSmoothMoving() end)\n  if okm and moving then return nil end\n  local lp = mapObj.positionToLocal(markerObj.getPosition())\n  local a, b = lp[TRACK.axis], lp[TRACK.other]\n  local nearRow = false\n  for _, rb in ipairs(TRACK.rows) do\n    if math.abs(b - rb) <= ROW_TOL + 0.12 then nearRow = true end\n  end\n  if not nearRow then return nil end\n  local idx = math.floor((a - TRACK.a0) / TRACK.s + 0.5)\n  if idx < 0 or idx > TRACK.n - 1 then return nil end\n  if math.abs(a - (TRACK.a0 + idx * TRACK.s)) > COL_TOL * TRACK.s then return nil end\n  return idx\nend\n\n-- Printed 0 sits at the track's MAXIMUM local coordinate (established three\n-- ways: markers parked on the printed 0 cell sit at local max; the on-table\n-- world view shows 0 bottom-left with the token's usual 180 rotation; and the\n-- map artwork places 0 at the image edge that maps to local max). So scores\n-- DESCEND along the local axis. S.flip reverses this for exotic maps only.\nlocal function cellToScore(idx)\n  if S.flip then return idx end\n  return TRACK.n - 1 - idx\nend\n\nlocal function scoreToCell(score)\n  if S.flip then return score end\n  return TRACK.n - 1 - score\nend\n\nlocal function findMarker(row)\n  local o = row.guid and getObjectFromGUID(row.guid) or nil\n  if o ~= nil and (o.getName() or \"\") == (row.fac .. \" VP\") then return o end\n  -- cached marker gone: re-find by name. Some kits spawn a spare copy (the\n  -- Vagabond's does), so prefer the one standing on the score track.\n  local loose = nil\n  for _, c in ipairs(getAllObjects()) do\n    if (c.getName() or \"\") == (row.fac .. \" VP\") then\n      if readCell(c) ~= nil then\n        row.guid = c.getGUID()\n        return c\n      end\n      if loose == nil then loose = c end\n    end\n  end\n  if loose ~= nil then row.guid = loose.getGUID() end\n  return loose\nend\n\nlocal function dominanceCardSuit(o)\n  if o == nil or (o.type ~= \"Card\" and o.tag ~= \"Card\") then return nil end\n  local okn, name = pcall(function() return o.getName() end)\n  if not okn or tostring(name or \"\"):lower() ~= \"dominance\" then return nil end\n  local okd, desc = pcall(function() return o.getDescription() end)\n  if not okd then return nil end\n  local suit = tostring(desc or \"\"):match(\"^%s*(.-)%s*$\"):lower()\n  return DOM_SUITS[suit] and suit or nil\nend\n\n-- Dominance is declared by physically putting the VP marker on the card. Use\n-- the card's live bounds (rather than CardIDs, which differ among deck copies)\n-- and require both objects to have settled before accepting the placement.\nlocal function objectSettled(o)\n  if o == nil or o.held_by_color ~= nil then return false end\n  local okm, moving = pcall(function() return o.isSmoothMoving() end)\n  if okm and moving then return false end\n  local okr, resting = pcall(function() return o.resting end)\n  if okr and resting == false then return false end\n  return true\nend\n\nlocal function markerSitsOnCard(marker, card)\n  if not objectSettled(marker) or not objectSettled(card) then return false end\n  local okb, b = pcall(function() return card.getBounds() end)\n  if not okb or b == nil or b.center == nil or b.size == nil then return false end\n  local mp = marker.getPosition()\n  local cx, cy, cz = b.center.x or b.center[1], b.center.y or b.center[2],\n    b.center.z or b.center[3]\n  local sx, sy, sz = b.size.x or b.size[1], b.size.y or b.size[2],\n    b.size.z or b.size[3]\n  if not cx or not cy or not cz or not sx or not sy or not sz then return false end\n  local dy = mp.y - cy\n  return math.abs(mp.x - cx) <= sx * 0.5 + 0.2\n    and math.abs(mp.z - cz) <= sz * 0.5 + 0.2\n    and dy >= -0.25 and dy <= math.max(3.0, sy + 2.0)\nend\n\nlocal function dominanceAt(marker, cards)\n  for _, c in ipairs(cards) do\n    if markerSitsOnCard(marker, c.obj) then return c.suit end\n  end\n  return nil\nend\n\n-- Count every copy of this faction's VP marker by settled location. This is\n-- deliberately independent of row.guid: Brazen Demagogue leaves the cached\n-- original on the score track and puts a copied marker on a dominance card.\nlocal function dominanceMarkerState(row, cards, objects)\n  local state = { domCount = 0, trackCount = 0, looseCount = 0,\n    unsettledCount = 0, suit = nil, domMarker = nil,\n    trackMarker = nil, trackIdx = nil }\n  if row == nil then return state end\n  local markerName = row.fac .. \" VP\"\n  for _, marker in ipairs(objects or getAllObjects()) do\n    if (marker.getName() or \"\") == markerName then\n      if not objectSettled(marker) then\n        state.unsettledCount = state.unsettledCount + 1\n      else\n        local suit = dominanceAt(marker, cards)\n        if suit ~= nil then\n          state.domCount = state.domCount + 1\n          if state.domMarker == nil then\n            state.domMarker, state.suit = marker, suit\n          end\n        else\n          local idx = readCell(marker)\n          if idx ~= nil then\n            state.trackCount = state.trackCount + 1\n            -- Prefer the already-cached original if more than one marker has\n            -- somehow been left on the track.\n            if state.trackMarker == nil or marker.getGUID() == row.guid then\n              state.trackMarker, state.trackIdx = marker, idx\n            end\n          else\n            state.looseCount = state.looseCount + 1\n          end\n        end\n      end\n    end\n  end\n  if state.trackMarker ~= nil then row.guid = state.trackMarker.getGUID() end\n  return state\nend\n\nlocal function dominanceFrozen(row)\n  return row ~= nil and row.dom ~= nil and row.dom.frozen ~= false\nend\n\nlocal function dominanceKindLabel(dom)\n  if dom ~= nil and dom.kind == \"brazen_demagogue\" then\n    return \"Brazen Demagogue (still scoring)\"\n  end\n  return \"standard (frozen)\"\nend\n\nlocal function registerDominance(row, state)\n  local suit = state and state.suit or nil\n  if row == nil or row.dom ~= nil or not DOM_SUITS[suit] then return false end\n  local brazen = (state.trackCount or 0) > 0\n  row.dom = { turn = currentTurnNumber(),\n    round = math.max(1, math.floor(S.turns / math.max(1, #S.rows)) + 1),\n    suit = suit, score = row.score, won = false,\n    kind = brazen and \"brazen_demagogue\" or \"standard\",\n    frozen = not brazen,\n    markerGuid = state.domMarker and state.domMarker.getGUID() or nil }\n  logev(\"dominance\", row.fac, row.dom.turn, suit)\n  return true\nend\n\nlocal function cancelDominance(row)\n  if row == nil or row.dom == nil then return false end\n  local dom = row.dom\n  -- Standard dominance restores its declaration-time score. Brazen has kept\n  -- reading the original track marker, so rewinding here would discard VP.\n  if dom.frozen ~= false then row.score = tonumber(dom.score) or row.score end\n  row.dom = nil\n  if S.winner == row.fac and S.winnerReason == \"dominance\" then\n    S.winner = nil\n    S.winnerReason = nil\n    S.winnerLock = nil\n  end\n  logev(\"dominance-undo\", row.fac, dom.turn, dom.suit)\n  return true\nend\n\n-- true = the declaration marker is still on a card; false = it settled away;\n-- nil = it is currently held/moving, so do not make a transient state change.\nlocal function dominanceMarkerActive(row, state, cards)\n  if row == nil or row.dom == nil then return false end\n  local guid = row.dom.markerGuid\n  if guid ~= nil and guid ~= \"\" then\n    local marker = getObjectFromGUID(guid)\n    if marker == nil or (marker.getName() or \"\") ~= (row.fac .. \" VP\") then\n      return false\n    end\n    if not objectSettled(marker) then return nil end\n    return dominanceAt(marker, cards) ~= nil\n  end\n  -- Migrate an already-active declaration saved by a pre-markerGuid build.\n  if state.domMarker ~= nil then\n    row.dom.markerGuid = state.domMarker.getGUID()\n    return true\n  end\n  if state.unsettledCount > 0 then return nil end\n  return false\nend\n\nlocal function syncDominance(row, cards, objects)\n  local state = dominanceMarkerState(row, cards, objects)\n  local changed = false\n  if row.dom ~= nil and dominanceMarkerActive(row, state, cards) == false then\n    changed = cancelDominance(row) or changed\n  end\n  if row.dom == nil and state.domCount > 0 then\n    changed = registerDominance(row, state) or changed\n  end\n  -- Re-classify a STILL-ACTIVE declaration when the track copy changes. Brazen Demagogue needs a marker\n  -- on the track AND one on a dominance card. If the maintainer copied a marker onto the card (registered\n  -- brazen, still scoring) and then ERASED the original track marker, it is now a STANDARD dominance play:\n  -- freeze the score and show the hyphen. The reverse (a standard play that later gains a track copy)\n  -- becomes brazen and resumes scoring.\n  if row.dom ~= nil and dominanceMarkerActive(row, state, cards) == true then\n    local wantBrazen = (state.trackCount or 0) > 0\n    if wantBrazen and row.dom.kind ~= \"brazen_demagogue\" then\n      row.dom.kind = \"brazen_demagogue\"; row.dom.frozen = false\n      changed = true; logev(\"dominance-reclass\", row.fac, \"brazen\")\n    elseif (not wantBrazen) and row.dom.kind == \"brazen_demagogue\" then\n      row.dom.score = row.score; row.dom.kind = \"standard\"; row.dom.frozen = true\n      changed = true; logev(\"dominance-reclass\", row.fac, \"standard\")\n    end\n  end\n  return state, changed\nend\n\n-- Track orientation is NOT inferred: on every map in this mod the printed 0\n-- sits at the track's minimum local coordinate and 30 at the maximum\n-- (verified against the artwork of all cached maps - the mod's authoring is\n-- uniform, matching the table rule \"bottom-left is 0, bottom-right is 30\").\n-- S.flip stays false unless manually toggled for some exotic future map.\n\n------------------------------------------------------- players and factions --\nlocal function rowByFac(fac)\n  for i, r in ipairs(S.rows) do\n    if r.fac == fac then return i end\n  end\n  return nil\nend\n\nlocal function rowByColor(color)\n  for i, r in ipairs(S.rows) do\n    if r.color == color then return i end\n  end\n  return nil\nend\n\nlocal function addRow(fac, obj)\n  table.insert(S.rows, { fac = fac, player = \"\", nameAuto = false, color = nil,\n    variant = \"\", variantAuto = true,\n    tintHex = tintHex(obj), iconUrl = markerImage(obj), guid = obj.getGUID(),\n    score = -1, locks = {}, edits = {} })\n  logev(\"join\", fac)\n  S.unpicked[fac] = nil   -- a playing faction cannot be the unpicked one\nend\n\n-- The point that marks a faction's play area: its supply bag when one\n-- exists. Some kits name theirs differently (the Rats play from the\n-- \"Hundreds Supply\", the Crows from the \"Corvid Supply\", the Badgers from\n-- the \"Keeper Supply\" - verified against the mod's own spawn data). The\n-- Vagabond has no supply at all: his FACTION BOARD anchors him, identified\n-- by its artwork since boards carry no usable name - the board never moves\n-- once set up, unlike his pawn, which wanders the map (and can do so before\n-- the VP marker ever reaches the track). The named pawn figurine\n-- (\"Vagabond - Thief\", ...) is only a last resort.\nlocal SUPPLY_ALIAS = { Rats = \"Hundreds\", Crows = \"Corvid\", Badgers = \"Keeper\" }\nlocal BOARD_ART = {\n  Vagabond = \"E9FFF39312426A1A13695C984510BB94B663436F\",\n}\n\nlocal function facAnchor(fac, byName)\n  byName = byName or {}   -- defensive: never index a nil table (audit: seat-box crash)\n  local o = byName[fac .. \" Supply\"]\n  if o == nil and SUPPLY_ALIAS[fac] ~= nil then\n    o = byName[SUPPLY_ALIAS[fac] .. \" Supply\"]\n  end\n  if o == nil and BOARD_ART[fac] ~= nil then\n    for _, c in ipairs(getAllObjects()) do\n      local img = markerImage(c)\n      -- markerImage returns NIL for anything with no custom object (a die, a bag, a scripting\n      -- zone), and nil ~= \"\" is TRUE, so this fell through to img:find and crashed the moment a\n      -- Vagabond row existed -- the only faction that reaches this branch.\n      if img ~= nil and img ~= \"\" and img:find(BOARD_ART[fac], 1, true) then\n        o = c\n        break\n      end\n    end\n  end\n  if o == nil then\n    local pre = fac .. \" - \"\n    for _, c in ipairs(getAllObjects()) do\n      local n = c.getName() or \"\"\n      if n:sub(1, #pre) == pre or n:sub(1, #pre - 1) == (fac .. \" -\") then\n        o = c\n        break\n      end\n    end\n  end\n  return o\nend\n\n-- Best effort: find the chosen vagabond character / captain card standing\n-- near the faction's supply. Fills the variant only while it is auto-managed;\n-- a hand-typed variant always wins.\nlocal function refreshVariants(byName)\n  local changed = false\n  for _, row in ipairs(S.rows) do\n    if row.variantAuto ~= false then\n      local bag = facAnchor(row.fac, byName)\n      if bag then\n        local bp = bag.getPosition()\n        local best, bestD = nil, 18 * 18\n        for _, ch in ipairs(CHARS) do\n          local o = byName[ch] or byName[\"Vagabond - \" .. ch]\n            or byName[\"Vagabond -\" .. ch]\n          if o then\n            local op = o.getPosition()\n            local dx, dz = op.x - bp.x, op.z - bp.z\n            local d = dx * dx + dz * dz\n            if d < bestD then best, bestD = ch, d end\n          end\n        end\n        if row.fac == \"Knaves\" then\n          local caps = {}\n          for _, ch in ipairs(CHARS) do\n            local o = byName[\"Captain - \" .. ch] or byName[\"Captain -\" .. ch]\n            if o then\n              local op = o.getPosition()\n              local dx, dz = op.x - bp.x, op.z - bp.z\n              if dx * dx + dz * dz < 18 * 18 then table.insert(caps, ch) end\n            end\n          end\n          best = (#caps > 0 and #caps <= 4) and table.concat(caps, \", \") or nil\n        end\n        if best and row.variant ~= best then\n          row.variant = best\n          changed = true\n        end\n      end\n    end\n  end\n  return changed\nend\n\n-- read the deck in play from the draw pile's card back; a manual chip click\n-- (uiRowBtn \"deck\") turns the automation off\nlocal function refreshDeck()\n  if S.deckAuto == false then return false end\n  -- several decks can sit on the table (draft leftovers, spares): trust the\n  -- one closest to the map, which is where the draw pile lives\n  local mapObj = TRACK and getObjectFromGUID(TRACK.guid) or nil\n  if mapObj == nil then return false end\n  local mp = mapObj.getPosition()\n  local best, bestD = nil, math.huge\n  for _, o in ipairs(getAllObjects()) do\n    if o.type == \"Deck\" then\n      local q = 0\n      pcall(function() q = o.getQuantity() end)\n      if q >= 15 then\n        local ok, data = pcall(function() return o.getData() end)\n        if ok and data and data.CustomDeck then\n          for _, cd in pairs(data.CustomDeck) do\n            local name = DECK_BACKS[urlTail(cd.BackURL)]\n            if name then\n              local op = o.getPosition()\n              local dx, dz = op.x - mp.x, op.z - mp.z\n              local d = dx * dx + dz * dz\n              if d < bestD then best, bestD = name, d end\n            end\n          end\n        end\n      end\n    end\n  end\n  if best and S.meta.deck ~= best then\n    S.meta.deck = best\n    return true\n  end\n  return false\nend\n\nlocal function seatedHands()\n  local hands = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated and p.color ~= \"Black\" and p.color ~= \"Grey\" then\n      local ok, ht = pcall(function() return p.getHandTransform() end)\n      if ok and ht then\n        table.insert(hands, { color = p.color, name = p.steam_name, pos = ht.position })\n      end\n    end\n  end\n  return hands\nend\n\n-- TTS's ten playable colors are stable even when nobody occupies them. Query\n-- each color directly: getHandTransform returns its hand-zone geometry without\n-- requiring a live Player entry. Some tables omit colors/hand zones, so every\n-- lookup is guarded. If this API yields nothing at all, retain the old live-seat\n-- behavior as a safe fallback.\nlocal PLAYER_COLORS = {\n  \"White\", \"Brown\", \"Red\", \"Orange\", \"Yellow\",\n  \"Green\", \"Teal\", \"Blue\", \"Purple\", \"Pink\",\n}\n\n-- RTT publishes each faction's exact seat position (faction id -> {x,z}) via\n-- Global \"RTT_SEAT_POS\" as factions are placed. It stays a JSON string because\n-- raw Lua tables cannot cross object-script boundaries.\nlocal function rttSeatPosMap()\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_POS\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- RTT also publishes each faction's real SEAT COLOUR (Global \"RTT_SEAT_COLOR\"), written only from its\n-- draft path where the colour is the seat's own. This is authoritative and beats the hand-zone guess\n-- below: Player[c].getHandTransform() returns a position for EVERY colour, seated or not, so the guess\n-- happily binds rows to colours nobody occupies.\nlocal function rttSeatColorMap()\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_COLOR\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- RTT also publishes WHO OWNS each faction (Global \"RTT_SEAT_PLAYER\", faction -> steam name),\n-- separately from the seat colour. The two are not the same thing: on RTT's manual 4-board path\n-- players keep the colour they joined with while the rows are coloured by SEAT, so matching a row's\n-- colour against seated players finds nobody and the row shows no name. This is authoritative for the\n-- NAME; the colour still drives the turn order.\nlocal function rttSeatPlayerMap()\n  local ok, raw = pcall(function() return Global.getVar(\"RTT_SEAT_PLAYER\") end)\n  if ok and type(raw) == \"string\" and raw ~= \"\" then\n    local ok2, m = pcall(function() return JSON.decode(raw) end)\n    if ok2 and type(m) == \"table\" then return m end\n  end\n  return nil\nend\n\n-- These color positions are only for associating a row with TTS's turn/player\n-- color. They are deliberately not an input to box-score row ordering.\nlocal function colorSeatPositions()\n  local positions, count = {}, 0\n  for _, color in ipairs(PLAYER_COLORS) do\n    local ok, ht = pcall(function() return Player[color].getHandTransform() end)\n    local pos = ok and ht and ht.position or nil\n    if pos ~= nil and pos.x ~= nil and pos.z ~= nil then\n      positions[color] = pos\n      count = count + 1\n    end\n  end\n  if count == 0 then\n    for _, h in ipairs(seatedHands()) do\n      if h.pos ~= nil and h.pos.x ~= nil and h.pos.z ~= nil then\n        positions[h.color] = h.pos\n        count = count + 1\n      end\n    end\n  end\n  return positions, count\nend\n\n-- Color -> faction: the faction's supply/board game piece remains in its player\n-- area after the VP marker moves to the score track. Match that physical anchor\n-- to the nearest color hand zone, greedily one-to-one. Live occupancy is used\n-- only to attach a Steam name; it never controls the row's color/seat.\n-- RTT uses full placement ids while box-score rows use the short VP-marker ids.\n-- Keep the direct row.fac lookup authoritative and bridge only those known names.\nlocal RTT_FACTION_ID = {\n  Marquise = \"Marquise de Cat\", Eyrie = \"Eyrie Dynasties\",\n  Alliance = \"Woodland Alliance\", Riverfolk = \"Riverfolk Company\",\n  Lizard = \"The Lizard Cult\", Duchy = \"Underground Duchy\",\n  Crows = \"Corvid Conspiracy\", Rats = \"Lord of the Hundreds\",\n  Badgers = \"Keepers in Iron\", Knaves = \"Knaves of the Deepwood\",\n  Council = \"Twilight Council\", Diaspora = \"Lilypad Diaspora\",\n}\n\n-- (moved above refreshSeats: it is a `local`, so any use EARLIER in the file resolves to a nil\n-- GLOBAL and throws 'attempt to index a nil value', killing the whole poll pass.)\nlocal function refreshSeats(byName)\n  local positions, seatCount = colorSeatPositions()\n  if seatCount == 0 then return false end\n  local liveNames = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated and p.color ~= \"Black\" and p.color ~= \"Grey\" then\n      liveNames[p.color] = p.steam_name\n    end\n  end\n  local cand, anchored = {}, {}\n  for _, row in ipairs(S.rows) do\n    local bag = facAnchor(row.fac, byName)\n    if bag then\n      anchored[row.fac] = true\n      local bp = bag.getPosition()\n      for ci, color in ipairs(PLAYER_COLORS) do\n        local pos = positions[color]\n        if pos ~= nil then\n          local dx, dz = pos.x - bp.x, pos.z - bp.z\n          table.insert(cand, { d = dx * dx + dz * dz, fac = row.fac,\n                               color = color, ci = ci })\n        end\n      end\n    end\n  end\n  table.sort(cand, function(x, y)\n    if math.abs(x.d - y.d) > 0.000001 then return x.d < y.d end\n    if x.fac ~= y.fac then return x.fac < y.fac end\n    return x.ci < y.ci\n  end)\n  local usedC, usedF, assigned, changed = {}, {}, {}, false\n  -- AUTHORITATIVE FIRST: any row RTT has named a seat colour for is bound directly, and both its colour\n  -- and its faction are marked used so the greedy geometric pass cannot reassign either.\n  local rttCol = rttSeatColorMap()\n  local rttOwner = rttSeatPlayerMap()\n  if rttCol ~= nil then\n    for _, row in ipairs(S.rows) do\n      local fid = RTT_FACTION_ID and RTT_FACTION_ID[row.fac] or nil\n      local c = rttCol[row.fac] or (fid ~= nil and rttCol[fid] or nil)\n      if c ~= nil and c ~= \"\" and not usedC[c] then\n        usedC[c], usedF[row.fac] = true, true\n        assigned[row.fac] = { fac = row.fac, color = c }\n      end\n    end\n  end\n  for _, c in ipairs(cand) do\n    if not usedC[c.color] and not usedF[c.fac] then\n      usedC[c.color], usedF[c.fac] = true, true\n      assigned[c.fac] = c\n    end\n  end\n  -- Clear a stale color only when this pass actually found the row's anchor but\n  -- could not assign it. If an anchor is temporarily absent, keep the last\n  -- known color instead of throwing away a valid physical-seat match.\n  for _, row in ipairs(S.rows) do\n    local c = assigned[row.fac]\n    if c then\n      if row.color ~= c.color then row.color = c.color; changed = true end\n      local name = liveNames[c.color]\n      local owned = rttOwner and (rttOwner[row.fac] or rttOwner[RTT_FACTION_ID[row.fac]])\n      if owned ~= nil and owned ~= \"\" then name = owned end   -- RTT knows who picked it\n      if name ~= nil and (row.player == \"\" or row.nameAuto) then\n        if row.player ~= name then row.player = name; changed = true end\n        row.nameAuto = true\n      end\n    elseif anchored[row.fac] and row.color ~= nil then\n      row.color = nil\n      changed = true\n    end\n  end\n  return changed\nend\n\nlocal function resort(cmp)\n  local activeRow = S.rows[S.active]\n  table.sort(S.rows, cmp)\n  for i, r in ipairs(S.rows) do\n    if r == activeRow then S.active = i end\n  end\nend\n\n-- The turn system can only drive the sheet when every faction row belongs to\n-- a seated color. Solo and hotseat games (one player running several\n-- factions) fall back to the manual END TURN button.\nlocal function fullTurnCoverage()\n  -- ONE rule, identical at every player count: if the TTS turn system is running\n  -- and the sheet has rows, the turn system drives the sheet. Otherwise the\n  -- manual END TURN button does.\n  --\n  -- This used to additionally require >= 2 seated players AND every row's colour\n  -- to be seated right now. Both made the behaviour depend on WHO happened to be\n  -- sitting down: a solo game (and any hotseat game where one player runs several\n  -- factions) silently fell back to manual mode, so the turn system could not be\n  -- tested or used at all, and a single disconnect mid-game flipped a running\n  -- table into a different mode. The maintainer asked for the same logic to work\n  -- the same way regardless of player count, so those two conditions are gone.\n  --\n  -- Nothing downstream needs them: followTurns() looks the turn colour up with\n  -- rowByColor and simply does nothing when there is no such row, and\n  -- onPlayerTurn still refuses to lock unless the PREVIOUS colour was really\n  -- seated -- so toggling the turn system, or TTS stepping through empty\n  -- colours, still records nothing.\n  return turnsRunning() and #S.rows > 0\nend\n\n\n-- Object-name index of each faction's supply anchor, refreshed by the poll (see ~line 1434) just\n-- before seatOrder. Declared HERE, ABOVE factionSeatPosition, so the function captures this upvalue\n-- rather than a nil GLOBAL -- otherwise the physical-anchor fallback threw 'index a nil value' on any\n-- non-RTT / Vagabond row and aborted the whole poll pass (audit: seat-box).\nlocal seatAnchorByName = {}\nlocal function factionSeatPosition(row, rtt)\n  local p = nil\n  if rtt ~= nil then p = rtt[row.fac] or rtt[RTT_FACTION_ID[row.fac]] end\n  if p ~= nil then\n    local x, z = (p[1] or p.x), (p[2] or p.z)\n    if x ~= nil and z ~= nil then return { x = x, z = z } end\n  end\n  local anchor = facAnchor(row.fac, seatAnchorByName)\n  if anchor == nil then return nil end\n  local ok, pos = pcall(function() return anchor.getPosition() end)\n  if ok and pos ~= nil and pos.x ~= nil and pos.z ~= nil then return pos end\n  return nil\nend\n\n-- (seatAnchorByName is declared above factionSeatPosition; the poll assigns it before seatOrder.)\n\n-- Row order is always physical faction-seat order, even while RTT's TTS turn\n-- system is running. The faction-keyed RTT map wins; a missing entry falls back\n-- to that row's physical faction anchor. Unknown rows stay last. Original\n-- indices make every pass stable, and the manual up-arrow disables this sorter.\nlocal function seatOrder()\n  if S.manualOrder then return false end\n  local rtt = rttSeatPosMap()\n  local before, original = {}, {}\n  local positions, seatCount = {}, 0\n  for i, r in ipairs(S.rows) do\n    before[i], original[r] = r, i\n    positions[r] = factionSeatPosition(r, rtt)\n    if positions[r] ~= nil then seatCount = seatCount + 1 end\n  end\n  if seatCount == 0 then return false end\n  resort(function(x, y)\n    local px, py = positions[x], positions[y]\n    if px == nil or py == nil then\n      if px ~= nil then return true end\n      if py ~= nil then return false end\n      return original[x] < original[y]\n    end\n    -- clockwise from directly-right (+X): seat 1 is first, proceeding to the left\n    local ax = math.atan2(-px.z, px.x); if ax < 0 then ax = ax + 2 * math.pi end\n    local ay = math.atan2(-py.z, py.x); if ay < 0 then ay = ay + 2 * math.pi end\n    if math.abs(ax - ay) > 0.000001 then return ax < ay end\n    return original[x] < original[y]\n  end)\n  for i, r in ipairs(S.rows) do\n    if before[i] ~= r then return true end\n  end\n  return false\nend\n\n-- Turns controls only the live pointer and automatic locks. It deliberately\n-- does not control row order; physical seat geometry above is authoritative.\nlocal function followTurns()\n  if not fullTurnCoverage() then return false end\n  local tc = Turns.turn_color\n  -- The FIRST turn of the game is ALWAYS the first player. Until a turn has\n  -- actually been recorded (S.turns == 0), pin the pointer to Turns.order[1]\n  -- - the first player - regardless of how late that faction's row joined the\n  -- sheet or whether turn_color was momentarily empty or nudged during setup.\n  -- Once real turns start recording, follow the live turn_color normally, so\n  -- every later round's first turn lands on the first player by itself too.\n  if (S.turns or 0) == 0 then\n    local first = Turns.order and Turns.order[1] or nil\n    if first and first ~= \"\" then tc = first end\n  end\n  if tc and tc ~= \"\" then\n    local i = rowByColor(tc)\n    if i and i ~= S.active then S.active = i; return true end\n  end\n  return false\nend\n\n-- The FIRST turn of a game belongs to the FIRST SEAT. followTurns() already\n-- says so, but its pin sits behind fullTurnCoverage() -> Turns.enable, and RTT\n-- ships the TTS turn system off, so that path never runs there. This is the\n-- manual-mode equivalent and it runs on every poll while the latch is set,\n-- which also means it self-corrects as rows appear: resort() re-pins S.active\n-- onto whichever row object it was on, and rows are appended in the order the\n-- VP markers become readable, so without this the pointer settles on the\n-- first faction DISCOVERED rather than seat 1.\n-- Target: ROW 1, and deliberately NOT a colour lookup.\n-- seatOrder() sorts rows clockwise from +X (angle = atan2(-z, x)), and RTT's\n-- seat slots are RTT_POS = {(52,-46),(-52,-46),(52,46),(-52,46)} -> angles\n-- 0.724 / 2.417 / 5.559 / 3.866, so the row order is seat 1, 2, 4, 3 and row 1\n-- is ALWAYS seat 1.\n-- An earlier version of this preferred rowByColor(Turns.order[1]) (\"Red\" =\n-- RTT's seat-1 colour) and fell back to row 1. That was WRONG and shipped a\n-- regression: row.color is assigned by refreshSeats() from the NEAREST HAND\n-- ZONE, not from RTT's seating, and rttSeatPlayers only recolours SEATED\n-- humans. With empty seats (a solo tester, or fewer humans than seats) \"Red\"\n-- binds to an arbitrary faction -- in the maintainer's 4-faction solo test the\n-- rows came out Marquise=White, Riverfolk=Red, Alliance=Orange, Duchy=Pink, so\n-- the pin jumped to Riverfolk (row 2, seat 2) instead of Marquise (row 1,\n-- seat 1). Geometry is authoritative here; colour is not.\nlocal function pinFirstSeat()\n  if not S.pinFirst or #S.rows == 0 then return false end\n  -- MANUAL MODE ONLY. When the TTS turn system is actually driving the sheet,\n  -- followTurns() owns the pointer and has its own first-player pin, and it runs\n  -- immediately before this in the poll -- so without this guard we overwrote it\n  -- every tick and the sheet stopped following turn order altogether (and\n  -- onPlayerTurn's immediate S.active was clobbered 1.2s later too). Regression\n  -- reported by the maintainer; this is the fix.\n  if fullTurnCoverage() then return false end\n  if S.active ~= 1 then S.active = 1; return true end\n  return false\nend\n\n--------------------------------------------------------------------- export --\nlocal function unpickedList()\n  local out = {}\n  for _, fac in ipairs(ROSTER) do\n    if S.unpicked[fac] == true then\n      local v = S.unpickedVar and S.unpickedVar[fac] or \"\"\n      table.insert(out, v ~= \"\" and (fac .. \" (\" .. v .. \")\") or fac)\n    end\n  end\n  return out\nend\n\nlocal function exportPayload(kind, extra)\n  local p = { type = kind, t = now(), meta = S.meta, turns = S.turns,\n              turnOrder = Turns.order, unpicked = unpickedList(),\n              unpickedVariants = S.unpickedVar, rows = {} }\n  for _, row in ipairs(S.rows) do\n    table.insert(p.rows, { faction = row.fac, player = row.player,\n      variant = row.variant, color = row.color, score = row.score,\n      locks = row.locks, edits = row.edits, crafts = row.crafts,\n      dominance = row.dom })\n  end\n  if extra ~= nil then\n    for k, v in pairs(extra) do p[k] = v end\n  end\n  return p\nend\n\n-- Post straight to a Discord webhook - no companion program needed. The URL\n-- is pasted once into EDIT's DISCORD field (or baked into GMNotes) and\n-- then travels with the object inside every save.\nlocal function postDiscord(chunks)\n  local hook = S.meta.hook or \"\"\n  if hook == \"\" or #chunks == 0 then return false end\n  local thread = (S.meta.thread or \"\"):match(\"(%d%d%d%d%d%d+)%s*$\")\n  hook = hook .. (hook:find(\"%?\") and \"&\" or \"?\") .. \"wait=true\"\n  if thread then hook = hook .. \"&thread_id=\" .. thread end\n  local idx = 0\n  local function sendNext()\n    idx = idx + 1\n    local text = chunks[idx]\n    if text == nil then\n      S.lastExport = os.date(\"%H:%M\") .. \" &#183; confirmed with Discord\"\n        .. (#chunks > 1 and (\" (\" .. #chunks .. \" msgs)\") or \"\")\n      rebuildUI()\n      return\n    end\n    local body = JSON.encode({ content = text })\n    local function report(req)\n      if req and (req.is_error or (req.response_code or 0) >= 300) then\n        S.lastExport = os.date(\"%H:%M\") .. \" &#183; Discord failed (msg \" .. idx .. \")\"\n        dbg(\"BoxScore discord error: \" .. tostring(req.error) .. \" code=\"\n          .. tostring(req.response_code) .. \" body=\" .. tostring(req.text):sub(1, 200))\n        rebuildUI()\n      else\n        sendNext()\n      end\n    end\n    local ok = pcall(function()\n      WebRequest.custom(hook, \"POST\", false, body,\n        { [\"Content-Type\"] = \"application/json\" }, report)\n    end)\n    if not ok then\n      pcall(function() WebRequest.post(hook, { content = text }, report) end)\n    end\n  end\n  sendNext()\n  return true\nend\n\n-- split lines into fenced messages under Discord's 2000-char limit\nlocal function fencedChunks(lines)\n  local chunks, cur, len = {}, {}, 0\n  for _, l in ipairs(lines) do\n    if len + #l + 10 > 1800 and #cur > 0 then\n      table.insert(chunks, \"```\\n\" .. table.concat(cur, \"\\n\") .. \"\\n```\")\n      cur, len = {}, 0\n    end\n    table.insert(cur, l)\n    len = len + #l + 1\n  end\n  if #cur > 0 then\n    table.insert(chunks, \"```\\n\" .. table.concat(cur, \"\\n\") .. \"\\n```\")\n  end\n  return chunks\nend\n\n--------------------------------------------------- experimental: crafting --\n-- Watch the craftable-item supply on the map (the edge opposite the score\n-- track). An item leaving the map = a craft: attributed to whoever carried\n-- it (or the active faction), with the VP taken from that faction's next\n-- score change within 30 seconds.\n-- craftable-item artwork -> item name (the tokens are unnamed in this mod)\nlocal ITEMS = {\n  [\"4C4E490133888321E24E3F77DC20E1A4A7369B6E\"] = \"Coins\",\n  [\"FF9D60BC2A7E6A38BE74773188B30F57C14E9FB5\"] = \"Tea\",\n  [\"366FF0B1EDD8B091B881287CF72CFBAA584B742B\"] = \"Sword\",\n  [\"0BEAA5BC0CC9AA3ADB7BEB4A59C124603DA73CD7\"] = \"Hammer\",\n  [\"639F7EE379C0EBF83B49BF9BE165BBD7345E7F5C\"] = \"Crossbow\",\n  [\"81AC7B7422C963CCFB711E0134FF957117DC1528\"] = \"Boot\",\n  [\"459F031CFC2B05BFD5597460610B20DD58D14843\"] = \"Bag\",\n}\nlocal ITEM_NAMES = { \"Coins\", \"Tea\", \"Sword\", \"Hammer\", \"Crossbow\", \"Boot\", \"Bag\" }\nlocal function itemTail(u)\n  if u == nil then return \"\" end\n  return (u:gsub(\"[^A-Za-z0-9]\", \"\")):sub(-40)\nend\n\nlocal ITEMWATCH = nil     -- guid -> { name, holder, img }\nlocal INFLIGHT = {}       -- guid -> { name, img, holder, tLeft }\nlocal SUPPLYPOS = {}      -- fac -> world position of its supply bag\nlocal CATCHUP = false     -- one adopt-existing-crafts sweep after (re)arming\n\nlocal function initItemWatch()\n  ITEMWATCH = {}\n  if TRACK == nil then return end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then return end\n  local trackB = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local count = 0\n  for _, o in ipairs(getAllObjects()) do\n    if o ~= self and o.getGUID() ~= TRACK.guid then\n      local n = o.getName() or \"\"\n      -- the item tokens are UNNAMED small tiles; named map furniture (VP\n      -- markers, ruins, landmarks) is excluded, everything else small in the\n      -- supply region is an item\n      local excluded = n:match(\" VP$\") or n:match(\"Supply$\") or n:match(\"Board$\")\n        or n == \"RUIN\" or o.type == \"Deck\" or o.type == \"Card\"\n      local sc = o.getScale()\n      if not excluded and sc.x < 1.0 then\n        local ok, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n        if ok and lp and math.abs(lp.x) < 1.95 and math.abs(lp.z) < 1.95 then\n          local b = (TRACK.axis == \"x\") and lp.z or lp.x\n          if b * trackB < 0 and math.abs(b) > 0.85 then\n            local img = markerImage(o)\n            local nm = ITEMS[itemTail(img)] or ((n ~= \"\") and n or \"Item\")\n            if ITEMS[itemTail(img)] and img ~= \"\" then S.itemImgs[nm] = img end\n            ITEMWATCH[o.getGUID()] = { name = nm, holder = nil, img = img }\n            count = count + 1\n          end\n        end\n      end\n    end\n  end\n  dbg(\"BoxScore experimental: watching \" .. count .. \" supply items\")\nend\n\n-- the item's crafting VP: the faction's first score increase since the item\n-- left the supply (the marker usually moves at craft time even when the item\n-- is moved to the board later)\nlocal function inferCraftVP(fac, tLeft)\n  for k = #S.log, 1, -1 do\n    local e = S.log[k]\n    if e.t ~= nil and e.t < tLeft then break end\n    if e.ev == \"score\" and e.fac == fac and type(e.a) == \"number\"\n      and type(e.b) == \"number\" and e.b > e.a and e.a >= 0 then\n      return e.b - e.a\n    end\n  end\n  return 0\nend\n\nlocal function inferRound(fac, t, activeFac)\n  local n = 0\n  for _, e in ipairs(S.log) do\n    if e.ev == \"lock\" and e.fac == fac and (e.t or 0) <= t then n = n + 1 end\n  end\n  if activeFac ~= nil and activeFac ~= fac then\n    -- the item moved while another faction was playing: it belongs to the\n    -- crafting faction's last noted turn, not their upcoming one\n    return math.max(1, n)\n  end\n  return n + 1\nend\n\n-- is this object back in the map's item-supply region?\nlocal function inSupplyRegion(mapObj, o)\n  if TRACK == nil then return false end\n  local ok, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n  if not (ok and lp) then return false end\n  if math.abs(lp.x) >= 1.95 or math.abs(lp.z) >= 1.95 then return false end\n  local trackB = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local b = (TRACK.axis == \"x\") and lp.z or lp.x\n  return b * trackB < 0 and math.abs(b) > 0.85\nend\n\nlocal function attributeCraft(i, entry, guid)\n  local row = S.rows[i]\n  if row == nil then return end\n  row.crafts = row.crafts or {}\n  table.insert(row.crafts, { item = entry.name, img = entry.img, guid = guid,\n    vp = inferCraftVP(row.fac, entry.tLeft),\n    r = inferRound(row.fac, entry.tLeft, entry.activeFac) })\n  if entry.img and entry.img ~= \"\" then S.itemImgs[entry.name] = entry.img end\n  logev(\"craft\", row.fac, entry.name)\n  refreshAssets()\nend\n\n-- items already sitting beside a faction board when the watch (re)starts are\n-- adopted as crafts, so late activation or missed flights still count\nlocal function catchUpCrafts(mapObj)\n  local counted = {}\n  for _, row in ipairs(S.rows) do\n    for _, c in ipairs(row.crafts or {}) do\n      if c.guid then counted[c.guid] = true end\n    end\n  end\n  for _, o in ipairs(getAllObjects()) do\n    local guid = o.getGUID()\n    if not counted[guid] and ITEMWATCH[guid] == nil and o.type == \"Tile\" then\n      local img = markerImage(o)\n      local nm = ITEMS[itemTail(img)]\n      if nm then\n        local okl, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n        local offMap = not (okl and lp and math.abs(lp.x) < 2.0 and math.abs(lp.z) < 2.0)\n        if offMap then\n          local op = o.getPosition()\n          local bestFac, bestD = nil, 30 * 30\n          for fac, sp2 in pairs(SUPPLYPOS) do\n            local dx, dz = op.x - sp2.x, op.z - sp2.z\n            local d = dx * dx + dz * dz\n            if d < bestD then bestFac, bestD = fac, d end\n          end\n          local i2 = bestFac and rowByFac(bestFac) or nil\n          if i2 then\n            attributeCraft(i2, { name = nm, img = img, tLeft = now(),\n              activeFac = S.rows[S.active] and S.rows[S.active].fac or nil }, guid)\n          end\n        end\n      end\n    end\n  end\nend\n\nfunction uiCraftMenu()\n  S.overlay = (S.overlay == \"craft\") and nil or \"craft\"\n  S.craftAdd = nil\n  S.craftPick = nil\n  rebuildUI()\nend\n\nfunction uiCraftBtn(player, _, id)\n  local i, k = id:match(\"^cfr_(%d+)_(%d+)$\")\n  if i then\n    -- clicking a craft's T# opens the round row below; clicking again closes\n    if S.craftPick ~= nil and S.craftPick.i == tonumber(i)\n      and S.craftPick.k == tonumber(k) then\n      S.craftPick = nil\n    else\n      S.craftPick = { i = tonumber(i), k = tonumber(k) }\n      S.craftAdd = nil\n    end\n    rebuildUI()\n    return\n  end\n  local pr = id:match(\"^cfpick_(%d+)$\")\n  if pr then\n    if S.craftPick ~= nil then\n      local row = S.rows[S.craftPick.i]\n      local c = row and (row.crafts or {})[S.craftPick.k] or nil\n      if c then c.r = tonumber(pr) end\n      S.craftPick = nil\n    end\n    rebuildUI()\n    return\n  end\n  i, k = id:match(\"^cfx_(%d+)_(%d+)$\")\n  if i then\n    local row = S.rows[tonumber(i)]\n    if row and row.crafts then\n      table.remove(row.crafts, tonumber(k))\n      refreshAssets()\n    end\n    rebuildUI()\n    return\n  end\n  i = id:match(\"^cfadd_(%d+)$\")\n  if i then\n    S.craftAdd = (S.craftAdd == tonumber(i)) and nil or tonumber(i)\n    S.craftPick = nil\n    rebuildUI()\n    return\n  end\n  k = id:match(\"^cfnew_(%d+)$\")\n  if k then\n    local row = S.rows[S.craftAdd or 0]\n    local nm = ITEM_NAMES[tonumber(k)]\n    if row and nm then\n      row.crafts = row.crafts or {}\n      table.insert(row.crafts, { item = nm, img = S.itemImgs[nm] or \"\",\n        vp = 0, r = math.floor(S.turns / math.max(1, #S.rows)) + 1 })\n      logev(\"craft\", row.fac, nm)\n      S.craftAdd = nil\n      refreshAssets()\n    end\n    rebuildUI()\n  end\nend\n\nfunction uiExperimental()\n  S.experimental = not S.experimental\n  ITEMWATCH = nil\n  INFLIGHT = {}\n  if S.overlay == \"craft\" then S.overlay = nil end\n  rebuildUI()\nend\n\n------------------------------------------------------------------- the poll --\nlocal dirty = false\n\n-- forward declaration, so anything above lockRow's definition can call it\nlocal lockRow\n\nlocal function poll()\n  pollCount = pollCount + 1\n  -- Track detection does no steady-state work. The every-poll scan runs\n  -- only until the first map is found; afterwards the sole periodic cost\n  -- is one object lookup every 25th poll, and a full re-detection happens\n  -- only when the mapped object has actually been deleted (a map swap).\n  -- A stale map NAME is acceptable - the MAP chip in EDIT corrects it.\n  if TRACK ~= nil and pollCount % 25 == 0\n    and getObjectFromGUID(TRACK.guid) == nil then\n    TRACK = nil\n  end\n  if TRACK == nil then\n    findTrack()\n    if TRACK ~= nil then dirty = true end\n  end\n  if TRACK == nil then return end\n\n  local objects = getAllObjects()\n  local domCards = {}\n  local vpMarkers = {}\n  for _, o in ipairs(objects) do\n    local n = o.getName() or \"\"\n    local fac = n:match(\"^(.+) VP$\")\n    if fac then\n      vpMarkers[fac] = vpMarkers[fac] or {}\n      table.insert(vpMarkers[fac], o)\n      if rowByFac(fac) == nil and readCell(o) ~= nil then\n        addRow(fac, o)\n        refreshAssets()\n        dirty = true\n      end\n    end\n    local suit = dominanceCardSuit(o)\n    if suit then table.insert(domCards, { obj = o, suit = suit }) end\n  end\n\n  -- PRUNE rows whose VP marker no longer exists. The sheet's memory must FOLLOW THE TABLE: rows were\n  -- only ever added, never removed, and S is persisted whole (onSave encodes S, onLoad replaces it), so\n  -- loading an old save re-imported every faction it had ever seen and a reset left the sheet still\n  -- believing in markers that were gone -- which is also why VP positions came out in odd slots. The\n  -- maintainer: \"the only memory of which factions are present should be the vp score markers on the\n  -- board\". A row with no guid was added by hand in EDIT mode and is never pruned; a held or moving\n  -- marker still resolves, so only a genuinely destroyed one prunes.\n  -- A faction leaves in more ways than its marker being destroyed: bagged, or removed while a\n  -- spare same-named marker survives, which findMarker re-points row.guid at. Prune on whether the\n  -- FACTION is present at all, over two polls so a held marker never drops a row.\n  local present, presentObj = {}, {}\n  for _, o in ipairs(getAllObjects()) do\n    local n = o.getName() or \"\"\n    if n ~= \"\" then present[n] = true; if presentObj[n] == nil then presentObj[n] = o end end\n  end\n  for i = #S.rows, 1, -1 do\n    local r = S.rows[i]\n    local guidGone = r.guid ~= nil and r.guid ~= \"\" and getObjectFromGUID(r.guid) == nil\n    local vpName   = (RTT_VP_SHORT and RTT_VP_SHORT[r.fac] or r.fac) .. \" VP\"\n    local factionGone = (not present[vpName]) and facAnchor(r.fac, presentObj) == nil\n    if factionGone then r.gone = (r.gone or 0) + 1 else r.gone = 0 end\n    if guidGone or (r.guid ~= nil and r.guid ~= \"\" and r.gone >= 2) then\n      logev(\"leave\", r.fac)\n      table.remove(S.rows, i)\n      if S.active > #S.rows then S.active = math.max(1, #S.rows) end\n      dirty = true\n    end\n  end\n\n  for _, row in ipairs(S.rows) do\n    -- Count all same-faction copies. The declaration follows its specific\n    -- settled card marker; held/moving markers cause no transient change.\n    local markerState, domChanged = syncDominance(row, domCards,\n      vpMarkers[row.fac] or {})\n    if domChanged then dirty = true end\n    -- Standard dominance freezes. Brazen keeps reading the separate settled\n    -- marker on the VP track and locks ordinary numeric scores.\n    local idx = (not dominanceFrozen(row)) and markerState.trackIdx or nil\n    if idx ~= nil then\n      local sc = cellToScore(idx)\n      if sc ~= row.score then\n        logev(\"score\", row.fac, row.score, sc)\n        row.score = sc\n        dirty = true\n      end\n      -- Reaching 30 ends the game: the 30 is printed into the CURRENT\n      -- round column and the world stops - the turn does NOT pass, the\n      -- pointer does not move, nothing locks any more. Moving that marker\n      -- off 30 to a lower score means it was a mistake: the cell returns\n      -- to exactly what it held before and play resumes.\n      if S.winner == nil and sc >= 30 then\n        local r = math.max(1, math.floor(S.turns / math.max(1, #S.rows)) + 1)\n        S.winnerLock = { fac = row.fac, r = r,\n          prevLock = row.locks[r], prevEdit = row.edits[tostring(r)] }\n        row.edits[tostring(r)] = nil\n        while #row.locks < r - 1 do table.insert(row.locks, -1) end\n        row.locks[r] = sc\n        S.winner = row.fac\n        S.winnerReason = \"score\"\n        logev(\"gameover\", row.fac, r, sc)\n        dirty = true\n      elseif S.winner == row.fac and S.winnerLock ~= nil and sc < 30 then\n        local wl = S.winnerLock\n        if wl ~= nil and wl.fac == row.fac then\n          if wl.prevLock ~= nil then\n            row.locks[wl.r] = wl.prevLock\n          else\n            row.locks[wl.r] = -1\n            while #row.locks > 0\n              and (row.locks[#row.locks] == -1 or row.locks[#row.locks] == nil) do\n              table.remove(row.locks)\n            end\n          end\n          if wl.prevEdit ~= nil then row.edits[tostring(wl.r)] = wl.prevEdit end\n        end\n        S.winner = nil\n        S.winnerReason = nil\n        S.winnerLock = nil\n        logev(\"resume\", row.fac)\n        dirty = true\n      end\n    end\n  end\n\n  if S.experimental and TRACK ~= nil then\n    if ITEMWATCH == nil then\n      initItemWatch()\n      CATCHUP = true\n    end\n    local mapObj = getObjectFromGUID(TRACK.guid)\n    -- the catch-up sweep needs the supply anchors, which fill on the first\n    -- fifth-poll scan; run it once they exist\n    if CATCHUP and mapObj and ITEMWATCH and next(SUPPLYPOS) ~= nil then\n      catchUpCrafts(mapObj)\n      CATCHUP = false\n      dirty = true\n    end\n    if mapObj and ITEMWATCH then\n      for guid, w in pairs(ITEMWATCH) do\n        local o = getObjectFromGUID(guid)\n        if o ~= nil and o.held_by_color ~= nil then w.holder = o.held_by_color end\n        local gone = (o == nil)\n        if not gone then\n          local okl, lp = pcall(function() return mapObj.positionToLocal(o.getPosition()) end)\n          if okl and lp and (math.abs(lp.x) > 2.1 or math.abs(lp.z) > 2.1) then gone = true end\n        end\n        if gone then\n          ITEMWATCH[guid] = nil\n          INFLIGHT[guid] = { name = w.name, img = w.img, holder = w.holder,\n            tLeft = now(),\n            activeFac = S.rows[S.active] and S.rows[S.active].fac or nil }\n          dbg(\"EXP leave: \" .. w.name .. \" \" .. guid)\n        end\n      end\n      -- a crafted item put BACK in the supply was a mistake: undo the craft\n      -- and watch the item again as if it had never been taken\n      for _, row in ipairs(S.rows) do\n        if row.crafts then\n          for ci3 = #row.crafts, 1, -1 do\n            local c = row.crafts[ci3]\n            if c.guid then\n              local o2 = getObjectFromGUID(c.guid)\n              if o2 and o2.held_by_color == nil and inSupplyRegion(mapObj, o2) then\n                logev(\"uncraft\", row.fac, c.item)\n                table.remove(row.crafts, ci3)\n                ITEMWATCH[c.guid] = { name = c.item, holder = nil, img = c.img }\n                dirty = true\n              end\n            end\n          end\n        end\n      end\n      -- items in flight settle where they were crafted: the faction board\n      -- whose supply they end up beside claims them\n      for guid, fl in pairs(INFLIGHT) do\n        local o = getObjectFromGUID(guid)\n        if o ~= nil then\n          if o.held_by_color ~= nil then fl.holder = o.held_by_color end\n          if o.held_by_color == nil and inSupplyRegion(mapObj, o) then\n            -- returned to the supply: never crafted\n            INFLIGHT[guid] = nil\n            ITEMWATCH[guid] = { name = fl.name, holder = nil, img = fl.img }\n          elseif o.held_by_color == nil then\n            local op = o.getPosition()\n            local bestFac, bestD = nil, 30 * 30\n            for fac, sp2 in pairs(SUPPLYPOS) do\n              local dx, dz = op.x - sp2.x, op.z - sp2.z\n              local d = dx * dx + dz * dz\n              if d < bestD then bestFac, bestD = fac, d end\n            end\n            dbg(\"EXP inflight \" .. guid .. \" bestFac=\" .. tostring(bestFac)\n              .. \" supplies=\" .. tostring((function() local c = 0\n                for _ in pairs(SUPPLYPOS) do c = c + 1 end\n                return c end)()))\n            if bestFac then\n              local i2 = rowByFac(bestFac)\n              if i2 then\n                INFLIGHT[guid] = nil\n                attributeCraft(i2, fl, guid)\n                dirty = true\n              end\n            elseif now() - fl.tLeft > 300 then\n              INFLIGHT[guid] = nil\n            end\n          end\n        else\n          -- object vanished (bagged): fall back to whoever carried it last\n          INFLIGHT[guid] = nil\n          local i2 = fl.holder and rowByColor(fl.holder) or nil\n          if i2 then\n            attributeCraft(i2, fl, guid)\n            dirty = true\n          end\n        end\n      end\n    end\n  end\n\n  if pollCount % 5 == 1 then\n    local byName = {}\n    for _, o in ipairs(getAllObjects()) do\n      byName[o.getName() or \"\"] = o\n    end\n    SUPPLYPOS = {}\n    for _, row in ipairs(S.rows) do\n      local bag = facAnchor(row.fac, byName)\n      if bag then SUPPLYPOS[row.fac] = bag.getPosition() end\n    end\n    seatAnchorByName = byName\n    if refreshSeats(byName) then dirty = true end\n    if seatOrder() then dirty = true end\n    if refreshDeck() then dirty = true end\n    if refreshVariants(byName) then dirty = true end\n    if followTurns() then dirty = true end\n    if pinFirstSeat() then dirty = true end\n  end\n\n  if dirty then\n    dirty = false\n    rebuildUI()\n  end\nend\n\n------------------------------------------------------------------ turn flow --\nfunction lockRow(i)\n  local row = S.rows[i]\n  if row == nil then return end\n  S.pinFirst = false          -- a turn is being recorded: stop holding seat 1\n  -- A quick turn pass can beat the poll in either direction, so count every\n  -- settled copy here too before the turn number advances.\n  local objects = getAllObjects()\n  local domCards = {}\n  local rowMarkers = {}\n  for _, o in ipairs(objects) do\n    local suit = dominanceCardSuit(o)\n    if suit then table.insert(domCards, { obj = o, suit = suit }) end\n    if (o.getName() or \"\") == (row.fac .. \" VP\") then\n      table.insert(rowMarkers, o)\n    end\n  end\n  local markerState = syncDominance(row, domCards, rowMarkers)\n  -- the game is over once someone reached 30: nothing locks any more\n  if S.winner ~= nil then return end\n  -- re-read the marker right now: the polled score can be a beat stale, and a\n  -- lock is forever (it is what gets exported)\n  if not dominanceFrozen(row) then\n    local idx = markerState.trackIdx\n    if idx ~= nil then\n      local sc = cellToScore(idx)\n      if sc ~= row.score then\n        logev(\"score\", row.fac, row.score, sc)\n        row.score = sc\n      end\n    end\n  end\n  -- The HIGHLIGHTED round column is the single truth for where a lock\n  -- lands: the lock goes exactly there, overwriting whatever the cell\n  -- holds (lock or hand edit). A wrong column is corrected by clicking\n  -- the right column number in EDIT, never by the sheet second-guessing.\n  local r = math.max(1, math.floor(S.turns / math.max(1, #S.rows)) + 1)\n  row.edits[tostring(r)] = nil\n  while #row.locks < r - 1 do\n    table.insert(row.locks, -1)\n  end\n  row.locks[r] = row.score\n  table.insert(S.undo, { fac = row.fac, r = r })\n  logev(\"lock\", row.fac, r, row.score)\n  S.turns = S.turns + 1\n  rebuildUI()\nend\n\n-- With full coverage the TTS turn system locks turns; otherwise END TURN.\nlocal function lockActive()\n  if S.winner ~= nil then return end\n  if #S.rows == 0 or fullTurnCoverage() then return end\n  if S.active > #S.rows then S.active = 1 end\n  local i = S.active\n  S.active = (S.active % #S.rows) + 1\n  lockRow(i)\nend\n\nfunction uiEndTurn() lockActive() end\n\nfunction onPlayerTurn(player, previous)\n  dbg(\"BoxScore onPlayerTurn: now=\" .. tostring(player and player.color)\n    .. \" prev=\" .. tostring(previous and previous.color)\n    .. \" coverage=\" .. tostring(fullTurnCoverage()))\n  -- ONE lock source per mode: with full coverage the event locks; in every\n  -- other situation the END TURN button is visible and is the only source.\n  if not fullTurnCoverage() then return end\n  -- A pass counts when the colour that just finished HAS A ROW -- i.e. it is one of the seats in play.\n  -- This used to require previous.seated, so an unoccupied seat's turn recorded nothing: in a solo game\n  -- every faction but one is on an empty seat, so ending a turn did nothing at all. Keying on \"has a\n  -- row\" keeps the original protection (toggling the turn system bursts through colours that have no\n  -- row, and those still lock nothing) while letting a seat's turn count whether or not a human sits\n  -- in it. In a full game every seat is occupied, so nothing changes there.\n  if previous == nil or previous.color == nil then return end\n  -- A pass by a seated color with no faction row (an observer) locks nothing.\n  local i = rowByColor(previous.color)\n  if i then lockRow(i) end\n  -- sync the pointer immediately instead of waiting for the next poll\n  local j = player and player.color and rowByColor(player.color) or nil\n  if j then S.active = j end\nend\n\n------------------------------------------------------------ marker movement --\n-- +/- moves the faction's marker along the track: a fast glide with a small\n-- hop, so rapid clicks load several points in a couple of seconds. Sub-row\n-- rule so every marker stays visible: an empty cell takes the marker dead\n-- centre; an occupied cell pushes the newcomer one step up, then down, then\n-- two up - never on top of another marker.\nlocal function subRowSequence()\n  local byB = {}\n  for _, b in ipairs(TRACK.rows) do table.insert(byB, b) end\n  table.sort(byB)\n  local mid = byB[math.ceil(#byB / 2)]\n  local step = 0.11\n  if #byB >= 2 then step = (byB[#byB] - byB[1]) / (#byB - 1) end\n  return { mid, mid - step, mid + step, mid - 2 * step, mid + 2 * step }\nend\n\nlocal function nudge(i, delta)\n  local row = S.rows[i]\n  if row == nil or dominanceFrozen(row) or TRACK == nil then return end\n  local m = findMarker(row)\n  if m == nil then dbg(\"BoxScore: cannot find \" .. row.fac .. \" VP\") return end\n  if m.held_by_color ~= nil then return end\n  local base = row.score >= 0 and row.score or 0\n  local target = row.score >= 0 and (base + delta) or 0\n  target = math.max(0, math.min(TRACK.n - 1, target))\n  if target == row.score then return end\n  local mapObj = getObjectFromGUID(TRACK.guid)\n  if mapObj == nil then return end\n  local cellA = TRACK.a0 + scoreToCell(target) * TRACK.s\n\n  -- candidate positions = the map's own snap points in this column, tried\n  -- centre-first so a lone marker sits exactly on the printed number\n  local mid = TRACK.rows[math.ceil(#TRACK.rows / 2)]\n  local cands = {}\n  for _, p in ipairs(TRACK.pts or {}) do\n    if math.abs(p.a - cellA) < 0.45 * TRACK.s then\n      table.insert(cands, p)\n    end\n  end\n  table.sort(cands, function(p, q)\n    return math.abs(p.b - mid) < math.abs(q.b - mid)\n  end)\n  -- extrapolated overflow spots keep every marker visible past 3 stacked\n  local seq = subRowSequence()\n  table.insert(cands, { a = cellA, b = seq[4] })\n  table.insert(cands, { a = cellA, b = seq[5] })\n\n  local chosen = cands[#cands]\n  for _, c in ipairs(cands) do\n    local free = true\n    for _, other in ipairs(S.rows) do\n      if other ~= row then\n        local om = other.guid and getObjectFromGUID(other.guid) or nil\n        if om then\n          local lp2 = mapObj.positionToLocal(om.getPosition())\n          if math.abs(lp2[TRACK.axis] - c.a) < 0.5 * TRACK.s\n            and math.abs(lp2[TRACK.other] - c.b) < 0.09 then free = false end\n        end\n      end\n    end\n    if free then chosen = c break end\n  end\n\n  local lp = { x = 0, y = 2.0, z = 0 }\n  lp[TRACK.axis] = chosen.a\n  lp[TRACK.other] = chosen.b\n  local wp = mapObj.positionToWorld(lp)\n  m.setPositionSmooth({ wp.x, wp.y + 0.12, wp.z }, false, true)\n  logev(\"score\", row.fac, row.score, target)\n  row.score = target\n  rebuildUI()\nend\n\n-------------------------------------------------------------------- buttons --\nfunction uiUndo()\n  if #S.undo == 0 then return end\n  local entry = table.remove(S.undo)\n  local fac = type(entry) == \"table\" and entry.fac or entry\n  local col = type(entry) == \"table\" and entry.r or nil\n  local i = rowByFac(fac)\n  local row = i and S.rows[i] or nil\n  if row and #row.locks > 0 then\n    col = col or #row.locks\n    logev(\"undo\", row.fac, col, row.locks[col])\n    row.locks[col] = -1\n    while #row.locks > 0 and (row.locks[#row.locks] == -1 or row.locks[#row.locks] == nil) do\n      table.remove(row.locks)\n    end\n    S.turns = math.max(0, S.turns - 1)\n    S.pinFirst = false        -- undo positions the pointer deliberately\n    if not fullTurnCoverage() then S.active = i end\n    rebuildUI()\n  end\nend\n\nfunction uiInfo()\n  S.overlay = (S.overlay == \"info\") and nil or \"info\"\n  rebuildUI()\nend\n\nfunction uiSetup()\n  S.setup = not S.setup\n  S.overlay = nil\n  rebuildUI()\nend\n\nfunction uiReset()\n  logev(\"reset\")\n  S.rows = {}\n  S.active = 1\n  S.turns = 0\n  S.pinFirst = true\n  S.winner = nil\n  S.winnerReason = nil\n  S.winnerLock = nil\n  S.undo = {}\n  S.log = {}\n  S.unpicked = {}\n  S.unpickedVar = {}\n  S.meta.map = \"\"\n  S.meta.deck = \"\"\n  S.mapAuto = nil\n  S.deckAuto = nil\n  S.flip = false\n  S.manualOrder = nil\n  S.lastExport = \"\"\n  TRACK = nil\n  findTrack()\n  refreshAssets()\n  rebuildUI()\nend\n\nfunction uiPicker()\n  S.overlay = \"picker\"\n  rebuildUI()\nend\n\nfunction uiMapMenu()\n  S.overlay = \"map\"\n  rebuildUI()\nend\n\nfunction uiGameMenu()\n  S.overlay = \"game\"\n  rebuildUI()\nend\n\nfunction uiDeckMenu()\n  S.overlay = \"deck\"\n  rebuildUI()\nend\n\nfunction uiDiscord()\n  S.overlay = \"discord\"\n  rebuildUI()\nend\n\nfunction uiOverlayClose()\n  S.overlay = nil\n  rebuildUI()\nend\n\n-- COPY: TTS Lua has no OS-clipboard access, so the closest honest thing is\n-- a selectable box holding the JSON - one Ctrl+A + Ctrl+C away. The text is\n-- injected via setAttribute AFTER the rebuild because entities in XML\n-- attributes never decode (a JSON quote would wreck the parse).\nfunction uiCopy()\n  S.overlay = (S.overlay == \"copy\") and nil or \"copy\"\n  rebuildUI()\nend\n\nfunction uiExport(player)\n  local by = player and player.steam_name or \"\"\n  S.exportBy = by\n  local payload = exportPayload(\"export\", { log = S.log, exportedBy = by })\n  local toDiscord = postDiscord(fencedChunks(boxText()))\n  local body = JSON.encode(payload)\n  local title = \"BoxScore\"\n  local done = false\n  for _, t in ipairs(Notes.getNotebookTabs()) do\n    if t.title == title then\n      Notes.editNotebookTab({ index = t.index, title = title, body = body })\n      done = true\n    end\n  end\n  if not done then Notes.addNotebookTab({ title = title, body = body }) end\n  S.lastExport = os.date(\"%H:%M\")\n    .. (toDiscord and \" &#183; discord&#8230;\" or \" (no webhook set)\")\n  dbg(\"BoxScore: exported\" .. (toDiscord and \" (discord)\" or \"\"))\n  rebuildUI()\nend\n\nfunction uiFlip()\n  S.flip = not S.flip\n  for _, row in ipairs(S.rows) do\n    if row.dom == nil then row.score = -1 end\n  end\n  rebuildUI()\nend\n\nfunction uiSpin()\n  S.pose = (S.pose % #UI_POSES) + 1\n  rebuildUI()\nend\n\nfunction uiScaleMode()\n  S.scaleMode = (S.scaleMode % 2) + 1\n  rebuildUI()\nend\n\nlocal function changeSizePct(delta)\n  S.sizePct = clampSizePct((S.sizePct or 100) + delta)\n  rememberSizePct()\n  rebuildUI()\nend\n\nfunction uiSizeDown() changeSizePct(-10) end\nfunction uiSizeUp() changeSizePct(10) end\n\nfunction uiHide()\n  S.hidden = not S.hidden\n  rebuildUI()\nend\n\nfunction uiDiag()\n  local lines = {}\n  if TRACK then\n    lines[1] = \"map=\" .. TRACK.guid .. \" (\" .. (S.meta.map ~= \"\" and S.meta.map or \"?\")\n      .. \") cells 0-\" .. (TRACK.n - 1) .. \", \" .. #TRACK.rows .. \" sub-rows, flip=\" .. tostring(S.flip)\n  else\n    lines[1] = \"NO TRACK FOUND - is a map on the table?\"\n  end\n  table.insert(lines, \"turn system: \" .. (turnsRunning() and \"following\" or \"manual\"))\n  table.insert(lines, \"unpicked: \" .. table.concat(unpickedList(), \", \"))\n  for _, row in ipairs(S.rows) do\n    local m = findMarker(row)\n    local idx = m and readCell(m) or nil\n    table.insert(lines, row.fac .. \" [\" .. tostring(row.color) .. \"/\" .. row.player\n      .. \"]: score=\" .. tostring(row.score) .. \" cell=\" .. tostring(idx)\n      .. \" locks=\" .. #row.locks)\n  end\n  broadcastToAll(\"Box Score diagnose:\\n\" .. table.concat(lines, \"\\n\"), { 0.91, 0.86, 0.74 })\n  log(\"BoxScore diagnose: \" .. JSON.encode({ track = TRACK, state = S }))\nend\n\nfunction uiRowBtn(player, _, id)\n  local uvF, uvC = id:match(\"^uv_(%d+)_(%d+)$\")\n  if uvF then\n    local fac = ROSTER[tonumber(uvF)]\n    local opts = fac and variantOptions(fac) or nil\n    if opts and opts[tonumber(uvC)] then\n      S.unpickedVar[fac] = toggleCSV(S.unpickedVar[fac], opts[tonumber(uvC)], opts)\n      rebuildUI()\n    end\n    return\n  end\n  local kind, i = id:match(\"^(%a+)_(%d+)$\")\n  i = tonumber(i)\n  if kind == \"plus\" then nudge(i, 1)\n  elseif kind == \"minus\" then nudge(i, -1)\n  elseif kind == \"up\" then\n    if i > 1 then\n      S.rows[i], S.rows[i - 1] = S.rows[i - 1], S.rows[i]\n      if S.active == i then S.active = i - 1 elseif S.active == i - 1 then S.active = i end\n      S.manualOrder = true\n      rebuildUI()\n    end\n  elseif kind == \"del\" then\n    local row = S.rows[i]\n    if row then\n      logev(\"leave\", row.fac)\n      table.remove(S.rows, i)\n      if i < S.active then S.active = S.active - 1 end\n      if S.active > #S.rows or S.active < 1 then S.active = 1 end\n      refreshAssets()\n      rebuildUI()\n    end\n  elseif kind == \"pick\" then\n    local fac = ROSTER[i]\n    if fac then\n      S.unpicked[fac] = (S.unpicked[fac] ~= true) and true or nil\n      rebuildUI()\n    end\n  elseif kind == \"act\" then\n    if S.rows[i] then\n      S.pinFirst = false      -- deliberate row pick: do not snap it back\n      S.active = i\n      rebuildUI()\n    end\n  elseif kind == \"domwin\" then\n    local row = S.rows[i]\n    if row and row.dom then\n      local won = row.dom.won == true\n      for _, other in ipairs(S.rows) do\n        if other.dom then other.dom.won = false end\n      end\n      if won then\n        if S.winner == row.fac and S.winnerReason == \"dominance\" then\n          S.winner = nil\n          S.winnerReason = nil\n        end\n        logev(\"domwin-undo\", row.fac, row.dom.turn, row.dom.suit)\n      else\n        row.dom.won = true\n        S.winner = row.fac\n        S.winnerReason = \"dominance\"\n        S.winnerLock = nil\n        logev(\"domwin\", row.fac, row.dom.turn, row.dom.suit)\n      end\n      rebuildUI()\n    end\n  elseif kind == \"fv\" then\n    S.varRow = i\n    S.overlay = \"var\"\n    rebuildUI()\n  elseif kind == \"vc\" then\n    local row = S.rows[S.varRow]\n    if row then\n      local opts = variantOptions(row.fac)\n      if opts and opts[i] then\n        row.variant = toggleCSV(row.variant, opts[i], opts)\n        row.variantAuto = false\n        rebuildUI()\n      end\n    end\n  elseif kind == \"deck\" then\n    local d = DECKS[i]\n    S.meta.deck = (S.meta.deck == d) and \"\" or d\n    S.deckAuto = false\n    S.overlay = nil\n    rebuildUI()\n  elseif kind == \"map\" then\n    local m = MAPS[i]\n    S.meta.map = (S.meta.map == m) and \"\" or m\n    S.mapAuto = false\n    S.overlay = nil\n    rebuildUI()\n  elseif kind == \"colh\" then\n    -- clicking a round-column number in setup declares \"we are in round i\";\n    -- locks always land in the declared (highlighted) column\n    S.turns = (i - 1) * math.max(1, #S.rows)\n    logev(\"setturn\", nil, S.turns)\n    rebuildUI()\n  end\nend\n\n--------------------------------------------------------------- text editing --\nfunction uiCellEdit(player, value, id)\n  local i, r = id:match(\"^cl_(%d+)_(%d+)$\")\n  i, r = tonumber(i), tonumber(r)\n  local row = S.rows[i]\n  if row == nil then return end\n  value = tostring(value or \"\"):gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n  -- an emptied cell stays empty: \"\" is an explicit blank that overrides the\n  -- locked value (it would otherwise reappear on the next rebuild)\n  if value == \"\" and row.locks[r] == nil then\n    row.edits[tostring(r)] = nil\n  else\n    row.edits[tostring(r)] = value\n    logev(\"edit\", row.fac, r, value)\n  end\nend\n\nfunction uiLiveEdit(player, value, id)\n  value = tostring(value or \"\")\n  local ni = id:match(\"^nm_(%d+)$\")\n  if ni then\n    local row = S.rows[tonumber(ni)]\n    if row then row.player = value; row.nameAuto = false end\n  else\n    local ci, r = id:match(\"^cl_(%d+)_(%d+)$\")\n    if ci then\n      local row = S.rows[tonumber(ci)]\n      if row then row.edits[tostring(tonumber(r))] = value end\n    elseif id == \"mt_hook\" then S.meta.hook = value\n    elseif id == \"mt_thread\" then S.meta.thread = value\n    elseif id == \"mt_game\" then\n      S.meta.game = value:gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n    end\n  end\n  -- push the keystroke to every client without rebuilding the sheet\n  pcall(function() self.UI.setAttribute(id, \"text\", value) end)\nend\n\nfunction uiNameEdit(player, value, id)\n  local i = tonumber(id:match(\"^nm_(%d+)$\"))\n  if S.rows[i] then\n    S.rows[i].player = tostring(value or \"\")\n    S.rows[i].nameAuto = false\n  end\nend\n\n\nfunction uiMetaEdit(player, value, id)\n  local key = id:match(\"^mt_(%a+)$\")\n  value = tostring(value or \"\"):gsub(\"^%s+\", \"\"):gsub(\"%s+$\", \"\")\n  if key == \"turns\" then\n    S.turns = math.max(0, math.floor(tonumber(value) or S.turns))\n    rebuildUI()\n  elseif key and S.meta[key] ~= nil then\n    S.meta[key] = value\n  end\nend\n\n--------------------------------------------------------------------- the UI --\nfunction refreshAssets()\n  local assets = {}\n  local seen = {}\n  for _, row in ipairs(S.rows) do\n    if row.iconUrl and row.iconUrl ~= \"\" then\n      table.insert(assets, { name = assetName(row.fac), url = row.iconUrl })\n    end\n    for _, c in ipairs(row.crafts or {}) do\n      if c.img and c.img ~= \"\" then\n        local nm = \"it\" .. urlTail(c.img)\n        if not seen[nm] then\n          seen[nm] = true\n          table.insert(assets, { name = nm, url = c.img })\n        end\n      end\n    end\n  end\n  for _, url in pairs(S.itemImgs or {}) do\n    if url ~= \"\" then\n      local an = \"it\" .. urlTail(url)\n      if not seen[an] then\n        seen[an] = true\n        table.insert(assets, { name = an, url = url })\n      end\n    end\n  end\n  self.UI.setCustomAssets(assets)\nend\n\nlocal function fieldText(v)\n  if v == nil or v == \"\" then return \" \" end\n  return esc(v)\nend\n\nlocal function cellText(row, r)\n  local e = row.edits[tostring(r)]\n  -- Keep numeric locks internally so cancel can reveal the ordinary score\n  -- history again, but never print a dominance-era score while dom is active.\n  if dominanceFrozen(row) and r >= row.dom.round\n    and (e ~= nil or r <= #row.locks) then return \"-\" end\n  if e ~= nil then return e end\n  local v = row.locks[r]\n  if v == nil or v < 0 then return \"\" end\n  return tostring(v)\nend\n\n-- fenced plain-text box score, as posted to Discord (global on purpose:\n-- uiExport is defined above and resolves it at call time)\nfunction boxText()\n  local bits = {}\n  if S.meta.map ~= \"\" then table.insert(bits, S.meta.map) end\n  if S.meta.deck ~= \"\" then table.insert(bits, S.meta.deck) end\n  local unp = unpickedList()\n  if #unp > 0 then table.insert(bits, \"Unpicked: \" .. table.concat(unp, \", \")) end\n  local R = 0\n  for _, row in ipairs(S.rows) do\n    R = math.max(R, #row.locks)\n    for k, v in pairs(row.edits or {}) do\n      local rn = tonumber(k)\n      if rn and v ~= \"\" and rn > R then R = rn end\n    end\n  end\n  local round = math.floor(S.turns / math.max(1, #S.rows)) + 1\n  local title = \"ROOT BOX SCORE\"\n  if S.meta.game ~= nil and S.meta.game ~= \"\" then\n    title = title .. \" - \" .. S.meta.game\n  end\n  local stamp = \"round \" .. round .. \" - \" .. os.date(\"%Y-%m-%d %H:%M\")\n  if S.exportBy ~= nil and S.exportBy ~= \"\" then\n    stamp = stamp .. \" - by \" .. S.exportBy\n  end\n  local lines = { title .. \" - \" .. table.concat(bits, \" / \"), stamp }\n  local head = string.format(\"%-11s %-17s\", \"faction\", \"player\")\n  for r = 1, R do head = head .. string.format(\"%4d\", r) end\n  table.insert(lines, head)\n  for _, row in ipairs(S.rows) do\n    local line = string.format(\"%-11s %-17s\", row.fac:sub(1, 11),\n      (row.player or \"\"):sub(1, 17))\n    for r = 1, R do line = line .. string.format(\"%4s\", cellText(row, r)) end\n    table.insert(lines, line)\n    if row.variant ~= nil and row.variant ~= \"\" then\n      table.insert(lines, \"  > \" .. row.variant)\n    end\n    if row.dom ~= nil then\n      table.insert(lines, \"  > dominance: \" .. dominanceKindLabel(row.dom)\n        .. \", turn \" .. tostring(row.dom.turn)\n        .. \", \" .. tostring(row.dom.suit)\n        .. \", won: \" .. ((row.dom.won == true) and \"yes\" or \"no\"))\n    end\n    if S.experimental and row.crafts ~= nil and #row.crafts > 0 then\n      local cs = {}\n      for _, c in ipairs(row.crafts) do\n        local tags = {}\n        if c.r then table.insert(tags, \"T\" .. c.r) end\n        if c.vp and c.vp > 0 then table.insert(tags, \"+\" .. c.vp) end\n        table.insert(cs, c.item\n          .. (#tags > 0 and (\" (\" .. table.concat(tags, \", \") .. \")\") or \"\"))\n      end\n      table.insert(lines, \"  > crafted: \" .. table.concat(cs, \", \"))\n    end\n  end\n  return lines\nend\n\n-- fields are invisible until touched: transparent at rest, white while hovered\n-- or being edited, so SETUP reads exactly like the printed sheet\nlocal IF_COLORS = 'placeholder=\" \" colors=\"#00000000|#FFFFFFC0|#FFFFFF|#00000000\"'\nlocal BTN_DARK = 'colors=\"' .. WALNUT .. '|' .. RUST .. '|' .. GOLD .. '|#00000000\" textColor=\"' .. PARCH .. '\"'\nlocal BTN_GOLD = 'colors=\"' .. GOLD .. '|' .. GOLDHI .. '|' .. RUST .. '|#00000000\" textColor=\"' .. INKTXT .. '\"'\nlocal BTN_SOFT = 'colors=\"' .. PARCH2 .. '|' .. GOLDHI .. '|' .. GOLD .. '|#00000000\" textColor=\"' .. RUST .. '\"'\nlocal NOClick = ' raycastTarget=\"false\"' \n\nlocal lastScaleKey = \"\"\n\nlocal function renderMinRows()\n  local n = tonumber(Global.getVar(\"RTT_BOXSCORE_MIN\"))\n  if not n then\n    local dn = tonumber(Global.getVar(\"RTT_DN\"))\n    if dn then n = dn - 1 end\n  end\n  return math.max(1, n or 4)\nend\n\nfunction rebuildUI()\n  if S.hidden then\n    self.UI.setXml(\"\")\n    return\n  end\n  local maxLocks = 0\n  for _, row in ipairs(S.rows) do maxLocks = math.max(maxLocks, #row.locks) end\n  local showR = math.min((S.cols or 10) + 1, 41)   -- FIXED: no maxLocks growth\n  local cellW = showR > 14 and 36 or 44\n  local iconW, facW, domW, nameW, liveW = 30, 118, 70, 130, 48\n  local btnW = 117\n  local W = 54 + iconW + facW + domW + nameW + (showR - 1) * cellW + liveW + btnW\n  local rowH, headH = 40, 26\n  local nMin = renderMinRows()\n  local H = 56 + headH + math.max(nMin, #S.rows) * (rowH + 3) + 42\n  local mul = clampSizePct(S.sizePct) / 100\n\n  -- The walnut cardboard extends FRAME px beyond the sheet on every side.\n  -- That rim is bare object surface - outside the UI canvas entirely - so it\n  -- is grabbable by construction, no matter how the UI treats clicks. The\n  -- parchment area additionally lets clicks through via raycastTarget.\n  local FRAME = 5\n  local k = BASE_SCALE * LEGACY_BASE_MUL / PX_PER_UNIT\n  local ww = (W + 2 * FRAME) * k\n  local wh = (H + 2 * FRAME) * k\n  ww = 31.80 wh = 10.42  -- FIXED to the maintainer 4-card box-score rectangle\n  ww, wh = ww * mul, wh * mul\n  local key = string.format(\"%.2f|%.2f\", ww, wh)\n  if key ~= lastScaleKey and self.held_by_color == nil then\n    lastScaleKey = key\n    self.setScale({ ww, 0.18, wh })\n  end\n  local sx, sy\n  if S.scaleMode == 1 then\n    sx, sy = PX_PER_UNIT / (W + 2 * FRAME), PX_PER_UNIT / (H + 2 * FRAME)\n  else\n    sx, sy = BASE_SCALE * LEGACY_BASE_MUL * mul, BASE_SCALE * LEGACY_BASE_MUL * mul\n  end\n  local pose = UI_POSES[S.pose]\n\n  local seatedNow = {}\n  for _, p in ipairs(Player.getPlayers()) do\n    if p.seated then seatedNow[p.color] = true end\n  end\n\n  local x = {}\n  local function add(s) table.insert(x, s) end\n\n  -- a Button whose label lives in a child Text: entities render correctly\n  -- there (attribute strings do not decode them), and the label can be bold\n  local function chip(id, handler, style, w, fs, textColor, label)\n    local wattr = (w == 0) and 'flexibleWidth=\"1\"' or ('preferredWidth=\"' .. w .. '\"')\n    add('<Button id=\"' .. id .. '\" ' .. wattr .. ' ' .. style .. ' onClick=\"' .. handler .. '\">'\n      .. '<Text fontSize=\"' .. fs .. '\" fontStyle=\"Bold\" color=\"' .. textColor\n      .. '\" raycastTarget=\"false\">' .. label .. '</Text></Button>')\n  end\n\n  add(string.format(\n    '<Panel position=\"%s\" rotation=\"%s\" scale=\"%.4f %.4f 1\" width=\"%d\" height=\"%d\" color=\"%s\"%s>',\n    pose.pos, pose.rot, sx, sy, W, H, PARCH, NOClick))\n  add('<VerticalLayout padding=\"12 12 8 8\" spacing=\"4\">')\n\n  -- header band: the printed title and game facts in play; the map / deck /\n  -- unpicked / discord choices in setup - same height either way\n  add('<HorizontalLayout preferredHeight=\"34\" spacing=\"6\">')\n  local unp = unpickedList()\n  if S.setup then\n    add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleLeft\"'\n      .. ' preferredWidth=\"44\"' .. NOClick .. '>EDIT</Text>')\n    add('<InputField id=\"mt_game\" fontSize=\"13\" preferredWidth=\"130\" preferredHeight=\"20\"'\n      .. ' placeholder=\"GAME NAME\" colors=\"' .. WALNUT .. '|#52381E|#52381E|#00000000\"'\n      .. ' textColor=\"' .. PARCH .. '\" onValueChanged=\"uiLiveEdit\" text=\"' .. esc(S.meta.game)\n      .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    chip(\"mpbtn\", \"uiMapMenu\", (S.overlay == \"map\") and BTN_GOLD or BTN_DARK, 84, 11,\n      (S.overlay == \"map\") and INKTXT or PARCH,\n      S.meta.map ~= \"\" and esc(S.meta.map) or \"MAP\")\n    add('<Button id=\"dkbtn\" preferredWidth=\"112\" '\n      .. ((S.overlay == \"deck\") and BTN_GOLD or BTN_DARK) .. ' onClick=\"uiDeckMenu\">'\n      .. '<Text fontSize=\"11\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"8\"'\n      .. ' resizeTextMaxSize=\"11\" fontStyle=\"Bold\" color=\"'\n      .. ((S.overlay == \"deck\") and INKTXT or PARCH) .. '\" raycastTarget=\"false\">'\n      .. (S.meta.deck ~= \"\" and esc(S.meta.deck) or \"DECK\") .. '</Text></Button>')\n    chip(\"pkbtn\", \"uiPicker\", (S.overlay == \"picker\") and BTN_GOLD or BTN_DARK, 92, 11,\n      (S.overlay == \"picker\") and INKTXT or PARCH, \"UNPICKED\")\n    chip(\"dcbtn\", \"uiDiscord\", (S.overlay == \"discord\") and BTN_GOLD or BTN_DARK, 70, 10,\n      (S.overlay == \"discord\") and INKTXT or PARCH, \"DISCORD\")\n    chip(\"xpbtn\", \"uiExperimental\", S.experimental and BTN_GOLD or BTN_DARK, 62, 10,\n      S.experimental and INKTXT or PARCH, \"CRAFT\")\n    if S.experimental then\n      chip(\"cebtn\", \"uiCraftMenu\", (S.overlay == \"craft\") and BTN_GOLD or BTN_DARK, 58, 10,\n        (S.overlay == \"craft\") and INKTXT or PARCH, \"ITEMS\")\n    end\n    add('<Text fontSize=\"10\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleRight\"'\n      .. ' preferredWidth=\"62\"' .. NOClick .. '>SIZE ' .. clampSizePct(S.sizePct) .. '%</Text>')\n    chip(\"szdn\", \"uiSizeDown\", BTN_DARK, 26, 13, PARCH, \"&#8722;\")\n    chip(\"szup\", \"uiSizeUp\", BTN_DARK, 26, 13, PARCH, \"+\")\n    chip(\"rsbtn\", \"uiReset\", BTN_DARK, 56, 10, PARCH, \"RESET\")\n  else\n    add('<Text fontSize=\"18\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" alignment=\"MiddleLeft\"'\n      .. ' preferredWidth=\"330\"' .. NOClick .. '>' .. spaced(\"ROOT\") .. '&#160;&#160;&#183;&#160;&#160;'\n      .. spaced(\"BOX SCORE\") .. '</Text>')\n    local bits = {}\n    if S.meta.game ~= \"\" then table.insert(bits, esc(S.meta.game)) end\n    if S.meta.map ~= \"\" then table.insert(bits, esc(S.meta.map)) end\n    if S.meta.deck ~= \"\" then table.insert(bits, esc(S.meta.deck)) end\n    if #unp > 0 then table.insert(bits, \"Unpicked: \" .. esc(table.concat(unp, \", \"))) end\n    add('<Text fontSize=\"15\" fontStyle=\"Italic\" color=\"' .. RUST .. '\" alignment=\"MiddleRight\"'\n      .. ' flexibleWidth=\"1\"' .. NOClick .. '>' .. table.concat(bits, \"&#160;&#160;&#183;&#160;&#160;\") .. '</Text>')\n  end\n  add('</HorizontalLayout>')\n\n  add('<Panel preferredHeight=\"2\" color=\"' .. GOLD .. '\"' .. NOClick .. '/>')\n\n  -- column headers; in setup the round numbers are buttons that set the turn\n  add('<HorizontalLayout preferredHeight=\"' .. headH .. '\" spacing=\"3\">')\n  add('<Text preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. facW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. domW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. nameW .. '\"' .. NOClick .. '> </Text>')\n  local curRound = math.floor(S.turns / math.max(1, #S.rows)) + 1\n  for r = 1, showR - 1 do\n    local isCur = (r == curRound)\n    if S.setup then\n      add('<Button id=\"colh_' .. r .. '\" fontSize=\"15\" fontStyle=\"Bold\" preferredWidth=\"' .. cellW\n        .. '\" colors=\"' .. (isCur and GOLD or \"#00000000\") .. '|#FFFFFFC0|' .. GOLDHI\n        .. '|#00000000\" textColor=\"' .. (isCur and INKTXT or RUST)\n        .. '\" text=\"' .. r .. '\" onClick=\"uiRowBtn\"/>')\n    elseif isCur then\n      add('<Panel preferredWidth=\"' .. cellW .. '\" color=\"' .. GOLD .. '\"' .. NOClick\n        .. '><Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. INKTXT\n        .. '\" alignment=\"MiddleCenter\"' .. NOClick .. '>' .. r .. '</Text></Panel>')\n    else\n      add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. RUST .. '\" alignment=\"MiddleCenter\" preferredWidth=\"'\n        .. cellW .. '\"' .. NOClick .. '>' .. r .. '</Text>')\n    end\n  end\n  add('<Text preferredWidth=\"10\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"' .. liveW .. '\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n  add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n  add('</HorizontalLayout>')\n\n  -- faction rows\n  local EMPTY_ROW = { fac=\"\", player=\"\", tintHex=\"3A2A1A\", iconUrl=\"\", variant=\"\", score=-1, locks={}, edits={}, crafts=nil }\n  for i = 1, math.max(nMin, #S.rows) do\n    local row = S.rows[i] or EMPTY_ROW\n    local placeholder = (S.rows[i] == nil)\n    local isActive = (not placeholder) and (i == S.active) and (fullTurnCoverage() or not turnsRunning())\n    if #S.rows == 0 then isActive = false end\n    local bg = isActive and GOLDHI or ((i % 2 == 1) and \"#00000000\" or PARCH2)\n    add('<HorizontalLayout preferredHeight=\"' .. rowH .. '\" spacing=\"3\" color=\"' .. bg .. '\"' .. NOClick .. '>')\n    if S.setup and not placeholder then\n      add('<Button id=\"act_' .. i .. '\" preferredWidth=\"' .. iconW\n        .. '\" colors=\"#00000000|#FFFFFFC0|' .. GOLDHI .. '|#00000000\" onClick=\"uiRowBtn\">')\n      if row.iconUrl and row.iconUrl ~= \"\" then\n        add('<Image image=\"' .. assetName(row.fac) .. '\" width=\"26\" height=\"26\"' .. NOClick .. '/>')\n      else\n        add('<Panel width=\"16\" height=\"16\" color=\"#' .. row.tintHex .. '\"' .. NOClick .. '/>')\n      end\n      add('</Button>')\n    elseif row.iconUrl and row.iconUrl ~= \"\" then\n      add('<Panel preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '><Image image=\"' .. assetName(row.fac)\n        .. '\" width=\"26\" height=\"26\"' .. NOClick .. '/></Panel>')\n    else\n      add('<Panel preferredWidth=\"' .. iconW .. '\"' .. NOClick .. '><Panel width=\"20\" height=\"20\" color=\"'\n        .. WALNUT .. '\"' .. NOClick .. '><Panel width=\"16\" height=\"16\" color=\"#' .. row.tintHex .. '\"' .. NOClick .. '/></Panel></Panel>')\n    end\n    add('<VerticalLayout preferredWidth=\"' .. facW .. '\" spacing=\"0\">')\n    local facName = esc(row.fac)\n    add('<HorizontalLayout preferredHeight=\"22\" spacing=\"2\" childForceExpandWidth=\"false\">')\n    add('<Text fontSize=\"15\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" preferredWidth=\"'\n      .. (facW - 30) .. '\" alignment=\"MiddleLeft\"' .. NOClick .. '>' .. facName .. '</Text>')\n    if S.setup and not placeholder and variantOptions(row.fac) then\n      chip(\"fv_\" .. i, \"uiRowBtn\", 'colors=\"#00000000|#FFFFFFC0|' .. GOLDHI .. '|#00000000\"',\n        26, 18, \"#8A7A64\", \"&#9660;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    add('</HorizontalLayout>')\n    if row.variant ~= nil and row.variant ~= \"\" then\n      add('<Text fontSize=\"11\" resizeTextForBestFit=\"true\" resizeTextMinSize=\"6\"'\n        .. ' resizeTextMaxSize=\"11\" fontStyle=\"Italic\" color=\"' .. RUST .. '\" preferredHeight=\"14\"'\n        .. ' alignment=\"UpperLeft\"' .. NOClick .. '>' .. esc(row.variant) .. '</Text>')\n    end\n    add('</VerticalLayout>')\n    if row.dom ~= nil then\n      add('<VerticalLayout preferredWidth=\"' .. domW\n        .. '\" spacing=\"1\" childForceExpandHeight=\"false\">')\n      add('<Text fontSize=\"9\" fontStyle=\"Bold\" color=\"' .. RUST\n        .. '\" preferredHeight=\"16\" alignment=\"MiddleCenter\"' .. NOClick .. '>dom '\n        .. esc(row.dom.suit) .. ' T' .. tostring(row.dom.turn) .. '</Text>')\n      add('<Button id=\"domwin_' .. i .. '\" fontSize=\"10\" fontStyle=\"Bold\" preferredHeight=\"18\" '\n        .. ((row.dom.won == true) and BTN_GOLD or BTN_SOFT)\n        .. ' text=\"dom win\" onClick=\"uiRowBtn\"/>')\n      add('</VerticalLayout>')\n    else\n      add('<Text preferredWidth=\"' .. domW .. '\"' .. NOClick .. '> </Text>')\n    end\n    if S.setup and not placeholder then\n      add('<InputField id=\"nm_' .. i .. '\" fontSize=\"15\" textAlignment=\"MiddleCenter\"'\n        .. ' preferredWidth=\"' .. nameW\n        .. '\" ' .. IF_COLORS .. ' textColor=\"' .. RUST\n        .. '\" text=\"' .. fieldText(row.player) .. '\" onValueChanged=\"uiLiveEdit\" onEndEdit=\"uiNameEdit\"/>')\n    else\n      add('<Text fontSize=\"15\" color=\"' .. RUST .. '\" alignment=\"MiddleCenter\" preferredWidth=\"' .. nameW\n        .. '\"' .. NOClick .. '>' .. esc(row.player) .. '</Text>')\n    end\n    local craftIcons = {}\n    if S.experimental then\n      for _, c in ipairs(row.crafts or {}) do\n        if c.r and c.img and c.img ~= \"\" then\n          craftIcons[c.r] = craftIcons[c.r] or {}\n          table.insert(craftIcons[c.r], c.img)\n        end\n      end\n    end\n    for r = 1, showR - 1 do\n      add('<Panel preferredWidth=\"' .. cellW .. '\"' .. NOClick .. '>')\n      if S.setup and not placeholder then\n        add('<InputField id=\"cl_' .. i .. '_' .. r .. '\" fontSize=\"15\" textAlignment=\"MiddleCenter\"'\n          .. ' width=\"' .. cellW .. '\" height=\"' .. (rowH - 6)\n          .. '\" characterLimit=\"3\" ' .. IF_COLORS .. ' textColor=\"' .. INKTXT\n          .. '\" text=\"' .. fieldText(cellText(row, r)) .. '\" onValueChanged=\"uiLiveEdit\" onEndEdit=\"uiCellEdit\"/>')\n      else\n        add('<Text fontSize=\"15\" color=\"' .. INKTXT\n          .. '\" alignment=\"MiddleCenter\" width=\"' .. cellW .. '\" height=\"' .. rowH .. '\"' .. NOClick .. '>'\n          .. esc(cellText(row, r)) .. '</Text>')\n      end\n      -- crafted-item figures climb the cell's right edge, clear of the number\n      local ic = craftIcons[r]\n      if ic then\n        for k = 1, math.min(#ic, 6) do\n          local col = math.floor((k - 1) / 3)\n          local rw = (k - 1) % 3\n          add('<Image image=\"it' .. urlTail(ic[k]) .. '\" width=\"13\" height=\"13\"'\n            .. ' rectAlignment=\"LowerRight\" offsetXY=\"' .. (-1 - col * 13) .. ' ' .. (1 + rw * 13)\n            .. '\"' .. NOClick .. '/>')\n        end\n      end\n      add('</Panel>')\n    end\n    local live = row.score >= 0 and tostring(row.score) or \"&#8211;\"\n    local liveFont = 16\n    if dominanceFrozen(row) then\n      live = (row.dom.won == true) and \"dom win\" or \"-\"\n      liveFont = 10\n    end\n    add('<Text preferredWidth=\"10\"' .. NOClick .. '> </Text>')\n    add('<Panel preferredWidth=\"' .. liveW .. '\" color=\"' .. GOLD .. '\"' .. NOClick .. '>'\n      .. '<Text fontSize=\"' .. liveFont .. '\" fontStyle=\"Bold\" color=\"' .. INKTXT .. '\" alignment=\"MiddleCenter\"' .. NOClick .. '>'\n      .. live .. '</Text></Panel>')\n    if placeholder or dominanceFrozen(row) then\n      add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n      add('<Text preferredWidth=\"28\"' .. NOClick .. '> </Text>')\n    else\n      chip(\"minus_\" .. i, \"uiRowBtn\", BTN_SOFT, 28, 14, RUST, \"&#8722;\")\n      chip(\"plus_\" .. i, \"uiRowBtn\", BTN_SOFT, 28, 14, RUST, \"+\")\n    end\n    if S.setup and i > 1 and not placeholder then\n      chip(\"up_\" .. i, \"uiRowBtn\", BTN_SOFT, 26, 11, RUST, \"&#9650;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    if S.setup and not placeholder then\n      chip(\"del_\" .. i, \"uiRowBtn\", BTN_SOFT, 26, 11, RUST, \"&#215;\")\n    else\n      add('<Text preferredWidth=\"26\"' .. NOClick .. '> </Text>')\n    end\n    add('</HorizontalLayout>')\n  end\n\n  -- footer\n  add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\" childForceExpandWidth=\"false\">')\n  if #S.rows > 0 and not fullTurnCoverage() then\n    add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"84\" ' .. BTN_GOLD\n      .. ' text=\"END TURN\" onClick=\"uiEndTurn\"/>')\n  end\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"66\" ' .. BTN_SOFT .. ' text=\"EXPORT\" onClick=\"uiExport\"/>')\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"52\" '\n    .. ((S.overlay == \"copy\") and BTN_GOLD or BTN_SOFT) .. ' text=\"COPY\" onClick=\"uiCopy\"/>')\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"56\" ' .. (S.setup and BTN_GOLD or BTN_SOFT)\n    .. ' text=\"' .. (S.setup and \"DONE\" or \"EDIT\") .. '\" onClick=\"uiSetup\"/>')\n  add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"52\" '\n    .. ((S.overlay == \"info\") and BTN_GOLD or BTN_SOFT) .. ' text=\"INFO\" onClick=\"uiInfo\"/>')\n  local right = \"made by MrDrouf&#160;&#160;&#183;&#160;&#160;\" .. BUILD\n  if S.lastExport ~= \"\" then\n    right = \"exported \" .. S.lastExport .. \"&#160;&#160;&#183;&#160;&#160;\" .. right\n  end\n  add('<Text fontSize=\"12\" fontStyle=\"Italic\" color=\"' .. RUST .. '\" alignment=\"MiddleRight\" flexibleWidth=\"1\"' .. NOClick .. '>'\n    .. right .. '</Text>')\n  add('</HorizontalLayout>')\n\n  add('</VerticalLayout>')\n\n  -- overlays float over the rows, so the sheet never changes size\n  local PICK_DARK = 'colors=\"#57402A|' .. RUST .. '|' .. GOLD .. '|#00000000\"'\n  if S.setup and S.overlay == \"picker\" then\n    -- character chips flow in rows of six so long names never wrap; the\n    -- panel is pinned by its TOP edge, so selecting a faction only grows\n    -- it downward - nothing shifts or recenters\n    -- the Eyrie is excluded: its leader is chosen in play, never in the\n    -- draft, so an unpicked Eyrie has no leader options to note (captains\n    -- and vagabond characters ARE distinct unpicked cards)\n    local extra = 0\n    for _, fac in ipairs(ROSTER) do\n      local opts = (S.unpicked[fac] == true and fac ~= \"Eyrie\")\n        and variantOptions(fac) or nil\n      if opts then extra = extra + math.ceil(#opts / 6) end\n    end\n    local baseH = 118\n    local topY = math.max(8, math.floor((H - baseH) / 2))\n    add('<Panel width=\"' .. (W - 80) .. '\" height=\"' .. (baseH + extra * 30)\n      .. '\" rectAlignment=\"UpperCenter\" offsetXY=\"0 -' .. topY .. '\"'\n      .. ' color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"10 10 10 10\" spacing=\"6\" childForceExpandHeight=\"false\">')\n    for half = 1, 2 do\n      add('<HorizontalLayout preferredHeight=\"46\" spacing=\"5\">')\n      local from = (half - 1) * 7 + 1\n      for ri = from, math.min(from + 6, #ROSTER) do\n        local fac = ROSTER[ri]\n        local sel = (S.unpicked[fac] == true)\n        chip(\"pick_\" .. ri, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK,\n          0, 12, sel and INKTXT or PARCH, esc(fac))\n      end\n      if half == 2 then\n        chip(\"pkdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n      end\n      add('</HorizontalLayout>')\n    end\n    for fi, fac in ipairs(ROSTER) do\n      local opts = variantOptions(fac)\n      if S.unpicked[fac] == true and fac ~= \"Eyrie\" and opts then\n        local chosen = {}\n        for w in (S.unpickedVar[fac] or \"\"):gmatch(\"[^,]+\") do\n          chosen[w:match(\"^%s*(.-)%s*$\")] = true\n        end\n        for from = 1, #opts, 6 do\n          add('<HorizontalLayout preferredHeight=\"24\" spacing=\"4\">')\n          add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"64\"'\n            .. ' alignment=\"MiddleRight\"' .. NOClick .. '>'\n            .. (from == 1 and (esc(fac) .. ':') or ' ') .. '</Text>')\n          for ci2 = from, math.min(from + 5, #opts) do\n            chip(\"uv_\" .. fi .. \"_\" .. ci2, \"uiRowBtn\",\n              chosen[opts[ci2]] and BTN_GOLD or PICK_DARK, 0, 10,\n              chosen[opts[ci2]] and INKTXT or PARCH, esc(opts[ci2]))\n          end\n          add('</HorizontalLayout>')\n        end\n      end\n    end\n    add('</VerticalLayout></Panel>')\n  elseif S.overlay == \"copy\" then\n    add('<Panel width=\"' .. (W - 160) .. '\" height=\"210\" color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"12 12 10 8\" spacing=\"5\" childForceExpandHeight=\"false\">')\n    add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredHeight=\"16\"'\n      .. ' alignment=\"MiddleLeft\"' .. NOClick\n      .. '>the box-score record as JSON &#8211; click the box, select all (Ctrl+A), copy (Ctrl+C)</Text>')\n    -- the JSON is baked straight into the field (no async setAttribute,\n    -- which raced the UI build and left the box empty on a busy table).\n    -- It sits in a SINGLE-quoted attribute, so the JSON's own double quotes\n    -- pass through untouched and stay valid, readable JSON; only the three\n    -- characters that would break the XML are escaped, and with the NUMERIC\n    -- entities this mod has verified TTS decodes (named ones like &amp; can\n    -- be rejected outright, which blanks the whole panel).\n    local rec = JSON.encode(exportPayload(\"copy\"))\n    rec = rec:gsub(\"&\", \"&#38;\"):gsub(\"<\", \"&#60;\"):gsub(\"'\", \"&#39;\")\n    add(\"<InputField id='cpyfld' fontSize='10' preferredHeight='130' lineType='MultiLineNewLine'\"\n      .. \" colors='#F1E5C8|#FFFFFF|#FFFFFF|#00000000' textColor='\" .. INKTXT .. \"' text='\" .. rec .. \"'/>\")\n    add('<HorizontalLayout preferredHeight=\"26\" spacing=\"6\" childForceExpandWidth=\"false\">')\n    add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n    add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  elseif S.overlay == \"info\" then\n    add('<Panel width=\"' .. (W - 110) .. '\" height=\"430\" color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"20 20 14 10\" spacing=\"3\">')\n    local function section(t, h, b, last)\n      add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredHeight=\"17\"'\n        .. ' alignment=\"MiddleLeft\"' .. NOClick .. '>' .. t .. '</Text>')\n      add('<Text fontSize=\"11\" color=\"' .. PARCH .. '\" preferredHeight=\"' .. h .. '\"'\n        .. ' alignment=\"UpperLeft\"' .. NOClick .. '>' .. b .. '</Text>')\n      if not last then\n        add('<Panel preferredHeight=\"1\" color=\"#C9A05C50\"' .. NOClick .. '/>')\n      end\n    end\n    section(\"SCORES\", 30,\n      \"Read automatically from VP markers. A settled marker on a fox, mouse, rabbit or bird Dominance card records turn and suit and offers dom win. With no same-faction marker on the score track this is standard dominance and freezes at -; with a second marker still on the track it is Brazen Demagogue and keeps scoring. Removing the card marker cancels either kind. A track marker reaching 30 ends the game.\")\n    section(\"TURNS\", 44,\n      \"Everything runs automatically once the TTS turn order is set and every faction has its seated player: each turn pass records the finishing faction by itself. Without that, END TURN records the highlighted faction. A lock always writes the highlighted round column, overwriting whatever it holds.\")\n    section(\"EDIT\", 44,\n      \"Correct anything: scores (click a cell), the round (click a column number), whose turn it is (click a portrait), faction order (&#9650;), player names, the Eyrie commander / Knaves captains / vagabond character (&#9660;), map, deck, game name and the unpicked faction.\")\n    section(\"EXPORT\", 40,\n      \"Posts the box score to Discord (set the webhook under DISCORD) and to the notebook. The footer reads confirmed with Discord once Discord has acknowledged the message. COPY opens the same record as selectable JSON &#8211; click the box, Ctrl+A, Ctrl+C (no other program needed).\")\n    section(\"CRAFT\", 44,\n      \"Watches the map's item supply. An item taken from it and placed by a faction's board is recorded as crafted that round, with its picture on the round's score cell. Returning an item to the supply cancels the craft. In EDIT, the ITEMS button corrects or adds crafts: click T# to pick the round, &#215; removes, + adds. Turning CRAFT off hides all crafts, exports included.\")\n    section(\"RESET\", 16,\n      \"Clears the sheet for a new game and re-detects map, deck, seats and markers.\", true)\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\" childForceExpandWidth=\"false\">')\n    add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"80\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  elseif S.setup and S.overlay == \"game\" then\n    add('<Panel width=\"' .. (W - 420) .. '\" height=\"66\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"12 12 12 12\" spacing=\"6\">')\n    add('<Text fontSize=\"13\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"90\"'\n      .. ' alignment=\"MiddleRight\"' .. NOClick .. '>game name</Text>')\n    add('<InputField id=\"mt_game\" fontSize=\"13\" flexibleWidth=\"1\"'\n      .. ' colors=\"#F1E5C8|#FFFFFF|#FFFFFF|#00000000\" textColor=\"' .. INKTXT\n      .. '\" onValueChanged=\"uiLiveEdit\" text=\"' .. fieldText(S.meta.game)\n      .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"map\" then\n    add('<Panel width=\"' .. (W - 200) .. '\" height=\"64\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"10 10 10 10\" spacing=\"5\">')\n    for mi, m in ipairs(MAPS) do\n      local sel = (S.meta.map == m)\n      chip(\"map_\" .. mi, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK, 0, 12,\n        sel and INKTXT or PARCH, esc(m))\n    end\n    chip(\"mpdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"deck\" then\n    add('<Panel width=\"' .. (W - 200) .. '\" height=\"64\" color=\"' .. WALNUT .. '\">')\n    add('<HorizontalLayout padding=\"10 10 10 10\" spacing=\"5\">')\n    for di, d in ipairs(DECKS) do\n      local sel = (S.meta.deck == d)\n      chip(\"deck_\" .. di, \"uiRowBtn\", sel and BTN_GOLD or PICK_DARK, 0, 12,\n        sel and INKTXT or PARCH, esc(d))\n    end\n    chip(\"dkdone\", \"uiOverlayClose\", BTN_GOLD, 0, 12, INKTXT, \"DONE\")\n    add('</HorizontalLayout></Panel>')\n  elseif S.setup and S.overlay == \"var\" then\n    local row = S.rows[S.varRow]\n    local opts = row and variantOptions(row.fac) or nil\n    if row and opts then\n      local chosen = {}\n      for w in (row.variant or \"\"):gmatch(\"[^,]+\") do\n        chosen[w:match(\"^%s*(.-)%s*$\")] = true\n      end\n      add('<Panel width=\"' .. (W - 140) .. '\" height=\"118\" color=\"' .. WALNUT .. '\">')\n      add('<VerticalLayout padding=\"10 10 10 10\" spacing=\"6\" childForceExpandHeight=\"false\">')\n      add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredHeight=\"18\"' .. NOClick .. '>'\n        .. esc(row.fac) .. ' &#8211; pick the character(s)</Text>')\n      for half = 1, 2 do\n        add('<HorizontalLayout preferredHeight=\"34\" spacing=\"4\">')\n        local from = (half - 1) * 6 + 1\n        for oi = from, math.min(from + 5, #opts) do\n          chip(\"vc_\" .. oi, \"uiRowBtn\", chosen[opts[oi]] and BTN_GOLD or PICK_DARK,\n            0, 10, chosen[opts[oi]] and INKTXT or PARCH, esc(opts[oi]))\n        end\n        if half == 2 then\n          chip(\"vcdone\", \"uiOverlayClose\", BTN_GOLD, 0, 11, INKTXT, \"DONE\")\n        end\n        add('</HorizontalLayout>')\n      end\n      add('</VerticalLayout></Panel>')\n    end\n  elseif S.setup and S.experimental and S.overlay == \"craft\" then\n    -- pinned by the top edge like the picker: opening the round or add row\n    -- grows the panel downward without shifting what is already there\n    local baseH = 64 + #S.rows * 32\n    local hh = baseH + ((S.craftAdd or S.craftPick) and 30 or 0)\n    local topY = math.max(8, math.floor((H - baseH) / 2))\n    add('<Panel width=\"' .. (W - 120) .. '\" height=\"' .. hh\n      .. '\" rectAlignment=\"UpperCenter\" offsetXY=\"0 -' .. topY .. '\"'\n      .. ' color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"10 10 8 8\" spacing=\"4\" childForceExpandHeight=\"false\">')\n    add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredHeight=\"16\"'\n      .. ' alignment=\"MiddleLeft\"' .. NOClick\n      .. '>CRAFTED ITEMS &#8211; click T# to set the round, &#215; removes, + adds</Text>')\n    for ci3, row in ipairs(S.rows) do\n      add('<HorizontalLayout preferredHeight=\"28\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"12\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>' .. esc(row.fac) .. '</Text>')\n      for k, c in ipairs(row.crafts or {}) do\n        if c.img and c.img ~= \"\" then\n          add('<Panel preferredWidth=\"20\"' .. NOClick .. '><Image image=\"it' .. urlTail(c.img)\n            .. '\" width=\"18\" height=\"18\"' .. NOClick .. '/></Panel>')\n        end\n        add('<Text fontSize=\"11\" color=\"' .. PARCH .. '\" preferredWidth=\"56\" alignment=\"MiddleLeft\"'\n          .. NOClick .. '>' .. esc(c.item) .. '</Text>')\n        local selT = S.craftPick ~= nil and S.craftPick.i == ci3 and S.craftPick.k == k\n        chip(\"cfr_\" .. ci3 .. \"_\" .. k, \"uiCraftBtn\", selT and BTN_GOLD or PICK_DARK, 32, 10,\n          selT and INKTXT or PARCH, \"T\" .. tostring(c.r or \"?\"))\n        chip(\"cfx_\" .. ci3 .. \"_\" .. k, \"uiCraftBtn\", PICK_DARK, 24, 10, PARCH, \"&#215;\")\n        add('<Text preferredWidth=\"4\"' .. NOClick .. '> </Text>')\n      end\n      chip(\"cfadd_\" .. ci3, \"uiCraftBtn\", (S.craftAdd == ci3) and BTN_GOLD or PICK_DARK, 26, 12,\n        (S.craftAdd == ci3) and INKTXT or PARCH, \"+\")\n      add('</HorizontalLayout>')\n    end\n    if S.craftPick ~= nil then\n      add('<HorizontalLayout preferredHeight=\"26\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"11\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>round:</Text>')\n      for r2 = 1, math.max(1, S.cols or 10) do\n        chip(\"cfpick_\" .. r2, \"uiCraftBtn\", PICK_DARK, 34, 10, PARCH, \"T\" .. r2)\n      end\n      add('</HorizontalLayout>')\n    end\n    if S.craftAdd ~= nil and S.rows[S.craftAdd] ~= nil then\n      add('<HorizontalLayout preferredHeight=\"26\" spacing=\"4\" childForceExpandWidth=\"false\">')\n      add('<Text fontSize=\"11\" fontStyle=\"Bold\" color=\"' .. GOLD .. '\" preferredWidth=\"90\"'\n        .. ' alignment=\"MiddleRight\"' .. NOClick .. '>add:</Text>')\n      for k, nm in ipairs(ITEM_NAMES) do\n        chip(\"cfnew_\" .. k, \"uiCraftBtn\", PICK_DARK, 74, 10, PARCH, esc(nm))\n      end\n      add('</HorizontalLayout>')\n    end\n    add('<HorizontalLayout preferredHeight=\"26\" spacing=\"6\" childForceExpandWidth=\"false\">')\n    add('<Text flexibleWidth=\"1\"' .. NOClick .. '> </Text>')\n    add('<Button fontSize=\"12\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  elseif S.setup and S.overlay == \"discord\" then\n    add('<Panel width=\"' .. (W - 160) .. '\" height=\"118\" color=\"' .. WALNUT .. '\">')\n    add('<VerticalLayout padding=\"12 12 10 10\" spacing=\"6\">')\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\">')\n    add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"72\" alignment=\"MiddleRight\"' .. NOClick .. '>webhook</Text>')\n    add('<InputField id=\"mt_hook\" fontSize=\"13\" flexibleWidth=\"1\" colors=\"#F1E5C8|#FFFFFF|#FFFFFF|#00000000\"'\n      .. ' textColor=\"' .. INKTXT .. '\" placeholder=\"Discord webhook URL\"'\n      .. ' text=\"' .. fieldText(S.meta.hook) .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('</HorizontalLayout>')\n    add('<HorizontalLayout preferredHeight=\"30\" spacing=\"6\">')\n    add('<Text fontSize=\"14\" fontStyle=\"Bold\" color=\"' .. PARCH .. '\" preferredWidth=\"72\" alignment=\"MiddleRight\"' .. NOClick .. '>thread</Text>')\n    add('<InputField id=\"mt_thread\" fontSize=\"13\" flexibleWidth=\"1\" colors=\"#F1E5C8|#FFFFFF|#FFFFFF|#00000000\"'\n      .. ' textColor=\"' .. INKTXT .. '\" placeholder=\"thread link (optional)\"'\n      .. ' text=\"' .. fieldText(S.meta.thread) .. '\" onEndEdit=\"uiMetaEdit\"/>')\n    add('<Button fontSize=\"13\" fontStyle=\"Bold\" preferredWidth=\"70\" ' .. BTN_GOLD\n      .. ' text=\"DONE\" onClick=\"uiOverlayClose\"/>')\n    add('</HorizontalLayout>')\n    add('</VerticalLayout></Panel>')\n  end\n\n  add('</Panel>')\n  self.UI.setXml(table.concat(x))\nend\n\n---------------------------------------------------------------- persistence --\nfunction onSave()\n  return JSON.encode(S)\nend\n\nfunction onLoad(saved)\n  local loadedState = false\n  if saved ~= nil and saved ~= \"\" then\n    local ok, d = pcall(function() return JSON.decode(saved) end)\n    if ok and d ~= nil and d.rows ~= nil then S = d; loadedState = true end\n  end\n  S.meta = S.meta or { map = \"\", deck = \"\", hook = \"\", thread = \"\" }\n  S.meta.deck = S.meta.deck or \"\"\n  -- old builds stored pre-escaped text; normalize once so it can never\n  -- round-trip into the display again\n  S.meta.deck = S.meta.deck:gsub(\"&amp;\", \"+\"):gsub(\"&#38;\", \"+\"):gsub(\"&\", \"+\")\n  S.meta.map = (S.meta.map or \"\"):gsub(\"&amp;\", \"&\"):gsub(\"&#38;\", \"&\")\n  S.meta.hook = S.meta.hook or \"\"\n  S.meta.thread = S.meta.thread or \"\"\n  S.meta.game = S.meta.game or \"\"\n  -- a webhook baked into GMNotes (by build.py) is the default\n  if S.meta.hook == \"\" then\n    local gm = self.getGMNotes() or \"\"\n    if gm:match(\"^https?://\") then S.meta.hook = gm:gsub(\"%s+$\", \"\") end\n  end\n  S.undo = S.undo or {}\n  S.log = S.log or {}\n  S.unpicked = S.unpicked or {}\n  S.unpickedVar = S.unpickedVar or {}\n  S.varRow = S.varRow or 1\n  S.experimental = S.experimental or false\n  S.itemImgs = S.itemImgs or {}\n  S.turns = S.turns or 0\n  S.active = S.active or 1\n  if S.active > math.max(1, #S.rows) then S.active = 1 end\n  local domWinner = nil\n  for _, row in ipairs(S.rows) do\n    row.locks = row.locks or {}\n    row.edits = row.edits or {}\n    row.crafts = row.crafts or nil\n    row.score = row.score or -1\n    row.player = row.player or \"\"\n    if row.dom ~= nil then\n      row.dom.turn = math.max(1, math.floor(tonumber(row.dom.turn) or 1))\n      row.dom.round = math.max(1, math.floor(tonumber(row.dom.round) or 1))\n      row.dom.suit = tostring(row.dom.suit or \"\"):lower()\n      row.dom.score = tonumber(row.dom.score) or row.score\n      row.dom.won = row.dom.won == true\n      local brazen = row.dom.kind == \"brazen_demagogue\" or row.dom.frozen == false\n      row.dom.kind = brazen and \"brazen_demagogue\" or \"standard\"\n      row.dom.frozen = not brazen\n      if row.dom.markerGuid == \"\" then row.dom.markerGuid = nil end\n      if row.dom.won then domWinner = row.fac end\n    end\n  end\n  if domWinner ~= nil then\n    S.winner = domWinner\n    S.winnerReason = \"dominance\"\n    S.winnerLock = nil\n  elseif S.winner ~= nil and S.winnerReason == nil then\n    S.winnerReason = \"score\"\n  end\n  S.cols = S.cols or 10\n  S.scaleMode = S.scaleMode or 1\n  if S.sizePct == nil then\n    local oldIdx = math.floor(tonumber(S.sizeIdx) or 2)\n    local oldMul = LEGACY_SIZE_MULS[oldIdx] or LEGACY_BASE_MUL\n    S.sizePct = math.floor(oldMul / LEGACY_BASE_MUL * 10 + 0.5) * 10\n  end\n  -- A brand-new RTT spawn has no LuaScriptState, so recover the percentage\n  -- remembered by the prior copy.  A real saved state always wins.\n  if not loadedState then\n    local ok, remembered = pcall(function()\n      return Global.getVar(\"RTT_BOXSCORE_SIZE_PCT\")\n    end)\n    if ok and tonumber(remembered) ~= nil then S.sizePct = tonumber(remembered) end\n  end\n  S.sizePct = clampSizePct(S.sizePct)\n  S.sizeIdx = nil\n  rememberSizePct()\n  S.setup = S.setup or false\n  S.overlay = nil\n  S.lastExport = S.lastExport or \"\"\n\n  self.addContextMenuItem(\"setup / done\", uiSetup, false)\n  self.addContextMenuItem(\"reset box score\", uiReset, false)\n  self.addContextMenuItem(\"hide / show\", uiHide, false)\n  self.addContextMenuItem(\"export\", uiExport, false)\n  self.addContextMenuItem(\"flip track\", uiFlip, false)\n  self.addContextMenuItem(\"spin panel\", uiSpin, false)\n  self.addContextMenuItem(\"size +10%\", uiSizeUp, false)\n  self.addContextMenuItem(\"size -10%\", uiSizeDown, false)\n  self.addContextMenuItem(\"panel scale mode\", uiScaleMode, false)\n  self.addContextMenuItem(\"diagnose\", uiDiag, false)\n\n  Wait.time(function()\n    findTrack()\n    for _, row in ipairs(S.rows) do\n      local m = findMarker(row)\n      if m then row.iconUrl = markerImage(m) end\n    end\n    refreshAssets()\n    rebuildUI()\n    Wait.time(poll, POLL_SECONDS, -1)\n  end, 2)\nend\n","LuaScriptState":"","XmlUI":""}]====]
RTT_BOXSCORE_TAG = "RTT BoxScore"

RTT_PICK_DEFS = {
  rttPickMap1  = { kind = "map",  id = "Summer Map",   label = "Autumn" },
  rttPickMap2  = { kind = "map",  id = "Winter Map",   label = "Winter" },
  rttPickMap3  = { kind = "map",  id = "Lake Map",     label = "Lake" },
  rttPickMap4  = { kind = "map",  id = "Marsh Map",    label = "Marsh" },
  rttPickMap5  = { kind = "map",  id = "Mountain Map", label = "Mountain" },
  rttPickMap6  = { kind = "map",  id = "Gorge Map",    label = "Gorge" },
  rttPickDeck1 = { kind = "deck", id = "Standard Deck",              label = "Standard" },
  rttPickDeck2 = { kind = "deck", id = "Exiles and Partisans Deck",  label = "Exiles & Partisans" },
  rttPickDeck3 = { kind = "deck", id = "Squires and Disciples Deck", label = "Squires & Disciples" },
}
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
RTT_BOARD_SEAT = {}     -- [board guid] = seat index

-- ==== seat-by-turn-order-card tables (RTT seating restore) ==================
RTT_SETUP_COLORS   = { "Red", "Yellow", "Orange", "Teal", "Green", "Brown" }   -- base setupColors: seat N -> colour N
RTT_HAND_SCALE     = { 20, 6, 4 }                                              -- base handScale (RTT had dropped it)
RTT_CARDID_FOR_N   = { 800, 801, 802, 805, 806 }                              -- seat N -> "Player N" order-card CardID
RTT_ORDER_CARD_NUM = { [800]=1, [801]=2, [802]=3, [805]=4, [806]=5 }           -- inverse: order-card CardID -> its number

function rttSpawnSelectors()
  for _, o in ipairs(getObjectsWithTag(RTT_SELECTOR_TAG)) do o.destruct() end
  RTT_CLONES = {}
  RTT_SEATS = {}
  RTT_BOARD_SEAT = {}
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
    RTT_BOARD_SEAT[board.getGUID()] = i
    RTT_SEATS[i] = { board = board, color = nil, pos = p, hand = RTT_SEAT_HAND[pi] }
  end
end

-- Seat by TURN-ORDER CARD, restoring the base placePlayer path (changeColor + base handPositions
-- geometry + base handScale) but TRIGGERED at turn-order time instead of on faction pick. ONE
-- shuffle sets the turn order; each player is seated at the seat matching their card's number and
-- then handed the matching "Player N" card, so it lands in the seated hand (not the off-table reset
-- strip at x=-77.5 that looked like "trash"). Uses the base's exact SAFE sequence: kick everyone to
-- Grey FIRST, then a FRESH getPlayers() loop matched by steam_name -- a pre-kick Player ref is stale
-- after the colour change, which is why capturing refs then kicking would seat nobody.
function rttSeatPlayers()
  -- real humans (steam_names survive the kick; Player refs don't).
  local humans = {}
  for _, p in ipairs(Player.getPlayers()) do
    if p.seated and p.color ~= "Grey" and p.color ~= "Black" then humans[#humans + 1] = p.steam_name end
  end
  -- Assign each human a RANDOM seat NUMBER out of ALL N seats, so the turn-order card is random for
  -- everyone -- including a lone tester, who previously always landed in seat 1 / "First Player".
  -- Seat NUMBER = each human's position in RTT_ORDER (the SINGLE shuffle done once in rttDealOrder,
  -- which also drives the Roster and box-score order). So the "Player N" turn-order card a person is
  -- dealt now MATCHES the order they are shown in. Previously a SECOND independent shuffle handed out
  -- the cards, so 'First Player' and box-score seat 1 were usually different people (audit HIGH).
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
  pcall(function() kickPlayersFromSeats() end)           -- base: everyone -> Grey (frees the colours; no hand reset)
  local seated = {}                                      -- [seat N] = seat colour, for the deferred card
  for _, p in ipairs(Player.getPlayers()) do             -- FRESH, post-kick (base pattern): refs are valid
    local sN = seatOf[p.steam_name]
    if sN ~= nil then
      local seat = RTT_SEATS[sN]
      if seat ~= nil and seat.board ~= nil and seat.hand ~= nil then
        local color = RTT_SETUP_COLORS[sN]
        pcall(function() p.changeColor(color) end)       -- base placePlayer op 1: put the player INTO the seat colour
        pcall(function()                                 -- base placePlayer op 2: move that colour's hand zone (+ base scale)
          Player[color].setHandTransform(
            { position = seat.hand.pos, rotation = seat.hand.rot, scale = RTT_HAND_SCALE }, 1)
        end)
        seat.color = color
        RTT_CLONES[color] = seat.board
        seated[sN] = color
      end
    end
  end
  -- SWITCH THE TTS TURN SYSTEM ON, with the real seat order.
  -- Nothing in this mod ever did. The scene ships Turns.Enable = false and onLoad only assigns a
  -- hardcoded Turns.order; Turns.enable was never set anywhere in 4,800 lines. So the turn system was
  -- off in every game, which is why the box score sat permanently in manual mode showing END TURN --
  -- it was reporting the truth, there was nothing to follow.
  -- Order is the SEATED colours in seat order, so seat 1 starts; skip_empty_hands stops TTS pausing on
  -- colours nobody occupies, which matters because RTT always builds 4-6 seats regardless of how many
  -- humans joined. enable is set LAST, once the order and starting colour are in place.
  rttEnableTurns((RTT_DN or 5) - 1)

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
  RTT_PICK_STAGE = 0                             -- map/deck pick REMOVED (the maintainer places them manually)
  if RTT_5P_MARSH then rttPlaceMap("Marsh Map") end   -- the 5-player button still auto-places its Marsh map
  rttSpawnSelectors()
  rttAfterFrames(function() rttSeatPlayers() rttStartFactionDraft() end, 10)
end

function rttShowPick(stage)
  local seat = (stage == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  local clone = RTT_CLONES[seat.color]
  if clone == nil then return end
  clone.UI.setAttribute("rttPickMapDeck", "active", "true")
  for _, b in ipairs(RTT_MAP_BTNS)  do clone.UI.setAttribute(b, "active", (RTT_PICKED.map  == nil) and "true" or "false") end
  for _, b in ipairs(RTT_DECK_BTNS) do clone.UI.setAttribute(b, "active", (RTT_PICKED.deck == nil) and "true" or "false") end
  local what
  if RTT_5P_MARSH then what = "Pick a DECK"
  else what = (stage == 1) and "Pick a MAP or a DECK" or ("Pick the " .. ((RTT_PICKED.map == nil) and "MAP" or "DECK")) end
  clone.UI.setAttribute("rttPickTitle", "text", what)
end

-- ---- the timer and counter, spawned with every map -----------------------------------------
-- Maintainer 2026-09-04: "every time we spawn a map, same as the battle mat, these two objects are
-- spawned at the same time, always with the map". Recovered from his save (TS_Save_22): a
-- Digital_Clock and a Counter at the bottom right of the map. Their blobs carry a zeroed Transform and
-- no GUID -- position comes from the spawn call and TTS assigns a fresh guid -- and both are tagged
-- "Map Object", exactly like the battle mat, so removeMapItems() replaces them with each new map
-- instead of stacking copies.
RTT_TIMER_JSON = [==[{"Name":"Digital_Clock","Transform":{"posX":0.0,"posY":0.0,"posZ":0.0,"rotX":90.0,"rotY":359.983582,"rotZ":0.0,"scaleX":1.10714281,"scaleY":1.10714281,"scaleZ":0.110714279},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.0,"g":0.0,"b":0.0},"LayoutGroupSortIndex":0,"Value":0,"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"Clock":{"Mode":3,"SecondsPassed":0,"Paused":true},"LuaScript":"function onPlayerTurnStart(pl, prevpl)\n  self.Clock.startStopwatch()\nend\n","LuaScriptState":"","XmlUI":""}]==]
RTT_COUNTER_JSON = [==[{"Name":"Counter","Transform":{"posX":0.0,"posY":0.0,"posZ":0.0,"rotX":-4.53648958e-08,"rotY":-5.28580422e-05,"rotZ":-2.90506961e-07,"scaleX":1.24999976,"scaleY":1.24999976,"scaleZ":1.24999976},"Nickname":"","Description":"","GMNotes":"","AltLookAngle":{"x":0.0,"y":0.0,"z":0.0},"ColorDiffuse":{"r":0.0823529139,"g":0.0823529139,"b":0.0823529139},"LayoutGroupSortIndex":0,"Value":0,"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"Counter":{"value":0},"LuaScript":"","LuaScriptState":"","XmlUI":""}]==]
RTT_TIMER_POS   = { 17.3624, 11.6669, -26.3142 }
RTT_COUNTER_POS = { 22.9297, 11.5240, -25.1741 }
RTT_TIMER_ROT   = { 90.0000, 359.9836, 0.0000 }
RTT_COUNTER_ROT = { -0.0000, -0.0001, -0.0000 }

function rttSpawnMapExtras()
  pcall(function() rttSpawnBoxScore() end)         -- it destructs any previous sheet, so this replaces
  for _, e in ipairs({ { RTT_TIMER_JSON, RTT_TIMER_POS, RTT_TIMER_ROT },
                       { RTT_COUNTER_JSON, RTT_COUNTER_POS, RTT_COUNTER_ROT } }) do
    spawnObjectJSON({
      json = e[1],
      position = e[2],
      rotation = e[3],                             -- the clock stands upright (rotX 90); {0,0,0} laid it flat
      callback_function = function(o)
        pcall(function() local t = o.getTags(); table.insert(t, "Map Object"); o.setTags(t) end)
      end
    })
  end
end

function rttPlaceMap(mapId)
  makeMap("", "", mapId)      -- makeMap spawns the battle mat itself now
end

function rttPlaceDeck(deckId)
  local id = deckId
  if #RTT_ORDER <= 2 then id = id .. " 2" end
  makeDeck("", "", id)
end

-- runs on the COORDINATOR (relayed from a selector)
function rttCoordPick(args)
  local def = RTT_PICK_DEFS[args.id]
  if def == nil or RTT_PICK_STAGE == 0 then return end
  local seat = (RTT_PICK_STAGE == 1) and RTT_ORDER[1] or (RTT_ORDER[2] or RTT_ORDER[1])
  if (not RTT_SOLO) and args.color ~= seat.color then return end
  local clone = RTT_CLONES[seat.color]

  if RTT_PICK_STAGE == 1 then
    if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
    else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
    if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end
    if RTT_5P_MARSH then rttPlaceMap("Marsh Map") RTT_PICK_STAGE = 0 rttStartFactionDraft() return end
    RTT_PICK_STAGE = 2
    rttShowPick(2)
    return
  end

  if RTT_PICKED.map == nil and def.kind ~= "map" then return end
  if RTT_PICKED.deck == nil and def.kind ~= "deck" then return end
  if def.kind == "map" then RTT_PICKED.map = def.id rttPlaceMap(def.id)
  else RTT_PICKED.deck = def.id rttPlaceDeck(def.id) end
  if clone ~= nil then clone.UI.setAttribute("rttPickMapDeck", "active", "false") end
  RTT_PICK_STAGE = 0
  rttStartFactionDraft()
end

-- ===== phase 3: reverse-order faction draft off the 5 dealt cards =====
RTT_FAC_STAGE = 0
RTT_FAC_TAKEN = {}
RTT_FAC_CURRENT = {}

-- spawn the Root Box Score sheet at the maintainer's placed spot (read from his TTS save),
-- rotated 270 to face the camera, sized to fill the board-design rectangle (scale up
-- ~1.3x wide / ~1.1x tall baked into _boxscore.json), locked to the table.
function rttSpawnBoxScore()
  for _, o in ipairs(getObjectsWithTag(RTT_BOXSCORE_TAG)) do o.destruct() end
  -- tell the box score how many player rows to pre-format for (4 ranked / 5 for 5p Marsh); it reads
  -- this Global each rebuild and grows past it only if more players are added.
  Global.setVar("RTT_BOXSCORE_MIN", (RTT_DN or 5) - 1)
  spawnObjectJSON({
    json = RTT_BOXSCORE_JSON,
    position = { -58.36, 11.652, -0.05 },   -- centre of the maintainer's 4-card box-score rectangle
    rotation = { 0, 270, 0 },
    callback_function = function(o) o.addTag(RTT_BOXSCORE_TAG) o.setLock(true) end
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
-- captains board = maintainer's LEFT of the Knaves board, raised HIGHER. His save has it at world
-- (63.71,-46.18) = worldoff (+15.84,+4.80); spawn formula gives worldoff = (-OFF_X, -OFF_Z), so both signs
-- are NEGATIVE. (The crafted board now sits on the SAME left, stacked BELOW it -- see its move_to.)
-- Recovered from the maintainer's save 'knaves' (TS_Save_21), seat 2: he nudged the captains board,
-- so these are solved from where he left it relative to the Knaves rules board.
RTT_CAP_OFF_X    = -15.6676
RTT_CAP_OFF_Z    = -4.5206
-- (snaps are BAKED into RTT_CAPTAIN_BOARD_JSON now; the old slot-fraction / self-size constants are gone)
-- The real Crafted Improvements art, cropped to its TOP 3 overlapping card slots (+ its real title
-- repainted to "Captains" and its real bottom border). 3 snaps for 3 captains stacked ON TOP of each
-- other (the crafted board's overlap look, just 3 instead of 5). Snaps computed with the verified
-- local_z = 2*py/H - 1 for the cropped H=1560; scale dropped to 7.59394 = 9.516764*(1560/1955) so a card
-- stays the same physical size as the full board. See [[rtt-tile-snap-geometry]].
RTT_CAPTAIN_BOARD_JSON = [==[{"Name":"Custom_Tile","Transform":{"posX":0.0,"posY":11.5,"posZ":0.0,"rotX":0.0,"rotY":0.0,"rotZ":0.0,"scaleX":13.24558,"scaleY":1.0,"scaleZ":13.24558},"Nickname":"Knaves Captains","Description":"","ColorDiffuse":{"r":1.0,"g":1.0,"b":1.0},"Locked":true,"Grid":true,"Snap":true,"IgnoreFoW":false,"MeasureMovement":false,"DragSelectable":true,"Autoraise":true,"Sticky":true,"Tooltip":true,"GridProjection":false,"HideWhenFaceDown":false,"Hands":false,"AttachedSnapPoints":[{"Position":{"x":0.0,"y":0.2,"z":-0.52}},{"Position":{"x":0.0,"y":0.2,"z":0.0614}},{"Position":{"x":0.0,"y":0.2,"z":0.6428}}],"CustomImage":{"ImageURL":"https://cdn.jsdelivr.net/gh/mrdrouf/root-tabletop-tournament@main/assets/labels/knaves_captains_v8.png","ImageSecondaryURL":"","ImageScalar":1.0,"WidthScale":0.0,"CustomTile":{"Type":0,"Thickness":0.1,"Stackable":false,"Stretch":true}}}]==]

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

-- one Knaves warrior below the captain row (board-local from his save: z=-1.137, x = -0.510, -0.260, -0.007).
function rttSpawnCaptainWarrior(idx)
  if RTT_CAP_WARRIOR_JSON == nil then rttBuildCaptainWarrior() end
  local kb = getObjectFromGUID(RTT_CAP_KNAVE_GUID or "")
  if RTT_CAP_WARRIOR_JSON == nil or kb == nil then return end
  local fry = kb.getRotation().y; local by = kb.getPosition().y
  local wp = kb.positionToWorld({ -0.510 + idx * 0.25, 0, -1.137 })
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
  local seat = RTT_BOARD_SEAT[args.board or ""]
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
  RTT_BOARD_SEAT[clone.getGUID()] = nil
  if s.color ~= nil then RTT_CLONES[s.color] = nil end
  clone.destruct()                                     -- board gone first, then the faction spawns there
  -- s.hand is this seat's RTT_SEAT_HAND entry -- exactly what rttSeatPlayers put on hand 1.
  local seatHand = s.hand and { position = s.hand.pos, rotation = s.hand.rot } or nil
  rttPlaceFaction(faction, bp.x, bp.z, bp.z > 0, s.color or args.color, true, nil, nil, args.color, seatHand)
  Wait.frames(function() rttShowFactions() end, 10)    -- refresh remaining boards
end

-- spawn a faction's pieces at (cx,cz), WITHOUT dice (m060). Warrior placements (m290
-- Lizard, m300 Duchy) are baked into the faction data, so they come along. flip rotates
-- the setup 180 for a far-side (z>0) seat. Mirrors tournamentSpawnDraftFaction's math.
function rttSpawnFaction(faction, cx, cz, flip, category, rotationY)
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
    if not isDice and not isCap then objects[#objects + 1] = v end
  end
  local scale = self.getScale()
  scale.x = 1 / scale.x
  scale.z = 1 / scale.z
  local spawnRy = rotationY or (flip and 180 or 0)
  local function cb(o)
    o.addTag("RTT Faction")
    -- Tag THIS spawn's own fresh VP marker. Two of the same faction on the table (solo testing) share
    -- the marker name "<short> VP", so a name-only search grabbed the FIRST (already-placed) marker and
    -- moved it again. The tag lets rttPlaceVP move the marker THIS spawn just created, then clears it.
    if (o.getName() or "") == rttVPName(faction) then o.addTag("RTT VP Unplaced") end
    if spawnRy ~= 0 then o.setRotation({ o.getRotation().x, o.getRotation().y + spawnRy, o.getRotation().z }) end
    if o.hasTag("Ruin Set") then o.destroy() end
    if o.hasTag("Shuffleable") then o.shuffle() o.shuffle() end
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
  return true
end

-- Both ranked and manual faction selectors come through this one automation path:
-- spawn the blueprint (including its single base VP marker), publish the faction's
-- physical seat, run the faction extras, then MOVE that marker onto score zero.
function rttPlaceFaction(faction, cx, cz, flip, color, isDraft, category, rotationY, pickerColor, seatHand)
  if not rttSpawnFaction(faction, cx, cz, flip, category, rotationY) then return false end

  -- Raw Lua tables do not cross object-script boundaries, so the accumulated map
  -- remains a JSON string. Guard decoding because selector boards relay through a
  -- clone script and an old/malformed Global value must not break faction setup.
  local seats = {}
  local okRaw, raw = pcall(function() return Global.getVar("RTT_SEAT_POS") end)
  if okRaw and type(raw) == "string" and raw ~= "" then
    local okMap, decoded = pcall(function() return JSON.decode(raw) end)
    if okMap and type(decoded) == "table" then seats = decoded end
  end
  seats[faction] = { cx, cz }
  Global.setVar("RTT_SEAT_POS", JSON.encode(seats))

  -- Publish the faction's real SEAT COLOUR too. The box score otherwise guesses a row's colour by
  -- matching the faction's supply to the nearest HAND ZONE, and Player[c].getHandTransform() returns a
  -- position for every colour whether or not anyone is sitting in it -- so rows came out White/Pink,
  -- colours RTT never seats anyone in, and solo only one row could ever pick up the player's name.
  -- Only the DRAFT path is authoritative: there `color` is the seat's colour (RTT_SETUP_COLORS[N]). On
  -- the manual selector path `color` is just whoever clicked, identical for every faction they pick, so
  -- publishing it would bind every row to one colour. Hence the isDraft guard.
  -- The faction's colour is the SEAT's colour, which exists whether or not a human occupies that seat.
  -- Derived from the seat position rather than from `color`: rttSeatPlayers only sets seat.color for
  -- SEATED humans, so on the draft path `s.color or args.color` fell back to the PICKER for every empty
  -- seat -- solo, that published the same colour for every faction and the box score showed one player
  -- heading several of them.
  local seatColor = nil
  do
    local best, bi = nil, nil
    for i, sp in ipairs(RTT_POS) do
      local d = (sp[1] - cx) ^ 2 + (sp[2] - cz) ^ 2
      if best == nil or d < best then best, bi = d, i end
    end
    if bi ~= nil then seatColor = RTT_SETUP_COLORS[bi] end
  end
  if seatColor ~= nil and seatColor ~= "" then
    local cols = {}
    local okC, rawC = pcall(function() return Global.getVar("RTT_SEAT_COLOR") end)
    if okC and type(rawC) == "string" and rawC ~= "" then
      local okD, dec = pcall(function() return JSON.decode(rawC) end)
      if okD and type(dec) == "table" then cols = dec end
    end
    cols[faction] = seatColor
    Global.setVar("RTT_SEAT_COLOR", JSON.encode(cols))
  end

  -- WHO OWNS the faction, published separately from the seat colour. These are two different things and
  -- conflating them broke naming: the manual 4-board path never recolours anyone, so a player keeps the
  -- colour they joined with while the rows are coloured by SEAT -- and the box score, which attaches a
  -- name by matching the row's colour to a seated player, then found no match and showed no name at all.
  -- Colour stays seat-derived (the turn order needs that); the NAME comes from whoever picked.
  if pickerColor ~= nil and pickerColor ~= "" then
    local who = nil
    pcall(function()
      for _, pl in ipairs(Player.getPlayers()) do
        if pl.color == pickerColor and pl.seated then who = pl.steam_name end
      end
    end)
    if who ~= nil and who ~= "" then
      local owners = {}
      local okO, rawO = pcall(function() return Global.getVar("RTT_SEAT_PLAYER") end)
      if okO and type(rawO) == "string" and rawO ~= "" then
        local okD, dec = pcall(function() return JSON.decode(rawO) end)
        if okD and type(dec) == "table" then owners = dec end
      end
      owners[faction] = who
      Global.setVar("RTT_SEAT_PLAYER", JSON.encode(owners))
    end
  end

  local extraFaction, extraX, extraZ, extraFlip, extraDraft = faction, cx, cz, flip, isDraft == true
  Wait.time(function() rttFactionExtras(extraFaction, extraX, extraZ, extraFlip, extraDraft) end, 0.5)

  RTT_VP_PLACED = (RTT_VP_PLACED or 0) + 1
  local vpN, vpF = RTT_VP_PLACED, faction
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
function rttVPName(faction) return (RTT_VP_SHORT[faction] or faction) .. " VP" end

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
-- Four decks laid out in a row on the right of the table, exactly as he saved them: the first deck
-- keeps its own table position and the rest are offset by the relative x/z the save records.
-- Not tagged for teardown -- like the other tool buttons, this is a reference aid that survives a
-- new game rather than faction kit that goes out with it.
RTT_HOOT = {
  { pos = { 66.140, 11.610, 23.260 }, json = [===[{"GUID": "403b02","Name": "Deck","Transform": {"posX": 66.13635,"posY": 11.6113586,"posZ": 23.2569218,"rotX": -4.18478443e-08,"rotY": 269.989532,"rotZ": -1.441599e-08,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"Tags": ["Shuffleable"],"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [309,307,310,301,73200,300],"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"732": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10042992881391430383/BAE426B4F4BD70FF7A6084DFA55961800C0F83DF/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "39be49","Name": "Card","Transform": {"posX": -1.66627669,"posY": 1.05879366,"posZ": -4.028566,"rotX": -0.0006826586,"rotY": 179.990768,"rotZ": -0.00112713769,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 309,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e8f093","Name": "Card","Transform": {"posX": -1.05922115,"posY": 0.9735951,"posZ": -3.99652,"rotX": 4.55595364e-05,"rotY": 179.990768,"rotZ": -0.000284563663,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 307,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "ed28df","Name": "Card","Transform": {"posX": -1.00858307,"posY": 1.15495336,"posZ": -3.80439377,"rotX": 1.40676332,"rotY": 179.996048,"rotZ": 5.81672975e-05,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 310,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "8df1be","Name": "Card","Transform": {"posX": -0.282207727,"posY": 1.04952276,"posZ": -3.6216743,"rotX": 0.00066678843,"rotY": 179.990768,"rotZ": -0.0006546988,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 301,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "35b81a","Name": "CardCustom","Transform": {"posX": 57.3735352,"posY": 11.6722345,"posZ": 22.0381832,"rotX": 0.0005990316,"rotY": 269.986877,"rotZ": -0.0033355006,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73200,"SidewaysCard": false,"CustomDeck": {"732": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10042992881391430383/BAE426B4F4BD70FF7A6084DFA55961800C0F83DF/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "c8f4ed","Name": "Card","Transform": {"posX": -1.57336509,"posY": 1.015244,"posZ": -3.802666,"rotX": 0.000971112,"rotY": 179.990768,"rotZ": -0.00130566931,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 300,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
  { pos = { 58.220, 11.610, 23.175 }, json = [===[{"GUID": "9957df","Name": "Deck","Transform": {"posX": -7.920185,"posY": 0.0,"posZ": -0.08452225,"rotX": -5.06577758e-09,"rotY": 269.9901,"rotZ": 2.459669e-08,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"Tags": ["Shuffleable"],"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [305,302,73000,304,308,73300],"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"730": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/17156148149837033890/98EA362B4304B9B9E5825AAE0D213A17FC4BBB7C/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0},"733": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10654530041309384819/5D0D59497688830C050F1BA44431CAB1104B7F3F/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "bdce9c","Name": "Card","Transform": {"posX": -34.3895874,"posY": 11.6095686,"posZ": 27.29517,"rotX": 359.7493,"rotY": 180.002716,"rotZ": 359.870728,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 305,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "c7b1d4","Name": "Card","Transform": {"posX": 5.14010143,"posY": 2.063494,"posZ": -4.39241171,"rotX": 359.8631,"rotY": 179.974548,"rotZ": -0.002107894,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 302,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "9be262","Name": "CardCustom","Transform": {"posX": 65.30026,"posY": 11.7010155,"posZ": 22.1271057,"rotX": 0.000114221068,"rotY": 269.986877,"rotZ": -0.0006956121,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73000,"SidewaysCard": false,"CustomDeck": {"730": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/17156148149837033890/98EA362B4304B9B9E5825AAE0D213A17FC4BBB7C/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "201005","Name": "Card","Transform": {"posX": -34.0781059,"posY": 11.6981983,"posZ": 27.2413673,"rotX": 0.0345823355,"rotY": 180.00032,"rotZ": 0.0251624361,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 304,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "06ace2","Name": "Card","Transform": {"posX": 49.28753,"posY": 11.5751371,"posZ": 22.6206779,"rotX": 5.08970043e-05,"rotY": 269.9901,"rotZ": -0.000322228385,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 308,"SidewaysCard": false,"CustomDeck": {"3": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/1859434225081947922/03DD57D219121078CF0C1952D6792FF19D9D373A/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1833522185803078168/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 6,"NumHeight": 2,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e88b64","Name": "CardCustom","Transform": {"posX": 49.4498253,"posY": 11.6168051,"posZ": 23.0559349,"rotX": 0.00105606078,"rotY": 269.9901,"rotZ": -0.00123060483,"scaleX": 2.29997349,"scaleY": 1.0,"scaleZ": 2.29997349},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73300,"SidewaysCard": false,"CustomDeck": {"733": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/10654530041309384819/5D0D59497688830C050F1BA44431CAB1104B7F3F/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/1799745188598220361/A2050800715C7861D93951496663C01554EF2E32/","NumWidth": 1,"NumHeight": 1,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
  { pos = { 50.219, 11.610, 23.191 }, json = [===[{"GUID": "e8dd4b","Name": "Deck","Transform": {"posX": -15.9210091,"posY": 0.028883934,"posZ": -0.0693779,"rotX": -7.1069195e-07,"rotY": 270.004669,"rotZ": -3.43679e-08,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": false,"SidewaysCard": false,"DeckIDs": [73409,73407,73410,73408,73406,73405,73404,73403,73402,73401,73400,73411],"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": "","ContainedObjects": [{"GUID": "acbc3d","Name": "Card","Transform": {"posX": -37.2867622,"posY": 12.70675,"posZ": -46.94957,"rotX": 0.0173129272,"rotY": 179.077057,"rotZ": 0.00480428524,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73409,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "252650","Name": "Card","Transform": {"posX": -37.3049927,"posY": 12.8145609,"posZ": -46.84961,"rotX": 0.00737715652,"rotY": 181.983322,"rotZ": -0.00153741566,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73407,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "f1926e","Name": "Card","Transform": {"posX": -37.341568,"posY": 12.73394,"posZ": -46.7927475,"rotX": 0.0169589818,"rotY": 178.502319,"rotZ": 0.00245550717,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73410,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "29250a","Name": "Card","Transform": {"posX": -37.3842278,"posY": 12.7875166,"posZ": -46.9959221,"rotX": 0.00554778334,"rotY": 180.2782,"rotZ": 0.00505224941,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73408,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "e68a7c","Name": "Card","Transform": {"posX": -37.3187027,"posY": 12.8410263,"posZ": -46.89997,"rotX": -0.00189985591,"rotY": 179.827484,"rotZ": 359.9936,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73406,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "1c0bd9","Name": "Card","Transform": {"posX": -37.41384,"posY": 12.8680658,"posZ": -47.0249023,"rotX": 359.9936,"rotY": 179.62326,"rotZ": -0.00395905,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73405,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "3cdb77","Name": "Card","Transform": {"posX": -37.33973,"posY": 12.975421,"posZ": -46.9574242,"rotX": 359.986328,"rotY": 180.108688,"rotZ": 359.991821,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73404,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "4101c5","Name": "Card","Transform": {"posX": -37.39057,"posY": 12.9484282,"posZ": -46.90895,"rotX": 359.9878,"rotY": 180.0682,"rotZ": -0.00543547142,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73403,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "5e03db","Name": "Card","Transform": {"posX": -37.342495,"posY": 12.92145,"posZ": -46.90487,"rotX": 359.9891,"rotY": 179.892639,"rotZ": -0.000873302342,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73402,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "27c9f0","Name": "Card","Transform": {"posX": -37.37935,"posY": 12.8945646,"posZ": -46.88789,"rotX": 359.98468,"rotY": 179.929886,"rotZ": -0.00236153952,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73401,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "2fa5dc","Name": "Card","Transform": {"posX": -37.5073051,"posY": 12.760704,"posZ": -47.0255,"rotX": 0.0113861654,"rotY": 180.72403,"rotZ": 0.00426952168,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73400,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""},{"GUID": "aefc79","Name": "Card","Transform": {"posX": 47.41141,"posY": 11.7373362,"posZ": 5.35248375,"rotX": 0.000762851967,"rotY": 270.004669,"rotZ": -0.002081007,"scaleX": 2.33,"scaleY": 1.0,"scaleZ": 2.33},"Nickname": "","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.713235259,"g": 0.713235259,"b": 0.713235259},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": true,"Hands": true,"CardID": 73411,"SidewaysCard": false,"CustomDeck": {"734": {"FaceURL": "https://steamusercontent-a.akamaihd.net/ugc/15619080643947473328/FA78C0F952724D77A33BECEC0651802808037E95/","BackURL": "https://steamusercontent-a.akamaihd.net/ugc/11558662492827477078/4394D314C12A881CE2AB93CEF90F1B28A1DE66CA/","NumWidth": 4,"NumHeight": 3,"BackIsHidden": true,"UniqueBack": false,"Type": 0}},"LuaScript": "","LuaScriptState": "","XmlUI": ""}]}]===] },
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
  -- The Corvid blueprint no longer spawns loose Plot tiles or the bot card (removed from the data), so
  -- there is nothing to destroy/replace: place the 12 plots straight into the 4x3 grid FACE DOWN in ONE
  -- step (rttSetup clears any leftovers from a prior game). Spawn-final -- no old-then-new (audit).
  local ry = board.getRotation().y
  for i, blob in ipairs(RTT_CROW_PLOTS or {}) do
    local idx = i - 1
    local col = math.floor(idx / 3) + 1
    local row = (idx % 3) + 1
    local w = board.positionToWorld({ RTT_CROW_COLS[col], 0.03, RTT_CROW_ROWS[row] })
    spawnObjectJSON({
      json = blob,
      position = { w.x, w.y + 0.2, w.z },
      rotation = { 0, ry, 180 },            -- face DOWN
      callback_function = function(o) o.setLock(false) o.addTag("RTT Faction") end   -- cleared with the faction
    })
  end
  rttCrowsHiddenZone(board, cx, cz, isDraft)
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
function rttFindMapObject()
  local best, bestN = nil, 0
  for _, o in ipairs(getObjectsWithTag("Map Object")) do
    local ok, sp = pcall(function() return o.getSnapPoints() end)
    if ok and sp and #sp > bestN then best, bestN = o, #sp end
  end
  if best ~= nil then return best end
  for _, o in ipairs(getAllObjects()) do       -- fallback: exclude the coordinator/score board
    if o.getGUID() ~= "bab7e1" then
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

-- The frog enclave calls this when it lands on a suit marker, so it can turn to face the middle of
-- the clearing it is in. Strings both ways: this codebase has already been bitten by raw Lua tables
-- not crossing object-script boundaries. "x,z" in, "x,z" out, "" when no map is up.
function rttNearestClearingCentre(arg)
  if type(arg) ~= "string" then return "" end
  local sx, sz = arg:match("^(-?[%d%.]+),(-?[%d%.]+)$")
  local x, z = tonumber(sx), tonumber(sz)
  if x == nil or z == nil then return "" end
  local centres = RTT_CURRENT_MAP and RTT_CLEARING_CENTRES[RTT_CURRENT_MAP]
  if centres == nil then return "" end
  local best, bestd = nil, nil
  for _, c in ipairs(centres) do
    local dx, dz = c[1] - x, c[2] - z
    local d = dx * dx + dz * dz
    if bestd == nil or d < bestd then best, bestd = c, d end
  end
  if best == nil then return "" end
  return tostring(best[1]) .. "," .. tostring(best[2])
end
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

RTT_MTN_LANDMARKS = { "Lost City", "Rabbit-Town", "Foxburrow", "Mousehold" }
RTT_MTN_LM_PIECES = RTT_MTN_LM_PIECES or {}

function rttMountainLandmark()
  -- clear the PREVIOUS landmark first, so a fast re-click replaces it (no stacking, no stale piece)
  for _, o in ipairs(RTT_MTN_LM_PIECES or {}) do
    if o ~= nil then pcall(function() o.destruct() end) end
  end
  RTT_MTN_LM_PIECES = {}
  -- The central clearing has NO suit marker (m590) and the Tower is hidden, so the landmark spawns
  -- DIRECTLY at RTT_MTN_LM — no marker flash. Advancing RNG (seeded once at load) => a fresh random
  -- landmark on every click, instantly. The landmark card itself defines the clearing's suit.
  local name = RTT_MTN_LANDMARKS[math.random(1, #RTT_MTN_LANDMARKS)]
  RTT_MTN_LM_PIECES = rttSpawnLandmarkAt(name, RTT_MTN_LM[1], RTT_MTN_LM[2], RTT_MTN_LM[3],
                     RTT_MTN_CARD[1], RTT_MTN_CARD[2], RTT_MTN_CARD[3],
                     165, 180, RTT_MTN_CARD_SCALE)  -- crotZ 180 = RULES face up (BackURL)
end

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
  -- ruins: 2 fixed + the pair ruin spots (best-effort onto valid clearings)
  local ruinSlots = {}
  for _, p in ipairs(RTT_MARSH_RUIN_FIXED) do ruinSlots[#ruinSlots + 1] = { p[1], p[2], p[3] } end
  for _, m in ipairs(RTT_MARSH) do
    if m.up.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.up.ruin end
    if m.down.ruin ~= nil then ruinSlots[#ruinSlots + 1] = m.down.ruin end
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
function rttMountainHideTower(objects)
  local ov = {}
  for idx, v in ipairs(objects) do
    if string.find(v.json, "\"Tower\"", 1, true) ~= nil then
      ov[idx] = { world = { 0, -60, 0 }, rot = nil }
    end
  end
  return ov
end

RTT_POND_JSON = [==[{"GUID": "347917","Name": "Custom_Tile","Transform": {"posX": -20.61854,"posY": 35.8698158,"posZ": -58.718235,"rotX": 0.016451491,"rotY": 179.94725,"rotZ": 0.08010805,"scaleX": 4.238119,"scaleY": 1.0,"scaleZ": 4.238119},"Nickname": "The Pond","Description": "","GMNotes": "","AltLookAngle": {"x": 0.0,"y": 0.0,"z": 0.0},"ColorDiffuse": {"r": 0.6901961,"g": 0.5960784,"b": 0.0156862754},"LayoutGroupSortIndex": 0,"Value": 0,"Locked": false,"Grid": true,"Snap": true,"IgnoreFoW": false,"MeasureMovement": false,"DragSelectable": true,"Autoraise": true,"Sticky": true,"Tooltip": true,"GridProjection": false,"HideWhenFaceDown": false,"Hands": false,"CustomImage": {"ImageURL": "https://steamusercontent-a.akamaihd.net/ugc/12393369561771611633/E59B2DE66EC1B0F68F19F6E7C071F8B8D38718B8/","ImageSecondaryURL": "https://steamusercontent-a.akamaihd.net/ugc/12393369561771611633/E59B2DE66EC1B0F68F19F6E7C071F8B8D38718B8/","ImageScalar": 1.0,"WidthScale": 0.0,"CustomTile": {"Type": 0,"Thickness": 0.2,"Stackable": false,"Stretch": true}},"LuaScript": "","LuaScriptState": "","XmlUI": "","AttachedSnapPoints": [{"Position": {"x": -0.000120528261,"y": 0.200000748,"z": -0.08064375},"Rotation": {"x": 3.824257E-06,"y": 0.00134896243,"z": 180.0}}]
  }]==]
function makeMap(player,value,id)
  if id == "Marsh Map" and RTT_5P_MARSH then Wait.time(function() rttMarshLandmarks() end, 1.4) end
  RTT_CURRENT_MAP = id
  if id == "Mountain Map" then Wait.frames(function() rttMountainLandmark() end, 2) end
  if id == "Summer Map" then Wait.frames(function() rttSpawnPriority("Summer Map", RTT_PRIO_SUMMERMAP) end, 2) end
  if id == "Lake Map" then Wait.frames(function() rttSpawnPriority("Lake Map", RTT_PRIO_LAKEMAP) end, 2) end
  if id == "Mountain Map" then Wait.frames(function() rttSpawnPriority("Mountain Map", RTT_PRIO_MOUNTAINMAP) end, 2) end
  if id == "Winter Map" then Wait.frames(function() rttSpawnPriority("Winter Map", RTT_PRIO_WINTERMAP) end, 2) end
  if id == "Gorge Map" then Wait.frames(function() rttSpawnPriority("Gorge Map", RTT_PRIO_GORGEMAP) end, 2) end
  if id == "Marsh Map" then Wait.frames(function() rttSpawnMarshNumbers() end, 3) end
  removeMapItems()
  Wait.time(function() pcall(function() rttPlaceUnplacedVPs() end) end, 2.0)  -- markers that had no track yet
  -- The battle mat belongs to the map, so it spawns HERE, with every map placement -- the map BUTTONS
  -- call makeMap directly and so never got one; only the draft's rttPlaceMap did. Tagged "Map Object",
  -- so removeMapItems above clears the previous one and there is never a second. Maintainer 2026-09-04:
  -- "spawn automatically when any map is selected... remove the battle map option button".
  Wait.frames(function() makeSpecialWithTag("Tools", "Battle Mat", 33.17, 1.55, 9.21, "Map Object") end, 2)
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
  if id == "Mountain Map" then RTT_OV = rttMountainHideTower(objects) end
  local scale = self.getScale()
  scale.x = 1/scale.x
  scale.z = 1/scale.z

  for idx,v in ipairs(objects) do
    local rtt_rot = nil
    local rtt_ov = false
    local new_pos
    if RTT_OV ~= nil and RTT_OV[idx] ~= nil then
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
    local ob = spawnObjectJSON({
        json              = v.json,
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
    if rtt_ov and RTT_MARSH_PIECES ~= nil then RTT_MARSH_PIECES[#RTT_MARSH_PIECES + 1] = ob end
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
  for i=1,30 do ruins = shuffle(ruins) end
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
  i=1,10 do clearingMarkers = shuffle(clearingMarkers) end
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







function removeMapItems()
    for _,v in ipairs(getObjectsWithTag("Map Object")) do
      v.destruct()
    end
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
-- Ginso's Gizmo, PORTED IN rather than spawned. Maintainer: "it should always be there available when
-- spawning the mod, functional but without spawning the item". onScriptingButtonDown is a TTS event
-- that fires in object scripts too, and this script has ZERO runtime dependency on its own object --
-- the only `self` in its 386 lines sits inside a comment -- so it runs unchanged from the setup board.
-- Its onLoad/onSave are renamed to rttGizmoLoad/rttGizmoSave and driven from the board's own hooks.
-- warlord is special, just place next to his supply
local WARLORD = {
 name = "The Warlord",
 oid = "352369"
}

-- these objects have specific supplies to return to
local SUPPLIES = {
 Wood = "6d512b",
 ["Cat Warrior"] = "67bcac",
 ["Eyrie Warrior"] = "f18544",
 ["Alliance Warrior"] = "a272b4",
 ["Lizard Cult Warrior"] = "2cc43b",
 ["Riverfolk Warrior"] = "8f5426",
 ["Duchy Warrior"] = "3d1178",
 ["Corvid Warrior"] = "653be4",
 ["Hundreds Warrior"] = "352369",
 ["Keeper Warrior"] = "3ecd38",
 ["Council Warrior"] = "60d78a",
 ["Diaspora Warrior"] = "26cc78",
 ["Knaves Warrior"] = "67bcac",
 -- alliance multistate warriors
 ["Alliance Fox Warrior"] = "a272b4",
 ["Alliance Mouse Warrior"] = "a272b4",
 ["Alliance Rabbit Warrior"] = "a272b4"
}

-- these are tracks of equally spaced objects (or maybe 1 object)
local TRACKS = {
 -- cats
 ["Saw Mill"] = {x=-9.2, y=0.3, z=-1.265, d=1.75, boardId="52c93d"},
 Workshop = {x=-9.2, y=0.3, z=0.604, d=1.75, boardId="52c93d"},
 Recruiter = {x=-9.2, y=0.3, z=2.4, d=1.75, boardId="52c93d"},
 Keep = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="52c93d"},
 -- eyrie
 Roost = {x=-9.653, y=0.3, z=-0.747, d=1.6, boardId="52af3f"},
 -- lizards
 ["Mouse Garden"] = {x=-4.0, y=0.3, z=3.95, d=1.66, boardId="6a1fe4"},
 ["Rabbit Garden"] = {x=-4.0, y=0.3, z=5.61, d=1.66, boardId="6a1fe4"},
 ["Fox Garden"] = {x=-4.0, y=0.3, z=7.27, d=1.66, boardId="6a1fe4"},
 -- otters
 ["Mouse Trade Post"] = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="22a3b3"},
 ["Rabbit Trade Post"] = {x=-8, y=0.4, z=-7.5, d=0, boardId="22a3b3"},
 ["Fox Trade Post"] = {x=-6.4, y=0.4, z=-7.5, d=0, boardId="22a3b3"},
 Stronghold = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="dbe57b"},
 -- moles
 Citadel = {x=-7.21, y=0.3, z=-2.68, d=1.64, boardId="919e94"},
 Market = {x=-7.21, y=0.3, z=-1.04, d=1.64, boardId="919e94"},
 Tunnel = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="919e94"},
 -- corvids
 Plot = {x=-9.6, y=0.4, z=-7.5, d=0, flip=true, boardId="bcf8d7"},
 -- badgers
 ["Tablet/Figure Waystation"] = {x=-3.95, y=0.3, z=6.8, d=0, boardId="7d2953"},
 ["Jewelry/Tablet Waystation"] = {x=-2.15, y=0.3, z=6.8, d=0, boardId="7d2953", flip=true},
 ["Figure/Jewelry Waystation"] = {x=-0.36, y=0.3, z=6.8, d=0, boardId="7d2953"},
 Relic = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="7d2953", flip=true},
 -- rats
 Stronghold = {x=-9.6, y=0.4, z=-7.5, d=0, boardId="dbe57b"},
 Mob = {x=-8, y=0.4, z=-7.5, d=0, boardId="dbe57b"},
 -- twilight council
 Commune = {x=-3.65, y=0.3, z=0.19, d=1.80, boardId="f443b9"},
 Assembly = {x=-10, y=0.4, z=-7.5, d=0, boardId="f443b9"},
 -- frogs - frog token is for old compat
 ["Frog Token"] = {x=-10, y=0.4, z=-7.5, d=0, boardId="f4ddda"},
 ["Fox Enclave"] = {x=-3.98, y=0.4, z=-2.03, d=1.91, boardId="f4ddda"},
 ["Mouse Enclave"] = {x=-3.98, y=0.4, z=-0.15, d=1.91, boardId="f4ddda"},
 ["Rabbit Enclave"] = {x=-3.98, y=0.4, z= 1.78, d=1.91, boardId="f4ddda"},
 -- knaves
 Hideout = {x=-2.23, y=0.3, z=1.60, d=1.51, boardId="52c93d"},
 -- woodland alliance
 ["Fox Base"] = {x=1.4, y=0.3, z=1.6, d=0, boardId="9a7786"},
 ["Rabbit Base"] = {x=-0.2, y=0.3, z=1.6, d=0, boardId="9a7786"},
 ["Mouse Base"] = {x=-1.8, y=0.3, z=1.6, d=0, boardId="9a7786"},
 Sympathy = {
 boardId="9a7786",
 spots = {
 {x=-9.8, y=0.3, z=5.85},
 {x=-8.2, y=0.3, z=6.55},
 {x=-6.7, y=0.3, z=5.85},
 {x=-5.15, y=0.3, z=6.55},
 {x=-3.6, y=0.3, z=5.85},
 {x=-2.1, y=0.3, z=6.55},
 {x=-0.5, y=0.3, z=5.85},
 {x= 1.05, y=0.3, z=6.55},
 {x= 2.6, y=0.3, z=5.85},
 {x= 4.15, y=0.3, z=6.55}
 }
 }
}

-- custom data to save/load to the object itself, so you can save modded tracks/supplies
local CUSTOM_DATA = {
 supplies = {},
 tracks = {}
}

-- gets an object by its display name
local function getObjectsByName(name)
 local arr = {}
 local obj = getAllObjects()
 for _,o in pairs(obj) do
 if o.getName() == name then 
 table.insert(arr,o)
 end
 end
 return arr
end

-- rotates the given vector based on the given y rotation
local function rotate(rot, v) 
 local a = -rot / 180 * math.pi
 local si = math.sin(a)
 local co = math.cos(a)
 local xx = v.x*co-v.z*si
 local zz = v.x*si+v.z*co
 return {x=xx, y=v.y, z=zz}
end

-- sums the positions together
local function addPos(guid, v, dx)
 local board = getObjectFromGUID(guid)
 local pos = board.getPosition()
 local rot = board.getRotation()
 v = rotate(rot.y, {x=v.x-dx, y=v.y, z=v.z})
 return pos + v
end

-- gets the location of the coffin helper
local function getCoffinPos(coffin)
 local x = math.random()*2-1
 local z = math.random()*12-6
 local rot = coffin.getRotation()
 local v = rotate(rot.y, {x=x, y=5, z=z})
 return coffin.getPosition() + v
end

-- checks if the given object is currently on the board
local function isOnBoard(color, o, boardId)
 local board = getObjectFromGUID(boardId)
 if board == nil then
 broadcastToColor(
 "Failed to locate board for " .. o.getName() .. ", use NUMPAD 1 to set the center of the right most track location",
 color, {r=1, g=0, b=0}
 )
 return true -- don't try placing on board
 end
 local v = o.getPosition() - board.getPosition()
 local rot = board.getRotation()
 v = rotate(-rot.y, v)
 return math.abs(v.x) < 12 and math.abs(v.z) < 9
end

-- counts the number of objects on the board
local function countItemsOnBoard(color, name, id)
 local boardPos = getObjectFromGUID(id).getPosition()
 local all = getObjectsByName(name)
 local c = 0
 for _, o in pairs(all) do
 local pos = o.getPosition()
 local diff = pos-boardPos
 local dist = diff.x * diff.x + diff.z * diff.z
 if isOnBoard(color, o, id) then
 c = c +1
 end
 end
 return c
end

-- gets the relative position to an object based on the pointers p1osition, rotation sensitive
local function getRelativePos(color, object)
 local objPos = object.getPosition()
 local pointPos = Player[color].getPointerPosition()
 local globalOffset = {x = pointPos.x - objPos.x, y = 0.3, z = pointPos.z - objPos.z}
 return rotate(object.getRotation().y, globalOffset)
end

-- length of the string "warrior"
local WARRIOR_LENGTH = string.len("Warrior") + 1

-- state for each player currently in the editor
local STATES = {}

local function getState(color, key)
 if STATES[color] == nil then
 return nil
 end
 return STATES[color][key]
end

-- called when the gizmo is loaded to retrieve data
function rttGizmoLoad(state)
 -- ignore empty
 if state ~= "" then
 -- decode from JSON
 local data = JSON.decode(state)
 if type(data) == "table" then
 -- ensure required tables are present
 if data.supplies == nil then
 data.supplies = {}
 end
 if data.tracks == nil then
 data.tracks = {}
 end
 CUSTOM_DATA = data
 return
 end
 broadcastToAll("Failed to load data from Gizmo's state", {r=1, g=0, b=0})
 end
 -- reset state on fallback
 CUSTOM_DATA = {
 supplies = {},
 tracks = {}
 }
end

-- called when the gizmo is saved to persist data
function rttGizmoSave()
 return JSON.encode(CUSTOM_DATA)
end

function onScriptingButtonDown(idx,color)
 -- numpad 1: save as destination
 if idx == 1 then
 -- if we have a last object, try to save it somewhere
 local lastName = getState(color, "lastName")
 if lastName ~= nil then
 local o = Player[color].getHoverObject()
 
 -- if we have a first position, we are selecting a second one
 local firstPos = getState(color, "firstPos")
 if firstPos ~= nil then
 local boardId = getState(color, "boardId")
 -- if off board, single position
 if o == nil or o.getGUID() ~= boardId then
 CUSTOM_DATA.tracks[lastName] = { x = firstPos.x, y = 0.3, z = firstPos.z, d = 0, boardId = boardId }
 broadcastToColor("Saved target position for " .. lastName .. " as " .. firstPos.x .. ", " .. firstPos.z, color, {r=1, g=1, b=1})
 -- if on board, track
 else
 local secondPos = getRelativePos(color, o)
 local d = secondPos.x - firstPos.x
 CUSTOM_DATA.tracks[lastName] = { x = firstPos.x, y = 0.3, z = firstPos.z, d = d, boardId = boardId }
 broadcastToColor(
 "Saved target position for " .. lastName .. " as " .. firstPos.x .. ", " .. firstPos.z .. " with offset " .. d,
 color, {r=1, g=1, b=1}
 )
 end
 STATES[color] = nil
 -- if no object, clear state
 elseif o == nil then
 STATES[color] = nil
 broadcastToColor("Canceled setting destination for " .. lastName, color, {r=1, g=1, b=1})
 else
 
 -- if its a supply, save it as a supply
 if o.getQuantity() ~= -1 then
 CUSTOM_DATA.supplies[lastName] = o.getGUID()
 broadcastToColor("Saved supply " .. o.getName() .. " as destination for " .. lastName, color, {r=1, g=1, b=1})
 STATES[color] = nil
 else
 STATES[color].boardId = o.getGUID()
 STATES[color].firstPos = getRelativePos(color, o)
 broadcastToColor(
 "Selected first location for " .. lastName
 .. ". Select center of second right most track position to setup a track, or select anywhere off the board for a single position.",
 color, {r=1, g=1, b=1}
 )
 end
 end
 else
 -- position debugging
 local o = Player[color].getHoverObject()
 local oriented = getRelativePos(color, o)
 broadcastToColor("Relative Position is " .. oriented.x .. "," .. oriented.z, color, {r=1, g=1, b=1})
 end
 
 -- numpad 0: return to supply
 elseif idx == 10 then
 -- ensure something is hovered
 local o = Player[color].getHoverObject()
 if o == nil then return end
 
 -- use the name to determine where it belongs
 local name = o.getName()
 if name == "" then
 broadcastToColor("Objects with no name are not supported, give the object a name to set target",color, {r=1, g=0, b=0})
 STATES[color] = nil
 return
 end
 STATES[color] = {lastName = name}
 local track = CUSTOM_DATA.tracks[name] or TRACKS[name]
 local guid = CUSTOM_DATA.supplies[name] or SUPPLIES[name]
 
 -- if its a warrior, try to find the supply if missing
 local isWarrior = string.match(name, "Warrior$")
 if isWarrior and (guid == nil or getObjectFromGUID(guid) == nil) then
 -- handle multistate warriors by ignoring the part between the quotes
 local _, _, supplyName = name:find("^(.+) \".+\" Warrior$")
 if supplyName == nil then
 supplyName = name:sub(1, name:len()-WARRIOR_LENGTH)
 end
 supplyName = supplyName .. " Supply"
 local possibleSupplies = getObjectsByName(supplyName)
 -- found a single supply with the name? store it
 if #possibleSupplies == 1 then
 if possibleSupplies[1].getQuantity() == -1 then
 broadcastToColor(
 "Object named '" .. supplyName .. "' is not a valid supply for " .. name .. ", use NUMPAD 1 to set a supply",
 color, {r=1, g=0, b=0}
 )
 return
 end
 broadcastToColor("Automatically found supply for " .. name, color, {r=1, g=1, b=1})
 guid = possibleSupplies[1].getGUID()
 CUSTOM_DATA.supplies[name] = guid
 elseif #possibleSupplies == 0 then
 broadcastToColor("No supply named '" .. supplyName .. "' exists for " .. name .. ", use NUMPAD 1 to set a supply", color, {r=1, g=0, b=0})
 return
 else
 broadcastToColor(
 "Multiple possible supplies named '" .. supplyName .. "' exists for " .. name .. ", use NUMPAD 1 to set a supply",
 color, {r=1, g=0, b=0}
 )
 return
 end
 end
 
 -- warlord lives next to the hundreds supply
 if name == WARLORD.name then
 local bag = getObjectFromGUID(WARLORD.oid)
 local pos = bag.getPosition()
 local v = rotate(bag.getRotation().y, {x=3, y=0, z=-1})
 o.setPosition(pos + v)
 -- next, try a supply
 elseif guid ~= nil then
 -- ensure the supply is on the board
 local supply = getObjectFromGUID(guid)
 if supply == nil then
 broadcastToColor("Supply for " .. name .. " is not on the board", color, {r=1, g=0, b=0})
 return
 end
 -- go to coffin first if open and the thing is not in the coffin
 local coffin = getObjectFromGUID("8a274d")
 if coffin ~= nil and isWarrior then
 local p1 = o.getPosition()
 local p2 = coffin.getPosition()
 local dx = p1.x-p2.x
 local dz = p1.z-p2.z
 local d = dx*dx+dz*dz
 if d > 45 then 
 o.setPosition(getCoffinPos(coffin))
 broadcastToAll(Player[color].steam_name .. " moved " .. name .. " to coffin", stringColorToRGB(color))
 else 
 supply.putObject(o) 
 broadcastToAll(Player[color].steam_name .. " removed " .. name .. " from coffin", stringColorToRGB(color))
 end
 else
 -- return to supply otherwise
 supply.putObject(o)
 broadcastToAll(Player[color].steam_name .. " removed " .. name, stringColorToRGB(color))
 end
 -- next, try a track
 elseif track ~= nil then
 if isOnBoard(color, o, track.boardId) then return end
 local n = countItemsOnBoard(color, name, track.boardId)
 local pos
 if track.spots ~= nil then
 pos = addPos(track.boardId, track.spots[n+1],0)
 else
 pos = addPos(track.boardId, track, -n * track.d)
 end
 o.setPosition(pos)
 local rotation = getObjectFromGUID(track.boardId).getRotation()
 if track.flip then
 rotation.z = rotation.z + 180
 end
 o.setRotation(rotation)
 broadcastToAll(Player[color].steam_name .. " removed " .. name, stringColorToRGB(color))
 else
 broadcastToColor(
 "This object is not supported, use NUMPAD 1 to set the supply or the center of the right most track location",
 color, {r=1, g=0, b=0}
 )
 end
 end
end


-- the board persists the gizmo's custom supply/track config, since the object that used to own
-- that state no longer exists.
function onSave() return rttGizmoSave() end
