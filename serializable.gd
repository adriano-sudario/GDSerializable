class_name Serializable

static func get_obj_properties(obj) -> Array:
	var properties:Array = []
	
	if typeof(obj) == TYPE_DICTIONARY:
		obj = dict_to_inst(obj)
	
	var property_list:Array = obj.get_property_list()
	
	for property in property_list:
		if property.usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		properties.append(property)
	
	return properties

func get_properties() -> Array:
	var properties:Array = []
	var property_list:Array = self.get_property_list()
	
	for property in property_list:
		var is_enum = property.type and property.class_name != ""
		if property.usage != PROPERTY_USAGE_SCRIPT_VARIABLE and not is_enum:
			continue
		
		properties.append(property)
	
	return properties

func get_fixed_save_value(value):
	if Serializable.is_native_object(value):
		value = var_to_str(value)
	
	return value

static func is_native_object(value) -> bool:
	var value_type = typeof(value)
	
	return not (value_type == TYPE_NIL or value_type == TYPE_BOOL \
		or value_type == TYPE_INT or value_type == TYPE_FLOAT \
		or value_type == TYPE_STRING)

static func fix_values_after_load(loaded_obj) -> void:
	var loaded_obj_type = typeof(loaded_obj)
	
	if loaded_obj_type != TYPE_DICTIONARY and loaded_obj_type != TYPE_OBJECT:
		return
	
	var variables:Array = Serializable.get_obj_properties(loaded_obj)
	
	for variable in variables:
		if variable.type == TYPE_ARRAY:
			for i in loaded_obj[variable.name].size():
				var value = loaded_obj[variable.name][i]
				
				if typeof(value) == TYPE_STRING and variable.hint_string.to_lower() != "string":
					loaded_obj[variable.name][i] = str_to_var(value)
				else:
					Serializable.fix_values_after_load(value)
		else:
			if variable.type != TYPE_STRING and typeof(loaded_obj[variable.name]) == TYPE_STRING:
				loaded_obj[variable.name] = str_to_var(loaded_obj[variable.name])

func get_dictionary() -> Dictionary:
	var dictionary:Dictionary = {}
	var instance = inst_to_dict(self)
	dictionary["@subpath"] = instance["@subpath"]
	dictionary["@path"] = instance["@path"]
	var variables:Array = get_properties()
	
	for variable in variables:
		var value = self[variable.name]
		
		if variable.type == TYPE_ARRAY:
			dictionary[variable.name] = []
			
			for i in self[variable.name].size():
				var array_value = self[variable.name][i]
				
				if typeof(array_value) == TYPE_OBJECT and array_value.has_method("get_dictionary"):
					dictionary[variable.name].append(array_value.get_dictionary())
				else:
					dictionary[variable.name].append(get_fixed_save_value(array_value))
		elif variable.type == TYPE_OBJECT and value.has_method("get_dictionary"):
			dictionary[variable.name] = value.get_dictionary()
		else:
			dictionary[variable.name] = get_fixed_save_value(value)
	
	return dictionary

func save_json(path: String, json_indentation := "\t", sort_json_keys := false) -> void:
	var index_file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(get_dictionary(), json_indentation, sort_json_keys, true)
	index_file.store_string(json_string)
	index_file.close()

static func load_from_json(path: String) -> Serializable:
	if not FileAccess.file_exists(path):
		return null
	
	var json_content = FileAccess.get_file_as_string(path)
	
	if json_content == "":
		return null
	
	var dictionary = JSON.parse_string(json_content)
	var loaded_dictionary = dict_to_inst(dictionary)
	Serializable.fix_values_after_load(loaded_dictionary)
	return loaded_dictionary

func save_encrypted(path: String, password:String) -> void:
	var index_file = FileAccess.open_encrypted_with_pass(path, FileAccess.WRITE, password)
	
	if index_file == null:
		push_error("couldn't save encrypted file")
		return
	
	var json_string = JSON.stringify(get_dictionary(), "", false, true)
	index_file.store_string(json_string)
	index_file.close()

static func load_from_encrypted(path: String, password:String) -> Serializable:
	var index_file = FileAccess.open_encrypted_with_pass(path, FileAccess.READ, password)
	
	if index_file == null:
		return null
	
	var json_content = index_file.get_as_text()
	
	if json_content == "":
		return null
	
	index_file.close()
	var dictionary = JSON.parse_string(json_content)
	var loaded_dictionary = dict_to_inst(dictionary)
	Serializable.fix_values_after_load(loaded_dictionary)
	return loaded_dictionary
