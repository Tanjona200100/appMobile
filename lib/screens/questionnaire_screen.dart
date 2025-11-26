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
  // Contrôleurs pour les champs texte
  final TextEditingController anneesExperienceController = TextEditingController();
  final TextEditingController surfaceTotaleController = TextEditingController();
  final TextEditingController nombreParcellesController = TextEditingController();
  final TextEditingController surfaceMoyenneController = TextEditingController();
  final TextEditingController varietesSemencesController = TextEditingController();
  final TextEditingController quantiteSemencesController = TextEditingController();
  final TextEditingController quantiteEngraisChimiqueController = TextEditingController();
  final TextEditingController frequenceEngraisController = TextEditingController();
  final TextEditingController amendementsController = TextEditingController();
  final TextEditingController rendementController = TextEditingController();
  final TextEditingController dureeStockageController = TextEditingController();
  final TextEditingController pertePostRecolteController = TextEditingController();
  final TextEditingController quantiteVendueController = TextEditingController();
  final TextEditingController prixVenteController = TextEditingController();

  // États pour les boutons radio
  bool? utilisationEngrais;
  bool? utilisationAmendements;
  bool? utilisationPesticides;
  bool? vendezVousRiz;
  bool? cultivezRizHybride;

  // États pour les checkboxes avec les labels réels
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

  // Fonction pour générer le JSON complet avec la structure exacte de l'exemple
  Map<String, dynamic> _generateCompleteJson() {
    return {
      "individu": {
        "uuid": "indiv-uuid-001",
        "nom": "Nom1",
        "prenom": "Prenom1",
        "surnom": "Rivo",
        "sexe": "M",
        "date_naissance": "1985-07-14",
        "adresse": "Lot II J 54B",
        "gps_point": "18.8792,47.5079",
        "photo": "photo_url_1.jpg",
        "user_id": 1,
        "commune_id": 2,
        "nom_pere": "Randrianarivo Jean",
        "nom_mere": "Razanatsimba Lalao",
        "profession": "Agriculteur",
        "activites_complementaires": "Elevage, artisanat",
        "statut_matrimonial": "Marié",
        "nombre_personnes_a_charge": 4,
        "telephone": "0321234567",
        "cin": {
          "numero": "345678912345",
          "date_delivrance": "2017-09-01",
          "commune_delivrance": "Antananarivo"
        },
        "commune_nom": "Antananarivo",
        "fokontany_nom": "Ankilizato",
        "nombre_enfants": 3,
        "telephone2": "0348765432",
        "lieu_naissance": "Antananarivo"
      },
      "parcelles": [
        {
          "nom": "Parcelle A",
          "superficie": 1500.0,
          "gps": {
            "latitude": -18.879,
            "longitude": 47.5078,
            "altitude": 1280
          },
          "geom": [
            {
              "latitude": -18.879,
              "longitude": 47.5078
            },
            {
              "latitude": -18.87905,
              "longitude": 47.50785
            },
            {
              "latitude": -18.8791,
              "longitude": 47.50775
            },
            {
              "latitude": -18.879,
              "longitude": 47.5078
            }
          ],
          "description": "Rizière en terrasse"
        }
      ],
      "questionnaire_parcelles": [
        {
          "exploitation": {
            "type_contrat": "Propriétaire",
            "technique_riziculture": _getSelectedOptions(techniqueRiziculture).isNotEmpty
                ? _getSelectedOptions(techniqueRiziculture).first
                : "Irriguée",
            "surface_totale_m2": surfaceTotaleController.text.isEmpty
                ? 1500
                : double.tryParse(surfaceTotaleController.text)?.toInt(),
            "nombre_parcelles": nombreParcellesController.text.isEmpty
                ? 1
                : int.tryParse(nombreParcellesController.text),
            "surface_moyenne_parcelle_m2": surfaceMoyenneController.text.isEmpty
                ? 1500
                : double.tryParse(surfaceMoyenneController.text)?.toInt(),
            "objectif_production": _getSelectedOptions(objectifProduction).isNotEmpty
                ? _getSelectedOptions(objectifProduction)
                : ["Autoconsommation", "Vente locale"],
          },
          "semences": {
            "varietes_semences": varietesSemencesController.text.isEmpty
                ? ["X123", "Y456"]
                : varietesSemencesController.text.split(',').map((e) => e.trim()).toList(),
            "provenance_semences": _getSelectedOptions(provenanceSemences).isNotEmpty
                ? _getSelectedOptions(provenanceSemences)
                : ["Production propre", "Achat local"],
            "quantite_semences_kg": quantiteSemencesController.text.isEmpty
                ? 30
                : double.tryParse(quantiteSemencesController.text)?.toInt(),
            "pratique_semis": _getSelectedOptions(pratiqueSemis).isNotEmpty
                ? _getSelectedOptions(pratiqueSemis).first
                : "Direct",
          },
          "engrais_et_amendements": {
            "utilisation_engrais": utilisationEngrais ?? true,
            "type_engrais": utilisationEngrais == true
                ? (_getSelectedOptions(typeEngrais).isNotEmpty
                ? _getSelectedOptions(typeEngrais)
                : ["Chimique", "Organique"])
                : null,
            "quantite_engrais_chimique_kg": quantiteEngraisChimiqueController.text.isEmpty
                ? 25
                : double.tryParse(quantiteEngraisChimiqueController.text)?.toInt(),
            "quantite_engrais_organique_kg": 100, // Valeur par défaut de l'exemple
            "frequence_engrais": frequenceEngraisController.text.isEmpty
                ? "1 par mois"
                : frequenceEngraisController.text,
            "utilisation_amendements": utilisationAmendements ?? true,
            "amendements": utilisationAmendements == true
                ? (amendementsController.text.isEmpty
                ? ["Fumier", "Cendre"]
                : amendementsController.text.split(',').map((e) => e.trim()).toList())
                : null,
          },
          "eau_et_irrigation": {
            "source_eau_principale": _getSelectedOptions(sourcesEau).isNotEmpty
                ? _getSelectedOptions(sourcesEau)
                : ["Canal", "Pluie"],
            "systeme_irrigation": _getSelectedOptions(systemeIrrigation).isNotEmpty
                ? _getSelectedOptions(systemeIrrigation).first
                : "Par gravité",
            "problemes_eau": _getSelectedOptions(problemesEau).isNotEmpty
                ? _getSelectedOptions(problemesEau)
                : ["Sécheresse"],
          },
          "protection_culture_et_recolte": {
            "ravageurs": _getSelectedOptions(principauxRavageurs).isNotEmpty
                ? _getSelectedOptions(principauxRavageurs)
                : ["Insectes", "Rongeurs"],
            "utilisation_pesticides": utilisationPesticides ?? true,
            "type_pesticides": utilisationPesticides == true
                ? (_getSelectedOptions(typePesticides).isNotEmpty
                ? _getSelectedOptions(typePesticides)
                : ["Chimique"])
                : null,
            "techniques_naturelles": _getSelectedOptions(techniquesNaturelles).isNotEmpty
                ? _getSelectedOptions(techniquesNaturelles)
                : ["Rotation des cultures"],
            "mode_recolte": _getSelectedOptions(modeRecolte).isNotEmpty
                ? _getSelectedOptions(modeRecolte).first
                : "Manuel",
          },
          "production_et_stockage": {
            "rendement_kg": rendementController.text.isEmpty
                ? 200
                : double.tryParse(rendementController.text)?.toInt(),
            "duree_stockage_mois": dureeStockageController.text.isEmpty
                ? 4
                : int.tryParse(dureeStockageController.text),
            "perte_post_recolte_pourcent": pertePostRecolteController.text.isEmpty
                ? 10
                : double.tryParse(pertePostRecolteController.text)?.toInt(),
            "mode_stockage": _getSelectedOptions(modeStockage).isNotEmpty
                ? _getSelectedOptions(modeStockage)
                : ["Grenier"],
            "pratique_post_recolte": _getSelectedOptions(pratiqueApresRecolte).isNotEmpty
                ? _getSelectedOptions(pratiqueApresRecolte)
                : ["Nouvelle culture"],
          },
          "commercialisation": {
            "vente_riz": vendezVousRiz ?? true,
            "quantite_vendue_kg": vendezVousRiz == true
                ? (quantiteVendueController.text.isEmpty
                ? 120
                : double.tryParse(quantiteVendueController.text)?.toInt())
                : null,
            "prix_vente_ar_kg": vendezVousRiz == true
                ? (prixVenteController.text.isEmpty
                ? 1800
                : double.tryParse(prixVenteController.text)?.toInt())
                : null,
            "lieu_vente": vendezVousRiz == true
                ? (_getSelectedOptions(lieuVente).isNotEmpty
                ? _getSelectedOptions(lieuVente)
                : ["Marché local"])
                : null,
            "sait_cultiver_riz_hybride": cultivezRizHybride ?? true,
          },
          "diversification_activites": {
            "autres_cultures": ["Haricot", "Maïs"],
            "elevage": true,
            "nombre_poules": 20,
            "nombre_volailles": 5,
            "nombre_boeufs": 2,
            "nombre_porc": 0,
            "nombre_moutons": 1,
            "nombre_chevres": 3,
            "nombre_lapins": 0,
            "pisciculture": false
          },
          "competences_et_formation": {
            "competences_maitrisees": ["Agroécologie", "Agriculture durable"],
            "mode_formation": ["Formation en groupement"],
            "competences_interet_formation": ["Gestion de ferme"]
          },
          "appui_et_besoins": {
            "appui_social": true,
            "appui_recu": ["Carte producteur", "Subvention engrais"],
            "besoins_supplementaires": ["Matériel", "Financement"]
          }
        }
      ]
    };
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

                    // QUEST 1 - Années d'expérience et Surface totale
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Années d\'expérience en riziculture',
                                controller: anneesExperienceController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Surface totale cultivée en riz en m² (approximatif)',
                                controller: surfaceTotaleController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // QUEST 1 - Nombre de parcelles et Surface moyenne
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Nombre de parcelles',
                                controller: nombreParcellesController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Surface moyenne d\'une parcelle en m²',
                                controller: surfaceMoyenneController,
                              ),
                            ),
                          ],
                        ),
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

                    // QUEST 1 - Variétés et Quantité de semences
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Variété(s) de(s) semence(s)',
                                controller: varietesSemencesController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Quantité de semences semées par an (kg)',
                                controller: quantiteSemencesController,
                              ),
                            ),
                          ],
                        ),
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Quantité d\'engrais chimique utilisé pour les cultures (kg)',
                                  controller: quantiteEngraisChimiqueController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  'Fréquence d\'application des engrais',
                                  controller: frequenceEngraisController,
                                ),
                              ),
                            ],
                          ),
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
                          _buildTextField(
                            'Quels amendements ? (chaux, compost, cendres, etc)',
                            controller: amendementsController,
                          ),
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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Rendement estimé par récolte (kg)',
                                controller: rendementController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Durée de stockage moyenne du riz (mois)',
                                controller: dureeStockageController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Perte post récolte estimée (%)',
                                controller: pertePostRecolteController,
                              ),
                            ),
                          ],
                        ),
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
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  'Quantité moyenne vendue par an (kg)',
                                  controller: quantiteVendueController,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  'Prix moyen de vente (Ar/kg)',
                                  controller: prixVenteController,
                                ),
                              ),
                            ],
                          ),
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
                                  // Sauvegarder et retourner avec les données JSON complètes
                                  final completeJsonData = _generateCompleteJson();
                                  print('Données complètes du questionnaire: ${completeJsonData}');

                                  // Retourner les données au parent
                                  Navigator.pop(context, completeJsonData);
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

  Widget _buildTextField(String label, {required TextEditingController controller}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF333333),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1AB999), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
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