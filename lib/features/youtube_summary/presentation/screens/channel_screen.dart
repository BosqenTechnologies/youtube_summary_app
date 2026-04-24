import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:youtube_summary_app/features/youtube_summary/data/services/database_service.dart';

// 🔥 Make sure this points to your actual provider file!
import '../state/subscription_provider.dart';

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  final DatabaseService _db = DatabaseService();

  List<Map<String, dynamic>> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoading = true);
    final data = await _db.getAllSubscriptions();
    if (mounted) {
      setState(() {
        _channels = data;
        _isLoading = false;
      });
    }
  }

  // ── Add Channel Dialog ──
  void _showAddChannelDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    bool notifEnabled = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Channel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name *',
                  hintText: 'e.g. Money Pechu',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Channel URL *',
                  hintText: 'https://www.youtube.com/@ChannelHandle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Notifications'),
                value: notifEnabled,
                onChanged: (v) => setDialogState(() => notifEnabled = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (name.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Channel name and URL are required.')),
                  );
                  return;
                }

                try {
                  // 1. Sync with Vault Provider First!
                  final subscribedChannels = ref.read(subscriptionProvider);
                  if (!subscribedChannels.contains(name)) {
                     await ref.read(subscriptionProvider.notifier).toggleSubscription(name);
                  }
                  
                  // 2. Save URL/Notifications to DB
                  await _db.updateSubscription(
                    channelName: name,
                    isSubscribed: true,
                    notificationsEnabled: notifEnabled,
                    channelUrl: url,
                  );

                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadChannels();
                } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white),
              child: const Text('Subscribe'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Channel Dialog (to update URL) ──
  void _showEditDialog(Map<String, dynamic> channel) {
    final urlController = TextEditingController(text: channel['channel_url'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit: ${channel['channel_name']}'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Channel URL',
            hintText: 'https://www.youtube.com/@ChannelHandle',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.updateSubscription(
                channelName: channel['channel_name'],
                isSubscribed: channel['is_subscribed'] as bool? ?? false,
                notificationsEnabled: channel['notifications_enabled'] as bool? ?? false,
                channelUrl: urlController.text.trim(),
              );
              if (ctx.mounted) Navigator.pop(ctx);
              _loadChannels();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── Toggle Subscribe (SYNCED WITH VAULT) ──
  Future<void> _toggleSubscribe(Map<String, dynamic> channel, bool isCurrentlySubscribed) async {
    final channelName = channel['channel_name'];

    try {
      // 1. Toggle via Provider so the Vault updates instantly. 
      // The Provider now handles the DB logic securely in the background.
      await ref.read(subscriptionProvider.notifier).toggleSubscription(channelName);
      
      _loadChannels();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // ── Toggle Notifications ──
  Future<void> _toggleNotifications(Map<String, dynamic> channel, bool isSubscribed) async {
    if (!isSubscribed) return; // Cannot turn on notifications if unsubscribed

    final newValue = !(channel['notifications_enabled'] as bool? ?? false);
    await _db.updateSubscription(
      channelName: channel['channel_name'],
      isSubscribed: true, 
      notificationsEnabled: newValue,
      channelUrl: channel['channel_url'],
    );
    _loadChannels();
  }

  // ── Delete Channel ──
  Future<void> _deleteChannel(String channelName, bool isSubscribed) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Channel'),
        content: Text('Remove "$channelName" from your feeds?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      if (isSubscribed) {
        await ref.read(subscriptionProvider.notifier).toggleSubscription(channelName);
      }
      await _db.deleteSubscription(channelName);
      _loadChannels();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Watch Vault Subscriptions
    final subscribedChannels = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Channels'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChannels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
              ? _buildEmptyState()
              : _buildChannelList(subscribedChannels),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddChannelDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Channel'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.subscriptions_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No channels yet.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to add your first channel.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelList(Set<String> subscribedChannels) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _channels.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final channel = _channels[i];
        final name = channel['channel_name'] as String? ?? 'Unknown';
        
        // 100% synced with Vault
        final isSubscribed = subscribedChannels.contains(name);
        
        final notifEnabled = channel['notifications_enabled'] as bool? ?? false;
        final channelUrl = channel['channel_url'] as String? ?? '';
        final hasUrl = channelUrl.isNotEmpty;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSubscribed ? Colors.redAccent : Colors.grey.shade300,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: isSubscribed ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: GestureDetector(
            onTap: () => _showEditDialog(channel),
            child: Text(
              hasUrl ? '✅ URL set  (tap to edit)' : '⚠️ No URL — tap to add',
              style: TextStyle(
                fontSize: 12,
                color: hasUrl ? Colors.green.shade700 : Colors.orange,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  notifEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: isSubscribed 
                      ? (notifEnabled ? Colors.amber : Colors.grey)
                      : Colors.grey.withOpacity(0.3),
                ),
                tooltip: notifEnabled ? 'Notifications ON' : 'Notifications OFF',
                onPressed: isSubscribed ? () => _toggleNotifications(channel, isSubscribed) : null,
              ),
              Switch(
                value: isSubscribed,
                activeColor: Colors.redAccent,
                onChanged: (_) => _toggleSubscribe(channel, isSubscribed),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove channel',
                onPressed: () => _deleteChannel(name, isSubscribed),
              ),
            ],
          ),
        );
      },
    );
  }
}