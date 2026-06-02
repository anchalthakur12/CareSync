import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  int _expandedPlan = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.getDiet();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.teal,
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Could not load diet plans', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text('Try Again', style: GoogleFonts.poppins()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final plans = (_data?['plans'] as List?) ?? [];
    final riskAdvice = _data?['risk_advice'] as String? ?? '';
    final riskLevel = _data?['risk_level'] as String? ?? 'Low';
    final medsCount = _data?['medicines_count'] as int? ?? 0;

    final riskColor = riskLevel == 'High'
        ? AppColors.red
        : riskLevel == 'Medium'
            ? AppColors.orange
            : AppColors.green;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRiskCard(riskLevel, riskColor, riskAdvice, medsCount),
        const SizedBox(height: 16),
        if (plans.isEmpty) _buildEmptyState() else ...[
          Row(
            children: [
              const Icon(Icons.restaurant_menu, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                '${plans.length} Personalised Diet Plan${plans.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...plans.asMap().entries.map((e) => _buildPlanCard(e.key, e.value as Map<String, dynamic>)),
        ],
        const SizedBox(height: 16),
        _buildGeneralTips(),
      ],
    );
  }

  Widget _buildRiskCard(String level, Color color, String advice, int medsCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.tealGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_dining, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Your Nutrition Guide',
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Text(
                  '$level Risk',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(advice, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 13, height: 1.5)),
          if (medsCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.medication, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Based on your $medsCount medicine${medsCount == 1 ? '' : 's'}',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.no_food, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('No Diet Plans Yet', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(
            'Add your medicines to get personalised diet recommendations based on your conditions.',
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Go to Medicines and add your medications — diet plans will appear here automatically.',
                    style: GoogleFonts.poppins(color: AppColors.teal, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index, Map<String, dynamic> plan) {
    final isExpanded = _expandedPlan == index;
    final condition = plan['condition'] as String? ?? '';
    final eatList = (plan['eat'] as List?)?.cast<String>() ?? [];
    final avoidList = (plan['avoid'] as List?)?.cast<String>() ?? [];
    final tipsList = (plan['tips'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? AppColors.teal.withOpacity(0.4) : AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _expandedPlan = isExpanded ? -1 : index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.spa_outlined, color: AppColors.teal, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(condition, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(
                          '${eatList.length} foods to eat  •  ${avoidList.length} to avoid',
                          style: GoogleFonts.poppins(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: AppColors.border),
            _buildSection(Icons.check_circle_outline, 'Foods to Eat', eatList, AppColors.green),
            _buildSection(Icons.cancel_outlined, 'Foods to Avoid', avoidList, AppColors.red),
            _buildSection(Icons.tips_and_updates_outlined, 'Health Tips', tipsList, AppColors.blue),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(IconData icon, String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item, style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildGeneralTips() {
    final tips = [
      ('Hydration', 'Drink at least 8 glasses of water daily to support medication absorption.', Icons.water_drop_outlined),
      ('Meal Timing', 'Eat at consistent times each day to keep energy levels and medication levels stable.', Icons.schedule_outlined),
      ('Portion Control', 'Use smaller plates and eat slowly — it takes 20 minutes to feel full.', Icons.straighten_outlined),
      ('Fibre First', 'Include vegetables or salad at the start of your meal to slow sugar absorption.', Icons.eco_outlined),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_outline, color: AppColors.orange, size: 18),
            const SizedBox(width: 8),
            Text('General Healthy Habits', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        ...tips.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(t.$3, color: AppColors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.$1, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(t.$2, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
