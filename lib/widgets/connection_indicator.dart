import 'package:flutter/material.dart';
import '../services/connection_service.dart';

class ConnectionIndicator extends StatefulWidget {
  final double? size;
  final bool showText;
  final bool showBackground;
  final VoidCallback? onTap;

  const ConnectionIndicator({
    super.key,
    this.size,
    this.showText = true,
    this.showBackground = true,
    this.onTap,
  });

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  final ConnectionService _connectionService = ConnectionService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _connectionService.connectionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildIndicator(
            'Chargement...',
            Colors.grey,
            Icons.hourglass_empty,
            true,
          );
        }

        if (snapshot.hasError) {
          return _buildIndicator(
            'Erreur',
            Colors.red,
            Icons.error,
            false,
          );
        }

        final data = snapshot.data ?? {};
        final statusText = data['statusText'] ?? 'Inconnu';
        final statusColor = data['statusColor'] ?? Colors.grey;
        final statusIcon = data['statusIcon'] ?? Icons.wifi_off;
        final isChecking = data['isChecking'] ?? false;

        return GestureDetector(
          onTap: widget.onTap ?? () => _showConnectionDetails(context, data),
          child: _buildIndicator(statusText, statusColor, statusIcon, isChecking),
        );
      },
    );
  }

  Widget _buildIndicator(String text, Color color, IconData icon, bool isChecking) {
    return Container(
      padding: widget.showBackground
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
          : EdgeInsets.zero,
      decoration: widget.showBackground
          ? BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isChecking)
            SizedBox(
              width: widget.size ?? 16,
              height: widget.size ?? 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(
              icon,
              size: widget.size ?? 16,
              color: color,
            ),

          if (widget.showText) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: (widget.size ?? 16) - 2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showConnectionDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statut de la connexion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', data['connectionType'].toString().split('.').last),
            _buildDetailRow('Internet', data['hasInternetPlan'] ? 'Disponible' : 'Indisponible'),
            _buildDetailRow('Réseau', data['isMobileData'] ? 'Données mobiles' : 'WiFi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () {
              _connectionService.refreshStatus();
              Navigator.of(context).pop();
            },
            child: const Text('Actualiser'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}