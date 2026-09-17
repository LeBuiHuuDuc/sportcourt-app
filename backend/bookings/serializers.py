from rest_framework import serializers
from .models import Booking, BookingSlot, Payment, Refund

class BookingSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = BookingSlot
        fields = ['id', 'time_slot']
class BookingSerializer(serializers.ModelSerializer):
    slots =  BookingSlotSerializer(source='bookingslot_set',many=True,read_only=True)
    time_slot_ids = serializers.ListField(child=serializers.IntegerField(),write_only=True)

    class Meta:
        model = Booking
        fields = [
            'id', 'booking_code', 'court', 'player', 'booking_date',
            'total_amount', 'status', 'created_at', 'slots', 'time_slot_ids'
        ]
        read_only_fields = ['booking_code', 'total_amount', 'status', 'player']


class PaymentSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payment
        fields = '__all__'
        read_only_fields = ['status', 'transaction_ref', 'paid_at']





