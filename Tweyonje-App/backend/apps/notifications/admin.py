from django.contrib import admin

from .models import Notification


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("recipient", "title", "channel", "status", "is_read", "created_at")
    list_filter = ("channel", "status", "is_read")
    search_fields = ("recipient__email", "title", "message")
