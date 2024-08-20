import 'dart:convert';
import 'dart:typed_data';

class TemplateNFC {
  final String id;
  final String templateBase64;

  TemplateNFC({required this.id, required this.templateBase64});

  // Factory method per creare un Template dal Uint8List
  factory TemplateNFC.fromUint8List(String id, Uint8List template) {
    String guid = id; // Genera un GUID
    String templateBase64 =
        base64Encode(template); // Codifica il template in base64
    return TemplateNFC(id: guid, templateBase64: templateBase64);
  }

  // Metodo per convertire il Template in una mappa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'template': templateBase64,
    };
  }

  // Factory method per creare un Template da una mappa JSON
  factory TemplateNFC.fromJson(Map<String, dynamic> json) {
    return TemplateNFC(
      id: json['id'] as String,
      templateBase64: json['template'] as String,
    );
  }
}
