import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../services/simulator_service.dart';

final simulatorServiceProvider = Provider<SimulatorService>((ref) => SimulatorService(ref.watch(dioClientProvider)));

// Simulator runs entirely in Dart — no provider state needed for the main scenario.
// This provider only stores the skip-EMI result from the API.
final skipEmiResultProvider = StateProvider<Map<String, dynamic>?>((ref) => null);
