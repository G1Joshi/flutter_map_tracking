import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Map Tracking',
      debugShowCheckedModeBanner: false,
      home: TrackingPage(),
    );
  }
}

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => TrackingPageState();
}

class TrackingPageState extends State<TrackingPage> {
  Completer<GoogleMapController> googleMapController = Completer();
  late LatLng sourceLocation;
  late LatLng currentLocation;
  List<LatLng> routeCoordinates = [];

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Geolocator.getCurrentPosition().then((location) {
      currentLocation = LatLng(
        location.latitude,
        location.longitude,
      );
      sourceLocation = currentLocation;

      setState(() => routeCoordinates.add(currentLocation));
    });

    GoogleMapController mapController = await googleMapController.future;

    Geolocator.getPositionStream().listen((newLocation) {
      currentLocation = LatLng(
        newLocation.latitude,
        newLocation.longitude,
      );

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 15,
          ),
        ),
      );

      setState(() => routeCoordinates.add(currentLocation));
    });
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: routeCoordinates.isEmpty
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation,
                zoom: 15,
              ),
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: routeCoordinates,
                  color: Colors.indigo,
                  width: 5,
                ),
              },
              markers: {
                Marker(
                  markerId: const MarkerId('current'),
                  position: currentLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(100),
                ),
                Marker(
                  markerId: const MarkerId('source'),
                  position: sourceLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(200),
                ),
              },
              onMapCreated: ((controller) {
                googleMapController.complete(controller);
              }),
            ),
    );
  }
}
