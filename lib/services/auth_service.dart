import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> register(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      print('🚀 MEMULAI REGISTRASI: $email');

      // Step 1: Create user in Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('✅ USER FIREBASE BERHASIL DIBUAT: ${userCredential.user!.uid}');

      // Step 2: Create user data in Firestore
      UserModel user = UserModel(
        uid: userCredential.user!.uid,
        email: email,
        fullName: fullName,
        groups: [],
      );

      await _firestore.collection('users').doc(user.uid).set(user.toMap());

      print('✅ DATA USER BERHASIL DISIMPAN DI FIRESTORE: ${user.uid}');

      // Verify the data was saved
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      print('✅ VERIFIKASI DATA: ${doc.exists ? "EXISTS" : "NOT EXISTS"}');

      return user;
    } on FirebaseAuthException catch (e) {
      print('❌ FIREBASE AUTH ERROR: ${e.code}');
      print('❌ ERROR MESSAGE: ${e.message}');

      // Handle specific error codes
      switch (e.code) {
        case 'email-already-in-use':
          print('❌ EMAIL SUDAH DIGUNAKAN: $email');
          break;
        case 'invalid-email':
          print('❌ EMAIL TIDAK VALID: $email');
          break;
        case 'operation-not-allowed':
          print('❌ OPERASI TIDAK DIIZINKAN');
          break;
        case 'weak-password':
          print('❌ PASSWORD TERLALU LEMAH');
          break;
        default:
          print('❌ ERROR LAINNYA: ${e.code}');
      }
      return null;
    } catch (e) {
      print('❌ UNEXPECTED ERROR: $e');
      print('❌ ERROR TYPE: ${e.runtimeType}');
      return null;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    try {
      print('🚀 MEMULAI LOGIN: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ LOGIN BERHASIL: ${userCredential.user!.uid}');

      // Get user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        print('✅ DATA USER DITEMUKAN DI FIRESTORE');
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      } else {
        print('❌ DATA USER TIDAK DITEMUKAN DI FIRESTORE');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ LOGIN ERROR: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('❌ LOGIN UNEXPECTED ERROR: $e');
      return null;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    print('✅ LOGOUT BERHASIL');
  }

  // Stream that emits the latest UserModel whenever the Firestore user document changes.
  // This listens to auth state changes and, when a user is logged in, switches to the
  // user's document snapshots so updates (like added group IDs) propagate to UI.
  Stream<UserModel?> get userDataStream {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value(null);
      }

      // Listen to user's document snapshots and map to UserModel
      return _firestore.collection('users').doc(user.uid).snapshots().map((
        snap,
      ) {
        if (snap.exists && snap.data() != null) {
          return UserModel.fromMap(snap.data() as Map<String, dynamic>);
        }
        return null;
      });
    });
  }
}
