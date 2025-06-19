import 'package:flutter/material.dart';
import '../../theme/fonts.dart';
import '../../theme/theme.dart';
import '../profile/user_profile.dart';
import '../profile/group_profile.dart';
import '../../services/supabase_service.dart';

class GroupsSection extends StatefulWidget {
  const GroupsSection({super.key});

  @override
  State<GroupsSection> createState() => _GroupsSectionState();
}

class _GroupsSectionState extends State<GroupsSection> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kCardPurple,
              child: const Icon(Icons.group, color: kMainText, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grupy',
                    style: AppTextStyles.cardDescription(
                      context,
                    ).copyWith(color: kMainText.withOpacity(0.7), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<List<GroupProfile>>(
                    valueListenable: userProfile.grupy,
                    builder: (context, groups, _) {
                      return Text(
                        '${groups.length} grup',
                        style: AppTextStyles.cardTitle(
                          context,
                        ).copyWith(fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, color: kMainText),
              onPressed: () => _showAddGroupDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<GroupProfile>>(
          valueListenable: userProfile.grupy,
          builder: (context, groups, _) {
            return Column(
              children:
                  groups.map((group) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: kCardPurple,
                            child: const Icon(
                              Icons.group,
                              color: kMainText,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${group.kodGrupy}/${group.podgrupa}',
                                  style: AppTextStyles.cardTitle(
                                    context,
                                  ).copyWith(fontSize: 15),
                                ),
                                Text(
                                  '${group.kierunek} - ${group.trybStudiow}',
                                  style: AppTextStyles.cardDescription(context),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: kMainText),
                            onPressed:
                                () => _showDeleteGroupDialog(context, group),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final TextEditingController kodGrupyController = TextEditingController();
    final TextEditingController podgrupaController = TextEditingController();
    final ValueNotifier<List<String>> groupSuggestions =
        ValueNotifier<List<String>>([]);
    final ValueNotifier<List<String>> subgroupSuggestions =
        ValueNotifier<List<String>>([]);
    final ValueNotifier<bool> podgrupaEnabled = ValueNotifier(true);

    void updateGroupSuggestions(String query) async {
      if (query.isEmpty) {
        groupSuggestions.value = [];
        subgroupSuggestions.value = [];
        podgrupaEnabled.value = true;
        return;
      }

      final results = await _supabaseService.fetchGroupSuggestions(query);
      groupSuggestions.value = results.map((r) => '${r['kod_grupy']}').toList();
    }

    void loadSubgroupsForSelectedGroup(String kodGrupy) async {
      if (kodGrupy.isEmpty) {
        subgroupSuggestions.value = [];
        podgrupaEnabled.value = true;
        return;
      }

      final results = await _supabaseService.fetchPodgrupyForGroup(kodGrupy);
      subgroupSuggestions.value = results;
      podgrupaEnabled.value = results.isNotEmpty;
      if (results.isEmpty) {
        podgrupaController.text = '';
      }
    }

    void updateSubgroupSuggestions(String query) async {
      if (kodGrupyController.text.isEmpty) {
        subgroupSuggestions.value = [];
        podgrupaEnabled.value = true;
        return;
      }

      final allSubgroups = await _supabaseService.fetchPodgrupyForGroup(
        kodGrupyController.text,
      );
      podgrupaEnabled.value = allSubgroups.isNotEmpty;
      if (allSubgroups.isEmpty) {
        subgroupSuggestions.value = [];
        podgrupaController.text = '';
        return;
      }

      if (query.isEmpty) {
        subgroupSuggestions.value = allSubgroups;
      } else {
        subgroupSuggestions.value =
            allSubgroups
                .where((sub) => sub.toLowerCase().contains(query.toLowerCase()))
                .toList();
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => Dialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 420,
                      maxWidth: 360,
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dodaj grupę',
                              style: AppTextStyles.cardTitle(context),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: kodGrupyController,
                              decoration: InputDecoration(
                                labelText: 'Kod grupy',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onChanged: (val) {
                                updateGroupSuggestions(val);
                                setStateDialog(() {});
                              },
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<List<String>>(
                              valueListenable: groupSuggestions,
                              builder: (context, suggestions, _) {
                                if (suggestions.isEmpty)
                                  return const SizedBox.shrink();
                                return Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 120,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: suggestions.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        dense: true,
                                        title: Text(suggestions[index]),
                                        onTap: () {
                                          kodGrupyController.text =
                                              suggestions[index];
                                          groupSuggestions.value = [];
                                          loadSubgroupsForSelectedGroup(
                                            suggestions[index],
                                          );
                                          setStateDialog(() {});
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            ValueListenableBuilder<bool>(
                              valueListenable: podgrupaEnabled,
                              builder: (context, enabled, _) {
                                return TextField(
                                  controller: podgrupaController,
                                  enabled: enabled,
                                  decoration: InputDecoration(
                                    labelText:
                                        enabled
                                            ? 'Podgrupa'
                                            : 'Brak podgrup dla tej grupy',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onChanged:
                                      enabled
                                          ? (val) {
                                            updateSubgroupSuggestions(val);
                                            setStateDialog(() {});
                                          }
                                          : null,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<List<String>>(
                              valueListenable: subgroupSuggestions,
                              builder: (context, suggestions, _) {
                                if (suggestions.isEmpty)
                                  return const SizedBox.shrink();
                                return Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 120,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: const ClampingScrollPhysics(),
                                    itemCount: suggestions.length,
                                    itemBuilder: (context, index) {
                                      return ListTile(
                                        dense: true,
                                        title: Text(suggestions[index]),
                                        onTap: () {
                                          podgrupaController.text =
                                              suggestions[index];
                                          subgroupSuggestions.value = [];
                                          setStateDialog(() {});
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Anuluj'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      if (kodGrupyController.text.isNotEmpty) {
                                        await userProfile.addGroup(
                                          kodGrupyController.text,
                                          podgrupaController.text.isNotEmpty
                                              ? podgrupaController.text
                                              : null,
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          setState(() {});
                                        }
                                      }
                                    },
                                    child: const Text('Dodaj'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, GroupProfile group) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Usuń grupę'),
            content: Text(
              'Czy na pewno chcesz usunąć grupę ${group.kodGrupy}/${group.podgrupa}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () async {
                  await userProfile.removeGroup(group.kodGrupy, group.podgrupa);
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
                  }
                },
                child: const Text('Usuń'),
              ),
            ],
          ),
    );
  }
}
