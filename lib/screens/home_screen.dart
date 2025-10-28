import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'package:tracker/providers/item_provider.dart';
import 'package:tracker/screens/scan_screen.dart';
import 'package:tracker/screens/add_item_screen.dart';
import 'package:tracker/screens/chatbot_screen.dart';
import 'package:tracker/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _sortBy = 'expiry'; // 'expiry', 'name', 'purchased'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  List<dynamic> _sortItems(List<dynamic> items) {
    final sorted = List.from(items);
    switch (_sortBy) {
      case 'expiry':
        sorted.sort((a, b) => a.expiry.compareTo(b.expiry));
        break;
      case 'name':
        sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'purchased':
        sorted.sort((a, b) => b.purchased.compareTo(a.purchased));
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemProvider>(context);
    final items = _sortItems(provider.items);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text('Good morning', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28)),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            // Promo card (white rounded) with image on right
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Eat some oranges while they are fresh!', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    RichText(text: TextSpan(style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color), children: [const TextSpan(text: 'Enjoy by '), TextSpan(text: 'this week', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600))])),
                  ]),
                ),
                const SizedBox(width: 12),
                // circular image on right, placeholder if not available
                ClipRRect(borderRadius: BorderRadius.circular(40), child: Container(width: 76, height: 76, color: Colors.grey.shade100, child: const Icon(Icons.local_grocery_store, size: 40, color: Colors.grey)))
              ]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text('All items', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.surfaceVariant,
                        ),
                        child: Text('${items.length}', style: Theme.of(context).textTheme.bodySmall),
                      )
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() => _sortBy = value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'expiry',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: _sortBy == 'expiry' ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 8),
                          Text('Sort by Expiry Date', style: TextStyle(fontWeight: _sortBy == 'expiry' ? FontWeight.bold : null)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'name',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 8),
                          Text('Sort by Name', style: TextStyle(fontWeight: _sortBy == 'name' ? FontWeight.bold : null)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'purchased',
                      child: Row(
                        children: [
                          Icon(Icons.shopping_cart, size: 18, color: _sortBy == 'purchased' ? Theme.of(context).colorScheme.primary : null),
                          const SizedBox(width: 8),
                          Text('Sort by Purchase Date', style: TextStyle(fontWeight: _sortBy == 'purchased' ? FontWeight.bold : null)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? const Center(
                      child: Text(
                        'No items yet — add one',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.separated(
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: items.length,
                      // Add these performance optimizations
                      addAutomaticKeepAlives: true,
                      cacheExtent: 100,
                      itemBuilder: (ctx, idx) {
                        final it = items[idx];
                        return _ItemTile(
                          item: it,
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AddItemScreen(
                                  prefill: {
                                    'id': it.id,
                                    'name': it.name,
                                    'quantity': it.quantity,
                                    'type': it.itemType,
                                    'imageUrl': it.imagePath,
                                    'purchased': it.purchased,
                                    'expiry': it.expiry,
                                  },
                                ),
                              ),
                            );
                            if (ctx.mounted) {
                              await Provider.of<ItemProvider>(ctx, listen: false).loadItems();
                            }
                          },
                          onDelete: () async {
                            await Provider.of<ItemProvider>(context, listen: false).deleteItem(it.id!);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Theme.of(context).scaffoldBackgroundColor,
        elevation: 8,
        notchMargin: 8,
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left tab (Items)
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 4),
                    Text('Items', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                  ]),
                ),
              ),
              // spacer for FAB
              const SizedBox(width: 72),
              // Right tab (AI Chat)
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    );
                  },
                  child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.smart_toy, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 4),
                    Text('AI Chat', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12)),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        height: 72,
        width: 72,
        child: FloatingActionButton(
          heroTag: 'scanner',
          backgroundColor: const Color(0xFF00C853), // bright green
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.qr_code_scanner, size: 28), SizedBox(height: 2)]),
        ),
      ),
      persistentFooterButtons: [],
    );
  }
}

// Separate stateless widget for better performance - avoids rebuilding entire list
class _ItemTile extends StatelessWidget {
  final dynamic item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ItemTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final daysLeft = item.expiry.difference(DateTime.now()).inDays;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      onTap: onTap,
      leading: _buildImage(),
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              daysLeft >= 0
                  ? 'Expires in $daysLeft days'
                  : 'Expired ${-daysLeft} days ago',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            'Qty: ${item.quantity}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (item.imagePath == null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.food_bank),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.imagePath!.startsWith('http')
          ? CachedNetworkImage(
              imageUrl: item.imagePath!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: 112, // Cache at 2x resolution for retina
              memCacheHeight: 112,
              placeholder: (c, s) => Container(
                color: Colors.grey[200],
                width: 56,
                height: 56,
              ),
              errorWidget: (c, s, e) => Container(
                color: Colors.grey[200],
                width: 56,
                height: 56,
                child: const Icon(Icons.broken_image),
              ),
            )
          : Image.file(
              File(item.imagePath!),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              cacheWidth: 112, // Reduce memory usage
              cacheHeight: 112,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                width: 56,
                height: 56,
                child: const Icon(Icons.broken_image),
              ),
            ),
    );
  }
}


