from rest_framework import viewsets, permissions,status,mixins
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Notification
from .serializers import NotificationSerializer

class NotificationViewSet(mixins.ListModelMixin,
                          mixins.RetrieveModelMixin,
                          mixins.DestroyModelMixin,
                          viewsets.GenericViewSet):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user).order_by('-created_at')


    @action(detail=True, methods=['patch'], url_path='read')
    def mark_notification_read(self, request, pk=None):
        notification = self.get_object()
        if notification.is_read:
            return Response({'message': 'Thông báo này đã được đọc từ trước.'})

        notification.mark_as_read()
        return Response({'message': 'Đã đánh dấu là đã đọc thành công.'})

    @action(detail=False, methods=['patch'], url_path='read-all')
    def mark_all_read(self, request):
        unread_notifications = self.get_queryset().filter(is_read=False)
        count = unread_notifications.count()
        unread_notifications.update(is_read=True)
        return Response({'message': f'Đã đánh dấu {count} thông báo là đã đọc.'}, status=status.HTTP_200_OK)