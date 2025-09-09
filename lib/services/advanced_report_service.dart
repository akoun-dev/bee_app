import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../models/agent_model.dart';
import '../models/user_model.dart';
import '../models/reservation_model.dart';
import '../models/review_model.dart';

// Service avancé pour la génération de rapports avec vraies données
class AdvancedReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Générer un rapport de performance des agents avec vraies données
  Future<Map<String, dynamic>> generateAgentPerformanceReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    // Récupérer tous les agents
    final agentsSnapshot = await _firestore.collection('agents').get();
    final agents = agentsSnapshot.docs
        .map((doc) => AgentModel.fromMap(doc.data(), doc.id))
        .toList();

    // Récupérer les réservations pour la période
    final reservationsSnapshot = await _firestore
        .collection('reservations')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final reservations = reservationsSnapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();

    // Récupérer les avis pour la période
    final reviewsSnapshot = await _firestore
        .collection('reviews')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final reviews = reviewsSnapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
        .toList();

    // Calculer les métriques par agent
    final agentMetrics = <String, Map<String, dynamic>>{};

    for (final agent in agents) {
      final agentReservations = reservations
          .where((r) => r.agentId == agent.id)
          .toList();

      final agentReviews = reviews
          .where((r) => r.agentId == agent.id)
          .toList();

      final completedReservations = agentReservations
          .where((r) => r.status == 'completed')
          .length;

      final cancelledReservations = agentReservations
          .where((r) => r.status == 'cancelled')
          .length;

      final totalRevenue = agentReservations
          .where((r) => r.status == 'completed')
          .fold<double>(0.0, (sum, r) => sum + (r.totalPrice ?? 0.0));

      final averageRating = agentReviews.isNotEmpty
          ? agentReviews.fold<double>(0.0, (sum, r) => sum + r.rating) / agentReviews.length
          : 0.0;

      agentMetrics[agent.id] = {
        'agent': agent,
        'totalReservations': agentReservations.length,
        'completedReservations': completedReservations,
        'cancelledReservations': cancelledReservations,
        'completionRate': agentReservations.isNotEmpty 
            ? (completedReservations / agentReservations.length * 100)
            : 0.0,
        'totalRevenue': totalRevenue,
        'averageRating': averageRating,
        'totalReviews': agentReviews.length,
      };
    }

    return {
      'period': {
        'startDate': startDate,
        'endDate': endDate,
      },
      'summary': {
        'totalAgents': agents.length,
        'activeAgents': agentMetrics.values
            .where((m) => m['totalReservations'] > 0)
            .length,
        'totalReservations': reservations.length,
        'totalRevenue': agentMetrics.values
            .fold<double>(0.0, (sum, m) => sum + m['totalRevenue']),
        'averageCompletionRate': agentMetrics.values.isNotEmpty
            ? agentMetrics.values
                .fold<double>(0.0, (sum, m) => sum + m['completionRate']) / agentMetrics.length
            : 0.0,
      },
      'agentMetrics': agentMetrics,
    };
  }

  // Générer un rapport financier avec vraies données
  Future<Map<String, dynamic>> generateFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    // Récupérer les réservations complétées
    final reservationsSnapshot = await _firestore
        .collection('reservations')
        .where('status', isEqualTo: 'completed')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final reservations = reservationsSnapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();

    // Calculer les revenus par jour
    final dailyRevenue = <String, double>{};
    final monthlyRevenue = <String, double>{};

    for (final reservation in reservations) {
      final date = reservation.createdAt;
      final dayKey = DateFormat('yyyy-MM-dd').format(date);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final revenue = reservation.totalPrice ?? 0.0;

      dailyRevenue[dayKey] = (dailyRevenue[dayKey] ?? 0.0) + revenue;
      monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0.0) + revenue;
    }

    // Calculer les commissions (exemple: 10% de commission)
    const commissionRate = 0.10;
    final totalRevenue = reservations.fold<double>(
        0.0, (sum, r) => sum + (r.totalPrice ?? 0.0));
    final totalCommission = totalRevenue * commissionRate;
    final netRevenue = totalRevenue - totalCommission;

    return {
      'period': {
        'startDate': startDate,
        'endDate': endDate,
      },
      'summary': {
        'totalReservations': reservations.length,
        'totalRevenue': totalRevenue,
        'totalCommission': totalCommission,
        'netRevenue': netRevenue,
        'averageOrderValue': reservations.isNotEmpty 
            ? totalRevenue / reservations.length 
            : 0.0,
      },
      'dailyRevenue': dailyRevenue,
      'monthlyRevenue': monthlyRevenue,
      'topAgentsByRevenue': await _getTopAgentsByRevenue(reservations),
    };
  }

  // Obtenir les meilleurs agents par revenus
  Future<List<Map<String, dynamic>>> _getTopAgentsByRevenue(
      List<ReservationModel> reservations) async {
    final agentRevenue = <String, double>{};

    for (final reservation in reservations) {
      final revenue = reservation.totalPrice ?? 0.0;
      agentRevenue[reservation.agentId] = 
          (agentRevenue[reservation.agentId] ?? 0.0) + revenue;
    }

    // Récupérer les informations des agents
    final topAgents = <Map<String, dynamic>>[];
    final sortedAgents = agentRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedAgents.take(10)) {
      final agentDoc = await _firestore.collection('agents').doc(entry.key).get();
      if (agentDoc.exists) {
        final agent = AgentModel.fromMap(agentDoc.data() as Map<String, dynamic>, agentDoc.id);
        topAgents.add({
          'agent': agent,
          'revenue': entry.value,
          'reservationCount': reservations
              .where((r) => r.agentId == entry.key)
              .length,
        });
      }
    }

    return topAgents;
  }

  // Générer un rapport d'activité utilisateur avec vraies données
  Future<Map<String, dynamic>> generateUserActivityReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    startDate ??= DateTime.now().subtract(const Duration(days: 30));
    endDate ??= DateTime.now();

    // Récupérer les utilisateurs
    final usersSnapshot = await _firestore.collection('users').get();
    final users = usersSnapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), doc.id))
        .toList();

    // Récupérer les réservations
    final reservationsSnapshot = await _firestore
        .collection('reservations')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    final reservations = reservationsSnapshot.docs
        .map((doc) => ReservationModel.fromMap(doc.data(), doc.id))
        .toList();

    // Calculer les métriques
    final newUsers = users
        .where((u) => u.createdAt.isAfter(startDate!) && u.createdAt.isBefore(endDate!))
        .length;

    final activeUsers = reservations
        .map((r) => r.userId)
        .toSet()
        .length;

    final userActivity = <String, Map<String, dynamic>>{};
    for (final user in users) {
      final userReservations = reservations
          .where((r) => r.userId == user.id)
          .toList();

      userActivity[user.id] = {
        'user': user,
        'reservationCount': userReservations.length,
        'totalSpent': userReservations.fold<double>(
            0.0, (sum, r) => sum + (r.totalPrice ?? 0.0)),
        'lastActivity': userReservations.isNotEmpty
            ? userReservations
                .map((r) => r.createdAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
            : user.createdAt,
      };
    }

    return {
      'period': {
        'startDate': startDate,
        'endDate': endDate,
      },
      'summary': {
        'totalUsers': users.length,
        'newUsers': newUsers,
        'activeUsers': activeUsers,
        'userRetentionRate': users.isNotEmpty ? (activeUsers / users.length * 100) : 0.0,
      },
      'userActivity': userActivity,
    };
  }

  // Générer des données pour le dashboard avec vraies métriques
  Future<Map<String, dynamic>> generateDashboardData() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);

    // Données du mois actuel
    final currentMonthData = await generateFinancialReport(
      startDate: startOfMonth,
      endDate: now,
    );

    // Données du mois précédent
    final lastMonthData = await generateFinancialReport(
      startDate: startOfLastMonth,
      endDate: endOfLastMonth,
    );

    // Calculer les pourcentages de croissance
    final currentRevenue = currentMonthData['summary']['totalRevenue'] as double;
    final lastRevenue = lastMonthData['summary']['totalRevenue'] as double;
    final revenueGrowth = lastRevenue > 0 
        ? ((currentRevenue - lastRevenue) / lastRevenue * 100)
        : 0.0;

    final currentReservations = currentMonthData['summary']['totalReservations'] as int;
    final lastReservations = lastMonthData['summary']['totalReservations'] as int;
    final reservationGrowth = lastReservations > 0 
        ? ((currentReservations - lastReservations) / lastReservations * 100)
        : 0.0;

    return {
      'currentMonth': currentMonthData,
      'lastMonth': lastMonthData,
      'growth': {
        'revenue': revenueGrowth,
        'reservations': reservationGrowth,
      },
      'generatedAt': now,
    };
  }

  // Exporter un rapport en PDF
  Future<File> exportToPDF(Map<String, dynamic> reportData, String reportType) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: pw.PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Rapport ${reportType.toUpperCase()}',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Période: ${DateFormat('dd/MM/yyyy').format(reportData['period']['startDate'])} - ${DateFormat('dd/MM/yyyy').format(reportData['period']['endDate'])}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Résumé:',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              ...reportData['summary'].entries.map<pw.Widget>((entry) =>
                pw.Text('${entry.key}: ${entry.value}')
              ).toList(),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/rapport_${reportType}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}
