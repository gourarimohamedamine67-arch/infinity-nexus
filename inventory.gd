class_name Inventory
extends RefCounted
## Inventaire du joueur : 9 cases de barre rapide (indices 0-8) + 24 cases de sac (9-32).
## Une case = {} (vide) ou {"id": StringName, "count": int}.

signal changed                       ## le contenu a changé (l'interface se redessine)
signal selected_changed(index: int)  ## une autre case de la barre rapide est sélectionnée
signal item_added(id: StringName, count: int)   ## des objets sont entrés (récolte, fabrication…)

const Items = preload("res://items.gd")
const HOTBAR_SIZE = 9
const BACKPACK_SIZE = 24
const SIZE = HOTBAR_SIZE + BACKPACK_SIZE

var slots: Array = []
var selected := 0   ## case sélectionnée de la barre rapide (0-8)

func _init():
	slots.resize(SIZE)
	for i in SIZE:
		slots[i] = {}

func get_slot(i: int) -> Dictionary:
	return slots[i]

func is_empty_slot(i: int) -> bool:
	return slots[i].is_empty()

func max_stack_of(id: StringName) -> int:
	var item = Items.get_item(id)
	return item.max_stack if item else 99

## Ajoute des objets (piles existantes d'abord, puis cases vides). Renvoie ce qui n'a pas pu rentrer.
func add(id: StringName, count: int) -> int:
	var requested = count
	if Items.get_item(id) == null:
		push_error("Objet inconnu : %s" % id)
		return count
	var max_stack = max_stack_of(id)
	for i in SIZE:
		if count == 0:
			break
		if slots[i].get("id") == id and slots[i].count < max_stack:
			var put = min(count, max_stack - slots[i].count)
			slots[i].count += put
			count -= put
	for i in SIZE:
		if count == 0:
			break
		if slots[i].is_empty():
			var put = min(count, max_stack)
			slots[i] = {"id": id, "count": put}
			count -= put
	changed.emit()
	if count < requested:
		item_added.emit(id, requested - count)
	return count

## Reste-t-il de la place pour count objets de ce type ?
func has_room_for(id: StringName, count: int) -> bool:
	var max_stack = max_stack_of(id)
	var room = 0
	for s in slots:
		if s.is_empty():
			room += max_stack
		elif s.id == id:
			room += max_stack - s.count
	return room >= count

## Nombre total d'un objet dans l'inventaire.
func count_of(id: StringName) -> int:
	var total = 0
	for s in slots:
		if s.get("id") == id:
			total += s.count
	return total

## Retire des objets (sac d'abord, barre rapide ensuite). Ne retire rien s'il n'y en a pas assez.
func remove(id: StringName, count: int) -> bool:
	if count_of(id) < count:
		return false
	for i in range(SIZE - 1, -1, -1):
		if count == 0:
			break
		if slots[i].get("id") == id:
			var take = min(count, slots[i].count)
			slots[i].count -= take
			count -= take
			if slots[i].count == 0:
				slots[i] = {}
	changed.emit()
	return true

## Déplace le contenu d'une case vers une autre : fusionne si même objet, sinon échange.
func move(from: int, to: int):
	if from == to or slots[from].is_empty():
		return
	var a = slots[from]
	var b = slots[to]
	if not b.is_empty() and b.id == a.id:
		var max_stack = max_stack_of(a.id)
		var put = min(a.count, max_stack - b.count)
		b.count += put
		a.count -= put
		if a.count == 0:
			slots[from] = {}
	else:
		slots[from] = b
		slots[to] = a
	changed.emit()

## Vide entièrement une case et renvoie son contenu.
func take_slot(i: int) -> Dictionary:
	var content = slots[i]
	slots[i] = {}
	changed.emit()
	return content

func select(index: int):
	selected = posmod(index, HOTBAR_SIZE)
	selected_changed.emit(selected)

## Objet tenu en main (case sélectionnée de la barre rapide), ou null.
func selected_item() -> ItemData:
	var s = slots[selected]
	return null if s.is_empty() else Items.get_item(s.id)
