class_name SignalUtil
extends Node

static func try_connect_signal(node: Node, signal_name: String, callable: Callable):
	if not node:
		printerr("[SignalUtil] ERROR: Attempted to connect signal on a null node.")
		return

	if node.has_signal(signal_name):
		if not node.is_connected(signal_name, callable):
			node.connect(signal_name, callable)
			print("[SignalUtil] Connected signal: %s on %s to %s" % [signal_name, node.name, callable.get_object().name])
		else:
			print("[SignalUtil] Signal already connected: %s on %s to %s" % [signal_name, node.name, callable.get_object().name])
	else:
		printerr("[SignalUtil] ERROR: Node does not have signal: ", signal_name, " on ", node.name)
