import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dose_certa/core/routes/app_router.dart';
import 'package:dose_certa/core/theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _navigateToMain();
  }

  Future<void> _navigateToMain() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRouter.main);
  }

  @override
  Widget build(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final double logoWidth =
        (shortestSide * 0.72).clamp(220.0, 340.0).toDouble();

    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: logoWidth,
              maxHeight: logoWidth,
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, _, __) => const Icon(
                Icons.medication,
                color: Colors.white,
                size: 128,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
