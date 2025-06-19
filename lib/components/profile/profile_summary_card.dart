import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import 'user_profile.dart';
import '../../services/supabase_service.dart';

class ProfileSummaryCard extends StatelessWidget {
  final SupabaseService service = SupabaseService();

  ProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: userProfile.kodGrupy,
      builder: (context, kodGrupy, _) {
        print('DEBUG: ProfileSummaryCard ValueListenableBuilder kodGrupy=$kodGrupy');
        return ValueListenableBuilder<String>(
          valueListenable: userProfile.podgrupa,
          builder: (context, podgrupa, _) {
            print('DEBUG: ProfileSummaryCard ValueListenableBuilder podgrupa=$podgrupa');
            if (kodGrupy.isEmpty) {
              return _summaryBox(context, "-", "-", "-", "-", "-");
            }
            return FutureBuilder<Map<String, dynamic>>(
              future: service.fetchProfileSummary(kodGrupy, podgrupa),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _summaryBox(
                    context,
                    "...",
                    "...",
                    "...",
                    "...",
                    "...",
                  );
                }
                if (snapshot.hasError) {
                  return Text('Błąd: ${snapshot.error}');
                }
                final data = snapshot.data ?? {};
                return _summaryBox(
                  context,
                  data['kierunek'] ?? "-",
                  data['wydzial'] ?? "-",
                  data['group'] ?? "-",
                  data['podgrupa'] ?? "-",
                  data['tryb'] ?? "-",
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _summaryBox(
    BuildContext context,
    String kier,
    String wydz,
    String grupa,
    String pod,
    String tryb,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kCardBorder.withOpacity(0.10), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row(context, "Kierunek", kier),
              _row(context, "Wydział", wydz),
              _row(context, "Grupa", grupa),
              _row(context, "Podgrupa", pod),
              _row(context, "Tryb studiów", tryb),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            "$label:",
            style: AppTextStyles.cardDescription(context)
                .copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: AppTextStyles.cardDescription(context)
                  .copyWith(color: Colors.black54),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}