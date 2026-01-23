import 'package:hive/hive.dart';
import 'product_model.dart';
import 'invoice_model.dart';
import 'sync_metadata.dart';
import 'category_model.dart';
import 'brand_model.dart';
import 'customer_model.dart';
import 'payment_model.dart';

// ═══════════════════════════════════════════════════════════
// PRODUCT SIZE MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class ProductSizeModelAdapter extends TypeAdapter<ProductSizeModel> {
  @override
  final int typeId = 7;

  @override
  ProductSizeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductSizeModel(
      size: fields[0] as String,
      stock: fields[1] as int? ?? 0,
      minStock: fields[2] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ProductSizeModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.size)
      ..writeByte(1)
      ..write(obj.stock)
      ..writeByte(2)
      ..write(obj.minStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSizeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// PRODUCT MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 0;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[13] as String?,
      categoryId: fields[6] as String?,
      categoryName: fields[14] as String?,
      brandId: fields[2] as String?,
      brandName: fields[15] as String?,
      description: fields[16] as String?,
      imageUrl: fields[17] as String?,
      sizeRange: fields[3] as String,
      sizes: (fields[18] as List?)?.cast<ProductSizeModel>() ?? [],
      costPrice: fields[19] as double? ?? 0,
      wholesalePrice: fields[4] as double,
      retailPrice: fields[20] as double?,
      currency: fields[5] as String? ?? 'USD',
      packagesCount: fields[11] as int? ?? 1,
      pairsPerPackage: fields[12] as int? ?? 12,
      totalStock: fields[21] as int?,
      isActive: fields[7] as bool? ?? true,
      createdAt: fields[8] as DateTime?,
      updatedAt: fields[9] as DateTime?,
      createdBy: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.brandId)
      ..writeByte(3)
      ..write(obj.sizeRange)
      ..writeByte(4)
      ..write(obj.wholesalePrice)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.isActive)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.createdBy)
      ..writeByte(11)
      ..write(obj.packagesCount)
      ..writeByte(12)
      ..write(obj.pairsPerPackage)
      ..writeByte(13)
      ..write(obj.code)
      ..writeByte(14)
      ..write(obj.categoryName)
      ..writeByte(15)
      ..write(obj.brandName)
      ..writeByte(16)
      ..write(obj.description)
      ..writeByte(17)
      ..write(obj.imageUrl)
      ..writeByte(18)
      ..write(obj.sizes)
      ..writeByte(19)
      ..write(obj.costPrice)
      ..writeByte(20)
      ..write(obj.retailPrice)
      ..writeByte(21)
      ..write(obj.totalStock);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// PAYMENT MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 6;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      method: fields[3] as String? ?? 'cash',
      note: fields[4] as String?,
      receivedBy: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.method)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.receivedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// INVOICE MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class InvoiceModelAdapter extends TypeAdapter<InvoiceModel> {
  @override
  final int typeId = 1;

  @override
  InvoiceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceModel(
      id: fields[0] as String,
      invoiceNumber: fields[1] as String,
      customerName: fields[2] as String,
      customerPhone: fields[3] as String?,
      customerId: fields[19] as String?,
      date: fields[4] as DateTime,
      items: (fields[5] as List).cast<InvoiceItemModel>(),
      subtotal: fields[6] as double,
      discount: fields[7] as double? ?? 0,
      discountAmount: fields[20] as double? ?? 0,
      totalUSD: fields[8] as double,
      exchangeRate: fields[9] as double,
      totalIQD: fields[10] as double,
      paidAmount: fields[18] as double? ?? 0,
      remainingAmount: fields[21] as double?,
      paymentStatus: fields[22] as String?,
      payments: (fields[23] as List?)?.cast<PaymentModel>() ?? [],
      status: fields[11] as String? ?? 'confirmed',
      notes: fields[12] as String?,
      invoiceDate: fields[24] as DateTime?,
      dueDate: fields[25] as DateTime?,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
      createdBy: fields[15] as String?,
      barcodeValue: fields[16] as String?,
      paymentMethod: fields[17] as String? ?? 'cash',
      year: fields[26] as int?,
      month: fields[27] as int?,
      day: fields[28] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceModel obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.invoiceNumber)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.customerPhone)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.items)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.discount)
      ..writeByte(8)
      ..write(obj.totalUSD)
      ..writeByte(9)
      ..write(obj.exchangeRate)
      ..writeByte(10)
      ..write(obj.totalIQD)
      ..writeByte(11)
      ..write(obj.status)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.createdBy)
      ..writeByte(16)
      ..write(obj.barcodeValue)
      ..writeByte(17)
      ..write(obj.paymentMethod)
      ..writeByte(18)
      ..write(obj.paidAmount)
      ..writeByte(19)
      ..write(obj.customerId)
      ..writeByte(20)
      ..write(obj.discountAmount)
      ..writeByte(21)
      ..write(obj.remainingAmount)
      ..writeByte(22)
      ..write(obj.paymentStatus)
      ..writeByte(23)
      ..write(obj.payments)
      ..writeByte(24)
      ..write(obj.invoiceDate)
      ..writeByte(25)
      ..write(obj.dueDate)
      ..writeByte(26)
      ..write(obj.year)
      ..writeByte(27)
      ..write(obj.month)
      ..writeByte(28)
      ..write(obj.day);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// INVOICE ITEM MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class InvoiceItemModelAdapter extends TypeAdapter<InvoiceItemModel> {
  @override
  final int typeId = 2;

  @override
  InvoiceItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InvoiceItemModel(
      productId: fields[0] as String,
      productName: fields[1] as String,
      size: fields[2] as String,
      quantity: fields[3] as int,
      unitPrice: fields[4] as double,
      total: fields[5] as double,
      brand: fields[6] as String? ?? '',
      packagesCount: fields[7] as int? ?? 1,
      pairsPerPackage: fields[8] as int? ?? 12,
      category: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InvoiceItemModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.size)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unitPrice)
      ..writeByte(5)
      ..write(obj.total)
      ..writeByte(6)
      ..write(obj.brand)
      ..writeByte(7)
      ..write(obj.packagesCount)
      ..writeByte(8)
      ..write(obj.pairsPerPackage)
      ..writeByte(9)
      ..write(obj.category);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// SYNC STATUS ADAPTER
// ═══════════════════════════════════════════════════════════

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = 8;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.syncing;
      case 2:
        return SyncStatus.synced;
      case 3:
        return SyncStatus.error;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
        break;
      case SyncStatus.syncing:
        writer.writeByte(1);
        break;
      case SyncStatus.synced:
        writer.writeByte(2);
        break;
      case SyncStatus.error:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// SYNC OPERATION ADAPTER
// ═══════════════════════════════════════════════════════════

class SyncOperationAdapter extends TypeAdapter<SyncOperation> {
  @override
  final int typeId = 11;

  @override
  SyncOperation read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncOperation.create;
      case 1:
        return SyncOperation.update;
      case 2:
        return SyncOperation.delete;
      default:
        return SyncOperation.create;
    }
  }

  @override
  void write(BinaryWriter writer, SyncOperation obj) {
    switch (obj) {
      case SyncOperation.create:
        writer.writeByte(0);
        break;
      case SyncOperation.update:
        writer.writeByte(1);
        break;
      case SyncOperation.delete:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncOperationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// SYNC METADATA ADAPTER
// ═══════════════════════════════════════════════════════════

class SyncMetadataAdapter extends TypeAdapter<SyncMetadata> {
  @override
  final int typeId = 12;

  @override
  SyncMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadata(
      id: fields[0] as String,
      collection: fields[1] as String,
      documentId: fields[2] as String,
      operation: fields[3] as SyncOperation,
      data: (fields[4] as Map?)?.cast<String, dynamic>(),
      status: fields[5] as SyncStatus? ?? SyncStatus.pending,
      createdAt: fields[6] as DateTime?,
      errorMessage: fields[7] as String?,
      retryCount: fields[8] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadata obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.collection)
      ..writeByte(2)
      ..write(obj.documentId)
      ..writeByte(3)
      ..write(obj.operation)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.errorMessage)
      ..writeByte(8)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// CATEGORY MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class CategoryModelAdapter extends TypeAdapter<CategoryModel> {
  @override
  final int typeId = 3;

  @override
  CategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryModel(
      id: fields[0] as String,
      name: fields[1] as String,
      nameEn: fields[6] as String?,
      description: fields[7] as String?,
      icon: fields[2] as String?,
      imageUrl: fields[8] as String?,
      colorValue: fields[3] as int?,
      order: fields[9] as int? ?? 0,
      isActive: fields[4] as bool? ?? true,
      productsCount: fields[10] as int? ?? 0,
      createdAt: fields[5] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.colorValue)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.nameEn)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.order)
      ..writeByte(10)
      ..write(obj.productsCount)
      ..writeByte(11)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// BRAND MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class BrandModelAdapter extends TypeAdapter<BrandModel> {
  @override
  final int typeId = 4;

  @override
  BrandModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BrandModel(
      id: fields[0] as String,
      name: fields[1] as String,
      nameEn: fields[2] as String?,
      logo: fields[3] as String?,
      logoUrl: fields[7] as String?,
      country: fields[4] as String?,
      order: fields[8] as int? ?? 0,
      isActive: fields[5] as bool? ?? true,
      productsCount: fields[9] as int? ?? 0,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, BrandModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nameEn)
      ..writeByte(3)
      ..write(obj.logo)
      ..writeByte(4)
      ..write(obj.country)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.logoUrl)
      ..writeByte(8)
      ..write(obj.order)
      ..writeByte(9)
      ..write(obj.productsCount)
      ..writeByte(10)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// ═══════════════════════════════════════════════════════════
// CUSTOMER MODEL ADAPTER
// ═══════════════════════════════════════════════════════════

class CustomerModelAdapter extends TypeAdapter<CustomerModel> {
  @override
  final int typeId = 5;

  @override
  CustomerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerModel(
      id: fields[0] as String,
      name: fields[1] as String,
      phone: fields[2] as String?,
      secondaryPhone: fields[8] as String?,
      address: fields[3] as String?,
      city: fields[9] as String?,
      totalPurchases: fields[10] as double? ?? 0,
      totalPaid: fields[11] as double? ?? 0,
      balance: fields[12] as double? ?? 0,
      type: fields[13] as String? ?? 'wholesale',
      rating: fields[14] as int? ?? 0,
      notes: fields[4] as String?,
      isActive: fields[5] as bool? ?? true,
      lastPurchaseDate: fields[15] as DateTime?,
      createdAt: fields[6] as DateTime?,
      updatedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.secondaryPhone)
      ..writeByte(9)
      ..write(obj.city)
      ..writeByte(10)
      ..write(obj.totalPurchases)
      ..writeByte(11)
      ..write(obj.totalPaid)
      ..writeByte(12)
      ..write(obj.balance)
      ..writeByte(13)
      ..write(obj.type)
      ..writeByte(14)
      ..write(obj.rating)
      ..writeByte(15)
      ..write(obj.lastPurchaseDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
