"""
run_payouts: Batch collector payouts for a given period.
"""
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Process batch payouts for collectors in a period"

    def add_arguments(self, parser):
        parser.add_argument("--period-start", type=str, help="Period start date (YYYY-MM-DD)", default=None)
        parser.add_argument("--period-end", type=str, help="Period end date (YYYY-MM-DD)", default=None)

    def handle(self, *args, **kwargs):
        from datetime import datetime
        from apps.payments.services import batch_process_payouts

        period_start = None
        period_end = None

        if kwargs.get("period_start"):
            period_start = datetime.strptime(kwargs["period_start"], "%Y-%m-%d").date()
        if kwargs.get("period_end"):
            period_end = datetime.strptime(kwargs["period_end"], "%Y-%m-%d").date()

        self.stdout.write(f"Processing payouts: {period_start} to {period_end}...")
        payouts = batch_process_payouts(period_start=period_start, period_end=period_end)
        self.stdout.write(self.style.SUCCESS(f"Created {len(payouts)} payout records."))
