import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pendingPayment, paid, packing, shipped, delivered, cancelled }

OrderStatus orderStatusFrom(String s) => switch (s) {
      'paid' => OrderStatus.paid,
      'packing' => OrderStatus.packing,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pendingPayment,
    };

class OrderItem {
  final String bookId;
  final String format; // "paper" | "ebook"
  final int qty;
  final int unitPrice;
  final String titleSnapshot;

  const OrderItem({
    required this.bookId,
    required this.format,
    required this.qty,
    required this.unitPrice,
    required this.titleSnapshot,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        bookId: m['bookId'],
        format: m['format'],
        qty: (m['qty'] as num).toInt(),
        unitPrice: (m['unitPrice'] as num).toInt(),
        titleSnapshot: m['titleSnapshot'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'format': format,
        'qty': qty,
        'unitPrice': unitPrice,
        'titleSnapshot': titleSnapshot,
      };
}

class QpayInfo {
  final String? invoiceId;
  final String? qrText;
  final List<String> deeplinks;
  final DateTime? paidAt;

  const QpayInfo({this.invoiceId, this.qrText, this.deeplinks = const [], this.paidAt});

  factory QpayInfo.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const QpayInfo();
    return QpayInfo(
      invoiceId: m['invoiceId'],
      qrText: m['qrText'],
      deeplinks: List<String>.from(m['deeplinks'] ?? []),
      paidAt: (m['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BookOrder {
  final String id;
  final String uid;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final OrderStatus status;
  final Map<String, dynamic>? addressSnapshot;
  final QpayInfo qpay;
  final DateTime? createdAt;

  const BookOrder({
    required this.id,
    required this.uid,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.addressSnapshot,
    this.qpay = const QpayInfo(),
    this.createdAt,
  });

  bool get hasPhysical => items.any((i) => i.format == 'paper');

  factory BookOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return BookOrder(
      id: doc.id,
      uid: d['uid'],
      items: (d['items'] as List)
          .map((e) => OrderItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      subtotal: (d['subtotal'] as num).toInt(),
      deliveryFee: (d['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (d['total'] as num).toInt(),
      status: orderStatusFrom(d['status'] ?? 'pending_payment'),
      addressSnapshot: d['addressSnapshot'] as Map<String, dynamic>?,
      qpay: QpayInfo.fromMap(d['qpay'] as Map<String, dynamic>?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
