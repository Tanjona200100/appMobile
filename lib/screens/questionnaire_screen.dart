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

  // États pour les checkboxes
  Map<String, bool> techniqueRiziculture = {
    'Option 1': false,
    'Option 2': true,
    'Option 3': false,
    'Option 4': true,
    'Option 5': true,
  };

  Map<String, bool> objectifProduction = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
    'Option 4': false,
    'Option 5': false,
  };

  Map<String, bool> provenanceSemences = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
    'Option 4': false,
  };

  Map<String, bool> pratiqueSemis = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> typeEngrais = {
    'Chimique': false,
    'Organique': false,
    'Les deux': false,
  };

  Map<String, bool> sourcesEau = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
    'Option 4': false,
  };

  Map<String, bool> systemeIrrigation = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> problemesEau = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> principauxRavageurs = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> typePesticides = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> techniquesNaturelles = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> modeRecolte = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> modeStockage = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> pratiqueApresRecolte = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

  Map<String, bool> lieuVente = {
    'Option 1': false,
    'Option 2': false,
    'Option 3': false,
  };

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
                    // Technique de riziculture
                    _buildSection(
                      'Technique de riziculture',
                      [
                        _buildCheckboxGrid(techniqueRiziculture, 2),
                      ],
                    ),

                    const Divider(height: 48),

                    // Années d'expérience et Surface totale
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                'Années d\'expérience en riziculture',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Surface totale cultivée en riz en m² (approximatif)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // Nombre de parcelles et Surface moyenne
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('Nombre de parcelles'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Surface moyenne d\'une parcelle en m²',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // Objectif de production
                    _buildSection(
                      'Objectif de production',
                      [
                        _buildCheckboxGrid(objectifProduction, 4),
                      ],
                    ),

                    const Divider(height: 48),

                    // Variétés et Quantité de semences
                    _buildSection(
                      '',
                      [
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField('Variété(s) de(s) semence(s)'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Quantité de semences semées par an (kg)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // Provenance des semences
                    _buildSection(
                      'Provenance des semences',
                      [
                        _buildCheckboxGrid(provenanceSemences, 4),
                      ],
                    ),

                    const Divider(height: 48),

                    // Pratique de semis
                    _buildSection(
                      'Pratique de semis',
                      [
                        _buildCheckboxGrid(pratiqueSemis, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Utilisation d'engrais
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
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  'Fréquence d\'application des engrais',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // Utilisation d'amendements
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
                          ),
                        ],
                      ],
                    ),

                    const Divider(height: 48),

                    // Sources d'eau
                    _buildSection(
                      'Source(s) d\'eau(x) principale(s)',
                      [
                        _buildCheckboxGrid(sourcesEau, 4),
                      ],
                    ),

                    const Divider(height: 48),

                    // Système d'irrigation
                    _buildSection(
                      'Système d\'irrigation',
                      [
                        _buildCheckboxGrid(systemeIrrigation, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Problèmes d'eau
                    _buildSection(
                      'Problèmes d\'eau rencontrés',
                      [
                        _buildCheckboxGrid(problemesEau, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Principaux ravageurs
                    _buildSection(
                      'Principaux ravageurs rencontrés',
                      [
                        _buildCheckboxGrid(principauxRavageurs, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Utilisation de pesticides
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

                    // Techniques naturelles
                    _buildSection(
                      'Techniques naturelles utilisées',
                      [
                        _buildCheckboxGrid(techniquesNaturelles, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Mode de récolte
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
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Durée de stockage moyenne du riz (mois)',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                'Perte post récolte estimée (%)',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Divider(height: 48),

                    // Mode de stockage
                    _buildSection(
                      'Mode de stockage du riz',
                      [
                        _buildCheckboxGrid(modeStockage, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Pratique après récolte
                    _buildSection(
                      'Pratique après récolte',
                      [
                        _buildCheckboxGrid(pratiqueApresRecolte, 3),
                      ],
                    ),

                    const Divider(height: 48),

                    // Vendez-vous votre riz
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
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTextField(
                                  'Prix moyen de vente (Ar/kg)',
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

                    // Cultivez-vous le riz hybride
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
                                  // Sauvegarder et retourner
                                  Navigator.pop(context);
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

  Widget _buildTextField(String label) {
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