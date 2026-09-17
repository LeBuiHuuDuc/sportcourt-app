from rest_framework import viewsets, permissions,status
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response

from bookings.models import Booking
from .models import PlayRequest, PlayRequestParticipant, Review
from .serializers import ReviewSerializer, PlayRequestSerializer, PlayRequestParticipantSerializer



class PlayRequestViewSet(viewsets.ModelViewSet):
    serializer_class = PlayRequestSerializer
    queryset = PlayRequest.objects.all().order_by('-created_at')
    permission_classes = [permissions.IsAuthenticatedOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(creator=self.request.user)
    @action(detail=True, methods=['post'],url_path='join',permission_classes=[permissions.IsAuthenticated])
    def join_request(self, request, pk=None):
        play_request = self.get_object()
        user = request.user
        if play_request.creator == user:
            raise ValidationError({"message": "Bạn là chủ kèo này nên không cần gửi yêu cầu tham gia."})
        existing_participants = PlayRequestParticipant.objects.filter(
            play_request=play_request,
            player=user,
            ).first()
        if existing_participants:
            return Response(
                {"message": f"Bạn đã gửi yêu cầu trước đó rồi (Trạng thái hiện tại: {existing_participants.status})."},
                status=status.HTTP_400_BAD_REQUEST
            )
        accepted_count = PlayRequestParticipant.objects.filter(
            play_request=play_request,
            status = 'approved',
        ).count()
        if accepted_count >= play_request.slot_number:
            return Response(
                {"message": "Kèo này đã đủ số lượng người chơi, không thể đăng ký thêm."},
                status=status.HTTP_400_BAD_REQUEST
            )
        participant = PlayRequestParticipant.objects.create(
            play_request=play_request,
            player=user,
            status='pending',
            note=request.data.get('note','')
        )
        serializer = PlayRequestParticipantSerializer(participant)
        return Response({
            "message": "Gửi yêu cầu tham gia thành công! Vui lòng chờ người tạo duyệt.",
            "data": serializer.data
        }, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['patch'], url_path='approve/(?P<participant_id>[^/.]+)',
            permission_classes=[permissions.IsAuthenticated])
    def approve_participant(self, request, pk=None, participant_id=None):
        play_request = self.get_object()
        if play_request.creator != request.user:
            raise ValidationError({"message": "Chỉ chủ kèo mới có quyền duyệt người tham gia."})

        try:
            participant = play_request.participants.get(id=participant_id)
        except PlayRequestParticipant.DoesNotExist:
            raise ValidationError({"message": "Không tìm thấy yêu cầu tham gia này."})

        accepted_count = play_request.participants.filter(status='approved').count()
        if accepted_count >= play_request.slot_number:
            raise ValidationError({"message": "Kèo đã đủ người, không thể duyệt thêm."})

        participant.status = 'approved'
        participant.save()

        if accepted_count + 1 >= play_request.slot_number:
            play_request.status = 'full'
            play_request.save()

        return Response({"message": "Duyệt thành công."})
class ReviewViewSet(viewsets.ModelViewSet):
    serializer_class = ReviewSerializer
    queryset = Review.objects.all().order_by('-created_at')
    permission_classes = [permissions.IsAuthenticated]


    def perform_create(self, serializer):
        court = serializer.validated_data['court']
        user = self.request.user

        existing_booking = Booking.objects.filter(
            player=user,
            court=court
        ).first()

        if not existing_booking:
            raise ValidationError({
                "detail": "Bạn cần phải đặt sân này ít nhất một lần thì mới có thể viết đánh giá."
            })
        if Review.objects.filter(booking=existing_booking, player=user).exists():
            raise ValidationError({
                "detail": "Bạn đã viết đánh giá cho lượt đặt sân này rồi, không thể đánh giá thêm!"
            })
        serializer.save(player=user, booking=existing_booking)
