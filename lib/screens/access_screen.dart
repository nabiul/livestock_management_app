import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../widgets/common.dart';

class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> roles = [];
  Map<String, String> permissions = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final data = widget.api.objectFrom(
        await widget.api.get('access-management'),
      );
      users = _maps(data['users']);
      roles = _maps(data['roles']);
      permissions = data['available_permissions'] is Map
          ? Map<String, String>.from(data['available_permissions'])
          : {};
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value.map((item) => Map<String, dynamic>.from(item as Map)).toList()
      : [];

  Future<void> editUser([Map<String, dynamic>? user]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: user == null ? 'Add user' : 'Edit user',
      child: UserForm(api: widget.api, roles: roles, initial: user),
    );
    if (saved == true) load();
  }

  Future<void> editRole([Map<String, dynamic>? role]) async {
    final saved = await AppSheet.show<bool>(
      context,
      title: role == null ? 'Add role' : 'Edit role',
      child: RoleForm(api: widget.api, permissions: permissions, initial: role),
    );
    if (saved == true) load();
  }

  Future<void> remove(String path, String label) async {
    if (!await confirmAction(
      context,
      'Delete $label',
      'This action cannot be undone.',
    )) {
      return;
    }
    try {
      await widget.api.delete(path);
      load();
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingView();
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Users'),
              Tab(
                icon: Icon(Icons.admin_panel_settings_outlined),
                text: 'Roles',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _list(
                  users,
                  'Add user',
                  editUser,
                  (item) => '${item['name']}',
                  (item) =>
                      '${item['email']} · ${item['role']?['name'] ?? 'No role'} · ${item['status']}',
                  (item) => remove('users/${item['id']}', 'user'),
                ),
                _list(
                  roles,
                  'Add role',
                  editRole,
                  (item) => '${item['name']}',
                  (item) =>
                      '${item['users_count'] ?? 0} users · ${(item['permissions'] as List?)?.length ?? 0} permissions',
                  (item) => remove('roles/${item['id']}', 'role'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    List<Map<String, dynamic>> items,
    String buttonLabel,
    void Function([Map<String, dynamic>?]) edit,
    String Function(Map<String, dynamic>) title,
    String Function(Map<String, dynamic>) subtitle,
    void Function(Map<String, dynamic>) delete,
  ) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: () => edit(),
              icon: const Icon(Icons.add),
              label: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const SizedBox(
              height: 300,
              child: EmptyView(
                icon: Icons.manage_accounts,
                message: 'No records found.',
              ),
            ),
          for (final item in items)
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  title(item),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(subtitle(item)),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') edit(item);
                    if (value == 'delete') delete(item);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UserForm extends StatefulWidget {
  const UserForm({
    super.key,
    required this.api,
    required this.roles,
    this.initial,
  });
  final ApiClient api;
  final List<Map<String, dynamic>> roles;
  final Map<String, dynamic>? initial;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.initial?['name']?.toString(),
  );
  late final email = TextEditingController(
    text: widget.initial?['email']?.toString(),
  );
  final password = TextEditingController();
  late int? roleId =
      int.tryParse('${widget.initial?['role_id'] ?? ''}') ??
      (widget.roles.isEmpty ? null : widget.roles.first['id'] as int?);
  late String status = widget.initial?['status']?.toString() ?? 'active';
  bool saving = false;

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    final payload = {
      'name': name.text.trim(),
      'email': email.text.trim(),
      'password': password.text,
      'role_id': roleId,
      'status': status,
    };
    try {
      if (widget.initial == null) {
        await widget.api.post('users', payload);
      } else {
        await widget.api.put('users/${widget.initial!['id']}', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: key,
    child: Column(
      children: [
        TextFormField(
          controller: name,
          decoration: InputDecoration(
            labelText: formFieldLabel('Full name', required: true),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: formFieldLabel('Email', required: true),
          ),
          validator: _required,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: password,
          obscureText: true,
          decoration: InputDecoration(
            labelText: formFieldLabel(
              widget.initial == null ? 'Password' : 'New password (optional)',
              required: widget.initial == null,
            ),
          ),
          validator: (value) {
            if (widget.initial == null && (value?.length ?? 0) < 8) {
              return 'Use at least 8 characters';
            }
            if (value!.isNotEmpty && value.length < 8) {
              return 'Use at least 8 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        SearchableDropdown(
          label: 'Role',
          items: widget.roles,
          value: roleId,
          required: true,
          onChanged: (value) => roleId = value,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: InputDecoration(
            labelText: formFieldLabel('Status', required: true),
          ),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ],
          onChanged: (value) => status = value ?? 'active',
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : save,
            child: const Text('Save user'),
          ),
        ),
      ],
    ),
  );

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }
}

class RoleForm extends StatefulWidget {
  const RoleForm({
    super.key,
    required this.api,
    required this.permissions,
    this.initial,
  });
  final ApiClient api;
  final Map<String, String> permissions;
  final Map<String, dynamic>? initial;

  @override
  State<RoleForm> createState() => _RoleFormState();
}

class _RoleFormState extends State<RoleForm> {
  final key = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.initial?['name']?.toString(),
  );
  late final Set<String> selected =
      ((widget.initial?['permissions'] as List?) ?? [])
          .map((item) => '$item')
          .toSet();
  bool saving = false;

  Future<void> save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    final payload = {
      'name': name.text.trim(),
      'permissions': selected.toList(),
    };
    try {
      if (widget.initial == null) {
        await widget.api.post('roles', payload);
      } else {
        await widget.api.put('roles/${widget.initial!['id']}', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) showMessage(context, errorMessage(error), error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: key,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: name,
          decoration: InputDecoration(
            labelText: formFieldLabel('Role name', required: true),
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Permissions',
          subtitle: 'Choose which modules this role can access.',
        ),
        for (final entry in widget.permissions.entries)
          CheckboxListTile(
            value: selected.contains(entry.key),
            title: Text(entry.value),
            subtitle: Text(entry.key),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) => setState(
              () => value == true
                  ? selected.add(entry.key)
                  : selected.remove(entry.key),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: saving ? null : save,
            child: const Text('Save role'),
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }
}
