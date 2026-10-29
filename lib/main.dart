
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Weather',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF536DFE),
        ),
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController cityController =
      TextEditingController();

  double? temperature;
  double? feelsLike;
  double? windSpeed;
  double? pressure;
  int? humidity;

  String cityName = '';
  String country = '';
  String description = '';
  String errorMessage = '';
  String weatherMain = '';

  bool isLoading = false;
  List<Map<String, dynamic>> forecast = [];

  Future<void> getWeather() async {
    final city = cityController.text.trim();

    if (city.isEmpty) {
      setState(() {
        errorMessage = 'Please enter a city name.';
      });
      return;
    }

    if (apiKey.isEmpty) {
      setState(() {
        errorMessage =
            'API key is missing. Run the app with the API key configured.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      forecast = [];
    });

    try {
      final url = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/weather',
        {
          'q': city,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          cityName = data['name'] ?? city;
          country = data['sys']['country'] ?? '';

          temperature =
              (data['main']['temp'] as num).toDouble();

          feelsLike =
              (data['main']['feels_like'] as num).toDouble();

          humidity = (data['main']['humidity'] as num).toInt();

          pressure =
              (data['main']['pressure'] as num).toDouble();

          windSpeed =
              (data['wind']['speed'] as num).toDouble();

          description =
              data['weather'][0]['description'] ?? '';

          weatherMain = data['weather'][0]['main'] ?? '';
        });

        await getForecast(city);
      } else {
        setState(() {
          errorMessage = data['message'] == 'city not found'
              ? 'City not found. Check the spelling and try again.'
              : 'Unable to get weather. Please try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Connection failed. Check your internet and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> getForecast(String city) async {
    try {
      final url = Uri.https(
        'api.openweathermap.org',
        '/data/2.5/forecast',
        {
          'q': city,
          'appid': apiKey,
          'units': 'metric',
        },
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      if (!mounted || response.statusCode != 200) return;

      final List<dynamic> items = data['list'];
      final Map<String, Map<String, dynamic>> daily = {};

      for (final item in items) {
        final date = item['dt_txt'].substring(0, 10);

        if (!daily.containsKey(date)) {
          daily[date] = Map<String, dynamic>.from(item);
        }

        // Prefer the forecast around noon for each day.
        if (item['dt_txt'].contains('12:00:00')) {
          daily[date] = Map<String, dynamic>.from(item);
        }
      }

      setState(() {
        forecast = daily.values.take(5).toList();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        forecast = [];
      });
    }
  }

  IconData get weatherIcon {
    final condition = weatherMain.toLowerCase();

    if (condition.contains('cloud')) return Icons.cloud;

    if (condition.contains('rain') ||
        condition.contains('drizzle')) {
      return Icons.water_drop;
    }

    if (condition.contains('thunder')) {
      return Icons.thunderstorm;
    }

    if (condition.contains('snow')) return Icons.ac_unit;

    if (condition.contains('mist') ||
        condition.contains('fog') ||
        condition.contains('haze')) {
      return Icons.cloud_queue;
    }

    return Icons.wb_sunny_rounded;
  }

  IconData forecastIcon(String condition) {
    final weather = condition.toLowerCase();

    if (weather.contains('thunder')) {
      return Icons.thunderstorm;
    }

    if (weather.contains('rain') ||
        weather.contains('drizzle')) {
      return Icons.water_drop;
    }

    if (weather.contains('snow')) return Icons.ac_unit;

    if (weather.contains('cloud')) return Icons.cloud;

    if (weather.contains('mist') ||
        weather.contains('fog') ||
        weather.contains('haze')) {
      return Icons.cloud_queue;
    }

    return Icons.wb_sunny_rounded;
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF101B46),
              Color(0xFF263C83),
              Color(0xFF536DFE),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.cloud_outlined,
                          color: Colors.white,
                          size: 34,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'My Weather',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.wb_twilight_rounded,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your weather, at a glance.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // City search
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF536DFE),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: cityController,
                              textInputAction:
                                  TextInputAction.search,
                              onSubmitted: (_) => getWeather(),
                              decoration: const InputDecoration(
                                hintText: 'Search a city...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton.filled(
                            onPressed:
                                isLoading ? null : getWeather,
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF536DFE),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.search),
                          ),
                        ],
                      ),
                    ),

                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],

                    if (isLoading) ...[
                      const SizedBox(height: 40),
                      const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ],

                    if (!isLoading && temperature == null) ...[
                      const SizedBox(height: 42),
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_queue_rounded,
                              size: 95,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 18),
                            Text(
                              'Discover the weather',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Enter a city above to see live conditions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (temperature != null) ...[
                      const SizedBox(height: 30),

                      Text(
                        '$cityName${country.isNotEmpty ? ', $country' : ''}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      const Text(
                        'CURRENT WEATHER',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          letterSpacing: 2,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Main weather card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.13,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              weatherIcon,
                              size: 85,
                              color: const Color(0xFFFFD166),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${temperature!.round()}°',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 76,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              description.isNotEmpty
                                  ? '${description[0].toUpperCase()}${description.substring(1)}'
                                  : weatherMain,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Feels like ${feelsLike!.round()}°C',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'WEATHER DETAILS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 14),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.55,
                        children: [
                          WeatherDetailCard(
                            icon: Icons.water_drop_outlined,
                            label: 'Humidity',
                            value: '$humidity%',
                          ),
                          WeatherDetailCard(
                            icon: Icons.air_rounded,
                            label: 'Wind Speed',
                            value:
                                '${windSpeed!.toStringAsFixed(1)} m/s',
                          ),
                          WeatherDetailCard(
                            icon: Icons.thermostat_rounded,
                            label: 'Feels Like',
                            value: '${feelsLike!.round()}°C',
                          ),
                          WeatherDetailCard(
                            icon: Icons.speed_rounded,
                            label: 'Pressure',
                            value: '${pressure!.round()} hPa',
                          ),
                        ],
                      ),

                      // Five-day forecast
                      const SizedBox(height: 28),

                      const Text(
                        '5-DAY FORECAST',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (forecast.isEmpty)
                        const Text(
                          'Forecast is currently unavailable.',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: forecast.map((item) {
                              final date =
                                  DateTime.parse(item['dt_txt']);

                              final weather = item['weather'][0];

                              final temp =
                                  (item['main']['temp'] as num)
                                      .round();

                              const days = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];

                              final day = days[date.weekday - 1];

                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(
                                  right: 10,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(
                                    alpha: 0.13,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      day,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Icon(
                                      forecastIcon(
                                        weather['main'].toString(),
                                      ),
                                      color: const Color(0xFFFFD166),
                                      size: 30,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '$temp°C',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      weather['main'].toString(),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],

                    const SizedBox(height: 28),

                    const Center(
                      child: Text(
                        'Weather data powered by OpenWeather',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WeatherDetailCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const WeatherDetailCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFFD166),
            size: 25,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
