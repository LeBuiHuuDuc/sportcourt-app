from django.urls import path,include
from rest_framework.routers import DefaultRouter
from users.views import UserViewSet, PlayerProfileViewSet

router = DefaultRouter()
router.register(r'accounts', UserViewSet, basename='user')
router.register(r'profiles', PlayerProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
    path('register/', UserViewSet.as_view({'post': 'create'}), name='register'),
    path('me/', UserViewSet.as_view({'get': 'me', 'put': 'me', 'patch': 'me'}), name='user-me'),
]