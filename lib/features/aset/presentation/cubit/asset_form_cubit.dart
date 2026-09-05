import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/result.dart';
import '../../domain/usecases/create_asset.dart';

part 'asset_form_state.dart';

@injectable
class AssetFormCubit extends Cubit<AssetFormState> {
  AssetFormCubit(this._createAsset) : super(const AssetFormInitial());

  final CreateAsset _createAsset;

  void reset() => emit(const AssetFormInitial());

  Future<void> save({
    String? assetId,
    required String name,
    String? description,
    required DateTime acquisitionDate,
    required double cost,
    required double salvageValue,
    required int usefulLifeYears,
  }) async {
    emit(const AssetFormSaving());
    final result = await _createAsset(
      CreateAssetParams(
        id: assetId,
        name: name,
        description: description,
        acquisitionDate: acquisitionDate,
        cost: cost,
        salvageValue: salvageValue,
        usefulLifeYears: usefulLifeYears,
      ),
    );
    switch (result) {
      case Ok():
        emit(const AssetFormSuccess());
      case Err(:final failure):
        emit(AssetFormFailure(failure.message));
    }
  }
}
