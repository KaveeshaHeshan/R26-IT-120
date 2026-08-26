import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'core/farmer_settings.dart';
import 'core/farmer_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ============================================================
  // FIRESTORE
  // ============================================================

  Future<Map<String, dynamic>?> _loadFarmerDetails() async {
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();

    return userDoc.data();
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _openEditProfileForm(
    FarmerSettings settings,
    Map<String, dynamic> currentData,
  ) async {
    final FarmerPalette p = settings.palette;

    final TextEditingController nameController =
        TextEditingController(text: _editableString(currentData['name']));
    final TextEditingController emailController =
        TextEditingController(text: _editableString(currentData['email']));
    final TextEditingController nicController =
        TextEditingController(text: _editableString(currentData['nic']));
    final TextEditingController phoneController =
        TextEditingController(text: _editableString(currentData['phone']));
    final TextEditingController addressController =
        TextEditingController(text: _editableString(currentData['address']));
    final TextEditingController districtController =
        TextEditingController(text: _editableString(currentData['district']));
    final TextEditingController landSizeController =
        TextEditingController(text: _editableString(currentData['landSize']));
    final TextEditingController rubberTreesController =
        TextEditingController(text: _editableString(currentData['rubberTrees']));
    final TextEditingController experienceController =
        TextEditingController(text: _editableString(currentData['experience']));
    final TextEditingController roleController =
        TextEditingController(text: _editableString(currentData['role']));

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            settings.t('Edit Farmer Details', 'ගොවි විස්තර සංස්කරණය'),
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 500,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.62,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  _editField(p: p, controller: emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _editField(p: p, controller: nicController, label: 'NIC', icon: Icons.badge_outlined),
                  _editField(p: p, controller: roleController, label: 'Farmer Role', icon: Icons.verified_user_outlined),
                  _editField(p: p, controller: nameController, label: settings.t('Name', 'නම'), icon: Icons.person_outline),
                  _editField(p: p, controller: phoneController, label: settings.t('Phone', 'දුරකථන අංකය'), icon: Icons.phone_outlined),
                  _editField(p: p, controller: addressController, label: settings.t('Address', 'ලිපිනය'), icon: Icons.location_on_outlined),
                  _editField(p: p, controller: districtController, label: settings.t('District', 'දිස්ත්‍රික්කය'), icon: Icons.map_outlined),
                  _editField(p: p, controller: landSizeController, label: settings.t('Land Size', 'ඉඩම් ප්‍රමාණය'), icon: Icons.landscape_outlined),
                  _editField(p: p, controller: rubberTreesController, label: settings.t('Rubber Trees', 'රබර් ගස් ගණන'), icon: Icons.park_outlined),
                  _editField(p: p, controller: experienceController, label: settings.t('Experience', 'අත්දැකීම්'), icon: Icons.work_history_outlined),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(settings.t('Cancel', 'අවලංගු කරන්න')),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).set(
                    <String, dynamic>{
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'nic': nicController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'address': addressController.text.trim(),
                      'district': districtController.text.trim(),
                      'landSize': landSizeController.text.trim(),
                      'rubberTrees': rubberTreesController.text.trim(),
                      'experience': experienceController.text.trim(),
                      'role': roleController.text.trim(),
                      'updatedAt': Timestamp.now(),
                    },
                    SetOptions(merge: true),
                  );

                  if (!mounted) return;

                  Navigator.of(dialogContext).pop();
                  setState(() {});

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(settings.t('Profile updated successfully.', 'ගොවි විස්තර සාර්ථකව යාවත්කාලීන කළා.')),
                      backgroundColor: p.primary,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(settings.t('Failed to update profile.', 'විස්තර යාවත්කාලීන කිරීමට නොහැකි විය.'))),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(settings.t('Save', 'සුරකින්න')),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    nicController.dispose();
    phoneController.dispose();
    addressController.dispose();
    districtController.dispose();
    landSizeController.dispose();
    rubberTreesController.dispose();
    experienceController.dispose();
    roleController.dispose();
  }

  Widget _editField({
    required FarmerPalette p,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: p.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: p.textSecondary),
          prefixIcon: Icon(icon, color: p.primary),
          filled: true,
          fillColor: p.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: p.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: p.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: p.primary, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APPEARANCE
  // ============================================================

  Future<void> _showAppearanceDialog(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            settings.t('Appearance', 'පෙනුම'),
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _appearanceOption(
                p: p,
                icon: Icons.light_mode_outlined,
                title: settings.t('Light', 'ආලෝක'),
                selected: !settings.darkMode,
                onTap: () {
                  settings.setDarkMode(false);
                  Navigator.of(dialogContext).pop();
                },
              ),
              const SizedBox(height: 10),
              _appearanceOption(
                p: p,
                icon: Icons.dark_mode_outlined,
                title: settings.t('Dark', 'අඳුරු'),
                selected: settings.darkMode,
                onTap: () {
                  settings.setDarkMode(true);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _appearanceOption({
    required FarmerPalette p,
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.primary.withOpacity(0.10) : p.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.primary : p.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: selected ? p.primary : p.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: p.primary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LANGUAGE
  // ============================================================

  Future<void> _showLanguageDialog(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            settings.t('Language', 'භාෂාව'),
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _languageOption(p, settings, FarmerLanguage.english, 'English', Icons.language),
              const SizedBox(height: 10),
              _languageOption(p, settings, FarmerLanguage.sinhala, 'සිංහල', Icons.translate),
            ],
          ),
        );
      },
    );
  }

  Widget _languageOption(
    FarmerPalette p,
    FarmerSettings settings,
    FarmerLanguage value,
    String title,
    IconData icon,
  ) {
    final bool selected = settings.language == value;

    return InkWell(
      onTap: () {
        settings.setLanguage(value);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? p.primary.withOpacity(0.10) : p.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? p.primary : p.border),
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, color: selected ? p.primary : p.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w700)),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: p.primary),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAboutDialog(FarmerSettings settings) {
    final FarmerPalette p = settings.palette;

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: p.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(13)),
                child: Icon(Icons.eco_rounded, color: p.primary),
              ),
              const SizedBox(width: 12),
              Text(
                settings.t('About Farmer App', 'Farmer App ගැන'),
                style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            settings.t(
              'Farmer App helps farmers manage their farm information, monitor tapping records and keep important agricultural data in one place.',
              'Farmer App මගින් ගොවීන්ට තම ගොවිපළ තොරතුරු කළමනාකරණය කිරීමටත්, tapping records නිරීක්ෂණය කිරීමටත්, වැදගත් කෘෂිකාර්මික දත්ත එකම ස්ථානයක තබා ගැනීමටත් හැකියාව ලැබේ.',
            ),
            style: TextStyle(color: p.textSecondary, height: 1.5),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(settings.t('Close', 'වසන්න')),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SECTIONS
  // ============================================================

  // Rather than dumping every field on screen at once, each category is a
  // single tappable summary card — a farmer taps it to see (and, from
  // there, edit) just that group of details.
  Widget _personalInfoCard(FarmerPalette p, FarmerSettings settings, Map<String, dynamic> data) {
    return _categoryCard(
      p: p,
      title: settings.t('Personal Information', 'පුද්ගලික තොරතුරු'),
      subtitle: settings.t('Tap to view and update', 'බැලීමට හා යාවත්කාලීන කිරීමට තට්ටු කරන්න'),
      icon: Icons.person_outline_rounded,
      onTap: () => _openDetailsSheet(
        settings: settings,
        data: data,
        title: settings.t('Personal Information', 'පුද්ගලික තොරතුරු'),
        icon: Icons.person_outline_rounded,
        rows: <Widget>[
          _detailRow(p, Icons.person_outline, settings.t('Name', 'නම'), _stringValue(data['name'])),
          _detailRow(p, Icons.email_outlined, settings.t('Email', 'විද්‍යුත් තැපෑල'), _stringValue(data['email'])),
          _detailRow(p, Icons.badge_outlined, settings.t('NIC', 'ජාතික හැඳුනුම්පත් අංකය'), _stringValue(data['nic'])),
          _detailRow(p, Icons.phone_outlined, settings.t('Phone', 'දුරකථන අංකය'), _stringValue(data['phone'])),
          _detailRow(p, Icons.location_on_outlined, settings.t('Address', 'ලිපිනය'), _stringValue(data['address'])),
          _detailRow(p, Icons.map_outlined, settings.t('District', 'දිස්ත්‍රික්කය'), _stringValue(data['district'])),
        ],
      ),
    );
  }

  Widget _farmInfoCard(FarmerPalette p, FarmerSettings settings, Map<String, dynamic> data) {
    return _categoryCard(
      p: p,
      title: settings.t('Farm Information', 'ගොවිපළ තොරතුරු'),
      subtitle: settings.t('Tap to view and update', 'බැලීමට හා යාවත්කාලීන කිරීමට තට්ටු කරන්න'),
      icon: Icons.agriculture_outlined,
      onTap: () => _openDetailsSheet(
        settings: settings,
        data: data,
        title: settings.t('Farm Information', 'ගොවිපළ තොරතුරු'),
        icon: Icons.agriculture_outlined,
        rows: <Widget>[
          _detailRow(p, Icons.landscape_outlined, settings.t('Land Size', 'ඉඩම් ප්‍රමාණය'), _stringValue(data['landSize'])),
          _detailRow(p, Icons.park_outlined, settings.t('Rubber Trees', 'රබර් ගස් ගණන'), _stringValue(data['rubberTrees'])),
          _detailRow(p, Icons.work_history_outlined, settings.t('Experience', 'අත්දැකීම්'), _stringValue(data['experience'])),
          _detailRow(p, Icons.verified_user_outlined, settings.t('Farmer Role', 'ගොවි භූමිකාව'), _stringValue(data['role'])),
        ],
      ),
    );
  }

  Widget _categoryCard({
    required FarmerPalette p,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          boxShadow: p.cardShadow,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: p.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: p.primary),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: p.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11.5, color: p.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }

  void _openDetailsSheet({
    required FarmerSettings settings,
    required Map<String, dynamic> data,
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    final FarmerPalette p = settings.palette;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: p.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(13)),
                      child: Icon(icon, color: p.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: p.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...rows,
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: FarmerMetrics.buttonHeight,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.primary,
                      foregroundColor: p.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openEditProfileForm(settings, data);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(settings.t('Edit Details', 'විස්තර සංස්කරණය')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required FarmerPalette p,
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: p.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: p.primary.withOpacity(0.10), borderRadius: BorderRadius.circular(13)),
                  child: Icon(icon, color: p.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: p.textPrimary, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(FarmerPalette p, IconData icon, String label, String value) {
    final String displayValue = value == '-' || value.trim().isEmpty ? '-' : value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(13)),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 19, color: p.primary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label, style: TextStyle(color: p.textSecondary, fontSize: 10.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(displayValue, style: TextStyle(color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETTINGS
  // ============================================================

  Widget _settingsSection(FarmerPalette p, FarmerSettings settings) {
    return _sectionCard(
      p: p,
      title: settings.t('Settings', 'සැකසුම්'),
      icon: Icons.settings_outlined,
      children: <Widget>[
        _settingsTile(
          p: p,
          icon: Icons.dark_mode_outlined,
          title: settings.t('Appearance', 'පෙනුම'),
          subtitle: settings.darkMode ? settings.t('Dark mode', 'අඳුරු මාදිලිය') : settings.t('Light mode', 'ආලෝක මාදිලිය'),
          onTap: () => _showAppearanceDialog(settings),
          trailing: Switch(
            value: settings.darkMode,
            activeThumbColor: p.primary,
            onChanged: (bool value) => settings.setDarkMode(value),
          ),
        ),
        _settingsTile(
          p: p,
          icon: Icons.language_outlined,
          title: settings.t('Language', 'භාෂාව'),
          subtitle: settings.language == FarmerLanguage.sinhala ? 'සිංහල' : 'English',
          onTap: () => _showLanguageDialog(settings),
          trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ),
        _settingsTile(
          p: p,
          icon: Icons.info_outline_rounded,
          title: settings.t('About', 'ගැන'),
          subtitle: settings.t('About Farmer App', 'Farmer App පිළිබඳ'),
          onTap: () => _showAboutDialog(settings),
          trailing: Icon(Icons.chevron_right_rounded, color: p.textMuted),
        ),
        Divider(height: 24, color: p.border),
        _settingsTile(
          p: p,
          icon: Icons.logout_rounded,
          title: settings.t('Log Out', 'ඉවත් වන්න'),
          subtitle: settings.t('Sign out of your account', 'ගිණුමෙන් ඉවත් වන්න'),
          onTap: () => _logout(settings),
          trailing: Icon(Icons.chevron_right_rounded, color: p.danger),
          danger: true,
        ),
      ],
    );
  }

  Widget _settingsTile({
    required FarmerPalette p,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Widget trailing,
    bool danger = false,
  }) {
    final Color tint = danger ? p.danger : p.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: danger ? p.danger.withOpacity(0.10) : p.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: tint, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: TextStyle(color: tint, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: p.textSecondary, fontSize: 10.5)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(FarmerSettings settings) async {
    final FarmerPalette p = settings.palette;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: p.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            settings.t('Log out?', 'ඉවත් වන්නද?'),
            style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          content: Text(
            settings.t("You'll need to sign in again to access the farmer app.", 'නැවත ඇතුළු වීමට අවශ්‍ය වේ.'),
            style: TextStyle(color: p.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(settings.t('Cancel', 'අවලංගු කරන්න')),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: p.danger),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(settings.t('Log Out', 'ඉවත් වන්න')),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _profileHeader(FarmerPalette p, FarmerSettings settings, Map<String, dynamic> data) {
    final String name = _stringValue(data['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[p.primary, p.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(color: p.primary.withOpacity(0.24), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.30)),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  name == '-' ? 'Farmer' : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  _stringValue(data['district']) == '-'
                      ? settings.t('Farmer Profile', 'ගොවි පැතිකඩ')
                      : _stringValue(data['district']),
                  style: TextStyle(color: Colors.white.withOpacity(0.78), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final FarmerSettings settings = FarmerSettingsScope.of(context);
    final FarmerPalette p = settings.palette;

    return FarmerScreenBackground(
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _loadFarmerDetails(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox.expand(child: Center(child: CircularProgressIndicator(color: p.primary)));
          }

          if (snapshot.hasError) {
            return SizedBox.expand(
              child: Center(
                child: Text(
                  settings.t('Failed to load profile details.', 'ගොවි විස්තර ලබා ගැනීමට නොහැකි විය.'),
                  style: TextStyle(color: p.textPrimary),
                ),
              ),
            );
          }

          final Map<String, dynamic> data = snapshot.data ?? <String, dynamic>{};

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: <Widget>[
              _profileHeader(p, settings, data),
              _personalInfoCard(p, settings, data),
              _farmInfoCard(p, settings, data),
              const SizedBox(height: 2),
              _settingsSection(p, settings),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Farmer App',
                  style: TextStyle(color: p.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: p.textSecondary.withOpacity(0.7), fontSize: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _stringValue(dynamic value) {
    if (value == null) return '-';

    final String result = value.toString().trim();

    if (result.isEmpty) return '-';

    return result;
  }

  String _editableString(dynamic value) {
    if (value == null) return '';

    return value.toString().trim();
  }
}
