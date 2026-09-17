from django.conf import settings
from django.db import models
from django.db.models import Avg
from cloudinary.models import CloudinaryField

class ComplexSetting(models.Model):
    name = models.CharField(max_length=150)
    address = models.CharField(max_length=255)
    open_time = models.TimeField()
    close_time = models.TimeField()
    description = models.TextField(blank=True, null=True)

    class Meta:
        db_table = 'complex_settings'

class Amenity(models.Model):
    name = models.CharField(max_length=150)
    def __str__(self):
        return self.name
class SportType(models.Model):
    name = models.CharField(max_length=50)
    icon_url = models.CharField(max_length=500, blank=True, null=True)
    class Meta:
        db_table = 'sport_types'

class Court(models.Model):
    complex = models.ForeignKey(ComplexSetting, on_delete=models.CASCADE)
    name = models.CharField(max_length=100)
    sport_type = models.ForeignKey(SportType, on_delete=models.PROTECT)
    owner = models.ForeignKey('users.User', on_delete=models.PROTECT)
    description = models.TextField(blank=True, null=True)
    image = CloudinaryField('image', blank=True, null=True)
    is_active = models.BooleanField(default=True)
    average_rating = models.FloatField(blank=True, null=True)
    total_rating = models.FloatField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    amenities = models.ManyToManyField(Amenity,blank=True,related_name='courts')
    class Meta:
         db_table = 'courts'

    def price_for(self, day_type, start_time, end_time):
        rule = self.pricing_rules.filter(
            day_type=day_type,
            start_time__lte=start_time,
            end_time__gte=end_time
        ).first()
        if rule:
            return rule.price_per_slot
        return 0
    def calculate_rating(self):
        avg = self.review_set.aggregate(Avg('rating'))['rating__avg']
        self.average_rating = avg or 0.0
        self.save(update_fields=['average_rating'])


class Pricing(models.Model):
    DAY_TYPE_CHOICES = (
        ('weekday', 'Ngày thường'),
        ('weekend', 'Cuối tuần'),
    )
    court = models.ForeignKey(Court, on_delete=models.CASCADE,related_name='pricing_rules')
    day_type = models.CharField(max_length=10, choices=DAY_TYPE_CHOICES)
    start_time = models.TimeField()
    end_time = models.TimeField()
    price_per_slot = models.DecimalField(max_digits=10, decimal_places=0)

    class Meta:
        db_table = 'pricing_rules'

    def covers(self,check_start_time,check_end_time):
        return self.start_time <= check_start_time and self.end_time >= check_end_time
    def __str__(self):
        return f"{self.court.name} | {self.get_day_type_display()} | {self.start_time.strftime('%H:%M')} - {self.end_time.strftime('%H:%M')} | {self.price_per_slot:,.0f} đ"

class TimeSlot(models.Model):
    court = models.ForeignKey(Court, on_delete=models.CASCADE)
    start_time = models.TimeField()
    end_time = models.TimeField()
    class Meta:
        db_table = 'time_slots'
        ordering = ['start_time']
