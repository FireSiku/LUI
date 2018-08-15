
local _, ns = ...
local oUF = ns.oUF or oUF
local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs

-- credits to authors of GridStatusRaidDebuff_Cata

if not ORD then return end

ORD.ShowDispelableDebuff = true
ORD.FilterDispellableDebuff = true
ORD.MatchBySpellName = true
ORD.SHAMAN_CAN_DECURSE = true

local debuff_data = {

	------------------------------------------------------------------------
	--	Baradin Hold
	------------------------------------------------------------------------
	
	-- Trash
	[89354] = 6, -- Arcane Amplifier

	-- Argaloth
	[88942] = 5, -- Meteor Slash
	[88954] = 6, -- Consuming Darkness

	------------------------------------------------------------------------
	--	Bastion of Twilight
	------------------------------------------------------------------------

	-- Trash
	[81118] = 6, -- Magma
	[87931] = 6, -- Tremors
	[85799] = 6, -- Phased Burn
	[88232] = 6, -- Crimson Flames
	[84850] = 6, -- Soul Blade
	[84853] = 6, -- Dark Pool
	[88219] = 6, -- Burning Twilight
	[88079] = 6, -- Frostfire Bolt
	[76622] = 4, -- Sunder Armor
	[88079] = 5, -- Dismantle
	[84856] = 6, -- Hungering Shadows
	[85643] = 6, -- Mind Sear
	[93277] = 7, -- Rending Gale
	[93306] = 6, -- Vaporize
	[93327] = 7, -- Entomb
	[93325] = 4, -- Shockwave
	[85482] = 6, -- Shadow Volley
	[87629] = 6, -- Gripping Shadows

	-- Halfus Wyrmbreaker
	[83710] = 6, -- Furious Roar
	[83908] = 7, -- Malevolent Strikes

	-- Valiona and Theralion
	[86788] = 6, -- Blackout
	[86622] = 6, -- Engulfing Magic
	[86202] = 6, -- Twilight Shift
	[86014] = 6, -- Twilight Meteorite

	-- Twilight Ascendant Council
	[82762] = 5, -- Waterlogged
	[83099] = 5, -- Lightning Rod
	[82285] = 6, -- Elemental Stasis
	[82660] = 6, -- Burning Blood
	[82665] = 6, -- Heart of Ice
	[82772] = 7, -- Frozen
	[84948] = 6, -- Gravity Crush
	[83500] = 4, -- Swirling Winds
	[83581] = 4, -- Grounded

	-- Cho'gall
	[81701] = 5, -- Corrupted Blood
	[81836] = 4, -- Corruption: Accelerated
	[82125] = 4, -- Corruption: Malformation
	[82170] = 5, -- Corruption: Absolute
	[82523] = 6, -- Gall's Blast
	[82518] = 6, -- Cho's Blast
	[82411] = 7, -- Debilitating Beam

	------------------------------------------------------------------------
	--	Blackwing Descent
	------------------------------------------------------------------------

	-- Trash
	[80390] = 6, -- Mortal Strike
	[80270] = 6, -- Shadow Flame
	[80145] = 6, -- Piercing Grip
	[80727] = 6, -- Execution Sentence
	[80345] = 6, -- Corrosive Acid
	[80329] = 6, -- Time Lapse
	[79630] = 6, -- Drakonid Rush
	[79589] = 6, -- Constricting Chains
	[79580] = 6, -- Overhead Smash
--	[91910] = 7, -- Grievous Wound
	[81060] = 6, -- Flash Bomb
	[80127] = 4, -- Flame Buffet

	-- Magmaw
	[89773] = 6, -- Mangle
	[78941] = 6, -- Parasitic Infection
	[88287] = 6, -- Massive Crash

	-- Omnitron Defense System
	[79888] = 6, -- Lightning Conductor
	[80161] = 6, -- Chemical Cloud
	[80011] = 6, -- Soaked in Poison
	[79505] = 6, -- Flamethrower
	[80094] = 6, -- Fixate
	[79501] = 6, -- Acquiring Target

	-- Chimaeron
	[89084] = 9, -- Low Health
	[82890] = 6, -- Mortality
	[82935] = 6, -- Caustic Slime
	[82881] = 8, -- Break

	-- Atramedes
	[78092] = 5, -- Tracking
	[77982] = 6, -- Searing Flame
	[78023] = 6, -- Roaring Flame
	[78897] = 7, -- Noisy!

	-- Maloriak
	[78034] = 5, -- Rend
	[78825] = 6, -- Acid Nova
	[77615] = 6, -- Debilitatint Slime
	[77786] = 6, -- Fixate
	[77760] = 6, -- Biting Chill
	[77699] = 7, -- Flash Freeze

	-- Nefarian
	[81118] = 6, -- Magma
	[77827] = 6, -- Tail Lash

	------------------------------------------------------------------------
	--	Throne of The Four Winds
	------------------------------------------------------------------------

	-- Conclave of Wind
	[84645] = 5, -- Wind Chill
	[86111] = 6, -- Ice Patch
	[86082] = 7, -- Permafrost
	[86481] = 7, -- Hurricane
	[86282] = 7, -- Toxic Spores
	[85573] = 8, -- Deafening Winds
	[85576] = 8, -- Withering Winds

	-- Al'Akir
	[88301] = 5, -- Acid Rain
	[87873] = 6, -- Static Shock
	[88427] = 6, -- Electrocute
	[89666] = 6, -- Lightning Rod
	[89668] = 6, -- Lightning Rod
	[87856] = 6, -- Squall Line
	
	------------------------------------------------------------------------
	--	Firelands
	------------------------------------------------------------------------
	
	-- Trash
	[76622] = 4, -- Sunder Armor
	[99610] = 5, -- Shockwave
	[99695] = 4, -- Flaming Spear
	[99800] = 4, -- Ensnare
	[99993] = 4, -- Fiery Blood
	[100767] = 4, -- Melt Armor
	[99693] = 4, -- Dinner Time
	[97151] = 4, -- Magma
	
	-- Beth'Tilac
	[99506] = 5, -- The Widow's Kiss
	[49026] = 6, -- Fixate
	[97202] = 5, -- Fiery Web Spin
	[97079] = 4, -- Seeping Venom
	
	-- Lord Rhyolith
	[98492] = 5, -- Eruption
	
	-- Alysrazor
--	[101729] = 5, -- Blazing Claw
	[100094] = 5, -- Fieroblast
	[99389] = 5, -- Imprinted
	[99308] = 5, -- Gushing Wound
	[100640] = 5, -- Harsh Winds
	[100555] = 5, -- Smouldering Roots
	[99461] = 4, -- Blazing Power

	-- Shannox
	[99936] = 4, -- Jagged Tear
	[99837] = 4, -- Crystal Prison Trap Effect
--	[101208] = 4, -- Immolation Trap
	[99840] = 4, -- Magma Rupture
	[99947] = 4, -- Face Rage
	[100415] = 4, -- Rage
	
	-- Baleroc
	[99252] = 5, -- Blaze of Glory
	[99256] = 5, -- Torment
--	[99403] = 6, -- Tormented
	[99262] = 4, -- Vital Spark
	[99263] = 4, -- Vital Flame
	[99516] = 7, -- Countdown
	[99353] = 7, -- Decimating Strike
--	[100908] = 6, -- Fiery Torment
	
	-- Majordomo Staghelm
	[98535] = 5, -- Leaping Flames
	[98443] = 6, -- Fiery Cyclone
	[98450] = 5, -- Searing Seeds
--	[100210] = 6, -- Burning Orb
	[96993] = 5, -- Stay Withdrawn?
	
	-- Ragnaros
	[99399] = 5, -- Burning Wound
--	[100293] = 5, -- Lava Wave
	[100238] = 4, -- Magma Trap Vulnerability
	[98313] = 4, -- Magma Blast
	[100460] = 7, -- Blazing Heat
	[98981] = 5, -- Lava Bolt
--	[100249] = 5, -- Combustion
	[99613] = 6, -- Molten Blast

--en_zone, debuffID, order, icon_priority, color_priority, timer, stackable, color, default_disable, noicon

--Trash

--Morchok
	[103687] = 4, --Crush Armor
	[103821] = 3, --Earthen Vortex
	[103785] = 6, --Black Blood of the Earth
	[103534] = 5, --Danger (Red)
	[103536] = 5, --Warning (Yellow)
	[103541] = 5, --Safe (Blue)

--Warlord Zon'ozz
	[104378] = 3, --Black Blood of Go'rath
	[103434] = 5, --Disrupting Shadows (dispellable)

--Yor'sahj the Unsleeping
	[104849] = 5, --Void Bolt
	[105171] = 4, --Deep Corruption

--Hagara the Stormbinder
	[105316] = 4, --Ice Lance
	[105465] = 6, --Lightning Storm
	[105369] = 5, --Lightning Conduit
	[105289] = 3, --Shattered Ice (dispellable)
	[105285] = 6, --Target (next Ice Lance)
	[104451] = 5, --Ice Tomb
	[110317] = 6, --Watery Entrenchment

--Ultraxion
	[105925] = 6, --Fading Light
	[106108] = 5, --Heroic Will
	[105984] = 3, --Timeloop
	[105927] = 4, --Faded Into Twilight

--Warmaster Blackhorn
	[108043] = 4, --Sunder Armor
	[107558] = 3, --Degeneration
	[107567] = 3, --Brutal Strike
	[108046] = 5, --Shockwave

--Spine of Deathwing
	[105563] = 3, --Grasping Tendrils
	[105479] = 6, --Searing Plasma
	[105490] = 5, --Fiery Grip

--Madness of Deathwing
	[105445] = 3, --Blistering Heat
	[105841] = 4, --Degenerative Bite
	[106385] = 5, --Crush
	[106730] = 5, --Tetanus
	[106444] = 5, --Impale
	[106794] = 6, --Shrapnel (target)
}

ORD:RegisterDebuffs(debuff_data)
