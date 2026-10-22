import 'package:flutter/material.dart';

/// ไอคอนหมวดช่างขนาดเล็ก พร้อมชื่อหมวดใต้ไอคอนเมื่อต้องการ
class SkillIcon extends StatelessWidget {
  final String skill;
  final double size;
  final bool showLabel;

  const SkillIcon(this.skill, {super.key, this.size = 28, this.showLabel = false});

  static const assets = <String, String>{
    'แอร์': 'assets/images/skills/air.png',
    'ไฟฟ้า': 'assets/images/skills/electric.png',
    'ประปา': 'assets/images/skills/plumbing.png',
    'สี': 'assets/images/skills/paint.png',
    'ต่อเติม': 'assets/images/skills/build.png',
    'ทำความสะอาด': 'assets/images/skills/clean.png',
    'เครื่องใช้ไฟฟ้า': 'assets/images/skills/appliance.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = assets[skill];
    if (path == null) {
      return Text(skill, style: const TextStyle(fontSize: 12));
    }
    final image = Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.contain,
      semanticLabel: skill,
    );
    if (!showLabel) return image;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(height: 2),
        Text(
          skill,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            height: 1.1,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

class SkillIconRow extends StatelessWidget {
  final List<String> skills;
  final double size;

  const SkillIconRow({super.key, required this.skills, this.size = 22});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final skill in skills)
          Tooltip(
            message: skill,
            child: SkillIcon(skill, size: size, showLabel: true),
          ),
      ],
    );
  }
}
