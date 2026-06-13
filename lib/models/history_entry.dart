import 'hairstyle_analysis_result.dart';

class HistoryEntry {
  const HistoryEntry({
    this.id = '',
    required this.result,
    required this.style,
    required this.timestamp,
    this.resultLabel = 'Hasil Deteksi',
  });

  final String id;
  final HairstyleAnalysisResult result;
  final String style;
  final DateTime timestamp;
  final String resultLabel;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result': result.toMap(),
      'style': style,
      'timestamp': timestamp.toIso8601String(),
      'resultLabel': resultLabel,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as String? ?? '',
      result: HairstyleAnalysisResult.fromMap(
        Map<String, dynamic>.from(map['result'] ?? {}),
      ),
      style: map['style'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      resultLabel: map['resultLabel'] as String? ?? 'Hasil Deteksi',
    );
  }
}
