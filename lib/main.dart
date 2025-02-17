import 'package:flutter/material.dart';
import 'dart:convert';
import "package:http/http.dart" as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// নোটিফিকেশন সেটআপ
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> showNotification(String title, String body) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
  AndroidNotificationDetails(
    'weather_channel_id',
    'Weather Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );

  const NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
      0, title, body, platformChannelSpecifics);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initializeNotifications();
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
  String lastWeather = "";
  bool isLoading = false;
  double? latitude;
  double? longitude;

  // ✅ GPS লোকেশন বের করা
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

  // ✅ শহরের নাম বের করা
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

  // ✅ বর্তমান আবহাওয়া আনতে
  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true;
    });

    Position? position = await _getCurrentLocation();
    if (position != null) {
      latitude = position.latitude;
      longitude = position.longitude;

      await getCityName(latitude!, longitude!);

      final currentWeatherUrl =
          "https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric";

      final currentResponse = await http.get(Uri.parse(currentWeatherUrl));

      if (currentResponse.statusCode == 200) {
        final data = json.decode(currentResponse.body);
        String newWeather = data['weather'][0]['description'];

        setState(() {
          temperature = "${data['main']['temp']}°C";
          weather = newWeather;
        });

        if (lastWeather != "" && lastWeather != newWeather) {
          await showNotification("আবহাওয়া পরিবর্তিত হয়েছে!", "নতুন আবহাওয়া: $newWeather");
        }

        lastWeather = newWeather;
      }
    }

    setState(() {
      isLoading = false;
    });
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
            Text("📍 City: $cityName", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("🌡 এখনকার তাপমাত্রা: $temperature", style: const TextStyle(fontSize: 22)),
            Text("🌤 এখনকার আবহাওয়া: $weather", style: const TextStyle(fontSize: 20)),
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
