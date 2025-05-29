extends Node

var sword_1h = WeaponData.new(
	"Sword_1H",
	["Knight"],
	[
		WeaponData.hands_variants.Left,
		WeaponData.hands_variants.Right
	],
	1.0
)
var sword_2h = WeaponData.new(
	"Sword_2H",
	["Knight"],
	[
		WeaponData.hands_variants.Both
	],
	2.0
)
var sword_2h_colored = WeaponData.new(
	"Sword_2H_colored",
	["Knight"],
	[
		WeaponData.hands_variants.Both
	],
	2.0
)
var axe_1h = WeaponData.new(
	"Axe_1H",
	["Barbarian"],
	[
		WeaponData.hands_variants.Left,
		WeaponData.hands_variants.Right
	],
	1.5
)
var axe_2h = WeaponData.new(
	"Axe_2H",
	["Barbarian"],
	[
		WeaponData.hands_variants.Both
	],
	2.5
)
var crossbow = WeaponData.new(
	"Crossbow",
	["Rogue"],
	[
		WeaponData.hands_variants.Left,
		WeaponData.hands_variants.Right
	],
	0.75
)
var dagger = WeaponData.new(
	"Dagger",
	["Rogue"],
	[
		WeaponData.hands_variants.Left,
		WeaponData.hands_variants.Right
	],
	1.0
)
var mug = WeaponData.new(
	"Mug",
	["Barbarian"],
	[
		WeaponData.hands_variants.Left,
		WeaponData.hands_variants.Right
	],
	0.0
)
var shield_badge = WeaponData.new(
	"Shield_Badge",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_badge_colored = WeaponData.new(
	"Shield_Badge_Colored",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_round = WeaponData.new(
	"Shield_Round",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_round_colored = WeaponData.new(
	"Shield_Round_Colored",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_round_barbarian = WeaponData.new(
	"Shield_Round_Barbarian",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_spikes = WeaponData.new(
	"Shield_Spikes",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_spikes_colored = WeaponData.new(
	"Shield_Spikes_Colored",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_square = WeaponData.new(
	"Shield_Square",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var shield_square_colored = WeaponData.new(
	"Shield_Square_Colored",
	["Knight", "Barbarian"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var bomb = WeaponData.new(
	"Bomb",
	["Rogue"],
	[
		WeaponData.hands_variants.Right
	],
	0.0
)
var spellbook = WeaponData.new(
	"Spellbook",
	["Mage"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var staff = WeaponData.new(
	"Staff",
	["Mage"],
	[
		WeaponData.hands_variants.Right
	],
	0.0
)
var wand = WeaponData.new(
	"Wand",
	["Mage"],
	[
		WeaponData.hands_variants.Right
	],
	0.0
)
var skeleton_axe = WeaponData.new(
	"Skeleton_Axe",
	["Warrior"],
	[
		WeaponData.hands_variants.Right
	],
	1.5
)
var skeleton_shield = WeaponData.new(
	"Skeleton_Shield",
	["Warrior"],
	[
		WeaponData.hands_variants.Left
	],
	0.0
)
var skeleton_blade = WeaponData.new(
	"Skeleton_Blade",
	["Minion"],
	[
		WeaponData.hands_variants.Right
	],
	1.0
)

var items = [
	sword_1h,
	sword_2h,
	sword_2h_colored,
	axe_1h,
	axe_2h,
	crossbow,
	dagger,
	mug,
	shield_badge,
	shield_badge_colored,
	shield_round,
	shield_round_colored,
	shield_round_barbarian,
	shield_spikes,
	shield_spikes_colored,
	shield_square,
	shield_square_colored,
	bomb,
	spellbook,
	staff,
	wand,
	skeleton_axe,
	skeleton_shield,
	skeleton_blade
]

func get_item_by_name(item_name: String) -> WeaponData:
	for item in items:
		if item.name == item_name:
			return item
	
	return null
