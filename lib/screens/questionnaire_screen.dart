import 'package:flutter/material.dart';

/// ------------------------------
/// Écran de questionnaire Riziculture
/// ------------------------------
class QuestionnaireScreen extends StatefulWidget {
  final String title;
  final int questionnaireNumber;

  const QuestionnaireScreen({
    Key? key,
    required this.title,
    required this.questionnaireNumber,
  }) : super(key: key);

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // États pour les boutons radio
  bool? utilisationEngrais;
  bool? utilisationAmendements;
  bool? utilisationPesticides;
  bool? vendezVousRiz;
  bool? cultivezRizHybride;
  bool? elevage;
  bool? pisciculture;
  bool? appuiSocial;

  // Map pour toutes les options avec cases à cocher
  Map<String, bool> techniqueRiziculture = {
    'Riziculture pluviale': false,
    'Riziculture irriguée': false,
    'Riziculture de bas-fond': false,
  };

  Map<String, bool> objectifProduction = {
    'Autoconsommation': false,
    'Vente locale': false,
    'Vente régionale': false,
    'Semences': false,
    'Autre': false,
  };

  Map<String, bool> provenanceSemences = {
    'Production propre': false,
    'Achat local': false,
    'Coopérative': false,
    'Projet/ONG': false,
  };

  Map<String, bool> pratiqueSemis = {
    'Semis direct': false,
    'Repiquage': false,
    'Semis en ligne': false,
  };

  Map<String, bool> typeEngrais = {
    'Chimique': false,
    'Organique': false,
    'Les deux': false,
  };

  Map<String, bool> sourcesEau = {
    'Rivière': false,
    'Canal': false,
    'Puits': false,
    'Pluie': false,
  };

  Map<String, bool> systemeIrrigation = {
    'Gravité': false,
    'Pompage': false,
    'Arrosage manuel': false,
  };

  Map<String, bool> problemesEau = {
    'Sécheresse': false,
    'Inondation': false,
    'Qualité': false,
  };

  Map<String, bool> principauxRavageurs = {
    'Insectes': false,
    'Oiseaux': false,
    'Rongeurs': false,
  };

  Map<String, bool> typePesticides = {
    'Insecticide': false,
    'Fongicide': false,
    'Herbicide': false,
  };

  Map<String, bool> techniquesNaturelles = {
    'Rotation': false,
    'Association': false,
    'Pièges': false,
  };

  Map<String, bool> modeRecolte = {
    'Manuel': false,
    'Mécanique': false,
    'Mixte': false,
  };

  Map<String, bool> modeStockage = {
    'Sacs': false,
    'Grenier': false,
    'Silo': false,
  };

  Map<String, bool> pratiqueApresRecolte = {
    'Vente immédiate': false,
    'Stockage': false,
    'Transformation': false,
  };

  Map<String, bool> lieuVente = {
    'Marché local': false,
    'Coopérative': false,
    'Domicile': false,
  };

  // NOUVEAUX MAPS pour remplacer les TextEditingController
  Map<String, bool> anneesExperience = {
    'Moins de 1 an': false,
    '1-5 ans': false,
    '6-10 ans': false,
    '11-20 ans': false,
    'Plus de 20 ans': false,
  };

  Map<String, bool> surfaceTotale = {
    'Moins de 1000 m²': false,
    '1000-5000 m²': false,
    '5001-10000 m²': false,
    '10001-20000 m²': false,
    'Plus de 20000 m²': false,
  };

  Map<String, bool> nombreParcelles = {
    '1 parcelle': false,
    '2-3 parcelles': false,
    '4-5 parcelles': false,
    '6-10 parcelles': false,
    'Plus de 10 parcelles': false,
  };

  Map<String, bool> surfaceMoyenne = {
    'Moins de 500 m²': false,
    '500-1000 m²': false,
    '1001-2000 m²': false,
    '2001-5000 m²': false,
    'Plus de 5000 m²': false,
  };

  Map<String, bool> varietesSemences = {
    'Vary gasy': false,
    'Makalioka': false,
    'X265': false,
    'X266': false,
    'Résistant 15': false,
    'Autre variété locale': false,
    'Autre variété hybride': false,
  };

  Map<String, bool> quantiteSemences = {
    'Moins de 10 kg': false,
    '10-25 kg': false,
    '26-50 kg': false,
    '51-100 kg': false,
    'Plus de 100 kg': false,
  };

  Map<String, bool> quantiteEngraisChimique = {
    'Moins de 10 kg': false,
    '10-25 kg': false,
    '26-50 kg': false,
    '51-100 kg': false,
    'Plus de 100 kg': false,
  };

  Map<String, bool> quantiteEngraisOrganique = {
    'Moins de 50 kg': false,
    '50-100 kg': false,
    '101-200 kg': false,
    '201-500 kg': false,
    'Plus de 500 kg': false,
  };

  Map<String, bool> frequenceEngrais = {
    '1 fois par saison': false,
    '2 fois par saison': false,
    '3 fois par saison': false,
    'Plus de 3 fois': false,
    'Selon les besoins': false,
  };

  Map<String, bool> amendements = {
    'Chaux': false,
    'Compost': false,
    'Fumier': false,
    'Cendres': false,
    'Biochar': false,
    'Aucun': false,
  };

  Map<String, bool> rendement = {
    'Moins de 100 kg': false,
    '100-500 kg': false,
    '501-1000 kg': false,
    '1001-2000 kg': false,
    'Plus de 2000 kg': false,
  };

  Map<String, bool> dureeStockage = {
    'Moins de 1 mois': false,
    '1-3 mois': false,
    '4-6 mois': false,
    '7-12 mois': false,
    'Plus d\'1 an': false,
  };

  Map<String, bool> pertePostRecolte = {
    'Moins de 5%': false,
    '5-10%': false,
    '11-20%': false,
    '21-30%': false,
    'Plus de 30%': false,
  };

  Map<String, bool> quantiteVendue = {
    'Moins de 50 kg': false,
    '50-100 kg': false,
    '101-200 kg': false,
    '201-500 kg': false,
    'Plus de 500 kg': false,
  };

  Map<String, bool> prixVente = {
    'Moins de 1000 Ar/kg': false,
    '1000-1500 Ar/kg': false,
    '1501-2000 Ar/kg': false,
    '2001-2500 Ar/kg': false,
    'Plus de 2500 Ar/kg': false,
  };

  Map<String, bool> autresCultures = {
    'Maïs': false,
    'Manioc': false,
    'Haricot': false,
    'Légumes': false,
    'Fruits': false,
    'Aucune autre culture': false,
  };

  Map<String, bool> nombrePoules = {
    'Aucune': false,
    '1-10': false,
    '11-20': false,
    '21-50': false,
    'Plus de 50': false,
  };

  Map<String, bool> nombreVolailles = {
    'Aucune': false,
    '1-10': false,
    '11-20': false,
    '21-50': false,
    'Plus de 50': false,
  };

  Map<String, bool> nombreBoeufs = {
    'Aucun': false,
    '1-2': false,
    '3-5': false,
    '6-10': false,
    'Plus de 10': false,
  };

  Map<String, bool> nombrePorc = {
    'Aucun': false,
    '1-2': false,
    '3-5': false,
    '6-10': false,
    'Plus de 10': false,
  };

  Map<String, bool> nombreMoutons = {
    'Aucun': false,
    '1-2': false,
    '3-5': false,
    '6-10': false,
    'Plus de 10': false,
  };

  Map<String, bool> nombreChevres = {
    'Aucun': false,
    '1-2': false,
    '3-5': false,
    '6-10': false,
    'Plus de 10': false,
  };

  Map<String, bool> nombreLapins = {
    'Aucun': false,
    '1-2': false,
    '3-5': false,
    '6-10': false,
    'Plus de 10': false,
  };

  Map<String, bool> competencesMaitrisees = {
    'Préparation sol': false,
    'Semis': false,
    'Irrigation': false,
    'Fertilisation': false,
    'Traitement phytosanitaire': false,
    'Récolte': false,
    'Stockage': false,
  };

  Map<String, bool> modeFormation = {
    'Formation en groupe': false,
    'Formation individuelle': false,
    'Démonstration champ': false,
    'Visite échange': false,
    'Radio rurale': false,
    'Aucune formation': false,
  };

  Map<String, bool> competencesInteret = {
    'Nouvelles techniques': false,
    'Gestion financière': false,
    'Commercialisation': false,
    'Transformation': false,
    'Gestion stock': false,
    'Agriculture biologique': false,
  };

  Map<String, bool> appuiRecu = {
    'Semences': false,
    'Engrais': false,
    'Matériel agricole': false,
    'Formation': false,
    'Financement': false,
    'Aucun appui': false,
  };

  Map<String, bool> besoinsSupplementaires = {
    'Semences améliorées': false,
    'Engrais': false,
    'Matériel irrigation': false,
    'Formation': false,
    'Financement': false,
    'Accès marché': false,
  };

  Map<String, dynamic> _generateQuestionnaireData() {
    return {
      "exploitation": {
        "type_contrat": "Co-gestion",
        "technique_riziculture": _getSelectedOptions(techniqueRiziculture).isNotEmpty
            ? _getSelectedOptions(techniqueRiziculture).join(', ')
            : "Traditionnelle",
        "surface_totale_m2": _convertSurfaceToNumber(_getSelectedOptions(surfaceTotale).isNotEmpty
            ? _getSelectedOptions(surfaceTotale).first
            : "Moins de 1000 m²"),
        "nombre_parcelles": _convertNombreToNumber(_getSelectedOptions(nombreParcelles).isNotEmpty
            ? _getSelectedOptions(nombreParcelles).first
            : "1 parcelle"),
        "surface_moyenne_parcelle_m2": _convertSurfaceToNumber(_getSelectedOptions(surfaceMoyenne).isNotEmpty
            ? _getSelectedOptions(surfaceMoyenne).first
            : "Moins de 500 m²"),
        "objectif_production": _getSelectedOptions(objectifProduction).isNotEmpty
            ? _getSelectedOptions(objectifProduction)
            : [],
      },
      "semences": {
        "varietes_semences": _getSelectedOptions(varietesSemences).isNotEmpty
            ? _getSelectedOptions(varietesSemences)
            : [],
        "provenance_semences": _getSelectedOptions(provenanceSemences).isNotEmpty
            ? _getSelectedOptions(provenanceSemences)
            : [],
        "quantite_semences_kg": _convertQuantiteToNumber(_getSelectedOptions(quantiteSemences).isNotEmpty
            ? _getSelectedOptions(quantiteSemences).first
            : "Moins de 10 kg"),
        "pratique_semis": _getSelectedOptions(pratiqueSemis).isNotEmpty
            ? _getSelectedOptions(pratiqueSemis).join(', ')
            : "Direct",
      },
      "engrais_et_amendements": {
        "utilisation_engrais": utilisationEngrais ?? false,
        "type_engrais": utilisationEngrais == true
            ? (_getSelectedOptions(typeEngrais).isNotEmpty
            ? _getSelectedOptions(typeEngrais)
            : [])
            : [],
        "quantite_engrais_chimique_kg": _convertQuantiteToNumber(_getSelectedOptions(quantiteEngraisChimique).isNotEmpty
            ? _getSelectedOptions(quantiteEngraisChimique).first
            : "Moins de 10 kg"),
        "quantite_engrais_organique_kg": _convertQuantiteOrganiquToNumber(_getSelectedOptions(quantiteEngraisOrganique).isNotEmpty
            ? _getSelectedOptions(quantiteEngraisOrganique).first
            : "Moins de 50 kg"),
        "frequence_engrais": _getSelectedOptions(frequenceEngrais).isNotEmpty
            ? _getSelectedOptions(frequenceEngrais).first
            : "",
        "utilisation_amendements": utilisationAmendements ?? false,
        "amendements": utilisationAmendements == true
            ? (_getSelectedOptions(amendements).isNotEmpty
            ? _getSelectedOptions(amendements)
            : [])
            : [],
      },
      "eau_et_irrigation": {
        "source_eau_principale": _getSelectedOptions(sourcesEau).isNotEmpty
            ? _getSelectedOptions(sourcesEau)
            : [],
        "systeme_irrigation": _getSelectedOptions(systemeIrrigation).isNotEmpty
            ? _getSelectedOptions(systemeIrrigation).join(', ')
            : "",
        "problemes_eau": _getSelectedOptions(problemesEau).isNotEmpty
            ? _getSelectedOptions(problemesEau)
            : [],
      },
      "protection_culture_et_recolte": {
        "ravageurs": _getSelectedOptions(principauxRavageurs).isNotEmpty
            ? _getSelectedOptions(principauxRavageurs)
            : [],
        "utilisation_pesticides": utilisationPesticides ?? false,
        "type_pesticides": utilisationPesticides == true
            ? (_getSelectedOptions(typePesticides).isNotEmpty
            ? _getSelectedOptions(typePesticides)
            : [])
            : [],
        "techniques_naturelles": _getSelectedOptions(techniquesNaturelles).isNotEmpty
            ? _getSelectedOptions(techniquesNaturelles)
            : [],
        "mode_recolte": _getSelectedOptions(modeRecolte).isNotEmpty
            ? _getSelectedOptions(modeRecolte).first
            : "Manuel",
      },
      "production_et_stockage": {
        "rendement_kg": _convertRendementToNumber(_getSelectedOptions(rendement).isNotEmpty
            ? _getSelectedOptions(rendement).first
            : "Moins de 100 kg"),
        "duree_stockage_mois": _convertDureeToNumber(_getSelectedOptions(dureeStockage).isNotEmpty
            ? _getSelectedOptions(dureeStockage).first
            : "Moins de 1 mois"),
        "perte_post_recolte_pourcent": _convertPerteToNumber(_getSelectedOptions(pertePostRecolte).isNotEmpty
            ? _getSelectedOptions(pertePostRecolte).first
            : "Moins de 5%"),
        "mode_stockage": _getSelectedOptions(modeStockage).isNotEmpty
            ? _getSelectedOptions(modeStockage)
            : [],
        "pratique_post_recolte": _getSelectedOptions(pratiqueApresRecolte).isNotEmpty
            ? _getSelectedOptions(pratiqueApresRecolte)
            : [],
      },
      "commercialisation": {
        "vente_riz": vendezVousRiz ?? false,
        "quantite_vendue_kg": vendezVousRiz == true
            ? _convertQuantiteVendueToNumber(_getSelectedOptions(quantiteVendue).isNotEmpty
            ? _getSelectedOptions(quantiteVendue).first
            : "Moins de 50 kg")
            : 0,
        "prix_vente_ar_kg": vendezVousRiz == true
            ? _convertPrixToNumber(_getSelectedOptions(prixVente).isNotEmpty
            ? _getSelectedOptions(prixVente).first
            : "Moins de 1000 Ar/kg")
            : 0,
        "lieu_vente": vendezVousRiz == true
            ? (_getSelectedOptions(lieuVente).isNotEmpty
            ? _getSelectedOptions(lieuVente)
            : [])
            : [],
        "sait_cultiver_riz_hybride": cultivezRizHybride ?? false,
      },
      "diversification_activites": {
        "autres_cultures": _getSelectedOptions(autresCultures).isNotEmpty
            ? _getSelectedOptions(autresCultures)
            : [],
        "elevage": elevage ?? false,
        "nombre_poules": _convertNombreAnimauxToNumber(_getSelectedOptions(nombrePoules).isNotEmpty
            ? _getSelectedOptions(nombrePoules).first
            : "Aucune"),
        "nombre_volailles": _convertNombreAnimauxToNumber(_getSelectedOptions(nombreVolailles).isNotEmpty
            ? _getSelectedOptions(nombreVolailles).first
            : "Aucune"),
        "nombre_boeufs": _convertNombreAnimauxToNumber(_getSelectedOptions(nombreBoeufs).isNotEmpty
            ? _getSelectedOptions(nombreBoeufs).first
            : "Aucun"),
        "nombre_porc": _convertNombreAnimauxToNumber(_getSelectedOptions(nombrePorc).isNotEmpty
            ? _getSelectedOptions(nombrePorc).first
            : "Aucun"),
        "nombre_moutons": _convertNombreAnimauxToNumber(_getSelectedOptions(nombreMoutons).isNotEmpty
            ? _getSelectedOptions(nombreMoutons).first
            : "Aucun"),
        "nombre_chevres": _convertNombreAnimauxToNumber(_getSelectedOptions(nombreChevres).isNotEmpty
            ? _getSelectedOptions(nombreChevres).first
            : "Aucun"),
        "nombre_lapins": _convertNombreAnimauxToNumber(_getSelectedOptions(nombreLapins).isNotEmpty
            ? _getSelectedOptions(nombreLapins).first
            : "Aucun"),
        "pisciculture": pisciculture ?? false,
      },
      "competences_et_formation": {
        "competences_maitrisees": _getSelectedOptions(competencesMaitrisees).isNotEmpty
            ? _getSelectedOptions(competencesMaitrisees)
            : [],
        "mode_formation": _getSelectedOptions(modeFormation).isNotEmpty
            ? _getSelectedOptions(modeFormation)
            : [],
        "competences_interet_formation": _getSelectedOptions(competencesInteret).isNotEmpty
            ? _getSelectedOptions(competencesInteret)
            : [],
      },
      "appui_et_besoins": {
        "appui_social": appuiSocial ?? false,
        "appui_recu": _getSelectedOptions(appuiRecu).isNotEmpty
            ? _getSelectedOptions(appuiRecu)
            : [],
        "besoins_supplementaires": _getSelectedOptions(besoinsSupplementaires).isNotEmpty
            ? _getSelectedOptions(besoinsSupplementaires)
            : [],
      },
    };
  }

// Fonctions de conversion
  int _convertSurfaceToNumber(String surface) {
    if (surface.contains('Moins de 1000')) return 500;
    if (surface.contains('1000-5000')) return 3000;
    if (surface.contains('5001-10000')) return 7500;
    if (surface.contains('10001-20000')) return 15000;
    if (surface.contains('Plus de 20000')) return 25000;
    return 1500;
  }

  int _convertNombreToNumber(String nombre) {
    if (nombre.contains('1 parcelle')) return 1;
    if (nombre.contains('2-3')) return 2;
    if (nombre.contains('4-5')) return 4;
    if (nombre.contains('6-10')) return 8;
    if (nombre.contains('Plus de 10')) return 15;
    return 1;
  }

  int _convertQuantiteToNumber(String quantite) {
    if (quantite.contains('Moins de 10')) return 5;
    if (quantite.contains('10-25')) return 17;
    if (quantite.contains('26-50')) return 38;
    if (quantite.contains('51-100')) return 75;
    if (quantite.contains('Plus de 100')) return 150;
    return 30;
  }

  int _convertQuantiteOrganiquToNumber(String quantite) {
    if (quantite.contains('Moins de 50')) return 25;
    if (quantite.contains('50-100')) return 75;
    if (quantite.contains('101-200')) return 150;
    if (quantite.contains('201-500')) return 350;
    if (quantite.contains('Plus de 500')) return 750;
    return 100;
  }

  int _convertRendementToNumber(String rendement) {
    if (rendement.contains('Moins de 100')) return 50;
    if (rendement.contains('100-500')) return 300;
    if (rendement.contains('501-1000')) return 750;
    if (rendement.contains('1001-2000')) return 1500;
    if (rendement.contains('Plus de 2000')) return 3000;
    return 200;
  }

  int _convertDureeToNumber(String duree) {
    if (duree.contains('Moins de 1')) return 0;
    if (duree.contains('1-3')) return 2;
    if (duree.contains('4-6')) return 5;
    if (duree.contains('7-12')) return 9;
    if (duree.contains('Plus d\'1 an')) return 18;
    return 4;
  }

  int _convertPerteToNumber(String perte) {
    if (perte.contains('Moins de 5')) return 3;
    if (perte.contains('5-10')) return 7;
    if (perte.contains('11-20')) return 15;
    if (perte.contains('21-30')) return 25;
    if (perte.contains('Plus de 30')) return 40;
    return 10;
  }

  int _convertQuantiteVendueToNumber(String quantite) {
    if (quantite.contains('Moins de 50')) return 25;
    if (quantite.contains('50-100')) return 75;
    if (quantite.contains('101-200')) return 150;
    if (quantite.contains('201-500')) return 350;
    if (quantite.contains('Plus de 500')) return 750;
    return 120;
  }

  int _convertPrixToNumber(String prix) {
    if (prix.contains('Moins de 1000')) return 800;
    if (prix.contains('1000-1500')) return 1250;
    if (prix.contains('1501-2000')) return 1750;
    if (prix.contains('2001-2500')) return 2250;
    if (prix.contains('Plus de 2500')) return 3000;
    return 1800;
  }

  int _convertNombreAnimauxToNumber(String nombre) {
    if (nombre.contains('Aucun') || nombre.contains('Aucune')) return 0;
    if (nombre.contains('1-10') || nombre.contains('1-2')) return 5;
    if (nombre.contains('11-20') || nombre.contains('3-5')) return 15;
    if (nombre.contains('21-50') || nombre.contains('6-10')) return 35;
    if (nombre.contains('Plus de 50') || nombre.contains('Plus de 10')) return 75;
    return 0;
  }

  List<String> _getSelectedOptions(Map<String, bool> options) {
    return options.entries.where((entry) => entry.value).map((entry) => entry.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Color(0xFF8E99AB)),
                      SizedBox(width: 8),
                      Text(
                        'Retour liste questionnaire',
                        style: TextStyle(
                          color: Color(0xFF8E99AB),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Color(0xFF003D82),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Questionnaire ${widget.questionnaireNumber}',
                      style: const TextStyle(
                        color: Color(0xFF8E99AB),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenu scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // QUEST 1 - Technique de riziculture
                    _buildSection(
                      'Technique de riziculture',
                      [
                        _buildCheckboxGrid(techniqueRiziculture, 2),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Années d'expérience
                    _buildSection(
                      'Années d\'expérience en riziculture',
                      [
                        _buildCheckboxGrid(anneesExperience, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Surface totale cultivée
                    _buildSection(
                      'Surface totale cultivée en riz',
                      [
                        _buildCheckboxGrid(surfaceTotale, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Nombre de parcelles
                    _buildSection(
                      'Nombre de parcelles',
                      [
                        _buildCheckboxGrid(nombreParcelles, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Surface moyenne parcelle
                    _buildSection(
                      'Surface moyenne d\'une parcelle',
                      [
                        _buildCheckboxGrid(surfaceMoyenne, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Objectif de production
                    _buildSection(
                      'Objectif de production',
                      [
                        _buildCheckboxGrid(objectifProduction, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Variétés de semences
                    _buildSection(
                      'Variété(s) de(s) semence(s)',
                      [
                        _buildCheckboxGrid(varietesSemences, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Quantité de semences
                    _buildSection(
                      'Quantité de semences semées par an',
                      [
                        _buildCheckboxGrid(quantiteSemences, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Provenance des semences
                    _buildSection(
                      'Provenance des semences',
                      [
                        _buildCheckboxGrid(provenanceSemences, 2),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Pratique de semis
                    _buildSection(
                      'Pratique de semis',
                      [
                        _buildCheckboxGrid(pratiqueSemis, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 2 - Utilisation d'engrais
                    _buildSection(
                      'Utilisation d\'engrais',
                      [
                        _buildYesNoRadio(
                          value: utilisationEngrais,
                          onChanged: (val) => setState(() => utilisationEngrais = val),
                        ),
                        if (utilisationEngrais == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Type d\'engrais',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(typeEngrais, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Quantité d\'engrais chimique utilisé',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(quantiteEngraisChimique, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Quantité d\'engrais organique utilisé',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(quantiteEngraisOrganique, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Fréquence d\'application des engrais',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(frequenceEngrais, 3),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 2 - Utilisation d'amendements
                    _buildSection(
                      'Utilisation d\'amendements',
                      [
                        _buildYesNoRadio(
                          value: utilisationAmendements,
                          onChanged: (val) => setState(() => utilisationAmendements = val),
                        ),
                        if (utilisationAmendements == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Types d\'amendements utilisés',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(amendements, 3),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Sources d'eau
                    _buildSection(
                      'Source(s) d\'eau(x) principale(s)',
                      [
                        _buildCheckboxGrid(sourcesEau, 2),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Système d'irrigation
                    _buildSection(
                      'Système d\'irrigation',
                      [
                        _buildCheckboxGrid(systemeIrrigation, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Problèmes d'eau
                    _buildSection(
                      'Problèmes d\'eau rencontrés',
                      [
                        _buildCheckboxGrid(problemesEau, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Principaux ravageurs
                    _buildSection(
                      'Principaux ravageurs rencontrés',
                      [
                        _buildCheckboxGrid(principauxRavageurs, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Utilisation de pesticides
                    _buildSection(
                      'Utilisation de pesticides',
                      [
                        _buildYesNoRadio(
                          value: utilisationPesticides,
                          onChanged: (val) => setState(() => utilisationPesticides = val),
                        ),
                        if (utilisationPesticides == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Type de pesticides',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(typePesticides, 3),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 3 - Techniques naturelles
                    _buildSection(
                      'Techniques naturelles utilisées',
                      [
                        _buildCheckboxGrid(techniquesNaturelles, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Mode de récolte
                    _buildSection(
                      'Mode de récolte',
                      [
                        _buildCheckboxGrid(modeRecolte, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Rendement estimé
                    _buildSection(
                      'Rendement estimé par récolte',
                      [
                        _buildCheckboxGrid(rendement, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Durée de stockage
                    _buildSection(
                      'Durée de stockage moyenne du riz',
                      [
                        _buildCheckboxGrid(dureeStockage, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Perte post récolte
                    _buildSection(
                      'Perte post récolte estimée',
                      [
                        _buildCheckboxGrid(pertePostRecolte, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Mode de stockage
                    _buildSection(
                      'Mode de stockage du riz',
                      [
                        _buildCheckboxGrid(modeStockage, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Pratique après récolte
                    _buildSection(
                      'Pratique après récolte',
                      [
                        _buildCheckboxGrid(pratiqueApresRecolte, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Vendez-vous votre riz
                    _buildSection(
                      'Vendez-vous votre riz ?',
                      [
                        _buildYesNoRadio(
                          value: vendezVousRiz,
                          onChanged: (val) => setState(() => vendezVousRiz = val),
                        ),
                        if (vendezVousRiz == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Quantité moyenne vendue par an',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(quantiteVendue, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Prix moyen de vente',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(prixVente, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Lieu de vente',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(lieuVente, 3),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 4 - Cultivez-vous le riz hybride
                    _buildSection(
                      'Savez-vous cultiver le riz hybride ?',
                      [
                        _buildYesNoRadio(
                          value: cultivezRizHybride,
                          onChanged: (val) => setState(() => cultivezRizHybride = val),
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 5 - Diversification des activités
                    _buildSection(
                      'Diversification des activités',
                      [
                        const Text(
                          'Autres cultures pratiquées',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCheckboxGrid(autresCultures, 3),
                        const SizedBox(height: 16),
                        const Text(
                          'Pratiquez-vous l\'élevage ?',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildYesNoRadio(
                          value: elevage,
                          onChanged: (val) => setState(() => elevage = val),
                        ),
                        if (elevage == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de poules',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombrePoules, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de volailles',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombreVolailles, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de boeufs',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombreBoeufs, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de porcs',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombrePorc, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de moutons',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombreMoutons, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de chèvres',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombreChevres, 3),
                          const SizedBox(height: 16),
                          const Text(
                            'Nombre de lapins',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(nombreLapins, 3),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Pratiquez-vous la pisciculture ?',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildYesNoRadio(
                          value: pisciculture,
                          onChanged: (val) => setState(() => pisciculture = val),
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 6 - Compétences et formation
                    _buildSection(
                      'Compétences et formation',
                      [
                        const Text(
                          'Compétences maîtrisées',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCheckboxGrid(competencesMaitrisees, 3),
                        const SizedBox(height: 16),
                        const Text(
                          'Mode de formation',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCheckboxGrid(modeFormation, 3),
                        const SizedBox(height: 16),
                        const Text(
                          'Compétences d\'intérêt pour la formation',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCheckboxGrid(competencesInteret, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 7 - Appui et besoins
                    _buildSection(
                      'Appui et besoins',
                      [
                        const Text(
                          'Bénéficiez-vous d\'un appui social ?',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildYesNoRadio(
                          value: appuiSocial,
                          onChanged: (val) => setState(() => appuiSocial = val),
                        ),
                        if (appuiSocial == true) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Appui reçu',
                            style: TextStyle(
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCheckboxGrid(appuiRecu, 3),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Besoins supplémentaires',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildCheckboxGrid(besoinsSupplementaires, 3),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Footer avec infos et boutons
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            'Date de l\'enquête : 11/04/2025    Dernière modification le : 12/04/2025    Enquêteur : Razafy Tiana / 12345',
                            style: TextStyle(
                              color: Color(0xFF8E99AB),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.access_time, size: 18),
                                label: const Text('Voir historique de modification'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF333333),
                                  side: const BorderSide(color: Color(0xFF8E99AB)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF8E99AB),
                                  side: const BorderSide(color: Color(0xFF8E99AB)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Annuler'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: () {
                                  // Sauvegarder et retourner avec les données JSON
                                  final jsonData = _generateQuestionnaireData();

                                  print('📤 RETOUR DES DONNÉES QUESTIONNAIRE:');
                                  print('   Type: ${jsonData.runtimeType}');
                                  print('   Keys: ${jsonData.keys.join(', ')}');
                                  print('   Exploitation: ${jsonData['exploitation']}');

                                  // Retourner les données au parent (IMPORTANT: c'est une Map, pas une List)
                                  Navigator.pop(context, {'questionnaire_parcelles': [jsonData]});
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1AB999),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text('Enregistrer'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _buildCheckboxGrid(Map<String, bool> options, int columns) {
    List<Widget> checkboxes = [];
    options.forEach((key, value) {
      checkboxes.add(
        Expanded(
          child: _buildCheckbox(key, value, (val) {
            setState(() {
              options[key] = val ?? false;
            });
          }),
        ),
      );
    });

    List<Widget> rows = [];
    for (int i = 0; i < checkboxes.length; i += columns) {
      int end = (i + columns < checkboxes.length) ? i + columns : checkboxes.length;
      List<Widget> rowChildren = checkboxes.sublist(i, end);

      // Ajouter des spacers si la dernière ligne n'est pas complète
      while (rowChildren.length < columns) {
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        Row(
          children: rowChildren
              .expand((widget) => [widget, if (widget != rowChildren.last) const SizedBox(width: 12)])
              .toList(),
        ),
      );
      if (i + columns < checkboxes.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF1AB999) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? const Color(0xFF1AB999) : const Color(0xFFD0D5DD),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value ? const Color(0xFF1AB999) : const Color(0xFFD0D5DD),
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(
                Icons.check,
                size: 14,
                color: Color(0xFF1AB999),
              )
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: value ? Colors.white : const Color(0xFF8E99AB),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoRadio({required bool? value, required Function(bool?) onChanged}) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => onChanged(true),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: value == true ? const Color(0xFF1AB999) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value == true ? const Color(0xFF1AB999) : const Color(0xFFD0D5DD),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value == true ? Colors.white : const Color(0xFFD0D5DD),
                        width: 2,
                      ),
                    ),
                    child: value == true
                        ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Oui',
                    style: TextStyle(
                      color: value == true ? Colors.white : const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: InkWell(
            onTap: () => onChanged(false),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: value == false ? const Color(0xFF8E99AB) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: value == false ? const Color(0xFF8E99AB) : const Color(0xFFD0D5DD),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: value == false ? Colors.white : const Color(0xFFD0D5DD),
                        width: 2,
                      ),
                    ),
                    child: value == false
                        ? Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Non',
                    style: TextStyle(
                      color: value == false ? Colors.white : const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}