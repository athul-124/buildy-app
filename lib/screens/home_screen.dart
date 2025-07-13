import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../models/service_model.dart';
import '../models/expert_model.dart';
import '../widgets/service_card.dart';
import '../widgets/expert_card.dart';
import '../widgets/skeleton_loader.dart';
import '../services/mock_data_service.dart';
import 'service_detail_screen.dart';
import 'expert_detail_screen.dart';
import 'search_screen.dart';
import 'bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  late final FirebaseService _firebaseService;
  final _scrollController = ScrollController();
  
  List<Service> _popularServices = [];
  List<Expert> _featuredExperts = [];
  
  bool _isLoadingServices = true;
  bool _isLoadingExperts = true;
  bool _isLoadingMoreExperts = false;
  
  DocumentSnapshot? _lastExpertDoc;
  
  @override
  bool get wantKeepAlive => true; // Keep state when navigating
  
  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _loadInitialData();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreExperts();
    }
  }
  
  Future<void> _loadInitialData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingServices = true;
          _isLoadingExperts = true;
        });
      }

      // Use the optimized combined method with timeout
      final homeData = await _firebaseService.getHomeData().timeout(
        const Duration(seconds: 10),
        onTimeout: () async {
          debugPrint('Firebase timeout, falling back to mock data');
          return await MockDataService.getHomeData();
        },
      );
      
      if (mounted) {
        setState(() {
          _popularServices = homeData.services;
          _featuredExperts = homeData.experts;
          _isLoadingServices = false;
          _isLoadingExperts = false;
          
          // Store the last document for pagination
          if (homeData.experts.isNotEmpty && homeData.experts.last.reference != null) {
            _lastExpertDoc = homeData.experts.last.reference as DocumentSnapshot?;
          }
          
          // Show success message if we got data
          if (homeData.services.isNotEmpty || homeData.experts.isNotEmpty) {
            debugPrint('Successfully loaded ${homeData.services.length} services and ${homeData.experts.length} experts');
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
          _isLoadingExperts = false;
        });
        
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to load data. Using offline content.'),
            backgroundColor: AppTheme.warning,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadInitialData,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }
  
  Future<void> _loadServices() async {
    try {
      setState(() {
        _isLoadingServices = true;
      });
      
      final services = await _firebaseService.getPopularServices();
      
      if (mounted) {
        setState(() {
          _popularServices = services;
          _isLoadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingServices = false;
        });
      }
    }
  }
  
  Future<void> _loadExperts() async {
    if (_isLoadingMoreExperts) return;
    
    try {
      setState(() {
        _isLoadingExperts = true;
      });
      
      final experts = await _firebaseService.getExperts(limit: 5);
      
      if (experts.isNotEmpty && mounted) {
        setState(() {
          _featuredExperts = experts;
          _isLoadingExperts = false;
          
          // Store the last document for pagination
          if (experts.isNotEmpty && experts.last.reference != null) {
            _lastExpertDoc = experts.last.reference as DocumentSnapshot?;
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingExperts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingExperts = false;
        });
      }
    }
  }
  
  Future<void> _loadMoreExperts() async {
    if (_isLoadingMoreExperts || _lastExpertDoc == null) return;
    
    try {
      setState(() {
        _isLoadingMoreExperts = true;
      });
      
      final moreExperts = await _firebaseService.getExperts(
        limit: 5,
        lastDoc: _lastExpertDoc,
      );
      
      if (moreExperts.isNotEmpty && mounted) {
        setState(() {
          _featuredExperts.addAll(moreExperts);
          _isLoadingMoreExperts = false;
          
          // Update the last document for pagination
          if (moreExperts.isNotEmpty && moreExperts.last.reference != null) {
            _lastExpertDoc = moreExperts.last.reference as DocumentSnapshot?;
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMoreExperts = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMoreExperts = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: AppTheme.primaryColor,
          backgroundColor: Colors.white,
          strokeWidth: 3,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 8),
                _buildQuickActions(),
                _buildPopularServices(),
                _buildFeaturedExperts(),
                if (_isLoadingMoreExperts)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                const SizedBox(height: 120), // Extra space for bottom navigation
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final user = authService.currentUserModel;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withOpacity(0.05),
                AppTheme.secondaryColor.withOpacity(0.03),
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? 'User'}! 👋',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'What service do you need today?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showProfileOptions(),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for services or experts...',
            hintStyle: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(
                Icons.search_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                onPressed: () {
                  // TODO: Show filter options
                },
              ),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SearchScreen(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.electrical_services_rounded, 'label': 'Electrical', 'color': AppTheme.primaryColor},
      {'icon': Icons.plumbing_rounded, 'label': 'Plumbing', 'color': AppTheme.secondaryColor},
      {'icon': Icons.carpenter_rounded, 'label': 'Carpentry', 'color': AppTheme.accentColor},
      {'icon': Icons.cleaning_services_rounded, 'label': 'Cleaning', 'color': AppTheme.warning},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Navigate to all categories
                },
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                label: Text(
                  'See All',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((action) {
              return _buildQuickActionCard(
                action['icon'] as IconData,
                action['label'] as String,
                action['color'] as Color,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          // TODO: Navigate to category screen
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularServices() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Services',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingServices
              ? SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 3, // Show 3 skeleton cards
                    itemBuilder: (context, index) {
                      return const ServiceCardSkeleton();
                    },
                  ),
                )
              : _popularServices.isEmpty
                  ? Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No services available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _popularServices.length,
                        itemBuilder: (context, index) {
                          return ServiceCard(
                            service: _popularServices[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ServiceDetailScreen(
                                    service: _popularServices[index],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _buildFeaturedExperts() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured Experts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all experts
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingExperts
              ? Column(
                  children: List.generate(3, (index) => const ExpertCardSkeleton()),
                )
              : _featuredExperts.isEmpty
                  ? Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_rounded,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No experts available',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _featuredExperts.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _featuredExperts.length - 1 ? 0 : 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ExpertCard(
                                expert: _featuredExperts[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExpertDetailScreen(
                                        expert: _featuredExperts[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', true),
              _buildNavItem(Icons.search_rounded, 'Search', false),
              _buildNavItem(Icons.bookmark_rounded, 'Bookings', false),
              _buildNavItem(Icons.chat_rounded, 'Chat', false),
              _buildNavItem(Icons.person_rounded, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isSelected) return;
            
          // Handle navigation based on label
          switch (label) {
            case 'Home':
              // Already on home
              break;
            case 'Search':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchScreen(),
                ),
              );
              break;
            case 'Bookings':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookingsScreen(),
                ),
              );
              break;
            case 'Chat':
              // TODO: Navigate to chat screen
              break;
            case 'Profile':
              // TODO: Navigate to profile screen
              break;
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to profile screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to help screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _handleSignOut();
            },
          ),
        ],
      ),
    );
  }

  void _handleSignOut() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/welcome', 
        (route) => false
      );
    }
  }
}
