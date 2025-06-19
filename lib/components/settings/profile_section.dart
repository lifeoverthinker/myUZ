import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../profile/user_profile.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userProfile.initialsNotifier,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kAccent.withOpacity(0.12),
                child: const Icon(Icons.person, color: kAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imię i nazwisko',
                      style: AppTextStyles.cardDescription(
                        context,
                      ).copyWith(color: kSecondaryText, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userProfile.fullName,
                      style: AppTextStyles.cardTitle(
                        context,
                      ).copyWith(fontSize: 16, color: kMainText),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: kAccent),
                tooltip: 'Edytuj imię i nazwisko',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final controller = TextEditingController(
                        text: userProfile.fullName,
                      );
                      return AlertDialog(
                        backgroundColor: kWhite,
                        title: const Text('Edytuj imię i nazwisko'),
                        content: TextField(
                          controller: controller,
                          style: const TextStyle(color: kMainText),
                          decoration: InputDecoration(
                            labelText: 'Imię i nazwisko',
                            labelStyle: const TextStyle(color: kSecondaryText),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Anuluj',
                              style: TextStyle(color: kAccent),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await userProfile.updateName(controller.text);
                              userProfile.initialsNotifier.value =
                                  userProfile.initials;
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            },
                            child: const Text('Zapisz'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
