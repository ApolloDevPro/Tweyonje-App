from django.contrib import admin

from .models import Dispute, SupportTicket, TicketMessage


class TicketMessageInline(admin.TabularInline):
    model = TicketMessage
    extra = 0


@admin.register(SupportTicket)
class SupportTicketAdmin(admin.ModelAdmin):
    list_display = ("ticket_number", "user", "subject", "category", "priority", "status", "sla_deadline", "is_escalated")
    list_filter = ("status", "category", "priority", "is_escalated")
    search_fields = ("ticket_number", "subject", "user__email")
    inlines = [TicketMessageInline]


@admin.register(Dispute)
class DisputeAdmin(admin.ModelAdmin):
    list_display = ("reference_id", "waste_request", "raised_by", "resolution", "resolved_by", "created_at")
    list_filter = ("resolution",)
    search_fields = ("reference_id", "raised_by__email", "waste_request__reference_id")
