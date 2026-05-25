import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/profile/data/profile_repository.dart';
import 'package:frontend/features/profile/domain/profile.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final Profile profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  bool _isLoading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  String? _selectedCountry;
  String? _selectedOccupation;

  final List<Map<String, String>> _countries = [
    {'code': 'VN', 'name': 'Việt Nam', 'flag': '🇻🇳'},
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'UK', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'SG', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': 'JP', 'name': 'Japan', 'flag': '🇯🇵'},
    {'code': 'KR', 'name': 'South Korea', 'flag': '🇰🇷'},
    {'code': 'TH', 'name': 'Thailand', 'flag': '🇹🇭'},
    {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'CN', 'name': 'China', 'flag': '🇨🇳'},
    {'code': 'RU', 'name': 'Russia', 'flag': '🇷🇺'},
    {'code': 'BR', 'name': 'Brazil', 'flag': '🇧🇷'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
    {'code': 'ID', 'name': 'Indonesia', 'flag': '🇮🇩'},
    {'code': 'MY', 'name': 'Malaysia', 'flag': '🇲🇾'},
    {'code': 'PH', 'name': 'Philippines', 'flag': '🇵🇭'},
    {'code': 'IT', 'name': 'Italy', 'flag': '🇮🇹'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
    {'code': 'CH', 'name': 'Switzerland', 'flag': '🇨🇭'},
    {'code': 'SE', 'name': 'Sweden', 'flag': '🇸🇪'},
    {'code': 'NO', 'name': 'Norway', 'flag': '🇳🇴'},
    {'code': 'DK', 'name': 'Denmark', 'flag': '🇩🇰'},
    {'code': 'FI', 'name': 'Finland', 'flag': '🇫🇮'},
    {'code': 'NZ', 'name': 'New Zealand', 'flag': '🇳🇿'},
    {'code': 'AE', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'code': 'SA', 'name': 'Saudi Arabia', 'flag': '🇸🇦'},
    {'code': 'TR', 'name': 'Turkey', 'flag': '🇹🇷'},
    {'code': 'MX', 'name': 'Mexico', 'flag': '🇲🇽'},
    {'code': 'AR', 'name': 'Argentina', 'flag': '🇦🇷'},
    {'code': 'ZA', 'name': 'South Africa', 'flag': '🇿🇦'},
    {'code': 'EG', 'name': 'Egypt', 'flag': '🇪🇬'},
    {'code': 'IL', 'name': 'Israel', 'flag': '🇮🇱'},
    {'code': 'PL', 'name': 'Poland', 'flag': '🇵🇱'},
    {'code': 'BE', 'name': 'Belgium', 'flag': '🇧🇪'},
    {'code': 'AT', 'name': 'Austria', 'flag': '🇦🇹'},
    {'code': 'GR', 'name': 'Greece', 'flag': '🇬🇷'},
    {'code': 'PT', 'name': 'Portugal', 'flag': '🇵🇹'},
    {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪'},
    {'code': 'TW', 'name': 'Taiwan', 'flag': '🇹🇼'},
    {'code': 'HK', 'name': 'Hong Kong', 'flag': '🇭🇰'},
    {'code': 'UA', 'name': 'Ukraine', 'flag': '🇺🇦'},
    {'code': 'CZ', 'name': 'Czech Republic', 'flag': '🇨🇿'},
    {'code': 'HU', 'name': 'Hungary', 'flag': '🇭🇺'},
    {'code': 'RO', 'name': 'Romania', 'flag': '🇷🇴'},
    {'code': 'CL', 'name': 'Chile', 'flag': '🇨🇱'},
    {'code': 'CO', 'name': 'Colombia', 'flag': '🇨🇴'},
    {'code': 'PE', 'name': 'Peru', 'flag': '🇵🇪'},
    {'code': 'PK', 'name': 'Pakistan', 'flag': '🇵🇰'},
    {'code': 'BD', 'name': 'Bangladesh', 'flag': '🇧🇩'},
    {'code': 'OTHER', 'name': 'Other', 'flag': '🌍'},
  ];

  final List<Map<String, String>> _occupations = [
    {'id': 'tech', 'name': 'Technology & Software', 'icon': '💻'},
    {'id': 'healthcare', 'name': 'Healthcare & Medicine', 'icon': '⚕️'},
    {'id': 'education', 'name': 'Education & Training', 'icon': '📚'},
    {'id': 'banking', 'name': 'Banking & Financial Services', 'icon': '💰'},
    {'id': 'accounting', 'name': 'Accounting & Finance', 'icon': '📊'},
    {'id': 'manufacturing', 'name': 'Manufacturing', 'icon': '🏭'},
    {'id': 'retail', 'name': 'Retail & E-commerce', 'icon': '🛒'},
    {'id': 'construction', 'name': 'Construction & Trades', 'icon': '🏗️'},
    {'id': 'hospitality', 'name': 'Hospitality & Tourism', 'icon': '🏨'},
    {'id': 'media', 'name': 'Media, Arts & Entertainment', 'icon': '🎭'},
    {'id': 'government', 'name': 'Government & Public Service', 'icon': '🏛️'},
    {'id': 'legal', 'name': 'Legal Services', 'icon': '⚖️'},
    {'id': 'science', 'name': 'Science & Research', 'icon': '🔬'},
    {'id': 'transport', 'name': 'Transportation & Logistics', 'icon': '🚚'},
    {'id': 'realestate', 'name': 'Real Estate', 'icon': '🏠'},
    {'id': 'agriculture', 'name': 'Agriculture & Mining', 'icon': '🌽'},
    {'id': 'energy', 'name': 'Energy & Utilities', 'icon': '⚡'},
    {'id': 'proservices', 'name': 'Professional Services', 'icon': '💼'},
    {'id': 'nonprofit', 'name': 'Non-profit & Social Services', 'icon': '🤝'},
    {'id': 'student', 'name': 'Student', 'icon': '📖'},
    {'id': 'freelancer', 'name': 'Freelancer', 'icon': '👨‍💻'},
    {'id': 'unemployed', 'name': 'Unemployed', 'icon': '⏳'},
    {'id': 'other', 'name': 'Other', 'icon': '👤'},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _selectedCountry = widget.profile.country;
    _selectedOccupation = widget.profile.occupation;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      
      String? avatarUrl = widget.profile.avatarUrl;
      
      // Upload image if changed
      if (_imageFile != null) {
        avatarUrl = await repo.uploadAvatar(
          _imageFile!,
          oldAvatarUrl: widget.profile.avatarUrl,
        );
      }

      await repo.updateProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: avatarUrl,
        country: _selectedCountry,
        occupation: _selectedOccupation,
      );

      ToastService.showSuccess("Profile updated successfully.");
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ToastService.showError(AuthErrorHandler.getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _save,
              child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar edit
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: _imageFile != null 
                        ? FileImage(_imageFile!) 
                        : (widget.profile.avatarUrl != null ? NetworkImage(widget.profile.avatarUrl!) : null) as ImageProvider?,
                      child: (_imageFile == null && widget.profile.avatarUrl == null)
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Fields
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Bro, what's your name?" : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Set a cool username!" : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Bio",
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.info_outline),
                  ),
                  border: OutlineInputBorder(),
                  hintText: "Tell other bros about yourself...",
                ),
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                value: _countries.any((c) => c['name'] == _selectedCountry) ? _selectedCountry : null,
                decoration: const InputDecoration(
                  labelText: "Country",
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(),
                ),
                items: _countries.map((c) => DropdownMenuItem(
                  value: c['name'],
                  child: Text("${c['flag']} ${c['name']}"),
                )).toList(),
                onChanged: (v) => setState(() => _selectedCountry = v),
              ),
              const SizedBox(height: 20),

              // Occupation Dropdown
              DropdownButtonFormField<String>(
                value: _occupations.any((o) => o['name'] == _selectedOccupation) ? _selectedOccupation : null,
                decoration: const InputDecoration(
                  labelText: "Current Occupation",
                  prefixIcon: Icon(Icons.work_outline),
                  border: OutlineInputBorder(),
                ),
                items: _occupations.map((o) => DropdownMenuItem(
                  value: o['name'],
                  child: Text("${o['icon']} ${o['name']}"),
                )).toList(),
                onChanged: (v) => setState(() => _selectedOccupation = v),
              ),
              
              const SizedBox(height: 30),
              const Text(
                "Updating your profile helps other bros know you better.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
