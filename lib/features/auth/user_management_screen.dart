import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'user_repository.dart';

final userRepoProvider = Provider((ref) => UserRepository());

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshUsers();
  }

  void _refreshUsers() {
    setState(() {
      _usersFuture = ref.read(userRepoProvider).getUsers();
    });
  }

  void _showUserDialog([Map<String, dynamic>? user]) async {
    final roles = await ref.read(userRepoProvider).getRoles();
    final sucursales = await ref.read(userRepoProvider).getSucursales();

    if (!mounted) return;

    final nameController = TextEditingController(
      text: user?['nombre_completo'],
    );
    final userController = TextEditingController(text: user?['username']);
    final passController = TextEditingController();
    int? selectedRole = user?['role_id'];
    int? selectedSucursal = user?['sucursal_id'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Nuevo Usuario' : 'Editar Usuario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                  ),
                ),
                TextField(
                  controller: userController,
                  enabled: user == null,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                  ),
                ),
                TextField(
                  controller: passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: user == null
                        ? 'Contraseña'
                        : 'Nueva Contraseña (dejar vacío para no cambiar)',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Rol'),
                  items: roles
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['id'] as int,
                          child: Text(r['nombre'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: selectedSucursal,
                  decoration: const InputDecoration(labelText: 'Sucursal'),
                  items: sucursales
                      .map(
                        (s) => DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(s['nombre'] as String),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedSucursal = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (user == null) {
                  await ref
                      .read(userRepoProvider)
                      .createUser(
                        username: userController.text,
                        password: passController.text,
                        nombreCompleto: nameController.text,
                        roleId: selectedRole!,
                        sucursalId: selectedSucursal!,
                      );
                } else {
                  await ref
                      .read(userRepoProvider)
                      .updateUser(
                        id: user['id'],
                        nombreCompleto: nameController.text,
                        roleId: selectedRole!,
                        sucursalId: selectedSucursal!,
                        password: passController.text.isEmpty
                            ? null
                            : passController.text,
                      );
                }
                // ignore: use_build_context_synchronously
                Navigator.pop(context);
                _refreshUsers();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Nuevo Usuario'),
            style: ElevatedButton.styleFrom(),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Rol')),
                  DataColumn(label: Text('Sucursal')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Acciones')),
                ],
                rows: users
                    .map(
                      (u) => DataRow(
                        cells: [
                          DataCell(Text(u['nombre_completo'])),
                          DataCell(Text(u['username'])),
                          DataCell(Text(u['rol'])),
                          DataCell(Text(u['sucursal'])),
                          DataCell(
                            Switch(
                              value: u['activo'],
                              onChanged: (val) async {
                                await ref
                                    .read(userRepoProvider)
                                    .toggleUserStatus(u['id'], val);
                                _refreshUsers();
                              },
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showUserDialog(u),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
