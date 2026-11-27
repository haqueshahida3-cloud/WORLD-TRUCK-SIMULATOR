extends Node
class_name RoadRoutePlanner

signal route_calculated(route: Array, total_distance: float)
signal route_failed

@export_group("Route Settings")
@export var road_nodes: Array[Node3D] = []
@export var maximum_connection_distance: float = 100.0

var road_graph: Dictionary = {}
var current_route: Array[Vector3] = []
var total_route_distance: float = 0.0


func _ready() -> void:
    add_to_group("road_route_planner")
    build_road_network()


# ============================================================
# BUILD ROAD NETWORK
# ============================================================

func build_road_network() -> void:

    road_graph.clear()

    for i in range(road_nodes.size()):

        var node := road_nodes[i]

        if not is_instance_valid(node):
            continue

        road_graph[i] = []

    for i in range(road_nodes.size()):

        var first := road_nodes[i]

        if not is_instance_valid(first):
            continue

        for j in range(i + 1, road_nodes.size()):

            var second := road_nodes[j]

            if not is_instance_valid(second):
                continue

            var distance := first.global_position.distance_to(
                second.global_position
            )

            if distance <= maximum_connection_distance:

                road_graph[i].append({
                    "id": j,
                    "distance": distance
                })

                road_graph[j].append({
                    "id": i,
                    "distance": distance
                })


# ============================================================
# FIND NEAREST ROAD NODE
# ============================================================

func find_nearest_node(position: Vector3) -> int:

    var nearest_id := -1
    var nearest_distance := INF

    for i in range(road_nodes.size()):

        var node := road_nodes[i]

        if not is_instance_valid(node):
            continue

        var distance := position.distance_to(
            node.global_position
        )

        if distance < nearest_distance:
            nearest_distance = distance
            nearest_id = i

    return nearest_id


# ============================================================
# DIJKSTRA ROUTE CALCULATION
# ============================================================

func calculate_route(
    start_position: Vector3,
    destination_position: Vector3
) -> bool:

    current_route.clear()
    total_route_distance = 0.0

    if road_graph.is_empty():
        route_failed.emit()
        return false

    var start_id := find_nearest_node(start_position)
    var destination_id := find_nearest_node(
        destination_position
    )

    if start_id == -1 or destination_id == -1:
        route_failed.emit()
        return false

    var distances: Dictionary = {}
    var previous: Dictionary = {}
    var unvisited: Array[int] = []

    for id in road_graph.keys():

        distances[id] = INF
        previous[id] = -1

        unvisited.append(id)

    distances[start_id] = 0.0

    while not unvisited.is_empty():

        var current_id := -1
        var smallest_distance := INF

        for id in unvisited:

            if distances[id] < smallest_distance:
                smallest_distance = distances[id]
                current_id = id

        if current_id == -1:
            break

        if smallest_distance == INF:
            break

        unvisited.erase(current_id)

        if current_id == destination_id:
            break

        for connection in road_graph[current_id]:

            var neighbor: int = connection["id"]
            var edge_distance: float = connection["distance"]

            var new_distance := (
                distances[current_id] + edge_distance
            )

            if new_distance < distances[neighbor]:

                distances[neighbor] = new_distance
                previous[neighbor] = current_id

    if distances[destination_id] == INF:
        route_failed.emit()
        return false

    _reconstruct_route(
        start_id,
        destination_id,
        previous
    )

    total_route_distance = distances[destination_id]

    current_route.insert(0, start_position)
    current_route.append(destination_position)

    route_calculated.emit(
        current_route,
        total_route_distance
    )

    return true


# ============================================================
# RECONSTRUCT ROUTE
# ============================================================

func _reconstruct_route(
    start_id: int,
    destination_id: int,
    previous: Dictionary
) -> void:

    var path: Array[int] = []
    var current_id := destination_id

    while current_id != -1:

        path.push_front(current_id)

        if current_id == start_id:
            break

        current_id = previous[current_id]

    if path.is_empty() or path[0] != start_id:
        return

    for id in path:

        var node := road_nodes[id]

        if is_instance_valid(node):
            current_route.append(node.global_position)


# ============================================================
# ROUTE INFORMATION
# ============================================================

func get_current_route() -> Array:
    return current_route.duplicate()


func get_route_distance() -> float:
    return total_route_distance


func get_route_distance_km() -> float:
    return total_route_distance / 1000.0


func clear_route() -> void:
    current_route.clear()
    total_route_distance = 0.0
