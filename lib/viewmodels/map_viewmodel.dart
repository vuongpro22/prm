import 'package:flutter/material.dart';
import 'package:prm_project/models/store_location.dart';

class MapViewModel extends ChangeNotifier {
  final List<StoreLocation> _stores = [
    StoreLocation(
      id: 'ST-01',
      name: 'Luxura FPT Hoa Lac Showroom',
      address: 'Beta Building, FPT University Campus, Hoa Lac High-Tech Park, Hanoi',
      latitude: 21.0135,
      longitude: 105.5255,
      phone: '+84 24 7300 1866',
      openingHours: '08:30 AM - 06:00 PM',
    ),
    StoreLocation(
      id: 'ST-02',
      name: 'Luxura Hoan Kiem Flagship',
      address: '24 Trang Tien Street, Hoan Kiem District, Hanoi',
      latitude: 21.0255,
      longitude: 105.8542,
      phone: '+84 24 3936 9999',
      openingHours: '09:00 AM - 10:00 PM',
    ),
    StoreLocation(
      id: 'ST-03',
      name: 'Luxura Landmark 81 Store',
      address: 'L1-02, Landmark 81 Mall, Binh Thanh District, Ho Chi Minh City',
      latitude: 10.7950,
      longitude: 106.7218,
      phone: '+84 28 3821 1111',
      openingHours: '09:30 AM - 10:00 PM',
    ),
    StoreLocation(
      id: 'ST-04',
      name: 'Luxura Da Nang Dragon Store',
      address: '150 Bach Dang Street, Hai Chau District, Da Nang',
      latitude: 16.0612,
      longitude: 108.2268,
      phone: '+84 236 3888 777',
      openingHours: '09:00 AM - 09:30 PM',
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
