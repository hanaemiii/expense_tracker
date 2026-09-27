import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/app_role.dart';

class RoleCubit extends Cubit<AppRole> {
  RoleCubit() : super(AppRole.user);

  void switchTo(AppRole role) => emit(role);

  void toggle() => emit(state == AppRole.user ? AppRole.admin : AppRole.user);
}
