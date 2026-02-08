import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_colors.dart';
import '../core/l10n/l10n_provider.dart';
import '../models/account_mode.dart';
import '../models/smart_insight.dart';
import '../models/transaction.dart';
import 'account_provider.dart';
import 'transaction_provider.dart';
import 'subscription_provider.dart';
import 'deal_provider.dart';
import 'invoice_provider.dart';
import 'contact_provider.dart';

final _cf = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

final smartInsightsProvider = Provider<List<SmartInsight>>((ref) {
  final mode = ref.watch(accountModeProvider);
  final s = ref.watch(stringsProvider);
  final isPersonal = mode == AccountMode.personal;
  final now = DateTime.now();

  final transactions = ref.watch(filteredTransactionsProvider);
  final totalIncome = ref.watch(totalIncomeProvider);
  final totalExpense = ref.watch(totalExpenseProvider);
  final monthlySubs = ref.watch(totalMonthlySubscriptionCostProvider);
  final netBalance = ref.watch(netBalanceProvider);

  final insights = <SmartInsight>[];

  // --- Shared insights ---
  final savingsRate = totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome * 100 : 0.0;

  // High expense alert
  if (totalExpense > totalIncome * 0.9 && totalIncome > 0) {
    insights.add(SmartInsight(
      id: 'alert_high_expense',
      title: s.aiAlertHighExpense,
      description: s.aiAlertHighExpenseDesc(
        _cf.format(totalExpense),
        '${savingsRate.toStringAsFixed(0)}%',
      ),
      type: InsightType.alert,
      priority: InsightPriority.high,
      icon: Icons.warning_amber_rounded,
      color: AppColors.expense,
      createdAt: now,
    ));
  }

  // Net positive achievement
  if (netBalance > 0 && savingsRate >= 20) {
    insights.add(SmartInsight(
      id: 'achieve_savings',
      title: s.aiAchieveSavings,
      description: s.aiAchieveSavingsDesc('${savingsRate.toStringAsFixed(0)}%'),
      type: InsightType.achievement,
      priority: InsightPriority.low,
      icon: Icons.emoji_events_outlined,
      color: AppColors.income,
      createdAt: now,
    ));
  }

  // Subscription cost warning
  if (monthlySubs > (isPersonal ? 500 : 3000)) {
    insights.add(SmartInsight(
      id: 'warn_subs',
      title: s.aiWarnSubs,
      description: s.aiWarnSubsDesc(_cf.format(monthlySubs), _cf.format(monthlySubs * 12)),
      type: InsightType.warning,
      priority: InsightPriority.medium,
      icon: Icons.autorenew,
      color: AppColors.warning,
      createdAt: now,
    ));
  }

  // Recurring expense ratio
  final recurringExp = transactions
      .where((t) => t.isRecurring && t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);
  if (totalExpense > 0 && recurringExp / totalExpense > 0.7) {
    insights.add(SmartInsight(
      id: 'trend_recurring',
      title: s.aiTrendRecurring,
      description: s.aiTrendRecurringDesc('${(recurringExp / totalExpense * 100).toStringAsFixed(0)}%'),
      type: InsightType.trend,
      priority: InsightPriority.medium,
      icon: Icons.repeat,
      color: const Color(0xFFF97316),
      createdAt: now,
    ));
  }

  // Top expense category
  final expenseByCategory = <TransactionCategory, double>{};
  for (final t in transactions.where((t) => t.type == TransactionType.expense)) {
    expenseByCategory[t.category] = (expenseByCategory[t.category] ?? 0) + t.amount;
  }
  if (expenseByCategory.isNotEmpty) {
    final topCategory = expenseByCategory.entries.reduce((a, b) => a.value > b.value ? a : b);
    final pct = totalExpense > 0 ? (topCategory.value / totalExpense * 100).toStringAsFixed(0) : '0';
    insights.add(SmartInsight(
      id: 'trend_top_category',
      title: s.aiTrendTopCategory,
      description: s.aiTrendTopCategoryDesc(
        s.categoryName(topCategory.key.name),
        _cf.format(topCategory.value),
        '$pct%',
      ),
      type: InsightType.trend,
      priority: InsightPriority.low,
      icon: Icons.pie_chart_outline,
      color: AppColors.primary,
      createdAt: now,
    ));
  }

  // --- Business-only insights ---
  if (!isPersonal) {
    final pipelineValue = ref.watch(totalPipelineValueProvider);
    final winRate = ref.watch(winRateProvider);
    final totalReceivable = ref.watch(totalReceivableProvider);
    final overdueAmount = ref.watch(totalOverdueProvider);
    final leadsCount = ref.watch(totalLeadsCountProvider);

    // Pipeline health
    if (pipelineValue > 0) {
      insights.add(SmartInsight(
        id: 'biz_pipeline',
        title: s.aiPipelineHealth,
        description: s.aiPipelineHealthDesc(
          _cf.format(pipelineValue),
          '${winRate.toStringAsFixed(0)}%',
        ),
        type: InsightType.tip,
        priority: InsightPriority.medium,
        icon: Icons.filter_list,
        color: AppColors.business,
        createdAt: now,
      ));
    }

    // Overdue invoices alert
    if (overdueAmount > 0) {
      insights.add(SmartInsight(
        id: 'biz_overdue',
        title: s.aiOverdueInvoices,
        description: s.aiOverdueInvoicesDesc(_cf.format(overdueAmount)),
        type: InsightType.alert,
        priority: InsightPriority.high,
        icon: Icons.receipt_long,
        color: AppColors.expense,
        createdAt: now,
      ));
    }

    // Receivable tracking
    if (totalReceivable > 0) {
      insights.add(SmartInsight(
        id: 'biz_receivable',
        title: s.aiReceivable,
        description: s.aiReceivableDesc(_cf.format(totalReceivable)),
        type: InsightType.tip,
        priority: InsightPriority.medium,
        icon: Icons.payments_outlined,
        color: AppColors.warning,
        createdAt: now,
      ));
    }

    // New leads
    if (leadsCount > 0) {
      insights.add(SmartInsight(
        id: 'biz_leads',
        title: s.aiNewLeads,
        description: s.aiNewLeadsDesc(leadsCount),
        type: InsightType.tip,
        priority: InsightPriority.low,
        icon: Icons.people_outline,
        color: AppColors.primary,
        createdAt: now,
      ));
    }
  } else {
    // --- Personal-only insights ---
    // Emergency fund tip
    if (netBalance > 0 && netBalance < totalExpense * 3) {
      insights.add(SmartInsight(
        id: 'personal_emergency',
        title: s.aiEmergencyFund,
        description: s.aiEmergencyFundDesc(
          _cf.format(netBalance),
          _cf.format(totalExpense * 6),
        ),
        type: InsightType.tip,
        priority: InsightPriority.medium,
        icon: Icons.shield_outlined,
        color: AppColors.primary,
        createdAt: now,
      ));
    }
  }

  // Sort: high priority first
  insights.sort((a, b) => a.priority.index.compareTo(b.priority.index));

  return insights;
});
