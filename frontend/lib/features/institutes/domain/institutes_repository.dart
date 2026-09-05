import 'institute.dart';

abstract class InstitutesRepository {
  Future<List<Institute>> getInstitutes();

  Future<InstituteCreationResult> createInstitute({
    required String name,
    required String email,
    required String adminName,
    String? phone,
    String? address,
  });

  Future<Institute> updateStatus(String id, InstituteStatus status);
}
