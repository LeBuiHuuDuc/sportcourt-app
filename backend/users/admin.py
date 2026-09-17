from django.contrib import admin
from .models import User  # Thay .models bằng đường dẫn app của cậu nếu cần


@admin.register(User)
class CustomUserAdmin(admin.ModelAdmin):
    list_display = ('id', 'email', 'username', 'role', 'is_approved', 'is_active')
    list_filter = ('role', 'is_approved')
    search_fields = ('email', 'username')

    # 2. KHAI BÁO ACTION MỚI Ở ĐÂY (Nằm ngang hàng với list_display)
    actions = ['approve_selected_users']

    @admin.action(description='Phê duyệt các tài khoản đã chọn')
    def approve_selected_users(self, request, queryset):
        updated_count = queryset.update(is_approved=True)

        self.message_user(request, f'Đã phê duyệt thành công {updated_count} tài khoản!')