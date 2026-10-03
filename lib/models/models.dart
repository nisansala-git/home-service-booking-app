/// Data models with Firestore serialization support

class ServiceProvider {
  final String id;
  final String name;
  final String category;
  final double rating;
  final int reviewCount;
  final int jobsCompleted;
  final int onTimePercentage;
  final int experienceYears;
  final double startingPrice;
  final double distanceKm;
  final bool isVerified;
  final bool isBackgroundChecked;
  final bool isInsured;
  final String imageUrl;
  final String about;
  final List<String> pastWorkImages;
  final List<Map<String, dynamic>> pricingTable;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.reviewCount,
    required this.jobsCompleted,
    required this.onTimePercentage,
    required this.experienceYears,
    required this.startingPrice,
    required this.distanceKm,
    this.isVerified = true,
    this.isBackgroundChecked = true,
    this.isInsured = true,
    required this.imageUrl,
    required this.about,
    required this.pastWorkImages,
    required this.pricingTable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'jobsCompleted': jobsCompleted,
      'onTimePercentage': onTimePercentage,
      'experienceYears': experienceYears,
      'startingPrice': startingPrice,
      'distanceKm': distanceKm,
      'isVerified': isVerified,
      'isBackgroundChecked': isBackgroundChecked,
      'isInsured': isInsured,
      'imageUrl': imageUrl,
      'about': about,
      'pastWorkImages': pastWorkImages,
      'pricingTable': pricingTable,
    };
  }

  factory ServiceProvider.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceProvider(
      id: docId,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      jobsCompleted: map['jobsCompleted'] ?? 0,
      onTimePercentage: map['onTimePercentage'] ?? 95,
      experienceYears: map['experienceYears'] ?? 1,
      startingPrice: (map['startingPrice'] ?? 1000).toDouble(),
      distanceKm: (map['distanceKm'] ?? 1.5).toDouble(),
      isVerified: map['isVerified'] ?? true,
      isBackgroundChecked: map['isBackgroundChecked'] ?? true,
      isInsured: map['isInsured'] ?? true,
      imageUrl: map['imageUrl'] ?? '',
      about: map['about'] ?? '',
      pastWorkImages: List<String>.from(map['pastWorkImages'] ?? []),
      pricingTable: List<Map<String, dynamic>>.from(map['pricingTable'] ?? []),
    );
  }
}

class Booking {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String providerId;
  final String providerName;
  final String serviceCategory;
  final String serviceItem;
  final DateTime bookingDate;
  final String timeSlot;
  final double totalPrice;
  final double depositAmount;
  final double remainingAmount;
  final String status; // 'confirmed', 'contract_signed', 'deposit_paid', 'in_progress', 'completed', 'cancelled'
  final String address;
  final String notes;
  final bool isContractSigned;
  final String? signature;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.providerId,
    required this.providerName,
    required this.serviceCategory,
    required this.serviceItem,
    required this.bookingDate,
    required this.timeSlot,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.status,
    required this.address,
    this.notes = '',
    this.isContractSigned = false,
    this.signature,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'providerId': providerId,
      'providerName': providerName,
      'serviceCategory': serviceCategory,
      'serviceItem': serviceItem,
      'bookingDate': bookingDate.toIso8601String(),
      'timeSlot': timeSlot,
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'remainingAmount': remainingAmount,
      'status': status,
      'address': address,
      'notes': notes,
      'isContractSigned': isContractSigned,
      'signature': signature,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map, String docId) {
    return Booking(
      id: docId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      serviceCategory: map['serviceCategory'] ?? '',
      serviceItem: map['serviceItem'] ?? '',
      bookingDate: DateTime.tryParse(map['bookingDate'] ?? '') ?? DateTime.now(),
      timeSlot: map['timeSlot'] ?? '',
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      depositAmount: (map['depositAmount'] ?? 0).toDouble(),
      remainingAmount: (map['remainingAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'confirmed',
      address: map['address'] ?? '',
      notes: map['notes'] ?? '',
      isContractSigned: map['isContractSigned'] ?? false,
      signature: map['signature'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Review {
  final String id;
  final String bookingId;
  final String providerId;
  final String customerName;
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.bookingId,
    required this.providerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookingId': bookingId,
      'providerId': providerId,
      'customerName': customerName,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      bookingId: map['bookingId'] ?? '',
      providerId: map['providerId'] ?? '',
      customerName: map['customerName'] ?? 'Anonymous',
      rating: (map['rating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class AppNotification {
  final String id;
  final String recipientId;
  final String title;
  final String message;
  final String type; // 'new_request', 'contract_signed', 'deposit_received', 'job_completed'
  final String bookingId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.recipientId,
    required this.title,
    required this.message,
    required this.type,
    required this.bookingId,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipientId': recipientId,
      'title': title,
      'message': message,
      'type': type,
      'bookingId': bookingId,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}
