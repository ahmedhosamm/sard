import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../style/BaseScreen.dart';
import '../../../../../../style/Colors.dart';
import '../../../../../../style/Fonts.dart';
import '../../../../../utils/text_input_formatters.dart';
import '../../../login/View/Login.dart';
import '../../otp/View/otp.dart';

import '../logic/register_cubit.dart';
import '../logic/register_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;

  // إضافة controller للـ ScrollView لتجنب مشكلة الـ overflow عند فتح لوحة المفاتيح
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(),
      child: BlocConsumer<RegisterCubit, RegisterStates>(
        listener: (context, state) {
          if (state is RegisterSuccessState) {
            // Create a completely new RegisterCubit for OTP screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      RegisterCubit()..setRegisteredEmail(state.email),
                  child: VerificationCodeScreen(email: state.email),
                ),
              ),
            );
          } else if (state is RegisterErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(state.error),
                ),
              ),
            );
          } else if (state is PasswordsNotMatchingState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text('كلمة المرور وتأكيد كلمة المرور غير متطابقين'),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: BaseScreen(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                "مرحبًا بك في سرد",
                                style: AppTexts.display1Bold,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                "الرجاء إدخال بريدك الإلكتروني وسنرسل رمز التأكيد إلى بريدك الإلكتروني",
                                style: AppTexts.highlightEmphasis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildTextField(
                                "الاسم الكامل", "أدخل اسمك", _nameController),
                            _buildTextField("البريد الإلكتروني",
                                "أدخل بريدك الإلكتروني", _emailController,
                                isEmailField: true),
                            _buildTextField(
                              "كلمة المرور",
                              "أدخل كلمة المرور",
                              _passwordController,
                              obscureText: _obscurePassword,
                              toggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            _buildTextField(
                              "تأكيد كلمة المرور",
                              "أعد إدخال كلمة المرور",
                              _confirmPasswordController,
                              obscureText: _obscurePassword,
                              toggleVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            _buildRegisterButton(context, state),
                            const SizedBox(height: 16),
                            _buildLoginLink(),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // إضافة resizeToAvoidBottomInset لمنع المشاكل عند ظهور لوحة المفاتيح
            resizeToAvoidBottomInset: true,
          );
        },
      ),
    );
  }

  Widget _buildRegisterButton(BuildContext context, RegisterStates state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: state is RegisterLoadingState
              ? null
              : () {
                  BlocProvider.of<RegisterCubit>(context).registerUser(
                    name: _nameController.text,
                    email: _emailController.text.toLowerCase(),
                    password: _passwordController.text,
                    confirmPassword: _confirmPasswordController.text,
                  );
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: state is RegisterLoadingState
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  "إنشاء حساب",
                  style: AppTexts.contentEmphasis
                      .copyWith(color: AppColors.neutral100),
                ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: Text(
              "تسجيل الدخول",
              style: AppTexts.contentEmphasis.copyWith(
                color: AppColors.primary500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "هل لديك حساب بالفعل؟",
            style: AppTexts.contentRegular.copyWith(
              color: AppColors.neutral900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    VoidCallback? toggleVisibility,
    bool isEmailField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: AppTexts.contentRegular),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            textAlign: TextAlign.right,
            obscureText: obscureText,
            inputFormatters:
                isEmailField ? [LowercaseTextInputFormatter()] : null,
            onTap: () {
              // التمرير لأسفل عند الضغط على الحقل لتجنب مشكلة الـ overflow
              Future.delayed(const Duration(milliseconds: 300), () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTexts.contentRegular,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.neutral400),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.neutral400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppColors.primary500, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: toggleVisibility != null
                  ? GestureDetector(
                      onTap: toggleVisibility,
                      child: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.neutral400,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
