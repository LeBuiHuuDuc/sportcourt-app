import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/booking_screen.dart';
import 'package:frontend/services/api_client.dart';

class CourtDetailScreen extends StatefulWidget {
  final Map<String, dynamic> courtData;
  const CourtDetailScreen({super.key, required this.courtData});
  @override
  State<CourtDetailScreen> createState() => _CourtDetailScreenState();
}
class _CourtDetailScreenState extends State<CourtDetailScreen> {
  List<dynamic> localReviews = [];
  @override
  void initState() {
    super.initState();
    localReviews = List.from(widget.courtData['reviews'] ?? []);
  }


  void _showReview(BuildContext context){
    int rating = 5;
    final TextEditingController commentController = TextEditingController();
    bool isSubmitting = false;
    showDialog(
      context: context, 
      builder:(context) {
        return StatefulBuilder(
          builder: (context,setPopupState){
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Viết đánh giá', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setPopupState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16,),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn về sân này...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setPopupState(() => isSubmitting = true);
                          try {
                            await ApiClient().dio.post(
                              'community/reviews/',
                              data: {
                                'court': widget.courtData['id'], 
                                'rating': rating,
                                'comment': commentController.text,
                              },
                            );
                            
                            if (context.mounted) {
                              setState(() {
                                localReviews.insert(0, {
                                  'user_name': 'Bạn (Vừa xong)',
                                  'rating': rating,
                                  'comment': commentController.text,
                                });
                              });

                              Navigator.pop(context); // Đóng popup
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cảm ơn bạn đã đánh giá!'), 
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setPopupState(() => isSubmitting = false);
                            if (context.mounted) {
                              String errorMsg = 'Có lỗi xảy ra, vui lòng thử lại!';
                              if (e is DioException && e.response?.data != null) {
                                final data = e.response?.data;
                                if (data is Map && data.containsKey('detail')) {
                                  errorMsg = data['detail'];
                                }
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                              );
                            } 
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Gửi', style: TextStyle(color: Colors.white)),
                )
              ],
            );
            }
          );
        } 
      );
   }
  @override
  Widget build(BuildContext context) {
    final List<dynamic> amenities = widget.courtData['amenities'] ?? [];
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.courtData['name'] ?? 'Chi tiết sân',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  fontSize: 16,
                ),
              ),
              background: Image.network(
                widget.courtData['image'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.green[700],
                  child: const Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.courtData['sport_type_name']['name'] ?? 'Thể thao',
                          style: TextStyle(
                            color: Colors.blue.shade700,  
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon( Icons.star, color: Colors.orange, size: 22,                      ),
                          const SizedBox(width: 4),
                          Text(
                            widget.courtData['average_rating']?.toString() ?? '5.0',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          widget.courtData['location'] ?? 'Chưa cập nhật địa chỉ',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1, color: Colors.black12),
                  const Text(
                    'Tiện ích',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  amenities.isEmpty
                      ? const Text('Đang cập nhật tiện ích', style: TextStyle(color: Colors.grey))
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: amenities.map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12,vertical: 8,),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    tag.toString(),
                                    style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                  const Divider(height: 40, thickness: 1, color: Colors.black12),
                  const Text(
                    'Giới thiệu',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.courtData['description'] ?? 'Chưa có giới thiệu về sân',
                    style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.6),
                  ),
                  const Divider(height: 40, thickness: 1, color: Colors.black12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng viết đánh giá đang được xây dựng!')),
                          );
                        },
                        child: TextButton(
                          onPressed: () => _showReview(context), // Gọi hàm mở Popup
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero, // Bỏ padding thừa
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Viết đánh giá',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  localReviews.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            'Chưa có đánh giá nào cho sân này.',
                            style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                          ),
                        )
                      : Column(
                          children: localReviews.map((review) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      radius: 16,
                                      child: const Icon(Icons.person, size: 20, color: Colors.blue),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        review['user_name'] ?? 'Người dùng ẩn danh',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(
                                        review['rating'] ?? 5,
                                        (index) => const Icon(Icons.star, color: Colors.amber, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  review['comment'] ?? '',
                                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                                ),
                              ],
                            ),
                          )).toList(),
                        ),
                  const SizedBox(height: 12,),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity, 
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingScreen(courtData: widget.courtData),
                  ),
                );
              },
              child: const Text(
                'Chọn ngày & giờ đặt sân',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
