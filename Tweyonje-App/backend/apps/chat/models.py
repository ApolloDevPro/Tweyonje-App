from django.conf import settings
from django.db import models

from apps.waste_requests.models import WasteRequest
from core.models import UUIDModel


class ChatConversation(UUIDModel):
    """A message thread between a resident/business and the assigned collector.

    Each waste request can have at most one conversation, opened once a
    collector has been assigned to it.
    """

    waste_request = models.OneToOneField(
        WasteRequest,
        on_delete=models.CASCADE,
        related_name="chat_conversation",
    )
    collector = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_conversations",
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"Chat on {self.waste_request.reference_id}"


class ChatMessage(UUIDModel):
    conversation = models.ForeignKey(
        ChatConversation,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="chat_messages",
    )
    content = models.TextField()
    is_read = models.BooleanField(default=False)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"Msg in {self.conversation_id} by {self.sender.email}"