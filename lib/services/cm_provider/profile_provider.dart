import 'package:flutter/material.dart';

class UserProfile {
  String? token;
  String? person_id;
  String? mem_status;
  String? mem_idcard;
  String? mem_email;
  String? mem_image;
  String? mem_fullname;
  String? mem_password;
  String? mem_birthdate;
  String? mem_sex;
  String? mem_bloodgroup;
  String? mem_contactinformation;
  String? mem_religion;
  String? mem_tel;
  String? mem_emergency_contact;
  String? mem_currentaddress;
  String? mem_passport;
  String? mem_position;
  String? line_uid;

  UserProfile({
    this.token,
    this.person_id,
    this.mem_status,
    this.mem_idcard,
    this.mem_email,
    this.mem_image,
    this.mem_fullname,
    this.mem_password,
    this.mem_birthdate,
    this.mem_sex,
    this.mem_bloodgroup,
    this.mem_contactinformation,
    this.mem_religion,
    this.mem_tel,
    this.mem_emergency_contact,
    this.mem_currentaddress,
    this.mem_passport,
    this.mem_position,
    this.line_uid,
  });
}

class UserProfileProvider with ChangeNotifier {
  UserProfile? _userProfile;

  UserProfile? get userProfile => _userProfile;

  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }
}
