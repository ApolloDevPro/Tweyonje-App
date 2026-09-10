from django.contrib import admin

from .models import TranslationKey


@admin.register(TranslationKey)
class TranslationKeyAdmin(admin.ModelAdmin):
    list_display = ("key", "category", "default_en", "lg_translation")
    list_filter = ("category",)
    search_fields = ("key", "default_en", "lg_translation")
