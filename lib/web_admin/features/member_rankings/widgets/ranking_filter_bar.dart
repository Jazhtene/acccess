import 'package:flutter/material.dart';

import 'package:access_mobile/web_admin/features/member_rankings/member_ranking_models.dart';

import 'package:access_mobile/web_admin/theme/admin_theme.dart';



class RankingFilters {

  String nameQuery = '';

  SkillLevelTier? skillFilter;

  ParticipationStatus? statusFilter;

  RankingSort sort = RankingSort.rank;

}



class RankingFilterBar extends StatelessWidget {

  const RankingFilterBar({

    super.key,

    required this.filters,

    required this.nameController,

    required this.onChanged,

    required this.onClear,

    this.visible = true,

  });



  final RankingFilters filters;

  final TextEditingController nameController;

  final VoidCallback onChanged;

  final VoidCallback onClear;

  final bool visible;



  @override

  Widget build(BuildContext context) {

    if (!visible) return const SizedBox.shrink();



    return LayoutBuilder(

      builder: (context, c) {

        final stacked = c.maxWidth < 900;

        final searchField = TextField(

          controller: nameController,

          decoration: const InputDecoration(

            hintText: 'Search by member name…',

            prefixIcon: Icon(Icons.person_search_outlined, size: 20),

            isDense: true,

          ),

          onChanged: (v) {

            filters.nameQuery = v;

            onChanged();

          },

        );



        final filtersRow = Wrap(

          spacing: 12,

          runSpacing: 10,

          crossAxisAlignment: WrapCrossAlignment.center,

          children: [

            SizedBox(width: stacked ? double.infinity : 180, child: _skillDropdown()),

            SizedBox(width: stacked ? double.infinity : 180, child: _statusDropdown()),

            SizedBox(width: stacked ? double.infinity : 160, child: _sortDropdown()),

            TextButton.icon(

              onPressed: onClear,

              icon: const Icon(Icons.clear_all, size: 18),

              label: const Text('Clear'),

            ),

          ],

        );



        return Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            if (stacked) ...[

              searchField,

              const SizedBox(height: 12),

              filtersRow,

            ] else

              Row(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Expanded(flex: 2, child: searchField),

                  const SizedBox(width: 12),

                  Expanded(flex: 3, child: filtersRow),

                ],

              ),

            const SizedBox(height: 8),

            const Align(

              alignment: Alignment.centerLeft,

              child: Text(

                'Skill level is calculated from media quality, approved uploads, tasks, admin review, and AI authenticity.',

                style: TextStyle(fontSize: 11, color: AdminTheme.textSecondary),

              ),

            ),

          ],

        );

      },

    );

  }



  Widget _skillDropdown() {

    return InputDecorator(

      decoration: const InputDecoration(labelText: 'Skill level', isDense: true),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<SkillLevelTier?>(

          value: filters.skillFilter,

          isExpanded: true,

          items: const [

            DropdownMenuItem(value: null, child: Text('All')),

            DropdownMenuItem(value: SkillLevelTier.beginner, child: Text('Beginner')),

            DropdownMenuItem(value: SkillLevelTier.intermediate, child: Text('Intermediate')),

            DropdownMenuItem(value: SkillLevelTier.advanced, child: Text('Advanced')),

            DropdownMenuItem(value: SkillLevelTier.expert, child: Text('Expert')),

          ],

          onChanged: (v) {

            filters.skillFilter = v;

            onChanged();

          },

        ),

      ),

    );

  }



  Widget _statusDropdown() {

    return InputDecorator(

      decoration: const InputDecoration(labelText: 'Participation', isDense: true),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<ParticipationStatus?>(

          value: filters.statusFilter,

          isExpanded: true,

          items: const [

            DropdownMenuItem(value: null, child: Text('All')),

            DropdownMenuItem(value: ParticipationStatus.active, child: Text('Active')),

            DropdownMenuItem(value: ParticipationStatus.inactive, child: Text('Inactive')),

            DropdownMenuItem(value: ParticipationStatus.needsTraining, child: Text('Needs Training')),

            DropdownMenuItem(value: ParticipationStatus.underReview, child: Text('Under Review')),

          ],

          onChanged: (v) {

            filters.statusFilter = v;

            onChanged();

          },

        ),

      ),

    );

  }



  Widget _sortDropdown() {

    return InputDecorator(

      decoration: const InputDecoration(labelText: 'Sort by', isDense: true),

      child: DropdownButtonHideUnderline(

        child: DropdownButton<RankingSort>(

          value: filters.sort,

          isExpanded: true,

          items: const [

            DropdownMenuItem(value: RankingSort.skillScore, child: Text('Skill score')),

            DropdownMenuItem(value: RankingSort.rank, child: Text('Rank')),

            DropdownMenuItem(value: RankingSort.points, child: Text('Points')),

            DropdownMenuItem(value: RankingSort.uploads, child: Text('Uploads')),

            DropdownMenuItem(value: RankingSort.averageQuality, child: Text('Avg quality')),

            DropdownMenuItem(value: RankingSort.lastActivity, child: Text('Last activity')),

          ],

          onChanged: (v) {

            if (v != null) {

              filters.sort = v;

              onChanged();

            }

          },

        ),

      ),

    );

  }

}

