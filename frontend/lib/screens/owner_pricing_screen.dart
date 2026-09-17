import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';

class OwnerPricingScreen extends StatefulWidget {
  final Map<String, dynamic> court;
  const OwnerPricingScreen({super.key,required this.court});

  @override
  State<OwnerPricingScreen> createState() => _OwnerPricingScreenState();
}
class _OwnerPricingScreenState extends State<OwnerPricingScreen>{
  List<dynamic> pricingList = [];
  bool isLoading = true;
  List<dynamic> pricingRules = [];
  @override
  void initState() {
    super.initState();
    pricingRules = List.from(widget.court['pricing_rules'] ?? []);
  
  debugPrint('🔥 Các khung giờ giá nhận được: $pricingRules');
    fetchPricing();
  }
  Future<void> fetchPricing() async {
    try{
      final int courtId = widget.court['id'];
      final response = await ApiClient().dio.get('owner/courts/$courtId/pricings/');
      if (mounted) {
        setState(() {
          pricingList = response.data;
          isLoading = false;
        });
      }
    } catch(e){
      debugPrint('Lỗi tải bảng giá: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> deletePricing(int pricingId) async {
    try {
      await ApiClient().dio.delete('owner/pricings/$pricingId/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa khung giá thành công!')));
      fetchPricing();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi xóa!'), backgroundColor: Colors.red));
    }
  }
  Future<void> _showAddPricingDialog() async {
    String selectedDayType = 'weekday'; 
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    final TextEditingController priceController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm khung giá mới', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Loại ngày
                    DropdownButtonFormField<String>(
                      initialValue: selectedDayType,
                      decoration: const InputDecoration(labelText: 'Loại ngày', prefixIcon: Icon(Icons.calendar_today)),
                      items: const [
                        DropdownMenuItem(value: 'weekday', child: Text('Ngày thường (T2 - T6)')),
                        DropdownMenuItem(value: 'weekend', child: Text('Cuối tuần (T7 - CN)')),
                      ],
                      onChanged: (value) => setDialogState(() => selectedDayType = value!),
                    ),
                    const SizedBox(height: 16),
                    
                    // Chọn Giờ Bắt Đầu
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                      title: Text(startTime == null ? 'Chọn giờ bắt đầu' : 'Từ: ${startTime!.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 6, minute: 0));
                        if (time != null) setDialogState(() => startTime = time);
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Chọn Giờ Kết Thúc
                    ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade400)),
                      title: Text(endTime == null ? 'Chọn giờ kết thúc' : 'Đến: ${endTime!.format(context)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                        if (time != null) setDialogState(() => endTime = time);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Nhập Giá
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Giá tiền mỗi ca (VNĐ)', prefixIcon: Icon(Icons.attach_money)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (startTime == null || endTime == null || priceController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đủ thông tin!'), backgroundColor: Colors.orange));
                            return;
                          }

                          // Định dạng giờ chuẩn HH:MM:00 gửi lên Backend
                          String formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

                          setDialogState(() => isSubmitting = true);
                          try {
                            // Gọi API tạo Pricing
                            await ApiClient().dio.post(
                              'owner/pricings/',
                              data: {
                                'court': widget.court['id'],
                                'day_type': selectedDayType,
                                'start_time': formatTime(startTime!),
                                'end_time': formatTime(endTime!),
                                'price_per_slot': int.parse(priceController.text),
                              },
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm khung giá!'), backgroundColor: Colors.green));
                            fetchPricing();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi thêm giá!'), backgroundColor: Colors.red));
                          }
                        },
                  child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Thêm ngay', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cấu hình Giá', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
            Text(widget.court['name'], style: const TextStyle(color: Colors.orange, fontSize: 13)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPricingDialog,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm khung giá', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : pricingList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.price_change_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('Sân này chưa có bảng giá nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Khách hàng sẽ không thể đặt sân nếu chưa có giá.', style: TextStyle(color: Colors.orange, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                  ),
                )
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pricingList.length,
            itemBuilder:(context, index) {
              final pricing = pricingList[index];
              final isWeekend = pricing['day_type'] == 'weekend';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isWeekend ? Colors.red.shade100 : Colors.blue.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: isWeekend ? Colors.red.shade50 : Colors.blue.shade50,
                    child: Icon(Icons.calendar_month, color: isWeekend ? Colors.red : Colors.blue),
                  ),
                  title: Text(
                    isWeekend ? 'Cuối tuần (T7 - CN)' : 'Ngày thường (T2 - T6)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: isWeekend ? Colors.red.shade700 : Colors.blue.shade700),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('⏰ ${pricing['start_time'].substring(0, 5)} - ${pricing['end_time'].substring(0, 5)}'),
                      const SizedBox(height: 4),
                      Text('💰 ${pricing['price_per_slot']} VNĐ / ca', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
                    ],
                  ),
                ),
              );
            }, 
          )
    );
  }
}