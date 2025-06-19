import 'package:flutter/material.dart';
import 'package:e_auction/utils/tool_utility.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, String> userData;
  final String? profilePicture;

  const ProfileHeader({
    super.key,
    required this.userData,
    this.profilePicture,
  });

  @override
  Widget build(BuildContext context) {
    // Debug information
    print('ProfileHeader - profilePicture: $profilePicture');
    print('ProfileHeader - userData profile_picture: ${userData['profile_picture']}');
    
    // Determine which profile picture to use
    String? finalProfilePicture;
    if (profilePicture != null && profilePicture!.isNotEmpty) {
      finalProfilePicture = profilePicture;
      print('Using profilePicture from API: $finalProfilePicture');
    } else if (userData['profile_picture'] != null && userData['profile_picture']!.isNotEmpty) {
      finalProfilePicture = userData['profile_picture'];
      print('Using profilePicture from SharedPreferences: $finalProfilePicture');
    } else {
      print('No profile picture available, using default icon');
    }
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.green,
            backgroundImage: finalProfilePicture != null
                ? NetworkImage(finalProfilePicture)
                : null,
            child: finalProfilePicture == null
                ? Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),
          SizedBox(height: 16),
          Text(
            userData['mem_fullname']?.isNotEmpty == true
                ? userData['mem_fullname']!
                : userData['name']?.isNotEmpty == true
                    ? userData['name']!
                    : '${userData['firstname']} ${userData['lastname']}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (userData['role_name_th']?.isNotEmpty == true) ...[
            SizedBox(height: 8),
            Text(
              userData['role_name_th']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoTile({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalInfoSection extends StatelessWidget {
  final Map<String, String> userData;

  const PersonalInfoSection({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'ข้อมูลส่วนตัว',
      children: [
        ProfileInfoTile(label: 'เบอร์โทรศัพท์', value: userData['phone_number'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'อีเมล', value: userData['email'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'เลขบัตรประชาชน', value: userData['mem_idcard'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'วันเกิด', value: _getBirthDate()),
        ProfileInfoTile(label: 'เพศ', value: _getGender()),
        ProfileInfoTile(label: 'หมู่เลือด', value: userData['mem_bloodgroup'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'ศาสนา', value: userData['mem_religion'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'สถานะสมรส', value: userData['marital_status'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'สัญชาติ', value: userData['nationality_name'] ?? 'ไม่ระบุ'),
      ],
    );
  }

  String _getBirthDate() {
    String? birthDate;
    if (userData['mem_birthdate']?.isNotEmpty == true) {
      birthDate = userData['mem_birthdate']!;
    } else if (userData['birthdate']?.isNotEmpty == true) {
      birthDate = userData['birthdate']!;
    }
    
    if (birthDate == null || birthDate.isEmpty) {
      return 'ไม่ระบุ';
    }
    
    // First convert to standard format using existing utility
    String formattedDate = ToolUtility.convertDateString(
      birthDate, 
      ToolUtility.yyyyMMddDash, 
      ToolUtility.ddMMyyyy
    );
    
    if (formattedDate.isEmpty) {
      return birthDate; // Return original if conversion fails
    }
    
    // Convert to Thai format
    try {
      final parts = formattedDate.split('/');
      if (parts.length >= 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        
        // Thai month names
        final thaiMonths = [
          'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
          'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
        ];
        
        final thaiYear = year + 543; // Convert to Buddhist era
        return 'วันที่ $day ${thaiMonths[month - 1]} $thaiYear';
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    
    return formattedDate; // Return formatted date if Thai conversion fails
  }

  String _getGender() {
    if (userData['mem_sex']?.isNotEmpty == true) {
      return userData['mem_sex']!;
    } else if (userData['gender']?.isNotEmpty == true) {
      return userData['gender']!;
    }
    return 'ไม่ระบุ';
  }
}

class WorkInfoSection extends StatelessWidget {
  final Map<String, String> userData;

  const WorkInfoSection({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'ข้อมูลการทำงาน',
      children: [
        ProfileInfoTile(label: 'ตำแหน่ง', value: userData['mem_position'] ?? 'ไม่ระบุ'),
        // ProfileInfoTile(label: 'แผนก', value: userData['department_id'] ?? 'ไม่ระบุ'),
        // ProfileInfoTile(label: 'สาขา', value: userData['branch_id'] ?? 'ไม่ระบุ'),
        ProfileInfoTile(label: 'วันที่เริ่มงาน', value: userData['start_work'] ?? 'ไม่ระบุ'),
      ],
    );
  }
}

class AddressInfoSection extends StatelessWidget {
  final Map<String, String> userData;

  const AddressInfoSection({
    super.key,
    required this.userData,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'ข้อมูลที่อยู่',
      children: [
        ProfileInfoTile(label: 'ที่อยู่ปัจจุบัน', value: _getCurrentAddress()),
      ],
    );
  }

  String _getCurrentAddress() {
    if (userData['mem_currentaddress']?.isNotEmpty == true) {
      return userData['mem_currentaddress']!;
    } else if (userData['current_address']?.isNotEmpty == true) {
      return userData['current_address']!;
    }
    return 'ไม่ระบุ';
  }
}
