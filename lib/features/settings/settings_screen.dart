import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers.dart';
import '../onboarding/onboarding_screen.dart';
import '../profile/profile_setup_screen.dart';
import '../../screens/privacy_policy_screen.dart';

const _privacyPolicyUrl =
    'https://operonte.github.io/releases/coroapp/policies/privacy_policy.html';
const _termsOfUseUrl =
    'https://operonte.github.io/releases/coroapp/policies/terms_of_use.html';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '—';
  String _buildNumber = '—';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        children: [
          _SectionTitle(title: 'Información'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de'),
            subtitle: Text('CoroApp v$_version (build $_buildNumber)'),
            onTap: () => _showAbout(context),
          ),
          const Divider(),
          _SectionTitle(title: 'Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Política de privacidad'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Términos de uso'),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _openUrl(_termsOfUseUrl),
          ),
          const Divider(),
          _SectionTitle(title: 'Perfil'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Cambiar voz y coro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ProfileSetupScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.admin_panel_settings_outlined),
            title: const Text('Jefe de grupo'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LeaderPasswordScreen(),
                ),
              );
            },
          ),
          const Divider(),
          _SectionTitle(title: 'Ayuda'),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Tutorial'),
            subtitle: const Text('Ver guía de bienvenida'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OnboardingScreen(
                    isTutorial: true,
                    onComplete: () => Navigator.of(context).pop(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CoroApp',
      applicationVersion: '$_version ($_buildNumber)',
      applicationLegalese: 'Organización de repertorio de coros cristianos.',
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class LeaderPasswordScreen extends ConsumerStatefulWidget {
  const LeaderPasswordScreen({super.key});

  @override
  ConsumerState<LeaderPasswordScreen> createState() =>
      _LeaderPasswordScreenState();
}

class _LeaderPasswordScreenState extends ConsumerState<LeaderPasswordScreen> {
  final _controller = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final password = _controller.text.trim();
    if (password.isEmpty) {
      setState(() => _error = 'Ingresa la contraseña');
      return;
    }

    final appUserAsync = ref.read(currentAppUserProvider);
    final appUser = appUserAsync.value;
    if (appUser == null || appUser.choirId == null) {
      setState(() => _error = 'Debes tener un coro asignado');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final firestore = ref.read(firestoreProvider);
      final choirDoc =
          await firestore.collection('choirs').doc(appUser.choirId!).get();

      if (!choirDoc.exists) {
        setState(() {
          _error = 'Coro no encontrado';
          _loading = false;
        });
        return;
      }

      final storedPassword = choirDoc.data()?['leaderPassword'] as String?;
      if (storedPassword == null || storedPassword.isEmpty) {
        setState(() {
          _error = 'Este coro no tiene contraseña de jefe configurada';
          _loading = false;
        });
        return;
      }

      if (password != storedPassword) {
        setState(() {
          _error = 'Contraseña incorrecta';
          _loading = false;
        });
        return;
      }

      await firestore.collection('users').doc(appUser.id).update({
        'role': 'admin_coro',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Ahora eres jefe de grupo!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Error al verificar';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jefe de grupo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ingresa la contraseña del coro para convertirte en jefe de grupo.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                border: const OutlineInputBorder(),
                errorText: _error,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verificar'),
            ),
          ],
        ),
      ),
    );
  }
}
