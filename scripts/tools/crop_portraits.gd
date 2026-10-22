extends SceneTree

func _init() -> void:
	var img = Image.load_from_file("docs/reference/riya_character_sheet.png")
	if not img:
		printerr("Failed to load reference image")
		quit(1)
		return

	print("Image size: %d x %d" % [img.get_width(), img.get_height()])

	# The EXPRESSIONS section is in the top-right corner.
	# Let's inspect the layout:
	# Total width 1536, Total height 1024.
	# Top right box spans from roughly x = 1100 to 1515, y = 60 to 305.
	# There are 4 columns and 2 rows of square/rounded portrait cards.
	# Card width ~90-95px, height ~110-115px.
	# Let's write out a slice of that area to check.
	var preview = img.get_region(Rect2i(1090, 50, 430, 260))
	DirAccess.make_dir_recursive_absolute("assets/ui/portraits")
	preview.save_png("assets/ui/portraits/expressions_preview.png")
	print("Saved expressions_preview.png")

	# Detailed portrait grid coordinates:
	# Row 1: y ≈ 65, height ≈ 112
	# Row 2: y ≈ 185, height ≈ 112
	# Col 1: x ≈ 1102, width ≈ 96
	# Col 2: x ≈ 1206, width ≈ 96
	# Col 3: x ≈ 1309, width ≈ 96
	# Col 4: x ≈ 1412, width ≈ 96

	var names = [
		"riya_neutral", "riya_happy", "riya_shocked", "riya_thoughtful",
		"riya_determined", "riya_concerned", "riya_warm", "riya_disappointed"
	]

	var col_xs = [1102, 1206, 1309, 1412]
	var row_ys = [66, 185]
	var w = 96
	var h = 112

	var idx = 0
	for r in range(2):
		for c in range(4):
			var x = col_xs[c]
			var y = row_ys[r]
			var portrait = img.get_region(Rect2i(x, y, w, h))
			portrait.save_png("assets/ui/portraits/%s.png" % names[idx])
			print("Saved assets/ui/portraits/%s.png (%d,%d %dx%d)" % [names[idx], x, y, w, h])
			idx += 1

	quit(0)
