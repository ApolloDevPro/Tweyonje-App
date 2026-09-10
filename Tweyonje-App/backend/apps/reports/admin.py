from django.contrib import admin

from .models import IllegalDumpingReport, ReportPhoto


class ReportPhotoInline(admin.TabularInline):
    model = ReportPhoto
    extra = 0


@admin.register(IllegalDumpingReport)
class IllegalDumpingReportAdmin(admin.ModelAdmin):
    list_display = ("reference_id", "reported_by", "is_anonymous", "zone", "severity", "status", "created_at")
    list_filter = ("status", "severity", "is_anonymous", "zone")
    search_fields = ("reference_id", "address", "description")
    inlines = [ReportPhotoInline]
