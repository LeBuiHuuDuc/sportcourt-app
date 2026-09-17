from rest_framework import serializers
from .models import ComplexSetting, SportType, Court, Pricing, TimeSlot

class ComplexSettingSerializer(serializers.ModelSerializer):
    class Meta:
        model = ComplexSetting
        fields = '__all__'

class SportTypeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SportType
        fields = '__all__'

class PricingSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pricing
        fields = '__all__'

class TimeSlotSerializer(serializers.ModelSerializer):
    class Meta:
        model = TimeSlot
        fields = '__all__'

class CourtSerializer(serializers.ModelSerializer):
    sport_type_name = SportTypeSerializer(source='sport_type', read_only=True)
    pricing_rules = PricingSerializer(many=True, read_only=True)
    amenities = serializers.StringRelatedField(many=True, read_only=True)
    location = serializers.CharField(source='complex.address', read_only=True)
    complex_name = serializers.CharField(source='complex.name', read_only=True)
    image = serializers.SerializerMethodField()
    reviews = serializers.SerializerMethodField()
    class Meta:
        model = Court
        fields = [
            'id', 'complex', 'name', 'sport_type', 'sport_type_name',
            'owner', 'description', 'image', 'is_active','reviews',
            'average_rating', 'total_rating', 'pricing_rules','amenities','location','complex_name',
        ]
        read_only_fields = ['owner']

    def get_image(self, obj):
        if obj.image:
            return obj.image.url
        return None

    def get_reviews(self, obj):
        reviews = obj.review_set.all().order_by('-created_at')
        return [
            {
                "user_name": r.player.fullname if r.player.fullname else r.player.username,
                "rating": r.rating,
                "comment": r.comment,
                "created_at": r.created_at.strftime('%d-%m-%Y %H:%M')
            } for r in reviews
        ]