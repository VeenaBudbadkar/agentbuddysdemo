// ✅ Part: Training Suggested Carousel Below Ask Buddy
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:agentbuddys/screens/training/training_hub_screen.dart';

class SuggestedTrainingCarousel extends StatefulWidget {
  const SuggestedTrainingCarousel({super.key});

  @override
  State<SuggestedTrainingCarousel> createState() => _SuggestedTrainingCarouselState();
}

class _SuggestedTrainingCarouselState extends State<SuggestedTrainingCarousel> {
  final List<Map<String, String>> trainingCards = [
    {
      'title': 'IC 38 Made Easy',
      'tag': 'Starter',
      'image': 'https://via.placeholder.com/300x200.png?text=IC+38',
      'location': 'Mumbai'
    },
    {
      'title': 'Plan 914 Deep Dive',
      'tag': 'Plans',
      'image': 'https://via.placeholder.com/300x200.png?text=Plan+914',
      'location': 'Delhi'
    },
    {
      'title': 'Mission MDRT',
      'tag': 'Advanced',
      'image': 'https://via.placeholder.com/300x200.png?text=MDRT',
      'location': 'Mumbai'
    },
  ];

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentIndex = 0;
  String agentLocation = 'Mumbai'; // This should be dynamically set from agent profile

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_scrollController.hasClients) {
        _currentIndex = (_currentIndex + 1) % filteredTrainingCards.length;
        _scrollController.animateTo(
          _currentIndex * 228.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Map<String, String>> get filteredTrainingCards => trainingCards
      .where((card) => card['location'] == agentLocation)
      .toList();

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0, left: 4),
            child: Text(
              "🎓 Suggested Training",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 160,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: filteredTrainingCards.length,
              itemBuilder: (context, index) {
                final card = filteredTrainingCards[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingHubScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 220,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Hero(
                          tag: card['title']!,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: Image.network(
                              card['image']!,
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 90,
                                color: Colors.grey.shade300,
                                child: const Center(child: Icon(Icons.broken_image, size: 40)),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card['title']!,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  card['tag']!,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
