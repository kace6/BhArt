class ParsedProduct {
  final String name;
  final String nameHi;
  final String material;
  final int quantity;
  final num? userSuggestedPrice;
  final String descriptionEn;
  final String descriptionHi;

  const ParsedProduct({
    required this.name,
    required this.nameHi,
    required this.material,
    required this.quantity,
    required this.userSuggestedPrice,
    required this.descriptionEn,
    required this.descriptionHi,
  });

  factory ParsedProduct.fromJson(Map<String, dynamic> json) {
    int parsedQty = 1;
    if (json['quantity'] is num) {
      parsedQty = (json['quantity'] as num).toInt();
    } else if (json['quantity'] != null) {
      parsedQty = int.tryParse(json['quantity'].toString()) ?? 1;
    }

    num? parsedPrice;
    if (json['userSuggestedPrice'] is num) {
      parsedPrice = json['userSuggestedPrice'] as num;
    } else if (json['userSuggestedPrice'] != null) {
      parsedPrice = num.tryParse(json['userSuggestedPrice'].toString());
    }

    return ParsedProduct(
      name: json['name']?.toString() ?? 'Unknown Product',
      nameHi: json['nameHi']?.toString() ?? '',
      material: json['material']?.toString() ?? 'Unknown',
      quantity: parsedQty,
      userSuggestedPrice: parsedPrice,
      descriptionEn: json['descriptionEn']?.toString() ?? '',
      descriptionHi: json['descriptionHi']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nameHi': nameHi,
        'material': material,
        'quantity': quantity,
        'userSuggestedPrice': userSuggestedPrice,
        'descriptionEn': descriptionEn,
        'descriptionHi': descriptionHi,
      };

  ParsedProduct copyWith({
    String? name,
    String? nameHi,
    String? material,
    int? quantity,
    num? userSuggestedPrice,
    String? descriptionEn,
    String? descriptionHi,
  }) {
    return ParsedProduct(
      name: name ?? this.name,
      nameHi: nameHi ?? this.nameHi,
      material: material ?? this.material,
      quantity: quantity ?? this.quantity,
      userSuggestedPrice: userSuggestedPrice ?? this.userSuggestedPrice,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
    );
  }

  static const mock = ParsedProduct(
    name: 'Handcrafted Terracotta Pot',
    nameHi: 'हस्तनिर्मित मिट्टी का मटका',
    material: 'Terracotta (Clay)',
    quantity: 1,
    userSuggestedPrice: null,
    descriptionEn:
        'A beautifully handcrafted terracotta pot, perfect for cooling water naturally or as rustic home decor. Made with traditional techniques.',
    descriptionHi:
        'यह एक सुंदर हस्तनिर्मित टेराकोटा पॉट है, जो पानी को प्राकृतिक रूप से ठंडा रखने या घर की सजावट के लिए एकदम सही है।',
  );
}