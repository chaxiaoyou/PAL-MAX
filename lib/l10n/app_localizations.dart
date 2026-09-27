import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
  ];

  /// No description provided for @navWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get navWatchlist;

  /// No description provided for @navCalculators.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get navCalculators;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get navPortfolio;

  /// No description provided for @navMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get navMarket;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTitle;

  /// No description provided for @portfolioTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get portfolioTotalValue;

  /// No description provided for @portfolioToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get portfolioToday;

  /// No description provided for @portfolioUnrealized.
  ///
  /// In en, this message translates to:
  /// **'Unrealized'**
  String get portfolioUnrealized;

  /// No description provided for @portfolioRealized.
  ///
  /// In en, this message translates to:
  /// **'Realized'**
  String get portfolioRealized;

  /// No description provided for @portfolioInvested.
  ///
  /// In en, this message translates to:
  /// **'Invested'**
  String get portfolioInvested;

  /// No description provided for @portfolioAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get portfolioAllocation;

  /// No description provided for @portfolioPositions.
  ///
  /// In en, this message translates to:
  /// **'Positions'**
  String get portfolioPositions;

  /// No description provided for @portfolioHoldingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} positions'**
  String portfolioHoldingCount(int count);

  /// No description provided for @portfolioEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No positions yet'**
  String get portfolioEmptyTitle;

  /// No description provided for @portfolioEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Record a buy to start tracking cost, P&L and allocation.'**
  String get portfolioEmptyBody;

  /// No description provided for @portfolioPartialData.
  ///
  /// In en, this message translates to:
  /// **'Some holdings could not be priced — totals are partial.'**
  String get portfolioPartialData;

  /// No description provided for @portfolioMissingSymbols.
  ///
  /// In en, this message translates to:
  /// **'No price for {symbols}'**
  String portfolioMissingSymbols(String symbols);

  /// No description provided for @portfolioRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh quotes'**
  String get portfolioRefresh;

  /// No description provided for @portfolioAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get portfolioAddTransaction;

  /// No description provided for @columnSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get columnSymbol;

  /// No description provided for @columnQuantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get columnQuantity;

  /// No description provided for @columnAverageCost.
  ///
  /// In en, this message translates to:
  /// **'Avg cost'**
  String get columnAverageCost;

  /// No description provided for @columnPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get columnPrice;

  /// No description provided for @columnMarketValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get columnMarketValue;

  /// No description provided for @columnPnl.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get columnPnl;

  /// No description provided for @columnWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get columnWeight;

  /// No description provided for @warningOversell.
  ///
  /// In en, this message translates to:
  /// **'{symbol}: a sell exceeded your holding by {quantity}'**
  String warningOversell(String symbol, String quantity);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get alertsTitle;

  /// No description provided for @alertsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No alerts yet'**
  String get alertsEmptyTitle;

  /// No description provided for @alertsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create a rule and the app will tell you when the price crosses it.'**
  String get alertsEmptyBody;

  /// No description provided for @alertAdd.
  ///
  /// In en, this message translates to:
  /// **'New alert'**
  String get alertAdd;

  /// No description provided for @alertKindPriceAbove.
  ///
  /// In en, this message translates to:
  /// **'Price above'**
  String get alertKindPriceAbove;

  /// No description provided for @alertKindPriceBelow.
  ///
  /// In en, this message translates to:
  /// **'Price below'**
  String get alertKindPriceBelow;

  /// No description provided for @alertKindPercentAbove.
  ///
  /// In en, this message translates to:
  /// **'Day change above'**
  String get alertKindPercentAbove;

  /// No description provided for @alertKindPercentBelow.
  ///
  /// In en, this message translates to:
  /// **'Day change below'**
  String get alertKindPercentBelow;

  /// No description provided for @alertSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get alertSymbol;

  /// No description provided for @alertThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get alertThreshold;

  /// No description provided for @alertStatusArmed.
  ///
  /// In en, this message translates to:
  /// **'Armed'**
  String get alertStatusArmed;

  /// No description provided for @alertStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get alertStatusPaused;

  /// No description provided for @alertStatusTriggered.
  ///
  /// In en, this message translates to:
  /// **'Triggered {time}'**
  String alertStatusTriggered(String time);

  /// No description provided for @alertDistanceAhead.
  ///
  /// In en, this message translates to:
  /// **'{distance} to go'**
  String alertDistanceAhead(String distance);

  /// No description provided for @alertDistanceCrossed.
  ///
  /// In en, this message translates to:
  /// **'Threshold crossed'**
  String get alertDistanceCrossed;

  /// No description provided for @alertNoPrice.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a price'**
  String get alertNoPrice;

  /// No description provided for @alertReArm.
  ///
  /// In en, this message translates to:
  /// **'Re-arm'**
  String get alertReArm;

  /// No description provided for @alertDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete alert'**
  String get alertDeleteTitle;

  /// No description provided for @alertDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete the alert for {symbol}?'**
  String alertDeleteMessage(String symbol);

  /// No description provided for @alertNeedSymbol.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol'**
  String get alertNeedSymbol;

  /// No description provided for @alertNeedThreshold.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid threshold'**
  String get alertNeedThreshold;

  /// No description provided for @alertNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'{symbol} price alert'**
  String alertNotificationTitle(String symbol);

  /// No description provided for @alertNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{condition} — last {price}'**
  String alertNotificationBody(String condition, String price);

  /// No description provided for @alertChannelName.
  ///
  /// In en, this message translates to:
  /// **'Price alerts'**
  String get alertChannelName;

  /// No description provided for @alertChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Tells you when one of your price rules is met.'**
  String get alertChannelDescription;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionSaveAs.
  ///
  /// In en, this message translates to:
  /// **'Save As'**
  String get actionSaveAs;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionAdded.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get actionAdded;

  /// No description provided for @actionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get actionPin;

  /// No description provided for @actionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get actionUnpin;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionLoad.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get actionLoad;

  /// No description provided for @actionOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get actionOptions;

  /// No description provided for @resultPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get resultPanelTitle;

  /// No description provided for @disclaimerFooter.
  ///
  /// In en, this message translates to:
  /// **'For reference only — not investment advice.'**
  String get disclaimerFooter;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Markets'**
  String get homeTitle;

  /// No description provided for @tooltipAddSymbols.
  ///
  /// In en, this message translates to:
  /// **'Add symbols'**
  String get tooltipAddSymbols;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipRefreshNow.
  ///
  /// In en, this message translates to:
  /// **'Refresh now'**
  String get tooltipRefreshNow;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterGainers.
  ///
  /// In en, this message translates to:
  /// **'Gainers'**
  String get filterGainers;

  /// No description provided for @filterLosers.
  ///
  /// In en, this message translates to:
  /// **'Losers'**
  String get filterLosers;

  /// No description provided for @sectionMarketIndices.
  ///
  /// In en, this message translates to:
  /// **'Market indices'**
  String get sectionMarketIndices;

  /// No description provided for @sectionPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get sectionPinned;

  /// No description provided for @watchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Watchlist'**
  String get watchlistTitle;

  /// No description provided for @statusUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get statusUpdating;

  /// No description provided for @statusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String statusUpdated(String time);

  /// No description provided for @errorQuotesFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch quotes. Check your connection and try again.'**
  String get errorQuotesFetchFailed;

  /// No description provided for @removeSymbolTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove symbol'**
  String get removeSymbolTitle;

  /// No description provided for @removeSymbolMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {symbol} from your watchlist?'**
  String removeSymbolMessage(String symbol);

  /// No description provided for @emptyWatchlistTitle.
  ///
  /// In en, this message translates to:
  /// **'Your watchlist is empty'**
  String get emptyWatchlistTitle;

  /// No description provided for @emptyOnlyIndices.
  ///
  /// In en, this message translates to:
  /// **'Only indices so far — add a few stocks'**
  String get emptyOnlyIndices;

  /// No description provided for @emptyNoGainers.
  ///
  /// In en, this message translates to:
  /// **'No gainers in the watchlist'**
  String get emptyNoGainers;

  /// No description provided for @emptyNoLosers.
  ///
  /// In en, this message translates to:
  /// **'No losers in the watchlist'**
  String get emptyNoLosers;

  /// No description provided for @emptyBuildTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your watchlist'**
  String get emptyBuildTitle;

  /// No description provided for @emptyBuildBody.
  ///
  /// In en, this message translates to:
  /// **'Search a ticker or company name to start tracking live quotes.'**
  String get emptyBuildBody;

  /// No description provided for @footerAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh every {minutes} min'**
  String footerAutoRefresh(int minutes);

  /// No description provided for @footerNextFetch.
  ///
  /// In en, this message translates to:
  /// **'next {time}'**
  String footerNextFetch(String time);

  /// No description provided for @footerNoFetchYet.
  ///
  /// In en, this message translates to:
  /// **'no fetch yet'**
  String get footerNoFetchYet;

  /// No description provided for @toolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get toolsTitle;

  /// No description provided for @tooltipSearchCalculators.
  ///
  /// In en, this message translates to:
  /// **'Search calculators'**
  String get tooltipSearchCalculators;

  /// No description provided for @tooltipSavedResults.
  ///
  /// In en, this message translates to:
  /// **'Saved results'**
  String get tooltipSavedResults;

  /// No description provided for @searchHintCalculators.
  ///
  /// In en, this message translates to:
  /// **'Search by name or what you want to work out'**
  String get searchHintCalculators;

  /// No description provided for @sectionStartHere.
  ///
  /// In en, this message translates to:
  /// **'Start here'**
  String get sectionStartHere;

  /// No description provided for @hintStarToPin.
  ///
  /// In en, this message translates to:
  /// **'Star a tool to pin it'**
  String get hintStarToPin;

  /// No description provided for @hintTapToUnpin.
  ///
  /// In en, this message translates to:
  /// **'Tap ★ to unpin'**
  String get hintTapToUnpin;

  /// No description provided for @sectionResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get sectionResults;

  /// No description provided for @noCalculatorMatches.
  ///
  /// In en, this message translates to:
  /// **'No calculator matches \"{query}\"'**
  String noCalculatorMatches(String query);

  /// No description provided for @resultsShownOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String resultsShownOfTotal(int shown, int total);

  /// No description provided for @summaryCalculators.
  ///
  /// In en, this message translates to:
  /// **'{total} calculators'**
  String summaryCalculators(int total);

  /// No description provided for @summaryStarterPicks.
  ///
  /// In en, this message translates to:
  /// **'{pinned} starter picks · everything runs on device'**
  String summaryStarterPicks(int pinned);

  /// No description provided for @summaryPinned.
  ///
  /// In en, this message translates to:
  /// **'{favorites} pinned · everything runs on device'**
  String summaryPinned(int favorites);

  /// No description provided for @categoryTrading.
  ///
  /// In en, this message translates to:
  /// **'Trading'**
  String get categoryTrading;

  /// No description provided for @categoryTradingHint.
  ///
  /// In en, this message translates to:
  /// **'Entries, exits and position sizing'**
  String get categoryTradingHint;

  /// No description provided for @categoryInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get categoryInvestment;

  /// No description provided for @categoryInvestmentHint.
  ///
  /// In en, this message translates to:
  /// **'Compounding, allocation and returns'**
  String get categoryInvestmentHint;

  /// No description provided for @toolCompoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Compound Interest'**
  String get toolCompoundTitle;

  /// No description provided for @toolCompoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the power of compounding over time'**
  String get toolCompoundSubtitle;

  /// No description provided for @toolRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Risk / Reward'**
  String get toolRiskTitle;

  /// No description provided for @toolRiskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quickly judge whether a trade is worth it'**
  String get toolRiskSubtitle;

  /// No description provided for @toolPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Position Cost'**
  String get toolPositionTitle;

  /// No description provided for @toolPositionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track average cost across multiple entries'**
  String get toolPositionSubtitle;

  /// No description provided for @toolSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Position Size'**
  String get toolSizeTitle;

  /// No description provided for @toolSizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Derive position size from your max loss'**
  String get toolSizeSubtitle;

  /// No description provided for @toolDividendTitle.
  ///
  /// In en, this message translates to:
  /// **'Dividend Reinvest'**
  String get toolDividendTitle;

  /// No description provided for @toolDividendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Put cash dividends back to work'**
  String get toolDividendSubtitle;

  /// No description provided for @toolAllocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Asset Allocation'**
  String get toolAllocationTitle;

  /// No description provided for @toolAllocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build an allocation that fits you'**
  String get toolAllocationSubtitle;

  /// No description provided for @toolProfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get toolProfitTitle;

  /// No description provided for @toolProfitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See at a glance how much you made'**
  String get toolProfitSubtitle;

  /// No description provided for @toolTargetTitle.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get toolTargetTitle;

  /// No description provided for @toolTargetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work backward from a return target'**
  String get toolTargetSubtitle;

  /// No description provided for @toolRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual Return'**
  String get toolRateTitle;

  /// No description provided for @toolRateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reverse-engineer the annualized return'**
  String get toolRateSubtitle;

  /// No description provided for @toolTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to Target'**
  String get toolTimeTitle;

  /// No description provided for @toolTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How long until you reach your goal'**
  String get toolTimeSubtitle;

  /// No description provided for @toolRoiTitle.
  ///
  /// In en, this message translates to:
  /// **'ROI Calculator'**
  String get toolRoiTitle;

  /// No description provided for @toolRoiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Measure the real return on your investment'**
  String get toolRoiSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @settingTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageJapanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get languageJapanese;

  /// No description provided for @settingAutoSort.
  ///
  /// In en, this message translates to:
  /// **'Auto-sort by daily change'**
  String get settingAutoSort;

  /// No description provided for @settingAutoSortSub.
  ///
  /// In en, this message translates to:
  /// **'Sort watchlist by today’s percent change'**
  String get settingAutoSortSub;

  /// No description provided for @sectionQuotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get sectionQuotes;

  /// No description provided for @settingRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Refresh interval'**
  String get settingRefreshInterval;

  /// No description provided for @minutesCount.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes'**
  String minutesCount(int minutes);

  /// No description provided for @settingRoundPrices.
  ///
  /// In en, this message translates to:
  /// **'Round prices to 2 decimals'**
  String get settingRoundPrices;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @aboutDataSource.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get aboutDataSource;

  /// No description provided for @aboutDataSourceSub.
  ///
  /// In en, this message translates to:
  /// **'Quotes & charts by Yahoo Finance'**
  String get aboutDataSourceSub;

  /// No description provided for @aboutCalculators.
  ///
  /// In en, this message translates to:
  /// **'Calculators'**
  String get aboutCalculators;

  /// No description provided for @aboutCalculatorsSub.
  ///
  /// In en, this message translates to:
  /// **'Trading & investment math runs entirely on device'**
  String get aboutCalculatorsSub;

  /// No description provided for @aboutDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get aboutDisclaimer;

  /// No description provided for @aboutDisclaimerSub.
  ///
  /// In en, this message translates to:
  /// **'For reference only — not investment advice.'**
  String get aboutDisclaimerSub;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved results'**
  String get historyTitle;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved results yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Save any calculation to keep it here.'**
  String get historyEmptyBody;

  /// No description provided for @historyNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String historyNote(String note);

  /// No description provided for @historyInputs.
  ///
  /// In en, this message translates to:
  /// **'Inputs'**
  String get historyInputs;

  /// No description provided for @historyResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get historyResults;

  /// No description provided for @historyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete result'**
  String get historyDeleteTitle;

  /// No description provided for @historyDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This cannot be undone.'**
  String historyDeleteMessage(String title);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Add symbols'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search symbol or company (e.g. AAPL)'**
  String get searchHint;

  /// No description provided for @searchTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get searchTrending;

  /// No description provided for @searchTrendingFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load trending symbols'**
  String get searchTrendingFailed;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No symbols found'**
  String get searchNoResults;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Please try again.'**
  String get searchFailed;

  /// No description provided for @searchAlreadyInWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{symbol} is already in your watchlist'**
  String searchAlreadyInWatchlist(String symbol);

  /// No description provided for @searchAddedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{symbol} added to watchlist'**
  String searchAddedToWatchlist(String symbol);

  /// No description provided for @detailRemoveFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Remove from watchlist'**
  String get detailRemoveFromWatchlist;

  /// No description provided for @detailAddToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'Add to watchlist'**
  String get detailAddToWatchlist;

  /// No description provided for @detailRefreshQuote.
  ///
  /// In en, this message translates to:
  /// **'Refresh quote'**
  String get detailRefreshQuote;

  /// No description provided for @detailRemovedFromWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{symbol} removed from watchlist'**
  String detailRemovedFromWatchlist(String symbol);

  /// No description provided for @detailAddedToWatchlist.
  ///
  /// In en, this message translates to:
  /// **'{symbol} added to watchlist'**
  String detailAddedToWatchlist(String symbol);

  /// No description provided for @detailChartFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load chart data.'**
  String get detailChartFailed;

  /// No description provided for @detailRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh quote'**
  String get detailRefreshFailed;

  /// No description provided for @marketOpen.
  ///
  /// In en, this message translates to:
  /// **'Market open'**
  String get marketOpen;

  /// No description provided for @marketPreMarket.
  ///
  /// In en, this message translates to:
  /// **'Pre-market'**
  String get marketPreMarket;

  /// No description provided for @marketAfterHours.
  ///
  /// In en, this message translates to:
  /// **'After hours'**
  String get marketAfterHours;

  /// No description provided for @marketClosed.
  ///
  /// In en, this message translates to:
  /// **'Market closed'**
  String get marketClosed;

  /// No description provided for @detailKeyStatistics.
  ///
  /// In en, this message translates to:
  /// **'Key statistics'**
  String get detailKeyStatistics;

  /// No description provided for @statOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statOpen;

  /// No description provided for @statPreviousClose.
  ///
  /// In en, this message translates to:
  /// **'Previous close'**
  String get statPreviousClose;

  /// No description provided for @statDayRange.
  ///
  /// In en, this message translates to:
  /// **'Day range'**
  String get statDayRange;

  /// No description provided for @statVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get statVolume;

  /// No description provided for @statMarketCap.
  ///
  /// In en, this message translates to:
  /// **'Market cap'**
  String get statMarketCap;

  /// No description provided for @statPeRatio.
  ///
  /// In en, this message translates to:
  /// **'P/E ratio'**
  String get statPeRatio;

  /// No description provided for @stat52WeekRange.
  ///
  /// In en, this message translates to:
  /// **'52-week range'**
  String get stat52WeekRange;

  /// No description provided for @stat50DayAvg.
  ///
  /// In en, this message translates to:
  /// **'50-day avg.'**
  String get stat50DayAvg;

  /// No description provided for @stat200DayAvg.
  ///
  /// In en, this message translates to:
  /// **'200-day avg.'**
  String get stat200DayAvg;

  /// No description provided for @detailRelatedNews.
  ///
  /// In en, this message translates to:
  /// **'Related news'**
  String get detailRelatedNews;

  /// No description provided for @detailNoNews.
  ///
  /// In en, this message translates to:
  /// **'No news available'**
  String get detailNoNews;

  /// No description provided for @detailOpenArticleFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to open the article'**
  String get detailOpenArticleFailed;

  /// No description provided for @chartRangeMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get chartRangeMax;

  /// No description provided for @chartNotEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough chart data'**
  String get chartNotEnoughData;

  /// No description provided for @calcLoaded.
  ///
  /// In en, this message translates to:
  /// **'Loaded: {title}'**
  String calcLoaded(String title);

  /// No description provided for @recordSavedAs.
  ///
  /// In en, this message translates to:
  /// **'Saved as \"{title}\"'**
  String recordSavedAs(String title);

  /// No description provided for @recordSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved \"{title}\"'**
  String recordSaved(String title);

  /// No description provided for @dialogSaveAsRecord.
  ///
  /// In en, this message translates to:
  /// **'Save As Record'**
  String get dialogSaveAsRecord;

  /// No description provided for @dialogSaveRecord.
  ///
  /// In en, this message translates to:
  /// **'Save Record'**
  String get dialogSaveRecord;

  /// No description provided for @fieldRecordName.
  ///
  /// In en, this message translates to:
  /// **'Record name'**
  String get fieldRecordName;

  /// No description provided for @fieldRecordNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2026 plan'**
  String get fieldRecordNameHint;

  /// No description provided for @fieldRecordNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fieldRecordNote;

  /// No description provided for @errorRecordNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a record name'**
  String get errorRecordNameRequired;

  /// No description provided for @fieldPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get fieldPrincipal;

  /// No description provided for @fieldTargetAmount.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get fieldTargetAmount;

  /// No description provided for @fieldInitialPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Initial Principal'**
  String get fieldInitialPrincipal;

  /// No description provided for @fieldPeriodicContribution.
  ///
  /// In en, this message translates to:
  /// **'Periodic Contribution'**
  String get fieldPeriodicContribution;

  /// No description provided for @fieldFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get fieldFrequency;

  /// No description provided for @segmentMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get segmentMonthly;

  /// No description provided for @segmentYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get segmentYearly;

  /// No description provided for @fieldAnnualRate.
  ///
  /// In en, this message translates to:
  /// **'Annual Rate'**
  String get fieldAnnualRate;

  /// No description provided for @fieldTerm.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get fieldTerm;

  /// No description provided for @suffixYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get suffixYears;

  /// No description provided for @quickRate.
  ///
  /// In en, this message translates to:
  /// **'Rate {rate}%'**
  String quickRate(String rate);

  /// No description provided for @quickTermYears.
  ///
  /// In en, this message translates to:
  /// **'{term}y'**
  String quickTermYears(String term);

  /// No description provided for @resultTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get resultTotalBalance;

  /// No description provided for @resultTotalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest'**
  String get resultTotalInterest;

  /// No description provided for @resultTotalReturn.
  ///
  /// In en, this message translates to:
  /// **'Total Return'**
  String get resultTotalReturn;

  /// No description provided for @resultTotalInvested.
  ///
  /// In en, this message translates to:
  /// **'Total Invested'**
  String get resultTotalInvested;

  /// No description provided for @resultYearlyBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Yearly Breakdown'**
  String get resultYearlyBreakdown;

  /// No description provided for @tableYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get tableYear;

  /// No description provided for @tablePrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal'**
  String get tablePrincipal;

  /// No description provided for @tableInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get tableInterest;

  /// No description provided for @tableYearRate.
  ///
  /// In en, this message translates to:
  /// **'Year Rate'**
  String get tableYearRate;

  /// No description provided for @tableBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get tableBalance;

  /// No description provided for @yearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year {year}'**
  String yearLabel(int year);

  /// No description provided for @sectionTradeSetup.
  ///
  /// In en, this message translates to:
  /// **'Trade Setup'**
  String get sectionTradeSetup;

  /// No description provided for @segmentLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get segmentLong;

  /// No description provided for @segmentShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get segmentShort;

  /// No description provided for @segmentSpot.
  ///
  /// In en, this message translates to:
  /// **'Spot'**
  String get segmentSpot;

  /// No description provided for @segmentFutures.
  ///
  /// In en, this message translates to:
  /// **'Futures'**
  String get segmentFutures;

  /// No description provided for @fieldEntryPrice.
  ///
  /// In en, this message translates to:
  /// **'Entry Price'**
  String get fieldEntryPrice;

  /// No description provided for @fieldStopPrice.
  ///
  /// In en, this message translates to:
  /// **'Stop Price'**
  String get fieldStopPrice;

  /// No description provided for @fieldTargetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get fieldTargetPrice;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @suffixUnits.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get suffixUnits;

  /// No description provided for @fieldContractMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Contract Multiplier'**
  String get fieldContractMultiplier;

  /// No description provided for @suffixPerPoint.
  ///
  /// In en, this message translates to:
  /// **'/ point'**
  String get suffixPerPoint;

  /// No description provided for @fieldMargin.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get fieldMargin;

  /// No description provided for @fieldQuickStop.
  ///
  /// In en, this message translates to:
  /// **'Quick Stop %'**
  String get fieldQuickStop;

  /// No description provided for @labelStopPct.
  ///
  /// In en, this message translates to:
  /// **'Stop {pct}%'**
  String labelStopPct(String pct);

  /// No description provided for @fieldQuickRr.
  ///
  /// In en, this message translates to:
  /// **'Quick R/R'**
  String get fieldQuickRr;

  /// No description provided for @labelRrRatio.
  ///
  /// In en, this message translates to:
  /// **'R/R 1:{ratio}'**
  String labelRrRatio(String ratio);

  /// No description provided for @resultRiskReward.
  ///
  /// In en, this message translates to:
  /// **'Risk / Reward'**
  String get resultRiskReward;

  /// No description provided for @resultTargetProfit.
  ///
  /// In en, this message translates to:
  /// **'Target Profit'**
  String get resultTargetProfit;

  /// No description provided for @resultExpectedLoss.
  ///
  /// In en, this message translates to:
  /// **'Expected Loss'**
  String get resultExpectedLoss;

  /// No description provided for @resultMarginRequired.
  ///
  /// In en, this message translates to:
  /// **'Margin Required'**
  String get resultMarginRequired;

  /// No description provided for @resultReturnOnMargin.
  ///
  /// In en, this message translates to:
  /// **'Return on Margin'**
  String get resultReturnOnMargin;

  /// No description provided for @sectionPositionSetup.
  ///
  /// In en, this message translates to:
  /// **'Position Setup'**
  String get sectionPositionSetup;

  /// No description provided for @fieldMaxLoss.
  ///
  /// In en, this message translates to:
  /// **'Max Loss'**
  String get fieldMaxLoss;

  /// No description provided for @resultMaxQuantity.
  ///
  /// In en, this message translates to:
  /// **'Max Quantity'**
  String get resultMaxQuantity;

  /// No description provided for @resultPositionValue.
  ///
  /// In en, this message translates to:
  /// **'Position Value'**
  String get resultPositionValue;

  /// No description provided for @resultStopDistance.
  ///
  /// In en, this message translates to:
  /// **'Stop Distance'**
  String get resultStopDistance;

  /// No description provided for @sectionTradeParameters.
  ///
  /// In en, this message translates to:
  /// **'Trade Parameters'**
  String get sectionTradeParameters;

  /// No description provided for @fieldExitPrice.
  ///
  /// In en, this message translates to:
  /// **'Exit Price'**
  String get fieldExitPrice;

  /// No description provided for @fieldFeeRate.
  ///
  /// In en, this message translates to:
  /// **'Fee Rate (optional)'**
  String get fieldFeeRate;

  /// No description provided for @resultPnl.
  ///
  /// In en, this message translates to:
  /// **'P&L'**
  String get resultPnl;

  /// No description provided for @resultReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get resultReturn;

  /// No description provided for @resultFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get resultFees;

  /// No description provided for @sectionAddReduceRecords.
  ///
  /// In en, this message translates to:
  /// **'Add / Reduce Records'**
  String get sectionAddReduceRecords;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// No description provided for @actionAddRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get actionAddRecord;

  /// No description provided for @actionReduce.
  ///
  /// In en, this message translates to:
  /// **'Reduce'**
  String get actionReduce;

  /// No description provided for @resultTotalPositionValue.
  ///
  /// In en, this message translates to:
  /// **'Total Position Value'**
  String get resultTotalPositionValue;

  /// No description provided for @resultTotalQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get resultTotalQuantity;

  /// No description provided for @resultAverageCost.
  ///
  /// In en, this message translates to:
  /// **'Average Cost'**
  String get resultAverageCost;

  /// No description provided for @tableRecordDetails.
  ///
  /// In en, this message translates to:
  /// **'Record Details'**
  String get tableRecordDetails;

  /// No description provided for @tableDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get tableDate;

  /// No description provided for @tableSide.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get tableSide;

  /// No description provided for @tablePrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get tablePrice;

  /// No description provided for @tableQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get tableQty;

  /// No description provided for @tableAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get tableAmount;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get fieldPrice;

  /// No description provided for @fieldQty.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get fieldQty;

  /// No description provided for @fieldAssetPrice.
  ///
  /// In en, this message translates to:
  /// **'Asset Price'**
  String get fieldAssetPrice;

  /// No description provided for @fieldDividendPerShare.
  ///
  /// In en, this message translates to:
  /// **'Dividend per Share'**
  String get fieldDividendPerShare;

  /// No description provided for @fieldSharesHeld.
  ///
  /// In en, this message translates to:
  /// **'Shares Held'**
  String get fieldSharesHeld;

  /// No description provided for @suffixShares.
  ///
  /// In en, this message translates to:
  /// **'shares'**
  String get suffixShares;

  /// No description provided for @resultDividendYield.
  ///
  /// In en, this message translates to:
  /// **'Dividend Yield'**
  String get resultDividendYield;

  /// No description provided for @resultTotalDividend.
  ///
  /// In en, this message translates to:
  /// **'Total Dividend'**
  String get resultTotalDividend;

  /// No description provided for @resultReinvestShares.
  ///
  /// In en, this message translates to:
  /// **'Reinvest Shares'**
  String get resultReinvestShares;

  /// No description provided for @resultTotalSharesAfter.
  ///
  /// In en, this message translates to:
  /// **'Total Shares After'**
  String get resultTotalSharesAfter;

  /// No description provided for @sectionTotalAssets.
  ///
  /// In en, this message translates to:
  /// **'Total Assets'**
  String get sectionTotalAssets;

  /// No description provided for @sectionAllocations.
  ///
  /// In en, this message translates to:
  /// **'Allocations'**
  String get sectionAllocations;

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemsCount(int count);

  /// No description provided for @actionAddAsset.
  ///
  /// In en, this message translates to:
  /// **'Add Asset'**
  String get actionAddAsset;

  /// No description provided for @fieldAssetName.
  ///
  /// In en, this message translates to:
  /// **'Asset name'**
  String get fieldAssetName;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldPercent.
  ///
  /// In en, this message translates to:
  /// **'Percent'**
  String get fieldPercent;

  /// No description provided for @resultAllocatedAmount.
  ///
  /// In en, this message translates to:
  /// **'Allocated Amount'**
  String get resultAllocatedAmount;

  /// No description provided for @resultAllocatedPct.
  ///
  /// In en, this message translates to:
  /// **'Allocated %'**
  String get resultAllocatedPct;

  /// No description provided for @resultRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get resultRemaining;

  /// No description provided for @resultPctDifference.
  ///
  /// In en, this message translates to:
  /// **'% Difference'**
  String get resultPctDifference;

  /// No description provided for @allocationRemainingHint.
  ///
  /// In en, this message translates to:
  /// **'{amount} not yet allocated'**
  String allocationRemainingHint(String amount);

  /// No description provided for @allocationExceedsHint.
  ///
  /// In en, this message translates to:
  /// **'Allocation exceeds total assets by {amount}'**
  String allocationExceedsHint(String amount);

  /// No description provided for @allocationNotFullHint.
  ///
  /// In en, this message translates to:
  /// **'Allocation is not 100% (missing {pct})'**
  String allocationNotFullHint(String pct);

  /// No description provided for @segmentLongUpside.
  ///
  /// In en, this message translates to:
  /// **'Long · Upside'**
  String get segmentLongUpside;

  /// No description provided for @segmentShortDownside.
  ///
  /// In en, this message translates to:
  /// **'Short · Downside'**
  String get segmentShortDownside;

  /// No description provided for @fieldCurrentPrice.
  ///
  /// In en, this message translates to:
  /// **'Current Price'**
  String get fieldCurrentPrice;

  /// No description provided for @fieldExpectedReturn.
  ///
  /// In en, this message translates to:
  /// **'Expected Return'**
  String get fieldExpectedReturn;

  /// No description provided for @fieldQuickReturn.
  ///
  /// In en, this message translates to:
  /// **'Quick Return'**
  String get fieldQuickReturn;

  /// No description provided for @quickReturnPct.
  ///
  /// In en, this message translates to:
  /// **'{rate}%'**
  String quickReturnPct(String rate);

  /// No description provided for @resultTargetPrice.
  ///
  /// In en, this message translates to:
  /// **'Target Price'**
  String get resultTargetPrice;

  /// No description provided for @resultExpectedChange.
  ///
  /// In en, this message translates to:
  /// **'Expected Change'**
  String get resultExpectedChange;

  /// No description provided for @resultYearsNeeded.
  ///
  /// In en, this message translates to:
  /// **'Years Needed'**
  String get resultYearsNeeded;

  /// No description provided for @resultApprox.
  ///
  /// In en, this message translates to:
  /// **'Approx.'**
  String get resultApprox;

  /// No description provided for @yearsCount.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String yearsCount(String years);

  /// No description provided for @yearsMonthsCount.
  ///
  /// In en, this message translates to:
  /// **'{years} years {months} months'**
  String yearsMonthsCount(int years, int months);

  /// No description provided for @resultAnnualizedReturn.
  ///
  /// In en, this message translates to:
  /// **'Annualized Return'**
  String get resultAnnualizedReturn;

  /// No description provided for @fieldInvestedCost.
  ///
  /// In en, this message translates to:
  /// **'Invested Cost'**
  String get fieldInvestedCost;

  /// No description provided for @segmentReturnAmount.
  ///
  /// In en, this message translates to:
  /// **'Return Amount'**
  String get segmentReturnAmount;

  /// No description provided for @segmentFinalValue.
  ///
  /// In en, this message translates to:
  /// **'Final Value'**
  String get segmentFinalValue;

  /// No description provided for @resultRoi.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get resultRoi;

  /// No description provided for @resultNetProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get resultNetProfit;

  /// No description provided for @errorUnableToFetchQuotes.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch quotes'**
  String get errorUnableToFetchQuotes;

  /// No description provided for @errorSymbolNotFound.
  ///
  /// In en, this message translates to:
  /// **'Symbol not found'**
  String get errorSymbolNotFound;

  /// No description provided for @errorNoChartData.
  ///
  /// In en, this message translates to:
  /// **'No chart data available'**
  String get errorNoChartData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
