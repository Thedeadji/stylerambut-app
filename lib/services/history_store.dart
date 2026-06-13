import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';
import 'detection_image_store.dart';
import 'guest_session.dart';

class HistoryStore {
  HistoryStore._() {
    _initAuthListener();
  }

  static final HistoryStore instance = HistoryStore._();

  static const _guestHistoryKey = 'guest_history_entries';

  final ValueNotifier<List<HistoryEntry>> entries = ValueNotifier(const []);
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  StreamSubscription<User?>? _authSubscription;

  void _initAuthListener() {
    GuestSession.instance.isGuestNotifier.addListener(_onSessionChanged);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((_) {
      _onSessionChanged();
    });
    GuestSession.instance.load().then((_) => _onSessionChanged());
  }

  void _onSessionChanged() {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = GuestSession.instance.isGuest;

    if (isGuest) {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;
      _loadGuestHistory();
    } else if (user != null) {
      _listenToUserHistory(user.uid);
    } else {
      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;
      entries.value = const [];
    }
  }

  void _listenToUserHistory(String uid) {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          final loadedEntries = snapshot.docs.map((doc) {
            return HistoryEntry.fromMap(doc.data());
          }).toList();
          entries.value = loadedEntries;
        }, onError: (error) {
          debugPrint('Error listening to user history: $error');
        });
  }

  Future<void> _loadGuestHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_guestHistoryKey);
    if (raw == null || raw.isEmpty) {
      entries.value = const [];
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final loadedEntries = list
          .map(
            (item) => HistoryEntry.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      entries.value = loadedEntries;
    } catch (error) {
      debugPrint('Failed to load guest history: $error');
      entries.value = const [];
    }
  }

  Future<void> _saveGuestHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = entries.value.map((entry) => entry.toMap()).toList();
    await prefs.setString(_guestHistoryKey, jsonEncode(jsonList));
  }

  Future<HistoryEntry> _withPersistedImage(HistoryEntry entry) async {
    final persistedPath = await DetectionImageStore.instance.persist(
      entry.result.imagePath,
    );
    if (persistedPath == entry.result.imagePath) {
      return entry;
    }

    return HistoryEntry(
      id: entry.id,
      result: entry.result.copyWith(imagePath: persistedPath),
      style: entry.style,
      timestamp: entry.timestamp,
      resultLabel: entry.resultLabel,
    );
  }

  Future<HistoryEntry?> add(HistoryEntry entry) async {
    final persistedEntry = await _withPersistedImage(entry);

    if (GuestSession.instance.isGuest) {
      final entryWithId = HistoryEntry(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        result: persistedEntry.result,
        style: persistedEntry.style,
        timestamp: persistedEntry.timestamp,
        resultLabel: persistedEntry.resultLabel,
      );
      entries.value = [entryWithId, ...entries.value];
      await _saveGuestHistory();
      return entryWithId;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc();

    final entryWithId = HistoryEntry(
      id: docRef.id,
      result: persistedEntry.result,
      style: persistedEntry.style,
      timestamp: persistedEntry.timestamp,
      resultLabel: persistedEntry.resultLabel,
    );

    await docRef.set(entryWithId.toMap());
    return entryWithId;
  }

  Future<void> remove(HistoryEntry entry) async {
    await DetectionImageStore.instance.deleteIfPersisted(entry.result.imagePath);

    if (GuestSession.instance.isGuest) {
      entries.value =
          entries.value.where((item) => item.id != entry.id).toList();
      await _saveGuestHistory();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || entry.id.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc(entry.id)
        .delete();
  }

  Future<void> update(HistoryEntry entry, HistoryEntry updatedEntry) async {
    final persistedEntry = await _withPersistedImage(updatedEntry);

    if (GuestSession.instance.isGuest) {
      final entryWithId = HistoryEntry(
        id: entry.id,
        result: persistedEntry.result,
        style: persistedEntry.style,
        timestamp: persistedEntry.timestamp,
        resultLabel: persistedEntry.resultLabel,
      );
      entries.value = entries.value
          .map((item) => item.id == entry.id ? entryWithId : item)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      await _saveGuestHistory();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || entry.id.isEmpty) return;

    final entryWithId = HistoryEntry(
      id: entry.id,
      result: persistedEntry.result,
      style: persistedEntry.style,
      timestamp: persistedEntry.timestamp,
      resultLabel: persistedEntry.resultLabel,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .doc(entry.id)
        .set(entryWithId.toMap());
  }

  void dispose() {
    GuestSession.instance.isGuestNotifier.removeListener(_onSessionChanged);
    _firestoreSubscription?.cancel();
    _authSubscription?.cancel();
  }
}
