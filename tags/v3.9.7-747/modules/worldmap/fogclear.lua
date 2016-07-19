--[[
	Project....: LUI NextGenWoWUserInterface
	File.......: fogclear.lua
	Description: WorldMap FogClear Module
]]

-- External references.
local addonname, LUI = ...
local WorldMap = LUI:Module("WorldMap")
local module = WorldMap:Module("FogClear", "AceEvent-3.0", "AceHook-3.0")

local db, dbd, global

--------------------------------------------------
-- Local Variables
--------------------------------------------------

local texPathTemplate = "Interface\\WorldMap\\%s\\"

local worldMapCache = {}
local battleMapCache = {}

local discoveredOverlays = {}

local zoneData = {
	-- Eastern Kingdoms
	["Arathi"] = {
		["BoulderfistHall"] = 394406398204,
		["Bouldergor"] = 132249835769,
		["CircleofEastBinding"] = 135822293175,
		["CircleofInnerBinding"] = 335218445540,
		["CircleofWestBinding"] = 25859226844,
		["CirecleofOuterBinding"] = 293479837911,
		["DabyriesFarmstead"] = 155042680018,
		["FaldirsCove"] = 429577744657,
		["GalensFall"] = 154619135188,
		["GoShekFarm"] = 267812856114,
		["Hammerfall"] = 127311035662,
		["NorthfoldManor"] = 112881578211,
		["RefugePoint"] = 156000073924,
		["StromgardeKeep"] = 288858884380,
		["ThandolSpan"] = 446950535405,
		["WitherbarkVillage"] = 385972662532,
	},
	["Badlands"] = {
		["AgmondsEnd"] = 338470208854,
		["AngorFortress"] = 73255845149,
		["ApocryphansRest"] = 70867322108,
		["CampBoff"] = 236650430738,
		["CampCagg"] = 301721808211,
		["CampKosh"] = 20929843436,
		["DeathwingScar"] = 191309866312,
		["HammertoesDigsite"] = 124985217233,
		["LethlorRavine"] = 59615319509,
		["TheDustbowl"] = 106451727574,
		["Uldaman"] = 352536842,
	},
	["BlastedLands"] = {
		["AltarofStorms"] = 118347730158,
		["DreadmaulHold"] = 270743824,
		["DreadmaulPost"] = 195764089067,
		["NethergardeKeep"] = 6998406439,
		["NethergardeSupplyCamps"] = 457383107,
		["RiseoftheDefiler"] = 109915056296,
		["SerpentsCoil"] = 104634440922,
		["Shattershore"] = 98316859632,
		["SunveilExcursion"] = 401984465129,
		["Surwich"] = 509302996167,
		["TheDarkPortal"] = 192585967986,
		["TheRedReaches"] = 288322062604,
		["TheTaintedForest"] = 334072485212,
		["TheTaintedScar"] = 188056045876,
	},
	["BurningSteppes"] = {
		["AltarofStorms"] = 368822,
		["BlackrockMountain"] = 83235097,
		["BlackrockPass"] = 277465164074,
		["BlackrockStronghold"] = 246809920,
		["Dracodar"] = 254477253994,
		["DreadmaulRock"] = 162730876178,
		["MorgansVigil"] = 274449462655,
		["PillarofAsh"] = 274069878034,
		["RuinsofThaurissan"] = 441813316,
		["TerrorWingPath"] = 8193922398,
	},
	["DeadwindPass"] = {
		["DeadmansCrossing"] = 87566953,
		["Karazhan"] = 332956801537,
		["TheVice"] = 223792792926,
	},
	["DunMorogh"] = {
		["AmberstillRanch"] = 242216000761,
		["ColdridgePass"] = 365449990369,
		["ColdridgeValley"] = 393094674830,
		["FrostmaneFront"] = 275370032354,
		["FrostmaneHold"] = 243792078261,
		["Gnomeregan"] = 28991355289,
		["GolBolarQuarry"] = 309933108422,
		["HelmsBedLake"] = 288559966426,
		["IceFlowLake"] = 276142316,
		["Ironforge"] = 417688952,
		["IronforgeAirfield"] = 660946228,
		["Kharanos"] = 236694204600,
		["NorthGateOutpost"] = 46973434093,
		["ShimmerRidge"] = 142150445227,
		["TheGrizzledDen"] = 308556234963,
		["TheShimmeringDeep"] = 142150445227,
		["TheTundridHills"] = 329172378798,
	},
	["Duskwood"] = {
		["AddlesStead"] = 373696012587,
		["BrightwoodGrove"] = 120780635415,
		["Darkshire"] = 138110363977,
		["ManorMistmantle"] = 131689797851,
		["RacenHill"] = 313633436877,
		["RavenHillCemetary"] = 141829657923,
		["TheDarkenedBank"] = 27991977891,
		["TheHushedBank"] = 163209071805,
		["TheRottingOrchard"] = 395702443299,
		["TheTranquilGardensCemetary"] = 370024894755,
		["TheTwilightGrove"] = 108777574720,
		["TheYorgenFarmstead"] = 425622495465,
		["VulGolOgreMound"] = 381417711884,
	},
	["EasternPlaguelands"] = {
		["Acherus"] = 110333543652,
		["BlackwoodLake"] = 162535808238,
		["CorinsCrossing"] = 310828553402,
		["CrownGuardTower"] = 377154108618,
		["Darrowshire"] = 496290183416,
		["EastwallTower"] = 198135955637,
		["LakeMereldar"] = 458972448010,
		["LightsHopeChapel"] = 291704631492,
		["LightsShieldTower"] = 291394193651,
		["Northdale"] = 66096177417,
		["NorthpassTower"] = 74508861690,
		["Plaguewood"] = 43100927304,
		["QuelLithienLodge"] = 368229653,
		["RuinsOfTheScarletEnclave"] = 317528069384,
		["Stratholme"] = 123914550,
		["Terrordale"] = 10737746178,
		["TheFungalVale"] = 226751635730,
		["TheInfectisScar"] = 283018274993,
		["TheMarrisStead"] = 359843178698,
		["TheNoxiousGlade"] = 59737681193,
		["ThePestilentScar"] = 374064087222,
		["TheUndercroft"] = 490758950168,
		["ThondorilRiver"] = 107374721286,
		["Tyrshand"] = 445211998422,
		["ZulMashar"] = 553828638,
	},
	["Elwynn"] = {
		["BrackwellPumpkinPatch"] = 455824597279,
		["CrystalLake"] = 351551044828,
		["EastvaleLoggingCamp"] = 314270010662,
		["FargodeepMine"] = 451223478541,
		["Goldshire"] = 315939331348,
		["JerodsLanding"] = 462124431590,
		["NorthshireValley"] = 148548919591,
		["RidgepointTower"] = 475336476957,
		["StonecairnLake"] = 200295072084,
		["Stromwind"] = 432640,
		["TowerofAzora"] = 308718847246,
		["WestbrookGarrison"] = 381300303117,
	},
	["EversongWoods"] = {
		["AzurebreezeCoast"] = 245514895616,
		["DuskwitherGrounds"] = 272291332352,
		["EastSanctum"] = 400988307712,
		["ElrendarFalls"] = 429031424128,
		["FairbreezeVilliage"] = 414869356800,
		["FarstriderRetreat"] = 386022899968,
		["GoldenboughPass"] = 503839850752,
		["LakeElrendar"] = 506344969344,
		["NorthSanctum"] = 320353861888,
		["RuinsofSilvermoon"] = 146351063296,
		["RunestoneFalithas"] = 532972482816,
		["RunestoneShandor"] = 530915178752,
		["SatherilsHaven"] = 412656861440,
		["SilvermoonCity"] = 93877436928,
		["StillwhisperPond"] = 337652220160,
		["SunsailAnchorage"] = 434034049280,
		["SunstriderIsle"] = 5573706240,
		["TheGoldenStrand"] = 445795005568,
		["TheLivingWood"] = 451507642496,
		["TheScortchedGrove"] = 544654622976,
		["ThuronsLivery"] = 328056570112,
		["TorWatha"] = 338908513536,
		["TranquilShore"] = 320200769792,
		["WestSanctum"] = 342830088320,
		["Zebwatha"] = 510608475264,
	},
	["Ghostlands"] = {
		["AmaniPass"] = 249735598484,
		["BleedingZiggurat"] = 255743754496,
		["DawnstarSpire"] = 603193771,
		["Deatholme"] = 402753099264,
		["ElrendarCrossing"] = 342098432,
		["FarstriderEnclave"] = 146629984685,
		["GoldenmistVillage"] = 46662144,
		["HowlingZiggurat"] = 235506435328,
		["IsleofTribulations"] = 613679360,
		["SanctumoftheMoon"] = 135511933184,
		["SanctumoftheSun"] = 161531560192,
		["SuncrownVillage"] = 482607616,
		["ThalassiaPass"] = 436321130752,
		["Tranquillien"] = 2530738432,
		["WindrunnerSpire"] = 308206108928,
		["WindrunnerVillage"] = 125691232512,
		["ZebNowa"] = 254965890560,
	},
	["HillsbradFoothills"] = {
		["AzurelodeMine"] = 428724115636,
		["ChillwindPoint"] = 73596673471,
		["CorrahnsDagger"] = 240965025927,
		["CrushridgeHold"] = 108933542022,
		["DalaranCrater"] = 147209828668,
		["DandredsFold"] = 357680386,
		["DarrowHill"] = 300019777683,
		["DunGarok"] = 440802740493,
		["DurnholdeKeep"] = 233594883509,
		["GallowsCorner"] = 150796913819,
		["GavinsNaze"] = 273091265652,
		["GrowlessCave"] = 205461266603,
		["HillsbradFields"] = 324470488366,
		["LordamereInternmentCamp"] = 232131828986,
		["MistyShore"] = 45433922718,
		["NethanderSteed"] = 401032335564,
		["PurgationIsle"] = 542449478800,
		["RuinsOfAlterac"] = 91632096445,
		["SlaughterHollow"] = 59488985236,
		["SoferasNaze"] = 178748803220,
		["SouthpointTower"] = 332922091832,
		["Southshore"] = 378358951141,
		["Strahnbrad"] = 47774369043,
		["TarrenMill"] = 243183856805,
		["TheHeadland"] = 274213261417,
		["TheUplands"] = 462586068,
	},
	["Hinterlands"] = {
		["AeriePeak"] = 253403344110,
		["Agolwatha"] = 171109986512,
		["JinthaAlor"] = 359140721951,
		["PlaguemistRavine"] = 112882636991,
		["QuelDanilLodge"] = 194578173169,
		["Seradane"] = 5867101487,
		["ShadraAlor"] = 407179038960,
		["Shaolwatha"] = 223931012377,
		["SkulkRock"] = 209893698736,
		["TheAltarofZul"] = 368667988193,
		["TheCreepingRuin"] = 270992088263,
		["TheOverlookCliffs"] = 287399363828,
		["ValorwindLake"] = 289136660679,
		["Zunwatha"] = 305102292194,
	},
	["LochModan"] = {
		["GrizzlepawRidge"] = 348149487889,
		["IronbandsExcavationSite"] = 318332243341,
		["MogroshStronghold"] = 56410498342,
		["NorthgatePass"] = 17073471,
		["SilverStreamMine"] = 231993569,
		["StonesplinterValley"] = 370626828561,
		["StronewroughtDam"] = 355672397,
		["TheFarstriderLodge"] = 225010028893,
		["TheLoch"] = 87330089290,
		["Thelsamar"] = 156766608839,
		["ValleyofKings"] = 333934060854,
	},
	["Redridge"] = {
		["AlthersMill"] = 149617368292,
		["CampEverstill"] = 307556975805,
		["GalardellValley"] = 602357164,
		["LakeEverstill"] = 229865941456,
		["LakeridgeHighway"] = 339457966472,
		["Lakeshire"] = 118111863194,
		["RedridgeCanyons"] = 39096733,
		["RendersCamp"] = 224647525,
		["RendersValley"] = 405273873835,
		["ShalewindCanyon"] = 304590688562,
		["StonewatchFalls"] = 324820719932,
		["StonewatchKeep"] = 503746788,
		["ThreeCorners"] = 274878323011,
	},
	["RuinsofGilneas"] = {
		["GilneasPuzzle"] = 685034,
	},
	["SearingGorge"] = {
		["BlackcharCave"] = 387621113207,
		["BlackrockMountain"] = 455521587504,
		["DustfireValley"] = 616926600,
		["FirewatchRidge"] = 80531039597,
		["GrimsiltWorksite"] = 259328846265,
		["TannerCamp"] = 386980434491,
		["TheCauldron"] = 183853490657,
		["ThoriumPoint"] = 41069884845,
	},
	["Silverpine"] = {
		["Ambermill"] = 268969430299,
		["BerensPeril"] = 435395239230,
		["DeepElemMine"] = 228139931865,
		["FenrisIsle"] = 16715659616,
		["ForsakenHighCommand"] = 466795881,
		["ForsakenRearGuard"] = 387168442,
		["NorthTidesBeachhead"] = 73353338030,
		["NorthTidesRun"] = 154494233,
		["OlsensFarthing"] = 267689041147,
		["ShadowfangKeep"] = 362204533939,
		["TheBattlefront"] = 461001380095,
		["TheDecrepitFields"] = 167997759664,
		["TheForsakenFront"] = 351567803544,
		["TheGreymaneWall"] = 543646976409,
		["TheSepulcher"] = 168935235802,
		["TheSkitteringDark"] = 247640291,
		["ValgansField"] = 83161690274,
	},
	["StranglethornJungle"] = {
		["BalAlRuins"] = 180668736671,
		["BaliaMahRuins"] = 261335758063,
		["Bambala"] = 176687333566,
		["FortLivingston"] = 403070691558,
		["GromGolBaseCamp"] = 245125794983,
		["KalAiRuins"] = 197939845259,
		["KurzensCompound"] = 523483380,
		["LakeNazferiti"] = 102438768880,
		["Mazthoril"] = 391353994590,
		["MizjahRuins"] = 264546464925,
		["MoshOggOgreMound"] = 272226269418,
		["NesingwarysExpedition"] = 67966793955,
		["RebelCamp"] = 321034542,
		["RuinsOfZulKunda"] = 165946596,
		["TheVileReef"] = 223485329644,
		["ZulGurub"] = 656982392,
		["ZuuldalaRuins"] = 23632026948,
	},
	["Sunwell"] = {
		["SunsReachHarbor"] = 270847607296,
		["SunsReachSanctum"] = 4558684672,
	},
	["SwampOfSorrows"] = {
		["Bogpaddle"] = 629343494,
		["IthariusCave"] = 259853185292,
		["MarshtideWatch"] = 501569866,
		["MistyValley"] = 85899638028,
		["MistyreedStrand"] = 629830034,
		["PoolOfTears"] = 256153720065,
		["Sorrowmurk"] = 86636923109,
		["SplinterspearJunction"] = 253606845678,
		["Stagalbog"] = 387113598299,
		["Stonard"] = 277337133413,
		["TheHarborage"] = 84994715914,
		["TheShiftingMire"] = 26117251364,
	},
	["TheCapeOfStranglethorn"] = {
		["BootyBay"] = 366449261793,
		["CrystalveinMine"] = 78937010447,
		["GurubashiArena"] = 362025198,
		["HardwrenchHideaway"] = 124772382052,
		["JagueroIsle"] = 434285846768,
		["MistvaleValley"] = 266716039421,
		["NekmaniWellspring"] = 229013419254,
		["RuinsofAboraz"] = 194906341560,
		["RuinsofJubuwal"] = 128266237083,
		["TheSundering"] = 474170612,
		["WildShore"] = 421263593708,
	},
	["Tirisfal"] = {
		["AgamandMills"] = 96976769309,
		["BalnirFarmstead"] = 348515388658,
		["BrightwaterLake"] = 131597635794,
		["Brill"] = 271086442695,
		["CalstonEstate"] = 274212234419,
		["ColdHearthManor"] = 340814644436,
		["CrusaderOutpost"] = 249827641519,
		["Deathknell"] = 222274411951,
		["GarrensHaunt"] = 139013085374,
		["NightmareVale"] = 349330236641,
		["RuinsofLorderon"] = 385917136262,
		["ScarletMonastery"] = 51242080518,
		["ScarletWatchPost"] = 107026294945,
		["SollidenFarmstead"] = 206369424670,
		["TheBulwark"] = 355078588709,
		["VenomwebVale"] = 161850088698,
	},
	["TwilightHighlands"] = {
		["Bloodgulch"] = 220553442519,
		["CrucibleOfCarnage"] = 288168820939,
		["Crushblow"] = 480350768310,
		["DragonmawPass"] = 128928921883,
		["DragonmawPort"] = 263728610555,
		["DunwaldRuins"] = 394477660357,
		["FirebeardsPatrol"] = 285065008343,
		["GlopgutsHollow"] = 95868352686,
		["GorshakWarCamp"] = 236792752322,
		["GrimBatol"] = 239531741414,
		["Highbank"] = 433449045212,
		["HighlandForest"] = 354840453359,
		["HumboldtConflaguration"] = 95923877007,
		["Kirthaven"] = 505687348,
		["ObsidianForest"] = 408479367510,
		["RuinsOfDrakgor"] = 310565070,
		["SlitheringCove"] = 182114788550,
		["TheBlackBreach"] = 130445166803,
		["TheGullet"] = 192482037935,
		["TheKrazzworks"] = 686006498,
		["TheTwilightBreach"] = 206485803207,
		["TheTwilightCitadel"] = 337313630569,
		["TheTwilightGate"] = 382595177637,
		["Thundermar"] = 100250391790,
		["TwilightShore"] = 371080767748,
		["VermillionRedoubt"] = 17254588740,
		["VictoryPoint"] = 328881831089,
		["WeepingWound"] = 375584982,
		["WyrmsBend"] = 249323264191,
	},
	["VashjirDepths"] = {
		["AbandonedReef"] = 282446932339,
		["AbyssalBreach"] = 521624043,
		["ColdlightChasm"] = 300927015179,
		["DeepfinRidge"] = 34648365419,
		["FireplumeTrench"] = 118442159402,
		["KorthunsEnd"] = 304301344114,
		["LGhorek"] = 225655952690,
		["Seabrush"] = 196930169057,
	},
	["VashjirKelpForest"] = {
		["DarkwhisperGorge"] = 245366977756,
		["GnawsBoneyard"] = 349439223095,
		["GubogglesLedge"] = 301066304739,
		["HoldingPens"] = 431048895804,
		["HonorsTomb"] = 46569568547,
		["LegionsFate"] = 37801487638,
		["TheAccursedReef"] = 174329136468,
	},
	["VashjirRuins"] = {
		["BethMoraRidge"] = 478242110799,
		["GlimmeringdeepGorge"] = 238653985040,
		["Nespirah"] = 280729236766,
		["RuinsOfTherseral"] = 188485958853,
		["RuinsOfVashjir"] = 287990719837,
		["ShimmeringGrotto"] = 419715411,
		["SilverTideHollow"] = 34517351904,
	},
	["WesternPlaguelands"] = {
		["Andorhal"] = 368394442192,
		["CaerDarrow"] = 419389718722,
		["DalsonsFarm"] = 249422872901,
		["DarrowmereLake"] = 380639701484,
		["FelstoneField"] = 245053477105,
		["GahrronsWithering"] = 229226311921,
		["Hearthglen"] = 246693296,
		["NorthridgeLumberCamp"] = 132312652135,
		["RedpineDell"] = 226859554082,
		["SorrowHill"] = 481310241136,
		["TheBulwark"] = 252379984188,
		["TheWeepingCave"] = 162713016505,
		["TheWrithingHaunt"] = 356977413289,
		["ThondrorilRiver"] = 559337783,
	},
	["Westfall"] = {
		["AlexstonFarmstead"] = 282569439578,
		["DemontsPlace"] = 403939986633,
		["FurlbrowsPumpkinFarm"] = 413357253,
		["GoldCoastQuarry"] = 85034584299,
		["JangoloadMine"] = 326341828,
		["Moonbrook"] = 349289272552,
		["SaldeansFarm"] = 87446238452,
		["SentinelHill"] = 243089548517,
		["TheDaggerHills"] = 424446018852,
		["TheDeadAcre"] = 215305438401,
		["TheDustPlains"] = 406377993533,
		["TheGapingChasm"] = 180697130168,
		["TheJansenStead"] = 497208522,
		["TheMolsenFarm"] = 127066669258,
		["WestfallLighthouse"] = 512406756563,
	},
	["Wetlands"] = {
		["AngerfangEncampment"] = 216198807788,
		["BlackChannelMarsh"] = 257737072941,
		["BluegillMarsh"] = 109554426177,
		["DireforgeHills"] = 37038035273,
		["DunAlgaz"] = 450260852010,
		["DunModr"] = 7889675521,
		["GreenwardensGrove"] = 110004286714,
		["IronbeardsTomb"] = 81994678457,
		["MenethilHarbor"] = 318901693765,
		["MosshideFen"] = 249638923633,
		["RaptorRidge"] = 132698592512,
		["Satlspray"] = 228878586,
		["SlabchiselsSurvey"] = 378515288364,
		["SundownMarsh"] = 67772861716,
		["ThelganRock"] = 360092744962,
		["WhelgarsExcavationSite"] = 209574100266,
	},
	-- Kalimdor
	["AhnQirajTheFallenKingdom"] = {
		["AQKingdom"] = 121271159,
	},
	["Ashenvale"] = {
		["Astranaar"] = 176361323771,
		["BoughShadow"] = 159790615718,
		["FallenSkyLake"] = 413945581855,
		["FelfireHill"] = 341125182741,
		["LakeFalathim"] = 159031468216,
		["MaelstrasPost"] = 197502198,
		["NightRun"] = 272280847581,
		["OrendilsRetreat"] = 150203636,
		["RaynewoodRetreat"] = 237801570535,
		["Satyrnaar"] = 166086291691,
		["SilverwindRefuge"] = 360058245467,
		["TheHowlingVale"] = 104649178437,
		["TheRuinsofStardust"] = 355629022444,
		["TheShrineofAssenia"] = 295321234738,
		["TheZoramStrand"] = 399622,
		["ThistlefurVillage"] = 84019496250,
		["ThunderPeak"] = 130318391499,
		["WarsongLumberCamp"] = 285350264039,
	},
	["Aszhara"] = {
		["BearsHead"] = 151516315904,
		["BilgewaterHarbor"] = 136779789899,
		["BitterReaches"] = 500424001,
		["BlackmawHold"] = 57122499844,
		["DarnassianBaseCamp"] = 3581155571,
		["GallywixPleasurePalace"] = 238444321018,
		["LakeMennar"] = 405057806546,
		["OrgimmarRearGate"] = 369390537056,
		["RavencrestMonument"] = 431069867303,
		["RuinsofArkkoran"] = 130525889755,
		["RuinsofEldarath"] = 246126195930,
		["StormCliffs"] = 433144963279,
		["TheSecretLab"] = 425572127928,
		["TheShatteredStrand"] = 180720313550,
		["TowerofEldara"] = 24339891506,
	},
	["AzuremystIsle"] = {
		["AmmenFord"] = 300114247936,
		["AmmenVale"] = 112222274011,
		["AzureWatch"] = 267763581184,
		["BristlelimbVillage"] = 389950996736,
		["Emberglade"] = 26281771264,
		["FairbridgeStrand"] = 373424384,
		["GreezlesCamp"] = 376341528832,
		["MoongrazeWoods"] = 196965826816,
		["OdesyusLanding"] = 406243770624,
		["PodCluster"] = 327786168576,
		["PodWreckage"] = 375220600960,
		["SiltingShore"] = 3526623488,
		["SilvermystIsle"] = 478913198336,
		["StillpineHold"] = 52996342016,
		["TheExodar"] = 91346174464,
		["ValaarsBerth"] = 325528584448,
		["WrathscalePoint"] = 452276247808,
	},
	["Barrens"] = {
		["BoulderLodeMine"] = 8052229398,
		["DreadmistPeak"] = 111973436657,
		["FarWatchPost"] = 139094995151,
		["GroldomFarm"] = 136835196147,
		["MorshanRampart"] = 6713204997,
		["Ratchet"] = 407521901787,
		["TheCrossroads"] = 295658783977,
		["TheDryHills"] = 61325195547,
		["TheForgottenPools"] = 223443419582,
		["TheMerchantCoast"] = 490209497403,
		["TheSludgeFen"] = 6865282305,
		["TheStagnantOasis"] = 407309157712,
		["TheWailingCaverns"] = 341609616761,
		["ThornHill"] = 273235025135,
	},
	["BloodmystIsle"] = {
		["AmberwebPass"] = 66618654976,
		["Axxarien"] = 146340577536,
		["BlacksiltShore"] = 457599863296,
		["Bladewood"] = 224797131008,
		["BloodWatch"] = 277483880704,
		["BloodscaleIsle"] = 275678232815,
		["BristlelimbEnclave"] = 440806932736,
		["KesselsCrossing"] = 566404199909,
		["Middenvale"] = 436373553408,
		["Mystwood"] = 518941500672,
		["Nazzivian"] = 434054103296,
		["RagefeatherRidge"] = 126132420864,
		["RuinsofLorethAran"] = 232511504640,
		["TalonStand"] = 84441039104,
		["TelathionsCamp"] = 232117108864,
		["TheBloodcursedReef"] = 58746732800,
		["TheBloodwash"] = 29307961600,
		["TheCrimsonReach"] = 93997760768,
		["TheCryoCore"] = 306323915008,
		["TheFoulPool"] = 146260885760,
		["TheHiddenReef"] = 42091151616,
		["TheLostFold"] = 505186294016,
		["TheVectorCoil"] = 255596083712,
		["TheWarpPiston"] = 31611683072,
		["VeridianPoint"] = 668205312,
		["VindicatorsRest"] = 260089053440,
		["WrathscaleLair"] = 363552047360,
		["WyrmscarIsland"] = 88689869056,
	},
	["Darkshore"] = {
		["AmethAran"] = 354643232070,
		["EyeoftheVortex"] = 256939065674,
		["Lordanel"] = 58392339733,
		["Nazjvel"] = 501654693108,
		["RuinsofAuberdine"] = 195714812107,
		["RuinsofMathystra"] = 30607154376,
		["ShatterspearVale"] = 17805067514,
		["ShatterspearWarcamp"] = 592596213,
		["TheMastersGlaive"] = 518907946287,
		["WildbendRiver"] = 406168208698,
		["WitheringThicket"] = 127021607240,
	},
	["Desolace"] = {
		["CenarionWildlands"] = 167939175736,
		["GelkisVillage"] = 507023397138,
		["KodoGraveyard"] = 293509225722,
		["MagramTerritory"] = 183179137313,
		["MannorocCoven"] = 383725657414,
		["NijelsPoint"] = 601097447,
		["RanzjarIsle"] = 220345505,
		["Sargeron"] = 687117629,
		["ShadowbreakRavine"] = 432312428836,
		["ShadowpreyVillage"] = 396359937246,
		["ShokThokar"] = 343141610805,
		["SlitherbladeShore"] = 25988258130,
		["TethrisAran"] = 418530578,
		["ThargadsCamp"] = 404015474900,
		["ThunderAxeFortress"] = 53074932956,
		["ValleyofSpears"] = 210631937345,
	},
	["Durotar"] = {
		["DrygulchRavine"] = 64859869420,
		["EchoIsles"] = 443905473866,
		["NorthwatchFoothold"] = 472864945314,
		["Orgrimmar"] = 324179203,
		["RazorHill"] = 169029635296,
		["RazormaneGrounds"] = 283784673528,
		["SenjinVillage"] = 436418568384,
		["SkullRock"] = 459437264,
		["SouthfuryWatershed"] = 187127003380,
		["ThunderRidge"] = 51849160924,
		["TiragardeKeep"] = 320459710674,
		["ValleyOfTrials"] = 335326480638,
	},
	["Dustwallow"] = {
		["AlcazIsland"] = 23236649166,
		["BlackhoofVillage"] = 208854360,
		["BrackenwllVillage"] = 63490483584,
		["DirehornPost"] = 181838066967,
		["Mudsprocket"] = 336195845553,
		["ShadyRestInn"] = 202007353661,
		["TheWyrmbog"] = 396587478452,
		["TheramoreIsle"] = 240013008177,
		["WitchHill"] = 449152270,
	},
	["Felwood"] = {
		["BloodvenomFalls"] = 248265245017,
		["DeadwoodVillage"] = 542669704365,
		["EmeraldSanctuary"] = 410582733074,
		["FelpawVillage"] = 494044467,
		["IrontreeWoods"] = 59481801989,
		["JadefireGlen"] = 492075960549,
		["JadefireRun"] = 9981598983,
		["Jaedenar"] = 340621705535,
		["MorlosAran"] = 520190345403,
		["RuinsofConstellas"] = 385765038348,
		["ShatterScarVale"] = 115145435479,
		["TalonbranchGlade"] = 61760309457,
	},
	["Feralas"] = {
		["CampMojache"] = 195051090094,
		["DarkmistRuins"] = 308759697580,
		["DireMaul"] = 108956774665,
		["FeathermoonStronghold"] = 254856593625,
		["FeralScar"] = 302200835263,
		["GordunniOutpost"] = 125249418432,
		["GrimtotemCompund"] = 183172819103,
		["LowerWilds"] = 205877626063,
		["RuinsofFeathermoon"] = 246082121936,
		["RuinsofIsildien"] = 380594533582,
		["TheForgottenCoast"] = 368686973122,
		["TheTwinColossals"] = 284506462,
		["WrithingDeep"] = 320658946280,
	},
	["Hyjal"] = {
		["ArchimondesVengeance"] = 5704560910,
		["AshenLake"] = 83758582042,
		["DarkwhisperGorge"] = 138154564928,
		["DireforgeHill"] = 211845035278,
		["GatesOfSothann"] = 344249940240,
		["Nordrassil"] = 411373081,
		["SethriasRoost"] = 468297425173,
		["ShrineOfGoldrinn"] = 18375574819,
		["TheRegrowth"] = 271711534521,
		["TheScorchedPlain"] = 232359469421,
		["TheThroneOfFlame"] = 406208154019,
	},
	["Moonglade"] = {
		["LakeEluneara"] = 293361483183,
		["Nighthaven"] = 145343369562,
		["ShrineofRemulos"] = 97929961743,
		["StormrageBarrowDens"] = 226054465811,
	},
	["Mulgore"] = {
		["BaeldunDigsite"] = 236460376282,
		["BloodhoofVillage"] = 293466242350,
		["PalemaneRock"] = 344931382444,
		["RavagedCaravan"] = 240974468283,
		["RedCloudMesa"] = 430870634942,
		["RedRocks"] = 46710056122,
		["StonetalonPass"] = 210952429,
		["TheGoldenPlains"] = 108917907642,
		["TheRollingPlains"] = 313011719428,
		["TheVentureCoMine"] = 148732424400,
		["ThunderBluff"] = 66790362485,
		["ThunderhornWaterWell"] = 217245195465,
		["WildmaneWaterWell"] = 347254974,
		["WindfuryRidge"] = 419637470,
		["WinterhoofWaterWell"] = 365543220398,
	},
	["Silithus"] = {
		["CenarionHold"] = 153993089316,
		["HiveAshi"] = 4656999829,
		["HiveRegal"] = 333258791401,
		["HiveZora"] = 221191192094,
		["SouthwindVillage"] = 194924236085,
		["TheCrystalVale"] = 132372809,
		["TheScarabWall"] = 488552748612,
		["TwilightBaseCamp"] = 162240110002,
		["ValorsRest"] = 644117819,
	},
	["SouthernBarrens"] = {
		["BaelModan"] = 491117563149,
		["Battlescar"] = 329926304128,
		["ForwardCommand"] = 269952921816,
		["FrazzlecrazMotherload"] = 468433702130,
		["HonorsStand"] = 210938171,
		["HuntersHill"] = 69034232026,
		["NorthwatchHold"] = 158414953752,
		["RazorfenKraul"] = 567222087894,
		["RuinsofTaurajo"] = 307346189597,
		["TheOvergrowth"] = 125931063651,
		["VendettaPoint"] = 210733586686,
	},
	["StonetalonMountains"] = {
		["BattlescarValley"] = 203168195874,
		["BoulderslideRavine"] = 550313816258,
		["CliffwalkerPost"] = 102389448945,
		["GreatwoodVale"] = 481667805506,
		["KromgarFortress"] = 366762725559,
		["Malakajin"] = 577247513811,
		["MirkfallonLake"] = 153982590196,
		["RuinsofEldrethar"] = 441692957917,
		["StonetalonPeak"] = 278122801,
		["SunRockRetreat"] = 306386794718,
		["ThaldarahOverlook"] = 130187195602,
		["TheCharredVale"] = 395345938709,
		["UnearthedGrounds"] = 396896712969,
		["WebwinderHollow"] = 431073003684,
		["WebwinderPath"] = 282885193995,
		["WindshearCrag"] = 192758971766,
		["WindshearHold"] = 310852646064,
	},
	["Tanaris"] = {
		["AbyssalSands"] = 159225415935,
		["BrokenPillar"] = 226992753859,
		["CavernsofTime"] = 256082359509,
		["DunemaulCompound"] = 276271645927,
		["EastmoonRuins"] = 366544587949,
		["Gadgetzan"] = 99216445629,
		["GadgetzanBay"] = 10166293758,
		["LandsEndBeach"] = 485783462112,
		["LostRiggerCover"] = 216467229874,
		["SandsorrowWatch"] = 106607826134,
		["SouthbreakShore"] = 310769805586,
		["SouthmoonRuins"] = 375051734248,
		["TheGapingChasm"] = 391311977697,
		["TheNoxiousLair"] = 226830252211,
		["ThistleshrubValley"] = 300841997533,
		["ValleryoftheWatchers"] = 463050307853,
		["ZulFarrak"] = 193132859,
	},
	["Teldrassil"] = {
		["BanethilHollow"] = 237689351343,
		["Darnassus"] = 194503853354,
		["GalardellValley"] = 254965639346,
		["GnarlpineHold"] = 381542388934,
		["LakeAlameth"] = 333302671649,
		["PoolsofArlithrien"] = 261281237132,
		["RutheranVillage"] = 481381544253,
		["Shadowglen"] = 112173737201,
		["StarbreezeVillage"] = 233572602043,
		["TheCleft"] = 117491075216,
		["TheOracleGlade"] = 96926421186,
		["WellspringLake"] = 89521382565,
	},
	["ThousandNeedles"] = {
		["DarkcloudPinnacle"] = 124731519293,
		["FreewindPost"] = 200005664180,
		["Highperch"] = 143881793782,
		["RazorfenDowns"] = 312797545,
		["RustmaulDiveSite"] = 499842755818,
		["SouthseaHoldfast"] = 443174617334,
		["SplithoofHeights"] = 53212506543,
		["TheGreatLift"] = 142844176,
		["TheShimmeringDeep"] = 276571778459,
		["TheTwilightWithering"] = 353625263478,
		["TwilightBulwark"] = 258903279974,
		["WestreachSummit"] = 333080,
	},
	["Uldum"] = {
		["AkhenetFields"] = 297920554148,
		["CradelOfTheAncient"] = 432001950922,
		["HallsOfOrigination"] = 198196840717,
		["KhartutsTomb"] = 568548555,
		["LostCityOfTheTolVir"] = 313011799273,
		["Marat"] = 187256997024,
		["Nahom"] = 174557694189,
		["Neferset"] = 412743891153,
		["ObeliskOfTheMoon"] = 115573136,
		["ObeliskOfTheStars"] = 130500700356,
		["ObeliskOfTheSun"] = 303151918349,
		["Orsis"] = 146305961209,
		["Ramkahen"] = 72371899620,
		["RuinsOfAhmtul"] = 382907670,
		["RuinsOfAmmon"] = 310539183307,
		["Schnottzslanding"] = 237326599480,
		["TahretGrounds"] = 207803808918,
		["TempleofUldum"] = 136503837992,
		["TheCursedlanding"] = 183324963053,
		["TheGateofUnendingCycles"] = 16784797857,
		["TheTrailOfDevestation"] = 375425020110,
		["TheVortexPinnacle"] = 508567948501,
		["ThroneOfTheFourWinds"] = 465170568462,
		["VirnaalDam"] = 231356907671,
	},
	["UngoroCrater"] = {
		["FirePlumeRidge"] = 206532018497,
		["FungalRock"] = 584252640,
		["GolakkaHotSprings"] = 242817979701,
		["IronstonePlateau"] = 216562628805,
		["LakkariTarPits"] = 320117168,
		["MarshalsStand"] = 354819418316,
		["MossyPile"] = 192543909050,
		["TerrorRun"] = 383496000828,
		["TheMarshlands"] = 275479163143,
		["TheRollingGarden"] = 42468705617,
		["TheScreamingReaches"] = 164966732,
		["TheSlitheringScar"] = 412668414333,
	},
	["Winterspring"] = {
		["Everlook"] = 209885304002,
		["FrostfireHotSprings"] = 126799349112,
		["FrostsaberRock"] = 319041868,
		["FrostwhisperGorge"] = 509398408509,
		["IceThistleHills"] = 337764377849,
		["LakeKeltheril"] = 288153143567,
		["Mazthoril"] = 365490845953,
		["OwlWingThicket"] = 471955822846,
		["StarfallVillage"] = 35673952623,
		["TheHiddenGrove"] = 18778160461,
		["TimbermawPost"] = 324366758250,
		["WinterfallVillage"] = 194964047069,
	},
	-- Outlands
	["BladesEdgeMountains"] = {
		["BashirLanding"] = 442761472,
		["BladedGulch"] = 158493573376,
		["BladesipreHold"] = 173202205952,
		["BloodmaulCamp"] = 102437748992,
		["BloodmaulOutpost"] = 398717134080,
		["BrokenWilds"] = 117806727424,
		["CircleofWrath"] = 225946370304,
		["DeathsDoor"] = 267899014400,
		["ForgeCampAnger"] = 158454776224,
		["ForgeCampTerror"] = 446827852288,
		["ForgeCampWrath"] = 189245161728,
		["Grishnath"] = 30364926208,
		["GruulsLayer"] = 87525949696,
		["JaggedRidge"] = 444997040384,
		["MokNathalVillage"] = 319591547136,
		["RavensWood"] = 59280458240,
		["RazorRidge"] = 357041520896,
		["RidgeofMadness"] = 277606721792,
		["RuuanWeald"] = 105729491200,
		["Skald"] = 76941623552,
		["Sylvanaar"] = 376113002752,
		["TheCrystalpine"] = 613679360,
		["ThunderlordStronghold"] = 292482855168,
		["VeilLashh"] = 459845910784,
		["VeilRuuan"] = 162725495040,
		["VekhaarStand"] = 436598997248,
		["VortexPinnacle"] = 221365352704,
	},
	["Hellfire"] = {
		["DenofHaalesh"] = 442572734720,
		["ExpeditionArmory"] = 443729313280,
		["FalconWatch"] = 350232074752,
		["FallenSkyRidge"] = 152507252992,
		["ForgeCampRage"] = 27345289728,
		["HellfireCitadel"] = 225840670976,
		["HonorHold"] = 320467108096,
		["MagharPost"] = 118327869696,
		["PoolsofAggonar"] = 48660742400,
		["RuinsofShanaar"] = 311411730688,
		["TempleofTelhamat"] = 163249127936,
		["TheLegionFront"] = 138046603520,
		["TheStairofDestiny"] = 168277049600,
		["Thrallmar"] = 165846188288,
		["ThroneofKiljaeden"] = 6942884352,
		["VoidRidge"] = 395876499712,
		["WarpFields"] = 438409892096,
		["ZethGor"] = 462317402534,
	},
	["Nagrand"] = {
		["BurningBladeRUins"] = 359322171648,
		["ClanWatch"] = 390326386944,
		["ForgeCampFear"] = 266326151680,
		["ForgeCampHate"] = 165526372608,
		["Garadar"] = 153997279488,
		["Halaa"] = 207583707392,
		["KilsorrowFortress"] = 459073111296,
		["LaughingSkullRuins"] = 56202887424,
		["OshuGun"] = 358806272512,
		["RingofTrials"] = 287248220416,
		["SouthwindCleft"] = 277435646208,
		["SunspringPost"] = 213904523520,
		["Telaar"] = 419165372672,
		["ThroneoftheElements"] = 57437061376,
		["TwilightRidge"] = 114901385472,
		["WarmaulHill"] = 34524627200,
		["WindyreedPass"] = 85452914944,
		["WindyreedVillage"] = 250880459008,
		["ZangarRidge"] = 58272776448,
	},
	["Netherstorm"] = {
		["Area52"] = 416864665856,
		["ArklonRuins"] = 426619699456,
		["CelestialRidge"] = 186432880896,
		["EcoDomeFarfield"] = 11152916736,
		["EtheriumStagingGrounds"] = 223842926848,
		["ForgeBaseOG"] = 23871095040,
		["KirinVarVillage"] = 562080924928,
		["ManaforgeBanar"] = 301875989760,
		["ManaforgeCoruu"] = 525434277120,
		["ManaforgeDuro"] = 361265103104,
		["ManafrogeAra"] = 166609551616,
		["Netherstone"] = 21906063616,
		["NetherstormBridge"] = 315818770688,
		["RuinedManaforge"] = 148714553600,
		["RuinsofEnkaat"] = 323461841152,
		["RuinsofFarahlon"] = 52984807936,
		["SocretharsSeat"] = 41042575616,
		["SunfuryHold"] = 484733838592,
		["TempestKeep"] = 305564877209,
		["TheHeap"] = 488803357952,
		["TheScrapField"] = 280620171520,
		["TheStormspire"] = 144194142464,
	},
	["ShadowmoonValley"] = {
		["AltarofShatar"] = 100403511552,
		["CoilskarPoint"] = 8955363840,
		["EclipsePoint"] = 333219994112,
		["IlladarPoint"] = 275028115712,
		["LegionHold"] = 166539559424,
		["NetherwingCliffs"] = 331293655296,
		["NetherwingLedge"] = 478350114284,
		["ShadowmoonVilliage"] = 37703123456,
		["TheBlackTemple"] = 135927431564,
		["TheDeathForge"] = 138817306880,
		["TheHandofGuldan"] = 97050427904,
		["TheWardensCage"] = 277517593088,
		["WildhammerStronghold"] = 246063488512,
	},
	["TerokkarForest"] = {
		["AllerianStronghold"] = 297930064128,
		["AuchenaiGrounds"] = 466263189760,
		["BleedingHollowClanRuins"] = 323304668416,
		["BonechewerRuins"] = 295825572096,
		["CarrionHill"] = 292453351680,
		["CenarionThicket"] = 329515264,
		["FirewingPoint"] = 160635027841,
		["GrangolvarVilliage"] = 183760060928,
		["RaastokGlade"] = 165886034176,
		["RazorthornShelf"] = 20902576384,
		["RefugeCaravan"] = 288094421120,
		["RingofObservance"] = 370766250240,
		["SethekkTomb"] = 310568550656,
		["ShattrathCity"] = 4404544000,
		["SkethylMountains"] = 374133293568,
		["SmolderingCaravan"] = 494258045184,
		["StonebreakerHold"] = 177583948032,
		["TheBarrierHills"] = 4416864512,
		["Tuurem"] = 36984848640,
		["VeilRhaze"] = 388927586560,
		["WrithingMound"] = 351551095040,
	},
	["Zangarmarsh"] = {
		["AngoroshGrounds"] = 53779628288,
		["AngoroshStronghold"] = 130154752,
		["BloodscaleEnclave"] = 443006845184,
		["CenarionRefuge"] = 345399099700,
		["CoilfangReservoir"] = 97121730816,
		["FeralfenVillage"] = 356811883008,
		["MarshlightLake"] = 163293954304,
		["OreborHarborage"] = 27189051648,
		["QuaggRidge"] = 349114293504,
		["Sporeggar"] = 216917082624,
		["Telredor"] = 120856248576,
		["TheDeadMire"] = 138190258462,
		["TheHewnBog"] = 54990995712,
		["TheLagoon"] = 325880905984,
		["TheSpawningGlen"] = 364031246592,
		["TwinspireRuins"] = 267720589568,
		["UmbrafenVillage"] = 495750167808,
		["ZabraJin"] = 249291866368,
	},
	-- Northrend
	["BoreanTundra"] = {
		["AmberLedge"] = 150664861940,
		["BorGorokOutpost"] = 329461132,
		["Coldarra"] = 52819404,
		["DeathsStand"] = 195088899361,
		["GarroshsLanding"] = 255711373579,
		["Kaskala"] = 230314799489,
		["RiplashStrand"] = 411550615934,
		["SteeljawsCaravan"] = 71283571956,
		["TempleCityOfEnKilah"] = 16853012770,
		["TheDensOfDying"] = 12505531595,
		["TheGeyserFields"] = 503667063,
		["TorpsFarm"] = 254762307770,
		["ValianceKeep"] = 283947350275,
		["WarsongStronghold"] = 254822078724,
	},
	["CrystalsongForest"] = {
		["ForlornWoods"] = 135950880,
		["SunreaversCommand"] = 43512087998,
		["TheAzureFront"] = 261993439648,
		["TheDecrepitFlow"] = 227616,
		["TheGreatTree"] = 97710772476,
		["TheUnboundThicket"] = 113267668470,
		["VioletStand"] = 188978871560,
		["WindrunnersOverlook"] = 411708978734,
	},
	["Dragonblight"] = {
		["AgmarsHammer"] = 218240346348,
		["Angrathar"] = 220449074,
		["ColdwindHeights"] = 422800597,
		["EmeraldDragonshrine"] = 389264140484,
		["GalakrondsRest"] = 127155799298,
		["IcemistVillage"] = 177308255467,
		["LakeIndule"] = 336309039460,
		["LightsRest"] = 8253626667,
		["Naxxramas"] = 172523536695,
		["NewHearthglen"] = 385043666134,
		["ObsidianDragonshrine"] = 111937793328,
		["RubyDragonshrine"] = 223730683068,
		["ScarletPoint"] = 8113195243,
		["TheCrystalVice"] = 510921957,
		["TheForgottenShore"] = 357214484781,
		["VenomSpite"] = 284161167586,
		["WestwindRefugeeCamp"] = 200834067685,
		["WyrmrestTemple"] = 235624826173,
	},
	["GrizzlyHills"] = {
		["AmberpineLodge"] = 262220843286,
		["BlueSkyLoggingGrounds"] = 138756205817,
		["CampOneqwah"] = 147677521220,
		["ConquestHold"] = 329656867148,
		["DrakTheronKeep"] = 49392416126,
		["DrakilJinRuins"] = 44660191583,
		["DunArgol"] = 276525629895,
		["GraniteSprings"] = 222272127332,
		["GrizzleMaw"] = 201165344038,
		["RageFangShrine"] = 316007623131,
		["ThorModan"] = 533977417,
		["UrsocsDen"] = 34707083592,
		["VentureBay"] = 495014067474,
		["Voldrune"] = 452230110491,
	},
	["HowlingFjord"] = {
		["AncientLift"] = 377242188977,
		["ApothecaryCamp"] = 39832528135,
		["BaelgunsExcavationSite"] = 351765054708,
		["Baleheim"] = 183140267182,
		["CampWinterHoof"] = 371410143,
		["CauldrosIsle"] = 173386418357,
		["EmberClutch"] = 218266599637,
		["ExplorersLeagueOutpost"] = 361390891240,
		["FortWildervar"] = 513999099,
		["GiantsRun"] = 600099114,
		["Gjalerbron"] = 236123378,
		["Halgrind"] = 223754853563,
		["IvaldsRuin"] = 240145081537,
		["Kamagua"] = 298604307789,
		["NewAgamand"] = 386982531356,
		["Nifflevar"] = 258322153650,
		["ScalawagPoint"] = 440410573150,
		["Skorn"] = 116324016366,
		["SteelGate"] = 107607138526,
		["TheTwistedGlade"] = 61643901194,
		["UtgardeKeep"] = 232428796152,
		["VengeanceLanding"] = 27540146399,
		["WestguardKeep"] = 193368125787,
	},
	["IcecrownGlacier"] = {
		["Aldurthar"] = 40101076341,
		["ArgentTournamentGround"] = 32858407226,
		["Corprethar"] = 421265625396,
		["IcecrownCitadel"] = 500774938932,
		["Jotunheim"] = 131020056969,
		["OnslaughtHarbor"] = 179315159244,
		["Scourgeholme"] = 287412829429,
		["SindragosasFall"] = 33942756652,
		["TheBombardment"] = 194911653112,
		["TheBrokenFront"] = 353846402331,
		["TheConflagration"] = 327834355939,
		["TheFleshwerks"] = 312687750363,
		["TheShadowVault"] = 16443129055,
		["Valhalas"] = 53914878190,
		["ValleyofEchoes"] = 419509265677,
		["Ymirheim"] = 296818523359,
	},
	["SholazarBasin"] = {
		["KartaksHold"] = 402733176137,
		["RainspeakerCanopy"] = 262440987855,
		["RiversHeart"] = 364375254484,
		["TheAvalanche"] = 99409470786,
		["TheGlimmeringPillar"] = 36830518566,
		["TheLifebloodPillar"] = 144407119160,
		["TheMakersOverlook"] = 254142609641,
		["TheMakersPerch"] = 145135755513,
		["TheMosslightPillar"] = 381456540911,
		["TheSavageThicket"] = 55176303909,
		["TheStormwrightsShelf"] = 62422024460,
		["TheSuntouchedPillar"] = 199802286535,
	},
	["TheStormPeaks"] = {
		["BorsBreath"] = 402767678786,
		["BrunnhildarVillage"] = 397640247601,
		["DunNiffelem"] = 306521177397,
		["EngineoftheMakers"] = 318159113426,
		["Frosthold"] = 460775977204,
		["GarmsBane"] = 505073040568,
		["NarvirsCradle"] = 154843462836,
		["Nidavelir"] = 221304266973,
		["SnowdriftPlains"] = 153715187917,
		["SparksocketMinefield"] = 502765134075,
		["TempleofLife"] = 121930791094,
		["TempleofStorms"] = 323447066793,
		["TerraceoftheMakers"] = 131303036267,
		["Thunderfall"] = 192857739570,
		["Ulduar"] = 228861297,
		["Valkyrion"] = 341552822500,
	},
	["ZulDrak"] = {
		["AltarOfHarKoa"] = 371000083721,
		["AltarOfMamToth"] = 95092536631,
		["AltarOfQuetzLun"] = 270145978629,
		["AltarOfRhunok"] = 136817459447,
		["AltarOfSseratus"] = 180690870509,
		["AmphitheaterOfAnguish"] = 308467202314,
		["DrakSotraFields"] = 384741680414,
		["GunDrak"] = 659858768,
		["Kolramas"] = 469623872814,
		["LightsBreach"] = 389958387009,
		["ThrymsEnd"] = 265214505232,
		["Voltarus"] = 205267438810,
		["Zeramas"] = 442389233971,
		["ZimTorga"] = 259274311929,
	},
	-- The Maelstrom
	["Deepholm"] = {
		["CrimsonExpanse"] = 13451542990,
		["DeathwingsFall"] = 319477341638,
		["NeedlerockChasm"] = 21339514,
		["NeedlerockSlag"] = 156766598514,
		["ScouredReach"] = 470056452,
		["StoneHearth"] = 337155295603,
		["StormsFuryWreckage"] = 411723658532,
		["TempleOfEarth"] = 190353597795,
		["ThePaleRoost"] = 89408979,
		["TheShatteredField"] = 470447004078,
		["TherazanesThrone"] = 455242002,
		["TwilightOverlook"] = 451569508763,
		["TwilightTerrace"] = 412628490477,
	},
	["Kezan"] = {
		["BilgewaterPort"] = 159085005494,
		["Drudgetown"] = 394252301663,
		["FirstbankofKezan"] = 349069204856,
		["GallywixsVilla"] = 44023877935,
		["KTCHeadquarters"] = 287143511361,
		["Kajamine"] = 331327316322,
		["KajaroField"] = 279574793466,
		["KezanMap"] = 4295648234,
		["SwindleStreet"] = 249440720040,
		["TheSlick"] = 116193962576,
	},
	["TheLostIsles"] = {
		["Alliancebeachhead"] = 373797597361,
		["BilgewaterLumberyard"] = 46655554808,
		["GallywixDocks"] = 22916812973,
		["HordeBaseCamp"] = 492029802718,
		["KTCOilPlatform"] = 12265339036,
		["Lostpeak"] = 23158330718,
		["OoomlotVillage"] = 370973822173,
		["Oostan"] = 173388597458,
		["RaptorRise"] = 395573408936,
		["RuinsOfVashelan"] = 485792899284,
		["ScorchedGully"] = 198981222705,
		["ShipwreckShore"] = 438285024428,
		["SkyFalls"] = 141096577214,
		["TheSavageGlen"] = 349189660903,
		["TheSlavePits"] = 73307194580,
		["WarchiefsLookout"] = 154895882399,
		["landingSite"] = 385868764302,
	},
	-- Pandaria
	["TheWanderingIsle"] = {
		["RidgeofLaughingWinds"] = 212793099577,
		["SkyfireCrash-Site"] = 434995731802,
		["TheSingingPools"] = 13456862580,
		["TheRows"] = 317282702721,
		["MorningBreezeVillage"] = 38867889413,
		["Pei-WuForest"] = 436307499659,
		["TheDawningValley"] = 341471909,
		["MandoriVillage"] = 316091521634,
		["Fe-FangVillage"] = 9804478698,
		["TempleofFiveDawns"] = 195835672159,
		["TheWoodofStaves"] = 216909958109,
	},
	["TheJadeForest"] = {
		["EmperorsOmen"] = 22999675082,
		["DreamersPavillion"] = 558842925274,
		["ChunTianMonastery"] = 60444317923,
		["WindlessIsle"] = 46736437499,
		["TempleOfTheJadeSerpent"] = 317244787976,
		["HellscreamsHope"] = 80720599236,
		["GrookinMound"] = 229971825917,
		["DawnsBlossom"] = 191467047146,
		["SlingtailPits"] = 447125573811,
		["WreckOfTheSkyShark"] = 211974354,
		["JadeMines"] = 157185882348,
		["NectarbreezeOrchard"] = 354639151323,
		["Waywardlanding"] = 517906557147,
		["GlassfinVillage"] = 384950393110,
		["RuinsOfGanShi"] = 331512004,
		["SerpentsSpine"] = 321455874239,
		["TheArboretum"] = 231359072498,
		["NookaNooka"] = 162333406427,
	},
	["Krasarang"] = {
		["ZhusBastion"] = 641937714,
		["RuinsOfKorja"] = 94620757203,
		["NayeliLagoon"] = 400865607926,
		["TheForbiddenJungle"] = 84825911553,
		["krasarangCove"] = 21136421150,
		["UngaIngoo"] = 535069632770,
		["CradleOfChiJi"] = 403911731472,
		["TheSouthernIsles"] = 286713505020,
		["TempleOfTheRedCrane"] = 231169330395,
		["TheDeepwild"] = 63767474364,
		["LostDynasty"] = 29608926425,
		["RedwingRefuge"] = 67978405076,
		["FallsongRiver"] = 82907112662,
		["RuinsOfDojan"] = 47710600396,
		["DojaniRiver"] = 3759433918,
		["AnglersOutpost"] = 220688746761,
	},
	["ValleyoftheFourWinds"] = {
		["KuzenVillage"] = 79692087495,
		["CliffsofDispair"] = 434017411582,
		["Theheartland"] = 80796328222,
		["ThunderfootFields"] = 652539260,
		["DustbackGorge"] = 368293761233,
		["GrandGranery"] = 349316534586,
		["MudmugsPlace"] = 173460907238,
		["SingingMarshes"] = 139764993199,
		["ZhusDecent"] = 123139853615,
		["PoolsofPurity"] = 62815197397,
		["SilkenFields"] = 272212692222,
		["Halfhill"] = 190511830222,
		["NesingwarySafari"] = 350149236985,
		["RumblingTerrace"] = 323806811413,
		["GildedFan"] = 44482990288,
		["HarvestHome"] = 256629796100,
		["StormsoutBrewery"] = 408260215041,
		["PaoquanHollow"] = 112755726609,
	},
	["TheHiddenPass"] = {
		["TheHiddenSteps"] = 512607059234,
		["TheBlackMarket"] = 188294346207,
		["TheHiddenCliffs"] = 454258982,
	},
	["KunLaiSummit"] = {
		["Mogujia"] = 441792545021,
		["Kotapeak"] = 386791638268,
		["GateoftheAugust"] = 543784339717,
		["PeakOfSerenity"] = 67995194655,
		["BinanVillage"] = 505295345904,
		["ValleyOfEmperors"] = 205559940320,
		["TEMPLEOFTHEWHITETIGER"] = 183151890682,
		["ZouchinVillage"] = 69246086442,
		["FireboughNook"] = 532913762528,
		["Iseoflostsouls"] = 4926448899,
		["ShadoPanMonastery"] = 98876917121,
		["TheBurlapTrail"] = 333277581622,
		["MuskpawRanch"] = 336713750757,
		["MountNeverset"] = 283707130169,
	},
	["TownlongWastes"] = {
		["Sikvess"] = 465251314949,
		["SriVess"] = 206255189286,
		["palewindVillage"] = 389420468506,
		["ShadoPanGarrison"] = 413823838421,
		["ShanzeDao"] = 131324204,
		["KriVess"] = 224852718847,
		["OsulMesa"] = 199229743342,
		["TheSumprushes"] = 396782417167,
		["NiuzaoTemple"] = 258995494184,
		["MingChiCrossroads"] = 480400078071,
		["GaoRanBlockade"] = 503083901281,
	},
	["ValeofEternalBlossoms"] = {
		["MistfallVillage"] = 389978309942,
		["GuoLaiRuins"] = 3312809297,
		["WhitepetalLake"] = 182827902219,
		["WhiteMoonShrine"] = 11243100458,
		["WinterboughGlade"] = 114894910825,
		["MoguShanPalace"] = 24282269045,
		["TheGoldenStair"] = 17524062450,
		["SettingSunTraining"] = 251256026462,
		["TheTwinMonoliths"] = 104619059472,
		["TuShenBurialGround"] = 339668685067,
		["TheStairsAscent"] = 287272443326,
	},
	["DreadWastes"] = {
		["SOGGYSGAMBLE"] = 436411286796,
		["BRINYMUCK"] = 334158379333,
		["HORRIDMARCH"] = 240980789571,
		["BREWGARDEN"] = 368273658,
		["HEARTOFFEAR"] = 131197080838,
		["DREADWATERLAKE"] = 336539635010,
		["CLUTCHESOFSHEKZEER"] = 134575618257,
		["RIKKITUNVILLAGE"] = 34607392986,
		["TERRACEOFGURTHAN"] = 99406293201,
		["KLAXXIVESS"] = 118592059628,
		["KYPARIVOR"] = 508754245,
		["ZANVESS"] = 413560761634,
	},
	['*'] = {},
}
zoneData.Hyjal_terrain1 = zoneData.Hyjal
zoneData.Uldum_terrain1 = zoneData.Uldum

--------------------------------------------------
-- Local Functions
--------------------------------------------------

local function updateOverlayTextures(frame, frameName, textureCache, scale, opacity)
	local mapFileName, _, _, isMicroDungeon = GetMapInfo()
	if not mapFileName or isMicroDungeon then
		for i, texture in ipairs(textureCache) do
			texture:Hide()
		end
		return
	end

	local pathPrefix = format(texPathTemplate, mapFileName)
	local overlayMap = global[mapFileName]

	local numOverlays = module.hooks.GetNumMapOverlays()
	local pathLen = strlen(pathPrefix) + 1

	for i = 1, numOverlays do
		local texName, texWidth, texHeight, offsetX, offsetY = GetMapOverlayInfo(i)
		texName = strsub(texName, pathLen)
		local texData = texWidth + texHeight * 2^10 + offsetX * 2^20 + offsetY * 2^30
		if texData ~= 0 and texData ~= 131200 and texName ~= "" and strlower(texName) ~= "pixelfix" then
			discoveredOverlays[texName] = texData
			overlayMap[texName] = texData -- AceDB will wipe any values that match the default on logout
		end
	end

	local textureCount = 0
	local r, g, b, a = unpack(db.Color)

	local numOv = #textureCache
	for texName, texData in pairs(overlayMap) do
		local texWidth, texHeight, offsetX, offsetY = mod(texData, 2^10), mod(floor(texData / 2^10), 2^10), mod(floor(texData / 2^20), 2^10), floor(texData / 2^30)

		local numTexWide = ceil(texWidth / 256)
		local numTexTall = ceil(texHeight / 256)
		local neededTextures = textureCount + (numTexWide * numTexTall)
		if neededTextures > numOv then
			for j = numOv + 1, neededTextures do
				local texture = frame:CreateTexture(format(frameName, j), "ARTWORK")
				tinsert(textureCache, texture)
			end
			numOv = neededTextures
		end
		local texPixelWidth, texFileWidth, texPixelHeight, texFileHeight
		for j = 1, numTexTall do
			if j < numTexTall then
				texPixelHeight = 256
				texFileHeight = 256
			else
				texPixelHeight = mod(texHeight, 256)
				if texPixelHeight == 0 then
					texPixelHeight = 256
				end
				texFileHeight = 16
				while texFileHeight < texPixelHeight do
					texFileHeight = texFileHeight * 2
				end
			end
			for k = 1, numTexWide do
				textureCount = textureCount + 1
				local texture = textureCache[textureCount]
				if k < numTexWide then
					texPixelWidth = 256
					texFileWidth = 256
				else
					texPixelWidth = mod(texWidth, 256)
					if texPixelWidth == 0 then
						texPixelWidth = 256
					end
					texFileWidth = 16
					while texFileWidth < texPixelWidth do
						texFileWidth = texFileWidth * 2
					end
				end
				texture:SetWidth(texPixelWidth*scale)
				texture:SetHeight(texPixelHeight*scale)
				texture:SetTexCoord(0, texPixelWidth / texFileWidth, 0, texPixelHeight / texFileHeight)
				texture:ClearAllPoints()
				texture:SetPoint("TOPLEFT", (offsetX + (256 * (k-1))) * scale, -(offsetY + (256 * (j - 1))) * scale)
				texture:SetTexture(format("%s%s%d", pathPrefix, texName, ((j - 1) * numTexWide) + k))

				if discoveredOverlays[texName] then
					texture:SetVertexColor(1, 1, 1)
					texture:SetAlpha(1)
					texture:SetDrawLayer("ARTWORK")
				else
					texture:SetVertexColor(r, g, b)
					texture:SetAlpha(a)
					texture:SetDrawLayer("BORDER")
				end

				texture:Show()
			end
		end
	end

	for i = textureCount+1, numOv do
		textureCache[i]:Hide()
	end

	wipe(discoveredOverlays)
end

--------------------------------------------------
-- Hook Functions
--------------------------------------------------

function module:GetNumMapOverlays()
	return 0
end

function module:WorldMapFrame_Update()
	if not WorldMapFrame:IsShown() then return end
	updateOverlayTextures(WorldMapDetailFrame, "WorldMapOverlay%d", worldMapCache, 1, 0)
end

function module:BattlefieldMinimap_Update()
	if not BattlefieldMinimap or not BattlefieldMinimap:IsShown() then return end
	local scale = BattlefieldMinimap1:GetWidth()/256
	updateOverlayTextures(BattlefieldMinimap, "BattlefieldMinimapOverlay%d", battleMapCache, scale, BattlefieldMinimapOptions.opacity)
end

--------------------------------------------------
-- Event Functions
--------------------------------------------------

function module:ADDON_LOADED(event, addon)
	if addon == "Blizzard_BattlefieldMinimap" then
		self:UnregisterEvent(event)
		self:SetBattleMapFogClear()
	end
end

--------------------------------------------------
-- FogClear Functions
--------------------------------------------------

function module:HasOverlays()
	local mapFileName = GetMapInfo()
	if not mapFileName or not global then return false end

	local overlayMap = global[mapFileName]
	if overlayMap and next(overlayMap) then return true end
end

function module:SetWorldMapFogClear()
	self:SecureHook("WorldMapFrame_Update")

	wipe(worldMapCache)
	for i = 1, _G.NUM_WORLDMAP_OVERLAYS do
		tinsert(worldMapCache, _G[format("WorldMapOverlay%d", i)])
	end
	_G.NUM_WORLDMAP_OVERLAYS = 0

	if WorldMapFrame:IsShown() then
		WorldMapFrame_Update()
	end
end

function module:SetBattleMapFogClear()
	self:SecureHook("BattlefieldMinimap_Update")

	wipe(battleMapCache)
	for i = 1, BattlefieldMinimap:GetAttribute("NUM_BATTLEFIELDMAP_OVERLAYS") do
		tinsert(battleMapCache, _G[format("BattlefieldMinimapOverlay%d", i)])
	end
	BattlefieldMinimap:SetAttribute("NUM_BATTLEFIELDMAP_OVERLAYS", 0)

	if BattlefieldMinimap:IsShown() then
		BattlefieldMinimap_Update()
	end
end

--------------------------------------------------
-- Module Functions
--------------------------------------------------

module.defaults = {
	global = zoneData,
	profile = {
		Color = {0.6, 0.6, 0.6, 1},
	},
}

function module:LoadOptions()
	local function fogClearDisabled()
		return not self:IsEnabled()
	end

	local function updateFogClear()
		self:Refresh()
	end

	local options = self:NewGroup("Fog Clear", 5, "generic", "Refresh", {
		Enable = self:NewEnable("Enable", nil, 1, nil, "normal"),
		Color = self:NewColor("Undiscovered Area", "undiscovered areas of the world", 2, updateFogClear, nil, fogClearDisabled),
	})

	return options
end

function module:Refresh(info, value)
	if type(info) == "table" then
		if info[#info] == "Enable" then
			return self:Toggle()
		end

		self:SetDBVar(info, value)
	end

	-- check to make sure hooks are in place before calling update functions
	if self:IsHooked("WorldMapFrame_Update") then
		self:WorldMapFrame_Update()
	end
	if self:IsHooked("BattlefieldMinimap_Update") then
		self:BattlefieldMinimap_Update()
	end
end

function module:OnInitialize()
	db, dbd = WorldMap:Namespace(self)
	global = self.db.global
end

module.DBCallback = module.OnInitialize

function module:OnEnable()
	self:RawHook("GetNumMapOverlays", true)

	if not IsAddOnLoaded("Blizzard_BattlefieldMinimap") then
		self:RegisterEvent("ADDON_LOADED")
	else
		self:SetBattleMapFogClear()
	end

	self:SetWorldMapFogClear()
end

function module:OnDisable()
	self:UnregisterAllEvents()
	self:UnhookAll()

	local tex
	_G.NUM_WORLDMAP_OVERLAYS = #worldMapCache
	for i = 1, _G.NUM_WORLDMAP_OVERLAYS do
		tex = _G[format("WorldMapOverlay%d", i)]
		tex:SetVertexColor(1, 1, 1)
		tex:SetAlpha(1)
		tex:SetDrawLayer("ARTWORK")
	end

	if WorldMapFrame:IsShown() then
		WorldMapFrame_Update()
	end

	if BattlefieldMinimap then
		local count = #battleMapCache
		BattlefieldMinimap:SetAttribute("NUM_BATTLEFIELDMAP_OVERLAYS", count)
		for i = 1, count do
			tex = _G[format("BattlefieldMinimapOverlay%d", i)]
			tex:SetVertexColor(1, 1, 1)
			tex:SetAlpha(1 - BattlefieldMinimapOptions.opacity)
		end

		if BattlefieldMinimap:IsShown() then
			BattlefieldMinimap_Update()
		end
	end
end