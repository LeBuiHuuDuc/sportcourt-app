from django.conf import settings
from django.db import transaction
from django.db.models import Sum, Count
from django.http import JsonResponse,HttpResponse
from django.utils import timezone
from rest_framework import viewsets, permissions,status
from rest_framework.decorators import action, permission_classes, api_view
from rest_framework.exceptions import ValidationError
from datetime import timedelta, datetime
from rest_framework.views import APIView

from notifications.models import Notification
from users.perms import IsApprovedOwner
from .vnpay import vnpay
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.db import models
from .serializers import BookingSerializer
from .models import Booking, BookingSlot, Payment
from .utils import get_client_ip, send_booking_confirmation_email
from courts.models import TimeSlot, Pricing, Court
import uuid

def cleanup_expired_bookings():
    five_mins_ago = timezone.now() - timedelta(minutes=5)
    expired_bookings = Booking.objects.filter(
        status='pending_payment',
        created_at__lt=five_mins_ago
    )
    for booking in expired_bookings:
        booking.cancel()

class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()
    serializer_class = BookingSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return self.queryset.filter(player=self.request.user).order_by('-created_at')
    @transaction.atomic
    def create(self, request, *args, **kwargs):
        cleanup_expired_bookings()
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        court = serializer.validated_data['court']
        booking_date = serializer.validated_data['booking_date']
        time_slot_ids = serializer.validated_data.pop('time_slot_ids')


        time_slots = TimeSlot.objects.select_for_update().filter(id__in=time_slot_ids)
        if time_slots.count() != len(time_slot_ids):
            raise ValidationError({"time_slot_ids": "Danh sách ca chơi không hợp lệ."})
        now = timezone.now()
        for slot in time_slots:
            slot_datetime = timezone.datetime.combine(booking_date, slot.start_time)
            slot_datetime = timezone.make_aware(slot_datetime, timezone.get_current_timezone())
            if now >= slot_datetime:
                raise ValidationError(
                    {"time_slot_ids": f"Ca {slot.start_time} đã bắt đầu hoặc đã qua, không thể đặt sân nữa!"})

        five_mins_ago = timezone.now() - timedelta(minutes=5)
        conflicting_slots = BookingSlot.objects.filter(
            booking__court=court,
            booking__booking_date=booking_date,
            time_slot_id__in=time_slot_ids
        ).filter(
            models.Q(booking__status='success') |
            (models.Q(booking__status='pending_payment') & models.Q(booking__created_at__gte=five_mins_ago))
        )
        if conflicting_slots.exists():
            raise ValidationError({
                "time_slot_ids": "Khung giờ này vừa có người nhanh tay chọn mất, vui lòng chọn khung giờ khác!"
            })
        is_weekend = booking_date.weekday() >= 5
        current_day_type = 'weekend' if is_weekend else 'weekday'
        available_pricings = Pricing.objects.filter(court=court, day_type=current_day_type)


        calculated_total = 0
        for slot in time_slots:
            matching_pricing = next(
                (p for p in available_pricings if p.covers(slot.start_time, slot.end_time)),
                None
            )
            if not matching_pricing:
                raise ValidationError({"time_slot_ids": f"Chưa cấu hình giá cho ca {slot.start_time}."})
            calculated_total += matching_pricing.price_per_slot
        booking = Booking.objects.create(
            booking_code = f"BK{uuid.uuid4().hex[:8].upper()}",
            court=court,
            player=request.user,
            booking_date=booking_date,
            total_amount=calculated_total,
            status='pending_payment'
        )
        slots_to_create = [
            BookingSlot(booking=booking, time_slot=slot)
            for slot in time_slots
        ]
        BookingSlot.objects.bulk_create(slots_to_create)

        Notification.create_notification(
            user=request.user,
            title="Giữ chỗ thành công! ",
            body=f"Vui lòng thanh toán đơn {booking.booking_code} trong vòng 5 phút để hoàn tất.",
            notif_type='system',
            related_id=booking.id
        )
        return Response({
            "message": "Giữ chỗ thành công. Vui lòng thanh toán trong 5 phút.",
            "booking_id": booking.id,
            "total_amount": calculated_total,
            "expired_at": booking.created_at + timedelta(minutes=5)
        }, status=status.HTTP_201_CREATED)

    def perform_create(self, serializer):
        booking_date = serializer.validated_data.get('date')
        start_time = serializer.validated_data.get('start_time')
        slot_datetime = timezone.datetime.combine(booking_date, start_time)
        slot_datetime = timezone.make_aware(slot_datetime, timezone.get_current_timezone())

        if timezone.now() >= slot_datetime:
            raise serializer.ValidationError("Ca này đã bắt đầu hoặc đã qua, không thể đặt sân nữa!")

        serializer.save(user=self.request.user)
    @action(detail=True, methods=['get'],url_name='payment_url',url_path='get_payment_url')
    def get_payment_url(self, request, pk=None):
        booking = self.get_object()

        if booking.status != 'pending_payment':
            return Response(
                {"error": "Đơn hàng này không ở trạng thái chờ thanh toán."},
                status=status.HTTP_400_BAD_REQUEST
            )
        ip_address= get_client_ip(request)
        vnp = vnpay()
        vnp.requestData['vnp_Version'] = '2.1.0'
        vnp.requestData['vnp_Command'] = 'pay'
        vnp.requestData['vnp_TmnCode'] = settings.VNPAY_TMN_CODE
        vnp.requestData['vnp_Amount'] = int(booking.total_amount * 100)
        vnp.requestData['vnp_CurrCode'] = 'VND'
        vnp.requestData['vnp_TxnRef'] = str(booking.id)
        vnp.requestData['vnp_OrderInfo'] = (
            f'Thanh toan don dat san {booking.id}'
        )
        vnp.requestData['vnp_OrderType'] = 'billpayment'
        vnp.requestData['vnp_Locale'] = 'vn'
        vnp.requestData['vnp_CreateDate'] = datetime.now().strftime(
            '%Y%m%d%H%M%S'
        )
        vnp.requestData['vnp_IpAddr'] = ip_address
        vnp.requestData['vnp_ReturnUrl'] = settings.VNPAY_RETURN_URL

        vnpay_payment_url = vnp.get_payment_url(
            settings.VNPAY_PAYMENT_URL, settings.VNPAY_HASH_SECRET
        )

        return Response(
        {
                'booking_id': booking.id,
                'payment_url': vnpay_payment_url
        },
            status=status.HTTP_200_OK,
        )

@api_view(['GET'])
@permission_classes([AllowAny])
def payment_ipn(request):
    inputData = request.GET
    if not inputData:
        return JsonResponse({'RspCode': '99', 'Message': 'Invalid request'})

    vnp = vnpay()
    vnp.responseData = inputData.dict()
    order_id = inputData.get('vnp_TxnRef')
    vnp_response_code = inputData.get('vnp_ResponseCode')
    vnp_transaction_no = inputData.get('vnp_TransactionNo', '')
    vnp_amount = inputData.get('vnp_Amount')

    if not vnp.validate_response(settings.VNPAY_HASH_SECRET):
        return JsonResponse({'RspCode': '97', 'Message': 'Invalid Signature'})
    try:
        booking = Booking.objects.get(id=order_id)

        expected_amount = int(booking.total_amount * 100)
        if vnp_amount and int(vnp_amount) != expected_amount:
            return JsonResponse({'RspCode': '04', 'Message': 'Invalid Amount'})

        payment, _ = Payment.objects.get_or_create(
            booking=booking,
            defaults={
                'amount': booking.total_amount,
                'method': 'vnpay',
                'status': 'pending'
            }
        )
        if payment.status == 'success' or booking.status == 'confirmed':
            return JsonResponse({'RspCode': '02', 'Message': 'Order already confirmed'})

        with transaction.atomic():
            if vnp_response_code == '00':
                payment.process_success(vnp_transaction_no)

                if booking.player and booking.player.email:
                    send_booking_confirmation_email(booking)
                    Notification.create_notification(
                        user=booking.player,
                        title="Đặt sân thành công! ⚽",
                        body=f"Đơn {booking.booking_code} tại {booking.court.name} đã thanh toán thành công.",
                        notif_type='booking',
                        related_id=booking.id
                    )
            else:
                payment.process_failed()
                booking.cancel()

        return JsonResponse({'RspCode': '00', 'Message': 'Confirm Success'})

    except Booking.DoesNotExist:
        return JsonResponse({'RspCode': '01', 'Message': 'Order not found'})

    except Exception:
        return JsonResponse({'RspCode': '99', 'Message': 'Unknown error'})


@api_view(['GET'])
@permission_classes([AllowAny])
def payment_return(request):
    inputData = request.GET
    if not inputData:
        return HttpResponse("<h1>Yêu cầu không hợp lệ!</h1>", status=400)

    vnp = vnpay()
    vnp.responseData = inputData.dict()
    order_id = inputData.get('vnp_TxnRef')
    vnp_response_code = inputData.get('vnp_ResponseCode')
    vnp_transaction_no = inputData.get('vnp_TransactionNo', '')

    if vnp.validate_response(settings.VNPAY_HASH_SECRET):
        try:
            booking = Booking.objects.get(id=order_id)
            payment, _ = Payment.objects.get_or_create(
                booking=booking,
                defaults={
                    'amount': booking.total_amount,
                    'method': 'vnpay',
                    'status': 'pending'
                }
            )

            if vnp_response_code == '00':
                if payment.status != 'success':
                    payment.process_success(vnp_transaction_no)
                    Notification.create_notification(
                        user=booking.player,
                        title="Đặt sân thành công! ⚽",
                        body=f"Đơn {booking.booking_code} tại {booking.court.name} đã thanh toán thành công.",
                        notif_type='booking',
                        related_id=booking.id
                    )
                else:
                    booking.status = 'confirmed'
                    booking.save()

                html_content = f"""
                        <html>
                            <body style="text-align: center; padding-top: 50px; font-family: Arial, sans-serif;">
                                <h1 style="color: #4CAF50;">🎉 THANH TOÁN THÀNH CÔNG!</h1>
                                <p style="font-size: 18px;">Đơn hàng <b>#{order_id}</b> đã được thanh toán.</p>
                                <p style="color: #555;">Bạn có thể đóng cửa sổ trình duyệt này và quay lại ứng dụng.</p>
                            </body>
                        </html>
                        """
                return HttpResponse(html_content)
            else:
                booking.cancel()
                payment.process_failed()
                html_content = """
                        <html>
                            <body style="text-align: center; padding-top: 50px; font-family: Arial, sans-serif;">
                                <h1 style="color: #F44336;">THANH TOÁN THẤT BẠI!</h1>
                                <p style="font-size: 18px;">Giao dịch bị hủy hoặc xảy ra lỗi.</p>
                                <p style="color: #555;">Vui lòng đóng trình duyệt và thử lại trong ứng dụng.</p>
                            </body>
                        </html>
                        """
                return HttpResponse(html_content)

        except Booking.DoesNotExist:
            return HttpResponse("<h1>Đơn hàng không tồn tại trong hệ thống!</h1>", status=404)
    else:
        return HttpResponse("<h1>Sai chữ ký bảo mật (Invalid Signature)!</h1>", status=400)


class OwnerDashBoardView(APIView):
    permission_classes = [IsApprovedOwner]

    def get(self, request):
        now = timezone.now()
        first_day_of_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        my_courts = Court.objects.filter(owner=request.user)

        revenue = Booking.objects.filter(
            court__in=my_courts,
            status__in=['confirmed', 'completed'],
            created_at__gte=first_day_of_month
        ).aggregate(total=Sum('total_amount'))['total'] or 0

        status_stats = Booking.objects.filter(
            court__in=my_courts,
            created_at__gte=first_day_of_month
        ).values('status').annotate(count=Count('id'))

        return Response({
            "month": now.strftime('%m/%Y'),
            "total_revenue": float(revenue),
            "total_my_courts": my_courts.count(),
            "booking_statistics": list(status_stats),
        })