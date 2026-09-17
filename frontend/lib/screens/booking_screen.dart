import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/payment_screen.dart';
import 'package:frontend/services/api_client.dart';

class BookingScreen extends StatefulWidget{
  final Map<String,dynamic> courtData;
  const BookingScreen({super.key,required this.courtData});
  @override
  State<BookingScreen> createState() => _BookingScreenState(); 
}
class _BookingScreenState extends State<BookingScreen>{
  DateTime selectedDate = DateTime.now();
  List <Map<String,dynamic>> selectedSlots = [];
  bool isLoading = true;
  List<Map<String, dynamic>> timeSlots = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchTimeSlotsForDate(selectedDate);  }  

  Future<void> _fetchTimeSlotsForDate(DateTime date) async {
    setState(() => isLoading= true);
    try {
      final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final courtId = widget.courtData['id'];

      final response = await ApiClient().dio.get(
        'courts/list/$courtId/check-slots/',
        queryParameters: {'date': formattedDate},
      );
      if(mounted){
          final DateTime now = DateTime.now();
          final bool isToday = date.year == now.year && 
                             date.month == now.month && 
                             date.day == now.day;
          final List<Map<String,dynamic>> parsedSlots = (response.data as List).map((item){

            final startTime = item['start_time'].toString().substring(0, 5);
            final endTime = item['end_time'].toString().substring(0, 5);
            bool isExpired = false;
            if(isToday){
              try {
              final timeParts = startTime.split(':');
              final int slotHour = int.parse(timeParts[0]);
              final int slotMinute = int.parse(timeParts[1]);

              // Tạo mốc thời gian của ca chơi trong ngày hôm nay
              final DateTime slotStartTime = DateTime(
                now.year, now.month, now.day, slotHour, slotMinute
              );
              if (now.isAfter(slotStartTime)) {
                isExpired = true;
              }
            } catch (e) {
              debugPrint('Lỗi check giờ: $e');
            }
            }
            return {
              "id" : item['id'],
              "time": "$startTime - $endTime", 
              "price": item['price'],
              "status": isExpired ? 'expired' : item['status'],
            };
          }).toList();
          setState(() {
            timeSlots = parsedSlots;
            selectedSlots.clear();
            isLoading = false;
        });
      }
    } catch(e){
      debugPrint('Lỗi tải khung giờ: $e');
      if (mounted) {
        setState(() {
          timeSlots = [];
          isLoading = false;
        });
      }
    }
  }
  String _formatDate(DateTime date){
    return '${date.day}/${date.month}';
  }
  String _getWeekday(DateTime date){
    if (date.day == DateTime.now().day) return 'Hôm nay';
    switch (date.weekday) {
      case 1: return 'Thứ 2';
      case 2: return 'Thứ 3';
      case 3: return 'Thứ 4';
      case 4: return 'Thứ 5';
      case 5: return 'Thứ 6';
      case 6: return 'Thứ 7';
      case 7: return 'CN';
      default: return '';
    }
  }
  Future<void> _submitBooking() async {
    setState(() {
      isSubmitting = true;
    });
    try {
      final formattedDate = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      final payload = {
        "court": widget.courtData['id'],
        "booking_date": formattedDate, // Gửi ngày lên
        "time_slot_ids": selectedSlots.map((s) => s['id']).toList(), // Danh sách ID các ca chơi
      };
      final response = await ApiClient().dio.post('bookings/orders/', data: payload);
      setState(() => isSubmitting = false);
      if(mounted){
        final bookingId = response.data['booking_id'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Giữ chỗ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>  PaymentScreen(
              bookingId: bookingId, 
              totalAmount: response.data['total_amount'] ?? 0,
              expiredAtString: response.data['expired_at'],
            )
          )
        );
      }
    }catch(e){
        setState(() => isSubmitting = false);
        String errorMessage = 'Có lỗi xảy ra khi đặt sân';
        if (e is DioException && e.response != null){
          final errorData = e.response?.data;
         if (errorData is Map && errorData.containsKey('time_slot_ids')) {
           errorMessage = errorData['time_slot_ids'].toString();
         }
        }
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
        // Load lại lịch mới nhất vì ca đó đã bị người khác cướp mất
        _fetchTimeSlotsForDate(selectedDate);
      }
    }
  }
  void _toggleSlot(Map<String, dynamic> slot) {
    if (slot['status'] == 'booked' || slot['status'] == 'expired') return; 

    setState(() {
      final isExisting = selectedSlots.any((s) => s['id'] == slot['id']);
      if (isExisting) {
        selectedSlots.removeWhere((s) => s['id'] == slot['id']);
      } else {
        selectedSlots.add(slot);
      }
    });
  }
  double get totalPrice {
    return selectedSlots.fold(0, (sum, item) => sum + item['price']);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn giờ đặt sân' ,style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
            Text(
              widget.courtData['name'] ?? 'Sân thể thao',
              style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 7, 
                itemBuilder: (context,index){
                  final date = DateTime.now().add(Duration(days: index));
                  final isSelected = date.day == selectedDate.day && date.month == selectedDate.month;
                  
                  return GestureDetector(
                    onTap: (){
                      setState(() => selectedDate = date);
                      _fetchTimeSlotsForDate(date);
                    },
                    child: Container(
                      width: 65,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(  
                        color: isSelected ? Colors.blue.shade700 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                          ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 3))]
                          : []
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _getWeekday(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4,),
                          Text(
                            _formatDate(date),
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          )

                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Ca trống ngày ${_formatDate(selectedDate)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ), 
              ],
            ),
          ),
          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator(),)
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: timeSlots.length, 
                  itemBuilder: (context,index){
                    final slot = timeSlots[index];
                    final isBooked = slot['status'] == 'booked';
                    final isSelected = selectedSlots.any((s) => s['id'] == slot['id']);
                    final bool isExpired = slot['status'] == 'expired';
                    return InkWell(
                      onTap: () => _toggleSlot(slot),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isBooked
                            ? Colors.grey.shade200
                            :isSelected
                              ? Colors.blue.shade50
                              : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isBooked
                            ? Colors.grey.shade300
                            : isSelected
                              ? Colors.blue.shade600
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1.0,
                          )
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slot['time'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                  color: isBooked
                                      ? Colors.grey.shade500
                                      : isSelected ? Colors.blue.shade700 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                              Text(
                                isExpired 
                                    ? 'Đã qua giờ' 
                                    : isBooked ? 'Đã hết chỗ' : '${slot['price']}đ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isExpired
                                      ? Colors.grey.shade500
                                      : isBooked ? Colors.red.shade300 : isSelected ? Colors.blue.shade600 : Colors.green.shade600,
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  }
              )
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng tiền', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  Text(
                    '${totalPrice.toInt()} đ',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                  )
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(  
                  backgroundColor: selectedSlots.isEmpty ? Colors.grey.shade400 : Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (selectedSlots.isEmpty || isSubmitting )
                  ? null
                  : _submitBooking,
                child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white,strokeWidth: 2,),
                  )
                  : const Text(
                        'Tiếp tục',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          )
        ),
      ),
    );
  }
}
