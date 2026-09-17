import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/community_screen.dart';
import 'package:frontend/screens/history_screen.dart';
import 'package:frontend/screens/notification_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/services/api_client.dart';
import 'court_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0; // Quản lý tab đang chọn ở BottomNavigationBar

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình tương ứng với Bottom Nav
    final List<Widget> pages = [
      const HomeTabContent(),    
      const HistoryScreen(),
      const CommunityScreen(),
      const NotificationScreen(),
      const ProfileScreen(),      
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Cộng đồng',
            activeIcon: Icon(Icons.group),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            activeIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});
  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  List<dynamic> mockCourts = [];
  bool isLoading = true;
  String searchQuery='';
  bool filterByTopRating = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCourts();
  }

  Future<void> fetchCourts() async {
    try {
      final response = await ApiClient().dio.get(
        'courts/list/',
        queryParameters: {
          if (searchQuery.isNotEmpty) 'search': searchQuery,
          if (filterByTopRating) 'ordering': '-average_rating',
        },
      );
      if (mounted) {
        setState(() {
          mockCourts = response.data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (e is DioException) {
        debugPrint(
          'Lỗi tải sân: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        debugPrint('Lỗi không xác định: $e');
      }
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Khám phá sân',
          style: TextStyle(fontWeight: FontWeight.w800,fontSize: 32,letterSpacing: -0.5),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF5F7FA),
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: (){Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => const ProfileScreen()));
            }  
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child:Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                   boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ), 
                TextField(
                  controller: _searchController,
                  onSubmitted: (value){
                    setState(() {
                      searchQuery = value;
                    });
                    fetchCourts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sân theo tên, khu vực...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: (){ 
                            _searchController.clear(); 
                            setState(() {searchQuery = '';});
                            fetchCourts();
                        },
                      )
                      : Icon(Icons.search, color: Colors.blue.shade700),
                    border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 8,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() => filterByTopRating = !filterByTopRating);
                        fetchCourts();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: filterByTopRating ? Colors.amber.shade50 : Colors.white,
                          border: Border.all(color: filterByTopRating ? Colors.amber : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              filterByTopRating ? Icons.star : Icons.star_border,
                              size: 16,
                              color: filterByTopRating ? Colors.amber.shade700 : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đánh giá cao',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: filterByTopRating ? Colors.amber.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    )
                  ],
                )
              ]
            ),
          ),
          const SizedBox(height: 8),  
          // 2. DANH SÁCH SÂN (Dùng ListView.builder)
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : mockCourts.isEmpty
                  ? const Center(child: Text('Hiện chưa có sân hoạt động'))
                  : ListView.builder(
                      itemCount: mockCourts.length,
                      itemBuilder: (context, index) {
                        final court = mockCourts[index];
                        final List<dynamic> amenities = court['amenities'] ?? [];
                        return Card(
                          key: ValueKey(court['id'] ?? index),
                          margin: const EdgeInsets.symmetric(horizontal: 16,vertical: 8,),
                          elevation: 0,
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.black.withValues(alpha :0.05)),
                          ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Future.delayed(const Duration(milliseconds: 50), () {
                                 if (!context.mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourtDetailScreen(courtData: court)
                                    ),
                                );
                                },
                              );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
                                        child: Image.network(
                                          court['image'] ?? '',
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.red.shade50,
                                              child: const Icon(Icons.broken_image, color: Colors.red, size: 36),
                                            );
                                          },
                                        )
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            court['name'] ?? 'Chưa cập nhật tên',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: amenities.map(
                                                  (tag) => Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(horizontal: 8,vertical: 4,),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.05),
                                                      borderRadius:BorderRadius.circular(4),),
                                                    child: Text(
                                                      tag.toString(),
                                                      style: TextStyle(fontSize: 11,color: Colors.blue.shade800,),
                                                    ),
                                                  ),
                                                ).toList(),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              const Icon( Icons.location_on,color: Colors.red,size: 14,),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  court['location'] ?? 'Chưa cập nhật địa chỉ',
                                                  style: const TextStyle( fontSize: 12,color: Colors.grey,),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.star, color: Colors.amber, size: 12),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        court['average_rating']?.toString() ?? '5.0',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.amber.shade800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                      }    
            )
          ),
        ],
      ),
    );
  }
}
