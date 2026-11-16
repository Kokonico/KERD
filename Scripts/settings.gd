extends Node

signal changed

var fullscreen := false
var vsync := true
# 0 means unlimited
var max_fps := 0

var render_scale := 1.0
var msaa := Viewport.MSAA_DISABLED
var fxaa := false

var ssao := true
var ssil := true
var glow := true

var _window_was_fullscreen := false

func _ready() -> void:
	fullscreen = _is_window_fullscreen()
	_window_was_fullscreen = fullscreen
	vsync = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	apply()

func _process(_delta: float) -> void:
	var is_fullscreen := _is_window_fullscreen()
	if is_fullscreen == _window_was_fullscreen:
		return
	_window_was_fullscreen = is_fullscreen
	if is_fullscreen != fullscreen:
		fullscreen = is_fullscreen
		changed.emit()

func apply() -> void:
	var target_mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if fullscreen != _is_window_fullscreen():
		DisplayServer.window_set_mode(target_mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = max_fps

	var viewport := get_viewport()
	viewport.scaling_3d_scale = render_scale
	viewport.msaa_3d = msaa
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA if fxaa else Viewport.SCREEN_SPACE_AA_DISABLED

	changed.emit()

func _is_window_fullscreen() -> bool:
	return DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
