import os
import django
from datetime import time, timedelta, datetime
from decimal import Decimal
import random

# 1. Khởi tạo môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.utils import timezone
from django.contrib.auth.hashers import make_password  # 👈 Import hàm băm mật khẩu
from users.models import User, PlayerProfile
from courts.models import ComplexSetting, SportType, Court, Pricing, TimeSlot, Amenity
from bookings.models import Booking, BookingSlot, Payment


def seed():
    print("🚀 Bắt đầu nạp dữ liệu: 1 Khu phức hợp - 14 Sân - Đầy đủ tiện ích...")

    # ==========================================
    # 1. USERS & PROFILES (Đã thêm Password và is_approved)
    # ==========================================
    # Mật khẩu chung dễ test
    default_password = make_password('123456')

    admin_user, _ = User.objects.get_or_create(
        email="admin@sportcourt.vn",
        defaults={
            "username": "admin",
            "fullname": "Admin System",
            "password": default_password,
            "role": "admin",
            "is_superuser": True,
            "is_approved": True
        }
    )

    owner_fb, _ = User.objects.get_or_create(
        email="owner.bongda@sportcourt.vn",
        defaults={
            "username": "owner_bongda",
            "fullname": "Nguyễn Văn Nam (Bóng Đá)",
            "password": default_password,
            "role": "owner",
            "is_approved": True  # 👈 Đã duyệt để vào được Dashboard
        }
    )

    owner_bm, _ = User.objects.get_or_create(
        email="owner.caulong@sportcourt.vn",
        defaults={
            "username": "owner_caulong",
            "fullname": "Trần Thị Lan (Cầu Lông)",
            "password": default_password,
            "role": "owner",
            "is_approved": True
        }
    )

    owner_pb, _ = User.objects.get_or_create(
        email="owner.pickleball@sportcourt.vn",
        defaults={
            "username": "owner_pickleball",
            "fullname": "Phạm Quốc Hùng (Pickleball)",
            "password": default_password,
            "role": "owner",
            "is_approved": True
        }
    )

    owner_bb, _ = User.objects.get_or_create(
        email="owner.bongro@sportcourt.vn",
        defaults={
            "username": "owner_bongro",
            "fullname": "Lê Trọng Tấn (Bóng Rổ)",
            "password": default_password,
            "role": "owner",
            "is_approved": True
        }
    )

    # ==========================================
    # 2. TIỆN ÍCH (AMENITIES) & MÔN THỂ THAO
    # ==========================================
    wifi, _ = Amenity.objects.get_or_create(name="Free Wifi")
    parking, _ = Amenity.objects.get_or_create(name="Bãi đỗ ô tô")
    water, _ = Amenity.objects.get_or_create(name="Quầy nước/Canteen")
    referee, _ = Amenity.objects.get_or_create(name="Thuê trọng tài")
    shoes, _ = Amenity.objects.get_or_create(name="Thuê giày/Vợt")
    shower, _ = Amenity.objects.get_or_create(name="Phòng tắm/Thay đồ")

    sport_fb, _ = SportType.objects.get_or_create(name="Bóng đá")
    sport_bm, _ = SportType.objects.get_or_create(name="Cầu lông")
    sport_pb, _ = SportType.objects.get_or_create(name="Pickleball")
    sport_bb, _ = SportType.objects.get_or_create(name="Bóng rổ")

    # ==========================================
    # 3. MỘT KHU PHỨC HỢP DUY NHẤT
    # ==========================================
    main_complex, _ = ComplexSetting.objects.get_or_create(
        name="Khu Phức Hợp Thể Thao SportCourt Central",
        defaults={
            "address": "101 Xuân Thủy, Cầu Giấy, Hà Nội",
            "open_time": time(5, 30),
            "close_time": time(23, 30),
            "description": "Tổ hợp thể thao lớn nhất khu vực với hơn 14 sân đạt chuẩn."
        }
    )

    # ==========================================
    # 4. TẠO 14 SÂN (COURTS) & GẮN TIỆN ÍCH
    # ==========================================
    print("-> Đang xây dựng 14 sân...")

    courts_data = [
        # ================= BÓNG ĐÁ =================
        {
            "name": "Sân Bóng Đá Số 1 (VIP)", "type": sport_fb, "owner": owner_fb, "base_price": 400000,
            "image": "v1789271821/OIP_4.webp",
            "am": [wifi, parking, water, referee, shower]
        },
        {
            "name": "Sân Bóng Đá Số 2", "type": sport_fb, "owner": owner_fb, "base_price": 300000,
            "image": "v1789271820/OIP_7.webp",
            "am": [parking, water, shoes]
        },
        {
            "name": "Sân Bóng Đá Số 3", "type": sport_fb, "owner": owner_fb, "base_price": 300000,
            "image": "v1789271820/OIP_6.webp",
            "am": [parking, water]
        },
        {
            "name": "Sân Bóng Đá Số 4 (Có mái che)", "type": sport_fb, "owner": owner_fb, "base_price": 450000,
            "image": "v1789271821/th.webp",
            "am": [parking, water, shower]
        },
        {
            "name": "Sân Bóng Đá Số 5", "type": sport_fb, "owner": owner_fb, "base_price": 250000,
            "image": "v1789271820/OIP_5.webp",
            "am": [water]
        },

        # ================= CẦU LÔNG =================
        {
            "name": "Sân Cầu Lông Thảm A", "type": sport_bm, "owner": owner_bm, "base_price": 120000,
            "image": "v1789271821/download_1.webp",
            "am": [wifi, parking, shoes, shower]
        },
        {
            "name": "Sân Cầu Lông Thảm B", "type": sport_bm, "owner": owner_bm, "base_price": 120000,
            "image": "v1789271821/download_2.webp",
            "am": [wifi, parking, shoes]
        },
        {
            "name": "Sân Cầu Lông Thảm C", "type": sport_bm, "owner": owner_bm, "base_price": 100000,
            "image": "v1789271821/download.webp",
            "am": [parking, water]
        },
        {
            "name": "Sân Cầu Lông VIP", "type": sport_bm, "owner": owner_bm, "base_price": 150000,
            "image": "v1789271821/OIP_3.webp",
            "am": [wifi, parking, water, shoes, shower]
        },

        # ================= PICKLEBALL =================
        {
            "name": "Sân Pickleball Chuẩn Thi Đấu 1", "type": sport_pb, "owner": owner_pb, "base_price": 180000,
            "image": "v1789271821/OIP_2.webp",
            "am": [parking, water, shoes]
        },
        {
            "name": "Sân Pickleball Chuẩn Thi Đấu 2", "type": sport_pb, "owner": owner_pb, "base_price": 180000,
            "image": "v1789271821/OIP_1.webp",
            "am": [parking, water, shoes]
        },
        {
            "name": "Sân Pickleball Tập Luyện", "type": sport_pb, "owner": owner_pb, "base_price": 140000,
            "image": "v1789272536/OIP_8.webp",
            "am": [water, shoes]
        },

        # ================= BÓNG RỔ =================
        {
            "name": "Sân Bóng Rổ Trong Nhà 1", "type": sport_bb, "owner": owner_bb, "base_price": 250000,
            "image": "v1789268164/indoor-basketball-court-hardwood-floor-blue-padded-walls-hoop-net-empty-sport-arena-wooden-flooring-lighting-game-competition-385681607.webp",
            "am": [wifi, parking, water, shower]
        },
        {
            "name": "Sân Bóng Rổ Ngoài Trời 2", "type": sport_bb, "owner": owner_bb, "base_price": 150000,
            "image": "v1789268246/OIP.webp",
            "am": [parking, water]
        },
    ]

    # 5. Insert sân và BẢNG GIÁ CHI TIẾT vào Database
    for data in courts_data:
        court, created = Court.objects.get_or_create(
            name=data["name"],
            defaults={
                "complex": main_complex,
                "sport_type": data["type"],
                "owner": data["owner"],
                "image": data["image"],
                "description": f"Trải nghiệm tuyệt vời tại {data['name']}.",
                "is_active": True,
                "average_rating": random.choice([4.5, 4.7, 4.9, 5.0])
            }
        )

        if created:
            court.amenities.set(data["am"])

            base_price = Decimal(data["base_price"])
            hot_price = base_price + Decimal(50000)

            # Khung 1: Ngày thường - Giờ hành chính (06:00 - 16:00)
            Pricing.objects.create(
                court=court,
                day_type='weekday',
                start_time=time(6, 0),
                end_time=time(18, 0),
                price_per_slot=base_price
            )

            # Khung 2: Ngày thường - Giờ Vàng (16:00 - 22:00)
            Pricing.objects.create(
                court=court,
                day_type='weekday',
                start_time=time(18, 0),
                end_time=time(22, 30),
                price_per_slot=hot_price
            )

            # Khung 3: Cuối tuần - Cả ngày (06:00 - 22:00)
            Pricing.objects.create(
                court=court,
                day_type='weekend',
                start_time=time(6, 0),
                end_time=time(22, 30),
                price_per_slot=hot_price
            )

        current_time = time(6, 0)
        closing_time = time(22, 30)
        while current_time < closing_time:
            start_dt = datetime.combine(datetime.today(), current_time)
            end_dt = start_dt + timedelta(minutes=90)
            end_time = end_dt.time()

            if end_time > closing_time:
                break

            TimeSlot.objects.get_or_create(
                court=court,
                start_time=current_time,
                end_time=end_time
            )
            current_time = end_time

    print(f"🎉 Hoàn tất! Đã tạo 1 Khu phức hợp, 14 Sân với hình ảnh xịn sò!")


if __name__ == '__main__':
    seed()
