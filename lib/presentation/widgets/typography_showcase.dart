import 'package:flutter/material.dart';
import '../../core/constants/text_styles.dart';

/// Typography Showcase Widget
/// 
/// Displays all typography styles defined in the unified typography system.
/// Use this widget for design review and documentation purposes.
class TypographyShowcase extends StatelessWidget {
  const TypographyShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Typography System'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Styles
            _buildSection(
              title: 'Display Styles',
              children: [
                _buildTypographyItem(
                  label: 'Display Large (57px)',
                  style: AppTypography.displayLarge,
                  text: 'Welcome to Coopvest Africa',
                ),
                _buildTypographyItem(
                  label: 'Display Medium (45px)',
                  style: AppTypography.displayMedium,
                  text: 'Investment Platform',
                ),
                _buildTypographyItem(
                  label: 'Display Small (36px)',
                  style: AppTypography.displaySmall,
                  text: 'Grow Your Wealth',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Headline Styles
            _buildSection(
              title: 'Headline Styles',
              children: [
                _buildTypographyItem(
                  label: 'Headline Large (32px)',
                  style: AppTypography.headlineLarge,
                  text: 'Investment Opportunities',
                ),
                _buildTypographyItem(
                  label: 'Headline Medium (28px)',
                  style: AppTypography.headlineMedium,
                  text: 'Loan Application',
                ),
                _buildTypographyItem(
                  label: 'Headline Small (24px)',
                  style: AppTypography.headlineSmall,
                  text: 'Account Settings',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Title Styles
            _buildSection(
              title: 'Title Styles',
              children: [
                _buildTypographyItem(
                  label: 'Title Large (22px)',
                  style: AppTypography.titleLarge,
                  text: 'Dialog Title',
                ),
                _buildTypographyItem(
                  label: 'Title Medium (18px)',
                  style: AppTypography.titleMedium,
                  text: 'Form Section Header',
                ),
                _buildTypographyItem(
                  label: 'Title Small (16px)',
                  style: AppTypography.titleSmall,
                  text: 'Card Title',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Body Styles
            _buildSection(
              title: 'Body Styles',
              children: [
                _buildTypographyItem(
                  label: 'Body Large (16px)',
                  style: AppTypography.bodyLarge,
                  text: 'This is primary body text used for main content and descriptions. It has a comfortable line height for readability.',
                ),
                _buildTypographyItem(
                  label: 'Body Medium (14px)',
                  style: AppTypography.bodyMedium,
                  text: 'This is secondary body text used for supporting content and additional information.',
                ),
                _buildTypographyItem(
                  label: 'Body Small (12px)',
                  style: AppTypography.bodySmall,
                  text: 'This is tertiary text used for captions and helper text.',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Label Styles
            _buildSection(
              title: 'Label Styles',
              children: [
                _buildTypographyItem(
                  label: 'Label Large (14px)',
                  style: AppTypography.labelLarge,
                  text: 'BUTTON TEXT',
                ),
                _buildTypographyItem(
                  label: 'Label Medium (12px)',
                  style: AppTypography.labelMedium,
                  text: 'BADGE',
                ),
                _buildTypographyItem(
                  label: 'Label Small (11px)',
                  style: AppTypography.labelSmall,
                  text: 'TAG',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Font Families
            _buildSection(
              title: 'Font Families',
              children: [
                _buildFontInfo(
                  name: 'Primary Font: Inter',
                  description: 'Used for body text, UI elements, and general content',
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: AppTypography.primaryFont,
                  ),
                ),
                _buildFontInfo(
                  name: 'Secondary Font: Poppins',
                  description: 'Used for headings, display text, and emphasis',
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: AppTypography.secondaryFont,
                  ),
                ),
                _buildFontInfo(
                  name: 'Monospace Font: JetBrains Mono',
                  description: 'Used for code, technical content, and data display',
                  style: AppTypography.bodyLarge.copyWith(
                    fontFamily: AppTypography.monoFont,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Usage Examples
            _buildSection(
              title: 'Usage Examples',
              children: [
                _buildUsageExample(
                  title: 'Page Header',
                  code: 'Text("Welcome", style: AppTypography.displayLarge)',
                  preview: Text(
                    'Welcome',
                    style: AppTypography.displayLarge,
                  ),
                ),
                _buildUsageExample(
                  title: 'Card Title',
                  code: 'Text("Investment", style: AppTypography.headlineLarge)',
                  preview: Text(
                    'Investment',
                    style: AppTypography.headlineLarge,
                  ),
                ),
                _buildUsageExample(
                  title: 'Body Text',
                  code: 'Text("Description", style: AppTypography.bodyMedium)',
                  preview: Text(
                    'This is a description of the investment opportunity.',
                    style: AppTypography.bodyMedium,
                  ),
                ),
                _buildUsageExample(
                  title: 'Button Text',
                  code: 'Text("Submit", style: AppTypography.labelLarge)',
                  preview: Text(
                    'SUBMIT',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildTypographyItem({
    required String label,
    required TextStyle style,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Text(
              text,
              style: style,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFontInfo({
    required String name,
    required String description,
    required TextStyle style,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: style.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExample({
    required String title,
    required String code,
    required Widget preview,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: AppTypography.bodySmall.copyWith(
                    fontFamily: AppTypography.monoFont,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                preview,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
