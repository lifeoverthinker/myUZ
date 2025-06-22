import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../theme/fonts.dart';
import '../profile/user_profile.dart';
import '../profile/group_profile.dart';
import '../../services/supabase_service.dart';
import '../../my_uz_icons.dart';

class GroupsSection extends StatefulWidget {
  const GroupsSection({super.key});

  @override
  State<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends State<GroupsSection> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPanelBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(top: 8, left: 0, right: 0, bottom: 0),
          child: IconButton(
            icon: const Icon(
              MyUzIcons.chevron_left,
              color: Color(0xFF1D192B),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Wróć',
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Grupy',
            style: AppTextStyles.sectionHeader(context).copyWith(fontSize: 20),
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 16),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: kCardPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  MyUzIcons.plus,
                  color: Color(0xFF1D192B),
                  size: 24,
                ),
                onPressed: () => _showAddGroupDialog(context),
                splashRadius: 24,
                padding: const EdgeInsets.all(8),
                tooltip: 'Dodaj grupę',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder<List<GroupProfile>>(
            valueListenable: userProfile.grupy,
            builder: (context, groups, _) {
              if (groups.isEmpty) {
                return Center(
                  child: Text(
                    'Brak grup. Dodaj pierwszą grupę!',
                    style: AppTextStyles.cardDescription(context),
                  ),
                );
              }
              return ListView.separated(
                itemCount: groups.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final group = groups[idx];
                  final colorIdx = idx % kMaterialPalette.length;
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: kMaterialPalette[colorIdx]
                              .withOpacity(0.35),
                          child: Icon(
                            MyUzIcons.users,
                            color: kAvatarZajecia,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '${group.kodGrupy}${group.podgrupa.isNotEmpty ? '/${group.podgrupa}' : ''}',
                                    style: AppTextStyles.cardTitle(
                                      context,
                                    ).copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: kMainText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: kMaterialPalette[colorIdx],
                                      border: Border.all(
                                        color: kActionAccent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${group.kierunek} • ${group.trybStudiow}',
                                style: AppTextStyles.cardDescription(context),
                              ),
                              Text(
                                group.wydzial,
                                style: AppTextStyles.cardDescription(
                                  context,
                                ).copyWith(color: kGreyText, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            MyUzIcons.trash,
                            color: kCardRed,
                            size: 22,
                          ),
                          tooltip: 'Usuń grupę',
                          onPressed:
                              () => _showDeleteGroupDialog(context, group),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final kodCtrl = TextEditingController();
    final podCtrl = TextEditingController();
    final subSuggestions = ValueNotifier<List<String>>([]);
    final podEnabled = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder:
                (context, setModalState) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  title: Text(
                    'Dodaj grupę',
                    style: AppTextStyles.cardTitle(
                      context,
                    ).copyWith(fontSize: 18, color: kMainText),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (val) async {
                          if (val.text.isEmpty) {
                            setModalState(() {
                              subSuggestions.value = [];
                              podEnabled.value = false;
                              podCtrl.clear();
                            });
                            return const Iterable<String>.empty();
                          }
                          final list = await _supabaseService
                              .fetchGroupSuggestions(val.text);
                          return list
                              .map((e) => e['kod_grupy'] as String)
                              .take(4);
                        },
                        fieldViewBuilder: (ctx, textController, focusNode, _) {
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: 'Kod grupy',
                              floatingLabelStyle: TextStyle(
                                color: kActionAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kActionAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          );
                        },
                        onSelected: (val) async {
                          kodCtrl.text = val;
                          final subs = await _supabaseService
                              .fetchPodgrupyForGroup(val);
                          setModalState(() {
                            subSuggestions.value = subs.cast<String>();
                            podEnabled.value = subs.isNotEmpty;
                            if (!podEnabled.value) podCtrl.clear();
                          });
                        },
                        optionsViewBuilder: (ctx, onSelected, options) {
                          final items = options.toList();
                          final maxItems = 4;
                          final itemHeight = 48.0;
                          final visibleCount = items.length.clamp(0, maxItems);
                          final height = visibleCount * itemHeight;
                          final width = MediaQuery.of(context).size.width * 0.7;
                          return Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: height,
                                  minWidth: width,
                                  maxWidth: width,
                                ),
                                child: ListView(
                                  shrinkWrap: true,
                                  physics: const ClampingScrollPhysics(),
                                  children:
                                      items
                                          .take(maxItems)
                                          .map(
                                            (opt) => ListTile(
                                              title: Text(
                                                opt,
                                                style:
                                                    AppTextStyles.cardDescription(
                                                      context,
                                                    ),
                                              ),
                                              onTap: () => onSelected(opt),
                                            ),
                                          )
                                          .toList(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Autocomplete<String>(
                        optionsBuilder:
                            (val) =>
                                podEnabled.value
                                    ? subSuggestions.value.where(
                                      (s) =>
                                          val.text.isEmpty
                                              ? true
                                              : s.toLowerCase().contains(
                                                val.text.toLowerCase(),
                                              ),
                                    )
                                    : const Iterable<String>.empty(),
                        fieldViewBuilder: (ctx, textController, focusNode, _) {
                          return TextField(
                            controller: textController,
                            focusNode: focusNode,
                            enabled: podEnabled.value,
                            decoration: InputDecoration(
                              labelText:
                                  podEnabled.value
                                      ? 'Podgrupa'
                                      : 'Brak podgrup',
                              floatingLabelStyle: TextStyle(
                                color: kActionAccent,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: kActionAccent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          );
                        },
                        onSelected: (val) => podCtrl.text = val,
                        optionsViewBuilder: (ctx, onSelected, options) {
                          final items = options.toList();
                          final maxItems = 4;
                          final itemHeight = 48.0;
                          final visibleCount = items.length.clamp(0, maxItems);
                          final height = visibleCount * itemHeight;
                          final width = MediaQuery.of(ctx).size.width * 0.7;
                          return podEnabled.value && items.isNotEmpty
                              ? Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxHeight: height,
                                      minWidth: width,
                                      maxWidth: width,
                                    ),
                                    child: ListView(
                                      shrinkWrap: true,
                                      physics: const ClampingScrollPhysics(),
                                      children:
                                          items
                                              .take(maxItems)
                                              .map(
                                                (opt) => ListTile(
                                                  title: Text(
                                                    opt,
                                                    style:
                                                        AppTextStyles.cardDescription(
                                                          context,
                                                        ),
                                                  ),
                                                  onTap: () => onSelected(opt),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ),
                                ),
                              )
                              : const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  actions: [
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: kGreyText,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Anuluj',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (kodCtrl.text.isNotEmpty) {
                                await userProfile.addGroup(
                                  kodCtrl.text,
                                  podEnabled.value ? podCtrl.text : null,
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  setState(() {});
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kActionAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            child: const Text('Dodaj'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
          ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, GroupProfile group) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            title: Text(
              'Usuń grupę',
              style: AppTextStyles.cardTitle(context).copyWith(fontSize: 18),
            ),
            content: Text(
              'Czy na pewno chcesz usunąć grupę ${group.kodGrupy}/${group.podgrupa}?',
              style: AppTextStyles.cardDescription(context),
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: kGreyText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Anuluj',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await userProfile.removeGroup(
                          group.kodGrupy,
                          group.podgrupa,
                        );
                        if (context.mounted) Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kCardRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Usuń', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );
  }
}
