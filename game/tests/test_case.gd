class_name TestCase
extends RefCounted
## Base class for headless tests run by res://tests/run_tests.gd.
## Assertions record failures instead of stopping the test.

var tree: SceneTree
var failures: PackedStringArray = PackedStringArray()
## Engine errors this test expects to cause (for example, opening a file in a
## missing folder). The runner fails the test on any further errors.
var allowed_errors := 0
var _nodes: Array[Node] = []


func assert_true(c: bool, msg := "") -> void:
	if not c:
		_fail("expected true" + _suffix(msg))


func assert_false(c: bool, msg := "") -> void:
	if c:
		_fail("expected false" + _suffix(msg))


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	if not _equal(actual, expected):
		_fail("expected %s, got %s%s" % [var_to_str(expected), var_to_str(actual), _suffix(msg)])


func assert_near(actual: float, expected: float, eps: float, msg := "") -> void:
	if is_nan(actual) or absf(actual - expected) > eps:
		_fail("expected %s ± %s, got %s%s" % [expected, eps, actual, _suffix(msg)])


func assert_between(x: float, lo: float, hi: float, msg := "") -> void:
	if is_nan(x) or x < lo or x > hi:
		_fail("expected %s to be in [%s, %s]%s" % [x, lo, hi, _suffix(msg)])


func fail(msg: String) -> void:
	_fail(msg)


func allow_errors(count: int) -> void:
	allowed_errors += count


func wait_frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func add_to_tree(n: Node) -> Node:
	tree.root.add_child(n)
	_nodes.append(n)
	return n


## Called by the runner after each test.
func _free_tracked() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()


func _fail(m: String) -> void:
	failures.append(m)


func _suffix(msg: String) -> String:
	return "" if msg.is_empty() else " (" + msg + ")"


func _equal(a: Variant, b: Variant) -> bool:
	var numeric := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numeric and typeof(b) in numeric:
		return a == b
	if typeof(a) != typeof(b):
		return false
	return a == b
