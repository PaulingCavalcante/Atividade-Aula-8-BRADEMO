import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minha Localização',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();

  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  String? _error;

  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(-23.55052, -46.633308),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _error = 'Serviço de localização desativado.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _error = 'Permissão de localização negada.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _error = 'Permissão de localização negada permanentemente.',
        );
        return;
      }

      final initial = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _currentPosition = initial);
      await _animateTo(initial);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _currentPosition = pos);
        _animateTo(pos);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao obter localização: $e');
    }
  }

  Future<void> _animateTo(Position pos) async {
    final controller = await _mapController.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentPosition;
    final markers = <Marker>{};
    if (position != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('atual'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: const InfoWindow(title: 'Você está aqui'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Localização')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _fallbackCamera,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
          ),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              ),
            ),
          if (position != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Lat: ${position.latitude.toStringAsFixed(5)}  '
                    'Lon: ${position.longitude.toStringAsFixed(5)}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
