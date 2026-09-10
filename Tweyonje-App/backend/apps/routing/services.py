"""Route optimization using 2-opt algorithm for TSP.

Upgrades from simple greedy nearest-neighbor to 2-opt local search
for better route optimization.
"""
import math
from django.utils import timezone
from apps.collections.models import CollectionAssignment
from apps.tracking.serializers import calculate_haversine_distance_km
from .models import RoutePlan


def two_opt_improve(route, distance_matrix):
    """
    Improve route using 2-opt algorithm.
    
    2-opt iteratively removes two edges and reconnects the route
    in a different way if it results in a shorter total distance.
    """
    improved = True
    best_route = route[:]
    
    while improved:
        improved = False
        for i in range(1, len(best_route) - 2):
            for j in range(i + 1, len(best_route)):
                if j - i == 1:
                    continue
                
                # Calculate current distance
                current_dist = (
                    distance_matrix[best_route[i - 1]][best_route[i]] +
                    distance_matrix[best_route[j - 1]][best_route[j]]
                )
                
                # Calculate distance after 2-opt swap
                new_dist = (
                    distance_matrix[best_route[i - 1]][best_route[j - 1]] +
                    distance_matrix[best_route[i]][best_route[j]]
                )
                
                if new_dist < current_dist:
                    # Reverse the segment between i and j-1
                    best_route[i:j] = reversed(best_route[i:j])
                    improved = True
                    break
            if improved:
                break
    
    return best_route


def optimize_collector_daily_route(collector, target_date=None):
    """
    Optimize collector route using greedy + 2-opt algorithm.
    
    Steps:
    1. Greedy nearest-neighbor for initial route
    2. 2-opt improvement for local optimization
    3. Calculate estimated time considering speed and stops
    """
    if not target_date:
        target_date = timezone.now().date()

    assignments = CollectionAssignment.objects.filter(
        collector=collector,
        assigned_at__date=target_date,
        status__in=[
            CollectionAssignment.Status.ASSIGNED,
            CollectionAssignment.Status.EN_ROUTE,
            CollectionAssignment.Status.ARRIVED,
        ],
    ).select_related("waste_request")

    points = []
    for a in assignments:
        req = a.waste_request
        if req and req.latitude and req.longitude:
            points.append({
                "assignment_id": str(a.id),
                "request_id": str(req.id),
                "reference_id": req.reference_id,
                "address": req.pickup_address,
                "lat": float(req.latitude),
                "lon": float(req.longitude),
                "status": a.status,
            })

    if not points:
        return None
    
    n = len(points)
    
    # Build distance matrix
    distance_matrix = [[0.0] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            if i != j:
                distance_matrix[i][j] = calculate_haversine_distance_km(
                    points[i]["lat"], points[i]["lon"],
                    points[j]["lat"], points[j]["lon"]
                )

    # Step 1: Greedy nearest-neighbor for initial solution
    unvisited = set(range(n))
    current = 0  # Start from first point
    route_indices = [current]
    unvisited.remove(current)
    
    while unvisited:
        nearest_idx = min(unvisited, key=lambda x: distance_matrix[current][x])
        route_indices.append(nearest_idx)
        unvisited.remove(nearest_idx)
        current = nearest_idx
    
    # Step 2: Improve with 2-opt (only if more than 3 points)
    if n > 3:
        route_indices = two_opt_improve(route_indices, distance_matrix)
    
    # Build final route with points
    ordered_route = [points[i] for i in route_indices]
    
    # Calculate total distance
    total_dist = sum(
        distance_matrix[route_indices[i]][route_indices[i + 1]]
        for i in range(len(route_indices) - 1)
    )

    # Estimate time: 25 km/h average speed + 12 mins per pickup
    est_travel_mins = (total_dist / 25.0) * 60 if total_dist > 0 else 0
    pickup_time_mins = len(ordered_route) * 12
    est_total_mins = int(round(est_travel_mins + pickup_time_mins))

    route_plan, _ = RoutePlan.objects.update_or_create(
        collector=collector,
        date=target_date,
        defaults={
            "status": RoutePlan.Status.OPTIMIZED,
            "total_distance_km": round(total_dist, 2),
            "estimated_duration_minutes": est_total_mins,
            "waypoints_order_json": ordered_route,
        },
    )

    return route_plan
