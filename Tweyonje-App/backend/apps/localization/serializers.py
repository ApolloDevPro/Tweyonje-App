from rest_framework import serializers

from .models import TranslationKey


class TranslationKeySerializer(serializers.ModelSerializer):
    class Meta:
        model = TranslationKey
        fields = ("id", "key", "default_en", "lg_translation", "category", "created_at", "updated_at")
