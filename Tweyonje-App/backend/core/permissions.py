from rest_framework.permissions import BasePermission, SAFE_METHODS

from core.models import Role


class IsAdmin(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and request.user.role == Role.ADMINISTRATOR
        )


class IsAuthority(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.role in (Role.AUTHORITY, Role.ADMINISTRATOR)
        )


class IsCollector(BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user and request.user.is_authenticated and request.user.role == Role.COLLECTOR
        )


class IsOwnerOrReadOnly(BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        user = getattr(request.user, "user", request.user)
        obj_user = getattr(obj, "user", None)
        return obj_user is not None and obj_user == user


class IsOwner(BasePermission):
    def has_object_permission(self, request, view, obj):
        user = getattr(request.user, "user", request.user)
        obj_user = getattr(obj, "user", None)
        return obj_user is not None and obj_user == user
