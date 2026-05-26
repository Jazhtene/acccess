import 'package:flutter/material.dart';

import 'package:access_mobile/shared/themes/theme.dart';

import 'package:access_mobile/shared/controllers/branding_controller.dart';

import 'package:access_mobile/shared/widgets/access_logo.dart';



/// Brief branded splash before the main app loads.

class MobileSplashGate extends StatefulWidget {

  const MobileSplashGate({super.key, required this.child});



  final Widget child;



  @override

  State<MobileSplashGate> createState() => _MobileSplashGateState();

}



class _MobileSplashGateState extends State<MobileSplashGate> {

  bool _showSplash = true;



  @override

  void initState() {

    super.initState();

    _initSplash();

  }



  Future<void> _initSplash() async {

    await brandingController.refresh();

    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) setState(() => _showSplash = false);

  }



  @override

  Widget build(BuildContext context) {

    if (_showSplash) {

      return Scaffold(

        backgroundColor: kBg,

        body: SafeArea(

          child: Center(

            child: Padding(

              padding: const EdgeInsets.symmetric(horizontal: 32),

              child: ListenableBuilder(

                listenable: brandingController,

                builder: (_, __) => Column(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    const AccessLogoImage(size: 150, fit: BoxFit.contain),

                    const SizedBox(height: 28),

                    Text(

                      brandingController.appName,

                      textAlign: TextAlign.center,

                      style: const TextStyle(

                        color: kTextPrimary,

                        fontSize: 26,

                        fontWeight: FontWeight.w800,

                        letterSpacing: 0.3,

                      ),

                    ),

                    const SizedBox(height: 10),

                    Text(

                      brandingController.shortTagline,

                      textAlign: TextAlign.center,

                      style: const TextStyle(color: kTextSecondary, fontSize: 13, height: 1.4),

                    ),

                    const SizedBox(height: 40),

                    const SizedBox(

                      width: 32,

                      height: 32,

                      child: CircularProgressIndicator(strokeWidth: 2.5, color: kAccent),

                    ),

                  ],

                ),

              ),

            ),

          ),

        ),

      );

    }

    return widget.child;

  }

}

