
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/screens/home_screen.dart';
import 'package:frontend/services/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentScreen extends StatefulWidget{
  final int bookingId;
  final int totalAmount;
  final String? expiredAtString;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalAmount,
    this.expiredAtString,
  });

  @override 
  State<PaymentScreen> createState() => _PaymentScreenState();
}
class _PaymentScreenState extends State<PaymentScreen>{
    Timer? _timer;
    Timer? _checkTimer;
    Duration _timeLeft = const Duration(minutes: 5);

    @override
    void initState() {
      super.initState();
      _startCountdown();
      _startStatusPolling();
    }
    void _startCountdown(){
      if(widget.expiredAtString != null){
        final expiredTime = DateTime.parse(widget.expiredAtString!).toLocal();
        _timeLeft = expiredTime.difference(DateTime.now());
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeLeft.inSeconds > 0){
          setState(() {
            _timeLeft = _timeLeft - const Duration(seconds: 1); 
          });
        }
        else{
          _timer?.cancel();
          _checkTimer?.cancel();
          _showTimeoutDialog();
        }
      });
    }
    void _startStatusPolling(){
      _checkTimer = Timer.periodic(const Duration(seconds: 3),(timer) async {
        try {
          final response = await ApiClient().dio.get('bookings/orders/${widget.bookingId}/');
          final String status = response.data['status'];
          if (status == 'success' || status == 'confirmed') {
            timer.cancel();
            _timer?.cancel(); 
            _showSuccessAndReturnHome();
         } 
        }catch (e){
          debugPrint ('Đang chờ thanh toán');
        }
      }); 
    }
    void _showSuccessAndReturnHome() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Thanh toán thành công!'),
        content: const Text('Đơn đặt sân của bạn đã được xác nhận thành công.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Scaffold(body: Center(child: HomeScreen()))),
                (route) => false,
              );
            },
            child: const Text('Về trang chủ'),
          ),
        ],
      ),
    );
  }
    void _showTimeoutDialog(){
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Hết thời gian thanh toán'),
          content: const Text('Rất tiếc, hết thời gian giữ chỗ.Vui lòng quay lại và đặt lại sân'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              }, 
              child: const Text('Quay lại'),
            )
          ],
        )
      );
    }
    Future<void> _handlePayment() async {
      try {
         final response = await ApiClient().dio.get(
          'bookings/orders/${widget.bookingId}/get_payment_url/',
            );
          final String paymentUrl = response.data['payment_url'];
          final Uri url = Uri.parse(paymentUrl);
          if (await canLaunchUrl(url)){
            await launchUrl(
              url,
              mode : LaunchMode.externalApplication,
            );
          } else {
              throw 'Không thể mở cổng thanh toán';
          }
          }catch (e){
            debugPrint('Lỗi mở VNPAY: $e');
            if (context.mounted) {
              
              ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lỗi kết nối cổng thanh toán!'), backgroundColor: Colors.red),    
          );        
        }
      }
    }
    @override
    void dispose() {
    _timer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }
  String _formatTime(int time) => time.toString().padLeft(2, '0');
  @override
  Widget build(BuildContext context) {
    final minutes = _formatTime(_timeLeft.inMinutes.remainder(60));
    final seconds = _formatTime(_timeLeft.inSeconds.remainder(60));  
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Thanh toán',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final shouldExit = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Hủy thanh toán?'),
                content: const Text(
                  'Bạn có chắc muốn hủy thanh toán và quay lại không?\n\n'
                  'Ca sân hiện đang được giữ tạm thời.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: const Text('Không'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hủy thanh toán'),
                  ),
                ],
              ),
            );
            if (shouldExit == true  ) {
              _timer?.cancel();
              _checkTimer?.cancel();
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                children: [
                  const Text('Thời gian giữ chỗ còn lại' ,style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8,),
                  Text(
                    '$minutes:$seconds',
                    style: const TextStyle(color: Colors.red,fontWeight: FontWeight.bold,fontSize: 32),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16,),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mã đơn hàng', style: TextStyle(color: Colors.grey),),
                      Text('#${widget.bookingId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${widget.totalAmount.toInt()} đ',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: SafeArea(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _timeLeft.inSeconds > 0
                ? _handlePayment  
                : null,
            child: const Text('Thanh toán ngay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          )
        ),
      ),
    );
  }
}
