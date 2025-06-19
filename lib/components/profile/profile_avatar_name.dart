import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import 'user_profile.dart' show userProfile;

class ProfileAvatarName extends StatelessWidget {
  final String userName;

  const ProfileAvatarName({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ValueListenableBuilder<String>(
          valueListenable: userProfile.initialsNotifier,
          builder: (context, initials, _) {
            return Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6750A4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6750A4).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: AppTextStyles.profileInitials(context).copyWith(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(
          userName,
          style: AppTextStyles.profileName(context).copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kMainText,
          ),
        ),
      ],
    );
  }
}
