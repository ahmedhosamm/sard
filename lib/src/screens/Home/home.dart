import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../style/BaseScreen.dart';
import '../../../style/Colors.dart';
import '../../../style/Fonts.dart';
import '../Home/Data/home_model.dart';
import '../Home/Logic/home_cubit.dart';
import '../Home/Logic/home_state.dart';
import '../Home/Withoutcategories/WithoutCategoryDetailsPage.dart';
import '../Home/categories/CategoryDetailsPage.dart';
import '../Home/categories/Data/categories_dio.dart';
import '../Home/categories/Logic/categories_cubit.dart';
import '../Home/categories/Logic/categories_state.dart';
import '../Home/Logic/home_books_cubit.dart';
import '../Home/search/search_results_screen.dart';

class CategoryItem extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? AppColors.primary600 : AppColors.neutral300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category['icon'] as IconData,
              size: 16,
              color: isSelected ? AppColors.primary600 : AppColors.neutral700,
            ),
            SizedBox(width: 4),
            Text(
              category['label'] as String,
              style: AppTexts.contentRegular.copyWith(
                color: isSelected ? AppColors.primary600 : AppColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategorySection extends StatefulWidget {
  final VoidCallback? onResetRequested;
  const CategorySection({super.key, this.onResetRequested});

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  int selectedIndex = -1;

  void resetSelection() {
    if (mounted) {
      setState(() {
        selectedIndex = -1;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<CategoriesCubit>().getCategories();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoriesCubit, CategoriesState>(
      buildWhen: (previous, current) =>
          current is CategoriesLoading || current is CategoriesLoaded,
      builder: (context, state) {
        if (state is CategoriesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CategoriesLoaded) {
          final categories = state.categories;

          return Column(
            children: [
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(categories.length, (index) {
                    final category = categories[index];
                    final isSelected = selectedIndex == index;
                    return Padding(
                      padding: EdgeInsets.only(right: index == 0 ? 0 : 8),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (selectedIndex == index) {
                              selectedIndex = -1;
                            } else {
                              selectedIndex = index;
                            }
                          });
                        },
                        child: Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary100
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary600
                                  : AppColors.neutral300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  category.photo,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.category,
                                      size: 24,
                                      color: isSelected
                                          ? AppColors.primary600
                                          : AppColors.neutral700,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                category.name,
                                style: AppTexts.contentRegular.copyWith(
                                  color: isSelected
                                      ? AppColors.primary600
                                      : AppColors.neutral700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (selectedIndex == -1)
                WithoutCategoryDetailsPage()
              else
                CategoryDetailsPage(id: categories[selectedIndex].id),
            ],
          );
        }

        if (state is CategoriesError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.primary600,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل الفئات',
                    style: AppTexts.heading3Bold.copyWith(
                      color: AppColors.neutral800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    state.message,
                    style: AppTexts.contentRegular.copyWith(
                      color: AppColors.neutral500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<CategoriesCubit>().getCategories();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      'إعادة المحاولة',
                      style: AppTexts.contentBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final dio = Dio()..options.baseUrl = 'https://api.mohamed-ramadan.me/api/';
  final GlobalKey<_CategorySectionState> _categorySectionKey =
      GlobalKey<_CategorySectionState>();

  late HomeCubit homeCubit;
  late CategoriesCubit categoriesCubit;
  late HomeBooksLCubit homeBooksLCubit;

  @override
  void initState() {
    super.initState();
    homeCubit = context.read<HomeCubit>();
    categoriesCubit = context.read<CategoriesCubit>();
    homeBooksLCubit = context.read<HomeBooksLCubit>();
    _loadInitialData();
  }

  void _loadInitialData() {
    // Load data using cache if available
    homeCubit.getUserData();
    categoriesCubit.getCategories();
    homeBooksLCubit.loadRecommendedBooks(limit: 4);
    homeBooksLCubit.loadExchangeBooks(limit: 3);
  }

  Future<void> _refreshData() async {
    // Force refresh all data
    await Future.wait([
      homeCubit.refreshUserData(),
      categoriesCubit.refreshCategories(),
      homeBooksLCubit.refreshRecommendedBooks(),
      homeBooksLCubit.refreshExchangeBooks(),
    ]);
  }

  void resetCategorySelection() {
    _categorySectionKey.currentState?.resetSelection();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: homeCubit),
        BlocProvider.value(value: categoriesCubit),
        BlocProvider.value(value: homeBooksLCubit),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Column(
            children: [
              Container(
                  width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                                  child: SafeArea(
                    bottom: false,
                    child: BlocBuilder<HomeCubit, HomeState>(
                      builder: (context, state) {
                        if (state is HomeLoaded) {
                          UserModelhome user = state.user;
                          
                          // Generate dynamic streak icons for AppBar
                          List<Widget> _buildStreakIconsForAppBar(int currentStreak) {
                            List<Widget> icons = [];

                            for (int i = 1; i <= 7; i++) {
                              String assetPath = '';

                              if (i == 7) {
                                // اليوم السابع دايماً له شكل مختلف
                                assetPath = 'assets/img/streak week done.png';
                              } else if (currentStreak == 0) {
                                assetPath = 'assets/img/streak_waiting.png';
                              } else if (i < currentStreak) {
                                assetPath = 'assets/img/streakDone.png';
                              } else if (i == currentStreak) {
                                assetPath = 'assets/img/streak_Today.png';
                              } else {
                                assetPath = 'assets/img/streak_waiting.png';
                              }

                              icons.add(
                                Image.asset(
                                  assetPath,
                                  width: 38,
                                  height: 38,
                                ),
                              );
                            }

                            return icons;
                          }
                          
                          return Column(
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundImage: user.photo.isNotEmpty
                                        ? NetworkImage(user.photo)
                                        : AssetImage('assets/img/Avatar.png')
                                            as ImageProvider,
                                    onBackgroundImageError: user.photo.isNotEmpty
                                        ? (exception, stackTrace) {
                                            // Handle network image load error
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            text: 'اهلا, ',
                                            style: AppTexts.heading2Bold.copyWith(
                                              color: AppColors.neutral200,
                                              fontSize: 22,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: user.name,
                                                style: AppTexts.heading1Bold.copyWith(
                                                  color: AppColors.neutral100,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${user.message}',
                                          style: AppTexts.contentRegular.copyWith(
                                            color: AppColors.neutral100,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: _buildStreakIconsForAppBar(user.streak),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${user.points}',
                                          style: AppTexts.heading2Bold.copyWith(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Image.asset(
                                          'assets/img/coin.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          return Text(
                            'جاري تحميل البيانات',
                            style: AppTexts.heading1Bold.copyWith(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ),
              Expanded(
                child: BaseScreen(
                  child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                if (state is HomeLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is HomeLoaded) {
                  return RefreshIndicator(
                    onRefresh: _refreshData,
                    color: AppColors.primary500,
                    backgroundColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SearchResultsScreen(searchQuery: ''),
                              ),
                            );
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'عن ماذا تبحث؟',
                                hintStyle: AppTexts.contentEmphasis
                                    .copyWith(color: AppColors.neutral600),
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                prefixIcon:
                                    Icon(Icons.search, color: AppColors.neutral600),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: AppColors.neutral300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: AppColors.primary600),
                                ),
                              ),
                              style: AppTexts.contentEmphasis
                                  .copyWith(color: AppColors.neutral1000),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(), // Important for RefreshIndicator
                            child: CategorySection(key: _categorySectionKey),
                          ),
                        ),
                      ],
                    ),
                  );
              } else if (state is HomeError) {
                return RefreshIndicator(
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 200,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 80,
                                color: AppColors.primary600,
                              ),
                              SizedBox(height: 24),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  text: 'عذراً، حدث خطأ أثناء تحميل ',
                                  style: AppTexts.heading2Bold.copyWith(
                                    color: AppColors.neutral700,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'الصفحة الرئيسية',
                                      style: AppTexts.heading2Bold.copyWith(
                                        color: AppColors.red200,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary200,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  state.message,
                                  style: AppTexts.contentRegular.copyWith(
                                    color: AppColors.neutral700,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  homeCubit.getUserData(forceRefresh: true);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary500,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'إعادة المحاولة',
                                  style: AppTexts.contentBold.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refreshData,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height - 200,
                    child: SizedBox(),
                  ),
                ),
              );
            },
          ),
        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
