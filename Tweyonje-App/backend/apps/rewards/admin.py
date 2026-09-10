from django.contrib import admin

from .models import EcoWallet, PointTransaction, RedemptionRequest, RewardItem, RewardTier


@admin.register(RewardTier)
class RewardTierAdmin(admin.ModelAdmin):
    list_display = ("name", "threshold_points", "multiplier", "is_active")


class PointTransactionInline(admin.TabularInline):
    model = PointTransaction
    extra = 0
    readonly_fields = ("points", "transaction_type", "source_id", "description", "created_at")


@admin.register(EcoWallet)
class EcoWalletAdmin(admin.ModelAdmin):
    list_display = ("user", "current_points", "lifetime_points", "current_tier")
    search_fields = ("user__email",)
    inlines = [PointTransactionInline]


@admin.register(RewardItem)
class RewardItemAdmin(admin.ModelAdmin):
    list_display = ("title", "category", "points_required", "stock", "is_active")
    list_filter = ("category", "is_active")
    search_fields = ("title",)


@admin.register(RedemptionRequest)
class RedemptionRequestAdmin(admin.ModelAdmin):
    list_display = ("user", "reward_item", "points_spent", "status", "created_at")
    list_filter = ("status",)
    search_fields = ("user__email", "reward_item__title")
