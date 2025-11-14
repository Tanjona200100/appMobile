import 'package:flutter/material.dart';

/// Classe pour gérer tous les contrôleurs de texte du formulaire
class FormControllers {
  // Contrôleurs IDENTITÉ
  final TextEditingController nom = TextEditingController();
  final TextEditingController prenom = TextEditingController();
  final TextEditingController surnom = TextEditingController();
  final TextEditingController sexe = TextEditingController();
  final TextEditingController dateNaissance = TextEditingController();
  final TextEditingController lieuNaissance = TextEditingController();
  final TextEditingController statutMatrimonial = TextEditingController();
  final TextEditingController nombreEnfants = TextEditingController();
  final TextEditingController nombrePersonnesCharge = TextEditingController();
  final TextEditingController nomPere = TextEditingController();
  final TextEditingController nomMere = TextEditingController();
  final TextEditingController metier = TextEditingController();
  final TextEditingController activitesComplementaires = TextEditingController();
  final TextEditingController adresse = TextEditingController();
  final TextEditingController region = TextEditingController();
  final TextEditingController commune = TextEditingController();
  final TextEditingController fokontany = TextEditingController();
  final TextEditingController telephone1 = TextEditingController();
  final TextEditingController telephone2 = TextEditingController();
  final TextEditingController numeroCIN = TextEditingController();
  final TextEditingController dateDelivrance = TextEditingController();

  // Contrôleurs PARCELLE
  final TextEditingController latitude = TextEditingController();
  final TextEditingController longitude = TextEditingController();
  final TextEditingController altitude = TextEditingController();
  final TextEditingController precision = TextEditingController();

  /// Disposer tous les contrôleurs
  void dispose() {
    nom.dispose();
    prenom.dispose();
    surnom.dispose();
    sexe.dispose();
    dateNaissance.dispose();
    lieuNaissance.dispose();
    statutMatrimonial.dispose();
    nombreEnfants.dispose();
    nombrePersonnesCharge.dispose();
    nomPere.dispose();
    nomMere.dispose();
    metier.dispose();
    activitesComplementaires.dispose();
    adresse.dispose();
    region.dispose();
    commune.dispose();
    fokontany.dispose();
    telephone1.dispose();
    telephone2.dispose();
    numeroCIN.dispose();
    dateDelivrance.dispose();
    latitude.dispose();
    longitude.dispose();
    altitude.dispose();
    precision.dispose();
  }

  /// Réinitialiser tous les contrôleurs
  void clear() {
    nom.clear();
    prenom.clear();
    surnom.clear();
    sexe.clear();
    dateNaissance.clear();
    lieuNaissance.clear();
    statutMatrimonial.clear();
    nombreEnfants.clear();
    nombrePersonnesCharge.clear();
    nomPere.clear();
    nomMere.clear();
    metier.clear();
    activitesComplementaires.clear();
    adresse.clear();
    region.clear();
    commune.clear();
    fokontany.clear();
    telephone1.clear();
    telephone2.clear();
    numeroCIN.clear();
    dateDelivrance.clear();
    latitude.clear();
    longitude.clear();
    altitude.clear();
    precision.clear();
  }

  /// Valider les champs obligatoires
  bool validate() {
    return nom.text.isNotEmpty && prenom.text.isNotEmpty;
  }
}