import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../widgets/common.dart';

enum FieldType { text, number, date, select, lookup, multiline, toggle }

class FieldSpec {
  const FieldSpec(
    this.key,
    this.label, {
    this.type = FieldType.text,
    this.options = const [],
    this.lookupPath,
    this.lookupLabel,
    this.availableOnly = false,
    this.required = false,
    this.createOnly = false,
    this.defaultValue,
    this.visibleWhenKey,
    this.visibleWhenValues = const [],
    this.hiddenWhenKey,
    this.hiddenWhenValues = const [],
  });

  final String key;
  final String label;
  final FieldType type;
  final List<String> options;
  final String? lookupPath;
  final String Function(Map<String, dynamic>)? lookupLabel;
  final bool availableOnly;
  final bool required;
  final bool createOnly;
  final dynamic defaultValue;
  final String? visibleWhenKey;
  final List<dynamic> visibleWhenValues;
  final String? hiddenWhenKey;
  final List<dynamic> hiddenWhenValues;
}

class ResourceScreen extends StatefulWidget {
  const ResourceScreen({
    super.key,
    required this.api,
    required this.title,
    required this.endpoint,
    required this.permission,
    required this.fields,
    required this.itemTitle,
    required this.itemSubtitle,
    this.icon = Icons.list_alt,
    this.canDelete = true,
    this.trailing,
    this.detailBuilder,
  });

  final ApiClient api;
  final String title;
  final String endpoint;
  final String permission;
  final List<FieldSpec> fields;
  final String Function(Map<String, dynamic>) itemTitle;
  final String Function(Map<String, dynamic>) itemSubtitle;
  final IconData icon;
  final bool canDelete;
  final Widget Function(Map<String, dynamic>)? trailing;
  final Widget Function(Map<String, dynamic>)? detailBuilder;

  @override
  State<ResourceScreen> createState() => _ResourceScreenState();
}

class _ResourceScreenState extends State<ResourceScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await widget.api.get(
        widget.endpoint,
        query: {'per_page': 100},
      );
      _items = widget.api.listFrom(response);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: item == null ? 'Add ${widget.title}' : 'Edit ${widget.title}',
      child: ResourceForm(
        api: widget.api,
        endpoint: widget.endpoint,
        fields: widget.fields,
        initial: item,
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    if (!await confirmAction(
      context,
      'Delete record',
      'This action cannot be undone.',
    )) {
      return;
    }
    try {
      await widget.api.delete('${widget.endpoint}/${item['id']}');
      if (mounted) showMessage(context, 'Record deleted.');
      _load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  Future<void> _view(Map<String, dynamic> item) async {
    final page = widget.detailBuilder?.call(item);
    if (page == null) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((item) {
      if (_query.isEmpty) return true;
      return item.values.join(' ').toLowerCase().contains(_query.toLowerCase());
    }).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.title.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(child: LoadingView())
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyView(icon: widget.icon, message: 'No records found.'),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 30),
              sliver: SliverList.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return Card(
                    child: ListTile(
                      onTap: widget.detailBuilder == null
                          ? null
                          : () => _view(item),
                      contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      leading: CircleAvatar(child: Icon(widget.icon)),
                      title: Text(
                        widget.itemTitle(item),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(widget.itemSubtitle(item)),
                      trailing:
                          widget.trailing?.call(item) ??
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.detailBuilder != null)
                                IconButton(
                                  onPressed: () => _view(item),
                                  tooltip: 'View details',
                                  icon: const Icon(Icons.visibility_outlined),
                                ),
                              PopupMenuButton<String>(
                                tooltip: 'More actions',
                                onSelected: (value) {
                                  if (value == 'view') _view(item);
                                  if (value == 'edit') _edit(item);
                                  if (value == 'delete') _delete(item);
                                },
                                itemBuilder: (_) => [
                                  if (widget.detailBuilder != null)
                                    const PopupMenuItem(
                                      value: 'view',
                                      child: ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        title: Text('View details'),
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  if (widget.canDelete)
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class ResourceForm extends StatefulWidget {
  const ResourceForm({
    super.key,
    required this.api,
    required this.endpoint,
    required this.fields,
    this.initial,
    this.updateEndpoint,
  });

  final ApiClient api;
  final String endpoint;
  final List<FieldSpec> fields;
  final Map<String, dynamic>? initial;
  final String? updateEndpoint;

  @override
  State<ResourceForm> createState() => _ResourceFormState();
}

class _ResourceFormState extends State<ResourceForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};
  final Map<String, List<Map<String, dynamic>>> _lookups = {};
  bool _loading = false;
  bool _loadingLookups = true;

  bool get _isEditing => widget.initial?['id'] != null;

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      final initial = widget.initial?[field.key] ?? field.defaultValue;
      if ([
        FieldType.text,
        FieldType.number,
        FieldType.date,
        FieldType.multiline,
      ].contains(field.type)) {
        _controllers[field.key] = TextEditingController(
          text: initial?.toString() ?? '',
        );
      } else {
        _values[field.key] = field.type == FieldType.toggle
            ? initial == true || initial == 1
            : initial;
      }
    }
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      for (final field in widget.fields.where(
        (field) => field.lookupPath != null,
      )) {
        final path = field.lookupPath!;
        final key = _lookupKey(field);
        if (_lookups.containsKey(key)) continue;

        final items = widget.api.listFrom(
          await widget.api.get(
            path,
            query: {'per_page': 100, if (field.availableOnly) 'available': 1},
          ),
        );

        final selectedId = int.tryParse('${_values[field.key] ?? ''}');
        if (selectedId != null &&
            !items.any((item) => item['id'] == selectedId)) {
          try {
            items.add(
              widget.api.objectFrom(await widget.api.get('$path/$selectedId')),
            );
          } catch (_) {
            // Keep the form usable if a historical selection is unavailable.
          }
        }
        _lookups[key] = items;
      }
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loadingLookups = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  dynamic _typedValue(FieldSpec field, String text) {
    if (text.trim().isEmpty) return null;
    if (field.type == FieldType.number) return num.tryParse(text.trim());
    return text.trim();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final payload = <String, dynamic>{};
    for (final field in widget.fields) {
      if (field.createOnly && _isEditing) continue;
      if (!_isVisible(field)) {
        payload[field.key] = null;
        continue;
      }
      payload[field.key] = _controllers.containsKey(field.key)
          ? _typedValue(field, _controllers[field.key]!.text)
          : _values[field.key];
    }
    try {
      if (!_isEditing) {
        await widget.api.post(widget.endpoint, payload);
      } else {
        await widget.api.put(
          '${widget.updateEndpoint ?? widget.endpoint}/${widget.initial!['id']}',
          payload,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isVisible(FieldSpec field) {
    if (field.visibleWhenKey != null &&
        !field.visibleWhenValues.contains(_values[field.visibleWhenKey])) {
      return false;
    }
    if (field.hiddenWhenKey != null &&
        field.hiddenWhenValues.contains(_values[field.hiddenWhenKey])) {
      return false;
    }

    return true;
  }

  String _lookupKey(FieldSpec field) =>
      '${field.lookupPath}|${field.availableOnly}';

  @override
  Widget build(BuildContext context) {
    if (_loadingLookups) {
      return const SizedBox(height: 220, child: LoadingView());
    }
    return Form(
      key: _formKey,
      child: Column(
        children: [
          for (final field in widget.fields)
            if (_isVisible(field)) ...[
              _field(field),
              const SizedBox(height: 12),
            ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(FieldSpec field) {
    if (field.type == FieldType.select) {
      return DropdownButtonFormField<dynamic>(
        key: ValueKey('${field.key}:${_values[field.key]}'),
        initialValue: _values[field.key],
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: field.options
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        validator: field.required
            ? (value) => value == null ? '${field.label} is required' : null
            : null,
        onChanged: (value) => setState(() {
          _values[field.key] = value;
          final newborn = value == 'birth' || value == 'hatch';
          if (field.key == 'type' && newborn) {
            _values['unit'] = 'head';
            if (_values['newborn_destination'] == 'individual') {
              _controllers['quantity']?.text = '1';
            }
          }
          if (field.key == 'newborn_destination' && value == 'individual') {
            _controllers['quantity']?.text = '1';
            _values['unit'] = 'head';
          }
        }),
      );
    }
    if (field.type == FieldType.lookup) {
      final items = _lookups[_lookupKey(field)] ?? [];
      return DropdownButtonFormField<int?>(
        initialValue: int.tryParse('${_values[field.key] ?? ''}'),
        isExpanded: true,
        decoration: InputDecoration(labelText: field.label),
        items: [
          if (!field.required)
            const DropdownMenuItem<int?>(value: null, child: Text('None')),
          ...items.map(
            (item) => DropdownMenuItem<int?>(
              value: item['id'] as int?,
              child: Text(
                field.lookupLabel?.call(item) ??
                    item['name']?.toString() ??
                    '#${item['id']}',
              ),
            ),
          ),
        ],
        validator: field.required
            ? (value) => value == null ? '${field.label} is required' : null
            : null,
        onChanged: (value) => setState(() => _values[field.key] = value),
      );
    }
    if (field.type == FieldType.toggle) {
      return SwitchListTile(
        value: _values[field.key] == true,
        title: Text(field.label),
        onChanged: (value) => setState(() => _values[field.key] = value),
      );
    }
    final controller = _controllers[field.key]!;
    if (field.type == FieldType.date) {
      return FormField<String>(
        initialValue: controller.text,
        validator: field.required
            ? (value) => value == null || value.isEmpty
                  ? '${field.label} is required'
                  : null
            : null,
        builder: (state) => InkWell(
          onTap: () async {
            final selected = await showDatePicker(
              context: context,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
            );
            if (selected != null) {
              controller.text = dateFormat.format(selected);
              state.didChange(controller.text);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: field.label,
              errorText: state.errorText,
              suffixIcon: const Icon(Icons.calendar_month_outlined),
            ),
            child: Text(
              controller.text.isEmpty
                  ? 'Select date'
                  : formatAppDate(controller.text),
            ),
          ),
        ),
      );
    }
    return TextFormField(
      controller: controller,
      maxLines: field.type == FieldType.multiline ? 3 : 1,
      keyboardType: field.type == FieldType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: field.label),
      validator: field.required
          ? (value) => value == null || value.trim().isEmpty
                ? '${field.label} is required'
                : null
          : null,
    );
  }
}
