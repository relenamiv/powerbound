extends Node

var players = {
	"Green": {
		"energy": 100,
		"moveset": ["Static Zap", "Bioelectric Boost"]
	},
	"Blue": {
		"energy": 100,
		"moveset": ["Static Zap", "Voltage Slam"],
		"passive": "Efficient Current"
	},
	"Red": {
		"energy": 100,
		"moveset": ["Static Zap", "Conductive Strike"]
	},
	"Yellow": {
		"energy": 100,
		"moveset": ["Bioelectric Boost", "Power Grid"],
		"passive": "Live Wire"
	}
}

var player_movelist = {
	"Bioelectric Boost": {
		"type": "status", 
		"description": "Restores health to another player using electrical energy from the earth", 
		"cost": 10,
		"power": 10,
		"target_type": "player"
	},
	"Power Grid": {
		"type": "status", 
		"description": "Heals all allies slightly", 
		"cost": 10,
		"power": 5,
		"target_type": "players"
	},
	"Static Zap": {
		"type": "damage", 
		"description": "A simple electric attack", 
		"cost": 10,
		"power": 10,
		"target_type": "enemy"
	},
	"Voltage Slam": {
		"type": "damage", 
		"description": "A powerful, electrified melee attack", 
		"cost": 20,
		"power": 20,
		"target_type": "enemy"
	},
	"Conductive Strike": {
		"type": "damage", 
		"description": "Deals moderate damage, but doubles in power if the player is in the back row.", 
		"cost": 25,
		"power": 15,
		"target_type": "enemy",
		"status_message": "The power was doubled from the back row!"
	}
}

var player_passives = {
	"Live Wire": {
		"description": "Gains a small amount of HP at the end of each turn.",
		"func": "live_wire()"
	},
	"Efficient Current": {
		"description": "Skill costs are reduced by 10%.",
		"func": "efficient_current()"
	},
}
