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
    // Load services and experts in parallel
    await Future.wait([
      _loadServices(),
      _loadExperts(),
    ]);
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
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildQuickActions(),
            _buildPopularServices(),
            _buildFeaturedExperts(),
            if (_isLoadingMoreExperts)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
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
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user?.name ?? 'User'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What service do you need today?',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showProfileOptions(),
                icon: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    user?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for services or experts...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune),
              onPressed: () {
                // TODO: Show filter options
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onTap: () {
            // TODO: Navigate to search screen
          },
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.electrical_services, 'label': 'Electrical', 'color': AppTheme.primaryColor},
      {'icon': Icons.plumbing, 'label': 'Plumbing', 'color': AppTheme.secondaryColor},
      {'icon': Icons.carpenter, 'label': 'Carpentry', 'color': AppTheme.accentColor},
      {'icon': Icons.cleaning_services, 'label': 'Cleaning', 'color': Colors.purple},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
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
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to category screen
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
              ? const Center(child: CircularProgressIndicator())
              : _popularServices.isEmpty
                  ? const Center(child: Text('No services available'))
                  : SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularServices.length,
                        itemBuilder: (context, index) {
                          return ServiceCard(service: _popularServices[index]);
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _featuredExperts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _featuredExperts.length - 1 ? 0 : 16,
                ),
                child: ExpertCard(expert: _featuredExperts[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
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
