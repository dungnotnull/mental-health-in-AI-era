import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common_widgets/toast_service.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:frontend/core/network/supabase_client.dart';
import 'package:frontend/features/auth/application/auth_error_handler.dart';
import '../data/gig_repository.dart';
import '../domain/gig.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final PagingController<int, Gig> _pagingController = PagingController(
    firstPageKey: 0,
  );
  String _selectedCategory = 'Tất cả';

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) => _fetchPage(pageKey));
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final repo = GigRepository(ref.read(supabaseClientProvider));
      final newItems = await repo.getGigs(
        page: pageKey,
        category: _selectedCategory,
      );
      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = AuthErrorHandler.getErrorMessage(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chợ của các Bro")),
      body: Column(
        children: [
          // Filter Category (Mock đơn giản)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tất cả', 'Code', 'Design', 'Vibe', 'Chilling']
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: _selectedCategory == cat,
                        onSelected: (val) {
                          setState(() => _selectedCategory = cat);
                          _pagingController.refresh();
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: PagedListView<int, Gig>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<Gig>(
                itemBuilder: (context, item, index) => Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: const Icon(
                      Icons.work_outline,
                      color: Colors.orange,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      item.priceEstimate,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      // Hiding chat feature temporarily
                      // ToastService.showSuccess("Chat with the poster to discuss this gig!");
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGigDialog(),
        child: const Icon(Icons.add_shopping_cart),
      ),
    );
  }

  void _showCreateGigDialog() {
    // Logic mở BottomSheet hoặc Screen để nhập Title, Desc, Price...
    ToastService.showSuccess("Create Gig screen coming soon!");
  }
}
