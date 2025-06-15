import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/annuity_engine.dart'; // Adjust path as per your file

class AnnuityRateScreen extends StatefulWidget {
  const AnnuityRateScreen({super.key});

  @override
  State<AnnuityRateScreen> createState() => _AnnuityRateScreenState();
}

class _AnnuityRateScreenState extends State<AnnuityRateScreen> {
  double? finalRate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnnuityRate();
  }

  Future<void> fetchAnnuityRate() async {
    try {
      final annuityEngine = AnnuityEngine(Supabase.instance.client);

      final rate = await annuityEngine.getFinalAnnuityRate(
        planId: 'LIC_857',
        purchaseAmount: 500000,
        annuityOption: 'Single Life Immediate',
      );

      setState(() {
        finalRate = rate;
        isLoading = false;
      });

      debugPrint("🔥 Final Annuity Rate: ${rate.toStringAsFixed(2)}%");
    } catch (e) {
      debugPrint("❌ Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuity Rate"),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Text(
          finalRate != null
              ? "🔥 Final Annuity Rate: ${finalRate!.toStringAsFixed(2)}%"
              : "❌ Could not load rate",
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
