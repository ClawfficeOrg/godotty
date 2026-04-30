## SignalBus - Global event bus for godotty
## Provides decoupled communication between components
## Note: No class_name to avoid conflict with autoload singleton name
extends Node

## Emitted when a command is submitted
signal command_submitted(command: String)

## Emitted when terminal output is ready to display
signal output_ready(text: String)

## Emitted when terminal is cleared
signal terminal_cleared()

## Emitted when godotty-node availability changes
signal addon_status_changed(available: bool)

## Emitted when shell status changes
signal shell_status_changed(running: bool)
