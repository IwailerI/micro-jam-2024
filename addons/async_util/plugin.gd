@tool
class_name AsyncUtil
extends EditorPlugin

## Awaits all signals or callable objects in [param objects] in any completion
## order.[br]
## - [param objects] - objects that need to be awaited. They can be either
## [Signal]s or async [Callable]s that take 0 arguments.
static func await_all(objects: Array[Variant]) -> void:
    await AwaitAll.new(objects).completed

## Awaits any of signals or callable objects in [param objects] in any
## completion order, returns the index of the first completed object.[br]
## - [param objects] - objects that need to be awaited. They can be either
## [Signal]s or async [Callable]s that take 0 arguments.
static func await_any(objects: Array[Variant]) -> int:
    return await AwaitAny.new(objects).work()

## Awaits the given callable or signal for certain duration. After that duration
## returns control. Returns whether callable has completed.[br]
## - [param object]: either [Callable] or [Signal], to be awaited.[br]
## - [param time]: duration in seconds to wait for.[br]
## - [param process_always], [param process_in_physics],
##  [param ignore_time_scale] are exactly the same as in
## [method SceneTree.create_timer]
static func timeout(
    object: Variant,
    time: float,
    process_always:=true,
    process_in_physics:=false,
    ignore_time_scale:=false,
) -> bool:
    assert(object is Signal or object is Callable,
            "object must be callable or a signal")
    return await AwaitAny.new([object]).or_timeout(time,
            process_always, process_in_physics, ignore_time_scale).work()

## Utility class to await all objects in a group.
##
## Await all should be created with [method new]. Optional timeout can be
## provided with [method and_timeout]. Signal [signal completed] will be emitted
## when all objects are awaited.
class AwaitAll:
    ## Emitted when all objects have completed.
    signal completed
    ## Should not be modified. Number of object not yet completed.
    var left: int

    func _init(objects: Array[Variant]) -> void:
        var bad: int = 0
        for object: Variant in objects:
            if object is Signal:
                var sig: Signal = object
                sig.connect(_report_completed, CONNECT_ONE_SHOT|CONNECT_REFERENCE_COUNTED)
            elif object is Callable:
                call_deferred("_run", object)
            else:
                bad += 1
                push_error("Object %s is not Callable or Signal, it will be ignored" % object)
        left = objects.size() - bad

    ## Adds timeout to this object. This guaranties that the given duration will
    ## pass regardless of time of execution of other objects.
    func and_timeout(
        timeout: float,
        process_always:=true,
        process_in_physics:=false,
        ignore_time_scale:=false,
    ) -> AwaitAll:
        var tree := Engine.get_main_loop() as SceneTree
        assert(tree, "invalid main loop type")
        tree.create_timer(timeout, process_always, process_in_physics,
                ignore_time_scale).timeout.connect(_report_completed)
        left += 1

        return self

    func _run(callable: Callable) -> void:
        await callable.call()
        _report_completed()

    func _report_completed() -> void:
        left = maxi(left - 1, 0)
        if left == 0:
            completed.emit()

## Utility class to await first object in a group.
##
## Await any should be created with [method new]. Optional timeout can be
## provided with [method or_timeout]. Signal [signal completed] will be emitted
## when all objects are awaited.
class AwaitAny:
    ## Emitted as soon as any objects completes. Contains index of the completed
    ## object.
    signal completed(index: int)
    ## Emitted right after [signal completed].
    signal after_completed
    ## Whether any object has completed.
    var done := false
    var _len: int

    func _init(objects: Array[Variant]) -> void:
        _len = objects.size()
        for i: int in objects.size():
            if objects[i] is Signal:
                var sig: Signal = objects[i]
                sig.connect(_report_completed.bind(i), CONNECT_ONE_SHOT|CONNECT_REFERENCE_COUNTED)
            elif objects[i] is Callable:
                call_deferred("_run", objects[i], i)
            else:
                push_error("Object %s is not Callable or Signal, it will be ignored" % objects[i])

    func or_timeout(
        timeout: float,
        process_always:=true,
        process_in_physics:=false,
        ignore_time_scale:=false,
    ) -> AwaitAny:
        var tree := Engine.get_main_loop() as SceneTree
        assert(tree, "invalid main loop type")
        _len += 1
        (tree.create_timer(timeout, process_always, process_in_physics,
                ignore_time_scale)
                .timeout.connect(_report_completed.bind(_len - 1)))
        return self

    ## Async method. Awaiting this is equivalent to awaiting [signal completed],
    ## awaiting [signal after_completed] and returning provided index.
    func work() -> int:
        var return_index: int = -1
        var c := func(i: int) -> void:
            return_index = i

        completed.connect(c, CONNECT_ONE_SHOT)
        await after_completed
        return return_index

    func _run(callable: Callable, index: int) -> void:
        await callable.call()
        if not done:
            _report_completed(index)

    func _report_completed(index: int) -> void:
        assert(index >= 0 and index < _len, "invalid index")

        if done:
            return
        done = true
        completed.emit(index)
        after_completed.emit()
