extends Node

func _ready() -> void:
	var night: Node = load("res://scenes/night/night.tscn").instantiate()
	add_child(night)
	await get_tree().process_frame
	var cs: Control = night.get_node("CameraSystem")
	await get_tree().process_frame
	var ro: Animatronic = night.get_node("Animatronics/Rochis")
	var bar: Animatronic = night.get_node("Animatronics/Barcosa")
	for a in [ro, bar]: a.ai_level = 0
	ro.debug_activate()
	cs.open()

	print("=== La foto en los cuatro estados de la CAM 3 ===")
	var casos := [
		["silla vacia (Rochis fuera)", func(): ro._start_coming()],
		["sentado", func(): ro.start(); ro.ai_level = 0; ro._set_stage(ro.Stage.SITTING)],
		["medio", func(): ro._set_stage(ro.Stage.HALF)],
		["de pie", func(): ro._set_stage(ro.Stage.STANDING)],
	]
	for caso in casos:
		caso[1].call()
		cs.switch_to_camera(3)
		cs._refresh_camera_content()
		print("  %-26s estado='%s'  foto encimada=%s  region=%s" % [
			caso[0], cs._state_of(3), cs.camera_overlay.visible, cs.camera_overlay._region])
		print("      imagen de fondo=%s   capa=%s" % [
			cs.feed_image.texture.resource_path.get_file() if cs.feed_image.texture else "ninguna",
			cs.camera_overlay._texture.resource_path.get_file() if cs.camera_overlay._texture else "ninguna"])

	print("=== No se mete en otras camaras ===")
	for cam in [1, 2, 4, 12]:
		cs.switch_to_camera(cam)
		cs._refresh_camera_content()
		var ov: Dictionary = CameraOverlays.overlay_for(cam, cs._state_of(cam), PowerManager.is_door_closed)
		print("  CAM %02d -> encimado='%s'" % [cam, ov.get("image", "nada")])
	print("=== La cortina de la CAM 2 sigue igual ===")
	PowerManager.is_door_closed = true
	cs.switch_to_camera(2)
	cs._refresh_camera_content()
	print("  puerta cerrada -> %s  region=%s" % [
		cs.camera_overlay._texture.resource_path.get_file(), cs.camera_overlay._region])
	bar.debug_activate(); bar.move_to_step(2); bar._state = bar.State.BANGING
	cs._refresh_camera_content()
	print("  Barcosa golpeando -> encimado=%s (la imagen ya la trae)" % cs.camera_overlay.visible)
	PowerManager.is_door_closed = false

	print("=== Sin señal y saturada no llevan nada encima ===")
	GameManager.patch_panel.disconnected.append(3)
	cs.switch_to_camera(3)
	cs._refresh_camera_content()
	print("  CAM 3 sin señal -> foto encimada=%s" % cs.camera_overlay.visible)
	GameManager.patch_panel.disconnected.erase(3)
	cs._refresh_camera_content()
	print("  reconectada -> foto encimada=%s" % cs.camera_overlay.visible)

	print("=== El rectangulo declarado contra lo que pinta la capa ===")
	var img: Image = cs.camera_overlay._texture.get_image()
	var w: int = img.get_width(); var h: int = img.get_height()
	var minx := w; var maxx := 0; var miny := h; var maxy := 0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if img.get_pixel(x, y).a > 0.03:
				minx = mini(minx, x); maxx = maxi(maxx, x)
				miny = mini(miny, y); maxy = maxi(maxy, y)
	print("  la capa pinta:  x %.4f..%.4f  y %.4f..%.4f" % [float(minx)/w, float(maxx+1)/w, float(miny)/h, float(maxy+1)/h])
	var r: Rect2 = CameraOverlays.PHOTO_RECT
	print("  PHOTO_RECT:     x %.4f..%.4f  y %.4f..%.4f" % [r.position.x, r.end.x, r.position.y, r.end.y])
	print("  la capa cabe dentro del rect: %s (por eso se dibuja completa)" % r.encloses(
		Rect2(float(minx)/w, float(miny)/h, float(maxx+1-minx)/w, float(maxy+1-miny)/h)))
	print("  la capa mide %s, igual que cam03_vacia: %s" % [img.get_size(),
		img.get_size() == load("res://assets/art/cameras/cam03_vacia.png").get_size()])
	get_tree().quit()
