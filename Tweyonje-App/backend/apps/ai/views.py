from rest_framework import permissions, status, viewsets
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .models import ClassificationLog
from .serializers import ClassificationLogSerializer
from .services import classify_waste_image


class ClassifyWasteImageView(APIView):
    permission_classes = [permissions.AllowAny]
    parser_classes = [MultiPartParser, FormParser]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "ai_classify"

    def post(self, request):
        image_file = request.FILES.get("image")
        if not image_file:
            return Response({"error": "No image provided."}, status=status.HTTP_400_BAD_REQUEST)

        result = classify_waste_image(image_file)
        
        user = request.user if request.user.is_authenticated else None
        log = ClassificationLog.objects.create(
            user=user,
            image=image_file,
            predicted_category=result["category"],
            confidence_score=result["confidence"],
            details_json=result,
        )

        return Response({
            "id": log.id,
            "prediction": result,
        }, status=status.HTTP_200_OK)


class ClassificationLogViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ClassificationLogSerializer

    def get_queryset(self):
        return ClassificationLog.objects.filter(user=self.request.user)
