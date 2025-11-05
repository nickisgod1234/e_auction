import 'package:flutter/material.dart';
import 'package:e_auction/services/auth_service/auth_service.dart';
import 'package:e_auction/views/config/config_prod.dart';
import 'package:e_auction/views/first_page/request_otp_page/email_login_methods.dart';
import 'package:e_auction/views/first_page/request_otp_page/email_login_widgets.dart';

class EmailLoginPage extends StatefulWidget {
  @override
  _EmailLoginPageState createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(baseUrl: Config.apiUrlotpsever);

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    EmailLoginWidgets.showLoadingDialog(context);

    try {
      final result = await EmailLoginMethods.loginWithEmail(
        _authService,
        _emailController.text.trim(),
        _passwordController.text,
      );

      EmailLoginWidgets.hideLoadingDialog(context);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        EmailLoginMethods.showSuccessDialog(context);
        // รอสักครู่แล้วค่อย navigate
        await Future.delayed(Duration(milliseconds: 500));
        EmailLoginMethods.navigateToHome(context);
      } else {
        EmailLoginMethods.showErrorDialog(
          context,
          result['message'] ?? 'ไม่สามารถเข้าสู่ระบบได้',
        );
      }
    } catch (e) {
      EmailLoginWidgets.hideLoadingDialog(context);
      setState(() {
        _isLoading = false;
      });
      EmailLoginMethods.showErrorDialog(
        context,
        'เกิดข้อผิดพลาด: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('เข้าสู่ระบบด้วยอีเมล'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40),
                // Logo or Icon
                Icon(
                  Icons.email,
                  size: 80,
                  color: Colors.blue,
                ),
                SizedBox(height: 24),
                // Title
                Text(
                  'เข้าสู่ระบบด้วยอีเมล',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'กรุณากรอกอีเมลและรหัสผ่านของคุณ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                // Email Field
                EmailLoginWidgets.buildEmailField(
                  controller: _emailController,
                  validator: EmailLoginMethods.validateEmail,
                ),
                SizedBox(height: 20),
                // Password Field
                EmailLoginWidgets.buildPasswordField(
                  controller: _passwordController,
                  validator: EmailLoginMethods.validatePassword,
                  isPasswordVisible: _isPasswordVisible,
                  onToggleVisibility: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                SizedBox(height: 12),
                // Forgot Password Link (Optional)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('ฟีเจอร์นี้จะเปิดใช้งานในอนาคต'),
                        ),
                      );
                    },
                    child: Text(
                      'ลืมรหัสผ่าน?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Login Button
                EmailLoginWidgets.buildLoginButton(
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                ),
                SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'หรือ',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: 24),
                // Back to Phone Login Button
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.blue),
                  ),
                  child: Text(
                    'กลับไปใช้เบอร์โทรศัพท์',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
