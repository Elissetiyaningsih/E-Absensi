import 'package:absenku/firebase_options.dart';
import 'package:absenku/pages/home/home.dart';
import 'package:absenku/pages/login/login.dart';
import 'package:absenku/pages/admin/admin_dash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('=== MAIN.DART AUTH WRAPPER DEBUG ===');
        
        // Masih loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Connection state: waiting');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // User belum login
        if (!snapshot.hasData || snapshot.data == null) {
          print('No user data - redirecting to Login');
          return const Login();
        }
        
        // User sudah login - cek role berdasarkan email
        final user = snapshot.data!;
        print('User logged in: ${user.email}');
        print('User UID: ${user.uid}');
        
        // Admin check dengan email admin639@gmail.com
        if (user.email == 'admin639@gmail.com') {
          print('ADMIN DETECTED in AuthWrapper - redirecting to AdminDashboard');
          return const AdminDashboard();
        }
        
        // User biasa - perlu cek role di Firestore
        print('Regular user detected - checking Firestore role');
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, firestoreSnapshot) {
            if (firestoreSnapshot.connectionState == ConnectionState.waiting) {
              print('Checking user role in Firestore...');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (firestoreSnapshot.hasError) {
              print('ERROR: Failed to fetch user data from Firestore');
              return const Login();
            }
            
            if (!firestoreSnapshot.hasData || !firestoreSnapshot.data!.exists) {
              print('WARNING: User document not found in Firestore - redirecting to Login');
              return const Login();
            }
            
            final userData = firestoreSnapshot.data!.data() as Map<String, dynamic>;
            print('User data from Firestore: $userData');
            
            // Cek role user
            if (userData['role'] == 'user') {
              print('User role confirmed - redirecting to Home');
              return const Home();
            } else {
              print('ERROR: Invalid user role - redirecting to Login');
              return const Login();
            }
          },
        );
      },
    );
  }
}