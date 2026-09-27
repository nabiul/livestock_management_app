import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_client.dart';

String formFieldLabel(String label, {bool required = false}) =>
    required ? '$label *' : label;

final moneyFormat = NumberFormat.currency(symbol: '৳', decimalDigits: 2);
final dateFormat = DateFormat('yyyy-MM-dd');
final displayDateFormat = DateFormat('dd-MM-yyyy');

String formatAppDate(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  if (text.isEmpty) return fallback;
  final parsed = DateTime.tryParse(text);
  return parsed == null ? text : displayDateFormat.format(parsed);
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

String errorMessage(Object error) =>
    error is ApiException ? error.message : error.toString();

Future<bool> confirmAction(
  BuildContext context,
  String title,
  String message,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class AppSheet extends StatelessWidget {
  const AppSheet({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .92,
    ),
    decoration: const BoxDecoration(
      color: Color(0xFFF7F9F5),
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: child,
          ),
        ),
      ],
    ),
  );
}

class SearchableDropdown extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.required = false,
    this.emptyLabel = 'None',
    this.labelBuilder,
  });

  final String label;
  final List<Map<String, dynamic>> items;
  final int? value;
  final ValueChanged<int?> onChanged;
  final bool required;
  final String emptyLabel;
  final String Function(Map<String, dynamic>)? labelBuilder;

  @override
  Widget build(BuildContext context) => FormField<int?>(
    initialValue: value,
    validator: required
        ? (selected) => selected == null ? '$label is required' : null
        : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<int?>(
          initialSelection: value,
          expandedInsets: EdgeInsets.zero,
          menuHeight: 310,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          leadingIcon: const Icon(Icons.search_rounded, size: 20),
          trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded),
          label: Text(formFieldLabel(label, required: required)),
          hintText: 'Type to search...',
          dropdownMenuEntries: [
            if (!required)
              DropdownMenuEntry<int?>(
                value: null,
                label: emptyLabel,
                leadingIcon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 18,
                ),
              ),
            ...items.map(
              (item) => DropdownMenuEntry<int?>(
                value: item['id'] as int?,
                label:
                    labelBuilder?.call(item) ??
                    item['label']?.toString() ??
                    item['name']?.toString() ??
                    '#${item['id']}',
                trailingIcon: state.value == item['id']
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF07883F),
                        size: 19,
                      )
                    : null,
              ),
            ),
          ],
          onSelected: (selected) {
            state.didChange(selected);
            onChanged(selected);
          },
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              state.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    ),
  );
}

class SearchableStringDropdown extends StatelessWidget {
  const SearchableStringDropdown({
    super.key,
    required this.label,
    required this.options,
    required this.onChanged,
    this.value,
    this.required = false,
    this.allowEmpty = false,
    this.emptyLabel = 'None',
    this.labels = const {},
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;
  final bool allowEmpty;
  final String emptyLabel;
  final Map<String, String> labels;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FormField<String>(
    initialValue: value,
    validator: required
        ? (selected) =>
              selected == null || selected.isEmpty ? '$label is required' : null
        : null,
    builder: (state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<String>(
          enabled: enabled,
          initialSelection: value,
          expandedInsets: EdgeInsets.zero,
          menuHeight: 310,
          enableFilter: true,
          enableSearch: true,
          requestFocusOnTap: true,
          leadingIcon: const Icon(Icons.search_rounded, size: 20),
          trailingIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          selectedTrailingIcon: const Icon(Icons.keyboard_arrow_up_rounded),
          label: Text(formFieldLabel(label, required: required)),
          hintText: 'Type to search...',
          dropdownMenuEntries: [
            if (allowEmpty)
              DropdownMenuEntry<String>(
                value: '',
                label: emptyLabel,
                leadingIcon: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 18,
                ),
              ),
            ...options.map(
              (option) => DropdownMenuEntry<String>(
                value: option,
                label: labels[option] ?? _readableOption(option),
                trailingIcon: state.value == option
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF07883F),
                        size: 19,
                      )
                    : null,
              ),
            ),
          ],
          onSelected: enabled
              ? (selected) {
                  final value = selected == '' ? null : selected;
                  state.didChange(value);
                  onChanged(value);
                }
              : null,
        ),
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              state.errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    ),
  );

  static String _readableOption(String value) {
    if (value.isEmpty) return value;
    final words = value.replaceAll('_', ' ');
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null)
          Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) {
    final good = [
      'active',
      'paid',
      'in',
      'income',
    ].contains(value.toLowerCase());
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text(value.replaceAll('_', ' ')),
      backgroundColor: good
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.secondaryContainer,
    );
  }
}
