import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ainme_vault/screens/contributors_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '1.0.0';
  String _buildNumber = '1';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    }
  }

  bool _isCheckingUpdate = false;

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $urlString')));
      }
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.github.com/repos/som120/AniFlux/releases/latest',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'];
        final String latestVersion = latestVersionTag.replaceAll('v', '');
        final String releaseUrl = data['html_url'];
        final String releaseBody =
            data['body'] ?? 'No release notes available.';

        // Simple version comparison logic
        // Assumes semantic versioning (x.y.z)
        if (_isNewerVersion(latestVersion, _version)) {
          _showUpdateDialog(latestVersion, releaseUrl, releaseBody);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are using the latest version.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        throw Exception('Failed to load releases');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check for updates: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  bool _isNewerVersion(String latest, String current) {
    List<String> latestParts = latest.split('.');
    List<String> currentParts = current.split('.');

    for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
      int latestPart = int.tryParse(latestParts[i]) ?? 0;
      int currentPart = int.tryParse(currentParts[i]) ?? 0;

      if (latestPart > currentPart) return true;
      if (latestPart < currentPart) return false;
    }

    // If main parts are equal, check length (e.g., 1.0.1 > 1.0)
    return latestParts.length > currentParts.length;
  }

  void _showUpdateDialog(String version, String url, String notes) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("New Version Available: v$version"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("A new version of AniFlux is available!"),
              const SizedBox(height: 10),
              const Text(
                "Release Notes:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                notes.length > 300 ? "${notes.substring(0, 300)}..." : notes,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchUrl(url);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A5CF6),
              foregroundColor: Colors.white,
            ),
            child: const Text("Update Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // App Icon and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/icon/aniflux_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.movie_filter,
                              size: 50,
                              color: Color(0xFF8A5CF6),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "AniFlux",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Version $_version (Build $_buildNumber)",
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Links Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.update,
                      title: _isCheckingUpdate
                          ? "Checking..."
                          : "Check for Updates",
                      onTap: _isCheckingUpdate
                          ? () {}
                          : () {
                              _checkForUpdates();
                            },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.history,
                      title: "Changelog",
                      onTap: () {
                        _showChangelog(context);
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.bug_report_outlined,
                      title: "Report a Bug",
                      onTap: () => _launchUrl(
                        "https://github.com/som120/AniFlux/issues",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Community & Support Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.code,
                      title: "GitHub Repository",
                      onTap: () =>
                          _launchUrl("https://github.com/som120/AniFlux"),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.people_outline,
                      title: "Contributors",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContributorsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.coffee,
                      title: "Buy Me a Coffee",
                      iconColor: Colors.orange,
                      onTap: () =>
                          _launchUrl("https://www.buymeacoffee.com/start0dev"),
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.article_outlined,
                      title: "License",
                      onTap: () {
                        showLicensePage(
                          context: context,
                          applicationName: "AniFlux",
                          applicationVersion: "$_version ($_buildNumber)",
                          applicationIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              'assets/icon/aniflux_logo.png',
                              width: 48,
                              height: 48,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Made with ❤️ by Somnath",
              style: TextStyle(color: Colors.black45, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF8A5CF6)).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF8A5CF6),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 64, color: Colors.black12);
  }

  void _showChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changelog"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Version 1.0.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "• Initial release of AniFlux\n• Track your favorite anime\n• Discover new series\n• Sync across devices",
              ),
              Divider(height: 30),
              // Add more changelog items here
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
