import 'package:flutter/material.dart';

import '../models/tool_definition.dart';

const appTools = <ToolDefinition>[
  ToolDefinition(
    id: 'compound',
    title: 'Compound Interest',
    subtitle: 'See the power of compounding over time',
    icon: Icons.auto_graph_rounded,
    color: Color(0xff7657e8),
    category: 'Investment',
  ),
  ToolDefinition(
    id: 'risk',
    title: 'Risk / Reward',
    subtitle: 'Quickly judge whether a trade is worth it',
    icon: Icons.balance_rounded,
    color: Color(0xffed6a5a),
    category: 'Trading',
  ),
  ToolDefinition(
    id: 'position',
    title: 'Position Cost',
    subtitle: 'Track average cost across multiple entries',
    icon: Icons.layers_rounded,
    color: Color(0xff3984e8),
    category: 'Trading',
  ),
  ToolDefinition(
    id: 'size',
    title: 'Position Size',
    subtitle: 'Derive position size from your max loss',
    icon: Icons.calculate_rounded,
    color: Color(0xff26a269),
    category: 'Trading',
  ),
  ToolDefinition(
    id: 'dividend',
    title: 'Dividend Reinvest',
    subtitle: 'Put cash dividends back to work',
    icon: Icons.savings_rounded,
    color: Color(0xffe49a32),
    category: 'Investment',
  ),
  ToolDefinition(
    id: 'allocation',
    title: 'Asset Allocation',
    subtitle: 'Build an allocation that fits you',
    icon: Icons.pie_chart_rounded,
    color: Color(0xff3a9d9a),
    category: 'Investment',
  ),
  ToolDefinition(
    id: 'profit',
    title: 'Profit & Loss',
    subtitle: 'See at a glance how much you made',
    icon: Icons.trending_up_rounded,
    color: Color(0xffef6b89),
    category: 'Trading',
  ),
  ToolDefinition(
    id: 'target',
    title: 'Target Price',
    subtitle: 'Work backward from a return target',
    icon: Icons.flag_rounded,
    color: Color(0xff5d73d8),
    category: 'Trading',
  ),
  ToolDefinition(
    id: 'rate',
    title: 'Annual Return',
    subtitle: 'Reverse-engineer the annualized return',
    icon: Icons.percent_rounded,
    color: Color(0xff9169d8),
    category: 'Investment',
  ),
  ToolDefinition(
    id: 'time',
    title: 'Time to Target',
    subtitle: 'How long until you reach your goal',
    icon: Icons.hourglass_bottom_rounded,
    color: Color(0xff2d9cdb),
    category: 'Investment',
  ),
  ToolDefinition(
    id: 'roi',
    title: 'ROI Calculator',
    subtitle: 'Measure the real return on your investment',
    icon: Icons.insights_rounded,
    color: Color(0xffe15d35),
    category: 'Investment',
  ),
];

ToolDefinition toolById(String id) =>
    appTools.firstWhere((tool) => tool.id == id);
