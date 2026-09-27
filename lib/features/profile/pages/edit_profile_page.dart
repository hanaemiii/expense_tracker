import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di/dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../bloc/profile_cubit.dart';

String? validateProfileEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isNotEmpty &&
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address or leave it blank';
  }
  return null;
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ProfileCubit(context.read<AppDependencies>()),
    child: const _EditProfileView(),
  );
}

class _EditProfileView extends StatefulWidget {
  const _EditProfileView();

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ProfileCubit, ProfileState>(
    listenWhen: (previous, current) => previous.noticeId != current.noticeId,
    listener: (context, state) {
      if (state.notice != null) {
        showFeedback(context, state.notice!, error: state.noticeIsError);
      }
    },
    builder: (context, state) {
      final profile = state.profile;
      if (profile != null && !_initialized) {
        _firstName.text = profile.firstName;
        _lastName.text = profile.lastName;
        _email.text = profile.email;
        _initialized = true;
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Edit profile')),
        body: state.error != null
            ? ErrorState(onRetry: context.read<ProfileCubit>().reload)
            : !state.ready || profile == null
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 50),
                  children: [
                    AppCard(
                      child: Column(
                        children: [
                          _PhotoPreview(
                            path: state.imagePath,
                            firstName: _firstName.text,
                            lastName: _lastName.text,
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: state.busy
                                ? null
                                : context.read<ProfileCubit>().choosePicture,
                            icon: const Icon(Icons.add_a_photo_rounded),
                            label: const Text('Choose profile photo'),
                          ),
                          const Text(
                            'The selected image is copied into this app and '
                            'saved with your profile when you tap Save.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'Your details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _firstName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'First name',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'First name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _lastName,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Last name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Last name is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        helperText: 'Optional · stored only on this device',
                      ),
                      validator: validateProfileEmail,
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: state.busy ? null : _save,
                      icon: state.busy
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: const Text('Save changes'),
                    ),
                  ],
                ),
              ),
      );
    },
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await context.read<ProfileCubit>().save(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
    );
    if (saved && mounted) context.pop();
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.path,
    required this.firstName,
    required this.lastName,
  });

  final String? path;
  final String firstName;
  final String lastName;

  @override
  Widget build(BuildContext context) {
    final file = path == null ? null : File(path!);
    final initials =
        '${firstName.trim().isEmpty ? '' : firstName.trim()[0]}'
                '${lastName.trim().isEmpty ? '' : lastName.trim()[0]}'
            .toUpperCase();
    return Container(
      width: 105,
      height: 105,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Color(0xFFEDF1FF),
        shape: BoxShape.circle,
      ),
      child: file == null || !file.existsSync()
          ? Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 48,
              ),
            ),
    );
  }
}
