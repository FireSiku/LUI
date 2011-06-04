
local _, ns = ...
local oUF = ns.oUF or oUF
local ORD = ns.oUF_RaidDebuffs or oUF_RaidDebuffs

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
	[91910] = 7, -- Grievous Wound
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
	
}

ORD:RegisterDebuffs(debuff_data)