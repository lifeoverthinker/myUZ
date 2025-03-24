import 'package:flutter/material.dart';

    // Przyjmuje BuildContext jako parametr
    Widget buildSyncInfoButton(BuildContext context) {
      return ElevatedButton.icon(
        icon: Icon(Icons.info_outline),
        label: Text('Informacje o synchronizacji'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Informacje o synchronizacji'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dane są synchronizowane automatycznie w chmurze.'),
                  SizedBox(height: 8),
                  Text('Aktualizacja danych odbywa się co 12 godzin poprzez GitHub Actions.'),
                  SizedBox(height: 8),
                  Text('Aplikacja mobilna służy tylko do przeglądania danych.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
      );
    }

    class HomeScreen extends StatelessWidget {
      const HomeScreen({super.key});

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(
            title: Text('UZ Plan'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // inne widgety
                buildSyncInfoButton(context), // przekazujemy context
              ],
            ),
          ),
        );
      }
    }