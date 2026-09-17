from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

from .models import User,PlayerProfile

class UserSerializer(serializers.ModelSerializer):
    avatar = serializers.SerializerMethodField()
    class Meta:
        model = User
        fields = ['id', 'email', 'fullname', 'phone', 'password', 'avatar', 'role', 'is_active','is_owner_requested']

        extra_kwargs = {
            'password': {'write_only': True},
            'is_active': {'read_only': True},
        }
    def get_avatar(self, obj):
        if obj.avatar:
            return obj.avatar.url
        return None
    def validate_password(self, value):
        if value:
            validate_password(value)
        return  value
    def validate_role(self, value):
        if value == 'admin':
            raise serializers.ValidationError("Không thể tự đăng ký tài khoản Quản trị viên.")
        return value
    def create(self, validated_data):
        frontend_role = validated_data.pop('role', None)
        password = validated_data.pop('password')
        email = validated_data.pop('email')
        is_owner_requested = validated_data.pop('is_owner_requested', False)
        is_owner_req = validated_data.pop('is_owner_requested', None)
        if frontend_role in ['Owner', 'owner'] or str(is_owner_req).lower() == 'true':
            final_role = 'Owner'
            is_approved = False  # Chờ duyệt
        else:
            final_role = 'Player'
            is_approved = True
        user = User(
            email=email,
            username=email,
            role=final_role,
            is_active=True,
            is_approved=is_approved,
            **validated_data
        )
        user.set_password(password)
        user.save()
        if final_role.lower() == 'player':
            PlayerProfile.objects.create(user=user)
        return user
    def update(self, instance, validated_data):
        password = validated_data.pop('password',None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if password:
            instance.set_password(password)
        instance.save()
        return instance
class PlayerProfileSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    class Meta:
        model = PlayerProfile
        fields = ['id', 'user', 'bio', 'date_of_birth', 'gender']

