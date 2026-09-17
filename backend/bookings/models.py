from django.db import models
from django.utils import timezone
from courts.models import TimeSlot



class Booking(models.Model):
    STATUS_CHOICES = (
        ('pending_payment', 'Chờ thanh toán'),
        ('confirmed', 'Đã xác nhận'),
        ('completed', 'Đã hoàn thành'),
        ('cancelled', 'Đã hủy'),
    )
    booking_code = models.CharField(max_length=20, unique=True)
    court =models.ForeignKey('courts.Court', on_delete=models.PROTECT)
    player = models.ForeignKey('users.User', on_delete=models.PROTECT)
    booking_date = models.DateTimeField(blank=True, null=True)
    total_amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending_payment')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'bookings'

    def calculate_total_amount(self):
        total = 0
        slots = self.bookingslot_set.all()
        day_type = 'weekend' if self.booking_date.weekday() >= 5 else 'weekday'
        for bs in slots:
            price = self.court.price_for(day_type,bs.time_slot.start_time,bs.time_slot.end_time)
            total += price
        self.total_amount = total
        self.save()

    def confirm(self):
        self.status = 'confirmed'
        self.save()

    def cancel(self):
        self.status = 'cancelled'
        self.save()
        self.bookingslot_set.all().delete()


class BookingSlot(models.Model):
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE)
    time_slot = models.ForeignKey('courts.TimeSlot', on_delete=models.CASCADE)

    class Meta:
        db_table = 'booking_slots'
        unique_together = (('booking', 'time_slot'),)

class Payment(models.Model):
    METHOD_CHOICES = (
        ('vnpay', 'VNPay'),
        ('cash', 'Tiền mặt'),
    )
    STATUS_CHOICES = (
        ('pending', 'Chờ xử lý'),
        ('success', 'Thành công'),
        ('failed', 'Thất bại'),
    )
    booking = models.ForeignKey(Booking, on_delete=models.CASCADE)
    method = models.CharField(max_length=10, choices=METHOD_CHOICES, default='vnpay')
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pending')
    transaction_ref= models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'payments'

    def process_success(self,trans_ref):
        self.status = 'success'
        self.transaction_ref = trans_ref
        self.paid_at = timezone.now()
        self.save()

        self.booking.confirm()
    def process_failed(self):
        self.status = 'failed'
        self.save()
class Refund(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Chờ xử lý'),
        ('processed', 'Đã hoàn tiền'),
    )
    payment = models.ForeignKey(Payment, on_delete=models.CASCADE)
    refund_percentage = models.PositiveIntegerField()
    refund_amount = models.DecimalField(max_digits=12, decimal_places=0)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    processed_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'refunds'

    def execute_refund(self):
        self.status = 'processed'
        self.processed_at = timezone.now()
        self.save()