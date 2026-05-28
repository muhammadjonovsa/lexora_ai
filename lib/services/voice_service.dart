import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});

class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (SpeechRecognitionError error) => print('Speech recognition error: $error'),
        onStatus: (String status) => print('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      print("Speech initialization exception: $e");
      _isInitialized = false;
      return false;
    }
  }

  bool get isListening => _speech.isListening;

  Future<void> startListening({
    required Function(String) onResult,
    required Function(double) onSoundLevel,
    required VoidCallback onComplete,
    String localeId = 'uz_UZ', // support Uzbek natively as default
  }) async {
    final hasPermission = await initSpeech();
    if (!hasPermission) {
      throw Exception("Mikrofon ruxsati berilmagan. Sozlamalardan faollashtiring.");
    }

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            onComplete();
          }
        },
        onSoundLevelChange: onSoundLevel,
        localeId: localeId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: true,
      );
    } catch (e) {
      print("Error listening: $e");
      throw Exception("Mikrofon tinglashida xatolik: $e");
    }
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    await _speech.cancel();
  }

  // Get available languages
  Future<List<LocaleName>> getLocales() async {
    await initSpeech();
    return await _speech.locales();
  }
}
