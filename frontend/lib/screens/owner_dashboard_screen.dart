import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/owner_court_screen.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_services.dart';

class OwnerDashboardScreen extends StatefulWidget{
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashBoardScreenState();
}
class _OwnerDashBoardScreenState extends State<OwnerDashboardScreen>{
  Map<String, dynamic> dashboardData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }
  Future<void> fetchDashboardData () async {
    try {
      final response = await ApiClient().dio.get('owner/dashboard/');
      if (mounted) {
        setState(() {
          dashboardData = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dashboard chủ sân: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context){
    final double totalRevenue = double.tryParse((dashboardData['total_revenue'] ?? 0).toString()) ?? 0.0;
    final int courtsCount = dashboardData['total_my_courts'] ?? 0;
    final String month = dashboardData['month'] ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kênh Chủ Sân', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          tooltip: 'Đăng xuất',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Xác nhận đăng xuất'),
                content: const Text('Bạn có chắc chắn muốn thoát khỏi Kênh Chủ Sân?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final authService = AuthService();
              await authService.logout();

              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            }
          },
        ),
        const SizedBox(width: 8), 
      ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
          onRefresh: fetchDashboardData, 
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Doanh thu tháng này', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                            child: Text('Tháng $month', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 12,),  
                      Text(
                        '${totalRevenue.toInt()} VNĐ',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                     ),
                      const SizedBox(height: 20,), 
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                const Icon(Icons.sports_soccer, color: Colors.blue, size: 28),
                                const SizedBox(height: 12),
                                Text('$courtsCount', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                const Text('Sân đang quản lý', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                              ),
                            )
                          )
                        ],
                      ),
                      const SizedBox(height: 24,),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.edit_location_alt, color: Colors.white),
                          label: const Text('Quản lý danh sách sân của tôi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const OwnerCourtsScreen())
                            );
                          }, 
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
      )
    );
  }
}