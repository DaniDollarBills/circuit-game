extends TestCase


func _circuit_with(n: int) -> Circuit:
	var c := Circuit.new()
	c.parts.append(Part.make("R%d" % n, "resistor", n, 0))
	return c


func test_commit_undo_redo() -> void:
	var a := _circuit_with(1)
	var b := _circuit_with(2)
	var h := CircuitHistory.new(a)
	assert_false(h.can_undo())
	h.commit(b)
	assert_eq(h.present, b)
	assert_true(h.undo())
	assert_eq(h.present, a)
	assert_true(h.can_redo())
	assert_true(h.redo())
	assert_eq(h.present, b)


func test_commit_after_undo_clears_future() -> void:
	var h := CircuitHistory.new(_circuit_with(1))
	h.commit(_circuit_with(2))
	h.undo()
	h.commit(_circuit_with(3))
	assert_false(h.can_redo())


func test_commit_same_instance_is_ignored() -> void:
	var a := _circuit_with(1)
	var h := CircuitHistory.new(a)
	h.commit(a)
	assert_false(h.can_undo())


func test_limit_100() -> void:
	var h := CircuitHistory.new(_circuit_with(0))
	for i in 101:
		h.commit(_circuit_with(i + 1))
	var undos := 0
	while h.undo():
		undos += 1
	assert_eq(undos, 100)


func test_undo_empty_returns_false() -> void:
	var h := CircuitHistory.new(_circuit_with(1))
	assert_false(h.undo())
	assert_false(h.redo())
