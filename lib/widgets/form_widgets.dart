import 'package:flutter/material.dart';
import 'dart:io';

class FormWidgets {
  // =====================================================================
  // CHAMPS DE TEXTE STANDARD
  // =====================================================================

  static Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1AB999)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // CHAMP DE DATE FONCTIONNEL
  // =====================================================================

  static Widget buildDateField(String label, TextEditingController controller, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1AB999)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[500]),
            hintText: 'JJ/MM/AAAA',
          ),
          readOnly: true,
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              final formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
              controller.text = formattedDate;
            }
          },
        ),
      ],
    );
  }

  // =====================================================================
  // SELECTION DE SEXE (HOMME/FEMME)
  // =====================================================================

  static Widget buildSexeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: controller.text.isEmpty ? null : controller.text,
            decoration: InputDecoration(
              border: InputBorder.none,
            ),
            items: [
              DropdownMenuItem(value: 'Homme', child: Text('Homme')),
              DropdownMenuItem(value: 'Femme', child: Text('Femme')),
            ],
            onChanged: (value) {
              controller.text = value ?? '';
            },
            hint: Text('Sélectionnez le sexe'),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // CHAMP NUMÉRIQUE
  // =====================================================================

  static Widget buildNumberField(
      String label,
      TextEditingController controller, {
        int? minValue,
        int? maxValue,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1AB999)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final numValue = int.tryParse(value);
              if (numValue != null) {
                if (minValue != null && numValue < minValue) {
                  controller.text = minValue.toString();
                } else if (maxValue != null && numValue > maxValue) {
                  controller.text = maxValue.toString();
                }
              }
            }
          },
        ),
      ],
    );
  }

  // =====================================================================
  // CHAMP TÉLÉPHONE AVEC +261
  // =====================================================================

  static Widget buildPhoneField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1AB999)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixText: '+261 ',
            hintText: '32 12 345 67',
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // CHAMP NOMBRE AVEC VIRGULE (LATITUDE/LONGITUDE)
  // =====================================================================

  static Widget buildDecimalField(
      String label,
      TextEditingController controller, {
        String? hintText,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF1AB999)),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            hintText: hintText,
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // BOUTONS RADIO
  // =====================================================================

  static Widget buildRadioButton(
      String title,
      String groupValue,
      Function(String?) onChanged,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == title ? Color(0xFF1AB999) : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
        color: groupValue == title ? Color(0xFF1AB999).withOpacity(0.1) : Colors.white,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: title,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: Color(0xFF1AB999),
          ),
          Text(
            title,
            style: TextStyle(
              color: groupValue == title ? Color(0xFF1AB999) : Colors.grey[700],
              fontWeight: groupValue == title ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // UPLOAD D'IMAGES
  // =====================================================================

  static Widget buildImageUploadField(
      String label,
      String imageType,
      String? imagePath,
      File? imageFile,
      Function(String) onPick,
      Function(String) onRemove,
      String Function(String?) getFileName,
      String Function(File?) getFileSize,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imageFile != null
              ? Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 12, color: Colors.white),
                    onPressed: () => onRemove(imageType),
                  ),
                ),
              ),
            ],
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.grey[400]),
                const SizedBox(height: 4),
                Text(
                  'Ajouter une photo',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (imageFile != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  getFileName(imagePath),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  getFileSize(imageFile),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => onPick(imageType),
            child: Text('Sélectionner une image'),
          ),
        ),
      ],
    );
  }

  // =====================================================================
  // ITEM DE CONTINUE (REMPLACE QUESTIONNAIRE)
  // =====================================================================

  static Widget buildContinueItem(
      int number,
      String title,
      String description,
      bool isLocked, {
        VoidCallback? onTap,
      }) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey[300] : Color(0xFF1AB999),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: isLocked ? Colors.grey[600] : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isLocked ? Colors.grey[500] : Color(0xFF333333),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: isLocked ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (isLocked)
            Icon(Icons.lock_outline, color: Colors.grey[400])
          else
            Icon(Icons.arrow_forward_ios, color: Color(0xFF1AB999), size: 16),
        ],
      ),
    ).addGestureTap(
      onTap: isLocked ? null : onTap,
    );
  }

  // =====================================================================
  // BOUTON DE SOUMISSION
  // =====================================================================

  static Widget buildSubmitButton({
    required String text,
    required VoidCallback onPressed,
    bool isEnabled = true,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1AB999),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // BOUTON SECONDAIRE
  // =====================================================================

  static Widget buildSecondaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Color(0xFF1AB999)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xFF1AB999),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// EXTENSION POUR GESTION DES TAP
// =====================================================================

extension GestureTapExtension on Widget {
  Widget addGestureTap({
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: this,
      ),
    );
  }
}