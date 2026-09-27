import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../domain/entities/app_role.dart';
import '../../../domain/entities/user_profile.dart';
import '../../role/bloc/role_cubit.dart';
import '../bloc/profile_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProfileCubit(context.read<AppDependencies>()),
    child: const _ProfileView(),
  );
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<RoleCubit>().state == AppRole.admin;
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: state.error != null
            ? ErrorState(onRetry: context.read<ProfileCubit>().reload)
            : !state.ready || state.profile == null
            ? const Center(child: CircularProgressIndicator())
            : ProfileContent(profile: state.profile!, isAdmin: isAdmin),
      ),
    );
  }
}

class ProfileContent extends StatelessWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    required this.isAdmin,
  });

  final UserProfile profile;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
    children: [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF597BFF)],
          ),
        ),
        child: Column(
          children: [
            _ProfileAvatar(
              path: profile.profileImagePath,
              initials: _initials(profile),
            ),
            const SizedBox(height: 16),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              profile.email.isEmpty ? 'No email on file' : profile.email,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: () => context.push(
                isAdmin ? '/admin/profile/edit' : '/profile/edit',
              ),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit profile'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 26),
      Text('Account', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _SettingRow(
              icon: Icons.swap_horiz_rounded,
              title: isAdmin ? 'Switch to User Mode' : 'Switch to Admin Mode',
              subtitle: isAdmin
                  ? 'Return to your categories and expenses'
                  : 'Review submitted expenses',
              onTap: () {
                final router = GoRouter.of(context);
                context.read<RoleCubit>().switchTo(
                  isAdmin ? AppRole.user : AppRole.admin,
                );
                router.go(isAdmin ? '/categories' : '/admin/expenses');
              },
            ),
            const Divider(height: 1, indent: 68),
            _SettingRow(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'How this local app works',
              onTap: () => _showInformation(context, terms: true),
            ),
            const Divider(height: 1, indent: 68),
            _SettingRow(
              icon: Icons.shield_outlined,
              title: 'Privacy Policy',
              subtitle: 'Your data stays on this device',
              onTap: () => _showInformation(context, terms: false),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Center(
        child: Text(
          'Your profile and expense records are saved locally.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ),
      const SizedBox(height: 24),
      const Center(
        child: Column(
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            SizedBox(height: 6),
            Text(
              'Made with ♥ by Ani Harutyunyan',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

String _initials(UserProfile profile) {
  final first = profile.firstName.trim();
  final last = profile.lastName.trim();
  return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
      .toUpperCase();
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.path, required this.initials});

  final String? path;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final image = path != null && File(path!).existsSync() ? File(path!) : null;
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.file(
              image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(22),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    ),
  );
}

void _showInformation(BuildContext context, {required bool terms}) {
  showIosSheet<void>(
    context,
    (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text(
              terms ? 'Terms & Conditions' : 'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            if (terms) ...[
              const Text(
                'Use the app to keep your own expense records on this device. '
                'The user and admin views are local modes, not authenticated '
                'accounts. Switching roles changes the available screens but '
                'does not grant or verify real-world authorization.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Please check amounts, dates and receipt images before '
                'submitting or reviewing. Back up important records yourself. '
                'Removing the app or its data may remove your records.',
              ),
            ] else ...[
              const Text(
                'Your profile, categories, expenses, and copied receipt images '
                'are stored in this app’s local documents and database. The '
                'app does not require sign-in or upload these records to a '
                'service for its ordinary features.',
              ),
              const SizedBox(height: 16),
              const Text(
                'You choose when to share exported PDFs through your device’s '
                'share sheet. Shared copies then follow the destination app’s '
                'privacy rules. Photo library or camera access is requested '
                'only when you choose to attach or scan an image.',
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
