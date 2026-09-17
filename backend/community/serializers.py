from rest_framework import serializers
from .models import Review, PlayRequest, PlayRequestParticipant

class ReviewSerializer(serializers.ModelSerializer):
    class Meta:
        model = Review
        fields = '__all__'
        read_only_fields = ['player','booking', 'created_at']


class PlayRequestParticipantSerializer(serializers.ModelSerializer):
    class Meta:
        model = PlayRequestParticipant
        fields = '__all__'
        read_only_fields = ['status', 'requested_at']

class PlayRequestSerializer(serializers.ModelSerializer):
    participants = PlayRequestParticipantSerializer(many=True,read_only=True)
    desired_level_display = serializers.CharField(source='get_desired_level_display', read_only=True)
    creator_name = serializers.CharField(source='creator.fullname', read_only=True)

    class Meta:
        model = PlayRequest
        fields = [
            'id', 'creator', 'booking', 'desired_level', 'slot_number','creator_name',
            'note', 'status', 'created_at', 'participants','desired_level_display'
        ]
        read_only_fields = ['status', 'creator']
