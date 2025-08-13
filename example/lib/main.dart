import 'package:flutter/material.dart';
import 'package:braintree_custom_ui/braintree_custom_ui.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Plugin example')),
      body: Center(
        child: FutureBuilder(
          future: BraintreeCustomUi.ping(),
          builder: (c, s) => Text('Ping: ${s.data ?? "..."}'),
        ),
      ),
    ),
  );
}
