import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SustainableProduct {
  final String name;
  final String description;
  final String imagePath;
  final String websiteUrl;
  final String discountCode;
  final int discountPercentage;

  SustainableProduct({
    required this.name,
    required this.description,
    required this.imagePath,
    required this.websiteUrl,
    required this.discountCode,
    required this.discountPercentage,
  });
}

class SustainableProductsSection extends StatelessWidget {
  final List<SustainableProduct> products = [
    SustainableProduct(
      name: 'Eco Bamboo Water Bottle',
      description:
          'Stay hydrated sustainably with our premium bamboo water bottle. Perfect for your workouts and daily use.',
      imagePath:
          'assets/images/eco_tips/sustainable_products/bamboo_bottle.jpg',
      websiteUrl: 'https://eco-bottle-partner.com',
      discountCode: 'SOLARVITA15',
      discountPercentage: 15,
    ),
    SustainableProduct(
      name: 'Sustainable Activewear',
      description:
          'Eco-friendly workout clothes made from recycled materials. Look good while protecting the planet.',
      imagePath: 'assets/images/eco_tips/sustainable_products/eco_clothes.jpg',
      websiteUrl: 'https://eco-clothes-partner.com',
      discountCode: 'SOLARVITA20',
      discountPercentage: 20,
    ),
    SustainableProduct(
      name: 'Cork Yoga Mat',
      description:
          'Premium cork yoga mat that\'s naturally antimicrobial and provides excellent grip. Perfect for your practice.',
      imagePath: 'assets/images/eco_tips/sustainable_products/yoga_mat.jpg',
      websiteUrl: 'https://eco-yoga-partner.com',
      discountCode: 'SOLARVITA15',
      discountPercentage: 15,
    ),
  ];

  SustainableProductsSection({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get current theme

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sustainable Products',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor, // Use primary color from theme
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Support sustainable living with our partner products',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyLarge
                      ?.color, // Use body text color from theme
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor, // Use card color from theme
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.asset(
                      product.imagePath,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge
                                ?.color, // Use body text color from theme
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.textTheme.bodyLarge
                                ?.color, // Use body text color from theme
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withAlpha(51),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${product.discountPercentage}% OFF with code ${product.discountCode}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _launchUrl(product.websiteUrl),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme
                                  .primaryColor, // Use primary color from theme
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Shop Now',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.textTheme.bodyLarge
                                    ?.color, // Use button text color from theme
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () => _launchUrl('https://eco-marketplace.com'),
            child: Text(
              'See More Products →',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor, // Use primary color from theme
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
