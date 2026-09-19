import 'package:flutter/foundation.dart';

import '../models/contact.dart';
import 'mock_data.dart';

/// In-memory, session-only store of contacts, seeded from [MockData.contacts].
///
/// Exists so a contact added via the real Scan QR flow shows up immediately
/// on the Chats and Contacts screens, without those screens needing to know
/// where a contact came from. Nothing here persists across app restarts yet
/// — that's a natural next step (shared_preferences/sqflite) once this is
/// proven out.
class ContactsRepository extends ChangeNotifier {
  ContactsRepository._() : _contacts = List.of(MockData.contacts);

  static final ContactsRepository instance = ContactsRepository._();

  final List<Contact> _contacts;

  List<Contact> get contacts => List.unmodifiable(_contacts);

  /// Adds a contact, or updates the existing one if a contact with the same
  /// meshId is already known (e.g. re-scanning the same person's QR code).
  void addOrUpdate(Contact contact) {
    final index = _contacts.indexWhere((c) => c.meshId == contact.meshId);
    if (index == -1) {
      _contacts.add(contact);
    } else {
      _contacts[index] = contact;
    }
    notifyListeners();
  }
}