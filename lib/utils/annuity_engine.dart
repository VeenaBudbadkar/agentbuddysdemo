import 'package:supabase_flutter/supabase_flutter.dart';

class AnnuityEngine {
  final SupabaseClient supabase;

  AnnuityEngine(this.supabase);

  /// Computes the final annuity payout rate for given plan, purchase amount & option
  Future<double> getFinalAnnuityRate({
    required String planId,
    required double purchaseAmount,
    required String annuityOption,
  }) async {
    // 1️⃣ Fetch repo rate
    final repoResponse = await supabase
        .from('market_rates')
        .select('current_rate')
        .eq('rate_name', 'repo_rate')
        .single();
    final repoRate = (repoResponse['current_rate'] as num).toDouble();

    // 2️⃣ Fetch matching annuity rate bracket for this plan & purchase amount
    final rateResponse = await supabase
        .from('annuity_rates')
        .select()
        .eq('plan_id', planId)
        .eq('annuity_option', annuityOption)
        .lte('purchase_amount_min', purchaseAmount)
        .gte('purchase_amount_max', purchaseAmount)
        .single();

    final baseRate = (rateResponse['rate_percent'] as num).toDouble();
    final pegFormula = rateResponse['peg_formula'] as String?;

    // 3️⃣ Compute final rate
    double finalRate;

    if (pegFormula != null && pegFormula.contains('-')) {
      // Example: "repo_rate - 1.75"
      final pegValue = double.parse(pegFormula.split('-')[1].trim());
      finalRate = repoRate - pegValue;
    } else {
      finalRate = baseRate;
    }

    return finalRate;
  }
}
