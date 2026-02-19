import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/presentation/widgets/bounceable.dart';

class GuideStep {
  final String title; // Optional title for the step itself
  final String description;
  final IconData? icon; // Placeholder if no image
  final String? imagePath; // Asset path for the image
  final Color? color;

  GuideStep({
    this.title = '',
    required this.description,
    this.icon,
    this.imagePath,
    this.color,
  });
}

class GuideDetailScreen extends StatefulWidget {
  final String title;
  final List<GuideStep> steps;
  final String buttonText;
  final VoidCallback onStart;

  const GuideDetailScreen({
    super.key,
    required this.title,
    required this.steps,
    this.buttonText = 'Start Now',
    required this.onStart,
  });

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image Slider Section (Top 3/4ish)
            Expanded(
              flex: 3,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.steps.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final step = widget.steps[index];
                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image Placeholder
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: step.color?.withOpacity(0.1) ?? Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: step.color?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: step.imagePath != null
                                  ? Image.asset(
                                      step.imagePath!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 50));
                                      },
                                    )
                                  : Center(
                                      child: Icon(
                                        step.icon ?? Icons.image,
                                        size: 80,
                                        color: step.color ?? Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Text Description & Indicator
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: widget.steps.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: widget.steps[_currentPage].color ?? Colors.white,
                        dotColor: Colors.grey.shade800,
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.steps[_currentPage].description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Bounceable(
                onTap: widget.onStart,
                scaleFactor: 0.95,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: widget.steps[_currentPage].color ?? const Color(0xFF6C63FF),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
