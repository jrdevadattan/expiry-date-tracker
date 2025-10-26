import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/providers/settings_provider.dart';
import 'package:tracker/providers/item_provider.dart';
import 'package:tracker/screens/scan_screen.dart';
import 'package:tracker/screens/add_item_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ItemProvider>(context);
    final items = provider.items;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false,
        title: const Text('Good morning', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 28)),
        actions: [
          Consumer<SettingsProvider>(builder: (context, s, _) {
            final initials = s.name.isNotEmpty ? s.name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').join() : '';
            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/settings'),
                child: CircleAvatar(radius: 18, backgroundColor: Theme.of(context).colorScheme.primaryContainer, child: Text(initials, style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer))),
              ),
            );
          }),
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
                Expanded(child: Row(children: [Text('All items', style: Theme.of(context).textTheme.titleMedium), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Theme.of(context).colorScheme.surfaceVariant), child: Text('${items.length}', style: Theme.of(context).textTheme.bodySmall))])),
                IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('No items yet — add one', style: Theme.of(context).textTheme.bodyLarge))
                  : ListView.separated(
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemCount: items.length,
                      itemBuilder: (ctx, idx) {
                        final it = items[idx];
                        final daysLeft = it.expiry.difference(DateTime.now()).inDays;
                        // daysLeft computed for display; color-coding omitted in this list layout
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                          onTap: () async {
                            // navigate to Add/Edit screen with prefilled data
                            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddItemScreen(prefill: {
                                  'id': it.id,
                                  'name': it.name,
                                  'quantity': it.quantity,
                                  'type': it.itemType,
                                  'imageUrl': it.imagePath,
                                  'purchased': it.purchased,
                                  'expiry': it.expiry,
                                })));
                            // reload items in case of edits
                            await Provider.of<ItemProvider>(context, listen: false).loadItems();
                          },
                          leading: it.imagePath != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: it.imagePath!.startsWith('http') ? CachedNetworkImage(imageUrl: it.imagePath!, width: 56, height: 56, fit: BoxFit.cover, placeholder: (c, s) => Container(color: Colors.grey[200], width: 56, height: 56), errorWidget: (c, s, e) => Container(color: Colors.grey[200], width: 56, height: 56, child: const Icon(Icons.broken_image))) : Image.file(File(it.imagePath!), width: 56, height: 56, fit: BoxFit.cover))
                              : Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.food_bank)),
                          title: Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Row(children: [Expanded(child: Text(daysLeft >= 0 ? 'Expires in $daysLeft days' : 'Expired ${-daysLeft} days ago', style: Theme.of(context).textTheme.bodySmall)), Text('Quantity: ${it.quantity}', style: Theme.of(context).textTheme.bodySmall)]),
                          trailing: PopupMenuButton<String>(onSelected: (v) async {
                            if (v == 'delete') await Provider.of<ItemProvider>(context, listen: false).deleteItem(it.id!);
                          }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))]),
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
              // Right tab (Shop)
              Expanded(
                child: InkWell(
                  onTap: () {},
                  child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shopping_bag_outlined, color: Colors.grey[700]),
                    const SizedBox(height: 4),
                    Text('Shop', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
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
          backgroundColor: const Color(0xFF00C853), // bright green
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [Icon(Icons.qr_code_scanner, size: 28), SizedBox(height: 2)]),
        ),
      ),
      persistentFooterButtons: [],
    );
  }
}



