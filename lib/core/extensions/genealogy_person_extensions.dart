import '../../data/database/app_database.dart';

extension GenealogyPersonExtensions on GenealogyPerson {
  String get fullName {
    final parts = <String>[
      if ((prefix ?? '').trim().isNotEmpty) prefix!.trim(),
      if (firstName.trim().isNotEmpty) firstName.trim(),
      if ((middleName ?? '').trim().isNotEmpty) middleName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
      if ((suffix ?? '').trim().isNotEmpty) suffix!.trim(),
    ];
    return parts.join(' ').trim();
  }

  String? get bio => biography;
  bool get private => isPrivate;
}
