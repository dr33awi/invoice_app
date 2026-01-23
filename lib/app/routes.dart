import 'package:flutter/material.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/Categories/categories_screen.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/brands/brands_screen.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/customers/customers_screen.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/splash/splash_screen.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/auth/auth_screens.dart';

import '../core/utils/page_transitions.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/invoices/invoices_list_screen.dart';
import '../presentation/screens/invoices/create_invoice_screen.dart';
import '../presentation/screens/invoices/invoice_details_screen.dart';
import '../presentation/screens/products/products_list_screen.dart';
import '../presentation/screens/products/add_product_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/exchange_rate_screen.dart';
import '../presentation/screens/settings/company_settings_screen.dart';
import '../presentation/screens/settings/account_settings_screen.dart';
import '../presentation/screens/invoices/invoice_preview_screen.dart';
import '../data/models/invoice_model.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String invoices = '/invoices';
  static const String createInvoice = '/invoices/create';
  static const String invoiceDetails = '/invoices/details';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';
  static const String settings = '/settings';
  static const String accountSettings = '/settings/account';
  static const String exchangeRate = '/settings/exchange-rate';
  static const String companySettings = '/settings/company';
  static const String categories = '/settings/categories';
  static const String brands = '/settings/brands';
  static const String customers = '/customers';
  static const String invoicePreview = '/invoices/preview';
  static const String invoicePreviewSettings = '/settings/invoice-preview';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return FadePageRoute(
          page: const SplashScreen(),
          settings: settings,
        );

      case login:
        return FadePageRoute(
          page: const EmailAuthScreen(),
          settings: settings,
        );

      case home:
        return FadePageRoute(
          page: const HomeScreen(),
          settings: settings,
        );

      case invoices:
        return SlidePageRoute(
          page: const InvoicesListScreen(),
          settings: settings,
        );

      case createInvoice:
        return SlidePageRoute(
          page: const CreateInvoiceScreen(),
          direction: SlideDirection.up,
          settings: settings,
        );

      case invoiceDetails:
        final invoice = settings.arguments as InvoiceModel;
        return SlidePageRoute(
          page: InvoiceDetailsScreen(invoice: invoice),
          settings: settings,
        );

      case products:
        return SlidePageRoute(
          page: const ProductsListScreen(),
          settings: settings,
        );

      case addProduct:
        return SlidePageRoute(
          page: const AddProductScreen(),
          direction: SlideDirection.up,
          settings: settings,
        );

      case editProduct:
        final productId = settings.arguments as String;
        return SlidePageRoute(
          page: AddProductScreen(productId: productId),
          settings: settings,
        );

      case AppRoutes.settings:
        return SlidePageRoute(
          page: const SettingsScreen(),
          settings: settings,
        );

      case accountSettings:
        return SlidePageRoute(
          page: const AccountSettingsScreen(),
          settings: settings,
        );

      case exchangeRate:
        return SlidePageRoute(
          page: const ExchangeRateScreen(),
          settings: settings,
        );

      case companySettings:
        return SlidePageRoute(
          page: const CompanySettingsScreen(),
          settings: settings,
        );

      case categories:
        return SlidePageRoute(
          page: const CategoriesScreen(),
          settings: settings,
        );

      case brands:
        return SlidePageRoute(
          page: const BrandsScreen(),
          settings: settings,
        );

      case customers:
        return SlidePageRoute(
          page: const CustomersScreen(),
          settings: settings,
        );

      case invoicePreview:
        final invoice = settings.arguments as InvoiceModel;
        return SlidePageRoute(
          page: InvoicePreviewScreen(invoice: invoice),
          settings: settings,
        );

      case invoicePreviewSettings:
        return SlidePageRoute(
          page: const InvoicePreviewSettingsScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('الصفحة غير موجودة: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
