// ============================================================
//  BookingModel – MaaCare
// ============================================================

class BookingModel {
  final String id;
  final String userId;
  final String doctorId;
  final String patientName;
  final String symptoms;
  final DateTime appointmentDate;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final String paymentStatus;
  final String meetingLink;
  final String amount;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.patientName,
    required this.symptoms,
    required this.appointmentDate,
    required this.status,
    required this.paymentStatus,
    required this.meetingLink,
    required this.amount,
    required this.createdAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      patientName: map['patient_name'] ?? 'Patient',
      symptoms: map['symptoms'] ?? '',
      appointmentDate: map['appointment_date'] != null 
          ? DateTime.parse(map['appointment_date']) 
          : DateTime.now(),
      status: map['status'] ?? 'scheduled',
      paymentStatus: map['payment_status'] ?? 'pending',
      meetingLink: map['meeting_link'] ?? '',
      amount: map['amount'] ?? '₹0',
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'doctor_id': doctorId,
      'patient_name': patientName,
      'symptoms': symptoms,
      'appointment_date': appointmentDate.toIso8601String(),
      'status': status,
      'payment_status': paymentStatus,
      'meeting_link': meetingLink,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
