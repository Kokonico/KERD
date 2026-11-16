extends Control

const MAIN_MENU_SCENE := "res://Scenes/main_menu.tscn"

const FPS_OPTIONS: Array[int] = [0, 30, 60, 120, 144, 240]
const MSAA_OPTIONS: Array[Viewport.MSAA] = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X]

@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var max_fps_option: OptionButton = %MaxFpsOption
@onready var render_scale_slider: HSlider = %RenderScaleSlider
@onready var render_scale_value: Label = %RenderScaleValue
@onready var msaa_option: OptionButton = %MsaaOption
@onready var fxaa_check: CheckButton = %FxaaCheck
@onready var ssao_check: CheckButton = %SsaoCheck
@onready var ssil_check: CheckButton = %SsilCheck
@onready var glow_check: CheckButton = %GlowCheck
@onready var back_button: Button = %BackButton

func _ready() -> void:
	for fps in FPS_OPTIONS:
		max_fps_option.add_item("Unlimited" if fps == 0 else str(fps))
	for label in ["Off", "2x", "4x", "8x"]:
		msaa_option.add_item(label)

	fullscreen_check.button_pressed = Settings.fullscreen
	vsync_check.button_pressed = Settings.vsync
	max_fps_option.selected = maxi(FPS_OPTIONS.find(Settings.max_fps), 0)
	render_scale_slider.value = Settings.render_scale
	msaa_option.selected = maxi(MSAA_OPTIONS.find(Settings.msaa), 0)
	fxaa_check.button_pressed = Settings.fxaa
	ssao_check.button_pressed = Settings.ssao
	ssil_check.button_pressed = Settings.ssil
	glow_check.button_pressed = Settings.glow
	_update_render_scale_label()

	fullscreen_check.toggled.connect(func(on: bool) -> void: _change_setting("fullscreen", on))
	vsync_check.toggled.connect(func(on: bool) -> void: _change_setting("vsync", on))
	max_fps_option.item_selected.connect(func(i: int) -> void: _change_setting("max_fps", FPS_OPTIONS[i]))
	render_scale_slider.value_changed.connect(_on_render_scale_changed)
	msaa_option.item_selected.connect(func(i: int) -> void: _change_setting("msaa", MSAA_OPTIONS[i]))
	fxaa_check.toggled.connect(func(on: bool) -> void: _change_setting("fxaa", on))
	ssao_check.toggled.connect(func(on: bool) -> void: _change_setting("ssao", on))
	ssil_check.toggled.connect(func(on: bool) -> void: _change_setting("ssil", on))
	glow_check.toggled.connect(func(on: bool) -> void: _change_setting("glow", on))
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()

	Settings.changed.connect(_on_settings_changed)

func _on_settings_changed() -> void:
	fullscreen_check.set_pressed_no_signal(Settings.fullscreen)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		_on_back_pressed()

func _change_setting(setting: StringName, value: Variant) -> void:
	Settings.set(setting, value)
	Settings.apply()

func _on_render_scale_changed(value: float) -> void:
	_change_setting("render_scale", value)
	_update_render_scale_label()

func _update_render_scale_label() -> void:
	render_scale_value.text = "%d%%" % roundi(Settings.render_scale * 100)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
