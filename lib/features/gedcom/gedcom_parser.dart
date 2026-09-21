import 'dart:convert';
import 'dart:io';

class GedcomNode {
  GedcomNode({required this.level, this.id, required this.tag, this.value});

  final int level;
  final String? id;
  final String tag;
  String? value;
  final List<GedcomNode> children = [];

  GedcomNode? getChild(String tag) {
    for (final child in children) {
      if (child.tag == tag) return child;
    }
    return null;
  }

  List<GedcomNode> getChildren(String tag) {
    return children.where((child) => child.tag == tag).toList();
  }
}

class GedcomParser {
  static Future<List<GedcomNode>> parseFile(File file) async {
    final lines = await file.readAsLines(encoding: utf8);
    return parseLines(lines);
  }

  static List<GedcomNode> parseLines(List<String> lines) {
    final rootNodes = <GedcomNode>[];
    final stack = <GedcomNode>[];

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      final parts = line.split(' ');
      if (parts.length < 2) continue;

      final level = int.tryParse(parts[0]);
      if (level == null) continue;

      String? id;
      String tag;
      String? value;

      if (parts[1].startsWith('@') && parts[1].endsWith('@')) {
        id = parts[1];
        if (parts.length > 2) {
          tag = parts[2];
          if (parts.length > 3) {
            value = parts.sublist(3).join(' ');
          }
        } else {
          continue;
        }
      } else {
        tag = parts[1];
        if (parts.length > 2) {
          value = parts.sublist(2).join(' ');
        }
      }

      final node = GedcomNode(level: level, id: id, tag: tag, value: value);

      if (tag == 'CONT' || tag == 'CONC') {
        if (stack.isNotEmpty) {
          final parent = stack.last;
          if (tag == 'CONT') {
            parent.value = (parent.value ?? '') + '\n' + (value ?? '');
          } else {
            parent.value = (parent.value ?? '') + (value ?? '');
          }
        }
        continue;
      }

      if (level == 0) {
        rootNodes.add(node);
        stack.clear();
        stack.add(node);
      } else {
        while (stack.isNotEmpty && stack.last.level >= level) {
          stack.removeLast();
        }
        if (stack.isNotEmpty) {
          stack.last.children.add(node);
        }
        stack.add(node);
      }
    }

    return rootNodes;
  }
}
