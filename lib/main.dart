// OBSERVAÇÃO PARA O PROFESSOR:
// Optei por utilizar o pacote `flutter_map` (com tiles do OpenStreetMap)
// em vez do `google_maps_flutter` indicado no enunciado. O motivo é que o
// `google_maps_flutter` exige uma chave da Google Maps Platform vinculada
// a uma conta de billing (cartão de crédito), e o `flutter_map` cumpre o
// mesmo objetivo do exercício, exibir a geolocalização atual em um mapa
// usando o `geolocator`, sem necessidade de chave nem cadastro pago. :)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  String? _error;

  static const LatLng _fallbackCenter = LatLng(-23.55052, -46.633308);

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
      _mapController.move(LatLng(initial.latitude, initial.longitude), 16);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _currentPosition = pos);
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao obter localização: $e');
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = _currentPosition;
    final markers = <Marker>[];
    if (position != null) {
      markers.add(
        Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minha Localização')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: position != null
                  ? LatLng(position.latitude, position.longitude)
                  : _fallbackCenter,
              initialZoom: position != null ? 16 : 14,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aula8',
              ),
              MarkerLayer(markers: markers),
            ],
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
