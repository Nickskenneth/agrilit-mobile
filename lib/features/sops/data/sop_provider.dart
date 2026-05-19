import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/database_helper.dart';
import 'sop_model.dart';

class SopProvider extends ChangeNotifier {
  List<SopModel> _sops = [];
  SopModel? _selected;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  List<SopModel> get sops => _sops;
  SopModel? get selected => _selected;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  final _api = ApiClient();
  final _db = DatabaseHelper();

  Future<void> fetchSops({String? commodity}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    String url = ApiConstants.sops;
    if (commodity != null && commodity.isNotEmpty) {
      url += '?commodity=$commodity';
    }

    final response = await _api.get(url);

    if (response.success) {
      _isOffline = false;
      final data = response.data as Map<String, dynamic>;
      final rawList = data['data'] as List<dynamic>;
      _sops = rawList
          .map((e) => SopModel.fromJson(e as Map<String, dynamic>))
          .toList();
      await _db.upsertSops(_sops.map((s) => s.toLocalDb()).toList());
    } else if (response.isNetworkError) {
      _isOffline = true;
      final local = await _db.getSops(commodity: commodity);
      _sops = local.map((m) => SopModel.fromLocalDb(m)).toList();
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSopDetail(int id) async {
    _isLoading = true;
    _selected = null;
    notifyListeners();

    final response = await _api.get(ApiConstants.sop(id));

    if (response.success) {
      final data = response.data as Map<String, dynamic>;
      _selected = SopModel.fromJson(data['data'] as Map<String, dynamic>);
      await _db.upsertSops([_selected!.toLocalDb()]);
    } else if (response.isNetworkError) {
      final local = await _db.getSopById(id);
      if (local != null) {
        _selected = SopModel.fromLocalDb(local);
        _isOffline = true;
      } else {
        _error = 'SOP tidak tersedia secara offline.';
      }
    } else {
      _error = response.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
