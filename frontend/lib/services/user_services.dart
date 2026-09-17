import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class UserServices {
  static Future<int> fetchCurrentUserId() async {
    try {
      final response = await ApiClient().dio.get('users/me/');
      if (response.statusCode == 200 && response.data != null) {
        final userId = response.data['id'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', userId);
        
        debugPrint('🔥 Đã tự động lấy và lưu user_id thành công: $userId');
        return userId is int ? userId : int.parse(userId.toString());
      }
    }catch(e){
      debugPrint('Lỗi lấy thông tin user hiện tại: $e');
    }
    return 0;
  } 
}