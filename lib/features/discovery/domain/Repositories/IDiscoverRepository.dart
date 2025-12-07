import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../kahoot/domain/entities/kahoot.dart';



abstract class IDiscoverRepository {

  Future<Either<Failure, List<Kahoot>>> getKahoots({
  required String? query,
  required List<String> themes,
  required String orderBy,
  required String order,
  });

  Future<Either<Failure, List<Kahoot>>> getFeaturedKahoots({
  int? limit,
  });
}


