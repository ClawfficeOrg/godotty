## TerminalManagerNode -- instanceable per-tab terminal manager.
## Contains real and mock terminal logic. Can be instantiated per-tab for
## multi-terminal layouts. Does not auto-subscribe to SignalBus.terminal_resized
## and does NOT broadcast on SignalBus -- consumers connect to this instance's
## own signals (output_received, shell_started/stopped, terminal_cleared).
## The application-wide default is the TerminalManager autoload, which is the
## only SignalBus publisher.
class_name TerminalManagerNode
extends TerminalManagerBase

func _init():
	_manager_label = "TerminalManagerNode"
