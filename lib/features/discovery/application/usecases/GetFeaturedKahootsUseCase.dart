import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase.dart';
import '../../domain/entities/kahoot.dart';
import '../../domain/Repositories/IDiscoverRepository.dart';




class GetFeaturedKahootsParams extends Equatable {
  final int? limit;

  const GetFeaturedKahootsParams({
    this.limit = 10,
  });

  @override
  List<Object?> get props => [limit];
}

class GetFeaturedKahoots extends UseCase<List<Kahoot>, GetFeaturedKahootsParams> {
  final IDiscoverRepository repository;

  GetFeaturedKahoots(this.repository);

  @override
  Future<Either<Failure, List<Kahoot>>> call(GetFeaturedKahootsParams params) async {
    return await repository.getFeaturedKahoots(
      limit: params.limit,
    );
  }
}