from django.contrib.auth.models import AbstractUser
from cloudinary.models import CloudinaryField
from django.db import models

class User(AbstractUser):
    ROLE_CHOICES = (
        ('admin', 'Quản trị viên'),
        ('owner', 'Chủ sân'),
        ('player', 'Người chơi'),
    )
    email = models.EmailField(max_length=100,unique=True)
    phone = models.CharField(max_length=15,blank=True,null=True)
    fullname = models.CharField(max_length=100)
    avatar = CloudinaryField("image",null=True,blank=True)
    role = models.CharField(max_length=100,choices=ROLE_CHOICES,default='player')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    is_approved = models.BooleanField(default=False)
    is_owner_requested = models.BooleanField(default=False)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username','fullname']

    class Meta:
        db_table = 'users'

    @property
    def is_admin(self):
        return self.role == 'admin'
    @property
    def is_owner(self):
        return self.role == 'owner'
    @property
    def is_player(self):
        return self.role == 'player'
    def __str__(self):
        return f'{self.fullname} ({self.email})'

class PlayerProfile(models.Model):
    GENDER_CHOICES = (
        ('male', 'Nam'),
        ('female', 'Nữ'),
        ('other', 'Khác'),
    )
    user = models.OneToOneField(User,on_delete=models.CASCADE)
    bio = models.TextField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)
    gender = models.CharField(max_length=11,choices=GENDER_CHOICES,blank=True, null=True)

    class Meta:
        db_table = 'player_profiles'