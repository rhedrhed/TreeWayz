import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../servicesuwu/api.dart';
import '../screensuwu/loading_screen.dart';
import '../screensuwu/signup_screen.dart';
import '../screensuwu/home_screen.dart';
import '../screensuwu/welcome_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  bool _emailEmptyError = false;
  bool _passError = false;
  bool _hasAtChar = false;
  bool _showedAtWarning = false;

  @override
  void initState() {
    super.initState();

    email.addListener(() {
      final hasAt = email.text.contains('@');
      if (hasAt != _hasAtChar) {
        _hasAtChar = hasAt;
        if (hasAt && !_showedAtWarning) {
          _showedAtWarning = true;
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Please use a university provided email'),
              ),
            );
        } else if (!hasAt && _showedAtWarning) {
          _showedAtWarning = false;
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
        }
      }

      if (_emailEmptyError && email.text.trim().isNotEmpty) {
        _emailEmptyError = false;
      }
      setState(() {});
    });

    password.addListener(() {
      if (_passError && password.text.trim().isNotEmpty) {
        _passError = false;
      }
      setState(() {});
    });

    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && email.text.trim().isEmpty) {
        setState(() => _emailEmptyError = true);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("Email shouldn't be empty")),
          );
      }
    });

    _passFocus.addListener(() {
      if (!_passFocus.hasFocus && password.text.trim().isEmpty) {
        setState(() => _passError = true);
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text("Password shouldn't be empty")),
          );
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final em = email.text.trim();
    final pw = password.text.trim();

    setState(() {
      _emailEmptyError = em.isEmpty;
      _passError = pw.isEmpty;
    });

    if (_emailEmptyError || _passError) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      return;
    }

    if (_hasAtChar) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Please use a university provided email'),
          ),
        );
      return;
    }

    setState(() => loading = true);

    // Backend expects just the local part (it adds @aubh.edu.bh)
    final res = await Api.post('/login', {
      "email": em, // Send local part only
      "password": pw,
    });

    setState(() => loading = false);

    if (res != null && res["success"] == true && res["token"] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", res["token"]);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoadingScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                res?["message"] ?? 'Login failed – check credentials',
              ),
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormFilled =
        email.text.trim().isNotEmpty && password.text.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
        body: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Image.asset("elementsuwu/logo.png", height: 180),
                Text("TreeWayz", style: AppText.heading),
                Text("Thrifty, Thoughtful, Together", style: AppText.small),
                const SizedBox(height: 20),

                TextField(
                  focusNode: _emailFocus,
                  controller: email,
                  cursorColor: AppColors.brown,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      InputDecoration(
                        labelText: "University Provided Email",
                        hintText: "Ex: F2300067 or fatema.akbar",
                        border: const OutlineInputBorder(),
                        suffixText: "@aubh.edu.bh",
                        suffixStyle: const TextStyle(color: AppColors.black),
                        errorText: _hasAtChar
                            ? 'Please use a university provided email'
                            : (_emailEmptyError ? 'Required' : null),
                      ).copyWith(
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _hasAtChar ? AppColors.red : AppColors.brown,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _hasAtChar
                                ? AppColors.red
                                : AppColors.lightGrey,
                          ),
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: AppColors.brown,
                        ),
                      ),
                ),
                const SizedBox(height: 15),

                TextField(
                  focusNode: _passFocus,
                  controller: password,
                  obscureText: true,
                  cursorColor: AppColors.brown,
                  decoration:
                      InputDecoration(
                        labelText: "Password",
                        border: const OutlineInputBorder(),
                        errorText: _passError ? 'Required' : null,
                      ).copyWith(
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.brown),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.lightGrey),
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: AppColors.brown,
                        ),
                      ),
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    fixedSize: const Size(350, 50),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: (loading || !isFormFilled || _hasAtChar)
                      ? null
                      : login,
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Sign In", style: AppText.button),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              );
            },
            child: const Text(
              "Not a member? Click here to sign up<3",
              style: AppText.small,
            ),
          ),
        ),
      ),
    );
  }
}
