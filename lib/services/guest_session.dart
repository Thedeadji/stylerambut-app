import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GuestSession {
  GuestSession._();

  static final GuestSession instance = GuestSession._();

  static const _guestKey = 'guest_mode_active';

  bool isGuest = false;
  final ValueNotifier<bool> isGuestNotifier = ValueNotifier(false);

  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    isGuest = prefs.getBool(_guestKey) ?? false;
    isGuestNotifier.value = isGuest;
    _loaded = true;
  }

  Future<void> enterGuestMode() async {
    isGuest = true;
    isGuestNotifier.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, true);
  }

  Future<void> exitGuestMode() async {
    isGuest = false;
    isGuestNotifier.value = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, false);
  }
}
