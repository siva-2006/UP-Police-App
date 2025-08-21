import 'package:eclub_app/main.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreSettingsPage extends StatefulWidget {
  const MoreSettingsPage({super.key});

  @override
  State<MoreSettingsPage> createState() => _MoreSettingsPageState();
}

class _MoreSettingsPageState extends State<MoreSettingsPage> {
  bool screamDetectionEnabled = false;
  String _selectedFrequency = "5";
  final List<String> _frequencyOptions = ["5", "10", "15", "20", "30"];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // NEW: Load the saved setting from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // CHANGED: The default value is now 'true'
      screamDetectionEnabled = prefs.getBool('screamDetectionEnabled') ?? true;
      _selectedFrequency = prefs.getString('locationFrequency') ?? "5";
    });
  }

  // NEW: Save the scream detection setting
  Future<void> _setScreamDetection(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      screamDetectionEnabled = value;
    });
    await prefs.setBool('screamDetectionEnabled', value);
  }

  // NEW: Save the frequency setting
  Future<void> _setFrequency(String? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedFrequency = value;
    });
    await prefs.setString('locationFrequency', value);
  }


  Widget _buildSettingTile({
    required BuildContext context,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontSize: 16,
                ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue.shade700,
            inactiveTrackColor: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyTile(BuildContext context, bool isHindi) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isHindi ? 'स्थान भेजने की आवृत्ति' : 'Location Sending Frequency',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedFrequency,
                onChanged: (String? newValue) {
                  _setFrequency(newValue); // Save the new value
                },
                items: _frequencyOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text("$value sec"),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              isHindi
                  ? 'आपातकालीन संपर्कों और पुलिस को स्थान और एसएमएस भेजने के बीच का अंतराल।'
                  : "Interval between sending location and SMS to emergency contacts and police.",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(bool isHindi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: MaterialButton(
        onPressed: () => languageNotifier.toggleLanguage(),
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isHindi ? 'भाषा बदलें (English)' : 'Change Language (हिन्दी)',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 16,
                  ),
            ),
            Icon(Icons.language, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageNotifier,
      builder: (context, child) {
        final isHindi = languageNotifier.isHindi;
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(isHindi ? 'अधिक सेटिंग्स' : 'More Settings'),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildSettingTile(
                    context: context,
                    label: isHindi ? 'चीख पहचान' : 'Scream detection',
                    value: screamDetectionEnabled,
                    onChanged: (val) {
                      _setScreamDetection(val); // Save the new value
                    },
                  ),
                  _buildFrequencyTile(context, isHindi),
                  const SizedBox(height: 20),
                  _buildLanguageButton(isHindi),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}