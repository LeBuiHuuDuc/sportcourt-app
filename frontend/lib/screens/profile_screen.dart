import 'package:flutter/material.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ProfileScreen extends StatefulWidget{
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen> {
  String fullname = "";
  String email = "";
  String? avatarUrl;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    try {
      final response = await ApiClient().dio.get('users/me/');

      if (mounted && response.statusCode == 200) {
        setState(() {
          fullname = response.data['fullname'] ?? 'Người dùng';
          email = response.data['email'] ?? '';
          avatarUrl = response.data['avatar']; 
          isLoading = false;
        });
      }
    }catch(e){
      debugPrint('Lỗi tải thông tin profile: $e');
      if (mounted) {
        setState(() {
          fullname = 'Không thể tải tên';
          isLoading = false;
        });
      }
    }
  }
  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title:  const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?') ,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context,false), 
            child: const Text('Không',style: TextStyle(color: Colors.grey),)
            ),
            ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(context, true), // Đồng ý
            child: const Text('Có, đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      )   
    );
    if (confirm == true){
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token'); 
      await prefs.remove('refresh_token');
      await prefs.remove('user_id');
      if(!context.mounted) return;
      
        Navigator.pushAndRemoveUntil(
          context , 
          MaterialPageRoute(builder: (context) => const LoginScreen(),), 
          (route) => false,        
        );
    }
   }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar:AppBar(
        title: const Text('Hồ sơ của tôi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.green.shade100,
              backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                ? NetworkImage(avatarUrl!)
                : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Colors.green)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Xin chào, $fullname!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Lịch sử đặt sân'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => HistoryScreen(), 
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}