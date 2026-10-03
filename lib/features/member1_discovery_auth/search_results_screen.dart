import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member2_booking_contract/provider_profile_screen.dart';

/// Member 1 (IT23684980): Search Results + Filters Screen (Variant A)
/// Requirements: FR008 (Service categories with filtering), FR003 (Upfront price preview)
class SearchResultsScreen extends StatefulWidget {
  final String? selectedCategory;
  final String initialQuery;

  const SearchResultsScreen({
    super.key,
    this.selectedCategory,
    this.initialQuery = '',
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final AppStateService _appState = AppStateService();
  late TextEditingController _searchController;
  late String _currentCategory;
  String _activeFilter = 'All'; // All | Price | Rating | Distance

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentCategory = widget.selectedCategory ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceProvider> _getFilteredProviders() {
    var list = _appState.getProvidersByCategory(
      _currentCategory.isEmpty ? null : _currentCategory,
      query: _searchController.text.trim(),
    );

    if (_activeFilter == 'Price (Low)') {
      list.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
    } else if (_activeFilter == 'Top Rated') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (_activeFilter == 'Nearest') {
      list.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _getFilteredProviders();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: widget.initialQuery.isEmpty && widget.selectedCategory == null,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Search provider or skill...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row (Variant A: Single row with Price, Rating, Distance)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Top Rated', 'Price (Low)', 'Nearest'].map((f) {
                  final selected = _activeFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _activeFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Result Count Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} verified pros found',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13),
                ),
                if (_currentCategory.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _currentCategory = ''),
                    child: Text(
                      'Clear Category: $_currentCategory',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          // Provider Cards List
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No providers found matching your filter.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        const Text('Try searching for another service or removing filters.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = results[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    p.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: AppColors.surfaceMuted,
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            p.name,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 4),
                                          if (p.isVerified)
                                            const Icon(Icons.verified, size: 16, color: AppColors.primary),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p.category.toUpperCase()} • ${p.experienceYears} Years Exp',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 14, color: AppColors.starFilled),
                                          const SizedBox(width: 3),
                                          Text('${p.rating} (${p.reviewCount})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 10),
                                          Icon(Icons.near_me_outlined, size: 13, color: Colors.grey.shade500),
                                          Text(' ${p.distanceKm} km away', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              p.about,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Estimated Starting', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    Text('Rs. ${p.startingPrice.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    minimumSize: const Size(110, 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProviderProfileScreen(provider: p),
                                      ),
                                    );
                                  },
                                  child: const Text('View Profile', style: TextStyle(fontSize: 13, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
