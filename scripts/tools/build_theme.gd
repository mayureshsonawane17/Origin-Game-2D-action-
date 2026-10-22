extends SceneTree

func _init() -> void:
	print("[ThemeBuilder] Constructing unified ORIGIN pixel UI theme...")

	var font_ui = load("res://assets/fonts/PixelifySans.ttf") as Font
	var font_header = load("res://assets/fonts/Silkscreen-Regular.ttf") as Font

	var tex_panel_normal = load("res://assets/ui/panel_9slice_normal.png") as Texture2D
	var tex_panel_focus = load("res://assets/ui/panel_9slice_focus.png") as Texture2D
	var tex_btn_normal = load("res://assets/ui/button_normal.png") as Texture2D
	var tex_btn_hover = load("res://assets/ui/button_hover.png") as Texture2D
	var tex_btn_pressed = load("res://assets/ui/button_pressed.png") as Texture2D
	var tex_btn_focus = load("res://assets/ui/button_focus.png") as Texture2D
	var tex_btn_disabled = load("res://assets/ui/button_disabled.png") as Texture2D
	var tex_slider_grabber = load("res://assets/ui/slider_grabber.png") as Texture2D

	var theme = Theme.new()

	# Palette
	var col_text_normal = Color("#ebd2bd")
	var col_text_hover = Color("#ffffff")
	var col_text_focus = Color("#cbefc0")
	var col_text_pressed = Color("#7c5cff")
	var col_text_disabled = Color("#5a6068")
	var col_gold = Color("#ae7e54")
	var col_mint = Color("#cbefc0")
	var col_purple = Color("#7c5cff")
	var col_emerald = Color("#385241")
	var col_bg_dark = Color("#081213")
	var col_border_dim = Color("#2c3640")

	# Fonts
	theme.default_font = font_ui
	theme.default_font_size = 9

	# Button StyleBoxes
	var sb_btn_normal = StyleBoxTexture.new()
	sb_btn_normal.texture = tex_btn_normal
	sb_btn_normal.texture_margin_left = 3
	sb_btn_normal.texture_margin_top = 3
	sb_btn_normal.texture_margin_right = 3
	sb_btn_normal.texture_margin_bottom = 3
	sb_btn_normal.content_margin_left = 6
	sb_btn_normal.content_margin_right = 6
	sb_btn_normal.content_margin_top = 4
	sb_btn_normal.content_margin_bottom = 4

	var sb_btn_hover = StyleBoxTexture.new()
	sb_btn_hover.texture = tex_btn_hover
	sb_btn_hover.texture_margin_left = 3
	sb_btn_hover.texture_margin_top = 3
	sb_btn_hover.texture_margin_right = 3
	sb_btn_hover.texture_margin_bottom = 3
	sb_btn_hover.content_margin_left = 6
	sb_btn_hover.content_margin_right = 6
	sb_btn_hover.content_margin_top = 4
	sb_btn_hover.content_margin_bottom = 4

	var sb_btn_pressed = StyleBoxTexture.new()
	sb_btn_pressed.texture = tex_btn_pressed
	sb_btn_pressed.texture_margin_left = 3
	sb_btn_pressed.texture_margin_top = 3
	sb_btn_pressed.texture_margin_right = 3
	sb_btn_pressed.texture_margin_bottom = 3
	sb_btn_pressed.content_margin_left = 6
	sb_btn_pressed.content_margin_right = 6
	sb_btn_pressed.content_margin_top = 4
	sb_btn_pressed.content_margin_bottom = 4

	var sb_btn_focus = StyleBoxTexture.new()
	sb_btn_focus.texture = tex_btn_focus
	sb_btn_focus.texture_margin_left = 3
	sb_btn_focus.texture_margin_top = 3
	sb_btn_focus.texture_margin_right = 3
	sb_btn_focus.texture_margin_bottom = 3
	sb_btn_focus.content_margin_left = 6
	sb_btn_focus.content_margin_right = 6
	sb_btn_focus.content_margin_top = 4
	sb_btn_focus.content_margin_bottom = 4

	var sb_btn_disabled = StyleBoxTexture.new()
	sb_btn_disabled.texture = tex_btn_disabled
	sb_btn_disabled.texture_margin_left = 3
	sb_btn_disabled.texture_margin_top = 3
	sb_btn_disabled.texture_margin_right = 3
	sb_btn_disabled.texture_margin_bottom = 3
	sb_btn_disabled.content_margin_left = 6
	sb_btn_disabled.content_margin_right = 6
	sb_btn_disabled.content_margin_top = 4
	sb_btn_disabled.content_margin_bottom = 4

	# Assign to Button
	theme.set_stylebox("normal", "Button", sb_btn_normal)
	theme.set_stylebox("hover", "Button", sb_btn_hover)
	theme.set_stylebox("pressed", "Button", sb_btn_pressed)
	theme.set_stylebox("focus", "Button", sb_btn_focus)
	theme.set_stylebox("disabled", "Button", sb_btn_disabled)

	theme.set_color("font_color", "Button", col_text_normal)
	theme.set_color("font_hover_color", "Button", col_text_hover)
	theme.set_color("font_pressed_color", "Button", col_text_pressed)
	theme.set_color("font_focus_color", "Button", col_text_focus)
	theme.set_color("font_disabled_color", "Button", col_text_disabled)
	theme.set_font("font", "Button", font_ui)

	# Panel & PanelContainer StyleBoxes
	var sb_panel_normal = StyleBoxTexture.new()
	sb_panel_normal.texture = tex_panel_normal
	sb_panel_normal.texture_margin_left = 4
	sb_panel_normal.texture_margin_top = 4
	sb_panel_normal.texture_margin_right = 4
	sb_panel_normal.texture_margin_bottom = 4
	sb_panel_normal.content_margin_left = 6
	sb_panel_normal.content_margin_top = 6
	sb_panel_normal.content_margin_right = 6
	sb_panel_normal.content_margin_bottom = 6

	theme.set_stylebox("panel", "Panel", sb_panel_normal)
	theme.set_stylebox("panel", "PanelContainer", sb_panel_normal)

	# Label styling
	theme.set_color("font_color", "Label", col_text_normal)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.7))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font("font", "Label", font_ui)

	# HSlider styling
	var sb_slider_bg = StyleBoxFlat.new()
	sb_slider_bg.bg_color = col_bg_dark
	sb_slider_bg.border_width_left = 1
	sb_slider_bg.border_width_top = 1
	sb_slider_bg.border_width_right = 1
	sb_slider_bg.border_width_bottom = 1
	sb_slider_bg.border_color = col_border_dim
	sb_slider_bg.content_margin_top = 3
	sb_slider_bg.content_margin_bottom = 3

	var sb_slider_fill = StyleBoxFlat.new()
	sb_slider_fill.bg_color = col_emerald
	sb_slider_fill.content_margin_top = 3
	sb_slider_fill.content_margin_bottom = 3

	theme.set_stylebox("slider", "HSlider", sb_slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", sb_slider_fill)
	theme.set_stylebox("grabber_area_highlight", "HSlider", sb_slider_fill)
	theme.set_icon("grabber", "HSlider", tex_slider_grabber)
	theme.set_icon("grabber_highlight", "HSlider", tex_slider_grabber)

	# CheckBox styling
	theme.set_color("font_color", "CheckBox", col_text_normal)
	theme.set_color("font_hover_color", "CheckBox", col_text_hover)
	theme.set_color("font_pressed_color", "CheckBox", col_mint)

	# ProgressBar
	var sb_pbar_bg = StyleBoxFlat.new()
	sb_pbar_bg.bg_color = col_bg_dark
	sb_pbar_bg.border_width_left = 1
	sb_pbar_bg.border_width_top = 1
	sb_pbar_bg.border_width_right = 1
	sb_pbar_bg.border_width_bottom = 1
	sb_pbar_bg.border_color = col_border_dim

	var sb_pbar_fill = StyleBoxFlat.new()
	sb_pbar_fill.bg_color = col_mint

	theme.set_stylebox("background", "ProgressBar", sb_pbar_bg)
	theme.set_stylebox("fill", "ProgressBar", sb_pbar_fill)

	# Save theme to disk
	DirAccess.make_dir_recursive_absolute("data/theme")
	var err = ResourceSaver.save(theme, "res://data/theme/origin_theme.tres")
	if err == OK:
		print("[ThemeBuilder] Successfully saved unified theme to res://data/theme/origin_theme.tres")
	else:
		printerr("[ThemeBuilder] Failed to save theme: ", err)

	quit(0)
