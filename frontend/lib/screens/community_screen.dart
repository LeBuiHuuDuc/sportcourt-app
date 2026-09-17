import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/services/user_services.dart';

class CommunityScreen extends StatefulWidget{
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}
class _CommunityScreenState extends State<CommunityScreen>{
  List<dynamic> playRequests = [];
  bool isLoading = true;
  int currentUserId = 0;
  
  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    fetchRequests();
  }
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    int id = prefs.getInt('user_id') ?? 0;
    if (id == 0) {
      id = await UserServices.fetchCurrentUserId();
    }

    if (mounted) {
      setState(() {
        currentUserId = id;
        debugPrint('🎯 ID thực tế đang dùng trên App là: $currentUserId');
      });
    }

  }
  Future<void> fetchRequests() async{
    try {
      final response = await ApiClient().dio.get('/community/playrequests/');
      if(mounted){
        setState(() {
          List<dynamic> rawData = [];
          if (response.data is Map<String, dynamic> && response.data.containsKey('results')) {
            rawData = response.data['results'];
          } else {
            rawData = response.data;
          }
          playRequests = rawData.where((req) => req['status'] == 'open').toList();
          isLoading = false;
        });
      }
    }catch(e){
      debugPrint('Lỗi tải danh sách: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }
  Future<void> _joinRequest(BuildContext context,int requestId) async{
    try {
      final res = await ApiClient().dio.post('community/playrequests/$requestId/join/');
      if(context.mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res.data['message'] ?? 'Gửi yêu cầu thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch(e){
      if (context.mounted) {
        String msg = 'Có lỗi xảy ra!';
        if (e is DioException && e.response?.data != null) {
           msg = e.response?.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }    
  }
   Future<void> _approveParticipant(int requestId, int participantId) async {
    try {
      await ApiClient().dio.patch('community/playrequests/$requestId/approve/$participantId/');
      if (mounted) {
        Navigator.pop(context); // Đóng popup
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã duyệt thành công!'), backgroundColor: Colors.green),
        );
        fetchRequests(); 
      } 
    } catch(e){
      if (mounted) {
        String msg = 'Lỗi khi duyệt!';
        if (e is DioException && e.response?.data != null) {
          msg = e.response?.data['message'] ?? msg;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }
  void _showParticipants(BuildContext context,Map<String,dynamic> req){
      List<dynamic> participants = req['participants'] ?? [];
      showModalBottomSheet(
        context: context, 
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh sách người xin tham gia',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                participants.isEmpty
                  ? const Center(child: Text('Chưa có ai xin tham gia kèo này.'))
                  : Expanded(
                    child: ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final p = participants[index];
                        bool isPending = p['status'] == 'pending';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person),),
                            title: Text('Người chơi ID: ${p['player']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              'Lời nhắn: ${p['note'] ?? 'Không có'}\nTrạng thái: ${p['status']}',
                            ),
                            isThreeLine: true,
                            trailing: isPending
                              ? ElevatedButton(
                                  onPressed: () => _approveParticipant(req['id'], p['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                   minimumSize: const Size(60, 36),
                              ),
                                  child: const Text('Duyệt', style: TextStyle(color: Colors.white)),
                            )
                            : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('Đã duyệt', style: TextStyle(color: Colors.green)),
                            )
                          ),
                          
                        );
                      },
                    )
                  )
              ],
            ),
          );
        },
      );
    }
    
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Ghép trận', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : playRequests.isEmpty
          ? const Center(child: Text('Hiện chưa có ai tìm bạn chơi chung.'))
          : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playRequests.length,
            itemBuilder: (context, index) {
              final req = playRequests[index];
              bool isMyPost = req['creator'] == currentUserId;
              final List participants = req['participants'] ?? [];
              final int approvedCount = participants.where((p) => p['status'] == 'approved').length;
              final int initialSlots = req['slot_number'] ?? 0;
              final int remainingSlots = initialSlots - approvedCount;
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.person, color: Colors.blue),
                          ),
                          const SizedBox(width: 12,),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  req['creator_name'] ?? 'Chủ kèo ID: ${req['creator']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text('Đơn đặt sân: #${req['booking']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: remainingSlots > 0 ? Colors.amber.shade100 : Colors.green.shade100, 
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              remainingSlots > 0 ? 'Thiếu $remainingSlots người' : 'Đã đủ người',
                              style: TextStyle(
                                color: remainingSlots > 0 ? Colors.amber.shade900 : Colors.green.shade900, 
                                fontWeight: FontWeight.bold, 
                                fontSize: 12,
                              ),
                            ),
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                      Text(
                        'Trình độ: ${req['desired_level_display'] ?? req['desired_level']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(req['note'] ?? 'Giao lưu vui vẻ', style: TextStyle(color: Colors.grey.shade800)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: isMyPost
                          ? OutlinedButton.icon(
                            onPressed: () => _showParticipants(context,req), 
                            icon: const Icon(Icons.list_alt, color: Colors.blue),
                            label: const Text('Kèo của bạn (Xem người tham gia)', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              side: BorderSide(color: Colors.blue.shade700),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ), 
                          )
                          : ElevatedButton(
                              onPressed: () => _joinRequest(context, req['id']),
                              child: const Text('Xin tham gia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                      )
                    ],
                  ),
                ),
              );
            },
          )
    );
  }
}