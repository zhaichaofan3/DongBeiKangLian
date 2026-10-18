extends SceneTree
## Run explicitly before import; original images and GLB files remain intact.

const DIRECTORY := "res://assets/user_expansion_20261015/"
const ALIASES := "res://tools/texture_aliases.json"
const IMPORTER := "res://tools/share_scene_textures.gd"

func _initialize() -> void:
	var names := DirAccess.get_files_at(DIRECTORY)
	names.sort()
	var signatures := {}
	var aliases := {}
	for name in names:
		if name.get_extension() not in ["jpg", "png"]: continue
		var path := DIRECTORY + name
		var config := ConfigFile.new()
		assert(config.load(path + ".import") == OK)
		var parameters := {}
		for key in config.get_section_keys("params"):
			parameters[key] = config.get_value("params", key)
		# Matching import parameters are required as well as matching source bytes.
		var signature := FileAccess.get_sha256(path) + JSON.stringify(parameters)
		if signatures.has(signature): aliases[path] = signatures[signature]
		else: signatures[signature] = path
	var output := FileAccess.open(ALIASES, FileAccess.WRITE)
	output.store_string(JSON.stringify(aliases, "  ") + "\n")
	output.close()
	for name in names:
		if name.get_extension() != "glb": continue
		var path := DIRECTORY + name + ".import"
		var config := ConfigFile.new()
		assert(config.load(path) == OK)
		config.set_value("params", "import_script/path", IMPORTER)
		assert(config.save(path) == OK)
	var presets := ConfigFile.new()
	assert(presets.load("res://export_presets.cfg") == OK)
	var exclusions := PackedStringArray()
	for entry in str(presets.get_value("preset.0", "exclude_filter")).split(","):
		if not entry.begins_with("assets/user_expansion_20261015/") and entry != "tools/*": exclusions.append(entry)
	exclusions.append("tools/*")
	# Only the assembled courtyard modules are used in the playable levels.
	exclusions.append("assets/user_expansion_20261015/village_complete*")
	for alias in aliases: exclusions.append(str(alias).trim_prefix("res://"))
	presets.set_value("preset.0", "exclude_filter", ",".join(exclusions))
	assert(presets.save("res://export_presets.cfg") == OK)
	print("DELIVERY ASSET CONFIG: PASS | shared textures=", aliases.size())
	quit()
