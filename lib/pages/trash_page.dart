import 'package:flutter/material.dart';

import '../models/trash_entry.dart';
import '../services/trash_service.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final TrashService _trashService = TrashService();

  List<TrashEntry> _entries = [];
  final Set<String> _selectedIds = {};

  bool _isLoading = true;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    try {
      final entries = await _trashService.loadTrash();

      if (!mounted) return;

      setState(() {
        _entries = entries;
        _selectedIds.removeWhere(
          (id) => !entries.any((entry) => entry.id == id),
        );
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load Trash. Your data was not changed.'),
        ),
      );
    }
  }

  String _title(TrashEntry entry) {
    if (entry.type == 'trip') {
      final tripData = Map<String, dynamic>.from(entry.data['trip'] as Map);
      return tripData['name'] as String? ?? 'Deleted trip';
    }

    return entry.data['description'] as String? ?? 'Deleted expense';
  }

  String _subtitle(TrashEntry entry) {
    if (entry.type == 'trip') {
      final rawExpenses = entry.data['expenses'] as List<dynamic>? ?? [];
      return 'Trip • ${rawExpenses.length} expense records';
    }

    final date = entry.data['date'] as String? ?? '';
    final amount = entry.data['amount'];

    return 'Expense • $date • $amount';
  }

  String _formatDeletedDate(DateTime date) {
    final localDate = date.toLocal();

    return '${localDate.year}-'
        '${localDate.month.toString().padLeft(2, '0')}-'
        '${localDate.day.toString().padLeft(2, '0')}';
  }

  void _toggleSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _entries.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_entries.map((entry) => entry.id));
      }
    });
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(actionLabel),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _restoreSelected() async {
    final selectedEntries = _entries
        .where((entry) => _selectedIds.contains(entry.id))
        .toList();

    if (selectedEntries.isEmpty || _isWorking) return;

    setState(() => _isWorking = true);

    var restored = 0;
    final failures = <String>[];

    for (final entry in selectedEntries) {
      try {
        await _trashService.restore(entry);
        restored++;
      } catch (error) {
        failures.add('${_title(entry)}: $error');
      }
    }

    if (!mounted) return;

    setState(() => _isWorking = false);
    await _loadTrash();

    if (!mounted) return;

    final message = failures.isEmpty
        ? '$restored item(s) restored'
        : '$restored restored; ${failures.length} could not be restored';

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _permanentlyDeleteSelected() async {
    final selectedEntries = _entries
        .where((entry) => _selectedIds.contains(entry.id))
        .toList();

    if (selectedEntries.isEmpty || _isWorking) return;

    final confirmed = await _confirm(
      title: 'Permanently delete?',
      message:
          'Permanently delete ${selectedEntries.length} selected item(s)? '
          'This action cannot be undone.',
      actionLabel: 'Delete permanently',
    );

    if (!confirmed || !mounted) return;

    setState(() => _isWorking = true);

    var deleted = 0;
    var failed = 0;

    for (final entry in selectedEntries) {
      try {
        await _trashService.permanentlyDelete(entry);
        deleted++;
      } catch (_) {
        failed++;
      }
    }

    if (!mounted) return;

    setState(() => _isWorking = false);
    await _loadTrash();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? '$deleted item(s) permanently deleted'
              : '$deleted deleted; $failed failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected =
        _entries.isNotEmpty && _selectedIds.length == _entries.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              tooltip: allSelected ? 'Deselect all' : 'Select all',
              onPressed: _isWorking ? null : _toggleSelectAll,
              icon: Icon(allSelected ? Icons.deselect : Icons.select_all),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Trash is empty',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Deleted trips and expenses will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                CheckboxListTile(
                  value: allSelected,
                  tristate: true,
                  title: Text(
                    '${_selectedIds.length} of '
                    '${_entries.length} selected',
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: _isWorking ? null : (_) => _toggleSelectAll(),
                ),
                const Divider(height: 1),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadTrash,
                    child: ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final selected = _selectedIds.contains(entry.id);

                        return CheckboxListTile(
                          value: selected,
                          controlAffinity: ListTileControlAffinity.leading,
                          secondary: Icon(
                            entry.type == 'trip'
                                ? Icons.luggage_outlined
                                : Icons.receipt_long_outlined,
                          ),
                          title: Text(_title(entry)),
                          subtitle: Text(
                            '${_subtitle(entry)}\n'
                            'Deleted ${_formatDeletedDate(entry.deletedAt)}',
                          ),
                          isThreeLine: true,
                          onChanged: _isWorking
                              ? null
                              : (value) =>
                                    _toggleSelection(entry.id, value ?? false),
                        );
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isWorking || _selectedIds.isEmpty
                                ? null
                                : _restoreSelected,
                            icon: const Icon(Icons.restore),
                            label: const Text('Restore'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _isWorking || _selectedIds.isEmpty
                                ? null
                                : _permanentlyDeleteSelected,
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Delete forever'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isWorking) const LinearProgressIndicator(),
              ],
            ),
    );
  }
}
