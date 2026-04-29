import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:youtube_summary_app/core/constants/app_colors.dart';

import 'package:youtube_summary_app/core/constants/app_strings.dart';
import 'package:youtube_summary_app/core/constants/app_dimensions.dart';
import '../../data/services/database_service.dart';
import '../state/subscription_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final DatabaseService _db = DatabaseService();

  List<Map<String, dynamic>> _allSubs = [];
  bool _isLoading = true;
  bool _isCheckingAll = false;
  String _checkAllStatus = '';

  String get _apiBase {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    return 'http://192.168.1.37:8000'; 
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final data = await _db.getAllSubscriptions();
    if (mounted) {
      setState(() {
        _allSubs = data;
        _isLoading = false;
      });
    }
  }

  void _showAddChannelDialog(Color primaryColor, Color primaryText, Color secondaryText, Color cardColor, Color inputFill) {
    final nameCtrl = TextEditingController();
    final urlCtrl  = TextEditingController();
    bool notifEnabled = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
          title: Text(
            AppStrings.addNewChannel,
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Curate your intelligence feed by subscribing to a new source.',
                style: TextStyle(fontSize: AppDimensions.fontTiny, color: secondaryText),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              _label('CHANNEL NAME *', secondaryText),
              const SizedBox(height: AppDimensions.spacingSmall),
              _inputField(nameCtrl, 'e.g. Verge Science', primaryText, secondaryText, inputFill, primaryColor),
              const SizedBox(height: AppDimensions.spacingNormal),
              _label('CHANNEL URL *', secondaryText),
              const SizedBox(height: AppDimensions.spacingSmall),
              _inputField(urlCtrl, 'https://youtube.com/@channel', primaryText, secondaryText, inputFill, primaryColor),
              const SizedBox(height: AppDimensions.spacingNormal),
              Container(
                decoration: BoxDecoration(
                  color: inputFill,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSmall),
                  secondary: Icon(Icons.notifications_active, color: primaryColor),
                  title: Text('Enable Notifications', style: TextStyle(color: primaryText, fontSize: AppDimensions.fontSmall)),
                  value: notifEnabled,
                  activeColor: primaryColor,
                  onChanged: (v) => setDialog(() => notifEnabled = v),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: AppColors.textLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
                elevation: 0,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final url  = urlCtrl.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('Channel name and URL are required.'),
                    backgroundColor: AppColors.errorRed,
                  ));
                  return;
                }
                Navigator.pop(ctx);

                await ref.read(subscriptionProvider.notifier).addChannel(
                      channelName: name,
                      channelUrl: url,
                      notificationsEnabled: notifEnabled,
                    );
                _loadAll();
              },
              child: const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUrlDialog(Map<String, dynamic> sub, Color primaryColor, Color primaryText, Color secondaryText, Color cardColor, Color inputFill) {
    final urlCtrl = TextEditingController(text: sub['channel_url'] as String? ?? '');
    final name = sub['channel_name'] as String? ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
        title: Text(
          'Edit: $name',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('CHANNEL URL', secondaryText),
            const SizedBox(height: AppDimensions.spacingSmall),
            _inputField(urlCtrl, 'https://youtube.com/@channel', primaryText, secondaryText, inputFill, primaryColor),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: AppColors.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
              elevation: 0,
            ),
            onPressed: () async {
              await _db.updateSubscription(
                channelName: name,
                isSubscribed: sub['is_subscribed'] as bool? ?? true,
                notificationsEnabled: sub['notifications_enabled'] as bool? ?? false,
                channelUrl: urlCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadAll();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(Map<String, dynamic> sub, Color primaryColor, Color primaryText, Color cardColor) async {
    final name = sub['channel_name'] as String? ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
        title: Text(
          'Remove Channel',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
        ),
        content: Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Remove ', style: TextStyle(color: primaryText)),
            TextSpan(
              text: '"$name"',
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
            ),
            TextSpan(text: ' from your feeds?', style: TextStyle(color: primaryText)),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(subscriptionProvider.notifier).removeChannel(name);
      _loadAll();
    }
  }

  Future<void> _toggleSubscribe(Map<String, dynamic> sub) async {
    final name = sub['channel_name'] as String? ?? '';
    final existingUrl = sub['channel_url'] as String?; // ✨ Get existing URL just in case
    
    await ref.read(subscriptionProvider.notifier).toggleSubscription(
          name, 
          channelUrl: existingUrl, // ✨ Pass it down so toggling preserves it
        );
    _loadAll();
  }

  Future<void> _toggleNotifications(Map<String, dynamic> sub) async {
    final name = sub['channel_name'] as String? ?? '';
    final newNotif = !(sub['notifications_enabled'] as bool? ?? false);
    final channelUrl = sub['channel_url'] as String?;

    await ref.read(subscriptionProvider.notifier).setNotifications(
          channelName: name,
          enabled: newNotif,
          channelUrl: channelUrl,
        );
    _loadAll();
  }

  Future<void> _checkAllChannels(Color primaryColor, Color primaryText, Color cardColor) async {
    final hasUrls = _allSubs.any((s) => (s['channel_url'] as String?)?.isNotEmpty == true);
    if (!hasUrls) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('⚠️ No channel URLs found. Tap a channel URL to add one.'),
        backgroundColor: AppColors.errorRed,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    setState(() {
      _isCheckingAll = true;
      _checkAllStatus = 'Checking all channels for new videos…';
    });

    try {
      final response = await http
          .get(Uri.parse('$_apiBase/force-check-all'))
          .timeout(const Duration(minutes: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results   = (data['results']   as List<dynamic>?) ?? [];
        final newVideos = (data['new_videos_found'] as int?) ?? 0;
        final total     = (data['total_channels_checked'] as int?) ?? 0;

        setState(() {
          _checkAllStatus = newVideos > 0
              ? '🎉 $newVideos new video(s) found across $total channel(s)!'
              : '✅ All $total channel(s) are up to date.';
        });
        if (mounted) _showResultsDialog(results, newVideos, total, primaryColor, primaryText, cardColor);
      } else {
        setState(() => _checkAllStatus = '❌ Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _checkAllStatus = '❌ Error: $e');
    } finally {
      setState(() => _isCheckingAll = false);
    }
  }

  void _showResultsDialog(List results, int newVideos, int total, Color primaryColor, Color primaryText, Color cardColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusLarge)),
        title: Row(children: [
          Icon(
            newVideos > 0 ? Icons.fiber_new : Icons.check_circle,
            color: newVideos > 0 ? Colors.green : Colors.blue, 
          ),
          const SizedBox(width: AppDimensions.spacingSmall),
          Text(
            newVideos > 0 ? '$newVideos new video(s)!' : 'All up to date',
            style: TextStyle(color: primaryText, fontSize: AppDimensions.fontButton),
          ),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r          = results[i] as Map<String, dynamic>;
              final status     = r['status']       as String? ?? 'unknown';
              final channelName= r['channel_name'] as String? ?? 'Unknown';
              final title      = r['title']        as String?;
              final message    = r['message']      as String? ?? '';

              IconData icon;
              Color    color;
              String   subtitle;

              switch (status) {
                case 'new_video':
                  icon     = Icons.fiber_new;
                  color    = Colors.green;
                  subtitle = title ?? 'New video processed!';
                  break;
                case 'up_to_date':
                  icon     = Icons.check_circle_outline;
                  color    = Colors.blue;
                  subtitle = 'Already up to date';
                  break;
                case 'skipped':
                  icon     = Icons.link_off;
                  color    = Colors.orange;
                  subtitle = 'No URL set — tap the channel to add one';
                  break;
                default:
                  icon     = Icons.error_outline;
                  color    = AppColors.errorRed;
                  subtitle = message;
              }

              return ListTile(
                dense:   true,
                leading: Icon(icon, color: color, size: 22),
                title:   Text(
                  channelName,
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryText),
                ),
                subtitle:Text(
                  subtitle,
                  style: TextStyle(fontSize: AppDimensions.fontTiny, color: primaryText.withValues(alpha: 0.7)),
                ),
              );
            },
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: AppColors.textLight,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSmall)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, Color color) => Text(
        text,
        style: TextStyle(
          fontSize: AppDimensions.fontTiny, 
          fontWeight: FontWeight.w700, 
          letterSpacing: 0.6,
          color: color,
        ),
      );

  Widget _inputField(TextEditingController ctrl, String hint, Color primaryText, Color secondaryText, Color inputFill, Color primaryColor) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: AppDimensions.fontNormal, color: primaryText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: secondaryText),
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingNormal, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusNormal),
          borderSide: BorderSide(color: primaryColor, width: AppDimensions.borderWidth),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? AppColors.primaryRedDark : AppColors.primaryRedLight;
    final primaryText = isDark ? AppColors.darkOnSurface : AppColors.lightOnSurface;
    final secondaryText = isDark ? AppColors.darkSecondaryTonal : AppColors.lightSecondaryTonal;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final cardColor = isDark ? AppColors.darkSurfaceContainerLowest : AppColors.lightSurfaceContainerLowest;
    final inputFill = isDark ? AppColors.darkSurfaceContainerLow : AppColors.lightSurfaceContainerLow;

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        // leading: IconButton(
        //   icon: Icon(Icons.menu, color: primaryColor),
        //   onPressed: () {},
        // ),
        title: Text(
          AppStrings.appName,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: AppDimensions.fontTitleMedium,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor),
            onPressed: _loadAll,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppDimensions.paddingMedium, AppDimensions.paddingSmall, AppDimensions.paddingMedium, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.manageSubscriptions,
                  style: TextStyle(
                    fontSize: AppDimensions.fontTitleLarge,
                    fontWeight: FontWeight.bold,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingSmall / 2),
                Text(
                  AppStrings.manageSubsSubtitle,
                  style: TextStyle(
                    fontSize: AppDimensions.fontSmall,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                const SizedBox(height: AppDimensions.spacingNormal),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryColor))
                : _allSubs.isEmpty
                    ? _buildEmpty(primaryColor, primaryText, secondaryText)
                    : _buildList(primaryColor, primaryText, secondaryText, cardColor, inputFill),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddChannelDialog(primaryColor, primaryText, secondaryText, cardColor, inputFill),
        icon: const Icon(Icons.add),
        label: const Text('Add Channel', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textLight,
        elevation: 2,
      ),
    );
  }

  Widget _buildEmpty(Color primaryColor, Color primaryText, Color secondaryText) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.subscriptions_outlined, size: 72, color: secondaryText),
          const SizedBox(height: AppDimensions.spacingNormal),
          Text(
            'No channels yet.',
            style: TextStyle(
              fontSize: AppDimensions.fontButton,
              fontWeight: FontWeight.w600,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSmall),
          Text(
            'Tap + Add Channel to subscribe.',
            style: TextStyle(color: secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Color primaryColor, Color primaryText, Color secondaryText, Color cardColor, Color inputFill) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppDimensions.paddingNormal, 0, AppDimensions.paddingNormal, 120),
      itemCount: _allSubs.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppDimensions.spacingSmall),
      itemBuilder: (ctx, i) {
        return _buildChannelCard(_allSubs[i], primaryColor, primaryText, secondaryText, cardColor, inputFill);
      },
    );
  }

  Widget _buildChannelCard(Map<String, dynamic> sub, Color primaryColor, Color primaryText, Color secondaryText, Color cardColor, Color inputFill) {
    final name         = sub['channel_name'] as String? ?? 'Unknown';
    final isSubscribed = sub['is_subscribed'] as bool? ?? false;
    final notifEnabled = sub['notifications_enabled'] as bool? ?? false;
    final channelUrl   = sub['channel_url'] as String? ?? '';
    final hasUrl       = channelUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingNormal, 
          vertical: 14,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: isSubscribed ? primaryColor : inputFill,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isSubscribed ? AppColors.textLight : secondaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: AppDimensions.fontButton,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppDimensions.fontNormal,
                      color: primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingSmall / 2),
                  GestureDetector(
                    onTap: () => _showEditUrlDialog(sub, primaryColor, primaryText, secondaryText, cardColor, inputFill),
                    child: Text(
                      hasUrl ? '✅ URL set  (tap to edit)' : '⚠️ No URL — tap to add',
                      style: TextStyle(
                        fontSize: AppDimensions.fontTiny,
                        color: hasUrl ? Colors.green.shade600 : AppColors.accentYellow,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                notifEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                color: notifEnabled ? AppColors.accentYellow : secondaryText,
              ),
              tooltip: notifEnabled ? 'Notifications ON' : 'Notifications OFF',
              onPressed: () => _toggleNotifications(sub),
            ),
            Switch(
              value: isSubscribed,
              activeColor: primaryColor,
              onChanged: (_) => _toggleSubscribe(sub),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              tooltip: 'Remove channel',
              onPressed: () => _confirmRemove(sub, primaryColor, primaryText, cardColor),
            ),
          ],
        ),
      ),
    );
  }
}