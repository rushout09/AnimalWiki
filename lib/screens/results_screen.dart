import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../models/animal_model.dart';
import '../utils/theme.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/animal_info_card.dart';

class ResultsScreen extends StatefulWidget {
  final Animal animal;
  final File imageFile;

  const ResultsScreen({
    Key? key,
    required this.animal,
    required this.imageFile,
  }) : super(key: key);

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFavorite = false;
  final GlobalKey _imageKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  late Animal _animal;
  
  // Values for personalized insights
  late int _estimatedAge;
  late double _healthScore;
  late double _activityLevel;
  late double _rarityScore;
  late String _mood;
  late int _weightEstimate;
  late List<String> _personalityTraits;
  late List<String> _notableFeatures;
  late String _humanComparison;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animal = widget.animal;
    
    // Debug logging for incoming data
    print('RESULTS SCREEN - ANIMAL DATA RECEIVED:');
    print('Name: ${_animal.name}');
    print('Species: ${_animal.species}');
    print('Age: ${_animal.estimatedAge}');
    print('Weight: ${_animal.estimatedWeightKg}');
    print('Health: ${_animal.healthStatus}');
    print('Activity: ${_animal.activityLevel}');
    print('Mood: ${_animal.mood}');
    print('Rarity: ${_animal.rarity}');
    print('Notable features: ${_animal.notableFeatures}');
    
    // Extract values directly from the animal model
    _estimatedAge = _extractEstimatedAgeNumber();
    _healthScore = _extractHealthScoreValue();
    _activityLevel = _extractActivityLevelValue();
    _rarityScore = _extractRarityScoreValue();
    _mood = _animal.mood ?? 'Alert';
    _weightEstimate = _animal.estimatedWeightKg ?? 0;
    _personalityTraits = _extractPersonalityTraitsList();
    _notableFeatures = _animal.notableFeatures ?? ['Healthy appearance', 'Good condition', 'Typical coloration'];
    _humanComparison = _getHumanAgeComparison();
    
    // Listen to scroll events for collapsing app bar title
    _scrollController.addListener(() {
      final RenderBox? imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (imageBox != null) {
        final imageHeight = imageBox.size.height;
        final scrollOffset = _scrollController.offset;
        
        if (scrollOffset > (imageHeight - kToolbarHeight) && !_showAppBarTitle) {
          setState(() {
            _showAppBarTitle = true;
          });
        } else if (scrollOffset < (imageHeight - kToolbarHeight) && _showAppBarTitle) {
          setState(() {
            _showAppBarTitle = false;
          });
        }
      }
    });
  }

  // Helper methods to extract data from the animal model
  int _extractEstimatedAgeNumber() {
    if (_animal.estimatedAge == null) return 5; // Default age
    
    String ageStr = _animal.estimatedAge!;
    // Try to extract a number from the age string
    RegExp regExp = RegExp(r'(\d+)');
    var matches = regExp.firstMatch(ageStr);
    if (matches != null && matches.groupCount >= 1) {
      return int.tryParse(matches.group(1) ?? '5') ?? 5;
    }
    return 5;
  }
  
  double _extractHealthScoreValue() {
    if (_animal.healthStatus == null) return 0.75; // Default
    
    String health = _animal.healthStatus!.toLowerCase();
    if (health.contains('excellent')) return 0.95;
    if (health.contains('very good')) return 0.85;
    if (health.contains('good')) return 0.75;
    if (health.contains('fair')) return 0.6;
    if (health.contains('poor')) return 0.4;
    
    return 0.75;
  }
  
  double _extractActivityLevelValue() {
    if (_animal.activityLevel == null) return 0.7; // Default
    
    String activity = _animal.activityLevel!.toLowerCase();
    if (activity.contains('very active')) return 0.9;
    if (activity.contains('active')) return 0.75;
    if (activity.contains('moderate')) return 0.6;
    if (activity.contains('low')) return 0.4;
    if (activity.contains('sedentary')) return 0.25;
    
    return 0.7;
  }
  
  double _extractRarityScoreValue() {
    if (_animal.rarity == null) return 0.3; // Default
    
    String rarity = _animal.rarity!.toLowerCase();
    if (rarity.contains('extremely rare')) return 0.9;
    if (rarity.contains('rare')) return 0.7;
    if (rarity.contains('uncommon')) return 0.5;
    if (rarity.contains('common')) return 0.2;
    
    return 0.3;
  }
  
  List<String> _extractPersonalityTraitsList() {
    if (_animal.behavior != null && 
        _animal.behavior!['personality_traits'] != null && 
        _animal.behavior!['personality_traits'] is List) {
      return (_animal.behavior!['personality_traits'] as List)
          .map((item) => item.toString())
          .toList();
    }
    
    // Default traits based on animal class
    final species = _animal.species.toLowerCase();
    if (species.contains('felis') || species.contains('panthera')) {
      return ['Independent', 'Territorial', 'Stealthy', 'Agile'];
    } else if (species.contains('canis')) {
      return ['Social', 'Loyal', 'Playful', 'Intelligent'];
    } else if (species.contains('elephas') || species.contains('loxodonta')) {
      return ['Intelligent', 'Social', 'Gentle', 'Long memory'];
    }
    
    return ['Adaptive', 'Intelligent', 'Instinctive', 'Resilient'];
  }
  
  String _getHumanAgeComparison() {
    // Simple conversion - would be more sophisticated in a real app
    final species = _animal.species.toLowerCase();
    if (species.contains('canis')) {
      return '${_estimatedAge * 7} years in human age';
    } else if (species.contains('felis')) {
      return '${_estimatedAge * 6} years in human age';
    }
    return 'Comparable to ${_estimatedAge * 5} human years';
  }

  String _getHealthDescription() {
    if (_healthScore > 0.9) return 'Excellent';
    if (_healthScore > 0.75) return 'Very Good';
    if (_healthScore > 0.6) return 'Good';
    if (_healthScore > 0.4) return 'Fair';
    return 'Poor';
  }

  String _getActivityDescription() {
    if (_activityLevel > 0.8) return 'Very Active';
    if (_activityLevel > 0.6) return 'Active';
    if (_activityLevel > 0.4) return 'Moderate';
    if (_activityLevel > 0.2) return 'Low';
    return 'Sedentary';
  }

  String _getRarityDescription() {
    if (_rarityScore > 0.9) return 'Extremely Rare';
    if (_rarityScore > 0.7) return 'Rare';
    if (_rarityScore > 0.4) return 'Uncommon';
    return 'Common';
  }

  Color _getHealthColor() {
    if (_healthScore > 0.8) return Colors.green;
    if (_healthScore > 0.6) return Colors.lightGreen;
    if (_healthScore > 0.4) return Colors.orange;
    return Colors.red;
  }

  Color _getActivityColor() {
    if (_activityLevel > 0.7) return Colors.blue;
    if (_activityLevel > 0.4) return Colors.lightBlue;
    return Colors.blueGrey;
  }

  Color _getRarityColor() {
    if (_rarityScore > 0.8) return Colors.purple;
    if (_rarityScore > 0.5) return Colors.deepPurple;
    return Colors.deepPurple.shade200;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              expandedHeight: 300.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: _showAppBarTitle ? AppTheme.primary : Colors.transparent,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              leading: IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showAppBarTitle ? Colors.transparent : Colors.black.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _showAppBarTitle ? Colors.transparent : Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    // Share functionality would go here
                  },
                ),
              ],
              title: _showAppBarTitle 
                ? Text(
                    _animal.breed ?? _animal.species,
                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    ),
                  )
                : null,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Animal image with gradient overlay
                    Container(
                      key: _imageKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Image with error handling
                          Image.file(
                            widget.imageFile,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppTheme.primary, // Fallback color if image fails
                                child: Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.6),
                                ],
                                stops: [0.6, 1.0],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Animal name at bottom
                    Positioned(
                      left: 20,
                      bottom: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _animal.breed ?? _animal.species,
                            style: AppTheme.textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _animal.name,
                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            _animal.species,
                            style: AppTheme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: AppTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Insights'),
                  Tab(text: 'Profile'),
                  Tab(text: 'Facts'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Insights Tab
            SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal Stats
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        _buildStatCard(
                          title: 'AGE',
                          value: '${_animal.estimatedAge ?? "Unknown"}',
                          subtitle: _humanComparison,
                          icon: Icons.calendar_today,
                          color: Colors.teal,
                        ),
                        SizedBox(width: 16),
                        _buildStatCard(
                          title: 'WEIGHT',
                          value: '${_animal.estimatedWeightKg ?? 0} kg',
                          subtitle: 'Estimated',
                          icon: Icons.fitness_center,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                  
                  // Health Metrics - Circular indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Health Overview',
                      style: AppTheme.textTheme.headlineSmall,
                    ),
                  ),
                  
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceLight,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildCircularIndicator(
                                label: 'Health',
                                value: _healthScore,
                                color: _getHealthColor(),
                                description: _animal.healthStatus ?? _getHealthDescription(),
                                icon: Icons.favorite,
                              ),
                              _buildCircularIndicator(
                                label: 'Activity',
                                value: _activityLevel,
                                color: _getActivityColor(),
                                description: _animal.activityLevel ?? _getActivityDescription(),
                                icon: Icons.directions_run,
                              ),
                              _buildCircularIndicator(
                                label: 'Rarity',
                                value: _rarityScore,
                                color: _getRarityColor(),
                                description: _animal.rarity ?? _getRarityDescription(),
                                icon: Icons.star,
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Current State
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.psychology, 
                                  color: AppTheme.primary,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current State',
                                    style: AppTheme.textTheme.titleMedium,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'This animal appears to be $_mood',
                                    style: AppTheme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Notable Features
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Notable Features',
                      style: AppTheme.textTheme.headlineSmall,
                    ),
                  ),
                  
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceLight,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: _notableFeatures.map((feature) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accent.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle, 
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: AppTheme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Personality Traits
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Typical Personality',
                      style: AppTheme.textTheme.headlineSmall,
                    ),
                  ),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _personalityTraits.map((trait) {
                      return Chip(
                        label: Text(trait),
                        backgroundColor: AppTheme.secondary.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        avatar: CircleAvatar(
                          backgroundColor: AppTheme.secondary,
                          child: Text(
                            trait[0],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  SizedBox(height: AppTheme.spacingLarge),
                  
                  AnimatedGradientButton(
                    text: 'Identify Another Animal',
                    icon: Icons.camera_alt_rounded,
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    isFullWidth: true,
                  ),
                  
                  SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
            
            // Profile Tab
            SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About section with an image
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusMedium),
                            topRight: Radius.circular(AppTheme.radiusMedium),
                          ),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            color: AppTheme.primary.withOpacity(0.1),
                            child: Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(
                                  Icons.info_outline,
                                  size: 32,
                                  color: AppTheme.primary,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'About ${_animal.breed ?? _animal.species}',
                                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            _animal.description,
                            style: AppTheme.textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Quick Facts - Visual cards with icons
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Quick Facts',
                      style: AppTheme.textTheme.headlineSmall,
                    ),
                  ),
                  
                  AnimalInfoCard(
                    title: 'Habitat',
                    value: _animal.habitat,
                    icon: Icons.terrain_rounded,
                    iconColor: AppTheme.primary,
                  ),
                  
                  SizedBox(height: AppTheme.spacingMedium),
                  
                  AnimalInfoCard(
                    title: 'Diet',
                    value: _animal.diet,
                    icon: Icons.restaurant_rounded,
                    iconColor: AppTheme.secondary,
                  ),
                  
                  SizedBox(height: AppTheme.spacingMedium),
                  
                  AnimalInfoCard(
                    title: 'Lifespan',
                    value: _animal.lifespan,
                    icon: Icons.access_time_rounded,
                    iconColor: AppTheme.accent,
                  ),
                  
                  SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
            
            // Facts Tab with dynamic content
            SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Classification - Dynamic taxonomy
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusMedium),
                            topRight: Radius.circular(AppTheme.radiusMedium),
                          ),
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            color: AppTheme.secondary.withOpacity(0.1),
                            child: Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(
                                  Icons.category,
                                  size: 28,
                                  color: AppTheme.secondary,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Classification',
                                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Use actual taxonomy data from the animal model if available
                              if (_animal.taxonomy != null) ...[
                                _buildTaxonomyRow('Kingdom', _animal.taxonomy!['kingdom'] ?? 'Animalia'),
                                _buildTaxonomyRow('Phylum', _animal.taxonomy!['phylum'] ?? 'Chordata'),
                                _buildTaxonomyRow('Class', _animal.taxonomy!['class'] ?? 'Mammalia'),
                                _buildTaxonomyRow('Order', _animal.taxonomy!['order'] ?? 'Unknown'),
                                _buildTaxonomyRow('Family', _animal.taxonomy!['family'] ?? 'Unknown'),
                                _buildTaxonomyRow('Genus', _animal.taxonomy!['genus'] ?? _animal.species.split(' ').first),
                                _buildTaxonomyRow('Species', _animal.species),
                              ] else ...[
                                // Fallback if taxonomy data is not available
                                _buildTaxonomyRow('Kingdom', 'Animalia'),
                                _buildTaxonomyRow('Phylum', 'Chordata'),
                                _buildTaxonomyRow('Class', 'Mammalia'),
                                _buildTaxonomyRow('Order', _getOrderFromSpecies(_animal.species)),
                                _buildTaxonomyRow('Family', _getFamilyFromSpecies(_animal.species)),
                                _buildTaxonomyRow('Genus', _animal.species.split(' ').first),
                                _buildTaxonomyRow('Species', _animal.species),
                                if (_animal.breed != null) _buildTaxonomyRow('Breed', _animal.breed!),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Conservation Status - Dynamic
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    elevation: 0,
                    color: AppTheme.surfaceLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.radiusMedium),
                            topRight: Radius.circular(AppTheme.radiusMedium),
                          ),
                          child: Container(
                            height: 80,
                            width: double.infinity,
                            color: Colors.red.withOpacity(0.1),
                            child: Row(
                              children: [
                                SizedBox(width: 20),
                                Icon(
                                  Icons.warning_amber,
                                  size: 28,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Conservation Status',
                                  style: AppTheme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Dynamic conservation status
                              _buildConservationScale(
                                _animal.conservation != null && _animal.conservation!['status'] != null 
                                    ? _animal.conservation!['status'].toString() 
                                    : _getStatusFromRarity(_animal.rarity)
                              ),
                              
                              SizedBox(height: 20),
                              
                              // Dynamic population trend
                              Row(
                                children: [
                                  Icon(
                                    _getPopulationTrendIcon(_animal.conservation),
                                    color: _getPopulationTrendColor(_animal.conservation),
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Population Trend: ${_animal.conservation != null && _animal.conservation!['population_trend'] != null ? _animal.conservation!['population_trend'] : 'Unknown'}',
                                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                                      color: _getPopulationTrendColor(_animal.conservation),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              
                              SizedBox(height: 20),
                              
                              Text(
                                'Major Threats:',
                                style: AppTheme.textTheme.titleMedium,
                              ),
                              
                              SizedBox(height: 12),
                              
                              // Dynamic threats
                              if (_animal.conservation != null && 
                                  _animal.conservation!['threats'] != null && 
                                  _animal.conservation!['threats'] is List) ...[
                                ...(_animal.conservation!['threats'] as List).map((threat) => 
                                  _buildThreatItem(threat.toString())
                                ).toList(),
                              ] else ...[
                                // Fallback threats if none provided
                                _buildThreatItem(_getDefaultThreat(_animal)),
                                _buildThreatItem('Habitat loss and fragmentation'),
                                _buildThreatItem('Human-wildlife conflict'),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Interesting Facts - Dynamic
                  if (_animal.interestingFacts != null && _animal.interestingFacts!.isNotEmpty) ...[
                    SizedBox(height: 24),
                    
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      elevation: 0,
                      color: AppTheme.surfaceLight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(AppTheme.radiusMedium),
                              topRight: Radius.circular(AppTheme.radiusMedium),
                            ),
                            child: Container(
                              height: 80,
                              width: double.infinity,
                              color: AppTheme.accent.withOpacity(0.1),
                              child: Row(
                                children: [
                                  SizedBox(width: 20),
                                  Icon(
                                    Icons.lightbulb,
                                    size: 28,
                                    color: AppTheme.accent,
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Interesting Facts',
                                    style: AppTheme.textTheme.headlineSmall?.copyWith(
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: _animal.interestingFacts!.map((fact) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accent.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.lightbulb_outline,
                                          color: AppTheme.accent,
                                          size: 16,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          fact,
                                          style: AppTheme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UI Components
  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        elevation: 0,
        color: AppTheme.surfaceLight,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                value,
                style: AppTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircularIndicator({
    required String label,
    required double value,
    required Color color,
    required String description,
    required IconData icon,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 45.0,
          lineWidth: 8.0,
          percent: value,
          center: Icon(
            icon,
            color: color,
            size: 24,
          ),
          progressColor: color,
          backgroundColor: color.withOpacity(0.2),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animationDuration: 1500,
        ),
        SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Facts Tab Helper Methods
  Widget _buildTaxonomyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTheme.textTheme.titleMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTheme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to get conservation status from rarity string
  String _getStatusFromRarity(String? rarity) {
    if (rarity == null) return 'LC';
    
    switch (rarity.toLowerCase()) {
      case 'extremely rare':
      case 'critically endangered':
        return 'CR';
      case 'endangered':
      case 'rare':
        return 'EN';
      case 'vulnerable':
      case 'uncommon':
        return 'VU';
      case 'near threatened':
        return 'NT';
      default:
        return 'LC';
    }
  }

  // Helper to get a reasonable order classification from species
  String _getOrderFromSpecies(String species) {
    final genusLower = species.split(' ').first.toLowerCase();
    
    if (genusLower.contains('felis') || genusLower.contains('panthera')) {
      return 'Carnivora';
    } else if (genusLower.contains('canis') || genusLower.contains('vulpes')) {
      return 'Carnivora';
    } else if (genusLower.contains('elephas') || genusLower.contains('loxodonta')) {
      return 'Proboscidea';
    } else if (genusLower.contains('equus')) {
      return 'Perissodactyla';
    } else if (genusLower.contains('bos') || genusLower.contains('ovis')) {
      return 'Artiodactyla';
    }
    
    return 'Unknown';
  }

  // Helper to get a reasonable family classification from species
  String _getFamilyFromSpecies(String species) {
    final genusLower = species.split(' ').first.toLowerCase();
    
    if (genusLower.contains('felis') || genusLower.contains('panthera')) {
      return 'Felidae';
    } else if (genusLower.contains('canis') || genusLower.contains('vulpes')) {
      return 'Canidae';
    } else if (genusLower.contains('elephas') || genusLower.contains('loxodonta')) {
      return 'Elephantidae';
    } else if (genusLower.contains('equus')) {
      return 'Equidae';
    } else if (genusLower.contains('bos') || genusLower.contains('ovis')) {
      return 'Bovidae';
    }
    
    return 'Unknown';
  }

  // Helper to infer a default threat based on animal type
  String _getDefaultThreat(Animal animal) {
    final habitat = animal.habitat.toLowerCase();
    final species = animal.species.toLowerCase();
    
    if (habitat.contains('forest') || habitat.contains('jungle')) {
      return 'Deforestation and habitat destruction';
    } else if (habitat.contains('ocean') || habitat.contains('sea') || habitat.contains('marine')) {
      return 'Ocean pollution and overfishing';
    } else if (habitat.contains('desert') || habitat.contains('arid')) {
      return 'Desertification and climate change';
    } else if (species.contains('tiger') || species.contains('rhino') || species.contains('elephant')) {
      return 'Poaching for body parts';
    }
    
    return 'Habitat loss due to human development';
  }

  // Helper to build the conservation status scale
  Widget _buildConservationScale(String status) {
    // Normalize the status code
    String normalizedStatus = 'LC';
    if (status.length <= 2) {
      normalizedStatus = status.toUpperCase();
    } else {
      // If it's a longer text description, try to match it
      final statusLower = status.toLowerCase();
      if (statusLower.contains('least') || statusLower.contains('common')) {
        normalizedStatus = 'LC';
      } else if (statusLower.contains('near') || statusLower.contains('threat')) {
        normalizedStatus = 'NT';
      } else if (statusLower.contains('vulner')) {
        normalizedStatus = 'VU';
      } else if (statusLower.contains('endang') && !statusLower.contains('critical')) {
        normalizedStatus = 'EN';
      } else if (statusLower.contains('critic') || statusLower.contains('extreme')) {
        normalizedStatus = 'CR';
      }
    }
    
    // Get the full status name
    String statusName = '';
    Color statusColor = Colors.green;
    
    switch (normalizedStatus) {
      case 'LC':
        statusName = 'LEAST CONCERN';
        statusColor = Colors.green;
        break;
      case 'NT':
        statusName = 'NEAR THREATENED';
        statusColor = Colors.lime;
        break;
      case 'VU':
        statusName = 'VULNERABLE';
        statusColor = Colors.orange;
        break;
      case 'EN':
        statusName = 'ENDANGERED';
        statusColor = Colors.deepOrange;
        break;
      case 'CR':
        statusName = 'CRITICALLY ENDANGERED';
        statusColor = Colors.red;
        break;
      default:
        statusName = 'UNKNOWN';
        statusColor = Colors.grey;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            color: Colors.grey.shade200,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(AppTheme.radiusSmall),
                      bottomLeft: Radius.circular(AppTheme.radiusSmall),
                    ),
                    color: Colors.green,
                  ),
                  child: Center(
                    child: Text(
                      'LC',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.lime,
                  child: Center(
                    child: Text(
                      'NT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.orange,
                  child: Center(
                    child: Text(
                      'VU',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.deepOrange,
                  child: Center(
                    child: Text(
                      'EN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(AppTheme.radiusSmall),
                      bottomRight: Radius.circular(AppTheme.radiusSmall),
                    ),
                    color: Colors.red,
                  ),
                  child: Center(
                    child: Text(
                      'CR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: statusColor.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Text(
                statusName,
                style: AppTheme.textTheme.titleMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Get appropriate icon for population trend
  IconData _getPopulationTrendIcon(Map<String, dynamic>? conservation) {
    if (conservation == null || conservation['population_trend'] == null) {
      return Icons.help_outline;
    }
    
    final trend = conservation['population_trend'].toString().toLowerCase();
    
    if (trend.contains('decreas') || trend.contains('declin')) {
      return Icons.trending_down;
    } else if (trend.contains('increas')) {
      return Icons.trending_up;
    } else if (trend.contains('stable')) {
      return Icons.trending_flat;
    }
    
    return Icons.help_outline;
  }

  // Get appropriate color for population trend
  Color _getPopulationTrendColor(Map<String, dynamic>? conservation) {
    if (conservation == null || conservation['population_trend'] == null) {
      return Colors.grey;
    }
    
    final trend = conservation['population_trend'].toString().toLowerCase();
    
    if (trend.contains('decreas') || trend.contains('declin')) {
      return Colors.red;
    } else if (trend.contains('increas')) {
      return Colors.green;
    } else if (trend.contains('stable')) {
      return Colors.blue;
    }
    
    return Colors.grey;
  }

  // Helper to build threat items
  Widget _buildThreatItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            color: Colors.red.withOpacity(0.7),
            size: 18,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTheme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}