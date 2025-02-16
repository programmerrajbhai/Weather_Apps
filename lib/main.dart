import 'package:flutter/material.dart';
import 'dart:convert';
import "package:http/http.dart" as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Weather App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  String apiKey = "8c87d4a7268ea7dc116ff9c642c44561"; // OpenWeatherMap API Key
  String temperature = "";
  String weather = "Unknown";
  String cityName = "Fetching...";
  bool isLoading = false;
  double? latitude;
  double? longitude;

  // লোকেশন পারমিশন চেক ও GPS থেকে লোকেশন বের করা
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Geocoding API দিয়ে **শহরের নাম বের করা**
  Future<void> getCityName(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        setState(() {
          cityName = placemarks[0].locality ?? "Unknown";
        });
      }
    } catch (e) {
      setState(() {
        cityName = "Location Error";
      });
    }
  }

  // Weather Fetch করার ফাংশন
  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true;
    });

    Position? position = await _getCurrentLocation();
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;

      // শহরের নাম বের করা
      await getCityName(latitude!, longitude!);

      final url =
          "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          temperature = "${data['main']['temp']}°C";
          weather = data['weather'][0]['description'];
          isLoading = false;
        });
      } else {
        setState(() {
          temperature = "Error fetching data";
          weather = "Unknown";
          isLoading = false;
        });
      }
    } else {
      setState(() {
        temperature = "Location Error";
        weather = "Unknown";
        cityName = "Unknown";
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Weather App"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cityName == "Unknown"
                  ? "City: Not Found"
                  : "📍 City: $cityName",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              latitude != null && longitude != null
                  ? "Lat: $latitude, Lon: $longitude"
                  : "Location not available",
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "🌡 Temperature: $temperature",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            Text(
              "🌤 Weather: $weather",
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchWeather,
              child: const Text("Refresh"),
            ),
          ],
        ),
      ),
    );
  }
}
