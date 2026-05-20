extends SelectableUI
class_name PlaceAbleUIObject2D

@export var mouse_left_input : String = "mb_left";
@export var center_to_placement_area : bool = true;
var dragger : DragWithMouse;
var _original_position : Vector2 = Vector2.ZERO;
var picked_up = false;
var is_in_placement_area : bool = false;
var placement_area : PlacementArea2D;

func _ready() -> void:
	super()
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
			mover.global_target_position = placement_area.global_position;
	if picked_up:
		is_selected = true;
	else:
		if not is_in_placement_area:
			mover.global_target_position = _original_position

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

func _on_object_placed():
	picked_up = false;
	if not is_in_placement_area:
		mover.global_target_position = _original_position;
	else:
		placement_area.snap_object(self)
