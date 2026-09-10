from django.db import transaction
from .models import EcoWallet, PointTransaction, RewardItem, RewardTier


def update_wallet_tier(wallet):
    tier = (
        RewardTier.objects.filter(
            threshold_points__lte=wallet.lifetime_points,
            is_active=True,
        )
        .order_by("-threshold_points")
        .first()
    )
    if tier and wallet.current_tier != tier:
        wallet.current_tier = tier
        wallet.save(update_fields=["current_tier"])
    return wallet


def award_eco_points(user, points, transaction_type, source_id="", description=""):
    """
    Idempotently awards eco-points to a user's wallet.
    """
    wallet, _ = EcoWallet.objects.get_or_create(user=user)

    # Check idempotency if source_id is provided
    if source_id:
        existing = PointTransaction.objects.filter(
            wallet=wallet,
            source_id=source_id,
            transaction_type=transaction_type,
        ).exists()
        if existing:
            return wallet

    with transaction.atomic():
        # Apply tier multiplier if active
        multiplier = float(wallet.current_tier.multiplier) if wallet.current_tier else 1.0
        final_points = int(points * multiplier)

        PointTransaction.objects.create(
            wallet=wallet,
            points=final_points,
            transaction_type=transaction_type,
            source_id=source_id,
            description=description,
        )

        wallet.current_points += final_points
        wallet.lifetime_points += final_points
        wallet.save(update_fields=["current_points", "lifetime_points"])

        update_wallet_tier(wallet)

    return wallet


def redeem_reward_points(user, reward_item):
    wallet, _ = EcoWallet.objects.get_or_create(user=user)

    if wallet.current_points < reward_item.points_required:
        return False, "Insufficient eco-points balance."

    if reward_item.stock == 0:
        return False, "This reward item is currently out of stock."

    with transaction.atomic():
        wallet.current_points -= reward_item.points_required
        wallet.save(update_fields=["current_points"])

        PointTransaction.objects.create(
            wallet=wallet,
            points=-reward_item.points_required,
            transaction_type=PointTransaction.TransactionType.REDEEMED,
            source_id=str(reward_item.id),
            description=f"Redeemed: {reward_item.title}",
        )

        if reward_item.stock > 0:
            reward_item.stock -= 1
            reward_item.save(update_fields=["stock"])

        from .models import RedemptionRequest
        redemption = RedemptionRequest.objects.create(
            user=user,
            reward_item=reward_item,
            points_spent=reward_item.points_required,
            status=RedemptionRequest.Status.PENDING,
        )

    return True, redemption
