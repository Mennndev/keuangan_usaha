enum ProductBrand { vanestrix, dioses, vinbee, zahwa }

extension ProductBrandX on ProductBrand {
  String get label => switch (this) {
    ProductBrand.vanestrix => 'Vanestrix',
    ProductBrand.dioses => 'Dioses',
    ProductBrand.vinbee => 'Vinbee',
    ProductBrand.zahwa => 'Zahwa',
  };

  static ProductBrand fromDatabase(String value) => ProductBrand.values
      .firstWhere((brand) => brand.label == value);
}

class Product {
  const Product({
    required this.id,
    required this.brand,
    required this.name,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ProductBrand brand;
  final String name;
  final int sellingPrice;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ProductSalesSummary {
  const ProductSalesSummary({
    required this.product,
    required this.quantitySold,
    required this.revenue,
  });

  final Product product;
  final int quantitySold;
  final int revenue;
}

class StockMovement {
  const StockMovement({
    required this.productName,
    required this.brand,
    required this.quantityChange,
    required this.reason,
    required this.movementDate,
    this.notes,
  });

  final String productName;
  final String brand;
  final int quantityChange;
  final String reason;
  final DateTime movementDate;
  final String? notes;
}
