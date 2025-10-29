import 'package:flutter/material.dart';
import 'package:e_auction/services/customer_stats_service.dart';
import 'package:fl_chart/fl_chart.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  late CustomerStatsService _customerStatsService;
  CustomerStatsData? _statsData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _customerStatsService = CustomerStatsService.defaultInstance();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _customerStatsService.getCustomerStats();
      if (response.success && response.data != null) {
        setState(() {
          _statsData = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายการผู้ใช้งาน'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            onPressed: _loadStats,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _buildStatsContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'เกิดข้อผิดพลาด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadStats,
            child: Text('ลองใหม่'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    if (_statsData == null) return Container();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // สถิติรวม
          _buildStatsCards(),
          SizedBox(height: 24),
          
          // กราฟรายวัน
          _buildDailyChart(),
          SizedBox(height: 24),
          
          // รายชื่อผู้ใช้ล่าสุด
          _buildRecentUsers(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          title: 'ทั้งหมด',
          value: _statsData!.total.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'วันนี้',
          value: _statsData!.today.toString(),
          icon: Icons.today,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'สัปดาห์นี้',
          value: _statsData!.thisWeek.toString(),
          icon: Icons.date_range,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'เดือนนี้',
          value: _statsData!.thisMonth.toString(),
          icon: Icons.calendar_month,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyChart() {
    // คำนวณเปอร์เซ็นต์สำหรับแต่ละช่วงเวลา
    final total = _statsData!.total;
    final todayPercent = total > 0 ? (_statsData!.today / total * 100).toDouble() : 0.0;
    final weekPercent = total > 0 ? (_statsData!.thisWeek / total * 100).toDouble() : 0.0;
    final monthPercent = total > 0 ? (_statsData!.thisMonth / total * 100).toDouble() : 0.0;
    final totalPercent = 100.0; // ใช้ 100% สำหรับผู้ใช้ทั้งหมด

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สถิติผู้ใช้ทั้งหมด (%)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                // กราฟวงกลม
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            color: Colors.green,
                            value: todayPercent,
                            title: '${todayPercent.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.orange,
                            value: weekPercent,
                            title: '${weekPercent.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.purple,
                            value: monthPercent,
                            title: '${monthPercent.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.blue,
                            value: totalPercent,
                            title: '${totalPercent.toStringAsFixed(1)}%',
                            radius: 60,
                            titleStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                // รายละเอียดสี
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem(
                        color: Colors.green,
                        label: 'วันนี้',
                        value: _statsData!.today,
                        percent: todayPercent,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        color: Colors.orange,
                        label: 'สัปดาห์นี้',
                        value: _statsData!.thisWeek,
                        percent: weekPercent,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        color: Colors.purple,
                        label: 'เดือนนี้',
                        value: _statsData!.thisMonth,
                        percent: monthPercent,
                      ),
                      SizedBox(height: 8),
                      _buildLegendItem(
                        color: Colors.blue,
                        label: 'ผู้ใช้ทั้งหมด',
                        value: total,
                        percent: totalPercent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required int value,
    required double percent,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$value คน (${percent.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentUsers() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ผู้ใช้ล่าสุด (10 คน)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _statsData!.recent.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _statsData!.recent[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple,
                    child: Text(
                      user.phone.substring(0, 1),
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user.formattedPhone,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'ID: ${user.id}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: Text(
                    user.formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
