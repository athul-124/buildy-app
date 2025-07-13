import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';
import '../services/firebase_service.dart';
import '../widgets/service_card.dart';
import '../widgets/expert_card.dart';
import '../widgets/skeleton_loader.dart';
import 'service_detail_screen.dart';
import 'expert_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  
  List<Service> _services = [];
  List<Expert> _experts = [];
  List<Service> _filteredServices = [];
  List<Expert> _filteredExperts = [];
  
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filter options
  String? _selectedCategory;
  RangeValues _priceRange = const RangeValues(0, 1000);
  double _minRating = 0;
  bool _availableOnly = false;
  
  final List<String> _categories = [
    'All',
    'Electrical',
    'Plumbing',
    'Carpentry',
    'Cleaning',
    'Appliance Repair',
    'Painting',
    'Gardening',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _firebaseService.getPopularServices(limit: 20),
        _firebaseService.getExperts(limit: 20),
      ]);
      
      setState(() {
        _services = results[0] as List<Service>;
        _experts = results[1] as List<Expert>;
        _filteredServices = _services;
        _filteredExperts = _experts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading search data: $e');
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Filter services
    _filteredServices = _services.where((service) {
      final matchesSearch = _searchQuery.isEmpty || 
          service.name.toLowerCase().contains(_searchQuery) ||
          service.category.toLowerCase().contains(_searchQuery);
      
      final matchesCategory = _selectedCategory == null || 
          _selectedCategory == 'All' ||
          service.category == _selectedCategory;
      
      final matchesPrice = service.price >= _priceRange.start && 
          service.price <= _priceRange.end;
      
      final matchesRating = service.rating >= _minRating;
      
      final matchesAvailability = !_availableOnly || service.isAvailable;
      
      return matchesSearch && matchesCategory && matchesPrice && 
             matchesRating && matchesAvailability;
    }).toList();
    
    // Filter experts
    _filteredExperts = _experts.where((expert) {
      final matchesSearch = _searchQuery.isEmpty || 
          expert.name.toLowerCase().contains(_searchQuery) ||
          expert.profession.toLowerCase().contains(_searchQuery) ||
          expert.skills.any((skill) => skill.toLowerCase().contains(_searchQuery));
      
      final matchesCategory = _selectedCategory == null || 
          _selectedCategory == 'All' ||
          expert.profession.contains(_selectedCategory!);
      
      final matchesRating = expert.rating >= _minRating;
      
      final matchesAvailability = !_availableOnly || expert.isAvailable;
      
      return matchesSearch && matchesCategory && matchesRating && matchesAvailability;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: _showFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildTabBar(),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          if (_searchQuery.isNotEmpty || _hasActiveFilters())
            _buildActiveFilters(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildServicesTab(),
                _buildExpertsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search services, experts, or skills...',
          hintStyle: TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.primaryColor,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: 'Services (${_filteredServices.length})'),
          Tab(text: 'Experts (${_filteredExperts.length})'),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Active Filters',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_searchQuery.isNotEmpty)
                _buildFilterChip('Search: "$_searchQuery"', () {
                  _searchController.clear();
                }),
              if (_selectedCategory != null && _selectedCategory != 'All')
                _buildFilterChip('Category: $_selectedCategory', () {
                  setState(() {
                    _selectedCategory = null;
                    _applyFilters();
                  });
                }),
              if (_minRating > 0)
                _buildFilterChip('Rating: $_minRating+', () {
                  setState(() {
                    _minRating = 0;
                    _applyFilters();
                  });
                }),
              if (_availableOnly)
                _buildFilterChip('Available Only', () {
                  setState(() {
                    _availableOnly = false;
                    _applyFilters();
                  });
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      onDeleted: onRemove,
      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(color: AppTheme.primaryColor),
      deleteIconColor: AppTheme.primaryColor,
      side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
    );
  }

  Widget _buildServicesTab() {
    if (_isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ServiceCardSkeleton(),
      );
    }

    if (_filteredServices.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No services found',
        message: 'Try adjusting your search or filters',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailScreen(service: service),
              ),
            );
          },
          child: ServiceCard(service: service),
        );
      },
    );
  }

  Widget _buildExpertsTab() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => const ExpertCardSkeleton(),
      );
    }

    if (_filteredExperts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.person_search,
        title: 'No experts found',
        message: 'Try adjusting your search or filters',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredExperts.length,
      itemBuilder: (context, index) {
        final expert = _filteredExperts[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExpertDetailScreen(expert: expert),
              ),
            );
          },
          child: ExpertCard(expert: expert),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            
            // Filters Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    _buildPriceFilter(),
                    const SizedBox(height: 24),
                    _buildRatingFilter(),
                    const SizedBox(height: 24),
                    _buildAvailabilityFilter(),
                  ],
                ),
              ),
            ),
            
            // Apply Button
            Container(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : null;
                });
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: 2000,
          divisions: 20,
          labels: RangeLabels(
            '\$${_priceRange.start.round()}',
            '\$${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$${_priceRange.start.round()}'),
            Text('\$${_priceRange.end.round()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 1; i <= 5; i++)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _minRating = i.toDouble();
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _minRating >= i
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _minRating >= i
                          ? AppTheme.primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: _minRating >= i ? Colors.amber : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$i+',
                        style: TextStyle(
                          color: _minRating >= i
                              ? AppTheme.primaryColor
                              : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityFilter() {
    return Row(
      children: [
        Switch(
          value: _availableOnly,
          onChanged: (value) {
            setState(() {
              _availableOnly = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        Text(
          'Available only',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null && _selectedCategory != 'All' ||
           _minRating > 0 ||
           _availableOnly;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _priceRange = const RangeValues(0, 1000);
      _minRating = 0;
      _availableOnly = false;
      _applyFilters();
    });
  }
}