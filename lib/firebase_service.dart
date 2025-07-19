import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'firebase_options.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _isInitialized = false;
  static const String _userId = 'swypshyt_user';
  static bool _hasLoggedStatus = false; // PREVENT SPAM LOGS

  // Initialize Firebase
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;

      // LOG ONLY ONCE
      if (!_hasLoggedStatus && kDebugMode) {
        print('🔥 Firebase initialized successfully');
        _hasLoggedStatus = true;
      }

      return await _testConnection();
    } catch (e) {
      if (kDebugMode) print('Firebase init error: $e');
      return false;
    }
  }

  // Test connection
  static Future<bool> _testConnection() async {
    try {
      await _firestore.collection('users').doc('_test').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> getFirebaseStatus() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return "Init Failed ❌";
        }
      }

      // Simple connection test
      await _firestore.collection('users').doc('_test').get();

      // LOG ONLY ONCE OR IN DEBUG
      if (!_hasLoggedStatus && kDebugMode) {
        print('🔥 Firebase connection successful');
        _hasLoggedStatus = true;
      }

      return "Online ✅";
    } catch (e) {
      if (kDebugMode) print('🔥 Firebase connection error: $e');
      if (e.toString().contains('cors')) {
        return "CORS Error ❌";
      } else if (e.toString().contains('permission')) {
        return "Permission ❌";
      } else if (e.toString().contains('network')) {
        return "Network ❌";
      } else {
        return "Error ❌";
      }
    }
  }

  // Force connection on app start - NO SPAM
  static Future<void> forceConnection() async {
    if (_hasLoggedStatus) return; // Already logged

    try {
      await initialize();
      await getFirebaseStatus();
      if (kDebugMode) print('🔥 Firebase ready');
    } catch (e) {
      if (kDebugMode) print('🔥 Firebase failed: $e');
    }
  }

  // Save finance data
  static Future<bool> saveFinanceData({
    required List<Map<String, dynamic>> expenses,
    required List<Map<String, dynamic>> income,
    required List<Map<String, dynamic>> paytrack,
  }) async {
    if (!_isInitialized && !await initialize()) return false;

    try {
      final userDoc = _firestore.collection('users').doc(_userId);
      await userDoc.set({
        'expenses': expenses,
        'income': income,
        'paytrack': paytrack,
        'lastUpdated': FieldValue.serverTimestamp(),
        'expenseCount': expenses.length,
        'incomeCount': income.length,
        'paytrackCount': paytrack.length,
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      if (kDebugMode) print('Save finance data error: $e');
      return false;
    }
  }

  // Load finance data
  static Future<Map<String, List<dynamic>>> loadFinanceData() async {
    if (!_isInitialized && !await initialize()) {
      return {'expenses': [], 'income': [], 'paytrack': []};
    }

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists) {
        return {'expenses': [], 'income': [], 'paytrack': []};
      }

      final data = userDoc.data()!;
      return {
        'expenses': data['expenses'] ?? [],
        'income': data['income'] ?? [],
        'paytrack': data['paytrack'] ?? [],
      };
    } catch (e) {
      if (kDebugMode) print('Load finance data error: $e');
      return {'expenses': [], 'income': [], 'paytrack': []};
    }
  }

  // Save profile data
  static Future<bool> saveProfile({
    required String userName,
    required String userNickname,
    required double dailyBudget,
    required Map<String, String> familyMembers,
  }) async {
    if (!_isInitialized && !await initialize()) return false;

    try {
      final userDoc = _firestore.collection('users').doc(_userId);
      await userDoc.set({
        'profile': {
          'userName': userName,
          'userNickname': userNickname,
          'dailyBudget': dailyBudget,
          'familyMembers': familyMembers,
          'lastUpdated': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      return true;
    } catch (e) {
      if (kDebugMode) print('Save profile error: $e');
      return false;
    }
  }

  // Load profile data
  static Future<Map<String, dynamic>> loadProfile() async {
    if (!_isInitialized && !await initialize()) {
      return {
        'userName': '',
        'userNickname': '',
        'dailyBudget': 1000.0,
        'familyMembers': <String, String>{},
      };
    }

    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();

      if (!userDoc.exists || userDoc.data()?['profile'] == null) {
        return {
          'userName': '',
          'userNickname': '',
          'dailyBudget': 1000.0,
          'familyMembers': <String, String>{},
        };
      }

      return userDoc.data()!['profile'] as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('Load profile error: $e');
      return {
        'userName': '',
        'userNickname': '',
        'dailyBudget': 1000.0,
        'familyMembers': <String, String>{},
      };
    }
  }
}
