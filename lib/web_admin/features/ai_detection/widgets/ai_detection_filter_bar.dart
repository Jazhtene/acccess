import 'package:flutter/material.dart';

import 'package:access_mobile/web_admin/features/ai_detection/ai_detection_models.dart';

import 'package:access_mobile/web_admin/features/media_evaluation/media_evaluation_models.dart';



class AiDetectionFilters {

  String mediaQuery = '';

  String memberQuery = '';

  AiResultLabel? aiFilter;

  ConfidenceLevel? confidenceFilter;

  ReviewStatus? reviewStatusFilter;

}



class AiDetectionFilterBar extends StatelessWidget {

  const AiDetectionFilterBar({

    super.key,

    required this.filters,

    required this.mediaSearchController,

    required this.memberSearchController,

    required this.onChanged,

    required this.onClear,

    this.visible = true,

  });



  final AiDetectionFilters filters;

  final TextEditingController mediaSearchController;

  final TextEditingController memberSearchController;

  final VoidCallback onChanged;

  final VoidCallback onClear;

  final bool visible;



  @override

  Widget build(BuildContext context) {

    if (!visible) return const SizedBox.shrink();



    return LayoutBuilder(

      builder: (context, c) {

        final stacked = c.maxWidth < 800;



        final searchRow = stacked

            ? Column(

                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [

                  _searchField(

                    mediaSearchController,

                    'Search by media name…',

                    Icons.image_search_outlined,

                    (v) {

                      filters.mediaQuery = v;

                      onChanged();

                    },

                  ),

                  const SizedBox(height: 10),

                  _searchField(

                    memberSearchController,

                    'Search by member name…',

                    Icons.person_search_outlined,

                    (v) {

                      filters.memberQuery = v;

                      onChanged();

                    },

                  ),

                ],

              )

            : Row(

                children: [

                  Expanded(

                    child: _searchField(

                      mediaSearchController,

                      'Search by media name…',

                      Icons.image_search_outlined,

                      (v) {

                        filters.mediaQuery = v;

                        onChanged();

                      },

                    ),

                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: _searchField(

                      memberSearchController,

                      'Search by member name…',

                      Icons.person_search_outlined,

                      (v) {

                        filters.memberQuery = v;

                        onChanged();

                      },

                    ),

                  ),

                  const SizedBox(width: 8),

                  TextButton.icon(

                    onPressed: onClear,

                    icon: const Icon(Icons.clear_all, size: 18),

                    label: const Text('Clear filters'),

                  ),

                ],

              );



        return Column(

          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [

            searchRow,

            if (stacked) ...[

              const SizedBox(height: 8),

              Align(

                alignment: Alignment.centerRight,

                child: TextButton.icon(

                  onPressed: onClear,

                  icon: const Icon(Icons.clear_all, size: 18),

                  label: const Text('Clear filters'),

                ),

              ),

            ],

            const SizedBox(height: 12),

            Wrap(

              spacing: 12,

              runSpacing: 8,

              crossAxisAlignment: WrapCrossAlignment.center,

              children: [

                _dropdown<AiResultLabel?>(

                  label: 'AI result',

                  value: filters.aiFilter,

                  stacked: stacked,

                  items: const [

                    (null, 'All'),

                    (AiResultLabel.human, 'Human'),

                    (AiResultLabel.aiGenerated, 'AI-Generated'),

                    (AiResultLabel.suspicious, 'Suspicious'),

                    (AiResultLabel.pending, 'Pending'),

                  ],

                  onChanged: (v) {

                    filters.aiFilter = v;

                    onChanged();

                  },

                ),

                _dropdown<ReviewStatus?>(

                  label: 'Review status',

                  value: filters.reviewStatusFilter,

                  stacked: stacked,

                  items: [

                    (null, 'All'),

                    ...ReviewStatus.values.map((s) => (s, reviewStatusLabel(s))),

                  ],

                  onChanged: (v) {

                    filters.reviewStatusFilter = v;

                    onChanged();

                  },

                ),

                _dropdown<ConfidenceLevel?>(

                  label: 'Confidence',

                  value: filters.confidenceFilter,

                  stacked: stacked,

                  items: const [

                    (null, 'All'),

                    (ConfidenceLevel.high, 'High'),

                    (ConfidenceLevel.medium, 'Medium'),

                    (ConfidenceLevel.low, 'Low'),

                  ],

                  onChanged: (v) {

                    filters.confidenceFilter = v;

                    onChanged();

                  },

                ),

              ],

            ),

          ],

        );

      },

    );

  }



  Widget _searchField(

    TextEditingController controller,

    String hint,

    IconData icon,

    ValueChanged<String> onChangedField,

  ) {

    return TextField(

      controller: controller,

      decoration: InputDecoration(

        hintText: hint,

        prefixIcon: Icon(icon, size: 20),

        isDense: true,

      ),

      onChanged: onChangedField,

    );

  }



  Widget _dropdown<T>({

    required String label,

    required T value,

    required List<(T, String)> items,

    required ValueChanged<T> onChanged,

    required bool stacked,

  }) {

    return SizedBox(

      width: stacked ? double.infinity : 200,

      child: InputDecorator(

        decoration: InputDecoration(labelText: label, isDense: true),

        child: DropdownButtonHideUnderline(

          child: DropdownButton<T>(

            value: value,

            isExpanded: true,

            items: items.map((e) => DropdownMenuItem<T>(value: e.$1, child: Text(e.$2))).toList(),

            onChanged: (v) => onChanged(v as T),

          ),

        ),

      ),

    );

  }

}

