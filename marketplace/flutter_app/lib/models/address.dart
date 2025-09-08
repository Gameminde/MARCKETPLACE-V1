/// Address model for checkout and shipping
class Address {
  final String id;
  final String firstName;
  final String lastName;
  final String street;
  final String? apartment;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String? phone;
  final bool isDefault;
  final AddressType type;

  const Address({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.street,
    this.apartment,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.phone,
    this.isDefault = false,
    this.type = AddressType.shipping,
  });

  /// Full address as single string
  String get fullAddress {
    final parts = <String>[
      '$firstName $lastName',
      street,
      if (apartment != null && apartment!.isNotEmpty) apartment!,
      '$city, $state $zipCode',
      country,
    ];
    return parts.join('\n');
  }

  /// Short address for display
  String get shortAddress {
    return '$street, $city, $state $zipCode';
  }

  /// Display name
  String get displayName {
    return '$firstName $lastName';
  }

  Address copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? street,
    String? apartment,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phone,
    bool? isDefault,
    AddressType? type,
  }) {
    return Address(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'street': street,
      'apartment': apartment,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'type': type.name,
    };
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      street: json['street'] as String,
      apartment: json['apartment'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      phone: json['phone'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
      type: AddressType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AddressType.shipping,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Address{id: $id, displayName: $displayName, shortAddress: $shortAddress}';
  }
}

/// Address types
enum AddressType {
  shipping,
  billing,
  both,
}

/// Mock data for addresses
class MockAddresses {
  static final List<Address> userAddresses = [
    const Address(
      id: 'addr_1',
      firstName: 'John',
      lastName: 'Doe',
      street: '123 Main Street',
      apartment: 'Apt 4B',
      city: 'New York',
      state: 'NY',
      zipCode: '10001',
      country: 'United States',
      phone: '+1 (555) 123-4567',
      isDefault: true,
      type: AddressType.both,
    ),
    const Address(
      id: 'addr_2',
      firstName: 'John',
      lastName: 'Doe',
      street: '456 Oak Avenue',
      city: 'Brooklyn',
      state: 'NY',
      zipCode: '11201',
      country: 'United States',
      phone: '+1 (555) 123-4567',
      type: AddressType.shipping,
    ),
    const Address(
      id: 'addr_3',
      firstName: 'Jane',
      lastName: 'Smith',
      street: '789 Pine Road',
      apartment: 'Suite 200',
      city: 'Los Angeles',
      state: 'CA',
      zipCode: '90210',
      country: 'United States',
      phone: '+1 (555) 987-6543',
      type: AddressType.billing,
    ),
  ];
}