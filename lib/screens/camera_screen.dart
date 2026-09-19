import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vision_service.dart';
import '../services/animal_service.dart';
import '../services/payment_service.dart';
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

    final visionService = VisionService();

    try {
      // Add artificial delay stages for better UX
      await Future.delayed(Duration(seconds: 1));

      // First, analyze the image to check if it contains a human or animal
      setState(() {
        _loadingMessage = 'Analyzing subject...';
        _loadingSubMessage = 'Determining what\'s in the image';
      });

      final analysisResult = await visionService.analyzeImage(widget.imageFile);

      // If a human was detected, or no animal was detected: not a failure,
      // just not identifiable. No credit is spent either way.
      if (analysisResult['is_human'] == true || analysisResult['is_animal'] == false) {
        await _showMessageAndGoBack(
          analysisResult['message'],
          Colors.orange,
        );
        return;
      }

      // Proceed with animal identification
      setState(() {
        _loadingMessage = 'Examining details...';
        _loadingSubMessage = 'Identifying species and characteristics';
      });

      final identification = analysisResult['animal_data'];

      await Future.delayed(Duration(milliseconds: 800));

      setState(() {
        _loadingMessage = 'Retrieving information...';
        _loadingSubMessage = 'Finding facts about this animal';
      });

      // Get detailed information about the animal
      final animalService = AnimalService();
      final animal = await animalService.getAnimalInfo(identification);

      await Future.delayed(Duration(milliseconds: 800));

      setState(() {
        _loadingMessage = 'Preparing results...';
        _loadingSubMessage = 'Almost done!';
      });

      await Future.delayed(Duration(milliseconds: 500));

      if (!mounted) return;

      // Only spend a credit once identification has actually succeeded.
      await Provider.of<PaymentService>(context, listen: false).useCredits(1);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            animal: animal,
            imageFile: widget.imageFile,
          ),
        ),
      );
    } catch (e) {
      await _showMessageAndGoBack(
        'Could not identify this photo. You were not charged. Please try again.',
        Colors.red,
      );
    }
  }

  Future<void> _showMessageAndGoBack(String message, Color color) async {
    if (!mounted) return;
    await Future.delayed(Duration(milliseconds: 500));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
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