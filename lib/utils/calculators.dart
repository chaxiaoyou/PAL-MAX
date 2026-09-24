import 'dart:math' as math;

// ---------- 1. Compound interest ----------

class CompoundYearRow {
  const CompoundYearRow({
    required this.year,
    required this.contributed,
    required this.interest,
    required this.yearRate,
    required this.endTotal,
  });

  final int year;
  final double contributed;
  final double interest;
  final double yearRate;
  final double endTotal;
}

class CompoundResult {
  const CompoundResult({
    required this.total,
    required this.totalInvested,
    required this.totalInterest,
    required this.totalReturnRate,
    required this.rows,
  });

  final double total;
  final double totalInvested;
  final double totalInterest;
  final double totalReturnRate;
  final List<CompoundYearRow> rows;
}

CompoundResult calcCompound({
  required double principal,
  required double contribution,
  required bool monthly,
  required double annualRatePct,
  required double years,
}) {
  final n = years.floor();
  final rows = <CompoundYearRow>[];
  if (n <= 0) {
    return CompoundResult(
      total: principal,
      totalInvested: principal,
      totalInterest: 0,
      totalReturnRate: 0,
      rows: rows,
    );
  }

  var balance = principal;
  if (monthly) {
    final monthlyRate = annualRatePct / 100 / 12;
    for (var year = 1; year <= n; year++) {
      final yearStart = balance;
      var contributed = 0.0;
      var interest = 0.0;
      for (var m = 0; m < 12; m++) {
        final monthInterest = balance * monthlyRate;
        interest += monthInterest;
        balance += monthInterest;
        if (contribution > 0) {
          balance += contribution;
          contributed += contribution;
        }
      }
      rows.add(CompoundYearRow(
        year: year,
        contributed: contributed,
        interest: interest,
        yearRate: yearStart > 0 ? interest / yearStart * 100 : 0,
        endTotal: balance,
      ));
    }
  } else {
    final rate = annualRatePct / 100;
    for (var year = 1; year <= n; year++) {
      final yearStart = balance;
      final yearInterest = balance * rate;
      balance += yearInterest;
      final contributed = contribution > 0 ? contribution : 0.0;
      balance += contributed;
      rows.add(CompoundYearRow(
        year: year,
        contributed: contributed,
        interest: yearInterest,
        yearRate: yearStart > 0 ? yearInterest / yearStart * 100 : 0,
        endTotal: balance,
      ));
    }
  }

  final totalInvested =
      principal + (monthly ? contribution * n * 12 : contribution * n);
  final total = rows.last.endTotal;
  final totalInterest = total - totalInvested;
  final totalReturnRate =
      totalInvested > 0 ? totalInterest / totalInvested * 100 : 0.0;
  return CompoundResult(
    total: total,
    totalInvested: totalInvested,
    totalInterest: totalInterest,
    totalReturnRate: totalReturnRate,
    rows: rows,
  );
}

// ---------- 2. Risk / reward ----------

class RiskRewardResult {
  const RiskRewardResult({
    required this.ratio,
    required this.targetProfit,
    required this.expectedLoss,
    this.marginRequired,
    this.returnOnMargin,
  });

  final double ratio;
  final double targetProfit;
  final double expectedLoss;
  final double? marginRequired;
  final double? returnOnMargin;
}

RiskRewardResult calcRiskReward({
  required bool isLong,
  required bool futures,
  required double entry,
  required double stop,
  required double target,
  required double qty,
  required double multiplier,
  required double marginPct,
}) {
  final riskPerUnit = isLong ? entry - stop : stop - entry;
  final rewardPerUnit = isLong ? target - entry : entry - target;
  final ratio =
      riskPerUnit > 0 && rewardPerUnit > 0 ? rewardPerUnit / riskPerUnit : 0.0;
  final targetProfit = rewardPerUnit * qty * multiplier;
  final expectedLoss = riskPerUnit > 0 ? riskPerUnit * qty * multiplier : 0.0;

  double? marginRequired;
  double? returnOnMargin;
  if (futures && marginPct > 0) {
    marginRequired = entry * qty * multiplier * marginPct / 100;
    returnOnMargin =
        marginRequired > 0 ? targetProfit / marginRequired * 100 : 0.0;
  }
  return RiskRewardResult(
    ratio: ratio,
    targetProfit: targetProfit,
    expectedLoss: expectedLoss,
    marginRequired: marginRequired,
    returnOnMargin: returnOnMargin,
  );
}

// ---------- 3. Position cost ----------

class PositionRecord {
  const PositionRecord({
    required this.date,
    required this.isBuy,
    required this.price,
    required this.qty,
  });

  final DateTime date;
  final bool isBuy;
  final double price;
  final double qty;
}

class PositionCostResult {
  const PositionCostResult({
    required this.totalAmount,
    required this.totalQty,
    required this.avgCost,
  });

  final double totalAmount;
  final double totalQty;
  final double avgCost;
}

PositionCostResult calcPositionCost(List<PositionRecord> records) {
  var amount = 0.0;
  var qty = 0.0;
  for (final r in records) {
    if (r.price <= 0 || r.qty <= 0) continue;
    if (r.isBuy) {
      amount += r.price * r.qty;
      qty += r.qty;
    } else {
      final sellQty = math.min(r.qty, qty);
      final avg = qty > 0 ? amount / qty : 0.0;
      amount -= avg * sellQty;
      qty -= sellQty;
    }
  }
  return PositionCostResult(
    totalAmount: amount,
    totalQty: qty,
    avgCost: qty > 0 ? amount / qty : 0,
  );
}

// ---------- 4. Position size ----------

class PositionSizeResult {
  const PositionSizeResult({
    required this.maxQty,
    required this.totalValue,
    required this.movePct,
  });

  final double maxQty;
  final double totalValue;
  final double movePct;
}

PositionSizeResult calcPositionSize({
  required double entry,
  required double stop,
  required double maxLoss,
}) {
  final diff = (entry - stop).abs();
  final maxQty = diff > 0 ? maxLoss / diff : 0.0;
  return PositionSizeResult(
    maxQty: maxQty,
    totalValue: entry * maxQty,
    movePct: entry > 0 ? diff / entry * 100 : 0,
  );
}

// ---------- 5. Dividend reinvestment ----------

class DividendResult {
  const DividendResult({
    required this.yieldPct,
    required this.totalDividend,
    required this.extraShares,
    required this.totalShares,
  });

  final double yieldPct;
  final double totalDividend;
  final double extraShares;
  final double totalShares;
}

DividendResult calcDividend({
  required double price,
  required double dividendPerShare,
  required double shares,
}) {
  final yieldPct = price > 0 ? dividendPerShare / price * 100 : 0.0;
  final totalDividend = dividendPerShare * shares;
  final extraShares = price > 0 ? totalDividend / price : 0.0;
  return DividendResult(
    yieldPct: yieldPct,
    totalDividend: totalDividend,
    extraShares: extraShares,
    totalShares: shares + extraShares,
  );
}

// ---------- 7. Profit & loss ----------

class PnlResult {
  const PnlResult({
    required this.amount,
    required this.returnPct,
    required this.fee,
  });

  final double amount;
  final double returnPct;
  final double fee;
}

PnlResult calcPnl({
  required bool isLong,
  required double entry,
  required double exit,
  required double qty,
  required double feePct,
}) {
  final perUnit = isLong ? exit - entry : entry - exit;
  final gross = perUnit * qty;
  final fee = (entry * qty + exit * qty) * feePct / 100;
  final amount = gross - fee;
  final cost = entry * qty;
  return PnlResult(
    amount: amount,
    returnPct: cost > 0 ? amount / cost * 100 : 0,
    fee: fee,
  );
}

// ---------- 8. Target price ----------

class TargetPriceResult {
  const TargetPriceResult({required this.target, required this.change});

  final double target;
  final double change;
}

TargetPriceResult calcTargetPrice({
  required bool isLong,
  required double price,
  required double ratePct,
}) {
  final target = isLong ? price * (1 + ratePct / 100) : price * (1 - ratePct / 100);
  return TargetPriceResult(target: target, change: target - price);
}

// ---------- 9. Annual return ----------

class AnnualReturnResult {
  const AnnualReturnResult({
    required this.totalReturnPct,
    required this.annualizedPct,
  });

  final double totalReturnPct;
  final double annualizedPct;
}

AnnualReturnResult calcAnnualReturn({
  required double principal,
  required double target,
  required double years,
}) {
  final totalReturnPct =
      principal > 0 ? (target / principal - 1) * 100 : 0.0;
  final annualizedPct = principal > 0 && years > 0 && target > 0
      ? (math.pow(target / principal, 1 / years).toDouble() - 1) * 100
      : 0.0;
  return AnnualReturnResult(
    totalReturnPct: totalReturnPct,
    annualizedPct: annualizedPct,
  );
}

// ---------- 10. Time to target ----------

class SavingsTimeResult {
  const SavingsTimeResult({
    required this.years,
    required this.yearInt,
    required this.monthInt,
  });

  final double years;
  final int yearInt;
  final int monthInt;
}

SavingsTimeResult calcSavingsTime({
  required double principal,
  required double target,
  required double annualRatePct,
}) {
  if (principal <= 0 || target <= principal || annualRatePct <= 0) {
    return const SavingsTimeResult(years: 0, yearInt: 0, monthInt: 0);
  }
  final years = math.log(target / principal) / math.log(1 + annualRatePct / 100);
  final yearInt = years.floor();
  final monthInt = ((years - yearInt) * 12).round();
  return SavingsTimeResult(
    years: years,
    yearInt: yearInt,
    monthInt: monthInt,
  );
}

// ---------- 11. ROI ----------

class RoiResult {
  const RoiResult({required this.returnPct, required this.profit});

  final double returnPct;
  final double profit;
}

RoiResult calcRoi({
  required bool incomeMode,
  required double cost,
  required double amount,
}) {
  final profit = incomeMode ? amount : amount - cost;
  return RoiResult(
    returnPct: cost > 0 ? profit / cost * 100 : 0,
    profit: profit,
  );
}
