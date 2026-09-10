from rest_framework import permissions, viewsets
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import TranslationKey
from .serializers import TranslationKeySerializer


class TranslationViewSet(viewsets.ModelViewSet):
    serializer_class = TranslationKeySerializer
    queryset = TranslationKey.objects.all()
    filterset_fields = ["category"]
    search_fields = ["key", "default_en", "lg_translation"]

    def get_permissions(self):
        if self.action in ("list", "retrieve", "bundle"):
            return [permissions.AllowAny()]
        return [permissions.IsAuthenticated()]

    @action(detail=False, methods=["get"])
    def bundle(self, request):
        lang = request.query_params.get("lang", "en").lower()
        items = TranslationKey.objects.all()
        bundle = {}
        for item in items:
            bundle[item.key] = item.lg_translation if lang == "lg" and item.lg_translation else item.default_en
        return Response({"language": lang, "strings": bundle})
