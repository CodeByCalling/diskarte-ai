import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActionChipBar extends StatelessWidget {
  final String messageText;
  final VoidCallback? onTranslateToBisaya;
  final VoidCallback? onMakeFormal;

  const ActionChipBar({
    super.key,
    required this.messageText,
    this.onTranslateToBisaya,
    this.onMakeFormal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        children: [
          _buildChip(
            context,
            icon: Icons.copy,
            label: 'Copy',
            onTap: () {
              Clipboard.setData(ClipboardData(text: messageText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          if (onMakeFormal != null)
            _buildChip(
              context,
              icon: Icons.business_center,
              label: 'Gawing Formal',
              onTap: onMakeFormal,
            ),
          if (onTranslateToBisaya != null)
            _buildChip(
              context,
              icon: Icons.translate,
              label: 'Translate to Bisaya',
              onTap: onTranslateToBisaya,
            ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: const Color(0xFF002D72)),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF002D72)),
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFF002D72), width: 1),
      onPressed: onTap,
    );
  }
}
