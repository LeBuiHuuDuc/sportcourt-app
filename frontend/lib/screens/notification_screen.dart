import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';

class NotificationScreen extends StatefulWidget{
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}
class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }
  Future<void> fetchNotifications() async {
    setState(() => isLoading = true);
    try {
      final response = await ApiClient().dio.get('notifications/list/');
        if (mounted) {
          setState(() {
            notifications = response.data;
            isLoading = false;
          });
        }
    }catch(e){
      debugPrint('Lỗi tải thông báo: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> markAsRead(int id, int index) async {
    if (notifications[index]['is_read'] == true) return; // Nếu đọc rồi thì bỏ qua

    try {
      await ApiClient().dio.patch('notifications/list/$id/read/');
      setState(() {
        notifications[index]['is_read'] = true;
      });
    } catch (e) {
      debugPrint('Lỗi đánh dấu đã đọc: $e');
    }
  }
  Future<void> markAllAsRead() async {
    try {
      await ApiClient().dio.patch('notifications/list/read-all/');
      setState(() {
        for (var notif in notifications) {
          notif['is_read'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đánh dấu tất cả là đã đọc'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }
  Future<void> deleteNotification(int id, int index) async {
    try {
      await ApiClient().dio.delete('notifications/list/$id/');
      setState(() {
        notifications.removeAt(index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thông báo')),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xóa thông báo: $e');
    }
  }
  String formatTime(String isoString) {
    try {
      final DateTime date = DateTime.parse(isoString).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }
  Widget _buildNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'booking':
        iconData = Icons.sports_soccer;
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.shade50;
        break;
      case 'play_request':
        iconData = Icons.handshake;
        iconColor = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;
      case 'review':
        iconData = Icons.star_rounded;
        iconColor = Colors.amber.shade700;
        bgColor = Colors.amber.shade50;
        break;
      default:
        iconData = Icons.notifications_active;
        iconColor = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
    }
    return CircleAvatar(
      backgroundColor: bgColor,
      radius: 24,
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.blue),
            tooltip: 'Đánh dấu tất cả đã đọc',
            onPressed: notifications.any((n) => n['is_read'] == false) 
                ? markAllAsRead 
                : null, 
          ),
        ],
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : notifications.isEmpty
          ? Center(
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('Bạn chưa có thông báo nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
               ],
             ),
          )
          : RefreshIndicator(
            onRefresh: fetchNotifications, 
            child: ListView.separated(
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200), 
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final bool isRead = notif['is_read'];
                return Dismissible(
                  key: Key(notif['id'].toString()), 
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red.shade400,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) => deleteNotification(notif['id'], index),
                  child: InkWell(
                    onTap: (){
                      markAsRead(notif['id'], index);
                    },
                    child: Container(
                      color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha : 0.5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildNotificationIcon(notif['type']),
                          const SizedBox(height: 16,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notif['title'] ?? 'Thông báo',
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                    fontSize: 15,
                                    color: isRead ? Colors.black87 : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4,),
                                Text(
                                  notif['body'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isRead ? Colors.grey.shade700 : Colors.black87,
                                    ),
                                ),
                                const SizedBox(height: 4,),
                                Text(
                                  formatTime(notif['created_at']),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                )
                              ],
                            )
                          ),
                          if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            height: 10,
                            width: 10,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                );
              }, 
              )
            )
    );
  }
}
