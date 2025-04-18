import 'package:flutter/material.dart';
import 'package:any_link_preview/any_link_preview.dart';
import '../../models/guide.dart';
import '../../models/external_link.dart';
import '../../services/guide_service.dart';
import '../../services/external_link_service.dart';
import 'guide_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class GuidesListPage extends StatelessWidget {
  final GuideCategory category;
  
  const GuidesListPage({Key? key, required this.category}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${category.title} Guides'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green.shade800),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guides Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Guides & Articles',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            
            _buildGuidesSection(),
            
            // External Links Section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'External Links',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ),
            
            _buildExternalLinksSection(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidesSection() {
    return FutureBuilder<List<Guide>>(
      future: GuideService().getGuidesByCategory(category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final guides = snapshot.data ?? [];
        
        if (guides.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text('No ${category.title} guides available yet'),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: guides.length,
          itemBuilder: (context, index) {
            final guide = guides[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GuideDetailPage(guide: guide),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (guide.imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          guide.imageUrl!,
                          height: 180,
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
                            guide.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            guide.summary ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(guide.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExternalLinksSection() {
    return FutureBuilder<List<ExternalLink>>(
      future: ExternalLinkService().getLinksByCategory(category.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ));
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error loading external links: ${snapshot.error}'));
        }
        
        final links = snapshot.data ?? [];
        
        if (links.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('No external resources available')),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Custom link preview
                    AnyLinkPreview(
                      link: link.url,
                      displayDirection: UIDirection.uiDirectionHorizontal,
                      showMultimedia: true,
                      bodyMaxLines: 3,
                      bodyTextOverflow: TextOverflow.ellipsis,
                      titleStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold, 
                        color: Colors.black,
                      ),
                      bodyStyle: TextStyle(
                        fontSize: 14, 
                        color: Colors.grey.shade800,
                      ),
                      errorBody: link.description ?? 'Check out this resource',
                      errorTitle: link.title,
                      errorImage: link.thumbnailUrl,
                      cache: const Duration(days: 7),
                      backgroundColor: Colors.white,
                      borderRadius: 12,
                      removeElevation: true,
                      onTap: () async {
                        final url = Uri.parse(link.url);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}