import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseStorageRepositoryProvider = Provider((ref) => 
  SupabaseStorageRepository(supabase: Supabase.instance.client)
);

class SupabaseStorageRepository {
  final SupabaseClient supabase;

  SupabaseStorageRepository({required this.supabase});

  Future<String> storeFileToSupabase(String ref, var file) async {
    if (file is File) {
      await supabase.storage.from('media').upload(ref, file,
      fileOptions: const FileOptions(upsert: true),
      );
    } else if (file is Uint8List) {
      await supabase.storage.from('media').uploadBinary(ref, file,
      fileOptions: const FileOptions(upsert: true),);
    }
    
    final imageUrl = supabase.storage.from('media').getPublicUrl(ref);
    return imageUrl;
  }
}