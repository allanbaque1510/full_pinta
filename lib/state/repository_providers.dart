import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/catalog_repository.dart';
import '../data/repositories/directory_repository.dart';
import '../data/repositories/identity_repository.dart';
import '../data/repositories/reviews_repository.dart';
import '../data/repositories/scheduling_repository.dart';
import '../data/repositories/staffing_repository.dart';

final identityRepositoryProvider = Provider<IdentityRepository>((ref) => IdentityRepository());
final directoryRepositoryProvider = Provider<DirectoryRepository>((ref) => DirectoryRepository());
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository());
final staffingRepositoryProvider = Provider<StaffingRepository>((ref) => StaffingRepository());
final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) => SchedulingRepository());
final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) => ReviewsRepository());
