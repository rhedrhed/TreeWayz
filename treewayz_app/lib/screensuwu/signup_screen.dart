import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../servicesuwu/api.dart';
import '../screensuwu/loading_screen.dart';
import '../screensuwu/signin_screen.dart';
import '../themeuwu/app_text.dart';
import '../themeuwu/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final first = TextEditingController();
  final last = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  // focus nodes to detect blur (losing focus)
  final FocusNode _firstFocus = FocusNode();
  final FocusNode _lastFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();

  // new state to track "@" presence and to avoid repeating the SnackBar
  bool _hasAtChar = false;
  bool _showedAtWarning = false;

  // per-field error flags
  bool _firstError = false;
  bool _lastError = false;
  bool _phoneError = false; // empty
  bool _emailEmptyError = false;
  bool _passError = false;

  // new phone format error (must be exactly 8 digits after 973)
  bool _phoneFormatError = false;

  @override
  void initState() {
    super.initState();

    // clear field errors as user types
    first.addListener(() {
      if (_firstError && first.text.trim().isNotEmpty) setState(() => _firstError = false);
    });
    last.addListener(() {
      if (_lastError && last.text.trim().isNotEmpty) setState(() => _lastError = false);
    });
    pass.addListener(() {
      if (_passError && pass.text.trim().isNotEmpty) setState(() => _passError = false);
    });

    // phone listener: clear empty error and manage format error live
    phone.addListener(() {
      final digits = phone.text.trim();
      if (_phoneError && digits.isNotEmpty) setState(() => _phoneError = false);

      // show format error while field is non-empty and length != 8
      final wantsFormatError = digits.isNotEmpty && digits.length != 8;
      if (wantsFormatError != _phoneFormatError) setState(() => _phoneFormatError = wantsFormatError);
    });

    // fixed email listener: clears "empty" error when user types and
    // removes the "@" warning as soon as "@" is removed or the field is filled
    email.addListener(() {
      final hasAt = email.text.contains('@');

      if (hasAt != _hasAtChar) {
        setState(() => _hasAtChar = hasAt);
      }

      // clear empty-error when the user types something
      if (_emailEmptyError && email.text.trim().isNotEmpty) {
        setState(() => _emailEmptyError = false);
      }

      if (hasAt && !_showedAtWarning) {
        _showedAtWarning = true;
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Please use a university provided email')),
          );
      } else if (!hasAt && _showedAtWarning) {
        // user removed '@' -> clear the warning immediately
        _showedAtWarning = false;
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
      }
    });

    // focus listeners -> when user blurs a field check emptiness and set error
    _firstFocus.addListener(() {
      if (!_firstFocus.hasFocus && first.text.trim().isEmpty) {
        setState(() => _firstError = true);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("First name shouldn't be empty")),
        );
      }
    });
    _lastFocus.addListener(() {
      if (!_lastFocus.hasFocus && last.text.trim().isEmpty) {
        setState(() => _lastError = true);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Last name shouldn't be empty")),
        );
      }
    });
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) {
        final digits = phone.text.trim();
        if (digits.isEmpty) {
          setState(() => _phoneError = true);
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phone shouldn't be empty")),
          );
        } else if (!RegExp(r'^\d{8}$').hasMatch(digits)) {
          setState(() => _phoneFormatError = true);
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Phone must be 8 digits after 973")),
          );
        }
      }
    });
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && email.text.trim().isEmpty) {
        setState(() => _emailEmptyError = true);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email shouldn't be empty")),
        );
      }
    });
    _passFocus.addListener(() {
      if (!_passFocus.hasFocus && pass.text.trim().isEmpty) {
        setState(() => _passError = true);
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password shouldn't be empty")),
        );
      }
    });
  }

  @override
  void dispose() {
    first.dispose();
    last.dispose();
    phone.dispose();
    email.dispose();
    pass.dispose();

    // dispose focus nodes
    _firstFocus.dispose();
    _lastFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();

    super.dispose();
  }

  Future<void> register() async {
    // validate required fields
    final f = first.text.trim();
    final l = last.text.trim();
    final ph = phone.text.trim();
    final em = email.text.trim();
    final pw = pass.text.trim();

    bool hasError = false;
    setState(() {
      _firstError = f.isEmpty;
      _lastError = l.isEmpty;
      _phoneError = ph.isEmpty;
      _emailEmptyError = em.isEmpty;
      _passError = pw.isEmpty;

      // phone format check
      _phoneFormatError = ph.isNotEmpty && !RegExp(r'^\d{8}$').hasMatch(ph);

      hasError = _firstError || _lastError || _phoneError || _emailEmptyError || _passError || _phoneFormatError;
    });

    if (hasError) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return;
    }

    // block registration if user typed '@' (we expect local-part only)
    if (_hasAtChar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please use a university provided email')),
      );
      return;
    }

    setState(() => loading = true);

    const domain = '@aubh.edu.bh';
    final rawEmail = em;

    // determine local part and validate domain if user typed a full email
    String localPart = rawEmail;
    if (rawEmail.contains('@')) {
      final parts = rawEmail.split('@');
      localPart = parts.first;
      final providedDomain = '@' + parts.sublist(1).join('@');
      if (providedDomain.toLowerCase() != domain) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please use an @aubh.edu.bh email')),
        );
        return;
      }
    }

    if (localPart.isEmpty) {
      setState(() => loading = false);
      setState(() => _emailEmptyError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email local-part (before @)')),
      );
      return;
    }

    final fullEmail = '$localPart$domain';
    final fullPhone = '973$ph';

    final res = await Api.post('/auth/register', {
      "firstName": f,
      "lastName": l,
      "email": fullEmail,
      "phone": fullPhone,
      "password": pw,
    });

    setState(() => loading = false);

    if (res != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const SigninScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool fieldsEmpty = first.text.trim().isEmpty || last.text.trim().isEmpty || phone.text.trim().isEmpty || email.text.trim().isEmpty || pass.text.trim().isEmpty;
    bool emailHasAt = email.text.contains('@');
    bool disableButton = loading || fieldsEmpty || emailHasAt;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(backgroundColor: AppColors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Image.asset("elementsuwu/logo.png", height: 180),
              Text(
                "TreeWayz",
                style: AppText.heading,
              ),
              Text(
                "Thrifty, Thoughtful, Together",
                style: AppText.small,
              ),
              const SizedBox(height: 20),
              TextField(
                focusNode: _firstFocus,
                controller: first,
                cursorColor: AppColors.brown,
                decoration: InputDecoration(
                  labelText: "First Name",
                  border: const OutlineInputBorder(),
                  errorText: _firstError ? 'Thwis cwan nwot bwe emptwy uwu' : null,
                ).copyWith(
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brown),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.lightGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.brown),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                focusNode: _lastFocus,
                controller: last,
                cursorColor: AppColors.brown,
                decoration: InputDecoration(
                  labelText: "Last Name",
                  border: const OutlineInputBorder(),
                  errorText: _lastError ? 'Thwis cwan nwot bwe emptwy uwu' : null,
                ).copyWith(
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brown),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.lightGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: Colors.brown),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                focusNode: _emailFocus,
                controller: email,
                cursorColor: AppColors.brown,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "University Provided Email",
                  hintText: "Ex: F2300067 or fatema.akbar",
                  border: const OutlineInputBorder(),
                  suffixText: "@aubh.edu.bh",
                  suffixStyle: const TextStyle(color: AppColors.black),
                  // show email errors
                  errorText: _hasAtChar
                      ? 'Pwease use a university pwovided email'
                      : (_emailEmptyError ? 'Thwis cwan nwot bwe emptwy uwu' : null),
                ).copyWith(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _hasAtChar ? AppColors.red : AppColors.brown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _hasAtChar ? AppColors.red : AppColors.lightGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.brown),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                focusNode: _phoneFocus,
                controller: phone,
                cursorColor: AppColors.brown,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: "Phone #",
                  prefixText: "973",
                  prefixStyle: const TextStyle(color: AppColors.black),
                  border: const OutlineInputBorder(),
                  errorText: _phoneFormatError
                      ? 'Enter exactly 8 digits after 973'
                      : (_phoneError ? 'Thwis cwan nwot bwe emptwy uwu' : null),
                ).copyWith(
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _phoneFormatError ? AppColors.red : AppColors.brown),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _phoneFormatError ? AppColors.red : AppColors.lightGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.brown),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                focusNode: _passFocus,
                controller: pass,
                obscureText: true,
                cursorColor: AppColors.brown,
                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  errorText: _passError ? 'Thwis cwan nwot bwe emptwy uwu' : null,
                ).copyWith(
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.brown),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.lightGrey),
                  ),
                  floatingLabelStyle: const TextStyle(color: AppColors.brown),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  fixedSize: const Size(350, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: disableButton ? null : register,
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Step into TreeWayz",
                        style: AppText.button,
                      ),
              )
            ],
          ),
        ),
      ),
      // Pin the create-account button to the bottom
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        child: TextButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SigninScreen()));
          },
          child: const Text(
            "Already a member? Click here to sign in<3",
            style: AppText.small,
          ),
        ),
      ),
    );
  }
}
