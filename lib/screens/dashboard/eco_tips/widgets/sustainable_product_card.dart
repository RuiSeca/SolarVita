import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/sustainable_products.dart';
import 'package:solar_vitas/utils/translation_helper.dart';

class SustainableProductsSection extends StatelessWidget {
  final List<SustainableProduct> products = [
    SustainableProduct(
      nameKey: 'product_bottle_name',
      descriptionKey: 'product_bottle_description',
      imagePath:
          'assets/images/eco_tips/sustainable_products/bamboo_bottle.jpg',
      websiteUrl: 'https://eco-bottle-partner.com',
      discountCode: 'SOLARVITA15',
      discountPercentage: 15,
    ),
    SustainableProduct(
      nameKey: 'product_activewear_name',
      descriptionKey: 'product_activewear_description',
      imagePath: 'assets/images/eco_tips/sustainable_products/eco_clothes.jpg',
      websiteUrl: 'https://eco-clothes-partner.com',
      discountCode: 'SOLARVITA20',
      discountPercentage: 20,
    ),
    SustainableProduct(
      nameKey: 'product_yoga_name',
      descriptionKey: 'product_yoga_description',
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
                tr(context, 'sustainable_products_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor, // Use primary color from theme
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, 'sustainable_products_subtitle'),
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Add this
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
                          tr(context, product.nameKey),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60, // Fixed height for description
                          child: Text(
                            tr(context, product.descriptionKey),
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
                              const Icon(Icons.local_offer,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                // Add this
                                child: Text(
                                  tr(context, 'sustainable_products_discount')
                                      .replaceAll('{discount}',
                                          '${product.discountPercentage}')
                                      .replaceAll(
                                          '{code}', product.discountCode),
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              tr(context, 'sustainable_products_shop_now'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
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
              tr(context, 'sustainable_products_see_more'),
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
