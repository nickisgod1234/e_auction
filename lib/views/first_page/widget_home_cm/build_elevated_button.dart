import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:e_auction/utils/tool_utility.dart'; // Import FontAwesome package

Widget buildElevatedButton(
    String title, IconData icon, BuildContext context, Widget destination) {
  return Expanded(
    child: ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                destination,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.ease;

              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);

              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(icon, size: 24, color: Colors.green),
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: ToolUtility.fontPromptRegular,
                  fontSize: ToolUtility.autoSize(context, 15),
                  color: ToolUtility.colorBlack,
                ),
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildAlertButton(
    String title, IconData icon, BuildContext context, VoidCallback onPressed) { 
  return Expanded(
    child: ElevatedButton(
      onPressed: onPressed, // ใช้ Function แทน Widget
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white, 
        padding: EdgeInsets.symmetric(vertical: 10), 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), 
        ),
        elevation: 0, 
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 5, right: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: FaIcon(icon, size: 24, color: Colors.green), 
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: ToolUtility.fontPromptRegular,
                  fontSize: ToolUtility.autoSize(context, 15),
                  color: ToolUtility.colorBlack, 
                ),
                textAlign: TextAlign.center, 
                softWrap: true, 
                overflow: TextOverflow.visible, 
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildActionButton(
    String text,
    IconData icon,
    BuildContext context,
    VoidCallback onPressed,
) {
  return Container(
    width: MediaQuery.of(context).size.width * 0.4,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.green.shade600),
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            color: Colors.green.shade600,
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildNormalButton(
    String title, IconData icon, BuildContext context, Widget destination) {
  return ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.ease;

            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            var offsetAnimation = animation.drive(tween);

            return SlideTransition(
              position: offsetAnimation,
              child: child,
            );
          },
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      backgroundColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 0,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min, // ทำให้ปุ่มมีขนาดพอดีกับเนื้อหา
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.4),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
                child: FaIcon(icon, size: 24, color: Colors.green),
            ),
          ),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontFamily: ToolUtility.fontPromptRegular,
              fontSize: ToolUtility.autoSize(context, 15),
              color: ToolUtility.colorBlack,
            ),
          ),
        ],
      ),
    ),
  );
}
