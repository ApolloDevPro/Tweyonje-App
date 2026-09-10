from django.conf import settings
from django.db import models

from core.models import UUIDModel, Zone


class RecyclableMaterial(UUIDModel):
    class MaterialType(models.TextChoices):
        PLASTIC = "PLASTIC", "Plastics (PET, HDPE)"
        PAPER = "PAPER", "Paper & Cardboard"
        GLASS = "GLASS", "Glass"
        METAL = "METAL", "Scrap Metal / Aluminum"
        E_WASTE = "E_WASTE", "Electronic Waste"
        BATTERY = "BATTERY", "Batteries"
        TEXTILE = "TEXTILE", "Textiles"

    name = models.CharField(max_length=128)
    slug = models.SlugField(max_length=128, unique=True)
    material_type = models.CharField(max_length=32, choices=MaterialType.choices, default=MaterialType.PLASTIC)
    price_per_kg = models.DecimalField(max_digits=10, decimal_places=2, default=300.0)
    point_multiplier = models.DecimalField(max_digits=4, decimal_places=2, default=1.5)
    description = models.TextField(blank=True)
    icon = models.CharField(max_length=64, blank=True, default="recycle")
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.price_per_kg} UGX/kg)"


class RecyclingCenter(UUIDModel):
    name = models.CharField(max_length=255)
    address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    zone = models.ForeignKey(Zone, on_delete=models.SET_NULL, null=True, blank=True, related_name="recycling_centers")
    accepted_materials = models.ManyToManyField(RecyclableMaterial, related_name="centers", blank=True)
    operating_hours = models.CharField(max_length=255, blank=True, default="Mon-Sat: 8:00 AM - 5:00 PM")
    phone = models.CharField(max_length=32, blank=True)
    email = models.EmailField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class MarketplaceListing(UUIDModel):
    class Status(models.TextChoices):
        AVAILABLE = "AVAILABLE", "Available"
        RESERVED = "RESERVED", "Reserved"
        SOLD = "SOLD", "Sold"
        CANCELLED = "CANCELLED", "Cancelled"

    seller = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="marketplace_listings",
    )
    material = models.ForeignKey(
        RecyclableMaterial,
        on_delete=models.CASCADE,
        related_name="listings",
    )
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    weight_kg = models.DecimalField(max_digits=8, decimal_places=2)
    price_ugx = models.DecimalField(max_digits=12, decimal_places=2)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.AVAILABLE)
    location_address = models.CharField(max_length=512)
    latitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    longitude = models.DecimalField(max_digits=9, decimal_places=6, null=True, blank=True)
    image = models.ImageField(upload_to="recycling_marketplace/", null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.title} - {self.weight_kg}kg ({self.status})"


class RecyclingTradeIn(UUIDModel):
    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        COMPLETED = "COMPLETED", "Completed"
        CANCELLED = "CANCELLED", "Cancelled"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="recycling_trade_ins",
    )
    center = models.ForeignKey(
        RecyclingCenter,
        on_delete=models.CASCADE,
        related_name="trade_ins",
    )
    material = models.ForeignKey(
        RecyclableMaterial,
        on_delete=models.CASCADE,
        related_name="trade_ins",
    )
    weight_kg = models.DecimalField(max_digits=8, decimal_places=2)
    amount_paid_ugx = models.DecimalField(max_digits=12, decimal_places=2, default=0.0)
    eco_points_earned = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=32, choices=Status.choices, default=Status.PENDING)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Trade-In ({self.user.email}): {self.weight_kg}kg {self.material.name}"
