import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/owner_pricing_screen.dart';
import 'package:frontend/services/api_client.dart';

class OwnerCourtsScreen extends StatefulWidget{
  const OwnerCourtsScreen({super.key});

  @override
  State<OwnerCourtsScreen> createState() => _OwnerCourtsScreenState();
}
class _OwnerCourtsScreenState extends State<OwnerCourtsScreen> {
  List<dynamic> myCourts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyCourts();
  }

  Future<void> fetchMyCourts() async {
    try{
      final response = await ApiClient().dio.get('owner/courts/');
      if (mounted) {
        setState(() {
          myCourts = response.data;
          isLoading = false;
        });
      }
    } catch (e){
      debugPrint('Lỗi tải danh sách sân chủ sở hữu: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  Future<void> deleteCourt(int courtId) async {
    try {
      await ApiClient().dio.delete('owner/courts/$courtId/');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa sân thành công!')));
      fetchMyCourts(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không thể xóa sân này!'), backgroundColor: Colors.red));
    }
  }
  Future<void> _showAddCourtDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final TextEditingController imageController = TextEditingController();

    await showDialog(
      context: context, 
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDigLogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm sân bóng mới', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên sân bóng (*)', prefixIcon: Icon(Icons.sports_soccer)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Link ảnh (URL)', prefixIcon: Icon(Icons.image_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Mô tả', prefixIcon: Icon(Icons.description_outlined)),
                    ),
                    const SizedBox(height: 8),
                    const Text('Lưu ý: Bạn sẽ cấu hình Giá & Giờ chơi ở bước sau.', style: TextStyle(color: Colors.orange, fontSize: 12, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting
                    ? null
                    : () async {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập Tên sân!'), backgroundColor: Colors.orange),
                        );
                      return;
                      }
                      setDigLogState (() => isSubmitting= true);
                      try {
                          await ApiClient().dio.post(
                              'owner/courts/',
                              data: {
                                'name': nameController.text,
                                'description': descController.text,
                                'image': imageController.text,
                                'complex': 1, 
                                'sport_type': 1, 
                              },
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thêm sân thành công!'), backgroundColor: Colors.green));
                            fetchMyCourts();
                      }catch(e){
                        setDigLogState(() => isSubmitting = false);
                        if (e is DioException) {
                          debugPrint('🔥 LỖI TẠO SÂN TỪ DJANGO: ${e.response?.data}');
                        }
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi thêm sân!'), backgroundColor: Colors.red));
                      }
                    },
                  child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Tạo mới', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      },
    );
  }
  Future<void> _showEditCourtsDialog(Map<String, dynamic> court) async {
    final TextEditingController nameController = TextEditingController(text: court['name']);
    final TextEditingController descController = TextEditingController(text: court['description'] ?? '');
    final TextEditingController imageController = TextEditingController(text: court['image'] ?? '');

    await showDialog(
      context: context, 
      builder: (context) {
        bool isUpdating = false;
        return StatefulBuilder(
          builder: (context, setDialogState){
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Sửa thông tin sân', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên sân bóng', prefixIcon: Icon(Icons.sports_soccer)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageController,
                      decoration: const InputDecoration(labelText: 'Link ảnh (URL)', prefixIcon: Icon(Icons.image_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Mô tả', prefixIcon: Icon(Icons.description_outlined)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  onPressed: isUpdating
                    ? null
                    : () async {
                      setDialogState(() => isUpdating = true);
                          try {
                            await ApiClient().dio.patch(
                              'owner/courts/${court['id']}/',
                              data: {
                                'name': nameController.text,
                                'description': descController.text,
                                'image': imageController.text,
                              },
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green));
                            fetchMyCourts();
                          } catch (e) {
                            setDialogState(() => isUpdating = false);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi cập nhật sân!'), backgroundColor: Colors.red));
                          }
                    },
                  child: isUpdating
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Lưu thay đổi', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      },
    );
  }
  void _openPricingConfig(Map<String, dynamic> court) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => OwnerPricingScreen(court: court),
    ),
  );
}
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Quản lý sân của tôi', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourtDialog,
        backgroundColor: Colors.blue.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm sân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        : myCourts.isEmpty
          ? Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Bạn chưa sở hữu sân bóng nào', style: TextStyle(color: Colors.grey, fontSize: 16)),
         ],
       ),
      )
      : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: myCourts.length,
        itemBuilder: (context, index) {
          final court = myCourts[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          court['image'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.orange.shade50,
                            child: Icon(Icons.sports_soccer, color: Colors.orange.shade400),
                        ),
                      ),
                    ),
                  ),
                  title: Text(court['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text(court['location'] ?? 'Chưa cập nhật địa chỉ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditCourtsDialog(court),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => deleteCourt(court['id']),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
                InkWell(
                  onTap: () => _openPricingConfig(court),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.settings_suggest, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Cấu hình Giá & Khung giờ', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                )
              ],
            )
          );
        } ,
      )
    );
  }
}
