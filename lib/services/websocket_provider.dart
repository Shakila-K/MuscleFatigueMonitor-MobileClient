import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:muscle_fatigue_monitor/main.dart';
import 'package:toastification/toastification.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketProvider extends ChangeNotifier {
  WebSocketChannel? _channel;
  bool isConnected = false;
  bool isConnecting = false;
  bool isReading = false;
  int latestValue = 0;
  int retryCount = 0;
  final int _maxRetries = 2;
  bool _manualDisconnect = false;

  double threshold = 0;

  /// Connect to a WebSocket server
  Future<void> connect(String ipAddress) async {
    if (isConnecting) return;
    isConnecting = true;
    _manualDisconnect = false;
    notifyListeners();

    final uri = Uri.parse('ws://$ipAddress:81');
    debugPrint("Trying to connect...");

    try {
      _channel = WebSocketChannel.connect(uri);

      isConnected = true;
      isConnecting = false;
      retryCount = 0;
      debugPrint("WebSocket handshake successful");
      _showToastSafe("Connected to $ipAddress (waiting for data...)", ToastificationType.success);
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          if (!isConnected) {
            isConnected = true;
            isConnecting = false;
            retryCount = 0;
            debugPrint("Connected after receiving first message");
            _showToastSafe("Connected to $ipAddress ", ToastificationType.success);
            notifyListeners();
          }

          try {
            final parsed = jsonDecode(data);
            // debugPrint(parsed);
            if (parsed['value'] != "-") {
              isReading = true;
              latestValue = int.parse(parsed['value']);
              notifyListeners();
            } else {
              isReading = false;
              notifyListeners();
            }
          } catch (e) {
            debugPrint("Invalid JSON: $data");
          }
        },
        onDone: () {
          debugPrint("Connection closed");
          isConnected = false;
          isConnecting = false;
          notifyListeners();
          if(_manualDisconnect){
            _showToastSafe("Connection closed by user", ToastificationType.info);
          }else{
            _showToastSafe("Connection closed by server", ToastificationType.info);
            _reconnect(ipAddress);
          }
          
        },
        onError: (error, stack) {
          debugPrint("Stream error: $error");
          isConnected = false;
          isConnecting = false;
          notifyListeners();
          _showToastSafe("Stream error: $error", ToastificationType.error);

          if (!_manualDisconnect) { //skip reconnect if manual
            _showToastSafe("Stream error: $error", ToastificationType.error);
            _reconnect(ipAddress);
          }
        },
        cancelOnError: true, // prevents bubbling unhandled
      );
    } on SocketException catch (e) {
      debugPrint("Socket error: $e");
      _showToastSafe("Socket error: $e", ToastificationType.error);
      isConnected = false;
      isConnecting = false;
      notifyListeners();
    } on WebSocketChannelException catch (e) {
      debugPrint("WebSocket error: $e");
      _showToastSafe("WebSocket error: $e", ToastificationType.error);
      isConnected = false;
      isConnecting = false;
      notifyListeners();
    } catch (e, st) {
      debugPrint("Unexpected error: $e\n$st");
      _showToastSafe("Unexpected error: $e", ToastificationType.error);
      isConnected = false;
      isConnecting = false;
      notifyListeners();
    }
  }

  /// Send a message
  void send(String msg) {
    _channel?.sink.add(msg);
  }

  /// Disconnect
  void disconnect(bool auto) {
    if(!auto){
      _manualDisconnect = true;
      retryCount=0;
    }
    _channel?.sink.close();
    _channel = null;
    isConnected = false;
    isConnecting = false;
    notifyListeners();
  }

  /// Reconnect with retry counter
  void _reconnect(String ipAddress) {
    if (retryCount >= _maxRetries) {
      _showToastSafe("Max retry attempts reached. Stop reconnecting.", ToastificationType.error);
      retryCount = 0;
      return;
    }

    retryCount++;
    debugPrint("Retrying connection ($retryCount/$_maxRetries)...");

    Future.delayed(const Duration(seconds: 2), () async {
      if (!isConnected && !_manualDisconnect) {
        try {
          await connect(ipAddress);
        } catch (e, st) {
          debugPrint("Reconnect failed: $e\n$st");
          _showToastSafe("Reconnect failed: $e", ToastificationType.error);
          isConnecting = false;
          notifyListeners();
        }
      }
    });
  }

  /// Toast with global navigatorKey
  void _showToastSafe(String message, ToastificationType type) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    toastification.show(
      context: ctx,
      type: type,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.bottomCenter,
      title: Text(message),
    );
  }
}
