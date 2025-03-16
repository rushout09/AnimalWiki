import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/vision_service.dart';
import '../services/animal_service.dart';
import '../models/animal_model.dart';
import '../widgets/animated_loading.dart';
import '../utils/theme.dart';
import 'results_screen.dart';

class CameraScreen extends StatefulWidget {
  final File imageFile;

  const CameraScreen({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _loadingMessage = 'Analyzing image...';
  String? _loadingSubMessage;
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup pulse animation for the scanning effect
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Start analysis after a short delay for better UX
    Future.delayed(Duration(milliseconds: 500), () {
      _analyzeImage();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _analyzeImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Analyzing image...';
      _loadingSubMessage = 'Identifying what\'s in the photo';
    });

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
      print('Using API key: $apiKey');
      
      final visionService = VisionService(apiKey: apiKey);
      
      // For debugging - create a minimal animal model in case of API issues
      var fallbackAnimal = Animal(
        id: 'fallback-1',
        name: 'Bengal Tiger',
        species: 'Panthera tigris tigris',
        breed: 'Bengal',
        description: 'The Bengal tiger is a tiger subspecies native to the Indian subcontinent. It is the most numerous tiger subspecies, and is threatened by poaching, loss, and fragmentation of habitat. It is listed as Endangered on the IUCN Red List.',
        habitat: 'Dense forests, mangrove swamps, and grasslands across India, Bangladesh, Nepal, and Bhutan',
        diet: 'Carnivore - primarily deer, wild boar, and other large mammals',
        lifespan: '8-10 years in the wild, up to 18 in captivity',
        imageUrl: '',
        estimatedAge: '5-7 years',
        estimatedWeightKg: 220,
        healthStatus: 'Good',
        activityLevel: 'Active',
        mood: 'Alert',
        rarity: 'Endangered',
        notableFeatures: [
          'Distinctive striped pattern', 
          'Muscular build', 
          'Healthy coat'
        ],
        taxonomy: {
          'kingdom': 'Animalia',
          'phylum': 'Chordata',
          'class': 'Mammalia',
          'order': 'Carnivora',
          'family': 'Felidae',
          'genus': 'Panthera'
        },
        conservation: {
          'status': 'EN',
          'population_trend': 'Decreasing',
          'threats': [
            'Habitat loss and fragmentation',
            'Poaching for traditional medicine',
            'Human-wildlife conflict'
          ]
        },
        behavior: {
          'activity_pattern': 'Nocturnal',
          'social_structure': 'Solitary',
          'personality_traits': [
            'Territorial', 
            'Powerful', 
            'Stealthy', 
            'Intelligent'
          ]
        },
        interestingFacts: [
          'Bengal tigers can consume up to 40 kg in a single meal',
          'Each tiger has a unique stripe pattern like a fingerprint',
          'Tigers can leap distances of over 6 meters'
        ],
      );
      
      try {
        // Add artificial delay stages for better UX
        await Future.delayed(Duration(seconds: 1));
        
        // First, analyze the image to check if it contains a human or animal
        setState(() {
          _loadingMessage = 'Analyzing subject...';
          _loadingSubMessage = 'Determining what\'s in the image';
        });
        
        final analysisResult = await visionService.analyzeImage(widget.imageFile);
        
        // If a human was detected
        if (analysisResult['is_human'] == true) {
          // Show error and return to previous screen
          if (mounted) {
            await Future.delayed(Duration(milliseconds: 500));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(analysisResult['message']),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
            Navigator.pop(context);
          }
          return;
        }
        
        // If no animal was detected
        if (analysisResult['is_animal'] == false) {
          if (mounted) {
            await Future.delayed(Duration(milliseconds: 500));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(analysisResult['message']),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {},
                ),
              ),
            );
            Navigator.pop(context);
          }
          return;
        }
        
        // Proceed with animal identification
        setState(() {
          _loadingMessage = 'Examining details...';
          _loadingSubMessage = 'Identifying species and characteristics';
        });
        
        final identification = analysisResult['animal_data'];
        print('Animal data: $identification');

        await Future.delayed(Duration(milliseconds: 800));
        
        setState(() {
          _loadingMessage = 'Retrieving information...';
          _loadingSubMessage = 'Finding facts about this animal';
        });

        // Get detailed information about the animal
        final animalService = AnimalService(apiKey: apiKey);
        final animal = await animalService.getAnimalInfo(identification);

        await Future.delayed(Duration(milliseconds: 800));
        
        setState(() {
          _loadingMessage = 'Preparing results...';
          _loadingSubMessage = 'Almost done!';
        });

        await Future.delayed(Duration(milliseconds: 500));

        // Navigate to results screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                animal: animal,
                imageFile: widget.imageFile,
              ),
            ),
          );
        }
      } catch (e) {
        print('Error during animal info retrieval: $e');
        // Use fallback animal if API fails
        await Future.delayed(Duration(milliseconds: 800));
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                animal: fallbackAnimal,
                imageFile: widget.imageFile,
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Critical error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Image preview with scanning effect
          if (!_isLoading)
            Center(
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
              ),
            )
          else
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background dimmed image
                  Opacity(
                    opacity: 0.2, // Darker background for better contrast
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  
                  // Backdrop blur effect for improved readability
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  
                  // Scanning animation overlay
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primary.withOpacity(0.6),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Enhanced loading content
                  AnimatedLoading(
                    message: _loadingMessage,
                    subMessage: _loadingSubMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}