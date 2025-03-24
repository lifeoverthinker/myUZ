import 'dart:async';
import 'dart:isolate';

import 'package:my_uz/utils/logger.dart';

typedef IsolateEntryFunction<T, R> = FutureOr<R> Function(T input, SendPort sendPort);

class IsolateManager<T, R> {
  final String name;

  IsolateManager(this.name);

  Future<List<R>> spawn(
      IsolateEntryFunction<T, R> entryPoint,
      List<T> inputs) async {
    if (inputs.isEmpty) {
      Logger.info('IsolateManager[$name]: Przetwarzanie partii 0 elementów');
      return [];
    }

    Logger.info('IsolateManager[$name]: Przetwarzanie partii ${inputs.length} elementów');
    final results = <R>[];
    final completer = Completer<void>();
    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    int completedCount = 0;

    receivePort.listen((message) {
      if (message is R) {
        results.add(message);
        completedCount++;

        if (completedCount >= inputs.length) {
          receivePort.close();
          errorPort.close();
          completer.complete();
        }
      } else if (message == 'done') {
        completedCount++;

        if (completedCount >= inputs.length) {
          receivePort.close();
          errorPort.close();
          completer.complete();
        }
      }
    });

    errorPort.listen((message) {
      Logger.error('IsolateManager[$name]: Błąd w izolacji: $message');
      // Nie zamykamy portów aby pozwolić innym zadaniom dokończyć pracę
    });

    for (final input in inputs) {
      await _spawnSingleIsolate(entryPoint, input, receivePort.sendPort, errorPort.sendPort);
    }

    await completer.future;
    return results;
  }

  Future<void> _spawnSingleIsolate(
    IsolateEntryFunction<T, R> entryPoint,
    T input,
    SendPort sendPort,
    SendPort errorPort
  ) async {
    try {
      // Przygotuj dane dla izolacji - tylko to co jest serializowalne
      final _IsolateData<T, R> isolateData = _IsolateData<T, R>(
        input: input,
        sendPort: sendPort,
        errorPort: errorPort,
        entryFunction: entryPoint,
      );

      await Isolate.spawn(_isolateEntryPoint, isolateData);
    } catch (e, stack) {
      Logger.error('IsolateManager[$name]: Błąd tworzenia izolacji: $e\n$stack');
      // Powiadom główny wątek o błędzie
      sendPort.send('error');
    }
  }

  static void _isolateEntryPoint<T, R>(_IsolateData<T, R> data) async {
    try {
      final result = await data.entryFunction(data.input, data.sendPort);
      if (result != null) {
        data.sendPort.send(result);
      } else {
        data.sendPort.send('done');
      }
    } catch (e, stack) {
      data.errorPort.send('$e\n$stack');
      // Powiadom główny wątek o zakończeniu (nawet z błędem)
      data.sendPort.send('done');
    }
  }
}

class _IsolateData<T, R> {
  final T input;
  final SendPort sendPort;
  final SendPort errorPort;
  final IsolateEntryFunction<T, R> entryFunction;

  _IsolateData({
    required this.input,
    required this.sendPort,
    required this.errorPort,
    required this.entryFunction,
  });
}