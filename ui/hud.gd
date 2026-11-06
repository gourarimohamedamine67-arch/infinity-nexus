extends CanvasLayer
## Interface en jeu : barre rapide (toujours visible) et inventaire (Tab).
## Gère aussi l'état de la souris quand un menu est ouvert :
## menu ouvert = souris libre et contrôles du joueur coupés ; Échap ou Tab referme le menu.

const SlotUI = preload("res://ui/slot_ui.gd")
const Recipes = preload("res://recipes.gd")
const Items = preload("res://items.gd")
const Families = preload("res://families.gd")
const WEATHER_NAMES = ["Temps clair", "Pluie", "Neige", "Brume"]

signal menu_toggled(open: bool)

var player: CharacterBody3D
var inventory: Inventory
var hotbar_slots: Array = []
var backpack_slots: Array = []
var inventory_panel: PanelContainer
var item_name_label: Label
var item_name_timer := 0.0
var menu_open := false
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var stamina_fill: StyleBoxFlat
var banner: VBoxContainer
var banner_title: Label
var banner_subtitle: Label
var banner_tween: Tween
var messages: VBoxContainer
var craft_list: VBoxContainer
var craft_hint: Label

func _ready():
	add_to_group("hud")
	layer = 5   # sous le fondu au noir (10)

## Branche l'interface sur le joueur (appelé par game.gd).
func setup(p: CharacterBody3D):
	player = p
	inventory = p.inventory
	_build_hotbar()
	_build_inventory_panel()
	_build_status_bars()
	_build_banner()
	_build_messages()
	p.health_changed.connect(func(v, m): health_bar.max_value = m; health_bar.value = v)
	p.stamina_changed.connect(_on_stamina_changed)
	inventory.changed.connect(_refresh_all)
	inventory.selected_changed.connect(_on_selected_changed)
	_on_selected_changed(inventory.selected)

# --- Construction de l'interface ---

func _build_hotbar():
	var bar = HBoxContainer.new()
	bar.name = "Hotbar"
	bar.add_theme_constant_override("separation", 6)
	bar.anchor_left = 0.5
	bar.anchor_right = 0.5
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	var width = Inventory.HOTBAR_SIZE * (SlotUI.SIZE + 6) - 6
	bar.offset_left = -width / 2.0
	bar.offset_right = width / 2.0
	bar.offset_top = -SlotUI.SIZE - 16
	bar.offset_bottom = -16
	add_child(bar)
	for i in Inventory.HOTBAR_SIZE:
		var slot = SlotUI.new()
		bar.add_child(slot)
		slot.setup(inventory, i)
		hotbar_slots.append(slot)

	item_name_label = Label.new()
	item_name_label.anchor_left = 0.5
	item_name_label.anchor_right = 0.5
	item_name_label.anchor_top = 1.0
	item_name_label.anchor_bottom = 1.0
	item_name_label.offset_left = -200
	item_name_label.offset_right = 200
	item_name_label.offset_top = -SlotUI.SIZE - 76
	item_name_label.offset_bottom = -SlotUI.SIZE - 48
	item_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name_label.add_theme_font_size_override("font_size", 18)
	item_name_label.add_theme_constant_override("outline_size", 5)
	item_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(item_name_label)

func _build_inventory_panel():
	inventory_panel = PanelContainer.new()
	inventory_panel.name = "InventoryPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.02, 0.08, 0.9)
	style.border_color = Color(0.55, 0.4, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	inventory_panel.add_theme_stylebox_override("panel", style)
	inventory_panel.set_anchors_preset(Control.PRESET_CENTER)
	inventory_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	inventory_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	inventory_panel.visible = false
	add_child(inventory_panel)

	var columns = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	inventory_panel.add_child(columns)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	columns.add_child(box)
	var title = Label.new()
	title.text = "Inventaire"
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)
	for i in Inventory.BACKPACK_SIZE:
		var slot = SlotUI.new()
		grid.add_child(slot)
		slot.setup(inventory, Inventory.HOTBAR_SIZE + i)
		backpack_slots.append(slot)
	var help = Label.new()
	help.text = "Glisser-déposer pour ranger · la barre rapide (en bas)\nfait partie de l'inventaire · Tab ou Échap pour fermer"
	help.add_theme_font_size_override("font_size", 13)
	help.modulate = Color(1, 1, 1, 0.7)
	box.add_child(help)
	_build_craft_column(columns)

func _build_craft_column(parent: Control):
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(330, 0)
	col.add_theme_constant_override("separation", 8)
	parent.add_child(col)
	var title = Label.new()
	title.text = "Fabrication"
	title.add_theme_font_size_override("font_size", 22)
	col.add_child(title)
	craft_hint = Label.new()
	craft_hint.add_theme_font_size_override("font_size", 13)
	craft_hint.modulate = Color(1, 1, 1, 0.7)
	col.add_child(craft_hint)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(330, 230)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	craft_list = VBoxContainer.new()
	craft_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	craft_list.add_theme_constant_override("separation", 6)
	scroll.add_child(craft_list)

## Redessine la liste des recettes connues (ingrédients en vert si on les a, en rouge sinon).
func _refresh_crafting():
	if craft_list == null or not menu_open:
		return
	for c in craft_list.get_children():
		c.queue_free()
	var near = player.is_near_workbench()
	craft_hint.text = "Établi à proximité : recettes avancées disponibles" if near \
		else "Recettes avancées : approchez-vous d'un établi"
	var known = Recipes.known(player.discovered)
	if known.is_empty():
		var none = Label.new()
		none.text = "Aucune recette connue.\nRécoltez des ressources pour en découvrir."
		none.modulate = Color(1, 1, 1, 0.6)
		craft_list.add_child(none)
	for recipe in known:
		craft_list.add_child(_recipe_row(recipe, near))

func _recipe_row(recipe: RecipeData, near: bool) -> Control:
	var item = Items.get_item(recipe.result)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var swatch = ColorRect.new()
	swatch.color = item.icon_color
	swatch.custom_minimum_size = Vector2(26, 26)
	row.add_child(swatch)
	var text = VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var name_label = Label.new()
	name_label.text = item.display_name + ("  (établi)" if recipe.requires_workbench else "")
	name_label.add_theme_font_size_override("font_size", 15)
	text.add_child(name_label)
	var parts = []
	for id in recipe.ingredients:
		var need: int = recipe.ingredients[id]
		var have = inventory.count_of(id)
		var color = "8f8" if have >= need else "f88"
		parts.append("[color=#%s]%d/%d %s[/color]" % [color, min(have, need), need, Items.get_item(id).display_name])
	var ing = RichTextLabel.new()
	ing.bbcode_enabled = true
	ing.fit_content = true
	ing.scroll_active = false
	ing.text = ", ".join(parts)
	ing.add_theme_font_size_override("normal_font_size", 13)
	text.add_child(ing)
	var button = Button.new()
	button.text = "Fabriquer"
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not Recipes.can_craft(recipe, inventory, near)
	button.pressed.connect(func(): player.craft(recipe))
	row.add_child(button)
	return row

func _build_status_bars():
	# Juste au-dessus de la barre rapide : vie à gauche, endurance à droite (aucun chevauchement
	# quelle que soit la résolution)
	var box = HBoxContainer.new()
	box.name = "StatusBars"
	box.add_theme_constant_override("separation", 12)
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 1.0
	box.anchor_bottom = 1.0
	var half = (Inventory.HOTBAR_SIZE * (SlotUI.SIZE + 6) - 6) / 2.0
	box.offset_left = -half
	box.offset_right = half
	box.offset_top = -SlotUI.SIZE - 16 - 30
	box.offset_bottom = -SlotUI.SIZE - 16 - 8
	add_child(box)
	health_bar = _make_bar(box, "Vie", Color(0.85, 0.18, 0.25))
	stamina_bar = _make_bar(box, "Endurance", Color(0.95, 0.8, 0.25))
	stamina_fill = stamina_bar.get_theme_stylebox("fill")
	health_bar.max_value = player.MAX_HEALTH
	health_bar.value = player.health
	stamina_bar.max_value = player.MAX_STAMINA
	stamina_bar.value = player.stamina

func _make_bar(parent: Control, caption: String, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(200, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.show_percentage = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.04, 0.1, 0.75)
	bg.border_color = Color(0.45, 0.35, 0.7, 0.8)
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(5)
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	var label = Label.new()
	label.text = caption
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	bar.add_child(label)
	parent.add_child(bar)
	return bar

func _build_banner():
	banner = VBoxContainer.new()
	banner.name = "ArrivalBanner"
	banner.anchor_left = 0.5
	banner.anchor_right = 0.5
	banner.offset_left = -400
	banner.offset_right = 400
	banner.offset_top = 40
	banner.offset_bottom = 130
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.modulate.a = 0.0
	add_child(banner)
	banner_title = Label.new()
	banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_title.add_theme_font_size_override("font_size", 38)
	banner_title.add_theme_constant_override("outline_size", 8)
	banner_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	banner.add_child(banner_title)
	banner_subtitle = Label.new()
	banner_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_subtitle.add_theme_font_size_override("font_size", 20)
	banner_subtitle.add_theme_constant_override("outline_size", 6)
	banner_subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	banner.add_child(banner_subtitle)

## Bandeau d'arrivée : nom du monde, famille, danger (étoiles) et météo.
func show_arrival(data: WorldData):
	banner_title.text = data.display_name
	if data.danger == 0:
		banner_subtitle.text = "Zone sûre"
	else:
		var stars = "★".repeat(data.danger) + "☆".repeat(5 - data.danger)
		banner_subtitle.text = "%s  ·  Danger %s  ·  %s" % [Families.name_of(data.family), stars, WEATHER_NAMES[data.weather]]
	banner_title.add_theme_color_override("font_color", Families.CRYSTAL_COLORS[data.family].lightened(0.35) if data.danger > 0 else Color.WHITE)
	if banner_tween:
		banner_tween.kill()
	banner_tween = create_tween()
	banner_tween.tween_interval(0.4)   # laisse le fondu au noir se terminer
	banner_tween.tween_property(banner, "modulate:a", 1.0, 0.6)
	banner_tween.tween_interval(3.0)
	banner_tween.tween_property(banner, "modulate:a", 0.0, 1.0)

func _build_messages():
	messages = VBoxContainer.new()
	messages.name = "Messages"
	messages.anchor_left = 1.0
	messages.anchor_right = 1.0
	messages.anchor_top = 1.0
	messages.anchor_bottom = 1.0
	messages.offset_left = -420
	messages.offset_right = -24
	messages.offset_top = -260
	messages.offset_bottom = -24
	messages.alignment = BoxContainer.ALIGNMENT_END
	messages.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(messages)

## Petit message en bas à droite (« +3 Pierre », « Il faut une pioche »…), qui s'efface seul.
func show_message(text: String, color: Color = Color.WHITE):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # les longs messages passent à la ligne
	label.custom_minimum_size.x = 396
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	messages.add_child(label)
	while messages.get_child_count() > 6:
		messages.get_child(0).free()   # garde les 6 derniers
	var tween = label.create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)

func _on_stamina_changed(value: float, max_value: float, exhausted: bool):
	stamina_bar.max_value = max_value
	stamina_bar.value = value
	# Essoufflé : la barre passe à l'orange tant que la course est bloquée
	stamina_fill.bg_color = Color(0.95, 0.45, 0.15) if exhausted else Color(0.95, 0.8, 0.25)

# --- Mise à jour ---

func _refresh_all():
	for s in hotbar_slots + backpack_slots:
		s.refresh()
	_refresh_crafting()
	_show_selected_name()

func _on_selected_changed(index: int):
	for i in hotbar_slots.size():
		hotbar_slots[i].set_selected(i == index)
	_show_selected_name()

func _show_selected_name():
	var item = inventory.selected_item()
	item_name_label.text = item.display_name if item else ""
	item_name_timer = 1.5
	item_name_label.modulate.a = 1.0

func _process(delta):
	if item_name_timer > 0.0:
		item_name_timer -= delta
		if item_name_timer < 0.5:
			item_name_label.modulate.a = max(item_name_timer / 0.5, 0.0)

# --- Menus et souris ---

func is_menu_open() -> bool:
	return menu_open

func set_inventory_open(open: bool):
	menu_open = open
	inventory_panel.visible = open
	_refresh_crafting()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED)
	menu_toggled.emit(open)

func _input(event):
	if event.is_action_pressed("inventory"):
		set_inventory_open(not menu_open)
		get_viewport().set_input_as_handled()
	elif menu_open and event.is_action_pressed("ui_cancel"):
		set_inventory_open(false)   # Échap ferme le menu sans libérer la souris
		get_viewport().set_input_as_handled()

func _unhandled_input(event):
	# Barre rapide : touches 1-9 (position physique, donc aussi sur AZERTY) et molette
	if event is InputEventKey and event.pressed and not event.echo:
		var k = event.physical_keycode
		if k >= KEY_1 and k <= KEY_9:
			inventory.select(k - KEY_1)
			get_viewport().set_input_as_handled()
		elif k == KEY_F1 and OS.is_debug_build():
			_debug_give_items()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and not menu_open \
			and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			inventory.select(inventory.selected + 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			inventory.select(inventory.selected - 1)

## Debug (F1, uniquement en mode debug) : donne quelques ressources de chaque sorte.
func _debug_give_items():
	for item in Items.all():
		inventory.add(item.id, 7 if item.rarity == 0 else 2)
	print("Debug : ressources ajoutées à l'inventaire")
