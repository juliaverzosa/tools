import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RecentCheckTile extends StatelessWidget {
  final String time;
  final String when;
  final String technicianName;
  final String checkedBy;

  const RecentCheckTile({
    super.key,
    required this.time,
    required this.when,
    required this.technicianName,
    required this.checkedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // left column: time / when
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            Text(when, style: GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
          ],
        ),
        const SizedBox(width: 12),
        // vertical divider
        Container(width: 1, height: 36, color: const Color(0xFF2A56A8)),
        const SizedBox(width: 12),
        // name and who checked
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(technicianName, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Checked by: $checkedBy', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
