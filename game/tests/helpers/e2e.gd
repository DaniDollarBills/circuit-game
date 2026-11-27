class_name E2E
extends RefCounted
## Drives the whole game through real input events pushed into the root
## viewport, the way a player's mouse and fingers would.

var tree: SceneTree
var main: Control

var _old_size := Vector2i.ZERO
var _old_scale := Vector2i.ZERO


func _init(t: SceneTree) -> void:
	tree = t


## Main in a `size` window (the headless runner's own window is 64 × 64),
## saving to `progress_path`, after its first frames.
func start(progress_path: String, size := Vector2i(1280, 720)) -> Control:
	# One Main at a time: a second start replaces the first.
	stop()
	_old_size = tree.root.size
	_old_scale = tree.root.content_scale_size
	tree.root.size = size
	main = load("res://src/app/main.tscn").instantiate()
	main.set("progress_path", progress_path)
	tree.root.add_child(main)
	await frames(4)
	return main


## Frees Main and gives the runner its window back.
func stop() -> void:
	if main != null and is_instance_valid(main):
		main.free()
	main = null
	if _old_size != Vector2i.ZERO:
		tree.root.size = _old_size
		tree.root.content_scale_size = _old_scale


## Resizes the window, as a player turning a phone or dragging a corner.
func resize(size: Vector2i) -> void:
	tree.root.size = size
	await frames(6)


func game() -> Game:
	return main.get("game")


func screen() -> Control:
	return main.get("screen")


func frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func seconds(s: float) -> void:
	await tree.create_timer(s).timeout


func _push(e: InputEvent) -> void:
	tree.root.push_input(e, true)


func move(at: Vector2, mask := 0) -> void:
	var m := InputEventMouseMotion.new()
	m.position = at
	m.global_position = at
	m.button_mask = mask
	_push(m)


func button(at: Vector2, pressed: bool, which := MOUSE_BUTTON_LEFT) -> void:
	var b := InputEventMouseButton.new()
	b.button_index = which
	b.pressed = pressed
	b.position = at
	b.global_position = at
	b.button_mask = (MOUSE_BUTTON_MASK_LEFT if which == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT) if pressed else 0
	_push(b)


func click(at: Vector2, which := MOUSE_BUTTON_LEFT) -> void:
	move(at)
	button(at, true, which)
	button(at, false, which)
	await frames(2)


## Scrolls `c` into view first when it sits in a scroll area, as a player would.
func click_control(c: Control) -> void:
	var p := c.get_parent()
	while p != null and not (p is ScrollContainer):
		p = p.get_parent()
	if p != null:
		(p as ScrollContainer).ensure_control_visible(c)
		await frames(2)
	await click(c.get_global_rect().get_center())


func drag(from: Vector2, to: Vector2, steps := 8) -> void:
	move(from)
	button(from, true)
	for k in range(1, steps + 1):
		move(from.lerp(to, float(k) / steps), MOUSE_BUTTON_MASK_LEFT)
	button(to, false)
	await frames(2)


func long_press(at: Vector2) -> void:
	move(at)
	button(at, true)
	await seconds(0.6)
	button(at, false)
	await frames(2)


func touch(index: int, at: Vector2, pressed: bool) -> void:
	var t := InputEventScreenTouch.new()
	t.index = index
	t.position = at
	t.pressed = pressed
	_push(t)


func touch_drag(index: int, at: Vector2, relative: Vector2) -> void:
	var d := InputEventScreenDrag.new()
	d.index = index
	d.position = at
	d.relative = relative
	_push(d)


## A pin's position on screen (root viewport coordinates).
func pin(s: LevelScreen, part_id: String, pin_name: String) -> Vector2:
	return s.editor.global_position + s.editor.pin_screen_pos(part_id, pin_name)


## Where a part is seen: in the real view, the top of its body (an LED's
## dome, not its legs); in the schematic, its symbol's middle.
func part_top(s: LevelScreen, part_id: String) -> Vector2:
	var c := s.game.state.history.present
	if str(s.game.state.progress.settings.get("view_style", "physical")) == "schematic":
		return grid(s, CircuitGeometry.part_rect(c.find_part(part_id)).get_center())
	var node := s.editor.workbench.part_node(part_id)
	var body: Node3D = node.get_node_or_null("epoxy")
	if body == null:
		body = node.get_node_or_null("body")
	if body == null:
		body = node
	var box := EditorLayer._bounds(body) if not (body is MeshInstance3D) else \
			(body as MeshInstance3D).global_transform * (body as MeshInstance3D).mesh.get_aabb()
	return s.editor.global_position + s.editor.workbench.camera.unproject_position(box.get_center() + Vector3(0, box.size.y * 0.35, 0))


func grid(s: LevelScreen, g: Vector2) -> Vector2:
	return s.editor.global_position + s.editor.grid_to_screen(g)


## Clicks through the lesson's cards with Next.
func skip_intro(s: LevelScreen) -> void:
	for i in 16:
		if s.game.state.session.phase != "learn":
			break
		await click_control(s.guide.action_buttons()[0])
	await frames(2)


## Taps away any New word card covering `at` (each tap opens the glossary,
## which is then closed).
func clear_cards_at(s: LevelScreen, points: Array) -> void:
	# Let any card finish sliding in first, so its final place is known.
	await seconds(NewWordCard.SLIDE_S + 0.1)
	for i in 20:
		var covering: NewWordCard = null
		for c in s.visible_word_cards():
			for p in points:
				if c.get_global_rect().has_point(p):
					covering = c
		if covering == null:
			return
		await click_control(covering)
		if s.glossary_popup.visible:
			s.glossary_popup.visible = false
		await frames(2)


## The first Button under `root` whose text is `text`.
static func find_button(root: Node, text: String) -> Button:
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).text == text and (b as Button).is_visible_in_tree():
			return b
	return null
