import 'dart:async';
import 'dart:isolate';
import 'logger.dart';

class IsolateManager<T, R> {
  final Function(T) _function;
  final String _name;
  final int _maxConcurrent;

  List<_TaskInfo<T, R>> _tasks = [];
  int _activeTasks = 0;

  IsolateManager(this._function, {
    required String name,
    int maxConcurrent = 3,
  }) : _name = name, _maxConcurrent = maxConcurrent;

  Future<List<R>> processBatch(List<T> items) async {
    Logger.info('IsolateManager[$_name]: Przetwarzanie partii ${items.length} elementów');

    _tasks = items.map((item) => _TaskInfo<T, R>(item)).toList();
    _activeTasks = 0;

    // Uruchom tyle zadań na raz, ile pozwala maxConcurrent
    _scheduleNext();

    // Czekaj aż wszystkie zadania się zakończą
    while (_tasks.any((task) => !task.isCompleted)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Zwróć wyniki
    return _tasks.map((task) => task.result!).toList();
  }

  void _scheduleNext() {
    if (_activeTasks >= _maxConcurrent) return;

    // Znajdź kolejne niezakończone zadanie
    final pendingTask = _tasks.firstWhere(
          (task) => !task.isStarted && !task.isCompleted,
      orElse: () => _TaskInfo(null as T, isCompleted: true),
    );

    // Jeśli nie ma więcej zadań, zakończ
    if (pendingTask.isCompleted) return;

    pendingTask.isStarted = true;
    _activeTasks++;

    // Uruchom zadanie w izolacji
    _runInIsolate(pendingTask.input).then((result) {
      pendingTask.result = result;
      pendingTask.isCompleted = true;
      _activeTasks--;

      // Uruchom kolejne zadanie
      _scheduleNext();
    }).catchError((e) {
      Logger.error('IsolateManager[$_name]: Błąd w izolacji: $e');
      pendingTask.isCompleted = true;
      _activeTasks--;

      // Mimo błędu, uruchom kolejne zadanie
      _scheduleNext();
    });

    // Jeśli możemy uruchomić więcej zadań równolegle, zrób to
    if (_activeTasks < _maxConcurrent) {
      _scheduleNext();
    }
  }

  Future<R> _runInIsolate(T input) async {
    final completer = Completer<R>();

    final receivePort = ReceivePort();
    final errorPort = ReceivePort();

    // Utwórz izolację
    final isolate = await Isolate.spawn<_IsolateData<T, R>>(
      _isolateEntryPoint,
      _IsolateData<T, R>(
        function: _function,
        input: input,
        sendPort: receivePort.sendPort,
      ),
      onError: errorPort.sendPort,
    );

    // Obsługa błędów
    errorPort.listen((error) {
      Logger.error('IsolateManager[$_name]: Błąd: $error');
      errorPort.close();
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
      completer.completeError(error ?? 'Nieznany błąd w izolacji');
    });

    // Obsługa wyniku
    receivePort.listen((message) {
      receivePort.close();
      errorPort.close();
      isolate.kill(priority: Isolate.immediate);
      completer.complete(message as R);
    });

    return completer.future;
  }

  static void _isolateEntryPoint<T, R>(_IsolateData<T, R> data) {
    try {
      // Wywołaj funkcję z danymi wejściowymi
      final result = data.function(data.input);

      // Wyślij wynik z powrotem
      data.sendPort.send(result);
    } catch (e) {
      // Błędy zostaną obsłużone przez errorPort
      rethrow;
    }
  }
}

// Klasa pomocnicza do przechowywania informacji o zadaniu
class _TaskInfo<T, R> {
  final T input;
  bool isStarted = false;
  bool isCompleted = false;
  R? result;

  _TaskInfo(this.input, {this.isCompleted = false});
}

// Klasa pomocnicza do przesyłania danych do izolacji
class _IsolateData<T, R> {
  final Function(T) function;
  final T input;
  final SendPort sendPort;

  _IsolateData({
    required this.function,
    required this.input,
    required this.sendPort,
  });
}