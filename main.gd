extends Node2D

@onready var label = $CanvasLayer/Control/Label

var previous_s_key_pressed: bool
var current_s_key_pressed: bool
var data_path = "res://saved_data.json"

func get_random_weapon() -> Weapon:
	var weapon1 = Weapon.new()
	weapon1.description = "an ordinary weapon"
	weapon1.damage = 2
	weapon1.types = ["neutral"] as Array[String]
	weapon1.slot_size = Vector2(1, 1)
	
	var weapon2 = Weapon.new()
	weapon2.description = "a crazy weapon"
	weapon2.damage = 4
	weapon2.types = ["fire", "water"] as Array[String]
	weapon2.slot_size = Vector2(2, 1)
	
	var weapon3 = Weapon.new()
	weapon3.description = "a very weak weapon"
	weapon3.damage = 0.1
	weapon3.types = ["neutral"] as Array[String]
	weapon3.slot_size = Vector2(1, 1)
	
	var weapon4 = Weapon.new()
	weapon4.description = "a dirty weapon"
	weapon4.damage = 3
	weapon4.types = ["earth", "water"] as Array[String]
	weapon4.slot_size = Vector2(1, 2)
	
	var weapon5 = Weapon.new()
	weapon5.description = "a wet weapon"
	weapon5.damage = 1
	weapon5.types = ["water"] as Array[String]
	weapon5.slot_size = Vector2(1, 1)
	
	randomize()
	var weapons = [weapon1, weapon2, weapon3, weapon4, weapon5]
	return weapons[randi() % weapons.size()]

func get_random_weapon_inventory() -> WeaponInventory:
	var inventory1 = WeaponInventory.new()
	inventory1.description = "an empty inventory"
	inventory1.is_active = true
	inventory1.maximum_slots = 5
	
	var inventory2 = WeaponInventory.new()
	inventory2.description = "a random inventory"
	randomize()
	inventory2.is_active = randi() % 2 == 0
	randomize()
	var weapons_count = randi() % 6 + 1
	randomize()
	inventory2.maximum_slots = weapons_count + (randi() % 3)
	
	for n in range(1, weapons_count + 1):
		inventory2.weapons.append(get_random_weapon())
	
	var inventory3 = WeaponInventory.new()
	inventory3.description = "a blocked full inventory"
	inventory3.is_active = false
	inventory3.maximum_slots = 1
	inventory3.weapons.append(get_random_weapon())
	
	randomize()
	var inventories = [inventory1, inventory2, inventory3]
	return inventories[randi() % inventories.size()]

func update_label_text():
	var weapon_inventory = Serializable.load_from_json(data_path) as WeaponInventory
	
	if weapon_inventory != null:
		var text = weapon_inventory.description.to_upper() + "\n"
		if not weapon_inventory.is_active:
			text += "not "
		text += "active with %s slots capacity" % weapon_inventory.maximum_slots
		
		if weapon_inventory.weapons.size() > 0:
			text += "\n\nWEAPONS\n"
			for n in weapon_inventory.weapons.size():
				var weapon = weapon_inventory.weapons[n]
				var format = {
					"description": weapon.description.to_upper(),
					"damage": weapon.damage,
					"types": weapon.types,
					"size": weapon.slot_size
				}
				text += "- " + ("{description}: {damage} damage of types {types} with size ")\
					.format(format) + ("(%d width / %d height)" % [format.size.x, format.size.y]) + "\n"
		else:
			text += " (empty)"
		
		text += "\n\n** press backspace to delete data **"
		label.text = text

func save_random_data():
	var inventory = get_random_weapon_inventory()
	inventory.save_json(data_path)
	update_label_text()

func _ready():
	update_label_text()

func _process(_delta):
	previous_s_key_pressed = current_s_key_pressed
	current_s_key_pressed = Input.is_key_pressed(KEY_S)
	var s_key_just_pressed = not previous_s_key_pressed and current_s_key_pressed
	
	if Input.is_key_pressed(KEY_CTRL) and s_key_just_pressed:
		save_random_data()
	
	if FileAccess.file_exists(data_path) and Input.is_key_pressed(KEY_BACKSPACE):
		DirAccess.remove_absolute(data_path)
		label.text = "press ctrl + s to save a random data"
