import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoodSamaritanScreen extends StatelessWidget {
  const GoodSamaritanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryRed = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Protection'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.gavel_rounded,
                      color: Colors.blueAccent,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'GOOD SAMARITAN LAW',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'You are legally protected. Act without fear.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 32),

                // Core Protections Card
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.1),
                          Colors.blueAccent.withOpacity(0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProtectionItem(
                          title: 'No Civil or Criminal Liability',
                          description: 'Under Indian Law (Section 134A of MV Act), bystanders who offer medical or non-medical care at an accident scene in good faith cannot be held liable for any injury or death.',
                          icon: Icons.shield_rounded,
                        ),
                        const Divider(height: 32, color: Colors.white12),
                        _buildProtectionItem(
                          title: 'No Mandatory Disclosure',
                          description: 'You are NOT forced to reveal your name, address, or phone number to the police or medical staff. Choosing to remain anonymous is your legal right.',
                          icon: Icons.visibility_off_rounded,
                        ),
                        const Divider(height: 32, color: Colors.white12),
                        _buildProtectionItem(
                          title: 'No Hospital Charges or Delays',
                          description: 'Hospitals are legally required to attend to the victim instantly. They cannot demand payment or register a case before beginning emergency treatment.',
                          icon: Icons.local_hospital_rounded,
                        ),
                        const Divider(height: 32, color: Colors.white12),
                        _buildProtectionItem(
                          title: 'No Police Station Visits',
                          description: 'You cannot be forced to visit the police station for questioning. Any examination must occur at your convenience, or via video conference.',
                          icon: Icons.local_police_rounded,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Dismiss Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'I UNDERSTAND, DISMISS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionItem({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
