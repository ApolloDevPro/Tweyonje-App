from rest_framework import serializers

from .models import ClassificationLog


class ClassificationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClassificationLog
        fields = (
            "id",
            "user",
            "image",
            "predicted_category",
            "confidence_score",
            "details_json",
            "created_at",
        )
        read_only_fields = ("id", "user", "created_at")
