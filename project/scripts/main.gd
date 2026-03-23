## Main - Entry point for Godotty application
## Initializes the terminal system and manages the main scene
class_name Main
extends Control

## Status bar reference
@onready var status_bar: HBoxContainer = $VBoxContainer/StatusBar

## Status labels
@onready var mode_label: Label = $VBoxContainer/StatusBar/ModeLabel
@onready var addon_label: Label = $VBoxContainer/StatusBar/AddonLabel

## Terminal view container
@onready var terminal_container: Control = $VBoxContainer/TerminalContainer


func _ready() -> void:
	# Connect to addon status changes
	SignalBus.addon_status_changed.connect(_on_addon_status_changed)
	
	# Update status bar
	_update_status()
	
	# Set window title
	DisplayServer.window_set_title("Godotty - Terminal Demo")
	
	# Print startup info
	print("=== Godotty Reference App ===")
	print("Mode: %s" % ("Mock" if TerminalManager.is_mock_mode else "Real"))
	print("Addon: %s" % ("Available" if TerminalManager.is_addon_available else "Not Found"))


func _update_status() -> void:
	if mode_label:
		mode_label.text = "MODE: %s" % ("MOCK" if TerminalManager.is_mock_mode else "REAL")
		mode_label.add_theme_color_override("font_color", 
			Color.YELLOW if TerminalManager.is_mock_mode else Color.GREEN)
	
	if addon_label:
		addon_label.text = "ADDON: %s" % ("YES" if TerminalManager.is_addon_available else "NO")
		addon_label.add_theme_color_override("font_color",
			Color.RED if not TerminalManager.is_addon_available else Color.CYAN)


func _on_addon_status_changed(available: bool) -> void:
	_update_status()
