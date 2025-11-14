import 'package:flutter/material.dart';

class ContinueScreen extends StatefulWidget {
  final String title;
  final int continueNumber;

  const ContinueScreen({
    Key? key,
    required this.title,
    required this.continueNumber,
  }) : super(key: key);

  @override
  State<ContinueScreen> createState() => _ContinueScreenState();
}

class _ContinueScreenState extends State<ContinueScreen> {
  // États pour suivre les sections dépliées
  final Map<String, bool> _expandedSections = {
    'technique_riziculture': false,
    'experience_surface': false,
    'objectif_production': false,
    'varietes_semences': false,
    'provenance_semences': false,
    'pratique_semis': false,
    'utilisation_engrais': false,
    'utilisation_amendements': false,
    'sources_eau': false,
    'systeme_irrigation': false,
    'problemes_eau': false,
    'ravageurs': false,
    'utilisation_pesticides': false,
    'techniques_naturelles': false,
    'mode_recolte': false,
    'mode_stockage': false,
    'pratique_apres_recolte': false,
    'vente_riz': false,
    'riz_hybride': false,
  };

  // États pour les réponses
  bool? utilisationEngrais;
  bool? utilisationAmendements;
  bool? utilisationPesticides;
  bool? vendezVousRiz;
  bool? cultivezRizHybride;

  // États pour les checkboxes
  Map<String, bool> techniqueRiziculture = {
    'Riziculture pluviale': false,
    'Riziculture irriguée': true,
    'Riziculture de bas-fond': false,
    'Riziculture de plateau': true,
    'Autre': false,
  };

  Map<String, bool> objectifProduction = {
    'Autoconsommation': true,
    'Vente sur le marché local': false,
    'Vente aux collecteurs': false,
    'Transformation': false,
    'Semencier': false,
  };

  // [Le reste des états reste identique à votre code original...]

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
                        'Retour',
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
                      'Questionnaire ${widget.continueNumber}',
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
                    // Section dépliable - Technique de riziculture
                    _buildExpandableSection(
                      key: 'technique_riziculture',
                      title: 'Technique de riziculture',
                      content: [
                        _buildCheckboxGrid(techniqueRiziculture, 2),
                      ],
                    ),

                    const Divider(height: 1),

                    // Section dépliable - Expérience et surface
                    _buildExpandableSection(
                      key: 'experience_surface',
                      title: 'Expérience et surface',
                      content: [
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
                        const SizedBox(height: 16),
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

                    const Divider(height: 1),

                    // Section dépliable - Objectif de production
                    _buildExpandableSection(
                      key: 'objectif_production',
                      title: 'Objectif de production',
                      content: [
                        _buildCheckboxGrid(objectifProduction, 3),
                      ],
                    ),

                    const Divider(height: 1),

                    // Section dépliable - Variétés et semences
                    _buildExpandableSection(
                      key: 'varietes_semences',
                      title: 'Variétés et semences',
                      content: [
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

                    const Divider(height: 1),

                    // Section dépliable - Utilisation d'engrais
                    _buildExpandableSection(
                      key: 'utilisation_engrais',
                      title: 'Utilisation d\'engrais',
                      content: [
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
                          _buildCheckboxGrid({
                            'Chimique': false,
                            'Organique': false,
                            'Les deux': false,
                          }, 3),
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

                    // [Ajouter les autres sections dépliables de la même manière...]

                    const SizedBox(height: 32),

                    // Footer avec boutons
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
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

  Widget _buildExpandableSection({
    required String key,
    required String title,
    required List<Widget> content,
  }) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // En-tête de section cliquable
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF8E99AB),
            ),
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),

          // Contenu de la section (affiché seulement si déplié)
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content,
              ),
            ),
        ],
      ),
    );
  }

  // [Les méthodes _buildTextField, _buildCheckboxGrid, _buildCheckbox, _buildYesNoRadio
  // restent identiques à votre code original]
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