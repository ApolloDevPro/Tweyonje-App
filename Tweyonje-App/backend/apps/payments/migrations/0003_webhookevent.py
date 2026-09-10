# Generated migration for WebhookEvent model

from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0002_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='WebhookEvent',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('created_at', models.DateTimeField(auto_now_add=True, db_index=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('provider', models.CharField(choices=[('MTN_MOMO', 'MTN Mobile Money'), ('AIRTEL_MONEY', 'Airtel Money'), ('CARD', 'Card Payment'), ('OTHER', 'Other Provider')], max_length=20)),
                ('provider_reference', models.CharField(db_index=True, help_text='Reference ID from the provider (e.g., MTN transaction ID)', max_length=255)),
                ('idempotency_key', models.CharField(db_index=True, help_text='Unique key to prevent duplicate processing', max_length=255, unique=True)),
                ('http_method', models.CharField(default='POST', max_length=10)),
                ('remote_ip', models.GenericIPAddressField(blank=True, null=True)),
                ('user_agent', models.TextField(blank=True)),
                ('raw_headers', models.JSONField(blank=True, default=dict)),
                ('raw_body', models.TextField(help_text='Raw request body for audit')),
                ('parsed_data', models.JSONField(blank=True, default=dict, help_text='Parsed JSON payload')),
                ('status', models.CharField(choices=[('PENDING', 'Pending'), ('PROCESSED', 'Processed'), ('FAILED', 'Failed'), ('DUPLICATE', 'Duplicate')], db_index=True, default='PENDING', max_length=20)),
                ('processed_at', models.DateTimeField(blank=True, null=True)),
                ('error_message', models.TextField(blank=True)),
                ('retry_count', models.PositiveIntegerField(default=0)),
                ('last_retry_at', models.DateTimeField(blank=True, null=True)),
                ('signature_verified', models.BooleanField(default=False)),
                ('signature_value', models.TextField(blank=True)),
                ('payment', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='webhook_events', to='payments.payment')),
            ],
            options={
                'db_table': 'payment_webhook_events',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='webhookevent',
            index=models.Index(fields=['provider', 'status'], name='payment_web_provide_idx'),
        ),
        migrations.AddIndex(
            model_name='webhookevent',
            index=models.Index(fields=['created_at'], name='payment_web_created_idx'),
        ),
        migrations.AddIndex(
            model_name='webhookevent',
            index=models.Index(fields=['provider_reference'], name='payment_web_provide_ref_idx'),
        ),
    ]
