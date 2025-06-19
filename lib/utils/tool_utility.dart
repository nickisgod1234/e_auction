// ignore_for_file: prefer_const_constructors, unused_element

import 'dart:io';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:e_auction/utils/fade_screen.dart';

import 'package:intl/intl.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

class FontFamily {
  FontFamily._();

  /// Font family: Prompt-Regular
  static const String promptRegular = 'Prompt-Regular';
}

class ToolUtility {
  // static String urlAPI = "http://192.168.1.120:801/APIGateway_VMS/";

  // static BaseOptions getOptionDio = BaseOptions(
  //     baseUrl: urlAPI,
  //     connectTimeout: ToolUtility.timeout,
  //     receiveTimeout: ToolUtility.timeout);

  static String yyyyMMddDash = "yyyy-MM-dd";
  static String ddMMyyyy = "dd/MM/yyyy";
  static String yyyyMMddDashHHmmss = "yyyy-MM-dd HH:mm:ss";
  static String showTimeOnly = "HH:mm";

  static String convertDateString(
      String date, String fromFormat, String toFormat) {
    if (stringIsNullOrEmpty(date)) {
      return "";
    } else {
      return DateFormat(toFormat)
          .format(DateFormat(fromFormat).parse(date.trim()));
    }
  }

  static String convertTimeString(
      String time, String fromFormat, String toFormat) {
    if (stringIsNullOrEmpty(time)) {
      return "";
    } else {
      return DateFormat(toFormat)
          .format(DateFormat(fromFormat).parse(time.trim()));
    }
  }

  //Font Size
  static String fontPromptRegular = FontFamily.promptRegular;

//Color
  static Map<int, Color> colorMainPrimarySwatch = {
    50: colorMain,
    100: colorMain,
    200: colorMain,
    300: colorMain,
    400: colorMain,
    500: colorMain,
    600: colorMain,
    700: colorMain,
    800: colorMain,
    900: colorMain,
  };
  static Duration timeout = const Duration(seconds: 900000);
  static int colorMainHax = 0xFF6b21a8;
  static Color colorMain = const Color.fromRGBO(107, 33, 168, 1);

  static double fontSizeNormal = 14;
  static double fontSizeNormal1 = 16;
  static double fontSizeButton2 = 12;
  static double fontSizeButton = 18;
  static double fontSizeShowInformation = 10;
  static double fontSize16px = 14;
  static double fontSize14px = 12;
  static double fontSizeIconDashboard = 40;
  static double borderRadiusNormal = 5;
  static double fontSizeImage = 500;

  static FilteringTextInputFormatter textInputAllowTypeText =
      FilteringTextInputFormatter.allow(
          RegExp(r"[a-zA-Zก-ฮฯะัาำิีึืฺุูเแโใไๅๆ็่้๊๋์0-9-.@ ]"));
  static TextInputType textInputTypeText = TextInputType.text;
  static TextInputType textInputTypeNumber = (Platform.isAndroid
      ? TextInputType.number
      : (Platform.isIOS ? TextInputType.text : TextInputType.text));
  static Color colorWhite = Colors.white;
  static Color colorBlack = Colors.black;
  static Color colorGreyCustom1 = const Color.fromRGBO(51, 51, 51, 0.8);
  static Color colorBtnSubmit = const Color.fromRGBO(143, 191, 115, 1);
  static Color colorBlueCustom8 = const Color.fromRGBO(0, 110, 221, 1);
  static Color colorBlueCustom1 = const Color.fromARGB(255, 145, 190, 244);
  static Color colorGrey = Colors.grey;
  static Color colorGreyCustom2 = const Color.fromRGBO(224, 224, 224, 1);
  static Color colorGreyCustom3 = const Color.fromRGBO(242, 242, 242, 1);
  static Color colorGreyCustom4 = const Color.fromRGBO(189, 189, 189, 1);
  static Color colorGreyCustom5 = const Color.fromRGBO(51, 51, 51, 0.2);
  static Color colorGreyCustom6 = const Color.fromRGBO(106, 106, 106, 1);
  static Color colorGreyCustom7 = const Color.fromRGBO(128, 128, 128, 1);
  static Color colorGreyCustom8 = const Color.fromRGBO(131, 131, 131, 1);
  static Color colorGreyCustom9 = const Color.fromRGBO(143, 144, 144, 1);
  static Color colorGreyCustom10 = const Color.fromRGBO(244, 244, 244, 1);
  static Color colorGreyCustom11 = const Color.fromRGBO(135, 135, 135, 1);
  static Color colorWaitForApproved = const Color.fromRGBO(251, 191, 36, 1);
  static Color colorCheckin = const Color.fromRGBO(2, 132, 199, 1);
  static Color colorApproved = const Color.fromRGBO(22, 163, 74, 1);
  static Color colorReject = const Color.fromRGBO(220, 38, 38, 1);
  static Color colorCompany = Color.fromARGB(255, 243, 107, 33);
  static Color colorCompanytest = Color.fromARGB(103, 243, 107, 33);

  static Color colorBlueCustom4 = const Color.fromRGBO(235, 243, 244, 1);
  static double buttonBorderRadius = 8;
  static double buttonMarginLogo = 5;
  static IconData iconHistory = FontAwesomeIcons.clockRotateLeft;
  static IconData iconSearch = FontAwesomeIcons.magnifyingGlass;
  static IconData iconUnCheck = FontAwesomeIcons.circle;
  static IconData iconTrash = FontAwesomeIcons.trash;
  static IconData iconSave = Icons.save;
  static IconData iconAdd = FontAwesomeIcons.circlePlus;
  static IconData iconAdd2 = FontAwesomeIcons.plus;
  static IconData iconOK = FontAwesomeIcons.solidCircleCheck;
  static IconData iconCheck = FontAwesomeIcons.check;
  static IconData iconCheck2 = FontAwesomeIcons.solidCircleCheck;
  static IconData iconCheckBoxUnCheck = FontAwesomeIcons.square;
  static IconData iconCheckBoxChecked = FontAwesomeIcons.squareCheck;
  static IconData iconClose = FontAwesomeIcons.solidCircleXmark;
  static IconData iconClose2 = FontAwesomeIcons.xmark;
  static Color colorGreen = Colors.green;
  static Color colorTransparent = Colors.transparent;
  static double fontSizeToast = 16;
  static String emailSupport = "support@vri.co.th";
  static String imgcicleBlue = "assets/images/cicleblue.png";
  static String imgeTimelinecircle = "assets/images/Group.png";
  static String imgeTransport = "assets/images/transport.svg";
  static String imgeBook = "assets/images/iconbook.svg";
  static String imgeBell = "assets/images/Bell.svg";
  static String imgeFastTrck = "assets/images/delivery.svg";
  static String imgeSetting = "assets/images/settings.svg";
  static String imgVip = "assets/images/VIP_1.png";
  static String vector = "assets/images/Vector.svg";
  static RegExp regExpEmail = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

  // static changeLanguageString(BuildContext context, String txt) {
  //   return EzLocalization.of(context)!.get(txt);
  // }

  // static changeLanguage(BuildContext context, String language) {
  //   return EzLocalizationBuilder.of(context)!.changeLocale(Locale(language));
  // }

  static showText(BuildContext context, String text, FontWeight weightText,
      Color textColor, double fontSize) {
    return Text(
      text,
      style: TextStyle(
        color: textColor,
        fontWeight: weightText,
        fontSize: ToolUtility.autoSize(context, fontSize),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  static loading(bool isShow) async {
    if (isShow) {
      BotToast.showLoading(
        backButtonBehavior: BackButtonBehavior.ignore,
        backgroundColor: colorTransparent,
      );
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        BotToast.closeAllLoading();
      });
    }
  }

  static bool checkEmailFormat(String email) {
    return regExpEmail.hasMatch(email);
  }

  static Radius borderRadiusNormalCircular(BuildContext context) {
    return Radius.circular(autoSize(context, borderRadiusNormal));
  }

  static BorderRadius borderRadiusNormalAllCircular(BuildContext context) {
    return BorderRadius.circular(autoSize(context, borderRadiusNormal));
  }

  static bool stringIsNullOrEmpty(dynamic data) {
    return ["", "null", null].contains(data);
  }

  static bool isNumberZero(dynamic data) {
    return ["0", "0.0", 0, 0.0].contains(data);
  }

  static OutlineInputBorder borderInput(BuildContext context) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.all(
        Radius.circular(autoSize(context, 5)),
      ),
    );
  }

  static Widget dividerList(BuildContext context, double lineHeight) {
    return Column(
      children: [
        Divider(
          color: colorMain,
          indent: autoSize(context, 5),
          endIndent: autoSize(context, 5),
          thickness: autoSize(context, lineHeight),
        ),
        Text(
          '',
          style: TextStyle(fontSize: ToolUtility.fontSizeButton2),
        ),
      ],
    );
  }

  static Widget loadingSearch(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(autoSize(context, 10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorMain),
          ),
        ],
      ),
    );
  }

  static toast(BuildContext context, bool isSuccress, String msg) {
    BotToast.showText(
      text: msg,
      contentColor: isSuccress ? colorGreen : Colors.brown,
      animationDuration: const Duration(milliseconds: 500),
      duration: const Duration(seconds: 4),
      textStyle: TextStyle(
        color: colorWhite,
        fontSize: autoSize(context, fontSizeToast),
      ),
    );
  }

  static Widget ticket(
      BuildContext context, Color colorRadius, Color colorLineDash) {
    double width = 20;
    List<Color> colorGradients = [colorGrey, colorBlueCustom4];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: autoSize(context, width),
          height: autoSize(context, width * 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: colorGradients,
            ),
            borderRadius: BorderRadius.horizontal(
              right: Radius.elliptical(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.width),
            ),
          ),
          child: Center(
            child: Container(
              width: autoSize(context, (width - 3)),
              height: autoSize(context, (width - 3) * 2),
              decoration: BoxDecoration(
                color: colorBlueCustom4,
                border: Border.all(
                  color: colorBlueCustom4,
                  width: 0,
                ),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.elliptical(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.width),
                ),
              ),
            ),
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: dotted(context, colorLineDash),
        ),
        Container(
          width: autoSize(context, width),
          height: autoSize(context, width * 2),
          margin: EdgeInsets.only(
            left: autoSize(context, 5),
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colorGradients,
            ),
            borderRadius: BorderRadius.horizontal(
              left: Radius.elliptical(MediaQuery.of(context).size.width,
                  MediaQuery.of(context).size.width),
            ),
          ),
          child: Center(
            child: Container(
              width: autoSize(context, (width - 3)),
              height: autoSize(context, (width - 3) * 2),
              decoration: BoxDecoration(
                color: colorBlueCustom4,
                border: Border.all(
                  color: colorBlueCustom4,
                  width: 0,
                ),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.elliptical(MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.width),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget dotted(BuildContext context, Color colorLineDash) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            List.generate(MediaQuery.of(context).size.width.toInt(), (index) {
          return Container(
            width: autoSize(context, 5),
            height: autoSize(context, 2),
            color: colorLineDash,
            margin: EdgeInsets.only(
              left: autoSize(context, 5),
            ),
          );
        }),
      ),
    );
  }

  static Widget verticalDivider(BuildContext context, Color color) {
    return VerticalDivider(
      color: color,
      thickness: autoSize(context, 1),
      indent: autoSize(context, 5),
      endIndent: autoSize(context, 5),
    );
  }

  static gotoPage(BuildContext? context, Widget page) {
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
          FadeScreen(page: page), (Route<dynamic> round) => false);
    }
  }

  static gotoPageHasBack(BuildContext context, Widget page) {
    Navigator.push(context, FadeScreen(page: page));
  }

  static gotoPageFromFCM(Widget page) {
    navigatorKey.currentState!.pushAndRemoveUntil(
        FadeScreen(page: page), (Route<dynamic> round) => false);
  }

  // static popupPageExit(BuildContext context, Widget page) {
  //   var body = Column(
  //     children: [
  //       titlePopup(context, changeLanguageString(context, "all.pageExit")),
  //     ],
  //   );
  //   popupCore(
  //     context,
  //     dialogTypeConfirm,
  //     body,
  //     CustomButton(
  //       text: changeLanguageString(context, "all.buttonOK"),
  //       icon: iconOK,
  //       color: colorGreen,
  //       onClick: () {
  //         gotoPage(context, page);
  //       },
  //     ),
  //     CustomButton(
  //       text: changeLanguageString(context, "all.buttonCancel"),
  //       icon: iconClose,
  //       color: colorRed,
  //       onClick: () {
  //         if (Navigator.canPop(context)) {
  //           Navigator.pop(context);
  //         }
  //       },
  //     ),
  //   );
  // }

  static double autoSize(BuildContext context, double size) {
    var textScaleFactor = MediaQuery.textScaleFactorOf(context);
    if (textScaleFactor <= 1) {
      return MediaQuery.of(context).size.width * (0.0025 * size);
    } else {
      return (MediaQuery.of(context).size.width * (0.0025 * size)) /
          textScaleFactor;
    }
  }
}
