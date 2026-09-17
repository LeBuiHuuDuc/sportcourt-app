import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';



class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> bookings = [];
  bool isLoading = true;
  

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }
  
  Future<void> fetchBookings() async {
    try {
      final response = await ApiClient().dio.get('bookings/orders/');
      if (mounted) {
        setState(() {
          if (response.data is Map<String, dynamic> && response.data.containsKey('results')) {
            bookings = response.data['results'];
          } else {
            bookings = response.data;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch sử: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showCreateMatchDialog(BuildContext context, int bookingId) {
    int slotNumber = 1;
    String desiredLevel = 'intermediate';
    final noteController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setPopupState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Đăng tìm bạn chơi', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Số người cần tìm:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: slotNumber.toDouble(),
                    min: 1, max: 10, divisions: 9,
                    label: slotNumber.toString(),
                    onChanged: (value) => setPopupState(() => slotNumber = value.toInt()),
                  ),
                  const Text('Trình độ mong muốn:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: desiredLevel,
                    onChanged: (value) => setPopupState(() => desiredLevel = value!),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'beginner', child: Text('Mới chơi')),
                      DropdownMenuItem(value: 'intermediate', child: Text('Trung bình')),
                      DropdownMenuItem(value: 'advanced', child: Text('Khá')),
                      DropdownMenuItem(value: 'pro', child: Text('Chuyên nghiệp')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'VD: Cần 2 bạn đá cánh, giao lưu vui vẻ...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                            await ApiClient().dio.post('community/playrequests/', data: {
                              'booking': bookingId,
                              'slot_number': slotNumber,
                              'desired_level': desiredLevel,
                              'note': noteController.text,
                            });
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Đã đăng bài tìm bạn chơi!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            setPopupState(() => isSubmitting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lỗi tạo bài đăng!'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Đăng bài', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return {'text': 'Đã xác nhận', 'color': Colors.green.shade700, 'bg': Colors.green.shade50, 'icon': Icons.check_circle_outline};
      case 'pending':
        return {'text': 'Chờ xác nhận', 'color': Colors.orange.shade800, 'bg': Colors.orange.shade50, 'icon': Icons.access_time_rounded};
      case 'cancelled':
        return {'text': 'Đã hủy', 'color': Colors.red.shade700, 'bg': Colors.red.shade50, 'icon': Icons.cancel_outlined};
      default:
        return {'text': status, 'color': Colors.blue.shade700, 'bg': Colors.blue.shade50, 'icon': Icons.info_outline};
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Lịch sử đặt sân', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.black87)),
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Chưa có lịch sử đặt sân nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    final statusConfig = _getStatusConfig(booking['status'] ?? 'confirmed');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long_rounded, size: 18, color: Colors.blue.shade700),
                                      const SizedBox(width: 6),
                                      Text('Mã đơn: #${booking['id'] ?? 'BK000'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: statusConfig['bg'], borderRadius: BorderRadius.circular(20)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusConfig['icon'], size: 14, color: statusConfig['color']),
                                        const SizedBox(width: 4),
                                        Text(statusConfig['text'], style: TextStyle(color: statusConfig['color'], fontWeight: FontWeight.w600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Ngày chơi:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text(booking['date'] ?? '2026-09-13', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text('Tổng tiền:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('${booking['total_amount'] ?? 0} đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue.shade700)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showCreateMatchDialog(context, booking['id']),
                                  icon: const Icon(Icons.group_add_outlined, size: 18),
                                  label: const Text('Đăng tìm bạn chơi chung'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue.shade700,
                                    side: BorderSide(color: Colors.blue.shade200),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
