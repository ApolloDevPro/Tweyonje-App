from django.conf import settings
from django.db import models

from core.models import UUIDModel


class ClassificationLog(UUIDModel):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="ai_classifications",
    )
    image = models.ImageField(upload_to="ai_classifications/")
    predicted_category = models.CharField(max_length=128)
    confidence_score = models.DecimalField(max_digits=5, decimal_places=4)
    details_json = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.predicted_category} ({self.confidence_score*100:.1f}%)"
