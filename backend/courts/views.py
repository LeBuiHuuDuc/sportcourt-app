from datetime import datetime, timedelta
from django.utils import timezone
from rest_framework import viewsets, permissions,filters
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.decorators import action
from rest_framework.exceptions import PermissionDenied
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.perms import IsApprovedOwner
from .serializers import CourtSerializer, ComplexSettingSerializer, PricingSerializer
from .models import Court, ComplexSetting, TimeSlot, Pricing
from bookings.models import BookingSlot
from bookings.views import cleanup_expired_bookings
from django.db import models

class CourtViewSet(viewsets.ModelViewSet):
    serializer_class = CourtSerializer
    queryset = Court.objects.all()
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name']
    ordering_fields = ['average_rating']
    filterset_fields = ['sport_type', 'owner']

    @action(detail=True, methods=['get'], url_path='check-slots')
    def check_slots(self, request, pk=None):
        cleanup_expired_bookings()
        court = self.get_object()
        date_str = request.query_params.get('date')
        if not date_str:
            return Response({"error": "Vui lòng truyền tham số date (YYYY-MM-DD)"}, status=400)
        try:
            target_date = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return Response({"error": "Sai định dạng ngày, vui lòng dùng chuẩn YYYY-MM-DD"}, status=400)
        is_weekend = target_date.isoweekday() >= 6
        day_type = 'weekend' if is_weekend else 'weekday'
        available_pricings = Pricing.objects.filter(court=court , day_type=day_type)
        all_slots = TimeSlot.objects.filter(court=court)

        five_mins_ago = timezone.now() - timedelta(minutes=5)
        occupied_slots = BookingSlot.objects.filter(
            booking__court=court,
            booking__booking_date__date= target_date
        ).filter(
            models.Q(booking__status__in=['confirmed', 'completed']) |
            (models.Q(booking__status='pending_payment') & models.Q(booking__created_at__gte=five_mins_ago))
        ).values_list('time_slot_id', flat=True)
        data =[]
        for slot in all_slots:
            if slot.id in occupied_slots:
                status = "booked"
            else:
                status = "available"
            matching_pricing = next(
                (p for p in available_pricings if p.covers(slot.start_time, slot.end_time)),
                None
            )
            if matching_pricing:
                price = matching_pricing.price_per_slot
            else:
                price = 0
            data.append({
                "id": slot.id,
                "start_time": slot.start_time,
                "end_time": slot.end_time,
                "status": status,
                "price": float(price),
            })
        return Response(data)
class ComplexViewSet(viewsets.ModelViewSet):
    serializer_class = ComplexSettingSerializer
    queryset = ComplexSetting.objects.all()
    permission_classes = [permissions.IsAdminUser]

class OwnerCourtViewSet(viewsets.ModelViewSet):
    serializer_class = CourtSerializer
    permissions = [IsApprovedOwner]

    def get_queryset(self):
        return Court.objects.filter(owner=self.request.user)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)



class OwnerPricingViewSet(viewsets.ModelViewSet):
    serializer_class = PricingSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Pricing.objects.filter(court__owner=self.request.user)

    def perform_create(self, serializer):
        court = serializer.validated_data.get('court')
        if court.owner != self.request.user:
            raise PermissionDenied("Bạn không có quyền thêm giá cho sân của người khác!")
        serializer.save()