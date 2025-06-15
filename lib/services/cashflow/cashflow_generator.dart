import 'package:supabase_flutter/supabase_flutter.dart';

class CashflowGenerator {
  final SupabaseClient supabase;

  CashflowGenerator(this.supabase);

  /// Generate cashflow rows for a given policy ID
  Future<List<Map<String, dynamic>>> generate(String policyId) async {
    // 👉 1️⃣ Fetch the policy record
    final policy = await supabase
        .from('policy_master')
        .select()
        .eq('id', policyId)
        .single();

    final String policyType = policy['policy_type'];
    final int policyTerm = policy['policy_term'];
    final double baseSA = (policy['sum_assured'] ?? 0).toDouble();
    final double annualPremium = (policy['annual_premium'] ?? 0).toDouble();
    final double riskCoverMultiple = (policy['risk_cover_multiple'] ?? 0).toDouble();
    final double charges = (policy['charges'] ?? 0).toDouble();
    final double projectedReturn = (policy['projected_return'] ?? 8).toDouble();
    final settlementOption = policy['settlement_option'];
    final int startYear = DateTime.parse(policy['policy_start_date']).year;
    final int startAge = 30; // Or fetch from client profile if stored

    final List<Map<String, dynamic>> rows = [];

    double cumulativeSRB = 0;
    double fundValue = 0;
    double sumAssured = baseSA > 0 ? baseSA : (annualPremium * riskCoverMultiple);

    // 👉 2️⃣ Fetch G-Sec yield for Settlement Interest
    final gsec = await supabase
        .from('gsec_yield')
        .select()
        .order('date', ascending: false)
        .limit(1)
        .single();
    final settlementInterest = (gsec['yield'] ?? 7.5) - 2;

    // 👉 3️⃣ Pre-fetch all SRB & FAB rates (for Traditional)
    final List srbRates = await supabase
        .from('srb_rates')
        .select()
        .eq('plan_code', policy['plan_code'])
        .eq('policy_term', policyTerm)
        .lte('sa_range_min', baseSA)
        .gte('sa_range_max', baseSA);

    final List fabRates = await supabase
        .from('fab_rates')
        .select()
        .eq('plan_code', policy['plan_code'])
        .eq('policy_term', policyTerm)
        .lte('sa_range_min', baseSA)
        .gte('sa_range_max', baseSA);

    for (int year = 1; year <= policyTerm; year++) {
      int calendarYear = startYear + year - 1;
      int age = startAge + year - 1;

      double srbForYear = 0;
      double fabForYear = 0;

      if (policyType == 'Traditional') {
        // Find SRB for that calendar year
        final srbRow = srbRates.firstWhere(
              (row) => row['year'] == calendarYear,
          orElse: () => null,
        );
        if (srbRow != null) {
          srbForYear = (baseSA / 1000) * (srbRow['rate_per_1000'] ?? 0);
        }
        cumulativeSRB += srbForYear;

        // Find FAB for that policy year
        final fabRow = fabRates.firstWhere(
              (row) => row['year'] == year,
          orElse: () => null,
        );
        if (fabRow != null) {
          fabForYear = (baseSA / 1000) * (fabRow['fab_per_1000'] ?? 0);
        }
      }

      double riskCover = 0;
      double cashIn = 0;

      if (policyType == 'Traditional') {
        riskCover = baseSA + cumulativeSRB + fabForYear;
        if (year == policyTerm) {
          cashIn = baseSA + cumulativeSRB + fabForYear;
        }
      } else if (policyType == 'ULIP') {
        // ULIP projection
        double netPremium = annualPremium * (1 - charges / 100);
        fundValue += netPremium;
        fundValue *= (1 + projectedReturn / 100);
        riskCover = fundValue > sumAssured ? fundValue : sumAssured;
        if (year == policyTerm) {
          cashIn = fundValue;
        }
      }

      rows.add({
        'year': calendarYear,
        'age': age,
        'baseSA': baseSA.round(),
        'sumAssured': sumAssured.round(),
        'cumulativeSRB': cumulativeSRB.round(),
        'fabForYear': fabForYear.round(),
        'fundValue': policyType == 'ULIP' ? fundValue.round() : null,
        'riskCover': riskCover.round(),
        'premiumPaid': annualPremium.round(),
        'cashIn': cashIn.round(),
      });
    }

    // 👉 4️⃣ Handle Settlement Option
    if (settlementOption != null && settlementOption > 0) {
      final maturityAmount = rows.last['cashIn'].toDouble();
      double principalPortion = maturityAmount / settlementOption;
      double remaining = maturityAmount;

      for (int i = 0; i < settlementOption; i++) {
        double interest = remaining * (settlementInterest / 100);
        rows.add({
          'year': startYear + policyTerm + i,
          'age': startAge + policyTerm + i,
          'principal': principalPortion.round(),
          'interest': interest.round(),
          'totalSettlementPayout': (principalPortion + interest).round(),
        });
        remaining -= principalPortion;
      }
    }

    return rows;
  }
}
