import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import 'mock_data.dart';

/// Persistent address book. Public contact keys are stored with the contact;
/// the local private identity key is deliberately kept elsewhere in secure
/// storage.
enum ContactAddResult { added, alreadyKnown, keyMismatch }

class ContactsRepository extends ChangeNotifier {
  ContactsRepository._() : _contacts = List.of(MockData.contacts);

  static final ContactsRepository instance = ContactsRepository._();

  final List<Contact> _contacts;
  static const _storageKey = 'meshly_contacts_v2';
  bool _loaded = false;

  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Adds a contact. A re-scan is idempotent, but an unexpected public-key
  /// change is never silently accepted.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List;
        _contacts
          ..clear()
          ..addAll(decoded
              .whereType<Map>()
              .map((e) => Contact.tryFromJson(Map<String, dynamic>.from(e)))
              .whereType<Contact>());
      } catch (_) {/* corrupt address book is ignored, never crashes startup */}
    }
    _loaded = true;
    notifyListeners();
  }

  Future<ContactAddResult> add(Contact contact) async {
    final index = _contacts.indexWhere((c) => c.meshId == contact.meshId);
    if (index == -1) {
      _contacts.add(contact);
    } else {
      if (_contacts[index].publicKey != contact.publicKey) {
        return ContactAddResult.keyMismatch;
      }
      return ContactAddResult.alreadyKnown;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_contacts.map((c) => c.toJson()).toList()));
    notifyListeners();
    return ContactAddResult.added;
  }
}
