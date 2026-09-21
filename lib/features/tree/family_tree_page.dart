import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/brand_background.dart';
import '../../core/extensions/genealogy_person_extensions.dart';
import '../../core/widgets/person_avatar.dart';
import '../../data/database/app_database.dart';
import '../people/people_providers.dart';
import '../settings/app_settings_provider.dart';
import '../settings/display_formatters.dart';
import 'tree_models.dart';
import 'tree_providers.dart';
import 'tree_view_mode_toggle.dart';
import 'package:graphview/GraphView.dart';

class FamilyTreePage extends ConsumerStatefulWidget {
  const FamilyTreePage({super.key, this.rootPersonId});

  final String? rootPersonId;

  @override
  ConsumerState<FamilyTreePage> createState() => _FamilyTreePageState();
}

class _FamilyTreePageState extends ConsumerState<FamilyTreePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (widget.rootPersonId != null) {
        ref
            .read(selectedRootPersonIdProvider.notifier)
            .setRootPersonId(widget.rootPersonId);
      }
    });
  }

  @override
  void dispose() {
    final rememberRootEnabled =
        ref.read(rememberLastRootPersonProvider).value ??
        rememberLastRootPersonDefault;
    if (!rememberRootEnabled) {
      ref.read(selectedRootPersonIdProvider.notifier).setRootPersonId(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRootId = ref.watch(selectedRootPersonIdProvider);
    final firstPersonAsync = ref.watch(firstPersonProvider);
    final peopleAsync = ref.watch(peopleListProvider);
    final savedRootAsync = ref.watch(lastRootPersonIdProvider);
    final defaultRootAsync = ref.watch(defaultRootPersonIdProvider);
    final rememberRootEnabled =
        ref.watch(rememberLastRootPersonProvider).value ??
        rememberLastRootPersonDefault;
    final rootId =
        selectedRootId ??
        widget.rootPersonId ??
        (rememberRootEnabled ? savedRootAsync.value : null) ??
        defaultRootAsync.value ??
        firstPersonAsync.asData?.value?.id;
    final dateFormat =
        ref.watch(dateDisplayFormatProvider).value ?? dateDisplayFormatDefault;
    final labelStyle =
        ref.watch(relationshipLabelStyleProvider).value ??
        relationshipLabelStyleDefault;
    final photoFitMode =
        ref.watch(personPhotoFitModeProvider).value ??
        personPhotoFitModeDefault;
    final treeSpacing =
        ref.watch(treeCardSpacingProvider).value ?? treeCardSpacingDefault;
    final treeDensity =
        ref.watch(treeCardDensityProvider).value ?? treeCardDensityDefault;
    final lineThickness =
        ref.watch(treeLineThicknessProvider).value ?? treeLineThicknessDefault;
    final zoomOnLoad = ref.watch(zoomOnLoadProvider).value ?? zoomOnLoadDefault;
    final hideYearsForLiving =
        ref.watch(hideYearsForLivingProvider).value ??
        hideYearsForLivingDefault;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Tree'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TreeFanModeToggle(
              selectedMode: TreeViewMode.tree,
              onTreeSelected: () {},
              onFanSelected: () {
                if (rootId == null) return;
                context.push('/fan-tree/$rootId');
              },
            ),
          ),
          IconButton(
            tooltip: 'People',
            onPressed: () => context.push('/people'),
            icon: const Icon(Icons.people_alt_outlined),
          ),
        ],
      ),
      body: firstPersonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load tree:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (firstPerson) {
          if (firstPerson == null) {
            return _EmptyTreeView(
              onAddPerson: () => context.push('/people/add?returnTo=/tree'),
            );
          }

          final rootId =
              selectedRootId ??
              widget.rootPersonId ??
              (rememberRootEnabled ? savedRootAsync.value : null) ??
              defaultRootAsync.value ??
              firstPerson.id;
          final treeAsync = ref.watch(multiGenFamilyTreeProvider(rootId));

          return Column(
            children: [
              peopleAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (people) => _RootPersonSelector(
                  people: people,
                  selectedPersonId: rootId,
                  onChanged: (personId) {
                    if (personId == null) return;
                    ref
                        .read(selectedRootPersonIdProvider.notifier)
                        .setRootPersonId(personId);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: const [
                        Icon(Icons.touch_app_outlined),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tap a card to view profile. Long press a person to make them root. Pinch to zoom and drag to move.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: treeAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Failed to render tree:\n$error',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (treeData) {
                    if (treeData == null) {
                      return const Center(
                        child: Text('Selected person not found'),
                      );
                    }

                    return _BasicTreeCanvas(
                      treeData: treeData,
                      dateFormat: dateFormat,
                      labelStyle: labelStyle,
                      photoFitMode: photoFitMode,
                      spacing: treeSpacing,
                      density: treeDensity,
                      lineThickness: lineThickness,
                      hideYearsForLiving: hideYearsForLiving,
                      zoomOnLoad: zoomOnLoad,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RootPersonSelector extends StatelessWidget {
  const _RootPersonSelector({
    required this.people,
    required this.selectedPersonId,
    required this.onChanged,
  });

  final List<GenealogyPerson> people;
  final String selectedPersonId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DropdownButtonFormField<String>(
          initialValue: selectedPersonId,
          decoration: const InputDecoration(
            labelText: 'Root Person',
            prefixIcon: Icon(Icons.account_tree_outlined),
          ),
          items: people
              .map(
                (person) => DropdownMenuItem(
                  value: person.id,
                  child: Text(person.fullName),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyTreeView extends StatelessWidget {
  const _EmptyTreeView({required this.onAddPerson});

  final VoidCallback onAddPerson;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No family tree yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first family member to start building the tree.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddPerson,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add First Person'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicTreeCanvas extends StatefulWidget {
  const _BasicTreeCanvas({
    required this.treeData,
    required this.dateFormat,
    required this.labelStyle,
    required this.photoFitMode,
    required this.spacing,
    required this.density,
    required this.lineThickness,
    required this.hideYearsForLiving,
    required this.zoomOnLoad,
  });

  final MultiGenFamilyTreeData treeData;
  final DateDisplayFormat dateFormat;
  final RelationshipLabelStyle labelStyle;
  final PersonPhotoFitMode photoFitMode;
  final TreeCardSpacing spacing;
  final TreeCardDensity density;
  final TreeLineThickness lineThickness;
  final bool hideYearsForLiving;
  final bool zoomOnLoad;

  @override
  State<_BasicTreeCanvas> createState() => _BasicTreeCanvasState();
}

class _BasicTreeCanvasState extends State<_BasicTreeCanvas> {
  final Graph graph = Graph()..isTree = true;
  late SugiyamaConfiguration configuration;

  @override
  void initState() {
    super.initState();
    configuration = SugiyamaConfiguration()
      ..nodeSeparation = widget.spacing == TreeCardSpacing.spacious ? 40 : widget.spacing == TreeCardSpacing.compact ? 10 : 25
      ..levelSeparation = widget.spacing == TreeCardSpacing.spacious ? 80 : widget.spacing == TreeCardSpacing.compact ? 40 : 60
      ..orientation = 1; // Top-to-Bottom
  }

  @override
  void didUpdateWidget(covariant _BasicTreeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spacing != widget.spacing) {
      configuration
        ..nodeSeparation = widget.spacing == TreeCardSpacing.spacious ? 40 : widget.spacing == TreeCardSpacing.compact ? 10 : 25
        ..levelSeparation = widget.spacing == TreeCardSpacing.spacious ? 80 : widget.spacing == TreeCardSpacing.compact ? 40 : 60;
    }
  }

  @override
  Widget build(BuildContext context) {
    graph.edges.clear();
    graph.nodes.clear();

    final Map<String, Node> nodeMap = {};
    for (final person in widget.treeData.nodes.values) {
      nodeMap[person.id] = Node.Id(person.id);
    }

    for (final edge in widget.treeData.edges) {
      if (nodeMap.containsKey(edge.sourceId) && nodeMap.containsKey(edge.targetId)) {
        graph.addEdge(nodeMap[edge.sourceId]!, nodeMap[edge.targetId]!);
      }
    }

    final double densityFactor = widget.density == TreeCardDensity.compact ? 0.9 : widget.density == TreeCardDensity.spacious ? 1.12 : 1.0;
    final double nodeWidth = 180 * densityFactor;
    final double nodeHeight = 82 * densityFactor;
    
    final lineThicknessValue = widget.lineThickness == TreeLineThickness.thin ? 1.4 : widget.lineThickness == TreeLineThickness.thick ? 3.2 : 2.2;

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 2.5,
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(configuration),
        paint: Paint()
          ..color = Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
          ..strokeWidth = lineThicknessValue
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
        builder: (Node node) {
          final personId = node.key!.value as String;
          final person = widget.treeData.nodes[personId]!;
          return SizedBox(
            width: nodeWidth,
            height: nodeHeight,
            child: _TreePersonCard(
              person: person,
              relationLabel: personId == widget.treeData.rootPerson.id ? 'Root' : '',
              isRoot: personId == widget.treeData.rootPerson.id,
              isHint: false,
              dateFormat: widget.dateFormat,
              labelStyle: widget.labelStyle,
              photoFitMode: widget.photoFitMode,
              density: widget.density,
              hideYearsForLiving: widget.hideYearsForLiving,
            ),
          );
        },
      ),
    );
  }
}
class _TreePersonCard extends StatelessWidget {
  const _TreePersonCard({
    required this.person,
    required this.relationLabel,
    required this.isRoot,
    required this.isHint,
    required this.dateFormat,
    required this.labelStyle,
    required this.photoFitMode,
    required this.density,
    required this.hideYearsForLiving,
  });

  final GenealogyPerson person;
  final String relationLabel;
  final bool isRoot;
  final bool isHint;
  final DateDisplayFormat dateFormat;
  final RelationshipLabelStyle labelStyle;
  final PersonPhotoFitMode photoFitMode;
  final TreeCardDensity density;
  final bool hideYearsForLiving;

  double get _densityFactor => switch (density) {
    TreeCardDensity.compact => 0.9,
    TreeCardDensity.normal => 1.0,
    TreeCardDensity.spacious => 1.12,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    if (isHint) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openAddPersonChoice(context),
        child: Card(
          color: _hintCardColor(context),
          elevation: 0,
          shadowColor: colorScheme.shadow.withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(10 * _densityFactor),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18 * _densityFactor,
                  backgroundColor: colorScheme.primaryContainer,
                  child: _hintAvatar(context),
                ),
                SizedBox(width: 10 * _densityFactor),
                Expanded(
                  child: Text(
                    relationLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.8 * _densityFactor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initial = person.fullName.trim().isNotEmpty
        ? person.fullName.trim()[0].toUpperCase()
        : '?';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/people/${person.id}'),
      onLongPress: () => context.push('/tree/${person.id}'),
      child: Card(
        color: isRoot ? colorScheme.primaryContainer : colorScheme.surface,
        elevation: isRoot ? 2 : 0,
        shadowColor: isRoot
            ? colorScheme.primary.withValues(alpha: 0.2)
            : colorScheme.shadow.withValues(alpha: isDark ? 0.18 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRoot
                ? colorScheme.primary.withValues(alpha: 0.28)
                : colorScheme.outlineVariant.withValues(alpha: 0.65),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(11 * _densityFactor),
          child: Stack(
            children: [
              const Positioned.fill(
                child: BrandWatermark(
                  alignment: Alignment.centerRight,
                  opacity: 0.03,
                  scale: 0.95,
                  padding: EdgeInsets.only(right: 2),
                ),
              ),
              Row(
                children: [
                  PersonAvatar(
                    photoPath: person.profilePhotoPath,
                    initialText: initial,
                    size: isRoot ? 56 * _densityFactor : 52 * _densityFactor,
                    fitMode: photoFitMode,
                  ),
                  SizedBox(width: 10 * _densityFactor),
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            person.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isRoot
                                  ? 15.1 * _densityFactor
                                  : 14.5 * _densityFactor,
                            ),
                          ),
                          SizedBox(height: 3 * _densityFactor),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _genderIcon(),
                                size: 13.5 * _densityFactor,
                                color: _genderColor(context),
                              ),
                              SizedBox(width: 4 * _densityFactor),
                              Text(
                                relationLabel,
                                style: TextStyle(
                                  fontSize: 12 * _densityFactor,
                                  fontWeight: FontWeight.w600,
                                  color: _relationLabelColor(context),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 3 * _densityFactor),
                          Text(
                            formatLifespanForDisplay(
                              person.birthDate,
                              person.deathDate,
                              dateFormat,
                              isLiving: person.isLiving,
                              hideYearsForLiving: hideYearsForLiving,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12 * _densityFactor,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _genderIcon() {
    switch (person.gender) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person_outline;
    }
  }

  Color _genderColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (person.gender) {
      case 'male':
        return colorScheme.primary;
      case 'female':
        return colorScheme.secondary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  Color _relationLabelColor(BuildContext context) {
    if (isRoot) return Theme.of(context).colorScheme.primary;
    if (relationLabel == 'Father' ||
        relationLabel == 'Mother' ||
        relationLabel == 'Parent') {
      return Theme.of(context).colorScheme.tertiary;
    }
    if (relationLabel == 'Husband' ||
        relationLabel == 'Wife' ||
        relationLabel == 'Spouse') {
      return Theme.of(context).colorScheme.secondary;
    }
    if (relationLabel == 'Son' ||
        relationLabel == 'Daughter' ||
        relationLabel == 'Child') {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Color _hintCardColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (relationLabel) {
      case 'Add Parent':
        return colorScheme.surfaceContainerHighest;
      case 'Add Spouse':
        return colorScheme.surfaceContainerHighest;
      case 'Add Son or Daughter':
        return colorScheme.surfaceContainerHighest;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Widget _hintAvatar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (relationLabel) {
      case 'Add Parent':
        if (labelStyle == RelationshipLabelStyle.neutral) {
          return Icon(
            Icons.family_restroom_outlined,
            color: colorScheme.tertiary,
          );
        }
        return SizedBox(
          width: 26,
          height: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(Icons.male, size: 16, color: colorScheme.primary),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.female,
                  size: 16,
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        );
      case 'Add Son or Daughter':
        return Icon(Icons.child_care_outlined, color: colorScheme.primary);
      case 'Add Spouse':
        if (labelStyle == RelationshipLabelStyle.neutral) {
          return Icon(Icons.favorite_border, color: colorScheme.secondary);
        }
        return Icon(Icons.favorite_border, color: colorScheme.secondary);
      default:
        return Icon(
          Icons.person_add_alt_1_outlined,
          color: colorScheme.primary,
        );
    }
  }

  void _openAddPersonChoice(BuildContext context) {
    final relationKind = _relationKind();
    final relationLabel = _relationLabelForAction();
    final existingLabel = _existingActionLabel();
    final createLabel = _createActionLabel();
    final sheetTheme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add $relationLabel',
                  style: sheetTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose whether to connect someone already in the tree or create a new person first.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(
                      '/people/${person.id}/add-relationship?${Uri(queryParameters: {'relation': relationKind}).query}',
                    );
                  },
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(existingLabel),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.go(
                      '/people/add?${Uri(queryParameters: {'linkPersonId': person.id, 'relationKind': relationKind, 'returnTo': '/tree', 'initialGender': _initialGenderForRelation()}).query}',
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(createLabel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _relationKind() {
    switch (relationLabel) {
      case 'Add Parent':
        return 'parent';
      case 'Add Son or Daughter':
        return 'child';
      case 'Add Spouse':
        return 'spouse';
      default:
        return 'parent';
    }
  }

  String _relationLabelForAction() {
    switch (relationLabel) {
      case 'Add Parent':
        return person.gender == 'female' ? 'mother' : 'father';
      case 'Add Son or Daughter':
        return 'child';
      case 'Add Spouse':
        return 'spouse';
      default:
        return 'relationship';
    }
  }

  String _existingActionLabel() {
    switch (relationLabel) {
      case 'Add Parent':
        return 'Link existing parent';
      case 'Add Son or Daughter':
        return 'Link existing son or daughter';
      case 'Add Spouse':
        return 'Link existing spouse';
      default:
        return 'Link existing person';
    }
  }

  String _createActionLabel() {
    switch (relationLabel) {
      case 'Add Spouse':
        return 'Create Spouse';
      case 'Add Parent':
        return 'Create New Parent';
      case 'Add Son or Daughter':
        return 'Create New Son or Daughter';
      default:
        return 'Create New Person';
    }
  }

  String _initialGenderForRelation() {
    switch (relationLabel) {
      case 'Add Parent':
        return person.gender == 'female' ? 'female' : 'male';
      case 'Add Son or Daughter':
        return 'other';
      case 'Add Spouse':
        return 'other';
      default:
        return 'other';
    }
  }
}
