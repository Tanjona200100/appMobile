/// Modèle de données pour le formulaire
class FormData {
  final String uuid;
  final Map<String, dynamic> identite;
  final Map<String, dynamic> parcelle;
  final Map<String, dynamic> metadata;

  FormData({
    required this.uuid,
    required this.identite,
    required this.parcelle,
    required this.metadata, required List<Map<String, dynamic>> questionnaire_parcelles,
  });

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'identite': identite,
      'parcelle': parcelle,
      'metadata': metadata,
    };
  }

  factory FormData.fromJson(Map<String, dynamic> json) {
    return FormData(
      uuid: json['uuid'] ?? '',
      identite: json['identite'] ?? {},
      parcelle: json['parcelle'] ?? {},
      metadata: json['metadata'] ?? {}, questionnaire_parcelles: [],
    );
  }

  get informationContrat => null;

  get createdAt => null;

  get questionnaire_parcelles => null;
}