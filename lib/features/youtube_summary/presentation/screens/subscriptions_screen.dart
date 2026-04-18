import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// 🔥 Adjust this import path to point to where you saved the provider!
import '../state/subscription_provider.dart'; 

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> _channels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChannels();
  }

  // We only fetch the list of available channels here. The Provider handles the status!
  Future<void> _fetchChannels() async {
    try {
      final channelsData = await supabase.from('channels').select();
      setState(() {
        _channels = channelsData;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Watch the global state!
    final subscribedChannels = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Subscriptions')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                final channelName = channel['channel_name'];
                
                // Check if this channel name is in the global state
                final isSubscribed = subscribedChannels.contains(channelName);

                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  title: Text(channelName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('YouTube Channel'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubscribed ? Colors.grey[300] : Colors.red,
                      foregroundColor: isSubscribed ? Colors.black : Colors.white,
                    ),
                    onPressed: () async {
                      try {
                        // Tell the Brain to toggle it
                        await ref.read(subscriptionProvider.notifier).toggleSubscription(channelName);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      }
                    },
                    child: Text(isSubscribed ? 'Unsubscribe' : 'Subscribe'),
                  ),
                );
              },
            ),
    );
  }
}