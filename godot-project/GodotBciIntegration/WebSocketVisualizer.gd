# File: WebSocketVisualizer.gd
# Consumes alpha-band amplitude values over WebSocket and maps them to
# the Y-scale of a cube.
# Written in Godot 4.4x
#
# How to Run:
# Start this scene (Play)
# Run the python script (Terminal or Colab)
# Observe the cube pulsating in editor viewport

extends Node3D

## Tunable Parameters
const WS_URL: String = "ws://localhost:8765" # match the python script
const SCALE_BASE: float = 1.0 # resting Y-scale of the cube
const SCALE_MULTIPLIER: float = 10.0 # exaggeration factor of Y-scale changes
const LERP_SPEED: float = 0.1 # speed of lerp function

## Variables
var _ws: WebSocketPeer = WebSocketPeer.new()
@onready var _cube: MeshInstance3D = $Cube

var _latestAlpha: float = 0.0 # store latest value recieved from python script

## Life Cycle

## Setup the scene and initiate connections
func _ready() -> void:
	_ws.connect_to_url(WS_URL)
	print("[GODOT] Connecting to %s ..." % WS_URL)

## Update each frame
## Handle WS polling and Updating cube Y-scale
func _process(delta: float) -> void:
	_pollWebSocket()
	_updateCubeScale()

## Private Func

## Polls WS for new packets, non blocking
func _pollWebSocket() -> void:
	if _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return # not connected
	
	while _ws.get_available_packet_count() > 0:
		var packet = _ws.get_packet().get_string_from_utf8()
		var result = JSON.parse_string(packet)
		if typeof(result) == TYPE_DICTIONARY and result.has("alpha"):
			_latestAlpha = float(result["alpha"])

## Smoothly interpolate the cube Y-scale toward >
## SCALE_BASE + alpha * SCALE_MULTIPLIER
func _updateCubeScale() -> void:
	var target_y = SCALE_BASE + _latestAlpha * SCALE_MULTIPLIER
	var current_scale: Vector3 = _cube.scale
	current_scale.y = lerp(current_scale, target_y, LERP_SPEED)
	_cube.scale = current_scale
