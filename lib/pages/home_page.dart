import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_weather_bloc_listener/blocs/temp_settings/temp_settings_bloc.dart';
import 'package:open_weather_bloc_listener/blocs/weather/weather_bloc.dart';
import 'package:open_weather_bloc_listener/constants/constants.dart';
import 'package:open_weather_bloc_listener/pages/search_page.dart';
import 'package:open_weather_bloc_listener/pages/settings_page.dart';
import 'package:open_weather_bloc_listener/widgets/error_dialog.dart';
import 'package:recase/recase.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    String? city;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearthere'),
        actions: [
          IconButton(
            onPressed: () async {
              city = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return const SearchPage();
                }),
              );
              log('__city: $city');
              if (city != null) {
                context.read<WeatherBloc>().add(FetchWeatherEvent(city: city!));
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () async {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return const SettingsPage();
                },
              ));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: _showWeather(),
    );
  }

  String showTemperature(double temperature) {
    final tempUnit = context.watch<TempSettingsBloc>().state.tempUnit;

    if (tempUnit == TempUnit.fahrenheit) {
      return '${((temperature * 9 / 5) + 32).toStringAsFixed(2)}℉';
    }

    return '${temperature.toStringAsFixed(2)}℃';
  }

  Widget showIcon(String icon) {
    return FadeInImage.assetNetwork(
      placeholder: 'assets/images/loading.gif',
      image: 'http://$kIconHost/img/wn/$icon@4x.png',
      width: 96,
      height: 96,
    );
  }

  Widget formatText(String description) {
    final formattedString = description.titleCase;
    return Text(
      formattedString,
      style: const TextStyle(fontSize: 24.0),
      textAlign: TextAlign.center,
    );
  }

  Widget _showWeather() {
    return BlocConsumer<WeatherBloc, WeatherState>(
      listener: (context, state) {
        if (state.status == WeatherStatus.error) {
          errorDialog(context, state.error.errMsg);
        }
      },
      builder: (context, state) {
        if (state.status == WeatherStatus.initial) {
          return const Center(
            child: Text(
              'Select a city',
              style: TextStyle(fontSize: 20.0),
            ),
          );
        }

        if (state.status == WeatherStatus.loading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state.status == WeatherStatus.error && state.weather.name == '') {
          return const Text(
            'Select a city',
            style: TextStyle(fontSize: 20.0),
          );
        }

        return ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height / 6),
            Text(
              state.weather.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  TimeOfDay.fromDateTime(state.weather.lastUpdated)
                      .format(context),
                  style: const TextStyle(fontSize: 18.0),
                ),
                const SizedBox(height: 10.0),
                Text(
                  '(${state.weather.country})',
                  style: const TextStyle(fontSize: 18.0),
                )
              ],
            ),
            const SizedBox(height: 60.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  showTemperature(state.weather.temp),
                  style: const TextStyle(
                    fontSize: 30.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 20.0),
                Column(
                  children: [
                    Text(
                      showTemperature(state.weather.tempMax),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      showTemperature(state.weather.tempMin),
                      style: const TextStyle(
                        fontSize: 16.0,
                      ),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Spacer(),
                showIcon(state.weather.icon),
                Expanded(flex: 3, child: formatText(state.weather.description)),
                const Spacer(),
              ],
            )
          ],
        );
      },
    );
  }
}
