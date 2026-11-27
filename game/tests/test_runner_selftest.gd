extends TestCase

func test_assert_eq_records_failure() -> void:
	var t := TestCase.new()
	t.assert_eq(1, 2)
	assert_eq(t.failures.size(), 1)

func test_async_waits_frames() -> void:
	var before := Engine.get_process_frames()
	await wait_frames(3)
	assert_true(Engine.get_process_frames() >= before + 2)
