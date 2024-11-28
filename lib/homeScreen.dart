import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static const LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 10,
  );

  static const apiKey = '269ebeab186884c9c33a027fdfa761c7';


  double? latitude;
  double? longitude;
  String cityName = '';
  double temperature = 0.0;
  String main = '';
  double temp_min = 0.0;
  double temp_max = 0.0;
  double humidity = 0.0;
  String windSpeed = '';
  String sunriseTime = '';
  String sunsetTime = '';
  int timeZone = 0;

  late DateTime sunriseDateTime;
  late DateTime sunsetDateTime;
  bool isDaytime = false;

  @override
  void initState() {
    super.initState();
    getLocationAndFetchWeather();
  }

  Future<void> getLocationAndFetchWeather() async {
    await getLocation();
    if (latitude != null && longitude != null) {
      await getData(latitude!, longitude!);
    }
  }

  Future<void> getLocation() async {
    PermissionStatus permission = await Permission.location.request();

    if (permission == PermissionStatus.granted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings: locationSettings);

        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        print("User's location: $latitude, $longitude");
      } catch (e) {
        print("Error fetching the location: $e");
      }
    } else if (permission == PermissionStatus.denied) {
      print("Location permission denied");
    } else if (permission == PermissionStatus.permanentlyDenied) {
      print('Location permission permanently denied');
      openAppSettings();
    }
  }

  Future<void> getData(double lat, double lon) async {
    // Reverse geocoding to fetch city name
    final reverseGeoResponse = await http.get(Uri.parse(
        'http://api.openweathermap.org/geo/1.0/reverse?lat=$lat&lon=$lon&appid=$apiKey'));

    if (reverseGeoResponse.statusCode == 200) {
      var reverseGeoData = json.decode(reverseGeoResponse.body);
      if (reverseGeoData.isNotEmpty) {
        setState(() {
          cityName = reverseGeoData[0]['name'];
        });
      }
    } else {
      print('Reverse geocoding failed: ${reverseGeoResponse.body}');
    }

    // Weather data
    final weatherResponse = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'));

    try {
      if (weatherResponse.statusCode == 200) {
        var weatherData = json.decode(weatherResponse.body);
        print('Weather API response: ${weatherResponse.body}');

        setState(() {
          temperature = (weatherData['main']['temp'] as num).toDouble();
          temp_max = (weatherData['main']['temp_max'] as num).toDouble();
          temp_min = (weatherData['main']['temp_min'] as num).toDouble();
          humidity = (weatherData['main']['humidity'] as num).toDouble();
          main = weatherData['weather'][0]['main'];
          timeZone = weatherData['timezone'];
          windSpeed = "${(weatherData['wind']['speed'] as num).toDouble()} km/h";

          // Get the timezone offset (in seconds) from the API response
          int timezoneOffset = weatherData['timezone'] as int;

          // Convert sunrise and sunset times using the timezone offset
          sunriseTime = DateFormat.jm().format(
              DateTime.fromMillisecondsSinceEpoch(
                  (weatherData['sys']['sunrise'] as int) * 1000));
          sunsetTime = DateFormat.jm().format(
              DateTime.fromMillisecondsSinceEpoch(
                  (weatherData['sys']['sunset'] as int) * 1000));

          // Convert sunrise and sunset times to DateTime objects
          sunriseDateTime = DateTime.fromMillisecondsSinceEpoch(
              (weatherData['sys']['sunrise'] as int) * 1000);
          sunsetDateTime = DateTime.fromMillisecondsSinceEpoch(
              (weatherData['sys']['sunset'] as int) * 1000);

          // Check if current time is day or night
          DateTime currentTime = DateTime.now().toUtc().add(Duration(seconds: timezoneOffset));
          if (currentTime.isAfter(sunriseDateTime) && currentTime.isBefore(sunsetDateTime)) {
            isDaytime = true;
          } else {
            isDaytime = false;
          }
        });

      } else {
        print('Failed to load weather data: ${weatherResponse.body}');
      }
    } catch (e) {
      print('Error occurred while fetching weather data: $e');
    }
  }

  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "WEATHER - TODAY",
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: height * 0.02),
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.yellow[700]!.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(8),
            ),
          ),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.4),
          toolbarHeight: height * 0.05,
          actions: [
            IconButton(
                onPressed: () {
                  getLocationAndFetchWeather();
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.black,
                  size: width * 0.06,
                )),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                  isDaytime
                      ? "https://images.unsplash.com/photo-1533113354171-490d836238e3?q=80&w=1935&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
                      : ""
              ),
              fit: BoxFit
                  .cover,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: width * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: height * 0.05,
                ),
                Row(
                  children: [
                    Text(
                      "$cityName",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.09,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: height * 0.02,
                ),
                Row(
                  children: [
                    Text(
                      "$temperature°",
                      style:
                          TextStyle(color: Colors.white, fontSize: width * 0.13),
                    ),
                    SizedBox(
                      width: width * 0.04,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$temp_max°/$temp_min°",
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: width * 0.04),
                        ),
                        Text(
                          "$main",
                          style: TextStyle(
                              color: Colors.white, fontSize: width * 0.06),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Container(),
                    ),
                    Image(
                      image: NetworkImage(
                          isDaytime
                              ? "https://cdn4.iconfinder.com/data/icons/weatherful/72/Sunny-64.png" // Sun icon
                              : "https://cdn2.iconfinder.com/data/icons/weather-and-forecast-free/32/Weather_Weather_Forecast_Moon_Night_Sky-64.png" // Moon icon
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: height * 0.03,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: width * 0.43,
                      width: width * 0.43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xff181818)!.withOpacity(0.7),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                              image: NetworkImage(
                                  "https://cdn0.iconfinder.com/data/icons/navigation-colored/80/travel-time-local-256.png"),width: 60,),
                          SizedBox(
                            height: width * 0.02,
                          ),
                          Text(
                            "Time Zone",
                            style: TextStyle(
                                color: Colors.white, fontSize: width * 0.045),
                          ),
                          SizedBox(
                            height: width * 0.01,
                          ),
                          Text(
                            "$timeZone",
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: width * 0.04),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: width * 0.43,
                      width: width * 0.43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xff181818)!.withOpacity(0.7),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                              image: NetworkImage(
                                  "https://cdn2.iconfinder.com/data/icons/weather-blue-filled-line/32/Weather_rain_water_drop_rainy_wet_liquid-64.png")),
                          SizedBox(
                            height: width * 0.02,
                          ),
                          Text(
                            "Humidity",
                            style: TextStyle(
                                color: Colors.white, fontSize: width * 0.045),
                          ),
                          SizedBox(
                            height: width * 0.01,
                          ),
                          Text(
                            "$humidity%",
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: width * 0.04),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: width * 0.04,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: width * 0.43,
                      width: width * 0.43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xff181818)!.withOpacity(0.7),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image(
                              image: NetworkImage(
                                  "https://cdn0.iconfinder.com/data/icons/weather-line-19/32/Windy-64.png")),
                          SizedBox(
                            height: width * 0.02,
                          ),
                          Text(
                            "Wind",
                            style: TextStyle(
                                color: Colors.white, fontSize: width * 0.045),
                          ),
                          SizedBox(
                            height: width * 0.01,
                          ),
                          Text(
                            "$windSpeed",
                            style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: width * 0.04),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: width * 0.43,
                      width: width * 0.43,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color(0xff181818)!.withOpacity(0.7),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image(
                                  image: NetworkImage(
                                      "https://cdn2.iconfinder.com/data/icons/weather-and-forecast-free/32/Weather_Weather_Forecast_Sunrise_Sunset_Sun-64.png")),
                              SizedBox(
                                height: width * 0.02,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sunrise",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.045),
                                  ),
                                  SizedBox(
                                    height: width * 0.01,
                                  ),
                                  Text(
                                    "$sunriseTime",
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: width * 0.04),
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: width * 0.04,
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Sunset",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: width * 0.045),
                                  ),
                                  SizedBox(
                                    height: width * 0.01,
                                  ),
                                  Text(
                                    "$sunsetTime",
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: width * 0.04),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
