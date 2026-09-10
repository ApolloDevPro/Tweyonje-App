from django.utils import timezone
from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.collections.models import CollectionAssignment
from apps.profiles.models import Vehicle
from .models import LiveLocation, LocationHistory
from .serializers import (
    LiveLocationSerializer,
    UpdateLocationSerializer,
    calculate_haversine_distance_km,
)


class UpdateLiveLocationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = UpdateLocationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data

        vehicle = None
        if data.get("vehicle_id"):
            vehicle = Vehicle.objects.filter(id=data["vehicle_id"]).first()

        live_loc, _ = LiveLocation.objects.update_or_create(
            user=request.user,
            defaults={
                "vehicle": vehicle,
                "latitude": data["latitude"],
                "longitude": data["longitude"],
                "heading": data.get("heading"),
                "speed_kmh": data.get("speed_kmh"),
                "last_updated": timezone.now(),
            },
        )

        # Log into history
        LocationHistory.objects.create(
            user=request.user,
            latitude=data["latitude"],
            longitude=data["longitude"],
            recorded_at=timezone.now(),
        )

        return Response(LiveLocationSerializer(live_loc).data, status=status.HTTP_200_OK)


class GetCollectorLocationView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, assignment_id):
        assignment = CollectionAssignment.objects.filter(id=assignment_id).select_related("waste_request", "collector").first()
        if not assignment:
            return Response({"error": "Assignment not found."}, status=status.HTTP_404_NOT_FOUND)

        live_loc = LiveLocation.objects.filter(user=assignment.collector).first()
        if not live_loc:
            return Response({"error": "Collector live location is currently unavailable."}, status=status.HTTP_404_NOT_FOUND)

        eta_minutes = None
        distance_km = None
        if assignment.waste_request.latitude and assignment.waste_request.longitude:
            distance_km = calculate_haversine_distance_km(
                float(live_loc.latitude),
                float(live_loc.longitude),
                float(assignment.waste_request.latitude),
                float(assignment.waste_request.longitude),
            )
            # Assuming average speed in Kampala traffic is ~20 km/h
            speed = float(live_loc.speed_kmh or 20)
            if speed > 0:
                eta_minutes = round((distance_km / speed) * 60)

        return Response({
            "collector_location": LiveLocationSerializer(live_loc).data,
            "destination": {
                "latitude": assignment.waste_request.latitude,
                "longitude": assignment.waste_request.longitude,
                "address": assignment.waste_request.pickup_address,
            },
            "distance_km": distance_km,
            "eta_minutes": max(eta_minutes or 5, 2),
            "status": assignment.status,
        })
