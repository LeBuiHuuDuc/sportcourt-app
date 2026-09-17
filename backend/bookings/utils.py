from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings
import threading

def get_client_ip(request):
    x_forwarded_ip = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded_ip:
        ip = x_forwarded_ip.split(',')[0]
    else:
        ip = request.META.get('REMOTE_ADDR')
    return ip


def send_booking_confirmation_email(booking):
    booking_code = f"BK-{booking.id:05d}"
    subject = f'Xác nhận đặt sân thành công - Mã: {booking_code}'

    html_content = f"""
    <h2>Cảm ơn bạn đã đặt sân!</h2>
    <p>Thanh toán của bạn đã được xác nhận. Dưới đây là thông tin chi tiết:</p>
    <ul>
        <li><strong>Mã đặt chỗ:</strong> <span style="color:red; font-size:18px;">{booking_code}</span></li>
        <li><strong>Sân:</strong> {booking.court.name}</li>
        <li><strong>Ngày chơi:</strong> {booking.booking_date.strftime('%d/%m/%Y')}</li>
        <li><strong>Tổng tiền:</strong> {booking.total_amount:,.0f} VNĐ</li>
    </ul>
    <p>Vui lòng đưa mã đặt chỗ này cho nhân viên khi đến sân. Chúc bạn có một trận đấu vui vẻ!</p>
    """

    text_content = strip_tags(html_content)

    msg = EmailMultiAlternatives(
        subject=subject,
        body=text_content,
        from_email=settings.EMAIL_HOST_USER,
        to=[booking.player.email],  # Gửi đến email của người đặt
    )
    msg.attach_alternative(html_content, "text/html")
    threading.Thread(target=msg.send).start()