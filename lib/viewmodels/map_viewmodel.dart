import 'package:flutter/material.dart';
import 'package:prm_project/models/store_location.dart';

class MapViewModel extends ChangeNotifier {
  final List<StoreLocation> _stores = [
    StoreLocation(
      id: 'ST-01',
      name: 'Showroom Luxura FPT Đà Nẵng',
      address: 'Tòa nhà FPT Complex, Khu đô thị FPT City, Quận Ngũ Hành Sơn, Đà Nẵng',
      latitude: 15.9753,
      longitude: 108.2638,
      phone: '+84 236 7300 999',
      openingHours: '08:30 sáng - 06:00 tối',
    ),
    StoreLocation(
      id: 'ST-02',
      name: 'Showroom Luxura Bạch Đằng',
      address: 'Số 150 Đường Bạch Đằng, Quận Hải Châu, Đà Nẵng',
      latitude: 16.0682,
      longitude: 108.2245,
      phone: '+84 236 3888 777',
      openingHours: '09:00 sáng - 10:00 tối',
    ),
    StoreLocation(
      id: 'ST-03',
      name: 'Cửa hàng Luxura Võ Nguyên Giáp',
      address: 'Số 258 Đường Võ Nguyên Giáp, Quận Sơn Trà, Đà Nẵng',
      latitude: 16.0610,
      longitude: 108.2464,
      phone: '+84 236 3999 888',
      openingHours: '09:30 sáng - 10:00 tối',
    ),
    StoreLocation(
      id: 'ST-04',
      name: 'Cửa hàng Luxura Nguyễn Văn Linh',
      address: 'Số 320 Đường Nguyễn Văn Linh, Quận Thanh Khê, Đà Nẵng',
      latitude: 16.0592,
      longitude: 108.2096,
      phone: '+84 236 3777 666',
      openingHours: '09:00 sáng - 09:30 tối',
    ),
  ];

  StoreLocation? _selectedStore;

  List<StoreLocation> get stores => _stores;
  StoreLocation? get selectedStore => _selectedStore;

  MapViewModel() {
    _selectedStore = _stores.first; // Default to first store
  }

  void selectStore(StoreLocation store) {
    _selectedStore = store;
    notifyListeners();
  }
}
