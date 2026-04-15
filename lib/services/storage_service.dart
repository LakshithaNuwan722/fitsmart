import 'dart:io';

class StorageService {

  Future<String> uploadMealImage(File imageFile) async {
    // Skip image upload for now
    // Storage not configured - return empty string
    print('Image upload skipped - Storage not configured');
    return '';
  }
}