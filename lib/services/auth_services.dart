// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../pages/admin/admin_dash.dart';
import '../pages/home/home.dart';
import '../pages/login/login.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signup({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Tambahkan user ke Firestore dengan role "user"
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await Future.delayed(const Duration(seconds: 1));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Registration successful! Please log in to continue.'),
            backgroundColor: Color.fromARGB(255, 49, 111, 236),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '';
      if (e.code == 'weak-password') {
        message = 'Password is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account with this email is already registered.';
      }
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    }
  }

  Future<void> signin({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      print('=== AUTH DEBUG START ===');
      print('Login attempt for: $email');
      
      // Login semua user ke Firebase Auth (termasuk admin)
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      print('Firebase Auth successful for: ${userCredential.user?.email}');
      print('User UID: ${userCredential.user?.uid}');

      // Cek apakah admin dengan email admin639@gmail.com
      if (email == 'admin639@gmail.com') {
        print('ADMIN DETECTED - Email matches admin639@gmail.com');
        print('Context mounted: ${context.mounted}');
        print('Navigating to AdminDashboard...');
        
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
            (route) => false, // Clear semua routes
          );
        }
        
        print('Navigation executed - should be in AdminDashboard');
        print('=== AUTH DEBUG END ===');
        return;
      }

      print('Not admin - proceeding to check Firestore for user role');

      // User biasa - Ambil data user dari Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      print('Firestore document exists: ${userDoc.exists}');

      if (!userDoc.exists) {
        print('ERROR: User document not found in Firestore');
        Fluttertoast.showToast(
          msg: 'User data not found in database.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return;
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      print('User data from Firestore: $userData');
      print('User role: ${userData['role']}');

      // Cek role
      if (userData['role'] == 'user') {
        print('User role confirmed - navigating to Home');
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const Home()),
            (route) => false,
          );
        }
      } else {
        print('ERROR: User role is not "user" - Access denied');
        Fluttertoast.showToast(
          msg: 'Access denied. Invalid user role.',
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
      }

      print('=== AUTH DEBUG END ===');

    } on FirebaseAuthException catch (e) {
      print('ERROR: Firebase Auth Exception - ${e.code}: ${e.message}');
      String message = '';
      if (e.code == 'invalid-email') {
        message = 'User with this email is not registered.';
      } else if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        message = 'Wrong password provided for that user.';
      } else if (e.code == 'user-not-found') {
        message = 'No user found for that email.';
      } else {
        message = 'Login failed: ${e.message}';
      }

      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 14.0,
      );
    } catch (e) {
      print('ERROR: Unexpected error during signin - $e');
      Fluttertoast.showToast(
        msg: 'An unexpected error occurred.',
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> signout({required BuildContext context}) async {
    try {
      print('=== SIGNOUT DEBUG ===');
      print('Signing out user...');
      
      await _auth.signOut();
      await Future.delayed(const Duration(seconds: 1));
      
      print('Navigating to Login page...');
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (BuildContext context) => const Login()),
          (route) => false,
        );
      }
      
      print('=== SIGNOUT DEBUG END ===');
    } catch (e) {
      print('ERROR: Error during signout - $e');
      Fluttertoast.showToast(
        msg: 'Error signing out.',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // Method tambahan untuk cek current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Method untuk cek apakah user adalah admin
  bool isAdmin(String email) {
    return email == 'admin639@gmail.com';
  }

  // Method untuk auto login ketika app dibuka
  Future<Widget> checkAuthState() async {
    final User? user = _auth.currentUser;
    
    if (user == null) {
      return const Login();
    }
    
    // Jika admin, langsung ke AdminDashboard
    if (isAdmin(user.email ?? '')) {
      return const AdminDashboard();
    }
    
    // Jika user biasa, cek di Firestore
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (userData['role'] == 'user') {
          return const Home();
        }
      }
    } catch (e) {
      print('Error checking user role: $e');
    }
    
    // Jika gagal cek role atau tidak ada data, kembali ke login
    return const Login();
  }
}