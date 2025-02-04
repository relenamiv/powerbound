extends Node

var enemy_moveset = {
	"Attack": {
		"Basic Punch": {
			"cost": 5,
			"power": 15,
			"target_type": "player",
		},
		"AOE Slam": {
			"cost": 10,
			"power": 10,
			"target_type": "players",
		}
	},
	"Heal": {
		"Self Healing": {
			"cost": 10,
			"power": 15,
			"target_type": "enemy"
		},
		"Life Steal": {
			"cost": 10,
			"power": 20,
			"target_type": "player"
		}
	},
	"Defend": {
		"Guard": {
			"description": "Reduces incoming damage by 50% for the next round.",
			"cost": 10,
			"target_type": "enemy"
		}
	}
}

var units = {
	"Enemy": {
		"energy": 400,
		"moveset": ["Attack", "AOE Attack", "Heal", "Lifesteal"]
	}
}
