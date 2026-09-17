from django.urls import path, include
from rest_framework.routers import DefaultRouter
from community.views import ReviewViewSet, PlayRequestViewSet

router = DefaultRouter()
router.register('reviews', ReviewViewSet,basename='reviews')
router.register('playrequests', PlayRequestViewSet, basename='playrequests')

urlpatterns = [
    path('', include(router.urls)),
]