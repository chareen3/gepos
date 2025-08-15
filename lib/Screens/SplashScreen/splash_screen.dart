import 'dart:io';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mobile_pos/Screens/SplashScreen/on_board.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:mobile_pos/model/business_info_model.dart';
import 'package:nb_utils/nb_utils.dart' as SystemNavigator;
import 'package:nb_utils/nb_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Repository/API/business_info_repo.dart';
import '../../currency.dart';
import '../Authentication/Repo/licnese_repo.dart';
import '../Home/home.dart';
import '../language/language_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  void getPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
  }

  int retryCount = 0;

  checkUserValidity() async {
    final bool isConnected = await InternetConnection().hasInternetAccess;
    if (isConnected) {
      await PurchaseModel().isActiveBuyer().then((value) {
        // nextPage();
        if (!value) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Not Active User"),
                content: const Text("Please use the valid purchase code to use the app."),
                actions: [
                  TextButton(
                    onPressed: () {
                      //Exit app
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else {
                        exit(0);
                      }
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
          }
        } else {
          nextPage();
        }
      });
    } else {
      if (retryCount < 3) {
        retryCount++;
        checkUserValidity();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("No Internet Connection"),
            content: const Text("Please check your internet connection and try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  checkUserValidity();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getPermission();
    CurrencyMethods().getCurrencyFromLocalDatabase();
    checkUserValidity();
    setLanguage();
  }

  Future<void> setLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('lang') ?? 'en'; // Default to English code
    setState(() {
      selectedLanguage = savedLanguageCode;
    });
    context.read<LanguageChangeProvider>().changeLocale(savedLanguageCode);
  }

  Future<void> nextPage() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.delayed(const Duration(seconds: 1));

    final token = prefs.getString('token');

    if (token == null) {
      CurrencyMethods().removeCurrencyFromLocalDatabase();
      return _goTo(const OnBoard());
    }

    final data = await BusinessRepository().checkBusinessData();
    _goTo(data == null ? const OnBoard() : const Home());
  }

  void _goTo(Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: kMainColor,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              height: 230,
              width: 230,
              decoration: const BoxDecoration(image: DecorationImage(image: AssetImage(splashLogo))),
            ),
            const Spacer(),
            Center(
              child: Text(
                '${lang.S.of(context).poweredBy} $companyName',
                style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 18),
              ),
            ),
            // Center(
            //   child: Text(
            //     'V $appVersion',
            //     style: theme.textTheme.titleLarge?.copyWith(
            //       color: Colors.white,
            //       fontWeight: FontWeight.w500,
            //       fontSize: 18,
            //     ),
            //   ),
            // ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
