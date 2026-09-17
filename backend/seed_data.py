import os
import django
from datetime import time, timedelta, datetime
from decimal import Decimal
import random

# 1. Khởi tạo môi trường Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()


from django.contrib.auth.hashers import make_password
from users.models import User, PlayerProfile
from courts.models import ComplexSetting, SportType, Court, Pricing, TimeSlot, Amenity



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
            "is_staff": True,
            "is_active": True,
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
            "is_approved": True
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
    # 3. MỘT KHU PHỨC HỢP DUY NHẤT
    # ==========================================
    main_complex, _ = ComplexSetting.objects.get_or_create(
        name="Khu Phức Hợp Thể Thao SportCourt Central",
        defaults={
            "address": "98 Võ Văn Tần, P. Xuân Hòa, TP. Hồ Chí Minh",
            "open_time": time(5, 30),
            "close_time": time(23, 30),
            "description": "Tổ hợp thể thao đa năng với hệ thống sân bóng đá, cầu lông, pickleball và bóng rổ, đáp ứng nhu cầu luyện tập, thi đấu và vui chơi thể thao.",
        }
    )

    # ==========================================
    # 4. TIỆN ÍCH (AMENITIES) & MÔN THỂ THAO
    # ==========================================

    # Tiện ích cơ bản
    wifi, _ = Amenity.objects.get_or_create(name="Free Wifi")
    parking, _ = Amenity.objects.get_or_create(name="Bãi đỗ ô tô")
    water, _ = Amenity.objects.get_or_create(name="Quầy nước/Canteen")
    referee, _ = Amenity.objects.get_or_create(name="Thuê trọng tài")
    shoes, _ = Amenity.objects.get_or_create(name="Thuê giày/Vợt")
    shower, _ = Amenity.objects.get_or_create(name="Phòng tắm/Thay đồ")
    air_conditioner, _ = Amenity.objects.get_or_create(name="Điều hòa")
    lighting, _ = Amenity.objects.get_or_create(name="Hệ thống đèn chiếu sáng")
    locker, _ = Amenity.objects.get_or_create( name="Tủ gửi đồ")
    waiting_area, _ = Amenity.objects.get_or_create(name="Khu vực nghỉ ngơi")
    first_aid, _ = Amenity.objects.get_or_create(name="Tủ thuốc sơ cứu")
    camera, _ = Amenity.objects.get_or_create(name="Camera an ninh")
    equipment, _ = Amenity.objects.get_or_create(name="Cho thuê dụng cụ thể thao")
    scoreboard, _ = Amenity.objects.get_or_create( name="Bảng điểm điện tử")
    water_station, _ = Amenity.objects.get_or_create(name="Nước uống miễn phí" )
    wifi_5g, _ = Amenity.objects.get_or_create(name="Wifi tốc độ cao")

    # Môn thể thao
    sport_fb, _ = SportType.objects.get_or_create(name="Bóng đá")
    sport_bm, _ = SportType.objects.get_or_create(name="Cầu lông")
    sport_pb, _ = SportType.objects.get_or_create(name="Pickleball")
    sport_bb, _ = SportType.objects.get_or_create(name="Bóng rổ")

    # ==========================================
    # 5. TẠO 14 SÂN
    # ==========================================

    courts_data = [

        # ================= BÓNG ĐÁ =================

        {
            "name": "Sân Bóng Đá Số 1 (VIP)", "type": sport_fb, "owner": owner_fb, "base_price": 400000,
            "image": "v1789271821/OIP_4.webp",
            "description": "Sân bóng đá VIP với mặt sân chất lượng cao, hệ thống chiếu sáng tốt và không gian rộng rãi. Phù hợp cho các trận đấu giao hữu, luyện tập và thi đấu vào buổi tối.",
            "am": [wifi, parking, water, referee, shower, lighting, locker, waiting_area, first_aid, camera]
        },
        {
            "name": "Sân Bóng Đá Số 2", "type": sport_fb, "owner": owner_fb, "base_price": 300000,
            "image": "v1789271820/OIP_7.webp",
            "description": "Sân bóng đá có mặt sân bằng phẳng, không gian thoáng và hệ thống đèn hỗ trợ thi đấu vào buổi tối. Phù hợp cho các nhóm bạn thường xuyên luyện tập.",
            "am": [parking, water, shoes, lighting, camera, first_aid, waiting_area]
        },
        {
            "name": "Sân Bóng Đá Số 3", "type": sport_fb, "owner": owner_fb, "base_price": 300000,
            "image": "v1789271820/OIP_6.webp",
            "description": "Sân bóng đá được bố trí thuận tiện cho các trận đấu phong trào và luyện tập hàng tuần. Khu vực sân có hệ thống chiếu sáng và khu vực nghỉ ngơi dành cho người chơi.",
            "am": [parking, water, lighting, camera, waiting_area, first_aid]
        },
        {
            "name": "Sân Bóng Đá Số 4 (Có mái che)", "type": sport_fb, "owner": owner_fb, "base_price": 450000,
            "image": "v1789271821/th.webp",
            "description": "Sân bóng đá có mái che, giúp người chơi hạn chế ảnh hưởng của thời tiết trong quá trình thi đấu. Không gian sân rộng, hệ thống chiếu sáng tốt và có khu vực thay đồ tiện lợi.",
            "am": [parking, water, shower, lighting, locker, waiting_area, camera, first_aid]
        },
        {
            "name": "Sân Bóng Đá Số 5", "type": sport_fb, "owner": owner_fb, "base_price": 250000,
            "image": "v1789271820/OIP_5.webp",
            "description": "Sân bóng đá có mức giá phù hợp cho các nhóm sinh viên và người chơi phong trào. Sân được trang bị hệ thống đèn và khu vực nước uống, đáp ứng nhu cầu luyện tập cơ bản.",
            "am": [water, lighting, camera, first_aid, waiting_area]
        },

        # ================= CẦU LÔNG =================

        {
            "name": "Sân Cầu Lông Thảm A", "type": sport_bm, "owner": owner_bm, "base_price": 120000,
            "image": "v1789271821/download_1.webp",
            "description": "Sân cầu lông sử dụng thảm chuyên dụng, không gian sạch sẽ và hệ thống ánh sáng phù hợp cho luyện tập. Sân thích hợp cho cả người chơi cá nhân và các nhóm bạn.",
            "am": [wifi, parking, shoes, shower, lighting, locker, waiting_area, camera]
        },
        {
            "name": "Sân Cầu Lông Thảm B", "type": sport_bm, "owner": owner_bm, "base_price": 120000,
            "image": "v1789271821/download_2.webp",
            "description": "Sân cầu lông có mặt thảm tốt, hệ thống chiếu sáng ổn định và khu vực nghỉ ngơi dành cho người chơi. Phù hợp cho luyện tập cá nhân, đánh đôi và các buổi giao lưu.",
            "am": [wifi, parking, shoes, lighting, locker, waiting_area, first_aid, camera]
        },
        {
            "name": "Sân Cầu Lông Thảm C", "type": sport_bm, "owner": owner_bm, "base_price": 100000,
            "image": "v1789271821/download.webp",
            "description": "Sân cầu lông có mức giá hợp lý, không gian thoáng và đầy đủ các tiện ích cơ bản. Đây là lựa chọn phù hợp cho sinh viên và người chơi muốn luyện tập thường xuyên.",
            "am": [parking, water, lighting, waiting_area, camera, first_aid]
        },
        {
            "name": "Sân Cầu Lông VIP", "type": sport_bm, "owner": owner_bm, "base_price": 150000,
            "image": "v1789271821/OIP_3.webp",
            "description": "Sân cầu lông VIP được trang bị không gian luyện tập hiện đại, thảm chất lượng cao và hệ thống chiếu sáng tốt. Sân phù hợp cho những buổi luyện tập chuyên sâu và các trận giao lưu.",
            "am": [wifi, parking, water, shoes, shower, lighting, locker, air_conditioner, waiting_area, camera,
                   first_aid]
        },

        # ================= PICKLEBALL =================

        {
            "name": "Sân Pickleball Chuẩn Thi Đấu 1", "type": sport_pb, "owner": owner_pb, "base_price": 180000,
            "image": "v1789271821/OIP_2.webp",
            "description": "Sân pickleball được thiết kế theo tiêu chuẩn thi đấu, mặt sân bằng phẳng và có hệ thống chiếu sáng hỗ trợ các trận đấu buổi tối. Phù hợp cho cả luyện tập và thi đấu.",
            "am": [parking, water, shoes, lighting, locker, waiting_area, camera, first_aid, scoreboard]
        },
        {
            "name": "Sân Pickleball Chuẩn Thi Đấu 2", "type": sport_pb, "owner": owner_pb, "base_price": 180000,
            "image": "v1789271821/OIP_1.webp",
            "description": "Sân pickleball rộng rãi với khu vực thi đấu được bố trí rõ ràng. Hệ thống chiếu sáng và khu vực nghỉ ngơi giúp người chơi có trải nghiệm thuận tiện trong suốt buổi chơi.",
            "am": [parking, water, shoes, lighting, waiting_area, locker, camera, first_aid]
        },
        {
            "name": "Sân Pickleball Tập Luyện", "type": sport_pb, "owner": owner_pb, "base_price": 140000,
            "image": "v1789272536/OIP_8.webp",
            "description": "Sân pickleball dành cho luyện tập với mức giá phù hợp. Không gian thoáng, có đầy đủ các tiện ích cơ bản và hỗ trợ người chơi làm quen với bộ môn pickleball.",
            "am": [water, shoes, lighting, waiting_area, camera, first_aid]
        },

        # ================= BÓNG RỔ =================

        {
            "name": "Sân Bóng Rổ Trong Nhà 1", "type": sport_bb, "owner": owner_bb, "base_price": 250000,
            "image": "v1789268164/indoor-basketball-court-hardwood-floor-blue-padded-walls-hoop-net-empty-sport-arena-wooden-flooring-lighting-game-competition-385681607.webp",
            "description": "Sân bóng rổ trong nhà với không gian rộng, mặt sàn phù hợp cho luyện tập và thi đấu. Khu vực sân được trang bị hệ thống chiếu sáng tốt, bảng điểm điện tử và khu vực nghỉ ngơi.",
            "am": [wifi, parking, water, shower, lighting, locker, air_conditioner, waiting_area, camera, first_aid,
                   scoreboard]
        },
        {
            "name": "Sân Bóng Rổ Ngoài Trời 2", "type": sport_bb, "owner": owner_bb, "base_price": 150000,
            "image": "v1789268246/OIP.webp",
            "description": "Sân bóng rổ ngoài trời có không gian thoáng và phù hợp cho các buổi luyện tập, giao lưu cùng bạn bè. Sân có hệ thống chiếu sáng giúp người chơi có thể sử dụng vào buổi chiều và buổi tối.",
            "am": [parking, water, lighting, waiting_area, camera, first_aid]
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
