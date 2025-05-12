import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/article.dart';
import '../../services/article_service.dart';
import '../../services/auth_service.dart';
import '../article/article_detail_screen.dart';
import '../article/create_article_screen.dart';
import '../auth/login_screen.dart';
// Discussion forum removed as requested
import '../../widgets/article_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/expanded_fab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ArticleService _articleService = ArticleService();
  final AuthService _authService = AuthService();
  
  String _searchQuery = '';
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  
  // Category tabs
  final List<String> _categories = ['All', 'Technology', 'Design', 'Business', 'Lifestyle'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }
  
  void _handleSearch() {
    setState(() {
      _isSearching = !_isSearching;
    });
  }
  
  void _filterArticles(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gestion Articles',
        onSearch: _handleSearch,
        onSearchQueryChanged: _filterArticles,
        actions: [
          // Only keeping the logout button, theme toggle is already in CustomAppBar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs - improved design
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              tabs: _categories.map((category) => Tab(
                text: category,
                height: 48,
              )).toList(),
            ),
          ),
          
          // Main content - Articles list
          Expanded(
            child: StreamBuilder<List<Article>>(
              stream: _articleService.getArticles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => setState(() {}),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                List<Article> articles = snapshot.data ?? [];
                
                // Filter based on search query
                if (_searchQuery.isNotEmpty) {
                  articles = articles.where((article) {
                    return article.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                           article.content.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();
                }
                
                // Filter based on selected category tab, except for 'All'
                if (_tabController.index > 0 && _categories[_tabController.index] != 'All') {
                  // In real app, you'd have a category field in Article model
                  // This is just for demo purposes
                  final selectedCategory = _categories[_tabController.index].toLowerCase();
                  // Mock filtering based on title/content containing category
                  articles = articles.where((article) {
                    return article.title.toLowerCase().contains(selectedCategory) || 
                           article.content.toLowerCase().contains(selectedCategory);
                  }).toList();
                }

                if (articles.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.article_outlined,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _searchQuery.isNotEmpty 
                                ? 'No articles matching your search' 
                                : 'No articles yet',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try using different keywords'
                                : 'Create your first article by tapping the button below',
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          if (_searchQuery.isNotEmpty)
                            ElevatedButton.icon(
                              onPressed: () => _filterArticles(''),
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear search'),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateArticleScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Article'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // This will trigger a reload of the stream
                    setState(() {});
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8.0),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final article = articles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ArticleCard(
                          article: article,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(
                                  articleId: article.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        distance: 112.0,
        children: [
          ActionButton(
            icon: const Icon(Icons.article_outlined),
            tooltip: 'Create Article',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateArticleScreen(),
                ),
              );
            },
          ),
          ActionButton(
            icon: const Icon(Icons.photo_camera),
            tooltip: 'Add Photo Article',
            backgroundColor: theme.colorScheme.tertiaryContainer,
            onPressed: () {
              // Uses our existing cross-platform image handling
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateArticleScreen(startWithImage: true),
                ),
              );
            },
          ),
          // Discussion forum button removed
        ],
      ),
    );
  }
}
