extends SelectableUI
class_name PlaceAbleUIObject2D

@export var mouse_left_input : String = "mb_left";
@export var center_to_placement_area : bool = true;
@export var keep_original_size : bool = true; ## if set to true, will keep the original size, even if the placement has their scale increased

static var _any_dragging: bool = false

var dragger : DragWithMouse;
var _original_position : Vector2 = Vector2.ZERO;
var picked_up = false;
var is_in_placement_area : bool = false;
var placement_area : PlacementArea2D;
var original_size : Vector2;
var _original_z_index : int = 0;

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
	dragger.on = picked_up or not _any_dragging;
	if get_parent() is PlacementArea2D:
		is_in_placement_area = true;
		if not dragger.moving:
			if mover: 
				placement_area = get_parent();
				mover.global_target_position = placement_area.global_position;
	if picked_up:
		is_selected = true;
	else:
		if not is_in_placement_area:
			if mover: mover.global_target_position = _original_position

func _update_placement_area() -> void:
	var best : PlacementArea2D = null
	var best_dist := INF
	for area in _area.get_overlapping_areas():
		if area is PlacementArea2D and not area.is_full() and area.can_accept(self):
			var d = global_position.distance_squared_to(area.global_position)
			if d < best_dist:
				best_dist = d
				best = area
	placement_area = best
	is_in_placement_area = best != null

func _on_area_entered(area : Area2D):
	if area is PlacementArea2D and area.can_accept(self):
		_update_placement_area()

func _on_area_exited(area : Area2D):
	if area is PlacementArea2D:
		_update_placement_area()

func _on_object_picked_up():
	is_in_placement_area = false;
	_original_position = mover.global_target_position if mover else global_position;
	picked_up = true;
	_any_dragging = true;
	_original_z_index = z_index;
	z_index = 100;
	emit_signal("just_picked_up", global_position)

func _on_object_placed():
	picked_up = false;
	_any_dragging = false;
	z_index = _original_z_index;
	_update_placement_area()
	if not is_in_placement_area:
		if mover: mover.global_target_position = _original_position;
	else:
		placement_area.snap_object(self)
		if keep_original_size:
			global_scale = original_size
			_base_scale = scale.x
		emit_signal("just_placed", global_position)
	# mouse_entered doesn't re-fire if the cursor was already over an element when the drag
	# ended (or when z_index reset exposed an element below). Push a synthetic motion event
	# so Area2D hover detection re-evaluates for elements now under the cursor.
	_push_mouse_recheck()

func _push_mouse_recheck() -> void:
	var vp := get_viewport()
	if not is_instance_valid(vp):
		return
	var recheck := InputEventMouseMotion.new()
	recheck.position = vp.get_mouse_position()
	vp.push_input(recheck)
