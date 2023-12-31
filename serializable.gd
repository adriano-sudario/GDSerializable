class_name Serializable

func get_dictionary():
	var dictionary:Dictionary = {}
	var instance = inst_to_dict(self)
	dictionary["@subpath"] = instance["@subpath"]
	dictionary["@path"] = instance["@path"]
	var variables:Array = []
	var properties:Array = self.get_property_list()
	
	for property in properties:
		if property.usage != PROPERTY_USAGE_SCRIPT_VARIABLE:
			continue
		
		variables.append(property)
	
	for variable in variables:
		if variable.type == TYPE_ARRAY:
			dictionary[variable.name] = []
			for i in self[variable.name].size():
				if typeof(self[variable.name][i]) == TYPE_OBJECT:
					dictionary[variable.name].append(self[variable.name][i].get_dictionary())
				else:
					dictionary[variable.name].append(self[variable.name][i])
		elif variable.type == TYPE_OBJECT:
			dictionary[variable.name] = self[variable.name].get_dictionary()
		else:
			dictionary[variable.name] = self[variable.name]
	
	return dictionary

func save_json(path: String, json_indentation := "\t", sort_json_keys := false):
	var index_file = FileAccess.open(path, FileAccess.WRITE)
	var json_string = JSON.stringify(get_dictionary(), json_indentation, sort_json_keys, true)
	index_file.store_string(json_string)
	index_file.close()

static func load_from_json(path: String) -> Serializable:
	if not FileAccess.file_exists(path):
		return null
	
	var json_content = FileAccess.get_file_as_string(path)
	var dictionary = JSON.parse_string(json_content)
	return dict_to_inst(dictionary)

func save_encrypted(path: String, password:String):
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
	index_file.close()
	var dictionary = JSON.parse_string(json_content)
	return dict_to_inst(dictionary)
