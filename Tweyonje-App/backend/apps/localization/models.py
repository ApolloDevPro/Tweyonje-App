from django.db import models

from core.models import UUIDModel


class TranslationKey(UUIDModel):
    key = models.CharField(max_length=128, unique=True)
    default_en = models.TextField()
    lg_translation = models.TextField(blank=True)
    category = models.CharField(max_length=64, blank=True, default="general")

    class Meta:
        ordering = ["key"]

    def __str__(self):
        return self.key
