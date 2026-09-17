from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import BookingViewSet, payment_ipn, payment_return

router = DefaultRouter()
router.register(r'orders', BookingViewSet, basename='booking')

urlpatterns = [
    path('', include(router.urls)),

    path('payment-ipn/', payment_ipn, name='payment_ipn'),
    path('payment-return/', payment_return, name='payment_return'),
]