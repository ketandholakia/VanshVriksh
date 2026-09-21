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
          ..color = Theme.of(context).colorScheme.primary.withOpacity(0.6)
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
