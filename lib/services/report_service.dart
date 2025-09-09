import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

// Service pour la génération de rapports
class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Logger logger = Logger();
  
  // Générer un rapport
  Future<String> generateReport({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String format,
  }) async {
    try {
      if (kDebugMode) {
        logger.i('Génération de rapport: $type, du ${DateFormat('dd/MM/yyyy').format(startDate)} au ${DateFormat('dd/MM/yyyy').format(endDate)}, format: $format');
      }
      
      // Simuler la génération d'un rapport
      await Future.delayed(const Duration(seconds: 2));
      
      // Dans une application réelle, cette méthode devrait:
      // 1. Récupérer les données nécessaires depuis Firestore
      // 2. Traiter ces données pour générer le rapport
      // 3. Créer un fichier au format demandé (PDF, CSV, Excel)
      // 4. Télécharger ce fichier sur Firebase Storage
      // 5. Retourner l'URL de téléchargement
      
      // Enregistrer l'historique du rapport généré
      await _saveReportHistory(type, startDate, endDate, format);
      
      // Retourner une URL fictive pour la démonstration
      return 'https://example.com/reports/report_${DateTime.now().millisecondsSinceEpoch}.$format';
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la génération du rapport: ${e.toString()}');
      }
      throw Exception('Erreur lors de la génération du rapport: ${e.toString()}');
    }
  }
  
  // Enregistrer l'historique des rapports générés
  Future<void> _saveReportHistory(
    String type,
    DateTime startDate,
    DateTime endDate,
    String format,
  ) async {
    try {
      await _firestore.collection('reports').add({
        'type': type,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'format': format,
        'generatedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
      });
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de l\'enregistrement de l\'historique: ${e.toString()}');
      }
    }
  }
  
  // Récupérer l'historique des rapports générés
  Future<List<Map<String, dynamic>>> getReportHistory() async {
    try {
      final snapshot = await _firestore.collection('reports')
          .orderBy('generatedAt', descending: true)
          .limit(10)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'type': data['type'],
          'startDate': (data['startDate'] as Timestamp).toDate(),
          'endDate': (data['endDate'] as Timestamp).toDate(),
          'format': data['format'],
          'generatedAt': data['generatedAt'] != null
              ? DateFormat('dd/MM/yyyy HH:mm').format((data['generatedAt'] as Timestamp).toDate())
              : 'Date inconnue',
          'status': data['status'],
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération de l\'historique: ${e.toString()}');
      }
      return [];
    }
  }
  
  // Récupérer les données pour le rapport de réservations
  Future<Map<String, dynamic>> getReservationsReportData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reservationsSnapshot = await _firestore.collection('reservations')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      // Traiter les données pour le rapport
      final Map<String, dynamic> reportData = {
        'totalReservations': reservationsSnapshot.docs.length,
        'byStatus': _countReservationsByStatus(reservationsSnapshot.docs),
        'byMonth': _groupReservationsByMonth(reservationsSnapshot.docs),
        'topLocations': _getTopLocations(reservationsSnapshot.docs),
      };
      
      return reportData;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération des données: ${e.toString()}');
      }
      throw Exception('Erreur lors de la récupération des données: ${e.toString()}');
    }
  }
  
  // Compter les réservations par statut
  Map<String, int> _countReservationsByStatus(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> counts = {
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'completed': 0,
      'cancelled': 0,
    };
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != null && counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }
    
    return counts;
  }
  
  // Grouper les réservations par mois
  Map<String, int> _groupReservationsByMonth(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> byMonth = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final startDate = (data['startDate'] as Timestamp).toDate();
      final monthKey = DateFormat('yyyy-MM').format(startDate);
      byMonth[monthKey] = (byMonth[monthKey] ?? 0) + 1;
    }
    
    return byMonth;
  }
  
  // Obtenir les lieux les plus populaires
  List<Map<String, dynamic>> _getTopLocations(List<QueryDocumentSnapshot> docs) {
    final Map<String, int> locationCounts = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as String?;
      if (location != null) {
        locationCounts[location] = (locationCounts[location] ?? 0) + 1;
      }
    }
    
    // Trier par nombre de réservations
    final sortedLocations = locationCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Prendre les 5 premiers
    return sortedLocations.take(5).map((entry) => {
      'location': entry.key,
      'count': entry.value,
    }).toList();
  }
  
  // Récupérer les données pour le rapport de performance des agents
  Future<Map<String, dynamic>> getAgentsPerformanceData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final agentsSnapshot = await _firestore.collection('agents').get();
      final reservationsSnapshot = await _firestore.collection('reservations')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();
      
      final Map<String, dynamic> reportData = {
        'totalAgents': agentsSnapshot.docs.length,
        'agentsPerformance': _calculateAgentsPerformance(agentsSnapshot.docs, reservationsSnapshot.docs),
      };
      
      return reportData;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération des données de performance: ${e.toString()}');
      }
      throw Exception('Erreur lors de la récupération des données de performance: ${e.toString()}');
    }
  }
  
  // Calculer la performance des agents
  List<Map<String, dynamic>> _calculateAgentsPerformance(
    List<QueryDocumentSnapshot> agentsDocs,
    List<QueryDocumentSnapshot> reservationsDocs,
  ) {
    final Map<String, Map<String, dynamic>> agentStats = {};
    
    // Initialiser les statistiques pour chaque agent
    for (final agentDoc in agentsDocs) {
      final agentData = agentDoc.data() as Map<String, dynamic>;
      agentStats[agentDoc.id] = {
        'id': agentDoc.id,
        'name': agentData['fullName'] ?? 'Inconnu',
        'totalReservations': 0,
        'completedReservations': 0,
        'cancelledReservations': 0,
        'averageRating': 0.0,
        'totalRevenue': 0.0,
      };
    }
    
    // Calculer les statistiques à partir des réservations
    for (final reservationDoc in reservationsDocs) {
      final reservationData = reservationDoc.data() as Map<String, dynamic>;
      final agentId = reservationData['agentId'] as String?;
      
      if (agentId != null && agentStats.containsKey(agentId)) {
        final stats = agentStats[agentId]!;
        stats['totalReservations'] = (stats['totalReservations'] as int) + 1;
        
        final status = reservationData['status'] as String?;
        if (status == 'completed') {
          stats['completedReservations'] = (stats['completedReservations'] as int) + 1;
        } else if (status == 'cancelled') {
          stats['cancelledReservations'] = (stats['cancelledReservations'] as int) + 1;
        }
        
        final rating = reservationData['rating'] as double?;
        if (rating != null) {
          final currentRating = stats['averageRating'] as double;
          final currentCount = stats['completedReservations'] as int;
          stats['averageRating'] = ((currentRating * currentCount) + rating) / (currentCount + 1);
        }
        
        final price = reservationData['price'] as double?;
        if (price != null) {
          stats['totalRevenue'] = (stats['totalRevenue'] as double) + price;
        }
      }
    }
    
    // Convertir en liste et trier par nombre de réservations
    final performanceList = agentStats.values.toList();
    performanceList.sort((a, b) => 
      (b['totalReservations'] as int).compareTo(a['totalReservations'] as int)
    );
    
    return performanceList;
  }
  
  // Récupérer les données pour le rapport de satisfaction client
  Future<Map<String, dynamic>> getCustomerSatisfactionData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reservationsSnapshot = await _firestore.collection('reservations')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('rating', isNotEqualTo: null)
          .get();
      
      final List<double> ratings = [];
      final Map<int, int> ratingDistribution = {};
      
      for (final doc in reservationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final rating = data['rating'] as double?;
        if (rating != null) {
          ratings.add(rating);
          final ratingInt = rating.round();
          ratingDistribution[ratingInt] = (ratingDistribution[ratingInt] ?? 0) + 1;
        }
      }
      
      final averageRating = ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0.0;
      
      final Map<String, dynamic> reportData = {
        'totalRatings': ratings.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
      
      return reportData;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération des données de satisfaction: ${e.toString()}');
      }
      throw Exception('Erreur lors de la récupération des données de satisfaction: ${e.toString()}');
    }
  }
  
  // Récupérer les données pour le rapport de revenus
  Future<Map<String, dynamic>> getRevenueData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final reservationsSnapshot = await _firestore.collection('reservations')
          .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('status', isEqualTo: 'completed')
          .get();
      
      double totalRevenue = 0.0;
      final Map<String, double> revenueByMonth = {};
      final Map<String, double> revenueByAgent = {};
      
      for (final doc in reservationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final price = data['price'] as double?;
        final startDate = (data['startDate'] as Timestamp).toDate();
        final agentId = data['agentId'] as String?;
        
        if (price != null) {
          totalRevenue += price;
          
          // Par mois
          final monthKey = DateFormat('yyyy-MM').format(startDate);
          revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0.0) + price;
          
          // Par agent
          if (agentId != null) {
            revenueByAgent[agentId] = (revenueByAgent[agentId] ?? 0.0) + price;
          }
        }
      }
      
      final Map<String, dynamic> reportData = {
        'totalRevenue': totalRevenue,
        'revenueByMonth': revenueByMonth,
        'revenueByAgent': revenueByAgent,
      };
      
      return reportData;
    } catch (e) {
      if (kDebugMode) {
        logger.e('Erreur lors de la récupération des données de revenus: ${e.toString()}');
      }
      throw Exception('Erreur lors de la récupération des données de revenus: ${e.toString()}');
    }
  }
}
