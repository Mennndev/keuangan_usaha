import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatefulWidget {
  const ConfirmDeleteDialog({
    required this.itemName,
    required this.onDelete,
    this.title = 'Hapus transaksi?',
    this.description,
    this.errorMessage = 'Transaksi belum berhasil dihapus. Coba lagi.',
    this.onError,
    super.key,
  });

  final String itemName;
  final String title;
  final String? description;
  final String errorMessage;
  final Future<void> Function() onDelete;
  final ValueChanged<Object>? onError;

  @override
  State<ConfirmDeleteDialog> createState() => _ConfirmDeleteDialogState();
}

class _ConfirmDeleteDialogState extends State<ConfirmDeleteDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      widget.onError?.call(error);
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = widget.errorMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description ??
                  '“${widget.itemName}” akan dihapus permanen. Tindakan ini tidak dapat dibatalkan.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: _deleting ? null : _delete,
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            icon: _deleting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline),
            label: Text(_deleting ? 'Menghapus…' : 'Hapus'),
          ),
        ],
      ),
    );
  }
}

Future<bool> showConfirmDeleteDialog(
  BuildContext context, {
  required String itemName,
  required Future<void> Function() onDelete,
  String title = 'Hapus transaksi?',
  String? description,
  String errorMessage = 'Transaksi belum berhasil dihapus. Coba lagi.',
  ValueChanged<Object>? onError,
}) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ConfirmDeleteDialog(
          itemName: itemName,
          onDelete: onDelete,
          title: title,
          description: description,
          errorMessage: errorMessage,
          onError: onError,
        ),
      ) ??
      false;
}
