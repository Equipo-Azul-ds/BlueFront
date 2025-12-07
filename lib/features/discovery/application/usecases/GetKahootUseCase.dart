import 'package:Trivvy/features/discovery/domain/Repositories/IDiscoverRepository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecase.dart';
import '../../../kahoot/domain/entities/kahoot.dart';


class GetKahootsParams extends Equatable {
  final String? query;
  final List<String> themes;

  final String orderBy;
  final String order;

  const GetKahootsParams({
    this.query,
    this.themes = const [],
    this.orderBy = 'createdAt',
    this.order = 'desc',
  });


  @override
  List<Object?> get props => [query, themes, orderBy, order];
}


class GetKahoots extends UseCase<List<Kahoot>, GetKahootsParams> {
  final IDiscoverRepository repository;

  GetKahoots(this.repository);

  @override
  Future<Either<Failure, List<Kahoot>>> call(GetKahootsParams params) async {
    return await repository.getKahoots(
      query: params.query,
      themes: params.themes,
      orderBy: params.orderBy,
      order: params.order,
    );
  }
}