extends Node2D

## Example usage of GodottyNode GDExtension
@onready var terminal = $TerminalNode2D

func _ready() -> void:
    if terminal == null:
        print_error("TerminalNode2D not found! Add the GodottyNode GDExtension to dependencies.")
        return

    terminal.spawn_shell()
    terminal.write_input("echo 'Hello, Godotty!'")

func _process(delta):
    # Example: capture output and log
    while terminal.has_output():
        print(terminal.read_output())