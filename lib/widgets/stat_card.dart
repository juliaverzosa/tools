import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isPercent;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.isPercent = false,
  });

  @override
  Widget build(BuildContext context) {
    // simple gradient and rounded style
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B54A6), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0,4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28)),
          if (isPercent) ...[
            const SizedBox(height: 4),
            Text('of tools OK', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
