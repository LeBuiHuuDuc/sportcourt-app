from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CourtViewSet, ComplexViewSet
# , CourtAvailabilityView

router = DefaultRouter()
router.register(r'complexes', ComplexViewSet, basename='complex')
router.register(r'list', CourtViewSet, basename='court')



urlpatterns = [
    path('', include(router.urls)),
]