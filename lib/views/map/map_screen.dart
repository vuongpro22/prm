import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:prm_project/viewmodels/map_viewmodel.dart';
import 'package:prm_project/views/theme/theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  void _moveToStore(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final mapVm = Provider.of<MapViewModel>(context);
    final selectedStore = mapVm.selectedStore;

    return Scaffold(
      appBar: AppBar(
        title: const Text('C Ủ A  H À N G'),
      ),
      body: Stack(
        children: [
          // Flutter Map widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedStore != null
                  ? LatLng(selectedStore.latitude, selectedStore.longitude)
                  : const LatLng(21.0255, 105.8542),
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.prm_project',
              ),
              MarkerLayer(
                markers: mapVm.stores.map((store) {
                  final isSelected = selectedStore?.id == store.id;
                  return Marker(
                    point: LatLng(store.latitude, store.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () {
                        mapVm.selectStore(store);
                        _moveToStore(store.latitude, store.longitude);
                      },
                      child: Icon(
                        Icons.location_on,
                        color: isSelected ? AppTheme.primaryNeon : AppTheme.accentRose,
                        size: isSelected ? 44.0 : 34.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Bottom Floating Cards for Store selection
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 155,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: mapVm.stores.length,
                itemBuilder: (context, index) {
                  final store = mapVm.stores[index];
                  final isSelected = selectedStore?.id == store.id;

                  return GestureDetector(
                    onTap: () {
                      mapVm.selectStore(store);
                      _moveToStore(store.latitude, store.longitude);
                    },
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryNeon : Colors.white10,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black38,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              store.address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined, size: 12, color: AppTheme.secondaryTeal),
                                const SizedBox(width: 4),
                                Text(
                                  store.phone,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 12, color: AppTheme.secondaryTeal),
                                const SizedBox(width: 4),
                                Text(
                                  store.openingHours,
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
