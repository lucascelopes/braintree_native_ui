import 'package:flutter/material.dart';
import 'package:braintree_native_ui/braintree_native_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _braintree = BraintreeNativeUi();
  String _output = '';

  Future<void> _tokenizeCard() async {
    try {
      final nonce = await _braintree.tokenizeCard(
        authorization: '<YOUR_TOKENIZATION_KEY>',
        number: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2030',
        cvv: '123',
      );
      setState(() => _output = 'Nonce: $nonce');
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  Future<void> _collectDeviceData() async {
    try {
      final data = await _braintree.collectDeviceData(
        authorization: '<YOUR_TOKENIZATION_KEY>',
      );
      setState(() => _output = 'Device data: $data');
    } catch (e) {
      setState(() => _output = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Braintree Native UI example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _tokenizeCard,
                child: const Text('Tokenize Card'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _collectDeviceData,
                child: const Text('Collect Device Data'),
              ),
              const SizedBox(height: 16),
              Text(_output),
            ],
          ),
        ),
      ),
    );
  }
}
