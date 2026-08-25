part of 'asset_form_cubit.dart';

sealed class AssetFormState extends Equatable {
  const AssetFormState();

  @override
  List<Object?> get props => [];
}

class AssetFormInitial extends AssetFormState {
  const AssetFormInitial();
}

class AssetFormSaving extends AssetFormState {
  const AssetFormSaving();
}

class AssetFormSuccess extends AssetFormState {
  const AssetFormSuccess();
}

class AssetFormFailure extends AssetFormState {
  const AssetFormFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
