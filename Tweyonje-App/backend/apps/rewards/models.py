from django.conf import settings
from django.db import models

from core.models import UUIDModel


class RewardTier(UUIDModel):
    name = models.CharField(max_length=64, unique=True)  # Bronze, Silver, Gold, Platinum
    threshold_points = models.PositiveIntegerField(default=0)
    multiplier = models.DecimalField(max_digits=4, decimal_places=2, default=1.0)
    badge_icon = models.CharField(max_length=64, blank=True, default="award")
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["threshold_points"]

    def __str__(self):
        return f"{self.name} Tier (>= {self.threshold_points} pts)"


class EcoWallet(UUIDModel):
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="eco_wallet",
    )
    current_points = models.PositiveIntegerField(default=0)
    lifetime_points = models.PositiveIntegerField(default=0)
    current_tier = models.ForeignKey(
        RewardTier,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="wallets",
    )

    class Meta:
        ordering = ["-current_points"]

    def __str__(self):
        return f"Wallet ({self.user.email}): {self.current_points} pts"


class PointTransaction(UUIDModel):
    class TransactionType(models.TextChoices):
        EARNED_COLLECTION = "EARNED_COLLECTION", "Earned from Collection"
        EARNED_RECYCLING = "EARNED_RECYCLING", "Earned from Recycling"
        EARNED_REPORT = "EARNED_REPORT", "Earned from Verified Report"
        REDEEMED = "REDEEMED", "Redeemed for Reward"
        ADJUSTMENT = "ADJUSTMENT", "Admin Adjustment"

    wallet = models.ForeignKey(
        EcoWallet,
        on_delete=models.CASCADE,
        related_name="transactions",
    )
    points = models.IntegerField()  # positive for earn, negative for redeem
    transaction_type = models.CharField(max_length=32, choices=TransactionType.choices)
    source_id = models.CharField(max_length=128, blank=True)  # ID of waste request / report / trade-in
    description = models.CharField(max_length=255, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.wallet.user.email} -> {self.points:+d} pts ({self.transaction_type})"


class RewardItem(UUIDModel):
    class Category(models.TextChoices):
        AIRTIME = "AIRTIME", "Airtime / Data"
        SHOPPING_VOUCHER = "SHOPPING_VOUCHER", "Shopping Voucher"
        CLEANING_SUPPLIES = "CLEANING_SUPPLIES", "Cleaning Supplies & Bins"
        BILL_DISCOUNT = "BILL_DISCOUNT", "Waste Bill Discount"
        TREE_PLANTING = "TREE_PLANTING", "Plant a Tree"

    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    points_required = models.PositiveIntegerField()
    category = models.CharField(max_length=32, choices=Category.choices, default=Category.AIRTIME)
    stock = models.IntegerField(default=-1)  # -1 = infinite
    image = models.ImageField(upload_to="rewards/", null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["points_required"]

    def __str__(self):
        return f"{self.title} ({self.points_required} pts)"


class RedemptionRequest(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        APPROVED = "APPROVED", "Approved"
        DELIVERED = "DELIVERED", "Delivered"
        REJECTED = "REJECTED", "Rejected"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="redemptions",
    )
    reward_item = models.ForeignKey(
        RewardItem,
        on_delete=models.CASCADE,
        related_name="redemptions",
    )
    points_spent = models.PositiveIntegerField()
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} redeemed {self.reward_item.title}"
