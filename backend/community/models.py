from django.conf import settings
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models

class SkillLevel(models.Model):
    LEVELS_CHOICES = (
        ('beginner', 'Mới chơi'),
        ('intermediate', 'Trung bình'),
        ('advanced', 'Khá'),
        ('pro', 'Chuyên nghiệp'),
    )
    player = models.ForeignKey('users.User', on_delete=models.DO_NOTHING)
    sport_type = models.ForeignKey('courts.SportType', on_delete=models.DO_NOTHING)
    level = models.CharField(max_length=15, choices=LEVELS_CHOICES)

    class Meta:
        db_table = 'skill_levels'

class Review(models.Model):
    booking = models.ForeignKey('bookings.Booking', on_delete=models.CASCADE)
    court = models.ForeignKey('courts.Court', on_delete=models.CASCADE)
    player = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    rating = models.IntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reviews'
        unique_together = (('booking', 'player'),)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        self.court.calculate_rating()

    def delete(self, *args, **kwargs):
        court_obj = self.court
        super().delete(*args,**kwargs)
        court_obj.calculate_rating()

class ReviewReply(models.Model):
    review = models.ForeignKey(Review, on_delete=models.CASCADE)
    replied_by = models.ForeignKey('users.User', on_delete=models.CASCADE)
    content = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'review_replies'

class PlayRequest(models.Model):
    STATUS_CHOICES = (
        ('open', 'Đang tìm người'),
        ('full', 'Đã đủ người'),
        ('closed', 'Đã đóng'),
    )
    creator = models.ForeignKey('users.User', on_delete=models.CASCADE)
    booking = models.ForeignKey('bookings.Booking', on_delete=models.CASCADE)
    desired_level = models.CharField(max_length=15, choices=SkillLevel.LEVELS_CHOICES)
    slot_number = models.IntegerField()
    note = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES,default='open')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'play_requests'

class PlayRequestParticipant(models.Model):
    STATUS_CHOICES = (
        ('pending', 'Chờ duyệt'),
        ('approved', 'Đã duyệt'),
        ('rejected', 'Từ chối'),
    )
    play_request = models.ForeignKey(PlayRequest, on_delete=models.CASCADE,related_name='participants')
    player = models.ForeignKey('users.User', on_delete=models.CASCADE)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    requested_at = models.DateTimeField(auto_now_add=True)
    note = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'play_request_participants'
        unique_together = (('play_request', 'player'),)