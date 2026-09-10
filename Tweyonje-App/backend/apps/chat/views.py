from rest_framework import permissions, status, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from apps.collections.models import CollectionAssignment
from apps.waste_requests.models import WasteRequest
from core.models import Role
from .models import ChatConversation, ChatMessage
from .serializers import ChatConversationSerializer, ChatMessageSerializer


class ChatConversationViewSet(viewsets.ReadOnlyModelViewSet):
    """Store-and-retrieve conversations between a requester and a collector."""

    permission_classes = [permissions.IsAuthenticated]
    serializer_class = ChatConversationSerializer
    search_fields = ["waste_request__reference_id"]

    def get_queryset(self):
        user = self.request.user
        if user.role in (Role.ADMINISTRATOR, Role.AUTHORITY):
            return ChatConversation.objects.all()
        return ChatConversation.objects.filter(
            collector=user,
        ) | ChatConversation.objects.filter(
            waste_request__user=user,
        )

    @action(detail=False, methods=["post"])
    def create_for_request(self, request):
        """Open (or return the existing) chat thread for a waste request.

        Body: {"waste_request": "<uuid>"}
        """
        waste_request_id = request.data.get("waste_request")
        if not waste_request_id:
            return Response(
                {"error": "waste_request (uuid) is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )
        try:
            waste_request = WasteRequest.objects.get(id=waste_request_id)
        except WasteRequest.DoesNotExist:
            return Response(
                {"error": "Waste request not found."},
                status=status.HTTP_404_NOT_FOUND,
            )

        user = request.user
        is_participant = (
            waste_request.user == user
            or user.role in (Role.ADMINISTRATOR, Role.AUTHORITY)
        )
        if not is_participant:
            return Response(
                {"error": "You are not a participant of this request."},
                status=status.HTTP_403_FORBIDDEN,
            )

        assignment = (
            waste_request.assignments.exclude(
                status=CollectionAssignment.Status.CANCELLED,
            )
            .select_related("collector")
            .order_by("-created_at")
            .first()
        )
        if not assignment:
            return Response(
                {"error": "No collector assigned to this request yet."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        conversation, _ = ChatConversation.objects.get_or_create(
            waste_request=waste_request,
            defaults={"collector": assignment.collector},
        )
        return Response(
            ChatConversationSerializer(conversation).data,
            status=status.HTTP_200_OK,
        )

    @action(detail=False, methods=["get"])
    def for_request(self, request):
        waste_request_id = request.query_params.get("waste_request")
        if not waste_request_id:
            return Response({}, status=status.HTTP_400_BAD_REQUEST)
        conversation = self.get_queryset().filter(waste_request=waste_request_id).first()
        if not conversation:
            return Response({}, status=status.HTTP_404_NOT_FOUND)
        return Response(ChatConversationSerializer(conversation).data)

    @action(detail=True, methods=["post"])
    def send_message(self, request, pk=None):
        from core.realtime import notify_chat_message
        
        conversation = self.get_object()
        user = request.user
        is_participant = (
            conversation.waste_request.user == user
            or conversation.collector == user
            or user.role in (Role.ADMINISTRATOR, Role.AUTHORITY)
        )
        if not is_participant:
            return Response(
                {"error": "You are not a participant of this conversation."},
                status=status.HTTP_403_FORBIDDEN,
            )

        content = (request.data.get("content") or "").strip()
        if not content:
            return Response(
                {"error": "Message content is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        message = ChatMessage.objects.create(
            conversation=conversation,
            sender=user,
            content=content,
        )
        
        # Broadcast real-time message to all participants
        notify_chat_message(conversation, message)
        
        return Response(
            ChatMessageSerializer(message).data,
            status=status.HTTP_201_CREATED,
        )

    @action(detail=True, methods=["post"])
    def mark_read(self, request, pk=None):
        conversation = self.get_object()
        conversation.messages.filter(is_read=False).exclude(sender=request.user).update(
            is_read=True
        )
        return Response({"ok": True})

    @action(detail=False, methods=["get"])
    def unread_count(self, request):
        """Get total unread message count for the current user across all conversations."""
        user = request.user
        unread_total = ChatMessage.objects.filter(
            conversation__in=self.get_queryset(),
            is_read=False,
        ).exclude(sender=user).count()
        
        return Response({"unread_count": unread_total})

    @action(detail=True, methods=["post"])
    def typing(self, request, pk=None):
        """Notify other participants that the user is typing."""
        from core.realtime import notify_chat_typing
        
        conversation = self.get_object()
        user = request.user
        is_participant = (
            conversation.waste_request.user == user
            or conversation.collector == user
            or user.role in (Role.ADMINISTRATOR, Role.AUTHORITY)
        )
        if not is_participant:
            return Response(
                {"error": "You are not a participant of this conversation."},
                status=status.HTTP_403_FORBIDDEN,
            )
        
        # Broadcast typing indicator
        notify_chat_typing(conversation, user)
        
        return Response({"ok": True})