import 'package:flutter/material.dart';
import 'package:wholesale_shoes_invoice/presentation/brands/brands_screen.dart';
import 'package:wholesale_shoes_invoice/presentation/screens/Categories/categories_screen.dart';

import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/invoices/invoices_list_screen.dart';
import '../presentation/screens/invoices/create_invoice_screen.dart';
import '../presentation/screens/invoices/invoice_details_screen.dart';
import '../presentation/screens/products/products_list_screen.dart';
import '../presentation/screens/products/add_product_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/settings/exchange_rate_screen.dart';
import '../data/models/invoice_model.dart';

class AppRoutes {
  static const String home = '/';
  static const String invoices = '/invoices';
  static const String createInvoice = '/invoices/create';
  static const String invoiceDetails = '/invoices/details';
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/edit';
  static const String settings = '/settings';
  static const String exchangeRate = '/settings/exchange-rate';
  static const String categories = '/settings/categories';
  static const String brands = '/settings/brands';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case invoices:
        return MaterialPageRoute(
          builder: (_) => const InvoicesListScreen(),
        );

      case createInvoice:
        return MaterialPageRoute(
          builder: (_) => const CreateInvoiceScreen(),
        );

      case invoiceDetails:
        final invoice = settings.arguments as InvoiceModel;
        return MaterialPageRoute(
          builder: (_) => InvoiceDetailsScreen(invoice: invoice),
        );

      case products:
        return MaterialPageRoute(
          builder: (_) => const ProductsListScreen(),
        );

      case addProduct:
        return MaterialPageRoute(
          builder: (_) => const AddProductScreen(),
        );

      case editProduct:
        final productId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => AddProductScreen(productId: productId),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const SettingsScreen(),
        );

      case exchangeRate:
        return MaterialPageRoute(
          builder: (_) => const ExchangeRateScreen(),
        );

      case categories:
        return MaterialPageRoute(
          builder: (_) => const CategoriesScreen(),
        );

      case brands:
        return MaterialPageRoute(
          builder: (_) => const BrandsScreen(),
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
