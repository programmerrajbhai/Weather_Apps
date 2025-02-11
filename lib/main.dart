import 'package:flutter/material.dart';
import 'dart:convert';
import "package:http/http.dart" as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
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
  String city = "Dimla";
  String apiKey = "8c87d4a7268ea7dc116ff9c642c44561"; // OpenWeatherMap API Key
  String temperature = "";
  String weather = "Unknown";
  bool isLoading = false;

  Future<void> fetchWeather() async {
    setState(() {
      isLoading = true;
    });
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";
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
        title: const Text("Weather App"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "City: $city",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Temperature: $temperature",
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 10),
            SelectableText(
              "Weather: $weather",
              style: const TextStyle(fontSize: 20,),
            )
,
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchWeather,
              child: const Text("Refresh"),
            )
          ],
        ),
      ),
    );
  }
}
