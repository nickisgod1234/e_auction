import 'package:e_auction/models/technician_profile.dart';
import 'package:flutter_test/flutter_test.dart';

List<TechnicianProfile> visibleToUsers(List<TechnicianProfile> profiles) {
  return profiles.where((profile) => profile.status == 1).toList();
}

TechnicianProfile _profile({required int status, String? comment}) {
  return TechnicianProfile.fromJson({
    'id': '1',
    'ownerId': 'sample-technician-1',
    'ownerName': 'ช่างทดสอบ',
    'ownerPhone': '0890000001',
    'displayName': 'สมชาย ไฟฟ้าและแอร์',
    'skills': ['แอร์', 'ไฟฟ้า'],
    'serviceArea': 'กทม. และนนทบุรี',
    'startingPrice': 450,
    'portfolioPaths': [],
    'certificatePaths': [],
    'jobs': [
      {'title': 'ล้างแอร์ 2 เครื่อง', 'detail': 'บ้านเดี่ยว นนทบุรี'},
    ],
    'status': status,
    'reviewComment': comment,
    'updatedAt': '2026-10-20T13:00:00',
  });
}

void main() {
  test('ประวัติรออนุมัติยังไม่ขึ้นหน้าหาช่าง และอนุมัติแล้วจึงเห็น', () {
    final pending = _profile(status: 0);
    expect(visibleToUsers([pending]), isEmpty);

    final approved = pending.copyWith(status: 1, reviewComment: 'ผ่าน');
    final listed = visibleToUsers([approved, _profile(status: 2, comment: 'ไม่ผ่าน')]);
    expect(listed, hasLength(1));
    expect(listed.single.displayName, 'สมชาย ไฟฟ้าและแอร์');
    expect(listed.single.reviewComment, 'ผ่าน');
  });
}
