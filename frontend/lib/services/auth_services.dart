import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

    Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('token/', data: {
        'email': email, 
        'password': password,
      });

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();

        // 1. Lưu token trước
        await prefs.setString('access_token', response.data['access']);
        await prefs.setString('refresh_token', response.data['refresh']);

        // 2. 🌟 GỌI THÊM API /users/me/ ĐỂ LẤY CHUẨN ROLE VÀ USER_ID TỪ SERVER
        try {
          // Tạo một client tạm thời hoặc dùng Dio với token vừa có để gọi /users/me/
          _dio.options.headers['Authorization'] = 'Bearer ${response.data['access']}';
          final userResponse = await _dio.get('users/me/');
          
          if (userResponse.statusCode == 200 && userResponse.data != null) {
            final String role = userResponse.data['role']?.toString() ?? 'player';
            final int userId = userResponse.data['id'] ?? 0;

            // Lưu chính xác role và user_id thực tế vào máy
            await prefs.setString('role', role);
            await prefs.setInt('user_id', userId);
            
            debugPrint('🔥 Đăng nhập thành công! Role: $role, UserID: $userId');
          }
        } catch (innerErr) {
          debugPrint('Không thể lấy thông tin phụ sau khi login: $innerErr');
          // Fallback nếu có lỗi gọi /users/me/
          await prefs.setString('role', 'player');
        }

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      return false;
    }
  }

  Future<bool> register({
    required String fullname,
    required String email,
    required String phone,
    required String password,
    XFile? avatar,
    required bool isOwnerRequested,
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'username': email, 
        'fullname': fullname,
        'email': email,
        'phone': phone,
        'password': password,
        'is_owner_requested': isOwnerRequested.toString(), 
      });
      if (avatar != null) {
        if (kIsWeb){
          final bytes = await avatar.readAsBytes();
          formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(bytes, filename: 'avatar.jpg'),
          ),
        );
        }else {
          formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(avatar.path, filename: 'avatar.jpg'),
          ),
        );
        }
      }
      final response = await ApiClient().dio.post('users/register/', data: formData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi đăng ký trong AuthService: $e');
      return false;
    }
  }
  // Hàm đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('role');
  }
}
