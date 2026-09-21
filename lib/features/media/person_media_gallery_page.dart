import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../data/database/app_database.dart';
import '../../data/providers/media_repository_provider.dart';
import '../../data/providers/media_storage_provider.dart';
import 'media_providers.dart';

class PersonMediaGalleryPage extends ConsumerStatefulWidget {
  const PersonMediaGalleryPage({super.key, required this.personId});

  final String personId;

  @override
  ConsumerState<PersonMediaGalleryPage> createState() =>
      _PersonMediaGalleryPageState();
}

class _PersonMediaGalleryPageState
    extends ConsumerState<PersonMediaGalleryPage> {
  bool _isWorking = false;

  Future<void> _addMedia() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'doc', 'docx'],
    );

    if (picked == null || picked.files.single.path == null) return;

    final file = File(picked.files.single.path!);
    final extension = picked.files.single.extension?.toLowerCase() ?? '';
    final mediaType = ['jpg', 'jpeg', 'png', 'webp'].contains(extension)
        ? 'photo'
        : 'document';

    setState(() {
      _isWorking = true;
    });

    try {
      final storage = ref.read(mediaStorageServiceProvider);
      final repository = ref.read(mediaRepositoryProvider);

      final savedPath = await storage.savePersonMedia(
        sourceFile: file,
        personId: widget.personId,
      );

      await repository.addMediaItem(
        personId: widget.personId,
        filePath: savedPath,
        mediaType: mediaType,
        title: picked.files.single.name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media added successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add media: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _deleteMedia(MediaItem item) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Media?'),
          content: const Text(
            'This will remove this media item from the person profile.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final storage = ref.read(mediaStorageServiceProvider);

      await repository.deleteMediaItem(item.id);
      await storage.deleteFileIfExists(item.filePath);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Media deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete media: $e')));
    }
  }

  Future<void> _openFile(MediaItem item) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found.')));
      return;
    }

    final result = await OpenFilex.open(item.filePath);
    if (!mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open file: ${result.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(mediaByPersonProvider(widget.personId));

    return Scaffold(
      appBar: AppBar(title: const Text('Media Gallery')),
      body: mediaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load media:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyMediaView(onAdd: _isWorking ? null : _addMedia);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return _MediaTile(
                item: item,
                onDelete: () => _deleteMedia(item),
                onOpenFile: () => _openFile(item),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isWorking ? null : _addMedia,
        icon: _isWorking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_photo_alternate_outlined),
        label: Text(_isWorking ? 'Adding...' : 'Add Media'),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.onDelete,
    required this.onOpenFile,
  });

  final MediaItem item;
  final VoidCallback onDelete;
  final VoidCallback onOpenFile;

  @override
  Widget build(BuildContext context) {
    final isPhoto = item.mediaType == 'photo';
    final file = File(item.filePath);
    final exists = file.existsSync();

    return Card(
      child: ListTile(
        leading: isPhoto && exists
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                ),
              )
            : CircleAvatar(
                child: Icon(
                  isPhoto ? Icons.photo_outlined : Icons.description_outlined,
                ),
              ),
        title: Text(
          item.title == null || item.title!.trim().isEmpty
              ? 'Untitled media'
              : item.title!,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          exists
              ? '${item.mediaType} • ${_formatDate(item.createdAt)}'
              : '${item.mediaType} • File missing',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'open') {
              if (!exists) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File not found.')),
                );
                return;
              }

              if (isPhoto) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _PhotoPreviewPage(
                      title: item.title ?? 'Photo',
                      filePath: item.filePath,
                    ),
                  ),
                );
              } else {
                onOpenFile();
              }
            }

            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'open', child: Text('Open')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        onTap: () {
          if (!exists) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('File not found.')));
            return;
          }

          if (isPhoto) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _PhotoPreviewPage(
                  title: item.title ?? 'Photo',
                  filePath: item.filePath,
                ),
              ),
            );
          } else {
            onOpenFile();
          }
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day-$month-$year';
  }
}

class _PhotoPreviewPage extends StatelessWidget {
  const _PhotoPreviewPage({required this.title, required this.filePath});

  final String title;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: InteractiveViewer(
          child: Image.file(File(filePath), fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _EmptyMediaView extends StatelessWidget {
  const _EmptyMediaView({required this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No media added yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add photos, documents, and memories for this family member.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add Media'),
            ),
          ],
        ),
      ),
    );
  }
}
