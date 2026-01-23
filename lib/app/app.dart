import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../core/theme/app_theme.dart';
import 'routes.dart';

class WholesaleShoesApp extends StatelessWidget {
  const WholesaleShoesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'نظام فواتير الأحذية',
          debugShowCheckedModeBanner: false,

          // Theme
          theme: AppTheme.light,

          // Localization
          locale: const Locale('ar'),
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // SafeArea builder - يطبق SafeArea للأسفل فقط
          builder: (context, child) {
            return SafeArea(
              top: false, // تعطيل الحماية العلوية
              bottom: true, // تفعيل الحماية السفلية
              child: child ?? const SizedBox.shrink(),
            );
          },

          // Routes
          initialRoute: AppRoutes.home,
          onGenerateRoute: AppRoutes.generateRoute,
        );
      },
    );
  }
}
