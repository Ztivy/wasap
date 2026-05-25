import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wasap2/feature/contact/repository/contacts_repository.dart';

final  contactControllerProvider= FutureProvider((ref){
  final ContactsRepository=ref.watch(contactsRepositoryProvider);
  return ContactsRepository.getAllContacts();
});