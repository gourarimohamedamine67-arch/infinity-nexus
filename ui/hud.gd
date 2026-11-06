extends CanvasLayer
## Interface en jeu : barre rapide (toujours visible) et inventaire (Tab).
## Gère aussi l'état de la souris quand un menu est ouvert :
## menu ouvert = souris libre et contrôles du joueur coupés ; Échap ou Tab referme le menu.

const SlotUI = preload("res://ui/slot_ui.gd")
const Items = preload("res://items.gd")

signal menu_toggled(open: bool)

var player: CharacterBody3D
var inventory: Inventory
var hotbar_slots: Array = []
var backpack_slots: Array = []
var inventory_panel: PanelContainer
var item_name_label: Label
var item_name_timer := 0.0
var menu_open := false

func _ready():
	add_to_group("hud")
	layer = 5   # sous le fondu au noir (10)

## Branche l'interface sur le joueur (appelé par game.gd).
func setup(p: CharacterBody3D):
	player = p
	inventory = p.inventory
	_build_hotbar()
	_build_inventory_panel()
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
	item_name_label.offset_top = -SlotUI.SIZE - 50
	item_name_label.offset_bottom = -SlotUI.SIZE - 22
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

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	inventory_panel.add_child(box)
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
	help.text = "Glisser-déposer pour ranger · la barre rapide (en bas) fait partie de l'inventaire · Tab ou Échap pour fermer"
	help.add_theme_font_size_override("font_size", 13)
	help.modulate = Color(1, 1, 1, 0.7)
	box.add_child(help)

# --- Mise à jour ---

func _refresh_all():
	for s in hotbar_slots + backpack_slots:
		s.refresh()
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
