"""
seed_data management command.
Populates the database with initial data: zones, waste categories,
recyclable materials, reward tiers, reward items, localization strings,
and demo user accounts for all roles.
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = "Seed the database with initial data (zones, categories, tiers, demo users, etc.)"

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.MIGRATE_HEADING("Seeding Tweyonje database..."))

        self._seed_zones()
        self._seed_waste_categories()
        self._seed_recyclable_materials()
        self._seed_reward_tiers()
        self._seed_reward_items()
        self._seed_translations()
        self._seed_demo_users()
        self._seed_system_settings()

        self.stdout.write(self.style.SUCCESS("Database seeded successfully!"))

    def _seed_zones(self):
        from core.models import Zone
        zones = [
            {"name": "Kampala Central", "code": "KLA-C", "region": "Kampala"},
            {"name": "Kawempe", "code": "KLA-K", "region": "Kampala"},
            {"name": "Makindye", "code": "KLA-M", "region": "Kampala"},
            {"name": "Nakawa", "code": "KLA-N", "region": "Kampala"},
            {"name": "Rubaga", "code": "KLA-R", "region": "Kampala"},
            {"name": "Entebbe", "code": "ENT-1", "region": "Wakiso"},
            {"name": "Mukono Central", "code": "MUK-1", "region": "Mukono"},
            {"name": "Gulu City", "code": "GUL-1", "region": "Gulu"},
        ]
        created = 0
        for z in zones:
            _, c = Zone.objects.get_or_create(code=z["code"], defaults=z)
            if c:
                created += 1
        self.stdout.write(f"  - Zones: {created} created")

    def _seed_waste_categories(self):
        from apps.waste_requests.models import WasteCategory
        categories = [
            {"name": "General Household Waste", "slug": "household", "default_price_per_kg": 500, "base_eco_points": 10, "icon": "trash"},
            {"name": "Recyclable Materials", "slug": "recyclable", "default_price_per_kg": 300, "base_eco_points": 20, "icon": "recycle"},
            {"name": "Organic / Food Waste", "slug": "organic", "default_price_per_kg": 200, "base_eco_points": 15, "icon": "leaf"},
            {"name": "Construction Debris", "slug": "construction", "default_price_per_kg": 1000, "base_eco_points": 5, "icon": "building"},
            {"name": "Electronic Waste", "slug": "e-waste", "default_price_per_kg": 2000, "base_eco_points": 50, "is_hazardous": True, "icon": "cpu"},
            {"name": "Medical / Hazardous Waste", "slug": "hazardous", "default_price_per_kg": 5000, "base_eco_points": 5, "is_hazardous": True, "icon": "biohazard"},
            {"name": "Garden & Green Waste", "slug": "green-waste", "default_price_per_kg": 250, "base_eco_points": 12, "icon": "tree"},
        ]
        created = 0
        for cat in categories:
            cat.setdefault("is_hazardous", False)
            _, c = WasteCategory.objects.get_or_create(slug=cat["slug"], defaults=cat)
            if c:
                created += 1
        self.stdout.write(f"  - Waste categories: {created} created")

    def _seed_recyclable_materials(self):
        from apps.recycling.models import RecyclableMaterial
        materials = [
            {"name": "PET Plastic Bottles", "slug": "pet-plastic", "material_type": "PLASTIC", "price_per_kg": 400, "point_multiplier": 1.5},
            {"name": "Cardboard & Paper", "slug": "cardboard", "material_type": "PAPER", "price_per_kg": 300, "point_multiplier": 1.2},
            {"name": "Glass Bottles", "slug": "glass-bottles", "material_type": "GLASS", "price_per_kg": 250, "point_multiplier": 1.0},
            {"name": "Aluminum Cans", "slug": "aluminum-cans", "material_type": "METAL", "price_per_kg": 1200, "point_multiplier": 2.5},
            {"name": "Scrap Metal", "slug": "scrap-metal", "material_type": "METAL", "price_per_kg": 800, "point_multiplier": 2.0},
            {"name": "Phones & Electronics", "slug": "electronics", "material_type": "E_WASTE", "price_per_kg": 3000, "point_multiplier": 5.0},
            {"name": "Used Batteries", "slug": "batteries", "material_type": "BATTERY", "price_per_kg": 500, "point_multiplier": 2.0},
        ]
        created = 0
        for mat in materials:
            _, c = RecyclableMaterial.objects.get_or_create(slug=mat["slug"], defaults=mat)
            if c:
                created += 1
        self.stdout.write(f"  - Recyclable materials: {created} created")

    def _seed_reward_tiers(self):
        from apps.rewards.models import RewardTier
        tiers = [
            {"name": "Bronze", "threshold_points": 0, "multiplier": 1.0, "badge_icon": "medal", "description": "Starting tier for all new users."},
            {"name": "Silver", "threshold_points": 500, "multiplier": 1.25, "badge_icon": "award", "description": "Earn 500+ lifetime points."},
            {"name": "Gold", "threshold_points": 2000, "multiplier": 1.5, "badge_icon": "star", "description": "Earn 2,000+ lifetime points."},
            {"name": "Platinum", "threshold_points": 10000, "multiplier": 2.0, "badge_icon": "crown", "description": "Elite tier for top eco-contributors."},
        ]
        created = 0
        for tier in tiers:
            _, c = RewardTier.objects.get_or_create(name=tier["name"], defaults=tier)
            if c:
                created += 1
        self.stdout.write(f"  - Reward tiers: {created} created")

    def _seed_reward_items(self):
        from apps.rewards.models import RewardItem
        items = [
            {"title": "MTN Airtime UGX 5,000", "points_required": 100, "category": "AIRTIME", "stock": -1, "description": "Redeem 100 points for MTN airtime worth 5,000 UGX."},
            {"title": "Airtel Airtime UGX 5,000", "points_required": 100, "category": "AIRTIME", "stock": -1, "description": "Redeem 100 points for Airtel airtime worth 5,000 UGX."},
            {"title": "Shopping Voucher UGX 20,000", "points_required": 400, "category": "SHOPPING_VOUCHER", "stock": 50, "description": "Kira Mall / Garden City shopping voucher."},
            {"title": "Recycling Bin (50L)", "points_required": 300, "category": "CLEANING_SUPPLIES", "stock": 30, "description": "Premium 50L recycling bin delivered to your doorstep."},
            {"title": "Waste Bill Discount 10%", "points_required": 200, "category": "BILL_DISCOUNT", "stock": -1, "description": "10% discount on your next waste collection bill."},
            {"title": "Plant a Tree in Your Name", "points_required": 150, "category": "TREE_PLANTING", "stock": -1, "description": "We plant a tree in Kampala's green corridors in your name."},
        ]
        created = 0
        for item in items:
            _, c = RewardItem.objects.get_or_create(title=item["title"], defaults=item)
            if c:
                created += 1
        self.stdout.write(f"  - Reward items: {created} created")

    def _seed_translations(self):
        from apps.localization.models import TranslationKey
        strings = [
            {"key": "app.name", "default_en": "Tweyonje", "lg_translation": "Tweyonje", "category": "general"},
            {"key": "app.tagline", "default_en": "Together for a Cleaner Uganda", "lg_translation": "Gwe ne nze okumala Uganda emirembe", "category": "general"},
            {"key": "nav.home", "default_en": "Home", "lg_translation": "Awaka", "category": "navigation"},
            {"key": "nav.requests", "default_en": "My Requests", "lg_translation": "Okusaba kwange", "category": "navigation"},
            {"key": "nav.schedule", "default_en": "Schedule Pickup", "lg_translation": "Tereza okuddukanya", "category": "navigation"},
            {"key": "nav.rewards", "default_en": "Eco Rewards", "lg_translation": "Empeera z'Obutonde", "category": "navigation"},
            {"key": "nav.profile", "default_en": "Profile", "lg_translation": "Ebikuwatako", "category": "navigation"},
            {"key": "request.status.pending", "default_en": "Pending", "lg_translation": "Gutegerwa", "category": "status"},
            {"key": "request.status.assigned", "default_en": "Assigned", "lg_translation": "Awewa", "category": "status"},
            {"key": "request.status.collected", "default_en": "Collected", "lg_translation": "Gukuŋŋaanyizibwa", "category": "status"},
            {"key": "payment.method.mtn", "default_en": "MTN Mobile Money", "lg_translation": "Sente za MTN", "category": "payment"},
            {"key": "payment.method.airtel", "default_en": "Airtel Money", "lg_translation": "Sente za Airtel", "category": "payment"},
        ]
        created = 0
        for s in strings:
            _, c = TranslationKey.objects.get_or_create(key=s["key"], defaults=s)
            if c:
                created += 1
        self.stdout.write(f"  - Translations: {created} created")

    def _seed_demo_users(self):
        from core.models import Role
        from apps.profiles.models import Profile, NotificationPreference
        from apps.rewards.models import EcoWallet

        demo_users = [
            {"email": "admin@tweyonje.ug", "full_name": "Admin User", "role": Role.ADMINISTRATOR, "is_staff": True, "is_superuser": True},
            {"email": "resident@tweyonje.ug", "full_name": "Jane Nakato", "role": Role.RESIDENT},
            {"email": "collector@tweyonje.ug", "full_name": "David Ssemwogerere", "role": Role.COLLECTOR},
            {"email": "authority@tweyonje.ug", "full_name": "Sarah Namutebi", "role": Role.AUTHORITY},
            {"email": "recycler@tweyonje.ug", "full_name": "Patrick Mukasa", "role": Role.RECYCLER},
            {"email": "business@tweyonje.ug", "full_name": "Kampala City Mall", "role": Role.BUSINESS},
        ]
        created = 0
        for u in demo_users:
            if not User.objects.filter(email=u["email"]).exists():
                user = User.objects.create_user(
                    email=u["email"],
                    password="Pass@1234",
                    full_name=u["full_name"],
                    role=u["role"],
                    is_staff=u.get("is_staff", False),
                    is_superuser=u.get("is_superuser", False),
                    email_verified=True,
                )
                Profile.objects.get_or_create(user=user)
                NotificationPreference.objects.get_or_create(user=user)
                EcoWallet.objects.get_or_create(user=user)
                created += 1
        self.stdout.write(f"  - Demo users: {created} created (password: Pass@1234)")

    def _seed_system_settings(self):
        from core.models import SystemSetting
        settings_data = [
            {"key": "collection.min_weight_kg", "value": "0.5", "description": "Minimum waste weight for a pickup request (kg)"},
            {"key": "collection.max_emergency_distance_km", "value": "50", "description": "Max distance for emergency collection coverage"},
            {"key": "rewards.report_points", "value": "25", "description": "Eco-points awarded for a verified illegal dumping report"},
            {"key": "platform.version", "value": "1.0.0", "description": "Platform version"},
            {"key": "platform.support_email", "value": "support@tweyonje.ug", "description": "Support email address"},
            {"key": "platform.support_phone", "value": "+256 700 000 000", "description": "Support phone number"},
        ]
        created = 0
        for s in settings_data:
            _, c = SystemSetting.objects.get_or_create(key=s["key"], defaults=s)
            if c:
                created += 1
        self.stdout.write(f"  - System settings: {created} created")
