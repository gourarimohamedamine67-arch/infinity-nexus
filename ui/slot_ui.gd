extends Panel
## Une case d'inventaire affichée : icône (carré coloré + abréviation), quantité,
## glisser-déposer vers une autre case. Info-bulle : nom + description.

const Items = preload("res://items.gd")
const SIZE = 56

var inventory: Inventory
var index := 0
var icon: ColorRect
var icon_texture: TextureRect
var short_label: Label
var count_label: Label
var style_normal: StyleBoxFlat
var style_selected: StyleBoxFlat

func setup(inv: Inventory, slot_index: int):
	inventory = inv
	index = slot_index
	custom_minimum_size = Vector2(SIZE, SIZE)
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP

	style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.05, 0.04, 0.1, 0.75)
	style_normal.border_color = Color(0.45, 0.35, 0.7, 0.8)
	style_normal.set_border_width_all(2)
	style_normal.set_corner_radius_all(6)
	style_selected = style_normal.duplicate()
	style_selected.border_color = Color(1.0, 0.85, 0.4)
	style_selected.set_border_width_all(3)
	add_theme_stylebox_override("panel", style_normal)

	icon = ColorRect.new()
	icon.position = Vector2(10, 10)
	icon.size = Vector2(SIZE - 20, SIZE - 20)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	icon_texture = TextureRect.new()
	icon_texture.position = icon.position
	icon_texture.size = icon.size
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	short_label = _make_label(HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 15)
	short_label.add_theme_color_override("font_color", Color(0, 0, 0, 0.8))
	count_label = _make_label(HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM, 14)
	count_label.add_theme_constant_override("outline_size", 4)
	count_label.add_theme_color_override("font_outline_color", Color.BLACK)
	refresh()

func _make_label(h_align, v_align, font_size: int) -> Label:
	var l = Label.new()
	l.position = Vector2(2, 0)
	l.size = Vector2(SIZE - 6, SIZE - 2)
	l.horizontal_alignment = h_align
	l.vertical_alignment = v_align
	l.add_theme_font_size_override("font_size", font_size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func set_selected(on: bool):
	add_theme_stylebox_override("panel", style_selected if on else style_normal)

## Redessine la case d'après l'inventaire.
func refresh():
	var s = inventory.get_slot(index)
	var item: ItemData = null if s.is_empty() else Items.get_item(s.id)
	icon.visible = item != null and item.icon == null
	icon_texture.visible = item != null and item.icon != null
	short_label.visible = icon.visible
	if item:
		icon.color = item.icon_color
		icon_texture.texture = item.icon
		short_label.text = item.short_name if item.short_name != "" else abbreviation(item.display_name)
		count_label.text = str(s.count) if s.count > 1 else ""
		tooltip_text = "%s\n%s" % [item.display_name, item.description]
	else:
		count_label.text = ""
		tooltip_text = ""

## « Cristal de Braise » -> « Br », « Pierre » -> « Pi » (2 lettres du dernier mot).
static func abbreviation(display_name: String) -> String:
	var words = display_name.replace("'", " ").split(" ", false)
	var last: String = words[words.size() - 1] if words.size() > 0 else "?"
	return last.substr(0, 2).capitalize()

# --- Glisser-déposer (géré par Godot) ---

func _get_drag_data(_at_position: Vector2):
	if inventory.is_empty_slot(index):
		return null
	var preview = ColorRect.new()
	preview.color = icon.color
	preview.size = icon.size
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	return {"inventory_slot": index, "inventory": inventory}

func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data is Dictionary and data.has("inventory_slot") and data.inventory == inventory

func _drop_data(_at_position: Vector2, data):
	inventory.move(data.inventory_slot, index)
