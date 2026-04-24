import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state/subscription_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_dimensions.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _channels = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChannels();
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChannels() async {
    try {
      final channelsData = await supabase.from('channels').select();
      if (mounted) {
        setState(() {
          _channels = channelsData;
        });
      }
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

    // 🔥 FIX: Apply local search filter AND ensure it only shows SUBSCRIBED channels
    final filteredChannels = _channels.where((channel) {
      final channelName = channel['channel_name'].toString();
      final matchesSearch = channelName.toLowerCase().contains(_searchQuery.toLowerCase());
      final isSubscribed = subscribedChannels.contains(channelName);
      
      return matchesSearch && isSubscribed; 
    }).toList();

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        centerTitle: true,
        title: Text(
          AppStrings.appName,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
      ),
        body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : Column(
              children: [
                // 1. Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppDimensions.paddingNormal, 
                      AppDimensions.paddingNormal, 
                      AppDimensions.paddingNormal, 
                      AppDimensions.paddingNormal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.manageSubscriptions,
                        style: theme.textTheme.headlineSmall?.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface) ?? const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppDimensions.spacingSmall),
                      Text(
                        AppStrings.manageSubsSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: AppDimensions.fontNormal, color: theme.textTheme.bodyMedium?.color) ?? const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      
                      // 2. Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: theme.inputDecorationTheme.fillColor ?? const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: AppStrings.searchChannels,
                            hintStyle: TextStyle(color: theme.hintColor, fontSize: 16),
                            prefixIcon: Icon(Icons.search, color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Channels List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingNormal,
                      vertical: AppDimensions.paddingSmall,
                    ),
                    itemCount: filteredChannels.length + 1, 
                    itemBuilder: (context, index) {
                      
                      // Render the "Add New Channel" button at the very bottom
                      if (index == filteredChannels.length) {
                        return _buildAddChannelButton();
                      }

                      final channel = filteredChannels[index];
                      final channelName = channel['channel_name'];
                      final isSubscribed = subscribedChannels.contains(channelName);

                      return _buildChannelCard(channelName, isSubscribed, context);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // Premium Channel Card
  Widget _buildChannelCard(String channelName, bool isSubscribed, BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), 
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  channelName,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface) ?? const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Text(
                        'YOUTUBE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 1.0,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CircleAvatar(radius: 2, backgroundColor: Colors.grey[400]),
                      ),
                      Text(
                        'CHANNEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isSubscribed ? theme.cardColor : theme.colorScheme.primary,
                foregroundColor: isSubscribed ? theme.colorScheme.onSurface : theme.colorScheme.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                try {
                  // Toggle sync with Vault!
                  await ref.read(subscriptionProvider.notifier).toggleSubscription(channelName);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                  }
                }
              },
              child: Text(
                isSubscribed ? 'Unsubscribe' : 'Subscribe',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSubscribed ? FontWeight.w600 : FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddChannelButton() {
    return GestureDetector(
      onTap: () {
        // Future logic for adding a new channel manually
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 32),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.addNewChannel,
                style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}