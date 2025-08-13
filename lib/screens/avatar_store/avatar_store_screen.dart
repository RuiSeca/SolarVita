import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/firebase/firebase_avatar.dart';
import '../../theme/app_theme.dart';
import '../../providers/firebase/firebase_avatar_provider.dart';
import '../../utils/translation_helper.dart';
import 'widgets/firebase_avatar_card.dart';
import 'widgets/coin_header.dart';
import 'widgets/membership_banner.dart';
import 'widgets/firebase_avatar_preview_modal.dart';

class AvatarStoreScreen extends ConsumerStatefulWidget {
  const AvatarStoreScreen({super.key});

  @override
  ConsumerState<AvatarStoreScreen> createState() => _AvatarStoreScreenState();
}

class _AvatarStoreScreenState extends ConsumerState<AvatarStoreScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏪 Building AvatarStoreScreen - Current tab: ${_tabController.index}');
    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildHeader()),
              const SliverToBoxAdapter(child: CoinHeader()),
              const SliverToBoxAdapter(child: MembershipBanner()),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAllItemsTab(),
              _buildFreeSkinsTab(),
              _buildPremiumTab(),
              _buildMembersTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.darkSurface,
            AppColors.darkSurface.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.close,
                color: AppColors.white,
                size: 18,
              ),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'store_title'),
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tr(context, 'store_subtitle'),
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.store_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(4),
        tabs: [
          SizedBox(
            width: double.infinity,
            child: Tab(text: tr(context, 'tabs_all')),
          ),
          SizedBox(
            width: double.infinity,
            child: Tab(text: tr(context, 'tabs_free')),
          ),
          SizedBox(
            width: double.infinity,
            child: Tab(text: tr(context, 'tabs_premium')),
          ),
          SizedBox(
            width: double.infinity,
            child: Tab(text: tr(context, 'tabs_vip')),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.12),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: tr(context, 'search_placeholder'),
          hintStyle: TextStyle(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.white.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildAllItemsTab() {
    debugPrint('🏪 Building All Items Tab');
    final availableAvatars = ref.watch(availableAvatarsProvider);
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    
    debugPrint('🏪 Avatar provider state: ${availableAvatars.runtimeType}');
    debugPrint('🏪 Ownership provider state: ${ownerships.runtimeType}');
    
    return availableAvatars.when(
      data: (avatars) {
        // Debug: Log avatar data
        debugPrint('💡 Available avatars count: ${avatars.length}');
        debugPrint('💡 Avatar IDs: ${avatars.map((a) => a.avatarId).toList()}');
        
        return ownerships.when(
          data: (ownershipList) {
            // Debug: Log ownership data  
            debugPrint('💡 User ownerships count: ${ownershipList.length}');
            debugPrint('💡 Ownership IDs: ${ownershipList.map((o) => o.avatarId).toList()}');
            
            return _buildFirebaseItemGrid(avatars, ownershipList, 'all');
          },
          loading: () {
            debugPrint('💡 Ownerships still loading, showing avatars with empty ownerships...');
            // Don't wait indefinitely for ownerships - show avatars with empty ownership list
            return _buildFirebaseItemGrid(avatars, <UserAvatarOwnership>[], 'all');
          },
          error: (error, _) {
            debugPrint('💡 Ownerships error: $error');
            return _buildErrorState(error.toString());
          },
        );
      },
      loading: () {
        debugPrint('💡 Avatar store: Avatars still loading...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, _) {
        debugPrint('💡 Avatar store error: $error');
        return _buildErrorState(error.toString());
      },
    );
  }


  Widget _buildFreeSkinsTab() {
    final availableAvatars = ref.watch(availableAvatarsProvider);
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    
    return availableAvatars.when(
      data: (avatars) => ownerships.when(
        data: (ownershipList) {
          final freeAvatars = avatars.where((avatar) => avatar.price == 0).toList();
          return _buildFirebaseItemGrid(freeAvatars, ownershipList, 'free');
        },
        loading: () {
          final freeAvatars = avatars.where((avatar) => avatar.price == 0).toList();
          return _buildFirebaseItemGrid(freeAvatars, <UserAvatarOwnership>[], 'free');
        },
        error: (error, _) => _buildErrorState(error.toString()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildPremiumTab() {
    final availableAvatars = ref.watch(availableAvatarsProvider);
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    
    return availableAvatars.when(
      data: (avatars) => ownerships.when(
        data: (ownershipList) {
          final premiumAvatars = avatars.where((avatar) => 
            avatar.price > 0 && avatar.rarity != 'legendary'
          ).toList();
          return _buildFirebaseItemGrid(premiumAvatars, ownershipList, 'premium');
        },
        loading: () {
          final premiumAvatars = avatars.where((avatar) => 
            avatar.price > 0 && avatar.rarity != 'legendary'
          ).toList();
          return _buildFirebaseItemGrid(premiumAvatars, <UserAvatarOwnership>[], 'premium');
        },
        error: (error, _) => _buildErrorState(error.toString()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildMembersTab() {
    final availableAvatars = ref.watch(availableAvatarsProvider);
    final ownerships = ref.watch(userAvatarOwnershipsProvider);
    
    return availableAvatars.when(
      data: (avatars) => ownerships.when(
        data: (ownershipList) {
          final legendaryAvatars = avatars.where((avatar) => 
            avatar.rarity == 'legendary'
          ).toList();
          return _buildFirebaseItemGrid(legendaryAvatars, ownershipList, 'legendary');
        },
        loading: () {
          final legendaryAvatars = avatars.where((avatar) => 
            avatar.rarity == 'legendary'
          ).toList();
          return _buildFirebaseItemGrid(legendaryAvatars, <UserAvatarOwnership>[], 'legendary');
        },
        error: (error, _) => _buildErrorState(error.toString()),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildFirebaseItemGrid(List<FirebaseAvatar> avatars, List<UserAvatarOwnership> ownerships, String category) {
    debugPrint('🏪 Building Firebase Item Grid - Category: $category');
    debugPrint('🏪 Input avatars: ${avatars.length}, ownerships: ${ownerships.length}');
    
    // Filter avatars based on search query
    final filteredAvatars = avatars.where((avatar) {
      if (_searchQuery.isEmpty) return true;
      return avatar.name.toLowerCase().contains(_searchQuery) ||
          avatar.description.toLowerCase().contains(_searchQuery) ||
          avatar.rarity.toLowerCase().contains(_searchQuery);
    }).toList();

    debugPrint('🏪 Filtered avatars: ${filteredAvatars.length}');
    debugPrint('🏪 Search query: "$_searchQuery"');

    if (filteredAvatars.isEmpty) {
      debugPrint('🏪 No filtered avatars - showing empty state');
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: 0.75,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredAvatars.length,
            itemBuilder: (context, index) {
              final avatar = filteredAvatars[index];
              final ownership = ownerships.firstWhere(
                (o) => o.avatarId == avatar.avatarId,
                orElse: () => UserAvatarOwnership(
                  userId: '',
                  avatarId: avatar.avatarId,
                  purchaseDate: DateTime.now(),
                  isEquipped: false,
                  customizations: {},
                  timesUsed: 0,
                  lastUsed: DateTime.now(),
                  metadata: {},
                ),
              );
              final isOwned = ownerships.any((o) => o.avatarId == avatar.avatarId);
              
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 50)),
                curve: Curves.easeOutBack,
                child: FirebaseAvatarCard(
                  avatar: avatar,
                  ownership: isOwned ? ownership : null,
                  onTap: () => _showFirebaseAvatarPreview(avatar, isOwned ? ownership : null),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                _searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.store_rounded,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _searchQuery.isNotEmpty
                  ? tr(context, 'no_results_title')
                  : tr(context, 'coming_soon_title'),
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? tr(context, 'no_results_message')
                  : tr(context, 'coming_soon_message'),
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    tr(context, 'clear_search'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showFirebaseAvatarPreview(FirebaseAvatar avatar, UserAvatarOwnership? ownership) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FirebaseAvatarPreviewModal(
        avatar: avatar,
        ownership: ownership,
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.withValues(alpha: 0.1),
                    Colors.orange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(70),
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              tr(context, 'error_title'),
              style: TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load avatars: ${error.length > 100 ? '${error.substring(0, 100)}...' : error}',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Trigger a rebuild to retry loading
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  tr(context, 'retry'),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}