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
const FINISH := "You did it! Keep experimenting here, or go on."
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
var hint_button: HintButton
var guide: GuideBubble
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
var _pages: Array[Dictionary] = []
var _page := -1
var _ghosts := {}
var _highlights: Array = []
var _board_key := ""
var _view_style := ""
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
	_build_hud()
	_connect()
	resized.connect(_layout)
	editor.resized.connect(_on_board_resized)
	_layout()
	_refresh()
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
	elif what == "calculator":
		_open_card(formula)
	elif what == "notebook":
		_open_card(notebook)
	elif what == "settings":
		_open_card(settings_sheet)


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
	if s.level == null or s.session.phase != "build" or _page >= 0:
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
## intro's words get the first New word cards.
func _refresh() -> void:
	_refresh_queued = false
	var s := game.state
	if s.level == null or not is_inside_tree():
		return
	var st := s.progress.settings
	_handle_events(s.take_events())
	_update_guide()
	_update_hints()
	var shown := s.shown()
	var key := "%d|%s|%s|%s" % [shown.get_instance_id(), st, _ghosts, _highlights]
	if key != _board_key:
		_board_key = key
		editor.set_state(shown.circuit, shown.result, st, _ghosts, _highlights)
	editor.set_tray(s.level.tray, s.tray_used())
	if str(st.get("view_style", "")) != _view_style:
		var first := _view_style == ""
		_view_style = str(st.get("view_style", ""))
		if not first:
			_frame_circuit.call_deferred()
	top_bar.refresh(s)
	tray.refresh(s.level.tray, s.tray_used())
	goals.refresh(s.level, s.session, s.outcome.circuit)
	checklist.visible = _help() == "heavy" and not s.level.steps.is_empty()
	if checklist.visible:
		checklist.refresh(s.level, s.session)
	test_sheet.visible = not s.level.tests.is_empty()
	if test_sheet.visible:
		test_sheet.refresh(s.session)
	hint_button.visible = _help() != "off" and not s.level.hints.is_empty()
	back_to_building.visible = s.zoom_layer != "editor"
	_check_mistakes()
	_check_formula_offer()
	if settings_sheet.visible:
		settings_sheet.sync()


func _handle_events(events: Array[Dictionary]) -> void:
	var s := game.state
	for e in events:
		match str(e["type"]):
			"burnt":
				var p := s.outcome.circuit.find_part(str(e["part"]))
				var title := Catalog.title(p.kind) if p != null else str(e["part"])
				toasts.show_text("Pop! %s burned out." % title)
				if _help() == "heavy" and p != null and _page < 0:
					_burn_help(p)
			"passed":
				_start_outro()
			"star":
				toasts.show_text("Star earned: %s" % s.level.star.get("text", ""), true)
			"badge":
				for a in Achievements.ALL:
					if a["id"] == e["id"]:
						toasts.show_text("Badge earned: %s" % a["name"], true)
			"new_word":
				_queue_word(str(e["term"]))


## Pip explains a burn: the goal's own message when it says what to do,
## otherwise why the part burned.
func _burn_help(p: Part) -> void:
	var m := _first_failing()
	if not _is_mistake(m):
		m = Explain.part(p, game.state.outcome.result)[0]
	_last_mistake = m
	guide.show_line(m, "oops", "help")


func _check_mistakes() -> void:
	var s := game.state
	if _help() != "heavy" or s.session.phase != "build" or _page >= 0:
		return
	var m := _first_failing()
	if not _is_mistake(m):
		_last_mistake = ""
		return
	if m != _last_mistake:
		_last_mistake = m
		guide.show_line(m, "oops", "help")


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
	if _help() != "heavy" or _formula_offered or s.level.formula == "" or s.session.phase != "build" or _page >= 0:
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
	if s.session.phase == "intro":
		var line: Dictionary = s.level.intro[s.session.intro_index]
		guide.show_line(line["text"], line.get("mood", "happy"), "intro", [{"label": "Next", "callback": game.next_intro}], "", false)
		return
	if guide.kind == "intro":
		guide.hide_bubble()
	if _page >= 0 and guide.kind != "outro":
		_show_page()


func _start_outro() -> void:
	var l := game.state.level
	_pages.clear()
	for o in l.outro:
		_pages.append({"text": o["text"], "mood": o.get("mood", "wow")})
	for f in l.facts:
		_pages.append({"text": "Fun fact: " + str(f["text"]), "mood": "wow", "source": f["source"]})
	_pages.append({"text": FINISH, "mood": "happy", "finish": true})
	_page = 0
	_show_page()


func _show_page() -> void:
	var pg := _pages[_page]
	if pg.get("finish", false):
		var actions := []
		var next_id := _next_level_id()
		if next_id != "":
			actions.append({"label": "Next level", "callback": func() -> void: game.open_level(next_id)})
		actions.append({"label": "Map", "callback": game.open_map})
		guide.show_line(pg["text"], pg["mood"], "outro", actions)
	else:
		guide.show_line(pg["text"], pg["mood"], "outro", [{"label": "Next", "callback": _next_page}], str(pg.get("source", "")), false)


func _next_page() -> void:
	_page = mini(_page + 1, _pages.size() - 1)
	_show_page()


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
	if tier <= 0 or s.level.hints.is_empty():
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
		if s.session.phase == "build" and _page < 0:
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
	while _cards.size() < (1 if _portrait else MAX_CARDS) and not _word_queue.is_empty():
		var card := NewWordCard.make(game, _word_queue[0])
		_word_queue.remove_at(0)
		card.finished.connect(_on_card_done)
		_cards_root.add_child(card)
		_cards.append(card)


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
	editor.commit_requested.connect(game.commit)
	editor.datasheet_requested.connect(_open_datasheet)
	editor.toast_requested.connect(func(text: String) -> void: toasts.show_text(text))
	editor.menu_requested.connect(func(target: Dictionary, at: Vector2) -> void: menu.open(target, at))
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
	top_bar.button("notebook").pressed.connect(func() -> void: _open_card(notebook))
	top_bar.button("settings").pressed.connect(func() -> void: _open_card(settings_sheet))


func _build_hud() -> void:
	hud = Control.new()
	hud.name = "HUD"
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_column = VBoxContainer.new()
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", 8)
	hud.add_child(_column)
	goals = _with_game(GoalsPanel.new())
	checklist = _with_game(StepsChecklist.new())
	test_sheet = _with_game(TestSheet.new())
	for p in [goals, checklist, test_sheet]:
		_column.add_child(p)
	tray = _add(PartsTray.new())
	top_bar = _add(TopBar.new())
	scale_bar = _add(ScaleBar.new())
	hint_button = _add(HintButton.create())
	guide = _add(GuideBubble.new())
	back_to_building = Button.new()
	back_to_building.text = "Back to building"
	back_to_building.visible = false
	hud.add_child(back_to_building)
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
	goals.compact = portrait
	checklist.compact = portrait
	top_bar.show_title = w >= 520.0
	top_bar.position = Vector2(MARGIN, MARGIN)
	top_bar.size = Vector2(w - 2.0 * MARGIN, BAR_H)
	var top := MARGIN + BAR_H + 8.0
	var safe: Rect2
	if portrait:
		tray.position = Vector2(MARGIN, h - MARGIN - STRIP_H)
		tray.size = Vector2(w - 2.0 * MARGIN, STRIP_H)
		_column.position = Vector2(MARGIN, top)
		_column.size = Vector2(w - 2.0 * MARGIN, 0)
		var column_h := _column.get_combined_minimum_size().y
		hint_button.position = Vector2(w - MARGIN - hint_button.custom_minimum_size.x, tray.position.y - 8.0 - hint_button.custom_minimum_size.y)
		scale_bar.position = Vector2(MARGIN, tray.position.y - 8.0 - scale_bar.custom_minimum_size.y)
		safe = Rect2(MARGIN, top + column_h + 8.0, w - 2.0 * MARGIN, tray.position.y - 8.0 - (top + column_h + 8.0))
	else:
		tray.position = Vector2(MARGIN, top)
		tray.size = Vector2(TRAY_W, h - top - MARGIN)
		_column.position = Vector2(w - MARGIN - COLUMN_W, top)
		_column.size = Vector2(COLUMN_W, 0)
		hint_button.position = Vector2(w - MARGIN - hint_button.custom_minimum_size.x, h - MARGIN - hint_button.custom_minimum_size.y)
		scale_bar.position = Vector2(MARGIN + TRAY_W + 12.0, h - MARGIN - scale_bar.custom_minimum_size.y)
		safe = Rect2(MARGIN + TRAY_W + 8.0, top, w - MARGIN - COLUMN_W - 8.0 - (MARGIN + TRAY_W + 8.0), h - top - MARGIN)
	editor.safe_rect = safe
	scale_bar.size = scale_bar.custom_minimum_size
	hint_button.size = hint_button.custom_minimum_size
	_place_floating()


## Things whose size follows their content: the guide, cards and popups.
func _place_floating() -> void:
	if hud == null:
		return
	var w := size.x
	var h := size.y
	var top := MARGIN + BAR_H + 8.0
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
	var board := editor.safe_rect
	toasts.size = Vector2(minf(board.size.x - 16.0, 460.0), 0)
	toasts.reset_size()
	toasts.size.x = minf(board.size.x - 16.0, 460.0)
	var above := guide.position.y if guide.visible else (hint_button.position.y if _portrait else h - MARGIN - 48.0)
	toasts.position = Vector2(board.get_center().x - toasts.size.x / 2.0, above - 8.0 - toasts.size.y)
	for card in [datasheet, formula, settings_sheet, notebook, glossary_popup]:
		if card.visible:
			var cw := minf(maxf(card.custom_minimum_size.x, 360.0), w - 2.0 * MARGIN)
			card.size = Vector2(cw, 0)
			card.reset_size()
			card.size = Vector2(cw, minf(card.size.y, h - top - MARGIN))
			card.position = ((Vector2(w, h) - card.size) / 2.0).max(Vector2(MARGIN, top)).round()
	var y := board.position.y + 8.0
	for card in _cards:
		var cw := minf(card.custom_minimum_size.x, board.size.x - 16.0)
		card.size = Vector2(cw, 0)
		card.reset_size()
		card.size.x = cw
		var x := board.position.x + 8.0
		card.position = Vector2(x - (1.0 - card.slide_progress()) * (x + cw), y)
		y += card.size.y + 8.0
