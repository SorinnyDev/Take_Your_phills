import 'package:flutter/material.dart';
import 'statistics_tab.dart';
import 'history_tab.dart';

class StatisticsScreen extends StatefulWidget {
  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // 🔥 탭 변경 시 UI 업데이트
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C2D5A),
      appBar: AppBar(
        title: Text(
          '복용 기록',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1C2D5A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔥 커스텀 탭 바
          Container(
            color: Color(0xFF1C2D5A),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    icon: Icons.bar_chart,
                    label: '통계',
                    isSelected: _tabController.index == 0,
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildTabButton(
                    icon: Icons.history,
                    label: '히스토리',
                    isSelected: _tabController.index == 1,
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔥 탭 뷰
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: [
                  StatisticsTab(),
                  HistoryTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 커스텀 탭 버튼 (기존 UI 스타일)
  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Color(0xFF1C2D5A) : Colors.white,
              size: 18, // 🔥 아이콘 크기 조정
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14, // 🔥 폰트 크기 조정
                fontWeight: FontWeight.w600,
                color: isSelected ? Color(0xFF1C2D5A) : Colors.white,
                letterSpacing: 0.3, // 🔥 자간 추가
              ),
            ),
          ],
        ),
      ),
    );
  }
}
