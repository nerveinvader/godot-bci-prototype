# File: WebSocketVisualizer.gd
# Consumes alpha-band amplitude values over WebSocket and maps them to
# the Y-scale of a cube.
# Written in Godot 4.4x
#
# How to Run:
# Run the python script (Terminal or Colab)
# Start this scene (Play)
# Observe the cube pulsating in editor viewport

extends Node3D

## Tunable Parameters
const WS_URL: String = "ws://localhost:8765" # match the python script
const SCALE_BASE: float = 1.0 # resting Y-scale of the cube
const SCALE_MULTIPLIER: float = 100000.0 # exaggeration factor of Y-scale changes
const LERP_SPEED: float = 0.1 # speed of lerp function

## Variables
var _ws: WebSocketPeer # client in GODOT
@onready var _cube: MeshInstance3D = $Cube
@onready var _label: Label = $CanvasLayer/Label

var _latestAlpha: float = 0.0 # store latest value recieved from python script

## Life Cycle

## Setup the scene and initiate connections
func _ready() -> void:
	_ws = WebSocketPeer.new()
	var err := _ws.connect_to_url(WS_URL)
	if err != OK:
		push_error("WebSocket Connect Error: d%" % err)
	else:
		print("[GODOT] Connecting to %s ..." % WS_URL)

## Update each frame
## Handle WS polling and Updating cube Y-scale
func _process(_delta: float) -> void:
	_ws.poll()
	
	if _ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_pollWebSocket()
		_updateCubeScale()

## Private Func

## Polls WS for new packets, non blocking
func _pollWebSocket() -> void:
	while _ws.get_available_packet_count() > 0:
		var packet = _ws.get_packet().get_string_from_utf8()
		var result = JSON.parse_string(packet)
		if typeof(result) == TYPE_DICTIONARY and result.has("alpha"):
			_latestAlpha = float(result["alpha"])
			_label.text = "alpha:" + str(_latestAlpha)

## Smoothly interpolate the cube Y-scale toward >
## SCALE_BASE + alpha * SCALE_MULTIPLIER
func _updateCubeScale() -> void:
	var target_y = SCALE_BASE + _latestAlpha * SCALE_MULTIPLIER
	var currentScale: Vector3 = _cube.scale
	currentScale.y = lerp(currentScale.y, target_y, LERP_SPEED)
	_cube.scale = currentScale
