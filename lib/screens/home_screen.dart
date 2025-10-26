import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tracker/models/item.dart';
import 'package:tracker/providers/item_provider.dart';
import 'package:tracker/screens/add_item_screen.dart';
import 'package:tracker/screens/scan_screen.dart';

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
        title: const Text('Good morning'),
        actions: [
          IconButton(onPressed: () => Navigator.of(context).pushNamed('/settings'), icon: const Icon(Icons.settings))
        ],
        centerTitle: false,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: const Text('Eat some oranges while they are fresh!'),
                subtitle: Text('Enjoy by this week', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                trailing: SizedBox(
                  width: 72,
                  child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]), child: const Icon(Icons.local_grocery_store, size: 36)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All items', style: Theme.of(context).textTheme.titleMedium),
                IconButton(onPressed: () {}, icon: const Icon(Icons.sort)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('No items yet — add one', style: Theme.of(context).textTheme.bodyLarge))
                  : ListView(
                      children: [
                        _CategorySection(title: 'Packaged goods', items: items.where((e) => e.category != 'fresh').toList()),
                        const SizedBox(height: 12),
                        _CategorySection(title: 'Fresh produce', items: items.where((e) => e.category == 'fresh').toList()),
                      ],
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(onPressed: () {
                  // navigate to home (refresh)
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
                }, icon: const Icon(Icons.home)),
                const SizedBox(width: 48),
                IconButton(onPressed: () {
                  // open add item
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen()));
                }, icon: const Icon(Icons.add_shopping_cart)),
              ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScanScreen())),
        child: const Icon(Icons.camera_alt),
      ),
      persistentFooterButtons: [
        TextButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddItemScreen())),
          icon: const Icon(Icons.add),
          label: const Text('Add item manually'),
        )
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<Item> items;

  const _CategorySection({required this.title, required this.items});

  Color _colorForDays(int daysLeft) {
    if (daysLeft < 0) return Colors.red.shade300;
    if (daysLeft <= 3) return Colors.orange.shade300;
    return Colors.green.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (items.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text('No items', style: Theme.of(context).textTheme.bodySmall)),
      ...items.map((it) {
        final daysLeft = it.expiry.difference(DateTime.now()).inDays;
        return Card(
          color: _colorForDays(daysLeft),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
      leading: it.imagePath != null
        ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: it.imagePath!.startsWith('http')
            ? CachedNetworkImage(imageUrl: it.imagePath!, width: 48, height: 48, fit: BoxFit.cover, placeholder: (c, s) => Container(color: Colors.grey[200], width: 48, height: 48), errorWidget: (c, s, e) => Container(color: Colors.grey[200], width: 48, height: 48, child: const Icon(Icons.broken_image)))
            : Image.file(File(it.imagePath!), width: 48, height: 48, fit: BoxFit.cover))
        : Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.food_bank)),
            title: Text(it.name),
            subtitle: Text('${daysLeft >= 0 ? 'Expires in $daysLeft days' : 'Expired ${-daysLeft} days ago'} • ${it.quantity}'),
            trailing: PopupMenuButton<String>(onSelected: (v) async {
              if (v == 'delete') await Provider.of<ItemProvider>(context, listen: false).deleteItem(it.id!);
            }, itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete'))]),
          ),
        );
      }).toList(),
    ]);
  }
}

