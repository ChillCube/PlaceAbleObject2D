extends SelectableUI
class_name PlaceAbleUIObject2D

@export var mouse_left_input : String = "mb_left";
@export var center_to_placement_area : bool = true;
@export var keep_original_size : bool = true; ## if set to true, will keep the original size, even if the placement has their scale increased

var dragger : DragWithMouse;
var _original_position : Vector2 = Vector2.ZERO;
var picked_up = false;
var is_in_placement_area : bool = false;
var placement_area : PlacementArea2D;
var original_size : Vector2;

signal just_placed(_position : Vector2)
signal just_picked_up(_position : Vector2)

func _ready() -> void:
	super()
	original_size = global_scale;
	use_relative_positioning = false;
	dragger = DragWithMouse.initialize(self, _area, mouse_left_input)
	dragger.smooth_movement = true;
	mover.name = "SmoothMovement";
	dragger.connect("object_placed", _on_object_placed)
	dragger.connect("object_picked_up", _on_object_picked_up)
	_original_position = global_position
	_area.connect("area_entered", _on_area_entered)
	_area.connect("area_exited", _on_area_exited)

func _process(delta: float) -> void:
	super(delta);
	if get_parent() is PlacementArea2D:
		is_in_placement_area = true;
		if not dragger.moving:
			if mover: mover.global_target_position = placement_area.global_position;
	if picked_up:
		is_selected = true;
	else:
		if not is_in_placement_area:
			if mover: mover.global_target_position = _original_position

func _on_area_entered(area : Area2D):
	if area is PlacementArea2D:
		if not area.is_full():
			is_in_placement_area = true;
			placement_area = area;

func _on_area_exited(area : Area2D):
	if area == placement_area:
		is_in_placement_area = false;

func _on_object_picked_up():
	is_in_placement_area = false;
	_original_position = global_position;
	picked_up = true;
	emit_signal("_picked_up", global_position)

func _on_object_placed():
	picked_up = false;
	if not is_in_placement_area:
		if mover: mover.global_target_position = _original_position;
	else:
		placement_area.snap_object(self)
		if keep_original_size:
			global_scale = original_size
			_base_scale = scale.x
		emit_signal("placed", global_position)
