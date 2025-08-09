import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        primaryColor: Color(0xFF1C2D5A),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    ReminderListScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF1C2D5A),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class ReminderListScreen extends StatelessWidget {
  void _goToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReminderDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Color(0xFF1C2D5A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('약 챙겨 먹었니', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: List.generate(6, (index) => ReminderCard(onTap: () => _goToDetail(context))),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToDetail(context),
        backgroundColor: Color(0xFF1C2D5A),
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class StatisticsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('복용 통계', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('이번 주 복용률', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('85%', style: TextStyle(fontSize: 36, color: Color(0xFF1C2D5A), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('최근 7일', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (index) => 
                          Column(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: index < 5 ? Color(0xFF1C2D5A) : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  index < 5 ? Icons.check : Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('${DateTime.now().subtract(Duration(days: 6-index)).day}일'),
                            ],
                          )
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('설정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.notifications),
                title: Text('알림 설정'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.palette),
                title: Text('테마 설정'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.backup),
                title: Text('데이터 백업'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('앱 정보'),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReminderCard extends StatefulWidget {
  final VoidCallback onTap;

  ReminderCard({required this.onTap});

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {
  bool isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('종합비타민', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                Switch(
                  value: isEnabled, 
                  onChanged: (value) {
                    setState(() {
                      isEnabled = value;
                    });
                  }
                ),
              ],
            ),
            Text('오전 10:10', style: TextStyle(fontSize: 16)),
            Text('매 12시간', style: TextStyle(color: Colors.grey[600]))
          ],
        ),
      ),
    );
  }
}

class ReminderDetailScreen extends StatefulWidget {
  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  String amPm = 'AM';
  int hour = 10;
  int minute = 10;
  int repeatHour = 10;
  int repeatMinute = 10;
  bool isEnabled = true;
  TextEditingController titleController = TextEditingController();

  List<int> hourList = List.generate(12, (i) => i + 1);
  List<int> minuteList = List.generate(60, (i) => i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text('알림 생성', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 24),
            Text('알림 시간', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                DropdownButton<String>(
                  value: amPm,
                  items: ['AM', 'PM'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                  onChanged: (val) => setState(() => amPm = val!),
                ),
                SizedBox(width: 12),
                DropdownButton<int>(
                  value: hour,
                  items: hourList.map((val) => DropdownMenuItem(value: val, child: Text(val.toString()))).toList(),
                  onChanged: (val) => setState(() => hour = val!),
                ),
                SizedBox(width: 12),
                DropdownButton<int>(
                  value: minute,
                  items: minuteList.map((val) => DropdownMenuItem(value: val, child: Text(val.toString().padLeft(2, '0')))).toList(),
                  onChanged: (val) => setState(() => minute = val!),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text('반복 간격', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                DropdownButton<int>(
                  value: repeatHour,
                  items: hourList.map((val) => DropdownMenuItem(value: val, child: Text(val.toString()))).toList(),
                  onChanged: (val) => setState(() => repeatHour = val!),
                ),
                SizedBox(width: 12),
                DropdownButton<int>(
                  value: repeatMinute,
                  items: minuteList.map((val) => DropdownMenuItem(value: val, child: Text(val.toString().padLeft(2, '0')))).toList(),
                  onChanged: (val) => setState(() => repeatMinute = val!),
                ),
                SizedBox(width: 8),
                Text('마다')
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('알림 활성화', style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(value: isEnabled, onChanged: (val) => setState(() => isEnabled = val)),
              ],
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(hintText: '알림 제목', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('취소'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1C2D5A)),
                    onPressed: () {},
                    child: Text('저장'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}