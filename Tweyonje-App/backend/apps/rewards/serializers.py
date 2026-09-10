from rest_framework import serializers

from apps.accounts.serializers import UserSerializer
from .models import EcoWallet, PointTransaction, RedemptionRequest, RewardItem, RewardTier


class RewardTierSerializer(serializers.ModelSerializer):
    class Meta:
        model = RewardTier
        fields = (
            "id",
            "name",
            "threshold_points",
            "multiplier",
            "badge_icon",
            "description",
            "is_active",
        )


class PointTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PointTransaction
        fields = (
            "id",
            "points",
            "transaction_type",
            "source_id",
            "description",
            "created_at",
        )


class EcoWalletSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    current_tier_details = RewardTierSerializer(source="current_tier", read_only=True)
    recent_transactions = serializers.SerializerMethodField()

    class Meta:
        model = EcoWallet
        fields = (
            "id",
            "user",
            "user_details",
            "current_points",
            "lifetime_points",
            "current_tier",
            "current_tier_details",
            "recent_transactions",
        )

    def get_recent_transactions(self, obj):
        txs = obj.transactions.all()[:15]
        return PointTransactionSerializer(txs, many=True).data


class RewardItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = RewardItem
        fields = (
            "id",
            "title",
            "description",
            "points_required",
            "category",
            "stock",
            "image",
            "is_active",
        )


class RedemptionRequestSerializer(serializers.ModelSerializer):
    user_details = UserSerializer(source="user", read_only=True)
    reward_item_details = RewardItemSerializer(source="reward_item", read_only=True)

    class Meta:
        model = RedemptionRequest
        fields = (
            "id",
            "user",
            "user_details",
            "reward_item",
            "reward_item_details",
            "points_spent",
            "status",
            "notes",
            "created_at",
        )
        read_only_fields = ("id", "user", "points_spent", "status", "created_at")
