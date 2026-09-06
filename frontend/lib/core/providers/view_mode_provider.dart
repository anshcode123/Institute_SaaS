import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../../shared/widgets/grid_list_toggle.dart';

const _viewModeKey = 'record_view_mode';

final StateNotifierProvider<ViewModeController, RecordViewMode> viewModeProvider =
    StateNotifierProvider<ViewModeController, RecordViewMode>((ref) {
  return ViewModeController(SecureStorage.instance);
});

class ViewModeController extends StateNotifier<RecordViewMode> {
  ViewModeController(this._storage) : super(RecordViewMode.list) {
    _loadSavedMode();
  }

  final SecureStorage _storage;
  bool _hasUserSelected = false;

  Future<void> setViewMode(RecordViewMode mode) async {
    _hasUserSelected = true;
    state = mode;
    await _storage.write(_viewModeKey, mode.name);
  }

  Future<void> _loadSavedMode() async {
    final saved = await _storage.read(_viewModeKey);
    if (_hasUserSelected) return;

    state = switch (saved) {
      'grid' => RecordViewMode.grid,
      'list' => RecordViewMode.list,
      _ => RecordViewMode.list,
    };
  }
}
