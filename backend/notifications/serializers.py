from rest_framework import serializers
from .models import Notification

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ['id', 'title', 'body', 'type', 'related_id', 'is_read', 'created_at']
        read_only_fields = ['title', 'body', 'type', 'related_id', 'created_at']