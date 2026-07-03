## TerminalManager -- application-wide default terminal manager (autoload).
## Extends TerminalManagerBase with SignalBus publishing and default-node
## registration. Views connect to SignalBus when using this autoload, or
## directly to TerminalManagerNode signals for per-tab managers.
## Note: No class_name to avoid conflict with autoload singleton name.
extends TerminalManagerBase

## Registered alternative default node (nil = use self).
var _registered_default: Node = null


func _ready() -> void:
	super()

	# Forward instance signals to the global bus so views using the default
	# autoload path (manager == null) receive output, status, and clear events.
	output_received.connect(_forward_output_to_bus)
	shell_started.connect(_forward_shell_started_to_bus)
	shell_stopped.connect(_forward_shell_stopped_to_bus)
	terminal_cleared.connect(_forward_terminal_cleared_to_bus)
	addon_availability_changed.connect(_forward_addon_to_bus)

	SignalBus.terminal_resized.connect(_on_terminal_resized)


func _exit_tree() -> void:
	SignalBus.terminal_resized.disconnect(_on_terminal_resized)


func _forward_output_to_bus(text: String) -> void:
	SignalBus.output_ready.emit(text)


func _forward_shell_started_to_bus() -> void:
	SignalBus.shell_status_changed.emit(true)


func _forward_shell_stopped_to_bus() -> void:
	SignalBus.shell_status_changed.emit(false)


func _forward_terminal_cleared_to_bus() -> void:
	SignalBus.terminal_cleared.emit()


func _forward_addon_to_bus(available: bool) -> void:
	SignalBus.addon_status_changed.emit(available)


## Returns the registered default terminal manager node.
## Returns this autoload itself when no explicit default has been registered.
func get_default() -> Node:
	return _registered_default if _registered_default != null else self


## Register an alternative node as the application-wide default terminal manager.
func set_default(node: Node) -> void:
	_registered_default = node
