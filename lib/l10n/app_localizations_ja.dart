// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navWatchlist => 'ウォッチリスト';

  @override
  String get navCalculators => '計算ツール';

  @override
  String get navSaved => '保存済み';

  @override
  String get navPortfolio => 'ポートフォリオ';

  @override
  String get navMarket => 'マーケット';

  @override
  String get navAlerts => 'アラート';

  @override
  String get portfolioTitle => 'ポートフォリオ';

  @override
  String get portfolioTotalValue => '評価額合計';

  @override
  String get portfolioToday => '前日比';

  @override
  String get portfolioUnrealized => '含み損益';

  @override
  String get portfolioRealized => '実現損益';

  @override
  String get portfolioInvested => '投資額';

  @override
  String get portfolioAllocation => '構成比';

  @override
  String get portfolioPositions => '保有銘柄';

  @override
  String portfolioHoldingCount(int count) {
    return '$count 銘柄';
  }

  @override
  String get portfolioEmptyTitle => '保有銘柄がありません';

  @override
  String get portfolioEmptyBody => '買付を登録すると、取得単価・損益・構成比を追跡できます。';

  @override
  String get portfolioPartialData => '一部の銘柄の価格を取得できないため、合計は不完全です。';

  @override
  String portfolioMissingSymbols(String symbols) {
    return '$symbols の価格を取得できません';
  }

  @override
  String get portfolioRefresh => '価格を更新';

  @override
  String get portfolioAddTransaction => '取引を追加';

  @override
  String get columnSymbol => '銘柄';

  @override
  String get columnQuantity => '数量';

  @override
  String get columnAverageCost => '取得単価';

  @override
  String get columnPrice => '現在値';

  @override
  String get columnMarketValue => '評価額';

  @override
  String get columnPnl => '損益';

  @override
  String get columnWeight => '比率';

  @override
  String warningOversell(String symbol, String quantity) {
    return '$symbol: 売却数量が保有数量を $quantity 上回っています';
  }

  @override
  String get alertsTitle => '価格アラート';

  @override
  String get alertsEmptyTitle => 'アラートはまだありません';

  @override
  String get alertsEmptyBody => '条件を登録すると、価格が条件に達したときに通知します。';

  @override
  String get alertAdd => 'アラートを作成';

  @override
  String get alertKindPriceAbove => '価格が以上';

  @override
  String get alertKindPriceBelow => '価格が以下';

  @override
  String get alertKindPercentAbove => '前日比が上回る';

  @override
  String get alertKindPercentBelow => '前日比が下回る';

  @override
  String get alertSymbol => '銘柄';

  @override
  String get alertThreshold => 'しきい値';

  @override
  String get alertStatusArmed => '待機中';

  @override
  String get alertStatusPaused => '停止中';

  @override
  String alertStatusTriggered(String time) {
    return '$time に到達';
  }

  @override
  String alertDistanceAhead(String distance) {
    return 'あと $distance';
  }

  @override
  String get alertDistanceCrossed => 'しきい値に到達';

  @override
  String get alertNoPrice => '価格を待っています';

  @override
  String get alertReArm => '再設定';

  @override
  String get alertDeleteTitle => 'アラートを削除';

  @override
  String alertDeleteMessage(String symbol) {
    return '$symbol のアラートを削除しますか？';
  }

  @override
  String get alertNeedSymbol => '銘柄を入力してください';

  @override
  String get alertNeedThreshold => '有効なしきい値を入力してください';

  @override
  String alertNotificationTitle(String symbol) {
    return '$symbol の価格アラート';
  }

  @override
  String alertNotificationBody(String condition, String price) {
    return '$condition — 現在値 $price';
  }

  @override
  String get alertChannelName => '価格アラート';

  @override
  String get alertChannelDescription => '設定した価格条件に達したときに通知します。';

  @override
  String get actionCancel => 'キャンセル';

  @override
  String get actionRemove => '削除';

  @override
  String get actionDelete => '削除';

  @override
  String get actionRetry => '再試行';

  @override
  String get actionSave => '保存';

  @override
  String get actionSaveAs => '別名で保存';

  @override
  String get actionAdd => '追加';

  @override
  String get actionAdded => '追加済み';

  @override
  String get actionPin => 'ピン留め';

  @override
  String get actionUnpin => 'ピン解除';

  @override
  String get actionClear => 'クリア';

  @override
  String get actionLoad => '読み込み';

  @override
  String get actionOptions => 'オプション';

  @override
  String get resultPanelTitle => '結果';

  @override
  String get disclaimerFooter => '参考情報です — 投資助言ではありません。';

  @override
  String get homeTitle => 'マーケット';

  @override
  String get tooltipAddSymbols => '銘柄を追加';

  @override
  String get tooltipSettings => '設定';

  @override
  String get tooltipRefreshNow => '今すぐ更新';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterGainers => '上昇';

  @override
  String get filterLosers => '下落';

  @override
  String get sectionMarketIndices => '市場指数';

  @override
  String get sectionPinned => 'ピン留め';

  @override
  String get watchlistTitle => 'ウォッチリスト';

  @override
  String get statusUpdating => '更新中…';

  @override
  String statusUpdated(String time) {
    return '$time 更新';
  }

  @override
  String get errorQuotesFetchFailed => '株価を取得できませんでした。接続を確認して、もう一度お試しください。';

  @override
  String get removeSymbolTitle => '銘柄を削除';

  @override
  String removeSymbolMessage(String symbol) {
    return '$symbol をウォッチリストから削除しますか？';
  }

  @override
  String get emptyWatchlistTitle => 'ウォッチリストは空です';

  @override
  String get emptyOnlyIndices => '指数のみです — 銘柄を追加してください';

  @override
  String get emptyNoGainers => '上昇した銘柄はありません';

  @override
  String get emptyNoLosers => '下落した銘柄はありません';

  @override
  String get emptyBuildTitle => 'ウォッチリストを作成';

  @override
  String get emptyBuildBody => 'ティッカーまたは企業名を検索して、リアルタイム株価を追跡しましょう。';

  @override
  String footerAutoRefresh(int minutes) {
    return '$minutes 分ごとに自動更新';
  }

  @override
  String footerNextFetch(String time) {
    return '次回 $time';
  }

  @override
  String get footerNoFetchYet => '未取得';

  @override
  String get toolsTitle => '計算ツール';

  @override
  String get tooltipSearchCalculators => '計算ツールを検索';

  @override
  String get tooltipSavedResults => '保存した結果';

  @override
  String get searchHintCalculators => '名前や計算したい内容で検索';

  @override
  String get sectionStartHere => 'まずはこちら';

  @override
  String get hintStarToPin => '★ をタップするとピン留めできます';

  @override
  String get hintTapToUnpin => '★ をタップでピン解除';

  @override
  String get sectionResults => '検索結果';

  @override
  String noCalculatorMatches(String query) {
    return '「$query」に一致する計算ツールはありません';
  }

  @override
  String resultsShownOfTotal(int shown, int total) {
    return '$total 件中 $shown 件';
  }

  @override
  String summaryCalculators(int total) {
    return '$total 個の計算ツール';
  }

  @override
  String summaryStarterPicks(int pinned) {
    return 'おすすめ $pinned 件 · すべて端末内で計算';
  }

  @override
  String summaryPinned(int favorites) {
    return 'ピン留め $favorites 件 · すべて端末内で計算';
  }

  @override
  String get categoryTrading => 'トレード';

  @override
  String get categoryTradingHint => 'エントリー・決済・建玉サイズ';

  @override
  String get categoryInvestment => '投資';

  @override
  String get categoryInvestmentHint => '複利・資産配分・リターン';

  @override
  String get toolCompoundTitle => '複利計算';

  @override
  String get toolCompoundSubtitle => '複利効果を時間軸で確認';

  @override
  String get toolRiskTitle => 'リスク・リワード';

  @override
  String get toolRiskSubtitle => 'その取引が割に合うか素早く判断';

  @override
  String get toolPositionTitle => '取得単価';

  @override
  String get toolPositionSubtitle => '複数回の買付から平均単価を算出';

  @override
  String get toolSizeTitle => '建玉サイズ';

  @override
  String get toolSizeSubtitle => '許容損失から数量を逆算';

  @override
  String get toolDividendTitle => '配当再投資';

  @override
  String get toolDividendSubtitle => '配当金を再投資に回す';

  @override
  String get toolAllocationTitle => '資産配分';

  @override
  String get toolAllocationSubtitle => '自分に合った配分を設計';

  @override
  String get toolProfitTitle => '損益計算';

  @override
  String get toolProfitSubtitle => '損益をひと目で確認';

  @override
  String get toolTargetTitle => '目標株価';

  @override
  String get toolTargetSubtitle => '目標リターンから株価を逆算';

  @override
  String get toolRateTitle => '年率リターン';

  @override
  String get toolRateSubtitle => '年率換算のリターンを算出';

  @override
  String get toolTimeTitle => '目標までの期間';

  @override
  String get toolTimeSubtitle => '目標達成までどれくらいかかるか';

  @override
  String get toolRoiTitle => 'ROI 計算';

  @override
  String get toolRoiSubtitle => '投資の実質リターンを測定';

  @override
  String get settingsTitle => '設定';

  @override
  String get sectionAppearance => '表示';

  @override
  String get settingTheme => 'テーマ';

  @override
  String get themeSystem => 'システムに合わせる';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get settingLanguage => '言語';

  @override
  String get languageSystem => 'システムに合わせる';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingAutoSort => '前日比で並べ替え';

  @override
  String get settingAutoSortSub => 'ウォッチリストを本日の変化率で並べ替えます';

  @override
  String get sectionQuotes => '株価';

  @override
  String get settingRefreshInterval => '更新間隔';

  @override
  String minutesCount(int minutes) {
    return '$minutes 分';
  }

  @override
  String get settingRoundPrices => '価格を小数点以下2桁に丸める';

  @override
  String get sectionAbout => 'このアプリについて';

  @override
  String get aboutDataSource => 'データ提供';

  @override
  String get aboutDataSourceSub => '株価・チャート: Yahoo Finance';

  @override
  String get aboutCalculators => '計算ツール';

  @override
  String get aboutCalculatorsSub => '計算はすべて端末内で実行されます';

  @override
  String get aboutDisclaimer => '免責事項';

  @override
  String get aboutDisclaimerSub => '参考情報です — 投資助言ではありません。';

  @override
  String get historyTitle => '保存した結果';

  @override
  String get historyEmptyTitle => '保存された結果はありません';

  @override
  String get historyEmptyBody => '計算結果を保存すると、ここに表示されます。';

  @override
  String historyNote(String note) {
    return 'メモ: $note';
  }

  @override
  String get historyInputs => '入力';

  @override
  String get historyResults => '結果';

  @override
  String get historyDeleteTitle => '結果を削除';

  @override
  String historyDeleteMessage(String title) {
    return '「$title」を削除しますか？元に戻せません。';
  }

  @override
  String get searchTitle => '銘柄を追加';

  @override
  String get searchHint => '銘柄または企業名で検索（例: AAPL）';

  @override
  String get searchTrending => '人気銘柄';

  @override
  String get searchTrendingFailed => '人気銘柄を読み込めませんでした';

  @override
  String get searchNoResults => '銘柄が見つかりません';

  @override
  String get searchFailed => '検索に失敗しました。もう一度お試しください。';

  @override
  String searchAlreadyInWatchlist(String symbol) {
    return '$symbol はすでにウォッチリストにあります';
  }

  @override
  String searchAddedToWatchlist(String symbol) {
    return '$symbol をウォッチリストに追加しました';
  }

  @override
  String get detailRemoveFromWatchlist => 'ウォッチリストから削除';

  @override
  String get detailAddToWatchlist => 'ウォッチリストに追加';

  @override
  String get detailRefreshQuote => '株価を更新';

  @override
  String detailRemovedFromWatchlist(String symbol) {
    return '$symbol をウォッチリストから削除しました';
  }

  @override
  String detailAddedToWatchlist(String symbol) {
    return '$symbol をウォッチリストに追加しました';
  }

  @override
  String get detailChartFailed => 'チャートを読み込めませんでした。';

  @override
  String get detailRefreshFailed => '株価を更新できませんでした';

  @override
  String get marketOpen => '取引中';

  @override
  String get marketPreMarket => 'プレマーケット';

  @override
  String get marketAfterHours => 'アフターマーケット';

  @override
  String get marketClosed => '取引時間外';

  @override
  String get detailKeyStatistics => '主要指標';

  @override
  String get statOpen => '始値';

  @override
  String get statPreviousClose => '前日終値';

  @override
  String get statDayRange => '当日レンジ';

  @override
  String get statVolume => '出来高';

  @override
  String get statMarketCap => '時価総額';

  @override
  String get statPeRatio => 'PER';

  @override
  String get stat52WeekRange => '52週レンジ';

  @override
  String get stat50DayAvg => '50日平均';

  @override
  String get stat200DayAvg => '200日平均';

  @override
  String get detailRelatedNews => '関連ニュース';

  @override
  String get detailNoNews => 'ニュースはありません';

  @override
  String get detailOpenArticleFailed => '記事を開けませんでした';

  @override
  String get chartRangeMax => '全期間';

  @override
  String get chartNotEnoughData => 'チャートのデータが不足しています';

  @override
  String calcLoaded(String title) {
    return '読み込み済み: $title';
  }

  @override
  String recordSavedAs(String title) {
    return '「$title」として保存しました';
  }

  @override
  String recordSaved(String title) {
    return '「$title」を保存しました';
  }

  @override
  String get dialogSaveAsRecord => '別名で保存';

  @override
  String get dialogSaveRecord => '計算結果を保存';

  @override
  String get fieldRecordName => '記録名';

  @override
  String get fieldRecordNameHint => '例: 2026年プラン';

  @override
  String get fieldRecordNote => 'メモ（任意）';

  @override
  String get errorRecordNameRequired => '記録名を入力してください';

  @override
  String get fieldPrincipal => '元本';

  @override
  String get fieldTargetAmount => '目標金額';

  @override
  String get fieldInitialPrincipal => '初期元本';

  @override
  String get fieldPeriodicContribution => '定期積立額';

  @override
  String get fieldFrequency => '頻度';

  @override
  String get segmentMonthly => '毎月';

  @override
  String get segmentYearly => '毎年';

  @override
  String get fieldAnnualRate => '年率';

  @override
  String get fieldTerm => '期間';

  @override
  String get suffixYears => '年';

  @override
  String quickRate(String rate) {
    return '年率 $rate%';
  }

  @override
  String quickTermYears(String term) {
    return '$term年';
  }

  @override
  String get resultTotalBalance => '最終残高';

  @override
  String get resultTotalInterest => '利息合計';

  @override
  String get resultTotalReturn => 'トータルリターン';

  @override
  String get resultTotalInvested => '投資元本合計';

  @override
  String get resultYearlyBreakdown => '年次内訳';

  @override
  String get tableYear => '年';

  @override
  String get tablePrincipal => '元本';

  @override
  String get tableInterest => '利息';

  @override
  String get tableYearRate => '年率';

  @override
  String get tableBalance => '残高';

  @override
  String yearLabel(int year) {
    return '$year 年';
  }

  @override
  String get sectionTradeSetup => '取引条件';

  @override
  String get segmentLong => 'ロング';

  @override
  String get segmentShort => 'ショート';

  @override
  String get segmentSpot => '現物';

  @override
  String get segmentFutures => '先物';

  @override
  String get fieldEntryPrice => 'エントリー価格';

  @override
  String get fieldStopPrice => '損切価格';

  @override
  String get fieldTargetPrice => '目標価格';

  @override
  String get fieldQuantity => '数量';

  @override
  String get suffixUnits => '単位';

  @override
  String get fieldContractMultiplier => '契約乗数';

  @override
  String get suffixPerPoint => '/ ポイント';

  @override
  String get fieldMargin => '証拠金';

  @override
  String get fieldQuickStop => 'クイック損切 %';

  @override
  String labelStopPct(String pct) {
    return '損切 $pct%';
  }

  @override
  String get fieldQuickRr => 'クイック R/R';

  @override
  String labelRrRatio(String ratio) {
    return 'R/R 1:$ratio';
  }

  @override
  String get resultRiskReward => 'リスク・リワード';

  @override
  String get resultTargetProfit => '目標利益';

  @override
  String get resultExpectedLoss => '想定損失';

  @override
  String get resultMarginRequired => '必要証拠金';

  @override
  String get resultReturnOnMargin => '証拠金利益率';

  @override
  String get sectionPositionSetup => 'ポジション設定';

  @override
  String get fieldMaxLoss => '許容損失';

  @override
  String get resultMaxQuantity => '最大数量';

  @override
  String get resultPositionValue => '建玉金額';

  @override
  String get resultStopDistance => '損切幅';

  @override
  String get sectionTradeParameters => '取引パラメータ';

  @override
  String get fieldExitPrice => '決済価格';

  @override
  String get fieldFeeRate => '手数料率（任意）';

  @override
  String get resultPnl => '損益';

  @override
  String get resultReturn => 'リターン';

  @override
  String get resultFees => '手数料';

  @override
  String get sectionAddReduceRecords => '買付・売却の記録';

  @override
  String recordsCount(int count) {
    return '$count 件';
  }

  @override
  String get actionAddRecord => '記録を追加';

  @override
  String get actionReduce => '売却';

  @override
  String get resultTotalPositionValue => '建玉評価額';

  @override
  String get resultTotalQuantity => '合計数量';

  @override
  String get resultAverageCost => '平均取得単価';

  @override
  String get tableRecordDetails => '記録の詳細';

  @override
  String get tableDate => '日付';

  @override
  String get tableSide => '売買';

  @override
  String get tablePrice => '価格';

  @override
  String get tableQty => '数量';

  @override
  String get tableAmount => '金額';

  @override
  String get fieldPrice => '価格';

  @override
  String get fieldQty => '数量';

  @override
  String get fieldAssetPrice => '資産価格';

  @override
  String get fieldDividendPerShare => '1株あたり配当';

  @override
  String get fieldSharesHeld => '保有株数';

  @override
  String get suffixShares => '株';

  @override
  String get resultDividendYield => '配当利回り';

  @override
  String get resultTotalDividend => '配当金合計';

  @override
  String get resultReinvestShares => '再投資株数';

  @override
  String get resultTotalSharesAfter => '再投資後の株数';

  @override
  String get sectionTotalAssets => '総資産';

  @override
  String get sectionAllocations => '配分';

  @override
  String itemsCount(int count) {
    return '$count 件';
  }

  @override
  String get actionAddAsset => '資産を追加';

  @override
  String get fieldAssetName => '資産名';

  @override
  String get fieldAmount => '金額';

  @override
  String get fieldPercent => '割合';

  @override
  String get resultAllocatedAmount => '配分済み金額';

  @override
  String get resultAllocatedPct => '配分済み %';

  @override
  String get resultRemaining => '残り';

  @override
  String get resultPctDifference => '差分 %';

  @override
  String allocationRemainingHint(String amount) {
    return '$amount が未配分です';
  }

  @override
  String allocationExceedsHint(String amount) {
    return '配分が総資産を $amount 超過しています';
  }

  @override
  String allocationNotFullHint(String pct) {
    return '配分が 100% になっていません（$pct 不足）';
  }

  @override
  String get segmentLongUpside => 'ロング・上昇';

  @override
  String get segmentShortDownside => 'ショート・下落';

  @override
  String get fieldCurrentPrice => '現在価格';

  @override
  String get fieldExpectedReturn => '期待リターン';

  @override
  String get fieldQuickReturn => 'クイック入力';

  @override
  String quickReturnPct(String rate) {
    return '$rate%';
  }

  @override
  String get resultTargetPrice => '目標株価';

  @override
  String get resultExpectedChange => '想定変化幅';

  @override
  String get resultYearsNeeded => '必要な年数';

  @override
  String get resultApprox => '目安';

  @override
  String yearsCount(String years) {
    return '$years 年';
  }

  @override
  String yearsMonthsCount(int years, int months) {
    return '$years 年 $months か月';
  }

  @override
  String get resultAnnualizedReturn => '年率換算リターン';

  @override
  String get fieldInvestedCost => '投資コスト';

  @override
  String get segmentReturnAmount => '受取額';

  @override
  String get segmentFinalValue => '最終評価額';

  @override
  String get resultRoi => 'ROI';

  @override
  String get resultNetProfit => '純利益';

  @override
  String get errorUnableToFetchQuotes => '株価を取得できません';

  @override
  String get errorSymbolNotFound => '銘柄が見つかりません';

  @override
  String get errorNoChartData => 'チャートデータがありません';
}
