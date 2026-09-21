part of 'app_router.dart';

class GenealogyTreePage extends ConsumerWidget {
  const GenealogyTreePage({super.key, required this.personId});

  final String personId;

  String _displayName(GenealogyPerson person) {
    final surname = (person.marriedSurname?.trim().isNotEmpty ?? false)
        ? person.marriedSurname!.trim()
        : (person.birthSurname?.trim().isNotEmpty ?? false)
        ? person.birthSurname!.trim()
        : (person.lastName ?? '').trim();
    final parts = <String>[
      person.firstName.trim(),
      if ((person.middleName ?? '').trim().isNotEmpty)
        person.middleName!.trim(),
      if (surname.isNotEmpty) surname,
    ];
    return parts.where((part) => part.trim().isNotEmpty).join(' ');
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(genealogyRepositoryProvider);
    final personAsync = StreamProvider.autoDispose(
      (ref) => repo.watchPersonById(personId),
    );
    final person = ref.watch(personAsync).asData?.value;

    if (person == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Genealogy Tree v2')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final branchPalette =
        ref.watch(treeConnectorPaletteProvider).value ??
        treeConnectorPaletteDefault;
    final spousePalette =
        ref.watch(treeSpouseConnectorPaletteProvider).value ??
        treeSpouseConnectorPaletteDefault;
    final childPalette =
        ref.watch(treeChildConnectorPaletteProvider).value ??
        treeChildConnectorPaletteDefault;
    final expandAll = ref.watch(genealogyTreeExpandAllProvider).value ?? false;
    final expandedBranchIds =
        ref.watch(genealogyTreeExpandedBranchIdsProvider).value ?? <String>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Genealogy Tree v2')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.person),
              title: Text(
                _displayName(person),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Root person • ${person.gender}'),
              trailing: IconButton(
                icon: const Icon(Icons.open_in_new),
                onPressed: () => context.push('/v2/people/$personId'),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  elevation: 1,
                  shadowColor: Colors.black.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!expandAll)
                          IconButton(
                            tooltip: 'Expand all',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ref
                                .read(genealogyTreeExpandAllProvider.notifier)
                                .setExpanded(true),
                            icon: const Icon(Icons.unfold_more, size: 18),
                          )
                        else
                          IconButton(
                            tooltip: 'Collapse all',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => ref
                                .read(genealogyTreeExpandAllProvider.notifier)
                                .setExpanded(false),
                            icon: const Icon(Icons.unfold_less, size: 18),
                          ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: expandAll
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            expandAll ? 'Expanded' : 'Collapsed',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: expandAll
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<FamiliesV2Data>>(
            future: repo.getFamiliesForPerson(personId),
            builder: (context, snapshot) {
              final families = snapshot.data ?? const [];
              if (families.isEmpty) {
                return const Text('No family links yet.');
              }
              final visitedFamilyIds = <String>{};
              return Column(
                children: families.map((family) {
                  visitedFamilyIds.add(family.id);
                  return _FamilyBranchCard(
                    family: family,
                    personId: personId,
                    repo: repo,
                    displayName: _displayName,
                    formatDate: _formatDate,
                    visitedFamilyIds: visitedFamilyIds,
                    depth: 0,
                    branchPalette: branchPalette,
                    spousePalette: spousePalette,
                    childPalette: childPalette,
                    expandAll: expandAll,
                    expandedBranchIds: expandedBranchIds,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BranchData {
  const _BranchData({required this.spouse, required this.children});

  final GenealogyPerson? spouse;
  final List<_ChildBranchData> children;
}

class _ChildBranchData {
  const _ChildBranchData({required this.link, required this.person});

  final FamilyChildrenV2Data link;
  final GenealogyPerson? person;
}

class _FamilyBranchCard extends ConsumerStatefulWidget {
  const _FamilyBranchCard({
    required this.family,
    required this.personId,
    required this.repo,
    required this.displayName,
    required this.formatDate,
    required this.visitedFamilyIds,
    required this.depth,
    required this.branchPalette,
    required this.spousePalette,
    required this.childPalette,
    required this.expandAll,
    required this.expandedBranchIds,
  });

  final FamiliesV2Data family;
  final String personId;
  final GenealogyRepository repo;
  final String Function(GenealogyPerson) displayName;
  final String Function(DateTime) formatDate;
  final Set<String> visitedFamilyIds;
  final int depth;
  final TreeConnectorPalette branchPalette;
  final TreeConnectorPalette spousePalette;
  final TreeConnectorPalette childPalette;
  final bool expandAll;
  final Set<String> expandedBranchIds;

  @override
  ConsumerState<_FamilyBranchCard> createState() => _FamilyBranchCardState();
}

class _FamilyBranchCardState extends ConsumerState<_FamilyBranchCard> {
  Color _paletteColor(TreeConnectorPalette palette, BuildContext context) {
    return switch (palette) {
      TreeConnectorPalette.classic => switch (widget.depth) {
        0 => Theme.of(context).colorScheme.primary,
        1 => Colors.teal.shade600,
        2 => Colors.deepOrange.shade400,
        _ => Colors.indigo.shade400,
      },
      TreeConnectorPalette.forest => switch (widget.depth) {
        0 => Colors.green.shade700,
        1 => Colors.green.shade500,
        2 => Colors.teal.shade600,
        _ => Colors.lightGreen.shade700,
      },
      TreeConnectorPalette.ocean => switch (widget.depth) {
        0 => Theme.of(context).colorScheme.primary,
        1 => Theme.of(context).colorScheme.secondary,
        2 => Theme.of(context).colorScheme.tertiary,
        _ => Theme.of(context).colorScheme.outline,
      },
      TreeConnectorPalette.sunset => switch (widget.depth) {
        0 => Theme.of(context).colorScheme.secondary,
        1 => Theme.of(context).colorScheme.tertiary,
        2 => Theme.of(context).colorScheme.primary,
        _ => Theme.of(context).colorScheme.error,
      },
    };
  }

  Color _branchAccentColor(BuildContext context) =>
      _paletteColor(widget.branchPalette, context);

  Color _spouseLineColor(BuildContext context) =>
      _paletteColor(widget.spousePalette, context);

  Color _childLineColor(BuildContext context) =>
      _paletteColor(widget.childPalette, context);

  Future<_BranchData> _loadBranchData() async {
    final spouseId = widget.family.husbandId == widget.personId
        ? widget.family.wifeId
        : widget.family.husbandId;
    final spouse = spouseId == null || spouseId.isEmpty
        ? null
        : await widget.repo.getPersonById(spouseId);
    final childrenLinks = await widget.repo.getChildrenForFamily(
      widget.family.id,
    );
    final children = <_ChildBranchData>[];
    for (final link in childrenLinks) {
      children.add(
        _ChildBranchData(
          link: link,
          person: await widget.repo.getPersonById(link.childId),
        ),
      );
    }
    return _BranchData(spouse: spouse, children: children);
  }

  Widget _countBadge(String label, int count, Color color) {
    return Text(
      '$count $label',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1,
      ),
    );
  }

  Widget _connectorLine(Color color, {double width = 2, double height = 18}) {
    return Container(
      width: width,
      height: height,
      color: color.withValues(alpha: 0.35),
    );
  }

  Widget _connectorDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }

  String _compactSummary(int spouseCount, int childCount) {
    final parts = <String>[
      if (spouseCount > 0) '$spouseCount sp',
      if (childCount > 0) '$childCount ch',
    ];
    return parts.isEmpty ? 'Tap to expand' : parts.join(' • ');
  }

  Widget _buildFamilyBody(BuildContext context, _BranchData data) {
    final spouseColor = _spouseLineColor(context);
    final childColor = _childLineColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        if (data.spouse == null)
          const Text('Spouse not linked.')
        else
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.favorite_border, size: 18, color: spouseColor),
            title: Text(widget.displayName(data.spouse!)),
            subtitle: const Text('Spouse'),
            onTap: () => context.push('/v2/people/${data.spouse!.id}'),
          ),
        const SizedBox(height: 4),
        const Divider(height: 1),
        const SizedBox(height: 8),
        if (data.children.isEmpty)
          const Text('No children linked.')
        else
          Column(
            children: data.children.map((childLink) {
              final child = childLink.person;
              if (child == null) {
                return const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.child_care),
                  title: Text('Unknown child'),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _connectorLine(childColor),
                            _connectorDot(childColor),
                            _connectorLine(childColor),
                          ],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.child_care,
                              size: 18,
                              color: childColor,
                            ),
                            title: Text(widget.displayName(child)),
                            subtitle: Text(childLink.link.relationshipType),
                            onTap: () => context.push('/v2/people/${child.id}'),
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder<List<FamiliesV2Data>>(
                      future: widget.repo.getFamiliesForPerson(child.id),
                      builder: (context, childFamiliesSnapshot) {
                        final childFamilies =
                            childFamiliesSnapshot.data ?? const [];
                        if (childFamilies.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(left: 18),
                          child: Column(
                            children: childFamilies.map((nextFamily) {
                              if (widget.visitedFamilyIds.contains(
                                nextFamily.id,
                              )) {
                                return const SizedBox.shrink();
                              }
                              return _FamilyBranchCard(
                                family: nextFamily,
                                personId: child.id,
                                repo: widget.repo,
                                displayName: widget.displayName,
                                formatDate: widget.formatDate,
                                visitedFamilyIds: widget.visitedFamilyIds,
                                depth: widget.depth + 1,
                                branchPalette: widget.branchPalette,
                                spousePalette: widget.spousePalette,
                                childPalette: widget.childPalette,
                                expandAll: widget.expandAll,
                                expandedBranchIds: widget.expandedBranchIds,
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.visitedFamilyIds.contains(widget.family.id)) {
      return const SizedBox.shrink();
    }
    widget.visitedFamilyIds.add(widget.family.id);
    final accentColor = _branchAccentColor(context);
    final branchExpanded = widget.expandedBranchIds.contains(widget.family.id);
    final effectiveExpanded = widget.expandAll || branchExpanded;

    return FutureBuilder<_BranchData>(
      future: _loadBranchData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final spouseCount = data?.spouse == null ? 0 : 1;
        final childCount = data?.children.length ?? 0;

        return Card(
          margin: EdgeInsets.only(bottom: 12, left: widget.depth * 12.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: accentColor.withValues(alpha: 0.55)),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (!widget.expandAll) {
                        ref
                            .read(
                              genealogyTreeExpandedBranchIdsProvider.notifier,
                            )
                            .toggleBranchId(widget.family.id);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.family_restroom,
                                size: 18,
                                color: accentColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Branch ${widget.depth + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              _countBadge(
                                spouseCount == 1 ? 'spouse' : 'spouses',
                                spouseCount,
                                _spouseLineColor(context),
                              ),
                              const SizedBox(width: 6),
                              _countBadge(
                                childCount == 1 ? 'child' : 'children',
                                childCount,
                                _childLineColor(context),
                              ),
                              const SizedBox(width: 6),
                              Chip(
                                label: Text(
                                  widget.family.isPrimaryMarriage
                                      ? 'Primary'
                                      : 'Family',
                                ),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide(
                                  color: accentColor.withValues(alpha: 0.35),
                                ),
                              ),
                              AnimatedRotation(
                                turns: effectiveExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 220),
                                child: Icon(
                                  Icons.expand_more,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                widget.family.relationshipType,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (widget.family.marriageDate != null)
                                Text(
                                  'Marriage: ${widget.formatDate(widget.family.marriageDate!)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                widget.depth == 0
                                    ? 'Generation: direct branch'
                                    : 'Generation: ${widget.depth + 1}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          if (!effectiveExpanded) ...[
                            const SizedBox(height: 8),
                            Text(
                              spouseCount == 0 && childCount == 0
                                  ? 'Tap to expand branch details.'
                                  : _compactSummary(spouseCount, childCount),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: effectiveExpanded && data != null
                                ? _buildFamilyBody(context, data)
                                : (effectiveExpanded && data == null)
                                ? const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
