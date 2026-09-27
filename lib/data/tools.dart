import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/tool_definition.dart';

/// Category ids used by the calculator catalogue.
const kCategoryTrading = 'trading';
const kCategoryInvestment = 'investment';

const appTools = <ToolDefinition>[
  ToolDefinition(
    id: 'compound',
    icon: Icons.auto_graph_rounded,
    color: Color(0xff7657e8),
    categoryId: kCategoryInvestment,
  ),
  ToolDefinition(
    id: 'risk',
    icon: Icons.balance_rounded,
    color: Color(0xffed6a5a),
    categoryId: kCategoryTrading,
  ),
  ToolDefinition(
    id: 'position',
    icon: Icons.layers_rounded,
    color: Color(0xff3984e8),
    categoryId: kCategoryTrading,
  ),
  ToolDefinition(
    id: 'size',
    icon: Icons.calculate_rounded,
    color: Color(0xff26a269),
    categoryId: kCategoryTrading,
  ),
  ToolDefinition(
    id: 'dividend',
    icon: Icons.savings_rounded,
    color: Color(0xffe49a32),
    categoryId: kCategoryInvestment,
  ),
  ToolDefinition(
    id: 'allocation',
    icon: Icons.pie_chart_rounded,
    color: Color(0xff3a9d9a),
    categoryId: kCategoryInvestment,
  ),
  ToolDefinition(
    id: 'profit',
    icon: Icons.trending_up_rounded,
    color: Color(0xffef6b89),
    categoryId: kCategoryTrading,
  ),
  ToolDefinition(
    id: 'target',
    icon: Icons.flag_rounded,
    color: Color(0xff5d73d8),
    categoryId: kCategoryTrading,
  ),
  ToolDefinition(
    id: 'rate',
    icon: Icons.percent_rounded,
    color: Color(0xff9169d8),
    categoryId: kCategoryInvestment,
  ),
  ToolDefinition(
    id: 'time',
    icon: Icons.hourglass_bottom_rounded,
    color: Color(0xff2d9cdb),
    categoryId: kCategoryInvestment,
  ),
  ToolDefinition(
    id: 'roi',
    icon: Icons.insights_rounded,
    color: Color(0xffe15d35),
    categoryId: kCategoryInvestment,
  ),
];

ToolDefinition toolById(String id) {
  for (final tool in appTools) {
    if (tool.id == id) return tool;
  }
  return appTools.first;
}

/// Localized name of a calculator. Falls back to the raw id so an unknown tool
/// (for example a record saved by a newer build) still renders something.
String toolTitle(AppLocalizations l10n, String id) => switch (id) {
      'compound' => l10n.toolCompoundTitle,
      'risk' => l10n.toolRiskTitle,
      'position' => l10n.toolPositionTitle,
      'size' => l10n.toolSizeTitle,
      'dividend' => l10n.toolDividendTitle,
      'allocation' => l10n.toolAllocationTitle,
      'profit' => l10n.toolProfitTitle,
      'target' => l10n.toolTargetTitle,
      'rate' => l10n.toolRateTitle,
      'time' => l10n.toolTimeTitle,
      'roi' => l10n.toolRoiTitle,
      _ => id,
    };

String toolSubtitle(AppLocalizations l10n, String id) => switch (id) {
      'compound' => l10n.toolCompoundSubtitle,
      'risk' => l10n.toolRiskSubtitle,
      'position' => l10n.toolPositionSubtitle,
      'size' => l10n.toolSizeSubtitle,
      'dividend' => l10n.toolDividendSubtitle,
      'allocation' => l10n.toolAllocationSubtitle,
      'profit' => l10n.toolProfitSubtitle,
      'target' => l10n.toolTargetSubtitle,
      'rate' => l10n.toolRateSubtitle,
      'time' => l10n.toolTimeSubtitle,
      'roi' => l10n.toolRoiSubtitle,
      _ => '',
    };

String categoryTitle(AppLocalizations l10n, String categoryId) =>
    switch (categoryId) {
      kCategoryTrading => l10n.categoryTrading,
      kCategoryInvestment => l10n.categoryInvestment,
      _ => categoryId,
    };

String categoryHint(AppLocalizations l10n, String categoryId) =>
    switch (categoryId) {
      kCategoryTrading => l10n.categoryTradingHint,
      kCategoryInvestment => l10n.categoryInvestmentHint,
      _ => '',
    };
