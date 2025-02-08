import 'package:flutter/material.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          tr(context, 'sign_up_login'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'select_country'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.cardColor,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr(context, 'united_kingdom'),
                      style: theme.textTheme.bodyLarge,
                    ),
                    Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Social Login Buttons (keeping white for Google, blue for Facebook)
              OutlinedButton.icon(
                onPressed: () {},
                icon: const SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      Image(image: AssetImage('assets/images/google_logo.jpg')),
                ),
                label: Text(
                  tr(context, 'continue_google'),
                  style: const TextStyle(color: Colors.black),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const SizedBox(
                  width: 24,
                  height: 24,
                  child: Image(
                      image: AssetImage('assets/images/facebook_logo.jpg')),
                ),
                label: Text(
                  tr(context, 'continue_facebook'),
                  style: const TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      tr(context, 'or'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ),
              const SizedBox(height: 32),

              // Email Input
              TextFormField(
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: tr(context, 'email_address'),
                  labelStyle: theme.textTheme.bodyMedium,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.primaryColor),
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
              ),
              const SizedBox(height: 24),

              // Continue Button
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/main'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr(context, 'continue_email'),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Terms Text
              Text(
                tr(context, 'terms_conditions'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
