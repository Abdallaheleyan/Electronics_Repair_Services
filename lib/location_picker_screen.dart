import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  final Function(LatLng) onLocationPicked;

  const LocationPickerScreen({Key? key, required this.onLocationPicked})
      : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  LatLng _initialPosition = const LatLng(0, 0);
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(pos.latitude, pos.longitude);
      _loading = false;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
  }

  void _onMapTap(LatLng position) {
    setState(() => _pickedLocation = position);
  }

  Future<List<Map<String, dynamic>>> _searchPlaces(String input) async {
    if (input.isEmpty) return [];

    final String apiKey = 'AIzaSyAYJ5Yi2E5YyTrwHKdHKpVBFkoLWiM4BtE';
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      return List<Map<String, dynamic>>.from(data['predictions']);
    } else {
      return [];
    }
  }

  Future<void> _moveToPlace(String placeId) async {
    final String apiKey = 'AIzaSyAYJ5Yi2E5YyTrwHKdHKpVBFkoLWiM4BtE';
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'OK') {
      final location = data['result']['geometry']['location'];
      final latLng = LatLng(location['lat'], location['lng']);

      setState(() => _pickedLocation = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF39ef64),
        title: const Text('Pick Location'),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => widget.onLocationPicked(_pickedLocation!),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: TypeAheadField<Map<String, dynamic>>(
              controller: _searchController,
              suggestionsCallback: _searchPlaces,
              itemBuilder: (context, suggestion) {
                return ListTile(
                  leading: const Icon(Icons.location_on),
                  title: Text(suggestion['description']),
                );
              },
              onSelected: (suggestion) {
                _moveToPlace(suggestion['place_id']);
                _searchController.clear();
              },
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search location...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 16,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: _onMapTap,
              markers: _pickedLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId("picked"),
                        position: _pickedLocation!,
                      ),
                    }
                  : {},
            ),
    );
  }
}
