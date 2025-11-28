
import 'package:flutter/material.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '설정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1C2D5A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          // 🔔 알림 설정
          _buildSectionTitle('알림 설정'),
          SizedBox(height: 12),
          _buildSettingsCard(
            children: [
              SettingsTile(
                icon: Icons.music_note,
                title: '알림음 선택',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('알림음 선택'),
              ),
              Divider(height: 1),
              SettingsTile(
                icon: Icons.volume_up,
                title: '알림 볼륨',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('알림 볼륨'),
              ),
              Divider(height: 1),
              SettingsTile(
                icon: Icons.vibration,
                title: '진동 사용',
                trailing: Switch(
                  value: _vibrationEnabled,
                  onChanged: (value) {
                    setState(() => _vibrationEnabled = value);
                    _showSnackBar(
                      value ? '진동이 활성화되었습니다' : '진동이 비활성화되었습니다',
                    );
                  },
                  activeColor: Color(0xFF1C2D5A),
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // 🎨 테마 설정
          _buildSectionTitle('테마 설정'),
          SizedBox(height: 12),
          _buildSettingsCard(
            children: [
              SettingsTile(
                icon: Icons.dark_mode,
                title: '다크 모드',
                trailing: Switch(
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() => _darkModeEnabled = value);
                    _showSnackBar('다크 모드는 준비 중입니다');
                  },
                  activeColor: Color(0xFF1C2D5A),
                ),
              ),
              Divider(height: 1),
              SettingsTile(
                icon: Icons.palette,
                title: '알림 화면 색상',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('알림 화면 색상'),
              ),
            ],
          ),

          SizedBox(height: 32),

          // ℹ️ 앱 정보
          _buildSectionTitle('앱 정보'),
          SizedBox(height: 12),
          _buildSettingsCard(
            children: [
              SettingsTile(
                icon: Icons.info_outline,
                title: '버전 정보',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('버전 정보'),
              ),
              Divider(height: 1),
              SettingsTile(
                icon: Icons.description,
                title: '오픈소스 라이선스',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('오픈소스 라이선스'),
              ),
              Divider(height: 1),
              SettingsTile(
                icon: Icons.person_outline,
                title: '개발자 정보',
                trailing: Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _showComingSoon('개발자 정보'),
              ),
            ],
          ),

          SizedBox(height: 32),

          // 🗑️ 위험 영역
          _buildDangerButton(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDangerButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: InkWell(
        onTap: _confirmDeleteAllData,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text(
                '모든 데이터 삭제',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.construction, color: Colors.orange),
            SizedBox(width: 12),
            Text('준비 중'),
          ],
        ),
        content: Text('$feature 기능은 곧 추가될 예정입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(color: Color(0xFF1C2D5A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDeleteAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 12),
            Text('경고'),
          ],
        ),
        content: Text(
          '모든 알림과 복용 기록이 영구적으로 삭제됩니다.\n정말 삭제하시겠습니까?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: 실제 삭제 로직은 나중에 구현
              _showSnackBar('데이터 삭제 기능은 준비 중입니다');
            },
            child: Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
