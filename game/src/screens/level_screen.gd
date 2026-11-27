class_name LevelScreen
extends Control
## One level: the zoomable building area (a ZoomStage holding the EditorLayer)
## with the HUD floating over it. The editor's requests go to the Game; every
## change in the Game is drawn again from its state, and the events it queues
## (burns, passes, stars, badges, new words) become toasts, Pip's help and
## New word cards.

const IDLE_OFFER_S := 30.0
const IDLE_OFFER := "Stuck? Tap the lightbulb and I'll help."
const FORMULA_OFFER := "This step needs a calculation. The calculator can work it out with you, step by step."
## Goal messages that mean something went wrong (Pip steps in on Heavy).
const MISTAKES: PackedStringArray = ["Pop!", "Short circuit!", "The LED is backwards", "Careful:", "Something burned out"]
const MARGIN := 12.0
const BAR_H := 52.0
const COLUMN_W := 300.0
const TRAY_W := 128.0
const STRIP_H := 124.0
const MAX_CARDS := 2

var game: Game
var stage: ZoomStage
var editor: EditorLayer
## Every HUD element lives under this node; it lets clicks through to the board.
var hud: Control

var top_bar: TopBar
var tray: PartsTray
var goals: GoalsPanel
var checklist: StepsChecklist
var test_sheet: TestSheet
var test_button: IconButton
## The goals, steps and test results; scrolls when they don't fit.
var column_scroll: ScrollContainer
var hint_button: HintButton
var guide: GuideBubble
var deck: LessonDeck
var lesson_button: IconButton
var try_panel: TryPanel
var recap: RecapCard
## Lesson 0: the tour's spotlight, the moving hand, and Skip.
var spotlight: Spotlight
var hand: GestureHand
var skip_tutorial_button: Button
var _hand_key := ""
## Reading a lesson again, or meeting a part again, from the Notebook.
var textbook: Textbook
## The Meet the part card on screen, and the parts waiting to be met.
var meet_card: MeetPartCard
var _meet_queue := PackedStringArray()
var toasts: Toasts
var menu: ContextMenu
var value_popover: ValuePopover
var explain: ExplainPopover
var datasheet: DatasheetCard
var formula: FormulaCard
var glossary_popup: GlossaryPopup
var settings_sheet: SettingsSheet
var notebook: NotebookSheet
var scale_bar: ScaleBar
var back_to_building: Button
var closeup: WireCloseupLayer
var copper: CopperLayer
## The caption shown inside the copper.
var zoom_caption: RichTextLabel

var _column: VBoxContainer
var _cards_root: Control
var _refresh_queued := false
var _portrait := false
var _idle := 0.0
var _idle_offered := false
var _ticked := -1
var _last_mistake := ""
var _formula_offered := false
var _hint_tier_shown := 0
var _ghosts := {}
## The phase at the last refresh, to notice coming back to a passed bench.
var _last_phase := ""
## The step row last scrolled into view.
var _row_in_view: Control
var _highlights: Array = []
var _board_key := ""
var _view_style := ""
var _night := false
## What the last refresh saw, so sounds play only for what's new.
var _heard := false
var _parts_before := {}
var _wires_before := {}
var _lit_before := {}
var _report_before: Dictionary = {}
var _large := false
## The column's room in portrait, set at layout: the board starts below it.
var _column_room := 0.0
var _cards: Array[NewWordCard] = []
var _word_queue := PackedStringArray()
var _carded := PackedStringArray()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = ZoomStage.new()
	stage.name = "Stage"
	add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	editor = load("res://src/editor/editor_layer.tscn").instantiate()
	stage.add_layer(editor)
	# Inside the wire: a close-up of the wire, then (a jump of about ×13,000)
	# its copper atoms.
	closeup = WireCloseupLayer.new()
	copper = CopperLayer.new()
	closeup.copper = copper
	editor.closeup = closeup
	stage.add_layer(closeup)
	stage.add_layer(copper)
	stage.add_link(ZoomLink.make("wire.closeup", "wire.copper", Vector2.ZERO, 8.0, 60.0))
	_build_hud()
	_connect()
	resized.connect(_layout)
	editor.resized.connect(_on_board_resized)
	_layout()
	_refresh()
	HudText.introduce_in(game, hud)
	_initial_frame.call_deferred()


func _process(delta: float) -> void:
	idle_tick(delta)
	_place_floating()


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or not (k.ctrl_pressed or k.meta_pressed):
		return
	if (k.keycode == KEY_Z and k.shift_pressed) or k.keycode == KEY_Y:
		game.redo()
		accept_event()
	elif k.keycode == KEY_Z:
		game.undo()
		accept_event()


## For development and screenshots: opens "calculator", "notebook",
## "settings" or "datasheet:<part id>".
func dev_show(what: String) -> void:
	if what.begins_with("datasheet:"):
		_open_datasheet(what.substr("datasheet:".length()))
	elif what == "recap":
		# For screenshots: the bench's parts count as met, so no card covers it.
		for p in game.state.level.solution.parts:
			game.state.progress.mark_part_seen(PartIntros.key_for(p), game.state.now())
		if meet_card != null:
			meet_card.visible = false
		_meet_queue.clear()
		game.commit(game.state.level.solution.copy())
	elif what == "try":
		game.reopen_lesson()
		game.skip_learn()
	elif what.begins_with("meet:"):
		_open_meet(what.substr("meet:".length()))
	elif what.begins_with("deck:"):
		game.reopen_lesson()
		for i in int(what.substr("deck:".length())):
			game.next_card()
	elif what == "calculator":
		_open_card(formula)
	elif what == "notebook":
		_open_card(notebook)
	elif what == "settings":
		_open_card(settings_sheet)
	elif what in ["closeup", "jump", "copper"] and not game.state.history.present.wires.is_empty():
		# After the first framing; then enter the first wire, as zooming in over it would.
		for i in 3:
			await get_tree().process_frame
		var w := game.state.history.present.wires[0]
		var path := CircuitGeometry.wire_path(game.state.history.present, w)
		editor.dynamic_child((path[0] + path[1]) / 2.0)
		var cam: Array = {"closeup": ["wire.closeup", 200.0], "jump": ["wire.closeup", 14.0], "copper": ["wire.copper", 40.0]}[what]
		stage.set_camera(ZoomCamera.make(cam[0], Vector2.ZERO, cam[1]))


## Toasts from the Game land here while a level is open.
func show_toast(text: String) -> void:
	toasts.show_text(text)


## Every term that has a New word card, shown or waiting its turn.
func shown_word_terms() -> PackedStringArray:
	return _carded


func visible_word_cards() -> Array[NewWordCard]:
	return _cards


## Counts toward Pip's "Stuck?" offer; any newly ticked step starts it over.
func idle_tick(seconds: float) -> void:
	var s := game.state
	if s.level == null or s.session.phase != "build" or recap.visible:
		return
	var ticked := StepsChecklist.ticked_count(s.session)
	if ticked != _ticked:
		_ticked = ticked
		_idle = 0.0
		_idle_offered = false
	_idle += seconds
	if _idle >= IDLE_OFFER_S and not _idle_offered and _help() == "heavy" and not s.level.hints.is_empty():
		_idle_offered = true
		guide.show_line(IDLE_OFFER, "curious", "help")


func _help() -> String:
	return str(game.state.progress.settings.get("help_level", "heavy"))


func _queue_refresh() -> void:
	if not _refresh_queued:
		_refresh_queued = true
		_refresh.call_deferred()


## Draws everything again from the Game's state. The guide goes first so the
## lesson's words get the first New word cards.
func _refresh() -> void:
	_refresh_queued = false
	var s := game.state
	if s.level == null or not is_inside_tree():
		return
	var st := s.progress.settings
	var q := str(st.get("quality", "auto"))
	if closeup.quality != q:
		closeup.quality = q
		copper.quality = q
	_handle_events(s.take_events())
	_sounds_for(s)
	if recap.visible and s.session.phase != "passed":
		# Started over (or reading the lesson again): the recap described a
		# board that's gone.
		recap.visible = false
	if s.session.phase == "passed" and _last_phase in ["learn", "try"] and not recap.visible:
		# Back from reading the lesson again to a bench that still passes:
		# the recap again, with the way on.
		_start_outro()
	_last_phase = s.session.phase
	if bool(st.get("night", false)) != _night:
		_night = not _night
		HudText.refresh_all(get_tree(), game)
	if bool(st.get("large_text", false)) != _large:
		_large = not _large
		HudText.refresh_sizes(get_tree(), game)
	_update_guide()
	_check_new_parts()
	_update_hints()
	var shown := s.shown()
	if explain.visible:
		var ep := shown.circuit.find_part(explain.part_id)
		if ep == null:
			explain.visible = false
		else:
			explain.refresh(ep, shown.result)
	menu.sync()
	var key := "%d|%s|%s|%s" % [shown.get_instance_id(), st, _ghosts, _highlights]
	if key != _board_key:
		_board_key = key
		editor.set_state(shown.circuit, shown.result, st, _ghosts, _highlights)
	editor.set_tray(s.current_tray(), s.tray_used())
	if str(st.get("view_style", "")) != _view_style:
		var first := _view_style == ""
		_view_style = str(st.get("view_style", ""))
		if not first:
			_frame_circuit.call_deferred()
	top_bar.refresh(s)
	tray.refresh(s.current_tray(), s.tray_used())
	# The lesson has the stage to itself: the build's tray and column wait.
	# (Lesson 0's tour points at them, so a tutorial keeps them.)
	var learning := s.session.phase == "learn" and s.level.kind != "tutorial"
	tray.visible = not s.current_tray().is_empty() and not learning
	column_scroll.visible = not learning
	skip_tutorial_button.visible = s.level.kind == "tutorial" and s.session.phase != "passed"
	# Trying: the try panel has the column; the build's goals, steps and Test wait.
	var trying := s.session.phase == "try"
	try_panel.visible = trying
	if trying:
		try_panel.refresh(s)
	goals.visible = not trying
	goals.refresh(s.level, s.session, s.outcome.circuit)
	# A tutorial is its steps: they (and the lightbulb its last step uses) show
	# at every help level.
	var tutorial := s.level.kind == "tutorial"
	checklist.visible = (_help() == "heavy" or tutorial) and not s.level.steps.is_empty() and not trying
	if checklist.visible:
		checklist.refresh(s.level, s.session)
		# On a short screen the column scrolls: keep the current step in view.
		var row := checklist.current_row()
		if row != null and row != _row_in_view:
			_row_in_view = row
			column_scroll.ensure_control_visible.call_deferred(row)
	test_button.visible = not s.level.tests.is_empty() and s.session.phase in ["build", "passed"]
	test_sheet.visible = test_button.visible and not (s.session.test_report.get("cases", []) as Array).is_empty()
	if test_sheet.visible:
		test_sheet.refresh(s.session)
	hint_button.visible = (_help() != "off" or tutorial) and not s.level.hints.is_empty() \
			and (s.session.phase in ["build", "passed"] or tutorial)
	lesson_button.visible = s.session.phase in ["build", "passed"] and (s.level.deck_size() > 0 or s.level.has_try())
	back_to_building.visible = s.zoom_layer != "editor"
	zoom_caption.visible = s.zoom_layer == "wire.copper"
	if zoom_caption.visible and zoom_caption.text == "":
		# Light links: the caption sits on the dark copper scene.
		var r := GlossaryText.render(CopperLayer.CAPTION, s.progress.seen_terms, true, true)
		zoom_caption.text = "[center]%s[/center]" % r["bbcode"]
		if not (r["new_terms"] as PackedStringArray).is_empty():
			game.mark_terms_seen(r["new_terms"])
			_queue_refresh()
	if not _any_burnt():
		toasts.drop("Pop! ")
	_check_mistakes()
	_check_formula_offer()
	if settings_sheet.visible:
		settings_sheet.sync()


func _handle_events(events: Array[Dictionary]) -> void:
	var s := game.state
	for e in events:
		match str(e["type"]):
			"burnt":
				_sound("pop")
				var p := s.outcome.circuit.find_part(str(e["part"]))
				var title := Catalog.title(p.kind) if p != null else str(e["part"])
				toasts.show_text("Pop! %s burned out." % title)
				if _help() == "heavy" and p != null and not recap.visible:
					_burn_help(p)
			"passed":
				_sound("success")
				_start_outro()
			"star":
				_sound("badge")
				toasts.show_text("Star earned: %s" % s.level.star.get("text", ""), true)
			"badge":
				_sound("badge")
				for a in Achievements.ALL:
					if a["id"] == e["id"]:
						toasts.show_text("Badge earned: %s" % a["name"], true)
			"new_word":
				_queue_word(str(e["term"]))


## Pip explains a burn: the goal's own message when it says what to do,
## otherwise why the part burned.
func _burn_help(p: Part) -> void:
	# In Try it the build's goals aren't being checked: explain the part.
	var m := "" if game.state.trying() else _first_failing()
	if not _is_mistake(m):
		m = Explain.part(p, game.state.outcome.result)[0]
	_last_mistake = m
	var why := MistakeWhy.for_message(m)
	guide.show_line(m, "oops", "help", _why_button(why if why != "" else MistakeWhy.for_burnt(p.kind)))


## A mistake line's Why? button, which adds the physics under it.
func _why_actions(m: String) -> Array:
	return _why_button(MistakeWhy.for_message(m))


func _why_button(why: String) -> Array:
	if why == "":
		return []
	return [{"label": "Why?", "callback": func() -> void: guide.expand(why)}]


func _check_mistakes() -> void:
	var s := game.state
	if _help() != "heavy" or s.session.phase != "build" or recap.visible:
		return
	var m := _first_failing()
	if not _is_mistake(m):
		# Fixed or undone: Pip stops talking about a mistake that's gone.
		if not _any_burnt() and guide.visible and guide.kind == "help" and guide.mood == "oops":
			guide.hide_bubble()
		_last_mistake = ""
		return
	if m != _last_mistake:
		_last_mistake = m
		guide.show_line(m, "oops", "help", _why_actions(m))


## Soft sounds for what changed since the last refresh: a part placed, a
## wire joined, an LED lighting up, a test run.
func _sounds_for(s: GameState) -> void:
	var c := s.outcome.circuit
	var parts := {}
	var wires := {}
	var lit := {}
	for p in c.parts:
		parts[p.id] = true
		if p.kind == "led" and float(VisualState.for_part(p, s.outcome.result, {})["brightness"]) >= 0.05:
			lit[p.id] = true
	for w in c.wires:
		wires[w.id] = true
	if _heard:
		if parts.keys().any(func(id: String) -> bool: return not _parts_before.has(id)):
			_sound("place")
		elif wires.keys().any(func(id: String) -> bool: return not _wires_before.has(id)):
			_sound("connect")
		if lit.keys().any(func(id: String) -> bool: return not _lit_before.has(id)):
			_sound("light")
		var report := s.session.test_report
		if not report.is_empty() and not is_same(report, _report_before):
			_sound("test_pass" if bool(report.get("pass", false)) else "test_fail")
			# New results: scroll the column to them.
			column_scroll.ensure_control_visible.call_deferred(test_sheet)
	_heard = true
	_parts_before = parts
	_wires_before = wires
	_lit_before = lit
	_report_before = s.session.test_report


func _sound(name: String) -> void:
	var audio := get_tree().get_first_node_in_group("audio") as Audio
	if audio != null:
		audio.play(name)


func _any_burnt() -> bool:
	return game.state.outcome.circuit.parts.any(func(p: Part) -> bool: return bool(p.props.get("burnt", false)))


func _first_failing() -> String:
	for r in game.state.session.goal_results:
		if not bool(r["pass"]):
			return str(r["message"])
	return ""


func _is_mistake(m: String) -> bool:
	for prefix in MISTAKES:
		if m.begins_with(prefix):
			return true
	return false


## On Heavy, Pip offers the calculator once, when the step that needs it
## comes up (or at the start when no step names it).
func _check_formula_offer() -> void:
	var s := game.state
	if _help() != "heavy" or _formula_offered or s.level.formula == "" or s.session.phase != "build" or recap.visible:
		return
	var flag := "formula:" + s.level.formula
	var named := false
	var current := {}
	for i in s.level.steps.size():
		var check: Dictionary = s.level.steps[i]["check"]
		if str(check.get("flag", "")) == flag:
			named = true
		if current.is_empty() and not (i < s.session.step_results.size() and bool(s.session.step_results[i]["pass"])):
			current = check
	if named and str(current.get("flag", "")) != flag:
		return
	_formula_offered = true
	guide.show_line(FORMULA_OFFER, "curious", "help", [{"label": "Open calculator", "callback": func() -> void: _open_card(formula)}])


func _update_guide() -> void:
	var s := game.state
	deck.visible = s.session.phase == "learn"
	if deck.visible:
		deck.show_card(s.level, s.session.card_index)
		if guide.visible and guide.kind != "help":
			guide.hide_bubble()
		return


## After a pass: the Recap, filled from the player's own circuit.
func _start_outro() -> void:
	var s := game.state
	guide.hide_bubble()
	recap.show_recap(s.level, s.outcome, _next_level_id())
	recap.visible = true
	game.mark_lesson_step("recap")
	_place_floating()


## The Lesson button opens the lesson again, or on a passed bench brings the
## recap back (and from there, Read again).
func _on_lesson_button() -> void:
	if game.state.session.phase == "passed":
		_start_outro()
	else:
		game.reopen_lesson()


## The answer's ghost parts and wires the hints show now ({} when none).
func hint_ghosts() -> Dictionary:
	return _ghosts


func _next_level_id() -> String:
	var ids := Levels.chapter_ids(game.state.level.chapter)
	var i := ids.find(game.state.level.id)
	return ids[i + 1] if i >= 0 and i + 1 < ids.size() else ""


## Hints: words first, then highlights, then the solution's ghosts with chips
## for value changes and removals.
func _update_hints() -> void:
	var s := game.state
	var tier := s.session.hint_tier
	_ghosts = {}
	_highlights = []
	# Hints are for the build: Try it's ready-made circuit isn't the answer's.
	if tier <= 0 or s.level.hints.is_empty() or s.trying():
		return
	var h: Dictionary = s.level.hints[mini(tier, s.level.hints.size()) - 1]
	_highlights = (h.get("highlight", []) as Array).duplicate(true)
	var chips := []
	if bool(h.get("show_solution", false)):
		_ghosts = SolutionDiff.compute(s.history.present, s.level.solution)
		for w in _ghosts["remove_wires"]:
			_highlights.append({"wire": w})
		for p in _ghosts["remove_parts"]:
			_highlights.append({"part": p})
		chips = _hint_chips(_ghosts)
	if tier != _hint_tier_shown or (guide.kind == "hint" and bool(h.get("show_solution", false))):
		_hint_tier_shown = tier
		if s.session.phase == "build" and not recap.visible:
			guide.show_line(h["text"], "curious", "hint", chips)


func _hint_chips(diff: Dictionary) -> Array:
	var chips := []
	var c := game.state.history.present
	for change in diff["props"]:
		var p := c.find_part(str(change["part"]))
		if p == null:
			continue
		var value: Variant = change["value"]
		var shown := Catalog.format_ohms(float(value)) if str(change["key"]) == "ohms" else str(value)
		var id := p.id
		var patch := {str(change["key"]): value}
		chips.append({"label": "Set %s to %s" % [Catalog.title(p.kind), shown], "callback": func() -> void:
			game.commit(CircuitEdits.set_props(game.state.history.present, id, patch))})
	var wires: PackedStringArray = diff["remove_wires"]
	if not wires.is_empty():
		chips.append({"label": "Delete the highlighted wire" + ("s" if wires.size() > 1 else ""), "callback": func() -> void:
			var out := game.state.history.present
			for w in wires:
				out = CircuitEdits.delete_wire(out, w)
			game.commit(out)})
	var parts: PackedStringArray = diff["remove_parts"]
	if not parts.is_empty():
		chips.append({"label": "Remove the highlighted part" + ("s" if parts.size() > 1 else ""), "callback": func() -> void:
			var out := game.state.history.present
			for p in parts:
				out = CircuitEdits.delete_part(out, p)
			game.commit(out)})
	return chips


func _on_ghost(kind: String, data: Dictionary) -> void:
	var s := game.state
	var c := s.history.present
	if kind == "part":
		var p := (data["part"] as Part).copy()
		var used := s.tray_used()
		if p.tray >= 0 and p.tray < used.size() and used[p.tray] >= int(s.level.tray[p.tray].get("count", 1)):
			toasts.show_text("That part is already on the board.")
			return
		game.commit(CircuitEdits.add_part(c, p))
	elif kind == "wire":
		if CircuitEdits.can_add_wire(c, data["a_part"], data["a_pin"], data["b_part"], data["b_pin"]) != "":
			return
		game.commit(CircuitEdits.add_wire(c, data["a_part"], data["a_pin"], data["b_part"], data["b_pin"]))


func _on_menu(action: String, target: Dictionary) -> void:
	var c := game.state.history.present
	var id := str(target.get("part", ""))
	match action:
		"Rotate":
			game.commit(CircuitEdits.rotate_part(c, id))
		"Delete":
			game.commit(CircuitEdits.delete_part(c, id) if id != "" else CircuitEdits.delete_wire(c, str(target.get("wire", ""))))
		"Datasheet":
			_open_datasheet(id)
		"Explain":
			_open_explain(id)
		"Replace":
			game.commit(CircuitEdits.set_props(c, id, {"burnt": false}))
		"About":
			var p := c.find_part(id)
			if p != null:
				_open_meet(PartIntros.key_for(p))


func _open_datasheet(id: String) -> void:
	var p := game.state.shown().circuit.find_part(id)
	if p == null:
		return
	datasheet.open(p, true)
	_open_card(datasheet)
	game.set_ui_flag("datasheet:" + id)


func _open_tray_datasheet(i: int) -> void:
	var item: Dictionary = game.state.level.tray[i]
	datasheet.open(Part.make("?", item["kind"], 0, 0, 0, item.get("props", {})), false)
	_open_card(datasheet)
	game.set_ui_flag("datasheet:tray")


func _open_explain(id: String) -> void:
	var o := game.state.shown()
	var p := o.circuit.find_part(id)
	if p == null:
		return
	explain.open(p, o.result, editor.grid_to_screen(CircuitGeometry.part_rect(p).get_center()))


func _open_value(id: String) -> void:
	var p := game.state.history.present.find_part(id)
	if p == null:
		return
	value_popover.open(id, float(p.props.get("ohms", 220.0)), editor.grid_to_screen(CircuitGeometry.part_rect(p).get_center()))


## Centered cards are shown one at a time (the glossary may sit on top).
func _open_card(card: Control) -> void:
	for c in [datasheet, formula, settings_sheet, notebook]:
		if c != card:
			c.visible = false
	if card == formula:
		formula.open()
	elif card == settings_sheet:
		settings_sheet.open()
	elif card == notebook:
		notebook.open()
	card.visible = true


func _queue_word(term: String) -> void:
	if term in _carded:
		return
	_carded.append(term)
	_word_queue.append(term)
	_pump_words()


func _pump_words() -> void:
	while _cards.size() < _max_cards() and not _word_queue.is_empty():
		var card := NewWordCard.make(game, _word_queue[0])
		_word_queue.remove_at(0)
		card.finished.connect(_on_card_done)
		_cards_root.add_child(card)
		_cards.append(card)
		_sound("word")


## The first time a part is on the bench or in the tray, at any help level,
## its Meet the part card comes up, one at a time. Lesson 0 is about the
## controls, so its parts wait for Lesson 1's deck.
func _check_new_parts() -> void:
	var s := game.state
	if s.level == null or s.level.kind == "tutorial" or not s.session.phase in ["try", "build"]:
		return
	var keys := PackedStringArray()
	for p in s.history.present.parts:
		keys.append(PartIntros.key_for(p))
	for item in s.current_tray():
		keys.append(PartIntros.key_for(Part.make("T", item["kind"], 0, 0, 0, item["props"])))
	var showing := meet_card != null and meet_card.visible
	for k in keys:
		if s.progress.parts_seen.has(k) or k in _meet_queue or PartIntros.get_intro(k).is_empty():
			continue
		if showing and meet_card.key == k:
			continue
		_meet_queue.append(k)
	if not showing and not _meet_queue.is_empty():
		_open_meet(_meet_queue[0])


func _open_meet(key: String) -> void:
	if meet_card != null:
		meet_card.get_parent().remove_child(meet_card)
		meet_card.queue_free()
	meet_card = MeetPartCard.make(game, key)
	meet_card.closed.connect(_on_meet_closed)
	hud.add_child(meet_card)
	# Under the glossary popup, so a word tapped on the card opens on top.
	hud.move_child(meet_card, glossary_popup.get_index())
	meet_card.visible = true
	_place_floating()


func _on_meet_closed(key: String) -> void:
	var i := _meet_queue.find(key)
	if i >= 0:
		_meet_queue.remove_at(i)
	game.mark_part_seen(key)
	_queue_refresh()


## Closes the topmost open card or popup (Android's Back); false when none
## was open.
func close_top() -> bool:
	if menu.visible:
		menu.close()
		return true
	if textbook.close_top():
		return true
	if recap.visible:
		recap.visible = false
		return true
	if meet_card != null and meet_card.visible:
		meet_card.close_button().pressed.emit()
		return true
	for card in [value_popover, explain, glossary_popup, datasheet, formula, notebook, settings_sheet]:
		if card.visible:
			card.visible = false
			return true
	return false


## Two cards when the board is tall enough for two, else one.
func _max_cards() -> int:
	return MAX_CARDS if editor.safe_rect.size.y >= 520.0 else 1


## Where the column is on screen (nothing while it's hidden).
func column_area() -> Rect2:
	return column_scroll.get_global_rect() if column_scroll.is_visible_in_tree() else Rect2()


func _on_card_done(card: NewWordCard) -> void:
	_cards.erase(card)
	card.queue_free()
	_pump_words()


func _frame_circuit() -> void:
	if not is_inside_tree():
		return
	if editor.size.y < 1.0:
		await editor.resized
	var view := editor.fit_view()
	# Leave room to zoom out past the framing, however small the board area is.
	editor.max_view = maxf(120.0, view * 1.5)
	stage.set_camera(ZoomCamera.make("editor", editor.fit_center(), view))


## The first framing waits a frame, so the panels around the board have their
## real sizes.
func _initial_frame() -> void:
	await get_tree().process_frame
	if not is_inside_tree():
		return
	_layout()
	_frame_circuit()


## A new board size (a window resize, a phone turned) frames the circuit again.
func _on_board_resized() -> void:
	if game.state.zoom_layer == "editor":
		_layout()
		_frame_circuit.call_deferred()


func _connect() -> void:
	try_panel.ready_pressed.connect(game.finish_try)
	skip_tutorial_button.pressed.connect(game.skip_tutorial)
	notebook.open_lesson.connect(func(id: String) -> void:
		notebook.visible = false
		textbook.open_lesson(id))
	notebook.open_part.connect(func(key: String) -> void:
		notebook.visible = false
		textbook.open_part(key))
	# What the player did, for Lesson 0's steps.
	editor.view_moved.connect(func(how: String) -> void: game.set_ui_flag("did:" + how))
	hint_button.pressed.connect(func() -> void: game.set_ui_flag("did:hint"))
	top_bar.button("calculator").pressed.connect(func() -> void: game.set_ui_flag("did:calculator"))
	top_bar.button("notebook").pressed.connect(func() -> void: game.set_ui_flag("did:notebook"))
	recap.next_lesson.connect(func() -> void:
		var next_id := _next_level_id()
		if next_id != "":
			game.open_level(next_id))
	recap.to_map.connect(game.open_map)
	recap.read_again.connect(game.reopen_lesson)
	recap.put_away.connect(func() -> void: recap.visible = false)
	deck.next_pressed.connect(game.next_card)
	deck.back_pressed.connect(game.back_card)
	deck.skip_pressed.connect(game.skip_learn)
	lesson_button.pressed.connect(_on_lesson_button)
	editor.commit_requested.connect(game.commit)
	editor.datasheet_requested.connect(_open_datasheet)
	editor.toast_requested.connect(func(text: String) -> void: toasts.show_text(text))
	editor.menu_requested.connect(func(target: Dictionary, at: Vector2) -> void:
		menu.open(target, at)
		game.set_ui_flag("did:menu"))
	editor.value_requested.connect(_open_value)
	editor.explain_requested.connect(_open_explain)
	editor.selected.connect(func(id: String) -> void:
		if game.state.history.present.find_wire(id) != null:
			game.set_ui_flag("selected:" + id))
	editor.ghost_tapped.connect(_on_ghost)
	stage.layer_changed.connect(game.set_zoom_layer)
	stage.view_changed.connect(func(meters: float, jump: String) -> void: scale_bar.set_view(meters, jump, stage.size.y))
	game.changed.connect(_queue_refresh)
	game.term_requested.connect(func(term: String) -> void: glossary_popup.open(term))
	tray.place_requested.connect(func(i: int) -> void: editor.begin_placing(i))
	tray.info_requested.connect(_open_tray_datasheet)
	menu.chosen.connect(_on_menu)
	value_popover.previewed.connect(func(id: String, ohms: float) -> void:
		game.preview(CircuitEdits.set_props(game.state.history.present, id, {"ohms": ohms})))
	value_popover.committed.connect(func(id: String, ohms: float) -> void:
		game.commit(CircuitEdits.set_props(game.state.history.present, id, {"ohms": ohms}))
		game.set_ui_flag("value:" + id))
	datasheet.explain_requested.connect(_open_explain)
	hint_button.pressed.connect(func() -> void: game.use_hint())
	back_to_building.pressed.connect(_frame_circuit)
	top_bar.button("calculator").pressed.connect(func() -> void: _open_card(formula))
	top_bar.button("restart").pressed.connect(game.start_over)
	top_bar.button("notebook").pressed.connect(func() -> void: _open_card(notebook))
	top_bar.button("settings").pressed.connect(func() -> void: _open_card(settings_sheet))


func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column_scroll = ScrollContainer.new()
	column_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hud.add_child(column_scroll)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_theme_constant_override("separation", 8)
	column_scroll.add_child(_column)
	skip_tutorial_button = Button.new()
	skip_tutorial_button.text = "Skip Lesson 0"
	skip_tutorial_button.theme_type_variation = "FlatButton"
	skip_tutorial_button.custom_minimum_size = Vector2(0, IconButton.MIN_TOUCH)
	skip_tutorial_button.visible = false
	try_panel = _with_game(TryPanel.new())
	goals = _with_game(GoalsPanel.new())
	checklist = _with_game(StepsChecklist.new())
	test_sheet = _with_game(TestSheet.new())
	for p in [skip_tutorial_button, try_panel, goals, checklist, test_sheet]:
		_column.add_child(p)
	tray = _add(PartsTray.new())
	top_bar = _add(TopBar.new())
	scale_bar = _add(ScaleBar.new())
	hint_button = _add(HintButton.create())
	# Beside Hint, never scrolled away with the column.
	test_button = _add(TestSheet.make_button(game))
	lesson_button = _add(IconButton.make("lesson", "Open the lesson again", "Lesson"))
	lesson_button.custom_minimum_size = Vector2(112, 52)
	guide = _add(GuideBubble.new())
	# Under the New word cards and every popup, so a word tapped in a card
	# opens its definition on top.
	hand = _add(GestureHand.new())
	hand.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	spotlight = _add(Spotlight.new())
	spotlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck = _add(LessonDeck.new())
	recap = _add(RecapCard.new())
	back_to_building = Button.new()
	back_to_building.text = "Back to building"
	back_to_building.visible = false
	hud.add_child(back_to_building)
	# Rendered when it first shows: its words count as met then, not before.
	zoom_caption = HudText.label(game, 18)
	zoom_caption.add_theme_color_override("default_color", Color(0.97, 0.96, 1.0))
	zoom_caption.add_theme_color_override("font_outline_color", Color(0.08, 0.07, 0.12, 0.85))
	zoom_caption.add_theme_constant_override("outline_size", 6)
	zoom_caption.visible = false
	hud.add_child(zoom_caption)
	_cards_root = Control.new()
	_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_cards_root)
	_cards_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	datasheet = _add(DatasheetCard.new())
	formula = _add(FormulaCard.new())
	settings_sheet = _add(SettingsSheet.new())
	notebook = _add(NotebookSheet.new())
	menu = _add(ContextMenu.new())
	value_popover = _add(ValuePopover.new())
	explain = _add(ExplainPopover.new())
	textbook = _add(Textbook.new())
	textbook.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glossary_popup = _add(GlossaryPopup.new())
	toasts = _add(Toasts.new())


func _with_game(node: Control) -> Control:
	node.set("game", game)
	return node


func _add(node: Control) -> Control:
	_with_game(node)
	hud.add_child(node)
	return node


## Landscape: the tray is a left column and the goals sit top right.
## Portrait: the tray is a strip along the bottom and the goals fold into a
## pill under the top bar. The board's framing avoids both.
func _layout() -> void:
	if hud == null:
		return
	var w := size.x
	var h := size.y
	var portrait := w < h
	_portrait = portrait
	if tray.vertical == portrait:
		tray.vertical = not portrait
	# A landscape phone is short: the goals fold up as in portrait.
	var short := not portrait and h < 560.0
	goals.compact = portrait or short
	checklist.compact = portrait or short
	top_bar.show_title = w >= 520.0
	top_bar.position = Vector2(MARGIN, MARGIN)
	top_bar.size = Vector2(w - 2.0 * MARGIN, BAR_H)
	var top := MARGIN + BAR_H + 8.0
	var safe: Rect2
	var hint_size := hint_button.custom_minimum_size
	var test_size := test_button.custom_minimum_size
	if portrait:
		tray.position = Vector2(MARGIN, h - MARGIN - STRIP_H)
		tray.size = Vector2(w - 2.0 * MARGIN, STRIP_H)
		# Hint and Test sit in a row above the tray; the scale bar beside
		# them when it fits, else above.
		var row_y := tray.position.y - 8.0 - hint_size.y
		hint_button.position = Vector2(w - MARGIN - hint_size.x, row_y)
		test_button.position = Vector2(hint_button.position.x - 8.0 - test_size.x, row_y)
		var column_h := _column_height(w - 2.0 * MARGIN, h * 0.38)
		_column_room = column_h
		column_scroll.position = Vector2(MARGIN, top)
		column_scroll.size = Vector2(w - 2.0 * MARGIN, column_h)
		safe = Rect2(MARGIN, top + column_h + 8.0, w - 2.0 * MARGIN, tray.position.y - 8.0 - (top + column_h + 8.0))
	else:
		tray.position = Vector2(MARGIN, top)
		tray.size = Vector2(TRAY_W, h - top - MARGIN)
		var row_y := h - MARGIN - hint_size.y
		hint_button.position = Vector2(w - MARGIN - hint_size.x, row_y)
		test_button.position = Vector2(hint_button.position.x - 8.0 - test_size.x, row_y)
		column_scroll.position = Vector2(w - MARGIN - COLUMN_W, top)
		column_scroll.size = Vector2(COLUMN_W, _column_height(COLUMN_W, row_y - 8.0 - top))
		scale_bar.position = Vector2(MARGIN + TRAY_W + 12.0, h - MARGIN - scale_bar.custom_minimum_size.y)
		safe = Rect2(MARGIN + TRAY_W + 8.0, top, w - MARGIN - COLUMN_W - 8.0 - (MARGIN + TRAY_W + 8.0), h - top - MARGIN)
	editor.safe_rect = safe
	scale_bar.size = scale_bar.custom_minimum_size
	hint_button.size = hint_size
	test_button.size = test_size
	_place_floating()


## The part of the screen the current tour card points at ("" when none).
func _tour_target() -> String:
	var s := game.state
	if s.level == null or s.session.phase != "learn":
		return ""
	var i := s.session.card_index - 1
	if i < 0 or i >= s.level.learn.size() or s.level.learn[i]["type"] != "tour":
		return ""
	return str(s.level.learn[i]["target"])


## Where a tour target is on screen.
func tour_rect(target: String) -> Rect2:
	match target:
		"board":
			return Rect2(editor.global_position - global_position + editor.safe_rect.position, editor.safe_rect.size)
		"tray":
			return _local_rect(tray)
		"top_bar":
			return _local_rect(top_bar)
		"map_button":
			return _buttons_rect(["map"])
		"edit_buttons":
			return _buttons_rect(["restart", "undo", "redo"])
		"tool_buttons":
			return _buttons_rect(["calculator", "notebook", "settings"])
		"column":
			return _local_rect(column_scroll)
		"hint":
			return _local_rect(hint_button)
		"battery":
			var a := demo_target({"pin": "B1:pos"})
			var b := demo_target({"pin": "B1:neg"})
			return Rect2(a.min(b), (a - b).abs()).grow(40.0)
	return Rect2()


## The top bar's buttons `ids`, as one rectangle.
func _buttons_rect(ids: Array) -> Rect2:
	var out := Rect2()
	for id in ids:
		var r := _local_rect(top_bar.button(id))
		out = r if out.size == Vector2.ZERO else out.merge(r)
	return out


func _local_rect(c: Control) -> Rect2:
	return Rect2(c.global_position - global_position, c.size)


## Moves `card` off `hole`: to the far side, top or bottom, and when the hole
## is narrow, to the other side across too.
func _dodge(card: Control, hole: Rect2, area: Rect2) -> void:
	var y := area.position.y if hole.get_center().y > area.get_center().y else area.end.y - card.size.y
	card.position.y = y
	if card.get_rect().intersects(hole) and hole.size.x < area.size.x * 0.5:
		card.position.x = area.end.x - card.size.x if hole.get_center().x < area.get_center().x else area.position.x
	card.position = card.position.round()


## A demo's point on screen: {tray: i}, {part: id | "placed", offset?},
## {pin: "B1:pos" | "placed:a"}, {wire: "placed"}, {button: "undo" | "hint"}
## or {board: [x, y]}. (-1, -1) when what it names isn't there.
func demo_target(spec: Dictionary) -> Vector2:
	var c := game.state.history.present
	var to_screen := func(g: Vector2) -> Vector2: return editor.global_position - global_position + editor.grid_to_screen(g)
	if spec.has("tray"):
		var items := tray.items()
		var i := int(spec["tray"])
		return _local_rect(items[i]).get_center() if i < items.size() else Vector2(-1, -1)
	if spec.has("part"):
		var p := _demo_part(c, str(spec["part"]))
		if p == null:
			return Vector2(-1, -1)
		var off: Array = spec.get("offset", [0, 0])
		return to_screen.call(CircuitGeometry.part_rect(p).get_center() + Vector2(float(off[0]), float(off[1])))
	if spec.has("pin"):
		var parts := str(spec["pin"]).split(":")
		var p := _demo_part(c, parts[0])
		if p == null:
			return Vector2(-1, -1)
		return editor.global_position - global_position + editor.pin_screen_pos(p.id, parts[1])
	if spec.has("wire"):
		for w in c.wires:
			if not w.locked:
				# Halfway along it, clear of the parts at its ends.
				var path := CircuitGeometry.wire_path(c, w)
				return to_screen.call(Diagram.along(path, Diagram.path_length(path) / 2.0))
		return Vector2(-1, -1)
	if spec.has("button"):
		var b: Control = hint_button if spec["button"] == "hint" else top_bar.button(str(spec["button"]))
		return _local_rect(b).get_center() if b != null else Vector2(-1, -1)
	if spec.has("board"):
		var xy: Array = spec["board"]
		return to_screen.call(Vector2(float(xy[0]), float(xy[1])))
	return Vector2(-1, -1)


## "placed" is the first part the player added; otherwise a part id.
func _demo_part(c: Circuit, name: String) -> Part:
	if name != "placed":
		return c.find_part(name)
	for p in c.parts:
		if not p.locked:
			return p
	return null


## Lesson 0: the moving hand shows the first step not done yet, where it's
## done; mouse players get the mouse version of a gesture.
func _update_hand() -> void:
	var s := game.state
	var step := -1
	if s.level != null and s.level.kind == "tutorial" and s.session.phase == "build":
		for i in s.level.steps.size():
			if not (i < s.session.step_results.size() and bool(s.session.step_results[i]["pass"])):
				step = i
				break
	if step < 0 or not s.level.steps[step].has("demo"):
		if hand.playing():
			hand.stop()
		_hand_key = ""
		return
	var spec: Dictionary = s.level.steps[step]["demo"].duplicate()
	if InputMode.current() == "mouse" and spec.has("mouse"):
		spec.merge(spec["mouse"], true)
	var from := demo_target(spec["from"])
	var to := demo_target(spec.get("to", spec["from"]))
	if from.x < 0.0:
		hand.stop()
		_hand_key = ""
		return
	var key := "%d|%s" % [step, spec["gesture"]]
	if key != _hand_key:
		_hand_key = key
		hand.still = bool(s.progress.settings.get("reduced_motion", false))
		hand.play(str(spec["gesture"]), from, to, str(spec.get("key", "")))
	else:
		hand.retarget(from, to)


## Lesson goes left of Test (or of Hint), icon-only on a narrow phone; in
## portrait the scale bar sits beside the row when it fits, else above it.
func _place_button_row() -> void:
	var narrow := _portrait and size.x < 420.0
	var passed := game.state.session.phase == "passed"
	lesson_button.text = "" if narrow else ("Recap" if passed else "Lesson")
	lesson_button.tooltip_text = "See the recap again" if passed else "Open the lesson again"
	lesson_button.custom_minimum_size = Vector2(52, 52) if narrow else Vector2(112, 52)
	lesson_button.size = lesson_button.custom_minimum_size
	var anchor_x := test_button.position.x if test_button.visible else hint_button.position.x
	lesson_button.position = Vector2(anchor_x - 8.0 - lesson_button.size.x, hint_button.position.y)
	if not _portrait:
		return
	var leftmost := hint_button.position.x
	for b in [test_button, lesson_button]:
		if (b as Control).visible:
			leftmost = minf(leftmost, (b as Control).position.x)
	var bar_size := scale_bar.custom_minimum_size
	var row_y := hint_button.position.y
	var beside := MARGIN + bar_size.x + 8.0 <= leftmost
	scale_bar.position = Vector2(MARGIN, row_y + hint_button.custom_minimum_size.y - bar_size.y if beside else row_y - 8.0 - bar_size.y)


## The column's height at `width`: its content's, up to `cap`.
func _column_height(width: float, cap: float) -> float:
	_column.size.x = width
	return clampf(_column.get_combined_minimum_size().y, 0.0, maxf(cap, 0.0))


## Things whose size follows their content: the guide, cards and popups.
func _place_floating() -> void:
	if hud == null:
		return
	var w := size.x
	var h := size.y
	var top := MARGIN + BAR_H + 8.0
	_place_button_row()
	# The column grows and shrinks with its content, never past its room.
	var column_cap := _column_room if _portrait else hint_button.position.y - 8.0 - top
	column_scroll.size.y = _column_height(column_scroll.size.x, column_cap)
	if _portrait:
		guide.size = Vector2(w - 2.0 * MARGIN, 0)
		guide.reset_size()
		guide.size.x = w - 2.0 * MARGIN
		guide.position = Vector2(MARGIN, hint_button.position.y - 8.0 - guide.size.y)
	else:
		var left := MARGIN + TRAY_W + 12.0
		var right := w - MARGIN - COLUMN_W - 12.0
		var gw := minf(right - left, 600.0)
		guide.size = Vector2(gw, 0)
		guide.reset_size()
		guide.size.x = gw
		guide.position = Vector2(left + (right - left - gw) / 2.0, h - MARGIN - guide.size.y)
	back_to_building.reset_size()
	back_to_building.position = Vector2((w - back_to_building.size.x) / 2.0, top)
	var caption_w := minf(w - 2.0 * MARGIN, 640.0)
	zoom_caption.custom_minimum_size = Vector2(caption_w, 0)
	zoom_caption.size = Vector2(caption_w, 0)
	zoom_caption.reset_size()
	zoom_caption.position = Vector2((w - caption_w) / 2.0, top + 52.0)
	var board := editor.safe_rect
	toasts.size = Vector2(minf(board.size.x - 16.0, 460.0), 0)
	toasts.reset_size()
	toasts.size.x = minf(board.size.x - 16.0, 460.0)
	var above := guide.position.y if guide.visible else (hint_button.position.y if _portrait else h - MARGIN - 48.0)
	toasts.position = Vector2(board.get_center().x - toasts.size.x / 2.0, above - 8.0 - toasts.size.y)
	var area := Rect2(MARGIN, top, w - 2.0 * MARGIN, h - top - MARGIN)
	if deck.visible:
		deck.fit_into(area, LessonDeck.MAX_W)
	var target := _tour_target()
	if target != "" and deck.visible:
		var hole := tour_rect(target)
		spotlight.show_rect(hole)
		_dodge(deck, hole, area)
	elif spotlight.visible:
		spotlight.clear()
	_update_hand()
	if meet_card != null and meet_card.visible:
		meet_card.fit_into(area, MeetPartCard.MAX_W)
	if recap.visible:
		recap.fit_into(area, RecapCard.MAX_W)
	for card in [datasheet, formula, settings_sheet, notebook, glossary_popup]:
		if card.visible:
			var cw := minf(380.0, area.size.x)
			var ch := 420.0 if card == notebook else -1.0
			CardFit.fit(card, cw, area, (area.position + (area.size - Vector2(cw, card.size.y)) / 2.0), ch)
	if explain.visible:
		CardFit.fit(explain, 360.0, area, explain.position)
	var y := board.position.y + 8.0
	for card in _cards:
		var cw := minf(card.custom_minimum_size.x, board.size.x - 16.0)
		card.size = Vector2(cw, 0)
		card.reset_size()
		card.size.x = cw
		var x := board.position.x + 8.0
		card.position = Vector2(x - (1.0 - card.slide_progress()) * (x + cw), y)
		y += card.size.y + 8.0
