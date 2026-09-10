from django.contrib import admin

from .models import ChatConversation, ChatMessage


@admin.register(ChatConversation)
class ChatConversationAdmin(admin.ModelAdmin):
    list_display = ("id", "waste_request", "collector", "is_active", "created_at")
    search_fields = ("waste_request__reference_id", "collector__email")


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ("id", "conversation", "sender", "is_read", "created_at")
    search_fields = ("sender__email", "content")