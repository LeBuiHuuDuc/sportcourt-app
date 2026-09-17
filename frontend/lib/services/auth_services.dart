import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'package:image_picker/image_picker.dart';

class AuthService {
  final Dio _dio = ApiClient().dio;

    Future<String?> login(String email, String password) async {
  try {
    final response = await _dio.post(
      'token/',
      data: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      return 'Sai email hoặc mật khẩu!';
    }

    final accessToken = response.data['access'];
    final refreshToken = response.data['refresh'];
    _dio.options.headers['Authorization'] = 'Bearer $accessToken';

    final userResponse = await _dio.get('users/me/');

    if (userResponse.statusCode != 200 || userResponse.data == null) {
      return 'Không thể lấy thông tin tài khoản!';
    }

    final userData = userResponse.data;

    final String role =
        userData['role']?.toString().toLowerCase() ?? 'player';

    final int userId = userData['id'] ?? 0;

    final bool isApproved =
        userData['is_approved'] == true;



    if (role == 'owner' && !isApproved) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('role');
      await prefs.remove('user_id');

      _dio.options.headers.remove('Authorization');

      return 'Tài khoản Chủ sân của bạn chưa được Quản trị viên phê duyệt. '
          'Vui lòng chờ phê duyệt để đăng nhập.';
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
    await prefs.setString('role', role);
    await prefs.setInt('user_id', userId);

    debugPrint(
      'Đăng nhập thành công - Role: $role',
    );

    return null;
  } on DioException catch (e) {
    debugPrint(
      'Lỗi đăng nhập: '
      '${e.response?.statusCode} - ${e.response?.data}',
    );

    if (e.response?.statusCode == 401) {
      return 'Sai email hoặc mật khẩu!';
    }

    return 'Không thể đăng nhập. Vui lòng thử lại!';
  } catch (e) {
    debugPrint('Lỗi không xác định khi đăng nhập: $e');
    return 'Đã xảy ra lỗi khi đăng nhập!';
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
        'is_owner_requested': isOwnerRequested, 
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
