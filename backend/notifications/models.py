from django.conf import settings
from django.db import models

class Notification(models.Model):
    TYPE_CHOICES = (
        ('booking', 'Thông báo đặt sân'),
        ('review', 'Thông báo đánh giá'),
        ('play_request', 'Thông báo tìm bạn chơi'),
        ('system', 'Thông báo hệ thống'),
    )
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    title = models.CharField(max_length=150)
    body = models.TextField()
    type = models.CharField(max_length=50, choices=TYPE_CHOICES)
    related_id = models.BigIntegerField(blank=True, null=True)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'

    def mark_as_read(self):
        self.is_read = True
        self.save(update_fields=['is_read'])

    @classmethod
    def create_notification(cls,user, title, body, notif_type, related_id=None):
        return cls.objects.create(
            user=user,
            title=title,
            body=body,
            type=notif_type,
            related_id=related_id
        )
