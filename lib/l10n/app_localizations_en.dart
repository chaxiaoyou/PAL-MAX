// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navWatchlist => 'Watchlist';

  @override
  String get navCalculators => 'Calculators';

  @override
  String get navSaved => 'Saved';

  @override
  String get navPortfolio => 'Portfolio';

  @override
  String get navMarket => 'Market';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get portfolioTotalValue => 'Total value';

  @override
  String get portfolioToday => 'Today';

  @override
  String get portfolioUnrealized => 'Unrealized';

  @override
  String get portfolioRealized => 'Realized';

  @override
  String get portfolioInvested => 'Invested';

  @override
  String get portfolioAllocation => 'Allocation';

  @override
  String get portfolioPositions => 'Positions';

  @override
  String portfolioHoldingCount(int count) {
    return '$count positions';
  }

  @override
  String get portfolioEmptyTitle => 'No positions yet';

  @override
  String get portfolioEmptyBody =>
      'Record a buy to start tracking cost, P&L and allocation.';

  @override
  String get portfolioPartialData =>
      'Some holdings could not be priced — totals are partial.';

  @override
  String portfolioMissingSymbols(String symbols) {
    return 'No price for $symbols';
  }

  @override
  String get portfolioRefresh => 'Refresh quotes';

  @override
  String get portfolioAddTransaction => 'Add transaction';

  @override
  String get columnSymbol => 'Symbol';

  @override
  String get columnQuantity => 'Qty';

  @override
  String get columnAverageCost => 'Avg cost';

  @override
  String get columnPrice => 'Price';

  @override
  String get columnMarketValue => 'Value';

  @override
  String get columnPnl => 'P&L';

  @override
  String get columnWeight => 'Weight';

  @override
  String warningOversell(String symbol, String quantity) {
    return '$symbol: a sell exceeded your holding by $quantity';
  }

  @override
  String get alertsTitle => 'Price alerts';

  @override
  String get alertsEmptyTitle => 'No alerts yet';

  @override
  String get alertsEmptyBody =>
      'Create a rule and the app will tell you when the price crosses it.';

  @override
  String get alertAdd => 'New alert';

  @override
  String get alertKindPriceAbove => 'Price above';

  @override
  String get alertKindPriceBelow => 'Price below';

  @override
  String get alertKindPercentAbove => 'Day change above';

  @override
  String get alertKindPercentBelow => 'Day change below';

  @override
  String get alertSymbol => 'Symbol';

  @override
  String get alertThreshold => 'Threshold';

  @override
  String get alertStatusArmed => 'Armed';

  @override
  String get alertStatusPaused => 'Paused';

  @override
  String alertStatusTriggered(String time) {
    return 'Triggered $time';
  }

  @override
  String alertDistanceAhead(String distance) {
    return '$distance to go';
  }

  @override
  String get alertDistanceCrossed => 'Threshold crossed';

  @override
  String get alertNoPrice => 'Waiting for a price';

  @override
  String get alertReArm => 'Re-arm';

  @override
  String get alertDeleteTitle => 'Delete alert';

  @override
  String alertDeleteMessage(String symbol) {
    return 'Delete the alert for $symbol?';
  }

  @override
  String get alertNeedSymbol => 'Enter a symbol';

  @override
  String get alertNeedThreshold => 'Enter a valid threshold';

  @override
  String alertNotificationTitle(String symbol) {
    return '$symbol price alert';
  }

  @override
  String alertNotificationBody(String condition, String price) {
    return '$condition — last $price';
  }

  @override
  String get alertChannelName => 'Price alerts';

  @override
  String get alertChannelDescription =>
      'Tells you when one of your price rules is met.';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionSave => 'Save';

  @override
  String get actionSaveAs => 'Save As';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionAdded => 'Added';

  @override
  String get actionPin => 'Pin';

  @override
  String get actionUnpin => 'Unpin';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionLoad => 'Load';

  @override
  String get actionOptions => 'Options';

  @override
  String get resultPanelTitle => 'Results';

  @override
  String get disclaimerFooter => 'For reference only — not investment advice.';

  @override
  String get homeTitle => 'Markets';

  @override
  String get tooltipAddSymbols => 'Add symbols';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipRefreshNow => 'Refresh now';

  @override
  String get filterAll => 'All';

  @override
  String get filterGainers => 'Gainers';

  @override
  String get filterLosers => 'Losers';

  @override
  String get sectionMarketIndices => 'Market indices';

  @override
  String get sectionPinned => 'Pinned';

  @override
  String get watchlistTitle => 'Watchlist';

  @override
  String get statusUpdating => 'Updating…';

  @override
  String statusUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get errorQuotesFetchFailed =>
      'Unable to fetch quotes. Check your connection and try again.';

  @override
  String get removeSymbolTitle => 'Remove symbol';

  @override
  String removeSymbolMessage(String symbol) {
    return 'Remove $symbol from your watchlist?';
  }

  @override
  String get emptyWatchlistTitle => 'Your watchlist is empty';

  @override
  String get emptyOnlyIndices => 'Only indices so far — add a few stocks';

  @override
  String get emptyNoGainers => 'No gainers in the watchlist';

  @override
  String get emptyNoLosers => 'No losers in the watchlist';

  @override
  String get emptyBuildTitle => 'Build your watchlist';

  @override
  String get emptyBuildBody =>
      'Search a ticker or company name to start tracking live quotes.';

  @override
  String footerAutoRefresh(int minutes) {
    return 'Auto-refresh every $minutes min';
  }

  @override
  String footerNextFetch(String time) {
    return 'next $time';
  }

  @override
  String get footerNoFetchYet => 'no fetch yet';

  @override
  String get toolsTitle => 'Calculators';

  @override
  String get tooltipSearchCalculators => 'Search calculators';

  @override
  String get tooltipSavedResults => 'Saved results';

  @override
  String get searchHintCalculators =>
      'Search by name or what you want to work out';

  @override
  String get sectionStartHere => 'Start here';

  @override
  String get hintStarToPin => 'Star a tool to pin it';

  @override
  String get hintTapToUnpin => 'Tap ★ to unpin';

  @override
  String get sectionResults => 'Results';

  @override
  String noCalculatorMatches(String query) {
    return 'No calculator matches \"$query\"';
  }

  @override
  String resultsShownOfTotal(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String summaryCalculators(int total) {
    return '$total calculators';
  }

  @override
  String summaryStarterPicks(int pinned) {
    return '$pinned starter picks · everything runs on device';
  }

  @override
  String summaryPinned(int favorites) {
    return '$favorites pinned · everything runs on device';
  }

  @override
  String get categoryTrading => 'Trading';

  @override
  String get categoryTradingHint => 'Entries, exits and position sizing';

  @override
  String get categoryInvestment => 'Investment';

  @override
  String get categoryInvestmentHint => 'Compounding, allocation and returns';

  @override
  String get toolCompoundTitle => 'Compound Interest';

  @override
  String get toolCompoundSubtitle => 'See the power of compounding over time';

  @override
  String get toolRiskTitle => 'Risk / Reward';

  @override
  String get toolRiskSubtitle => 'Quickly judge whether a trade is worth it';

  @override
  String get toolPositionTitle => 'Position Cost';

  @override
  String get toolPositionSubtitle =>
      'Track average cost across multiple entries';

  @override
  String get toolSizeTitle => 'Position Size';

  @override
  String get toolSizeSubtitle => 'Derive position size from your max loss';

  @override
  String get toolDividendTitle => 'Dividend Reinvest';

  @override
  String get toolDividendSubtitle => 'Put cash dividends back to work';

  @override
  String get toolAllocationTitle => 'Asset Allocation';

  @override
  String get toolAllocationSubtitle => 'Build an allocation that fits you';

  @override
  String get toolProfitTitle => 'Profit & Loss';

  @override
  String get toolProfitSubtitle => 'See at a glance how much you made';

  @override
  String get toolTargetTitle => 'Target Price';

  @override
  String get toolTargetSubtitle => 'Work backward from a return target';

  @override
  String get toolRateTitle => 'Annual Return';

  @override
  String get toolRateSubtitle => 'Reverse-engineer the annualized return';

  @override
  String get toolTimeTitle => 'Time to Target';

  @override
  String get toolTimeSubtitle => 'How long until you reach your goal';

  @override
  String get toolRoiTitle => 'ROI Calculator';

  @override
  String get toolRoiSubtitle => 'Measure the real return on your investment';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get settingTheme => 'Theme';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingLanguage => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingAutoSort => 'Auto-sort by daily change';

  @override
  String get settingAutoSortSub => 'Sort watchlist by today’s percent change';

  @override
  String get sectionQuotes => 'Quotes';

  @override
  String get settingRefreshInterval => 'Refresh interval';

  @override
  String minutesCount(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get settingRoundPrices => 'Round prices to 2 decimals';

  @override
  String get sectionAbout => 'About';

  @override
  String get aboutDataSource => 'Data source';

  @override
  String get aboutDataSourceSub => 'Quotes & charts by Yahoo Finance';

  @override
  String get aboutCalculators => 'Calculators';

  @override
  String get aboutCalculatorsSub =>
      'Trading & investment math runs entirely on device';

  @override
  String get aboutDisclaimer => 'Disclaimer';

  @override
  String get aboutDisclaimerSub =>
      'For reference only — not investment advice.';

  @override
  String get historyTitle => 'Saved results';

  @override
  String get historyEmptyTitle => 'No saved results yet';

  @override
  String get historyEmptyBody => 'Save any calculation to keep it here.';

  @override
  String historyNote(String note) {
    return 'Note: $note';
  }

  @override
  String get historyInputs => 'Inputs';

  @override
  String get historyResults => 'Results';

  @override
  String get historyDeleteTitle => 'Delete result';

  @override
  String historyDeleteMessage(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String get searchTitle => 'Add symbols';

  @override
  String get searchHint => 'Search symbol or company (e.g. AAPL)';

  @override
  String get searchTrending => 'Trending';

  @override
  String get searchTrendingFailed => 'Unable to load trending symbols';

  @override
  String get searchNoResults => 'No symbols found';

  @override
  String get searchFailed => 'Search failed. Please try again.';

  @override
  String searchAlreadyInWatchlist(String symbol) {
    return '$symbol is already in your watchlist';
  }

  @override
  String searchAddedToWatchlist(String symbol) {
    return '$symbol added to watchlist';
  }

  @override
  String get detailRemoveFromWatchlist => 'Remove from watchlist';

  @override
  String get detailAddToWatchlist => 'Add to watchlist';

  @override
  String get detailRefreshQuote => 'Refresh quote';

  @override
  String detailRemovedFromWatchlist(String symbol) {
    return '$symbol removed from watchlist';
  }

  @override
  String detailAddedToWatchlist(String symbol) {
    return '$symbol added to watchlist';
  }

  @override
  String get detailChartFailed => 'Unable to load chart data.';

  @override
  String get detailRefreshFailed => 'Unable to refresh quote';

  @override
  String get marketOpen => 'Market open';

  @override
  String get marketPreMarket => 'Pre-market';

  @override
  String get marketAfterHours => 'After hours';

  @override
  String get marketClosed => 'Market closed';

  @override
  String get detailKeyStatistics => 'Key statistics';

  @override
  String get statOpen => 'Open';

  @override
  String get statPreviousClose => 'Previous close';

  @override
  String get statDayRange => 'Day range';

  @override
  String get statVolume => 'Volume';

  @override
  String get statMarketCap => 'Market cap';

  @override
  String get statPeRatio => 'P/E ratio';

  @override
  String get stat52WeekRange => '52-week range';

  @override
  String get stat50DayAvg => '50-day avg.';

  @override
  String get stat200DayAvg => '200-day avg.';

  @override
  String get detailRelatedNews => 'Related news';

  @override
  String get detailNoNews => 'No news available';

  @override
  String get detailOpenArticleFailed => 'Unable to open the article';

  @override
  String get chartRangeMax => 'Max';

  @override
  String get chartNotEnoughData => 'Not enough chart data';

  @override
  String calcLoaded(String title) {
    return 'Loaded: $title';
  }

  @override
  String recordSavedAs(String title) {
    return 'Saved as \"$title\"';
  }

  @override
  String recordSaved(String title) {
    return 'Saved \"$title\"';
  }

  @override
  String get dialogSaveAsRecord => 'Save As Record';

  @override
  String get dialogSaveRecord => 'Save Record';

  @override
  String get fieldRecordName => 'Record name';

  @override
  String get fieldRecordNameHint => 'e.g. 2026 plan';

  @override
  String get fieldRecordNote => 'Note (optional)';

  @override
  String get errorRecordNameRequired => 'Please enter a record name';

  @override
  String get fieldPrincipal => 'Principal';

  @override
  String get fieldTargetAmount => 'Target Amount';

  @override
  String get fieldInitialPrincipal => 'Initial Principal';

  @override
  String get fieldPeriodicContribution => 'Periodic Contribution';

  @override
  String get fieldFrequency => 'Frequency';

  @override
  String get segmentMonthly => 'Monthly';

  @override
  String get segmentYearly => 'Yearly';

  @override
  String get fieldAnnualRate => 'Annual Rate';

  @override
  String get fieldTerm => 'Term';

  @override
  String get suffixYears => 'years';

  @override
  String quickRate(String rate) {
    return 'Rate $rate%';
  }

  @override
  String quickTermYears(String term) {
    return '${term}y';
  }

  @override
  String get resultTotalBalance => 'Total Balance';

  @override
  String get resultTotalInterest => 'Total Interest';

  @override
  String get resultTotalReturn => 'Total Return';

  @override
  String get resultTotalInvested => 'Total Invested';

  @override
  String get resultYearlyBreakdown => 'Yearly Breakdown';

  @override
  String get tableYear => 'Year';

  @override
  String get tablePrincipal => 'Principal';

  @override
  String get tableInterest => 'Interest';

  @override
  String get tableYearRate => 'Year Rate';

  @override
  String get tableBalance => 'Balance';

  @override
  String yearLabel(int year) {
    return 'Year $year';
  }

  @override
  String get sectionTradeSetup => 'Trade Setup';

  @override
  String get segmentLong => 'Long';

  @override
  String get segmentShort => 'Short';

  @override
  String get segmentSpot => 'Spot';

  @override
  String get segmentFutures => 'Futures';

  @override
  String get fieldEntryPrice => 'Entry Price';

  @override
  String get fieldStopPrice => 'Stop Price';

  @override
  String get fieldTargetPrice => 'Target Price';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get suffixUnits => 'units';

  @override
  String get fieldContractMultiplier => 'Contract Multiplier';

  @override
  String get suffixPerPoint => '/ point';

  @override
  String get fieldMargin => 'Margin';

  @override
  String get fieldQuickStop => 'Quick Stop %';

  @override
  String labelStopPct(String pct) {
    return 'Stop $pct%';
  }

  @override
  String get fieldQuickRr => 'Quick R/R';

  @override
  String labelRrRatio(String ratio) {
    return 'R/R 1:$ratio';
  }

  @override
  String get resultRiskReward => 'Risk / Reward';

  @override
  String get resultTargetProfit => 'Target Profit';

  @override
  String get resultExpectedLoss => 'Expected Loss';

  @override
  String get resultMarginRequired => 'Margin Required';

  @override
  String get resultReturnOnMargin => 'Return on Margin';

  @override
  String get sectionPositionSetup => 'Position Setup';

  @override
  String get fieldMaxLoss => 'Max Loss';

  @override
  String get resultMaxQuantity => 'Max Quantity';

  @override
  String get resultPositionValue => 'Position Value';

  @override
  String get resultStopDistance => 'Stop Distance';

  @override
  String get sectionTradeParameters => 'Trade Parameters';

  @override
  String get fieldExitPrice => 'Exit Price';

  @override
  String get fieldFeeRate => 'Fee Rate (optional)';

  @override
  String get resultPnl => 'P&L';

  @override
  String get resultReturn => 'Return';

  @override
  String get resultFees => 'Fees';

  @override
  String get sectionAddReduceRecords => 'Add / Reduce Records';

  @override
  String recordsCount(int count) {
    return '$count records';
  }

  @override
  String get actionAddRecord => 'Add Record';

  @override
  String get actionReduce => 'Reduce';

  @override
  String get resultTotalPositionValue => 'Total Position Value';

  @override
  String get resultTotalQuantity => 'Total Quantity';

  @override
  String get resultAverageCost => 'Average Cost';

  @override
  String get tableRecordDetails => 'Record Details';

  @override
  String get tableDate => 'Date';

  @override
  String get tableSide => 'Side';

  @override
  String get tablePrice => 'Price';

  @override
  String get tableQty => 'Qty';

  @override
  String get tableAmount => 'Amount';

  @override
  String get fieldPrice => 'Price';

  @override
  String get fieldQty => 'Qty';

  @override
  String get fieldAssetPrice => 'Asset Price';

  @override
  String get fieldDividendPerShare => 'Dividend per Share';

  @override
  String get fieldSharesHeld => 'Shares Held';

  @override
  String get suffixShares => 'shares';

  @override
  String get resultDividendYield => 'Dividend Yield';

  @override
  String get resultTotalDividend => 'Total Dividend';

  @override
  String get resultReinvestShares => 'Reinvest Shares';

  @override
  String get resultTotalSharesAfter => 'Total Shares After';

  @override
  String get sectionTotalAssets => 'Total Assets';

  @override
  String get sectionAllocations => 'Allocations';

  @override
  String itemsCount(int count) {
    return '$count items';
  }

  @override
  String get actionAddAsset => 'Add Asset';

  @override
  String get fieldAssetName => 'Asset name';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldPercent => 'Percent';

  @override
  String get resultAllocatedAmount => 'Allocated Amount';

  @override
  String get resultAllocatedPct => 'Allocated %';

  @override
  String get resultRemaining => 'Remaining';

  @override
  String get resultPctDifference => '% Difference';

  @override
  String allocationRemainingHint(String amount) {
    return '$amount not yet allocated';
  }

  @override
  String allocationExceedsHint(String amount) {
    return 'Allocation exceeds total assets by $amount';
  }

  @override
  String allocationNotFullHint(String pct) {
    return 'Allocation is not 100% (missing $pct)';
  }

  @override
  String get segmentLongUpside => 'Long · Upside';

  @override
  String get segmentShortDownside => 'Short · Downside';

  @override
  String get fieldCurrentPrice => 'Current Price';

  @override
  String get fieldExpectedReturn => 'Expected Return';

  @override
  String get fieldQuickReturn => 'Quick Return';

  @override
  String quickReturnPct(String rate) {
    return '$rate%';
  }

  @override
  String get resultTargetPrice => 'Target Price';

  @override
  String get resultExpectedChange => 'Expected Change';

  @override
  String get resultYearsNeeded => 'Years Needed';

  @override
  String get resultApprox => 'Approx.';

  @override
  String yearsCount(String years) {
    return '$years years';
  }

  @override
  String yearsMonthsCount(int years, int months) {
    return '$years years $months months';
  }

  @override
  String get resultAnnualizedReturn => 'Annualized Return';

  @override
  String get fieldInvestedCost => 'Invested Cost';

  @override
  String get segmentReturnAmount => 'Return Amount';

  @override
  String get segmentFinalValue => 'Final Value';

  @override
  String get resultRoi => 'ROI';

  @override
  String get resultNetProfit => 'Net Profit';

  @override
  String get errorUnableToFetchQuotes => 'Unable to fetch quotes';

  @override
  String get errorSymbolNotFound => 'Symbol not found';

  @override
  String get errorNoChartData => 'No chart data available';
}
