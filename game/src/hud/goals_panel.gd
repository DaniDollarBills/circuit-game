class_name GoalsPanel
extends PanelContainer
## The level's goals: a ✓ or ○ row for each, then the first failing goal's
## message. In portrait it folds into a pill that opens on a tap.

var game: Game
var compact := false:
	set(value):
		compact = value
		_open = false
		_apply_compact()

var _title: Button
var _rows: VBoxContainer
var _message: RichTextLabel
var _open := false
var _signature := ""


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	add_child(col)
	_title = Button.new()
	_title.flat = true
	_title.theme_type_variation = "FlatButton"
	_title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# A long lesson title in Large text ends in "…" rather than widening the
	# column past a small phone.
	_title.clip_text = true
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.pressed.connect(func() -> void:
		_open = not _open
		_apply_compact())
	col.add_child(_title)
	_rows = VBoxContainer.new()
	col.add_child(_rows)
	_message = HudText.label(game, 15)
	col.add_child(_message)


func refresh(level: LevelDef, session: LevelSession, circuit: Circuit) -> void:
	var results := session.goal_results
	var done := 0
	var first_fail := ""
	for i in level.goals.size():
		var ok := i < results.size() and bool(results[i]["pass"])
		done += int(ok)
		if not ok and first_fail == "" and i < results.size():
			first_fail = str(results[i]["message"])
	_title.text = ("%s  ·  " % level.title if compact else "") + "Goals  %d/%d" % [done, level.goals.size()]
	var sig := "%s|%s" % [results, first_fail]
	if sig != _signature:
		_signature = sig
		for c in _rows.get_children():
			_rows.remove_child(c)
			c.queue_free()
		for i in level.goals.size():
			var ok := i < results.size() and bool(results[i]["pass"])
			var row := HBoxContainer.new()
			var mark := Label.new()
			mark.text = "✓" if ok else "○"
			mark.custom_minimum_size = Vector2(22, 0)
			mark.theme_type_variation = "" if ok else "SoftLabel"
			row.add_child(mark)
			row.add_child(HudText.make(game, label_for(level.goals[i], circuit), 15))
			_rows.add_child(row)
		HudText.put(_message, first_fail, game)
	_message.visible = first_fail != ""
	_apply_compact()


func _apply_compact() -> void:
	if _rows == null:
		return
	_rows.visible = not compact or _open


## A short name for a goal, like "Light the LED (20 mA max)".
static func label_for(goal: Dictionary, c: Circuit) -> String:
	if goal.has("label"):
		return str(goal["label"])
	match str(goal.get("kind", "")):
		"led_lit":
			var lo: Variant = goal.get("min_ma")
			var hi: Variant = goal.get("max_ma")
			var name := part_name(c, str(goal["part"]))
			if lo != null and hi != null:
				return "Light %s at %s–%s mA" % [name, _n(lo), _n(hi)]
			if hi != null:
				return "Light %s (%s mA max)" % [name, _n(hi)]
			if lo != null:
				return "Light %s with at least %s mA" % [name, _n(lo)]
			return "Light %s" % name
		"led_dark":
			return "Keep %s off" % part_name(c, str(goal["part"]))
		"no_damage":
			return "Nothing burns out"
		"no_short":
			return "No short circuits"
		"meter_reads":
			var p := c.find_part(str(goal["part"]))
			var ammeter := p != null and p.kind == "ammeter"
			var t := float(goal["target"])
			var tol := float(goal.get("tolerance", 0.0))
			if ammeter:
				return "The ammeter reads %.1f mA (±%.1f)" % [t * 1000.0, tol * 1000.0]
			return "The voltmeter reads %.2f V (±%.2f)" % [t, tol]
		"uses":
			var title := noun(Catalog.title(str(goal["part_kind"])))
			if goal.has("max"):
				return "Use at most %d %s" % [int(goal["max"]), _count_noun(int(goal["max"]), title)]
			var n := int(goal.get("min", 1))
			return "Use a %s" % title if n <= 1 else "Use %d %s" % [n, _count_noun(n, title)]
		"zoom_reached":
			return "Zoom in until you see %s" % ("copper atoms" if str(goal["layer"]) == "wire.copper" else "inside the wire")
		"connected":
			return "Connect %s and %s" % [_pin_name(c, str(goal["a"])), _pin_name(c, str(goal["b"]))]
		"all":
			var parts := PackedStringArray()
			for g in goal["goals"]:
				parts.append(label_for(g, c))
			return " and ".join(parts)
		"resistor_watts":
			return "Make %s–%s W of heat in a resistor" % [_n(goal["min"]), _n(goal["max"])]
	return "Done"


## "the LED" when there is one LED, otherwise "LED L1".
static func part_name(c: Circuit, id: String) -> String:
	var p := c.find_part(id)
	if p == null:
		return id
	var same := 0
	for q in c.parts:
		same += int(q.kind == p.kind)
	var title := Catalog.title(p.kind)
	return "the " + noun(title) if same == 1 else "%s %s" % [title, p.id]


## A title as a word inside a sentence: "Resistor" → "resistor", but "LED"
## and "Battery pack (4 × AA)" keep their capitals where they matter.
static func noun(title: String) -> String:
	if title.length() > 1 and title[1] == title[1].to_lower():
		return title[0].to_lower() + title.substr(1)
	return title


static func _pin_name(c: Circuit, spec: String) -> String:
	return part_name(c, spec.get_slice(":", 0))


## "switch" → "switches" for any count but one.
static func _count_noun(n: int, word: String) -> String:
	if n == 1:
		return word
	for end in ["s", "sh", "ch", "x", "z"]:
		if word.ends_with(end):
			return word + "es"
	return word + "s"


static func _n(v: Variant) -> String:
	return ("%.2f" % float(v)).rstrip("0").rstrip(".")
