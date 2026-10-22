part of '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final email = TextEditingController();
  final name = TextEditingController();
  final otp = TextEditingController();

  bool registering = false;
  bool loading = false;
  String? challengeId;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    email.dispose();
    name.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      if (challengeId != null) {
        // Bước 3: Xác thực OTP
        final result = await api(
          'POST',
          'auth/verify-otp',
          {
            'challengeId': challengeId,
            'code': otp.text.trim(),
          },
        );

        jwtToken = result['token']?.toString();
        currentRole =
            result['role']?.toString() ?? 'Employee';
        fullName = result['fullName']?.toString() ?? '';

        if (jwtToken == null || jwtToken!.isEmpty) {
          throw Exception('Không nhận được JWT Token');
        }

        if (!mounted) return;

        if (currentRole == 'Admin') {
          goTo(context, const AdminScreen());
        } else {
          goTo(context, const EmployeeScreen());
        }
      } else if (registering) {
        // Bước 1: Đăng ký nhân viên
        final result = await api(
          'POST',
          'auth/register',
          {
            'username': username.text.trim(),
            'password': password.text,
            'email': email.text.trim(),
            'fullName': name.text.trim(),
          },
        );

        if (!mounted) return;
        showMessage(
          context,
          result['message']?.toString() ??
              'Đăng ký thành công',
        );
        setState(() => registering = false);
      } else {
        // Bước 2: Đăng nhập lấy Challenge ID
        final result = await api(
          'POST',
          'auth/login',
          {
            'username': username.text.trim(),
            'password': password.text,
          },
        );

        if (!mounted) return;
        setState(() {
          challengeId =
              result['challengeId']?.toString();
        });

        showMessage(
          context,
          'Đã tạo OTP. Kiểm tra email hoặc Console Backend.',
        );
      }
    } catch (e) {
      if (mounted) showMessage(context, '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      color: Colors.indigo,
                      size: 70,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'HELLO CHECKIN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Ứng dụng chấm công - Nhóm Hello',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),

                    if (challengeId == null) ...[
                      TextField(
                        controller: username,
                        decoration: const InputDecoration(
                          labelText: 'Tên đăng nhập',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (registering) ...[
                        TextField(
                          controller: name,
                          decoration: const InputDecoration(
                            labelText: 'Họ và tên',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Mật khẩu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ] else ...[
                      const Text(
                        'Nhập mã OTP gồm 6 chữ số',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: otp,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Mã OTP',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: loading ? null : submit,
                      child: Text(
                        loading
                            ? 'Đang xử lý...'
                            : challengeId != null
                            ? 'XÁC THỰC OTP'
                            : registering
                            ? 'ĐĂNG KÝ'
                            : 'ĐĂNG NHẬP',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (challengeId != null) {
                            challengeId = null;
                            otp.clear();
                          } else {
                            registering = !registering;
                          }
                        });
                      },
                      child: Text(
                        challengeId != null
                            ? 'Đăng nhập lại'
                            : registering
                            ? 'Đã có tài khoản? Đăng nhập'
                            : 'Chưa có tài khoản? Đăng ký',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ====================================
// TRANG NHÂN VIÊN
// ====================================

