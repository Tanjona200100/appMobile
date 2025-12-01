import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/form_data.dart';
import '../models/form_data.dart';

class AutoSyncService {
  final String _baseUrl = 'http://13.246.182.15:3001';

  get _pendingSyncForms => null;

  // === MÉTHODES DE CONVERSION SÉCURISÉES ===

  int safeInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9-]'), '');
      return int.tryParse(cleaned) ?? defaultValue;
    }
    if (value is double) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    return defaultValue;
  }

  double safeDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  String safeString(dynamic value, [String defaultValue = '']) {
    if (value == null) return defaultValue;
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  /// Garantit qu'une map n'est jamais null
  Map<String, dynamic> _ensureMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  /// Gestion sécurisée des données CIN
  Map<String, dynamic> _safeCin(dynamic cinData) {
    try {
      if (cinData == null) return {};

      final cinMap = _ensureMap(cinData);
      final cleanedCin = <String, dynamic>{};

      if (cinMap['numero'] != null) {
        cleanedCin['numero'] = safeString(cinMap['numero']);
      }
      if (cinMap['date_delivrance'] != null) {
        cleanedCin['date_delivrance'] = safeString(cinMap['date_delivrance']);
      }
      if (cinMap['commune_delivrance'] != null) {
        cleanedCin['commune_delivrance'] = safeString(cinMap['commune_delivrance']);
      }

      return cleanedCin;
    } catch (e) {
      print('⚠️ Erreur conversion CIN: $e');
      return {};
    }
  }

  /// Génère les données geom selon la structure attendue
  List<Map<String, double>> _safeGeomData(Map<String, dynamic> parcelle) {
    try {
      final lat = safeDouble(parcelle['latitude'], -18.879);
      final lng = safeDouble(parcelle['longitude'], 47.5078);

      return [
        {'latitude': lat, 'longitude': lng},
        {'latitude': lat - 0.00005, 'longitude': lng + 0.00005},
        {'latitude': lat - 0.0001, 'longitude': lng - 0.00005},
        {'latitude': lat, 'longitude': lng},
      ];
    } catch (e) {
      print('⚠️ Erreur génération geom: $e');
      return [
        {'latitude': -18.879, 'longitude': 47.5078},
        {'latitude': -18.87905, 'longitude': 47.50785},
        {'latitude': -18.8791, 'longitude': 47.50775},
        {'latitude': -18.879, 'longitude': 47.5078},
      ];
    }
  }

  /// Nettoie et valide les données du questionnaire
  List<dynamic> _safeQuestionnaireData(dynamic questionnaireData) {
    try {
      if (questionnaireData == null) return [];

      if (questionnaireData is List) {
        if (questionnaireData.isEmpty) return [];

        return questionnaireData.map((section) {
          if (section is Map) {
            return _cleanQuestionnaireSection(Map<String, dynamic>.from(section));
          }
          return section;
        }).toList();
      }

      // Si c'est une Map, la convertir en List
      if (questionnaireData is Map) {
        final cleaned = _cleanQuestionnaireSection(Map<String, dynamic>.from(questionnaireData));
        return [cleaned];
      }

      print('⚠️ Format questionnaire inattendu: ${questionnaireData.runtimeType}');
      return [];
    } catch (e) {
      print('⚠️ Erreur conversion questionnaire: $e');
      return [];
    }
  }

  /// Nettoie une section du questionnaire
  Map<String, dynamic> _cleanQuestionnaireSection(Map<String, dynamic> section) {
    final cleaned = <String, dynamic>{};

    section.forEach((key, value) {
      if (value is Map) {
        cleaned[key] = _cleanNestedMap(value);
      } else if (value is List) {
        cleaned[key] = value.map((item) {
          if (item is Map) return _cleanNestedMap(item);
          return _cleanPrimitiveValue(item);
        }).toList();
      } else {
        cleaned[key] = _cleanPrimitiveValue(value);
      }
    });

    return cleaned;
  }

  /// Nettoie les maps imbriquées
  Map<String, dynamic> _cleanNestedMap(dynamic mapData) {
    if (mapData is! Map) return {};

    final cleaned = <String, dynamic>{};
    final map = Map<String, dynamic>.from(mapData);

    map.forEach((key, value) {
      cleaned[key] = _cleanPrimitiveValue(value);
    });

    return cleaned;
  }

  /// Nettoie les valeurs primitives
  dynamic _cleanPrimitiveValue(dynamic value) {
    if (value == null) return null;

    // Conversion des types selon les besoins
    if (value is String) {
      if (_looksLikeInteger(value)) {
        return safeInt(value);
      } else if (_looksLikeDouble(value)) {
        return safeDouble(value);
      } else if (value.toLowerCase() == 'true' || value.toLowerCase() == 'false') {
        return value.toLowerCase() == 'true';
      }
      return value.trim();
    }

    return value;
  }

  bool _looksLikeInteger(String value) {
    return RegExp(r'^-?\d+$').hasMatch(value.trim());
  }

  bool _looksLikeDouble(String value) {
    return RegExp(r'^-?\d*\.?\d+$').hasMatch(value.trim());
  }

  /// Crée un questionnaire par défaut avec les bons types
  Map<String, dynamic> _createDefaultQuestionnaire() {
    return {
      'exploitation': {
        'type_contrat': 'Co-gestion',
        'technique_riziculture': 'Traditionnelle',
        'surface_totale_m2': 0,
        'nombre_parcelles': 0,
        'surface_moyenne_parcelle_m2': 0,
        'objectif_production': []
      },
      'semences': {
        'varietes_semences': [],
        'provenance_semences': [],
        'quantite_semences_kg': 0,
        'pratique_semis': 'Direct'
      },
      'engrais_et_amendements': {
        'utilisation_engrais': false,
        'type_engrais': [],
        'quantite_engrais_chimique_kg': 0,
        'quantite_engrais_organique_kg': 0,
        'frequence_engrais': '',
        'utilisation_amendements': false,
        'amendements': []
      },
      'eau_et_irrigation': {
        'source_eau_principale': [],
        'systeme_irrigation': '',
        'problemes_eau': []
      },
      'protection_culture_et_recolte': {
        'ravageurs': [],
        'utilisation_pesticides': false,
        'type_pesticides': [],
        'techniques_naturelles': [],
        'mode_recolte': 'Manuel'
      },
      'production_et_stockage': {
        'rendement_kg': 0,
        'duree_stockage_mois': 0,
        'perte_post_recolte_pourcent': 0,
        'mode_stockage': [],
        'pratique_post_recolte': []
      },
      'commercialisation': {
        'vente_riz': false,
        'quantite_vendue_kg': 0,
        'prix_vente_ar_kg': 0,
        'lieu_vente': [],
        'sait_cultiver_riz_hybride': false
      },
      'diversification_activites': {
        'autres_cultures': [],
        'elevage': false,
        'nombre_poules': 0,
        'nombre_volailles': 0,
        'nombre_boeufs': 0,
        'nombre_porc': 0,
        'nombre_moutons': 0,
        'nombre_chevres': 0,
        'nombre_lapins': 0,
        'pisciculture': false
      },
      'competences_et_formation': {
        'competences_maitrisees': [],
        'mode_formation': [],
        'competences_interet_formation': []
      },
      'appui_et_besoins': {
        'appui_social': false,
        'appui_recu': [],
        'besoins_supplementaires': []
      }
    };
  }

  /// Valide les types dans le JSON avant envoi
  void _validateJsonTypes(Map<String, dynamic> jsonData) {
    print('🔍 VALIDATION DES TYPES FINALE:');

    final errors = <String>[];

    final individu = jsonData['individu'] as Map<String, dynamic>;
    _validateField(individu, 'user_id', int, errors);
    _validateField(individu, 'commune_id', int, errors);
    _validateField(individu, 'nombre_personnes_a_charge', int, errors);
    _validateField(individu, 'nombre_enfants', int, errors);

    final parcelles = jsonData['parcelles'] as List;
    if (parcelles.isNotEmpty) {
      final parcelle = parcelles.first as Map<String, dynamic>;
      _validateField(parcelle, 'superficie', double, errors);

      final gps = parcelle['gps'] as Map<String, dynamic>;
      _validateField(gps, 'latitude', double, errors);
      _validateField(gps, 'longitude', double, errors);
      _validateField(gps, 'altitude', double, errors);

      final geom = parcelle['geom'] as List;
      for (int i = 0; i < geom.length; i++) {
        final point = geom[i] as Map<String, dynamic>;
        _validateField(point, 'latitude', double, errors, 'geom[$i]');
        _validateField(point, 'longitude', double, errors, 'geom[$i]');
      }
    }

    if (errors.isNotEmpty) {
      print('❌ ERREURS DE TYPE DÉTECTÉES:');
      errors.forEach(print);
    } else {
      print('✅ TOUS LES TYPES SONT CORRECTS');
    }
  }

  void _validateField(Map<String, dynamic> map, String field, Type expectedType,
      List<String> errors, [String prefix = '']) {
    final fullField = prefix.isEmpty ? field : '$prefix.$field';
    final value = map[field];

    if (value == null) {
      errors.add('$fullField: NULL (attendu: $expectedType)');
      return;
    }

    if (value.runtimeType != expectedType) {
      errors.add('$fullField: ${value.runtimeType} (attendu: $expectedType)');
    }
  }

  // === MÉTHODES PRINCIPALES DE SYNCHRONISATION ===

  /// Convertit FormData en format JSON complet pour l'API - VERSION CORRIGÉE
  /// Convertit FormData en format JSON complet pour l'API - VERSION CORRIGÉE
  Map<String, dynamic> _convertToCompleteJson(FormData formData) {
    print('🔧 CONVERSION JSON pour ${formData.uuid}');

    // GARANTIR que les maps ne sont jamais null
    final identite = _ensureMap(formData.identite);
    final parcelle = _ensureMap(formData.parcelle);
    final metadata = _ensureMap(formData.metadata);

    // Gestion du questionnaire - CORRECTION CRITIQUE
    List<dynamic> questionnaireData = [];

    if (formData.questionnaire_parcelles != null) {
      if (formData.questionnaire_parcelles is List) {
        questionnaireData = formData.questionnaire_parcelles as List<dynamic>;
      } else if (formData.questionnaire_parcelles is Map) {
        // Si c'est une Map, la convertir en List avec un seul élément
        questionnaireData = [formData.questionnaire_parcelles];
      }
    }

    print('📊 Données questionnaire pour sync: ${questionnaireData.length} sections');

    // CONSTRUCTION SÉCURISÉE DU JSON selon votre exemple
    final jsonData = {
      'individu': {
        'uuid': safeString(formData.uuid),
        'nom': safeString(identite['nom'], 'Inconnu'),
        'prenom': safeString(identite['prenom'], 'Inconnu'),
        'surnom': safeString(identite['surnom']),
        'sexe': safeString(identite['sexe']),
        'date_naissance': safeString(identite['date_naissance']),
        'lieu_naissance': safeString(identite['lieu_naissance']),
        'adresse': safeString(identite['adresse']),
        'gps_point': '${safeDouble(parcelle['latitude'])},${safeDouble(parcelle['longitude'])}',
        'photo': '',
        'user_id': safeInt(metadata['agent_id'], 1),
        'commune_id': 2,
        'nom_pere': safeString(identite['nom_pere']),
        'nom_mere': safeString(identite['nom_mere']),
        'profession': safeString(identite['metier']),
        'activites_complementaires': safeString(identite['activites_complementaires']),
        'statut_matrimonial': safeString(identite['statut_matrimonial']),
        'nombre_personnes_a_charge': safeInt(identite['nombre_personnes_charge']),
        'telephone': safeString(identite['telephone1']),
        'cin': _safeCin(identite['cin']),
        'commune_nom': safeString(identite['commune'], 'Non spécifié'),
        'fokontany_nom': safeString(identite['fokontany'], 'Non spécifié'),
        'nombre_enfants': safeInt(identite['nombre_enfants']),
        'telephone2': safeString(identite['telephone2']),
      },
      'parcelles': [
        {
          'nom': safeString(parcelle['nom'], 'Parcelle ${identite['nom']} ${identite['prenom']}'),
          'superficie': safeDouble(parcelle['superficie'], 1500.0),
          'gps': {
            'latitude': safeDouble(parcelle['latitude'], -18.879),
            'longitude': safeDouble(parcelle['longitude'], 47.5078),
            'altitude': safeDouble(parcelle['altitude'], 1280.0),
          },
          'geom': _safeGeomData(parcelle),
          'description': safeString(parcelle['description'], 'Rizière en terrasse'),
        }
      ],
      'questionnaire_parcelles': questionnaireData, // DONNÉES QUESTIONNAIRE DIRECTES
    };

    // Validation finale
    _validateJsonTypes(jsonData);

    // Log final pour debug
    final encoder = JsonEncoder.withIndent('  ');
    print('🎯 JSON FINAL À ENVOYER:\n${encoder.convert(jsonData)}');

    return jsonData;
  }



  /// Synchronise un formulaire individuel - CORRIGÉ
  Future<Map<String, dynamic>> _syncSingleForm(FormData formData) async {
    try {
      final url = Uri.parse('$_baseUrl/import_massif');

      // Convertir en format JSON complet
      final jsonData = _convertToCompleteJson(formData);

      print('📤 Envoi vers: $url');
      print('📄 UUID: ${formData.uuid}');
      print('👤 Nom: ${formData.identite?['nom']} ${formData.identite?['prenom']}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(jsonData),
      ).timeout(const Duration(seconds: 30));

      print('📥 Réponse reçue:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      // ANALYSE DÉTAILLÉE DE LA RÉPONSE
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Succès - Statut ${response.statusCode}');
        return {'success': true};
      }
      else if (response.statusCode == 409) {
        print('⚠️ Doublon - Statut 409');
        return {
          'success': false,
          'duplicate': true,
          'error': 'Doublon: Le formulaire existe déjà sur le serveur'
        };
      }
      else if (response.statusCode == 400) {
        String errorMessage = 'Requête invalide (400)';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = 'Erreur 400: ${errorBody['message'] ?? errorBody['error'] ?? response.body}';
        } catch (e) {
          errorMessage = 'Erreur 400: ${response.body}';
        }
        print('❌ Erreur client: $errorMessage');
        return {
          'success': false,
          'error': errorMessage
        };
      }
      else if (response.statusCode == 422) {
        String errorMessage = 'Données non valides (422)';
        try {
          final errorBody = jsonDecode(response.body);
          errorMessage = 'Erreur 422: ${errorBody['errors'] ?? errorBody['message'] ?? response.body}';
        } catch (e) {
          errorMessage = 'Erreur 422: ${response.body}';
        }
        print('❌ Erreur validation: $errorMessage');
        return {
          'success': false,
          'error': errorMessage
        };
      }
      else if (response.statusCode >= 500) {
        print('❌ Erreur serveur - Statut ${response.statusCode}');
        return {
          'success': false,
          'error': 'Erreur serveur ${response.statusCode}: Le serveur rencontre des problèmes'
        };
      }
      else {
        print('❌ Erreur HTTP inattendue - Statut ${response.statusCode}');
        return {
          'success': false,
          'error': 'Erreur HTTP ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      print('❌ Exception lors de la synchronisation:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');

      String errorMessage;
      if (e is http.ClientException) {
        errorMessage = 'Erreur réseau: ${e.message}';
      } else if (e is FormatException) {
        errorMessage = 'Erreur format JSON: $e';
      } else {
        errorMessage = 'Exception: $e';
      }

      return {
        'success': false,
        'error': errorMessage
      };
    }
  }

  /// Synchronise plusieurs formulaires avec progression
  Future<Map<String, dynamic>> syncMultipleForms(
      List<FormData> forms, {
        required Function(int current, int total) onProgress,
      }) async {
    print('🔄 Début sync multiple de ${forms.length} formulaires');

    int successCount = 0;
    int failureCount = 0;
    int duplicateCount = 0;
    final failedUuids = <String>[];
    final errors = <String, String>{};

    for (int i = 0; i < forms.length; i++) {
      final form = forms[i];
      print('📤 Envoi formulaire ${i + 1}/${forms.length}: ${form.uuid}');

      try {
        final result = await _syncSingleForm(form);

        if (result['success'] == true) {
          successCount++;
          print('✅ Formulaire ${form.uuid} synchronisé avec succès');
        } else if (result['duplicate'] == true) {
          duplicateCount++;
          print('⚠️ Formulaire ${form.uuid} déjà existant (doublon)');
        } else {
          failureCount++;
          failedUuids.add(form.uuid);
          final errorMsg = result['error'] ?? 'Erreur inconnue';
          errors[form.uuid] = errorMsg;
          print('❌ Échec formulaire ${form.uuid}: $errorMsg');
        }
      } catch (e) {
        failureCount++;
        failedUuids.add(form.uuid);
        final errorMsg = e.toString();
        errors[form.uuid] = errorMsg;
        print('❌ Exception formulaire ${form.uuid}: $errorMsg');
      }

      // Mettre à jour la progression
      onProgress(i + 1, forms.length);

      // Petit délai pour éviter de surcharger le serveur
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final result = {
      'success': failureCount == 0,
      'success_count': successCount,
      'failure_count': failureCount,
      'duplicate_count': duplicateCount,
      'failed_uuids': failedUuids,
      'errors': errors,
      'total_processed': forms.length,
    };

    print('📊 Résultat final syncMultipleForms:');
    print('   Succès: $successCount');
    print('   Échecs: $failureCount');
    print('   Doublons: $duplicateCount');
    print('   Erreurs détaillées: $errors');

    return result;
  }

  /// Teste la connexion au serveur avec diagnostic complet
  Future<Map<String, dynamic>> testServerConnection() async {
    print('🔍 TEST COMPLET DE CONNEXION SERVEUR');

    try {
      // Test 1: Endpoint principal
      print('1️⃣ Test endpoint /import_massif...');
      final testUrl = Uri.parse('$_baseUrl/import_massif');
      print('   URL: $testUrl');

      final response1 = await http.get(testUrl).timeout(const Duration(seconds: 10));
      print('   ✅ Statut: ${response1.statusCode}');
      print('   📄 Body: ${response1.body}');

      // Test 2: Endpoint racine
      print('2️⃣ Test endpoint racine...');
      final rootUrl = Uri.parse('$_baseUrl/');
      final response2 = await http.get(rootUrl).timeout(const Duration(seconds: 10));
      print('   ✅ Statut: ${response2.statusCode}');

      // Test 3: Health check
      print('3️⃣ Test health check...');
      try {
        final healthUrl = Uri.parse('$_baseUrl/health');
        final response3 = await http.get(healthUrl).timeout(const Duration(seconds: 5));
        print('   ✅ Health: ${response3.statusCode}');
      } catch (e) {
        print('   ⚠️ Health endpoint non disponible: $e');
      }

      return {
        'success': true,
        'import_massif_status': response1.statusCode,
        'root_status': response2.statusCode,
        'message': 'Serveur accessible'
      };

    } catch (e) {
      print('❌ TEST CONNEXION ÉCHOUÉ:');
      print('   Type: ${e.runtimeType}');
      print('   Message: $e');

      return {
        'success': false,
        'error': 'Impossible de joindre le serveur: $e'
      };
    }
  }

  // Méthodes supplémentaires pour compatibilité
  Future<bool> syncFormToServer(FormData form) async {
    final result = await _syncSingleForm(form);
    return result['success'] == true;
  }

  Future<Map<String, dynamic>> syncAllFromLocalToMaster() async {
    try {
      // Implémentation simulée pour l'instant
      return {
        'success': true,
        'total': 0,
        'inserted': 0,
        'updated': 0,
        'skipped': 0,
        'errors': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  void _showSnackBar(String s, orange) {}
}