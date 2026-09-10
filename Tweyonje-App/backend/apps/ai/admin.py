from django.contrib import admin

from .models import ClassificationLog


@admin.register(ClassificationLog)
class ClassificationLogAdmin(admin.ModelAdmin):
    list_display = ("predicted_category", "confidence_score", "user", "created_at")
    list_filter = ("predicted_category",)
    search_fields = ("predicted_category", "user__email")
