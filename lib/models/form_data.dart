// models/form_data.dart
class FormData {
  final String uuid;
  final Map<String, dynamic> identite;
  final Map<String, dynamic> parcelle;
  final dynamic questionnaire_parcelles;
  Map<String, dynamic> metadata; // Changez de final à mutable

  FormData({
    required this.uuid,
    required this.identite,
    required this.parcelle,
    required this.questionnaire_parcelles,
    required this.metadata,
  });

  // Ajoutez un setter pour metadata
  void setMetadata(Map<String, dynamic> newMetadata) {
    metadata = newMetadata;
  }

  // Ou créez une méthode pour mettre à jour un champ spécifique
  void updateMetadataField(String key, dynamic value) {
    metadata[key] = value;
  }

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      uuid: json['uuid'] ?? '',
      identite: Map<String, dynamic>.from(json['identite'] ?? {}),
      parcelle: Map<String, dynamic>.from(json['parcelle'] ?? {}),
      questionnaire_parcelles: json['questionnaire_parcelles'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'identite': identite,
      'parcelle': parcelle,
      'questionnaire_parcelles': questionnaire_parcelles,
      'metadata': metadata,
    };
  }
}