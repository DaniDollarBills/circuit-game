class_name FormulaCard
extends PanelContainer
## The calculator: the LED resistor formula, Ohm's law and power, worked step
## by step. The boxes start from the level's own numbers. When your simulated
## circuit gives a slightly different answer, both are shown, with the reason.

const TABS := {"led_resistor": "LED resistor", "ohms_law": "Ohm's law", "power": "Power"}
const FIELDS := {
	"led_resistor": [["supply", "Supply voltage (V)"], ["led_v", "LED voltage (V)"], ["led_a", "LED current (A)"]],
	"ohms_law": [["v", "Voltage, V (volts)"], ["i", "Current, I (amps)"], ["r", "Resistance, R (ohms)"]],
	"power": [["v", "Voltage, V (volts)"], ["r", "Resistance, R (ohms)"]],
}
## Filled with the simulated value and the voltage the resistor really gets.
const REAL_LESS := "In your circuit it's %s: a little less, because the battery's 1 Ω internal resistance uses up part of its voltage, leaving %s across the resistor."
const REAL_MORE := "In your circuit it's %s: a little more, because the resistor really has %s across it, more than the %s you typed."

var game: Game
var tab := "led_resistor"

var _tab_buttons := {}
var _fields := {}
var _form: GridContainer
var _note: Label
var _steps: VBoxContainer


func _ready() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	# Narrower on a phone, and scrolls when it is still too tall.
	CardFit.wrap(self, col)
	var top := HBoxContainer.new()
	col.add_child(top)
	var title := Label.new()
	title.text = "Calculator"
	title.theme_type_variation = "HeadingLabel"
	HudText.font_size(title, 22, game)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var close_b := IconButton.make("close", "Close")
	close_b.custom_minimum_size = Vector2(IconButton.MIN_TOUCH, IconButton.MIN_TOUCH)
	close_b.pressed.connect(func() -> void: visible = false)
	top.add_child(close_b)
	var tabs := HFlowContainer.new()
	tabs.add_theme_constant_override("h_separation", 6)
	col.add_child(tabs)
	for id in TABS:
		var b := Button.new()
		b.text = TABS[id]
		b.toggle_mode = true
		b.pressed.connect(func() -> void: _show_tab(id))
		tabs.add_child(b)
		_tab_buttons[id] = b
	_form = GridContainer.new()
	_form.columns = 2
	_form.add_theme_constant_override("h_separation", 10)
	col.add_child(_form)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	HudText.font_size(_note, 14, game)
	_note.theme_type_variation = "SoftLabel"
	col.add_child(_note)
	var go := Button.new()
	go.text = "Calculate"
	go.pressed.connect(calculate)
	col.add_child(go)
	_steps = VBoxContainer.new()
	col.add_child(_steps)
	visible = false


## Opens on `name`, or on the level's own calculator.
func open(name := "") -> void:
	var level := game.state.level
	if name == "" and level != null and TABS.has(level.formula):
		name = level.formula
	_show_tab(name if TABS.has(name) else "led_resistor")
	visible = true
	HudText.introduce_in(game, self)


func field(name: String) -> LineEdit:
	return _fields.get(name)


func calculate() -> void:
	var out := {}
	match tab:
		"led_resistor":
			out = Formulas.led_resistor(_num("supply"), _num("led_v"), _num("led_a"))
		"ohms_law":
			out = Formulas.ohms_law(_num("v"), _num("i"), _num("r"))
			if (out["steps"] as PackedStringArray).is_empty():
				out["steps"] = PackedStringArray(["Leave exactly one box empty: the one to work out."])
		"power":
			out = Formulas.power_from_r(_num("v"), _num("r"))
	var steps: PackedStringArray = out["steps"]
	var real := _real_note(out)
	if real != "":
		steps.append(real)
	for c in _steps.get_children():
		_steps.remove_child(c)
		c.queue_free()
	for s in steps:
		_steps.add_child(HudText.make(game, s, 16))
	game.set_ui_flag("formula:" + tab)


func steps_text() -> String:
	var lines := PackedStringArray()
	for c in _steps.get_children():
		if c is RichTextLabel and not c.is_queued_for_deletion():
			lines.append((c as RichTextLabel).get_parsed_text())
	return "\n".join(lines)


func _show_tab(id: String) -> void:
	tab = id
	for t in _tab_buttons:
		_tab_buttons[t].button_pressed = t == id
	for c in _form.get_children():
		_form.remove_child(c)
		c.queue_free()
	_fields.clear()
	for f in FIELDS[id]:
		var l := Label.new()
		l.text = f[1]
		_form.add_child(l)
		var e := LineEdit.new()
		e.custom_minimum_size = Vector2(96, 0)
		e.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER_DECIMAL
		e.text_submitted.connect(func(_t: String) -> void: calculate())
		_form.add_child(e)
		_fields[f[0]] = e
	_note.text = "Leave empty the one you want to work out." if id == "ohms_law" else ""
	_note.visible = _note.text != ""
	for c in _steps.get_children():
		_steps.remove_child(c)
		c.queue_free()
	_prefill()
	if is_visible_in_tree():
		HudText.introduce_in(game, self)


## Starts from the level's numbers: the battery's voltage, the LED's datasheet
## voltage at 20 mA, a meter target or the resistor on the board.
func _prefill() -> void:
	var c := game.state.history.present if game.state.history != null else Circuit.new()
	var supply := 5.0
	var led_v := "2.0"
	var ohms := ""
	for p in c.parts:
		match p.kind:
			"battery":
				supply = float(p.props.get("volts", 5.0))
			"led":
				led_v = str(Catalog.LED_DATA.get(str(p.props.get("color", "red")), Catalog.LED_DATA["red"])["vf"])
			"resistor":
				if ohms == "":
					ohms = "%d" % roundi(float(p.props.get("ohms", 220.0)))
	var target_amps := ""
	if game.state.level != null:
		for g in game.state.level.goals:
			if str(g.get("kind", "")) == "meter_reads":
				var m := c.find_part(str(g["part"]))
				if m != null and m.kind == "ammeter":
					target_amps = "%.3f" % float(g["target"])
	match tab:
		"led_resistor":
			_fill("supply", "%.1f" % supply)
			_fill("led_v", led_v)
			_fill("led_a", "0.020")
		"ohms_law":
			_fill("v", "%.1f" % supply)
			_fill("i", target_amps)
			_fill("r", "" if target_amps != "" else ohms)
		"power":
			_fill("v", "%.1f" % supply)
			_fill("r", ohms)


func _fill(name: String, value: String) -> void:
	if _fields.has(name):
		(_fields[name] as LineEdit).text = value


func _num(name: String) -> float:
	var t := (_fields[name] as LineEdit).text.strip_edges().replace(",", ".") if _fields.has(name) else ""
	return float(t) if t.is_valid_float() else NAN


## The simulated value for the same resistor, when it differs from the ideal
## answer by between 1% and 10%, with why: the voltage the resistor really
## gets. Otherwise "".
func _real_note(out: Dictionary) -> String:
	var ideal := float(out.get("value", NAN))
	if is_nan(ideal) or ideal == 0.0:
		return ""
	var unit := str(out.get("unit", ""))
	if not (tab == "power" or (tab == "ohms_law" and unit == "A")):
		return ""
	var r := _num("r")
	var o := game.state.outcome
	if o == null or is_nan(r):
		return ""
	for p in o.circuit.parts:
		if p.kind != "resistor" or absf(float(p.props.get("ohms", 0.0)) - r) > r * 0.005 or bool(p.props.get("burnt", false)):
			continue
		var amps := absf(float(o.result.part_amps.get(p.id, 0.0)))
		var real := absf(float(o.result.part_watts.get(p.id, 0.0))) if tab == "power" else amps
		var diff := absf(real - ideal) / absf(ideal)
		if diff <= 0.01 or diff >= 0.1:
			continue
		var shown := "%.2f W" % real if tab == "power" else "%.3f A (%.1f mA)" % [real, real * 1000.0]
		var across := "%.2f V" % (amps * r)
		if real < ideal:
			return REAL_LESS % [shown, across]
		return REAL_MORE % [shown, across, "%s V" % String.num(_num("v"), 2)]
	return ""
