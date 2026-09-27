// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navWatchlist => 'Mi lista';

  @override
  String get navCalculators => 'Calculadoras';

  @override
  String get navSaved => 'Guardados';

  @override
  String get navPortfolio => 'Portafolio';

  @override
  String get navMarket => 'Mercado';

  @override
  String get navAlerts => 'Alertas';

  @override
  String get portfolioTitle => 'Portafolio';

  @override
  String get portfolioTotalValue => 'Valor total';

  @override
  String get portfolioToday => 'Hoy';

  @override
  String get portfolioUnrealized => 'No realizado';

  @override
  String get portfolioRealized => 'Realizado';

  @override
  String get portfolioInvested => 'Invertido';

  @override
  String get portfolioAllocation => 'Distribución';

  @override
  String get portfolioPositions => 'Posiciones';

  @override
  String portfolioHoldingCount(int count) {
    return '$count posiciones';
  }

  @override
  String get portfolioEmptyTitle => 'Aún no tienes posiciones';

  @override
  String get portfolioEmptyBody =>
      'Registra una compra para seguir costo, ganancias y distribución.';

  @override
  String get portfolioPartialData =>
      'No se pudieron valorar algunas posiciones — los totales son parciales.';

  @override
  String portfolioMissingSymbols(String symbols) {
    return 'Sin precio para $symbols';
  }

  @override
  String get portfolioRefresh => 'Actualizar cotizaciones';

  @override
  String get portfolioAddTransaction => 'Agregar operación';

  @override
  String get columnSymbol => 'Símbolo';

  @override
  String get columnQuantity => 'Cant.';

  @override
  String get columnAverageCost => 'Costo prom.';

  @override
  String get columnPrice => 'Precio';

  @override
  String get columnMarketValue => 'Valor';

  @override
  String get columnPnl => 'G/P';

  @override
  String get columnWeight => 'Peso';

  @override
  String warningOversell(String symbol, String quantity) {
    return '$symbol: una venta superó tu posición en $quantity';
  }

  @override
  String get alertsTitle => 'Alertas de precio';

  @override
  String get alertsEmptyTitle => 'Aún no tienes alertas';

  @override
  String get alertsEmptyBody =>
      'Crea una regla y la app te avisará cuando el precio la cruce.';

  @override
  String get alertAdd => 'Nueva alerta';

  @override
  String get alertKindPriceAbove => 'Precio por encima de';

  @override
  String get alertKindPriceBelow => 'Precio por debajo de';

  @override
  String get alertKindPercentAbove => 'Cambio diario mayor a';

  @override
  String get alertKindPercentBelow => 'Cambio diario menor a';

  @override
  String get alertSymbol => 'Símbolo';

  @override
  String get alertThreshold => 'Umbral';

  @override
  String get alertStatusArmed => 'Activa';

  @override
  String get alertStatusPaused => 'Pausada';

  @override
  String alertStatusTriggered(String time) {
    return 'Se activó $time';
  }

  @override
  String alertDistanceAhead(String distance) {
    return 'Faltan $distance';
  }

  @override
  String get alertDistanceCrossed => 'Umbral alcanzado';

  @override
  String get alertNoPrice => 'Esperando precio';

  @override
  String get alertReArm => 'Rearmar';

  @override
  String get alertDeleteTitle => 'Eliminar alerta';

  @override
  String alertDeleteMessage(String symbol) {
    return '¿Eliminar la alerta de $symbol?';
  }

  @override
  String get alertNeedSymbol => 'Escribe un símbolo';

  @override
  String get alertNeedThreshold => 'Escribe un umbral válido';

  @override
  String alertNotificationTitle(String symbol) {
    return 'Alerta de precio: $symbol';
  }

  @override
  String alertNotificationBody(String condition, String price) {
    return '$condition — último $price';
  }

  @override
  String get alertChannelName => 'Alertas de precio';

  @override
  String get alertChannelDescription =>
      'Te avisa cuando se cumple una de tus reglas de precio.';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get actionRemove => 'Quitar';

  @override
  String get actionDelete => 'Eliminar';

  @override
  String get actionRetry => 'Reintentar';

  @override
  String get actionSave => 'Guardar';

  @override
  String get actionSaveAs => 'Guardar como';

  @override
  String get actionAdd => 'Agregar';

  @override
  String get actionAdded => 'Agregado';

  @override
  String get actionPin => 'Fijar';

  @override
  String get actionUnpin => 'Quitar';

  @override
  String get actionClear => 'Limpiar';

  @override
  String get actionLoad => 'Cargar';

  @override
  String get actionOptions => 'Opciones';

  @override
  String get resultPanelTitle => 'Resultados';

  @override
  String get disclaimerFooter =>
      'Solo como referencia — no es asesoría de inversión.';

  @override
  String get homeTitle => 'Mercados';

  @override
  String get tooltipAddSymbols => 'Agregar símbolos';

  @override
  String get tooltipSettings => 'Ajustes';

  @override
  String get tooltipRefreshNow => 'Actualizar ahora';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterGainers => 'Suben';

  @override
  String get filterLosers => 'Bajan';

  @override
  String get sectionMarketIndices => 'Índices del mercado';

  @override
  String get sectionPinned => 'Fijados';

  @override
  String get watchlistTitle => 'Mi lista';

  @override
  String get statusUpdating => 'Actualizando…';

  @override
  String statusUpdated(String time) {
    return 'Actualizado $time';
  }

  @override
  String get errorQuotesFetchFailed =>
      'No se pudieron obtener las cotizaciones. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get removeSymbolTitle => 'Quitar símbolo';

  @override
  String removeSymbolMessage(String symbol) {
    return '¿Quitar $symbol de tu lista?';
  }

  @override
  String get emptyWatchlistTitle => 'Tu lista está vacía';

  @override
  String get emptyOnlyIndices => 'Solo hay índices — agrega algunas acciones';

  @override
  String get emptyNoGainers => 'Ninguno sube hoy';

  @override
  String get emptyNoLosers => 'Ninguno baja hoy';

  @override
  String get emptyBuildTitle => 'Crea tu lista';

  @override
  String get emptyBuildBody =>
      'Busca un ticker o el nombre de una empresa para seguir cotizaciones en vivo.';

  @override
  String footerAutoRefresh(int minutes) {
    return 'Actualización automática cada $minutes min';
  }

  @override
  String footerNextFetch(String time) {
    return 'siguiente $time';
  }

  @override
  String get footerNoFetchYet => 'sin datos aún';

  @override
  String get toolsTitle => 'Calculadoras';

  @override
  String get tooltipSearchCalculators => 'Buscar calculadoras';

  @override
  String get tooltipSavedResults => 'Resultados guardados';

  @override
  String get searchHintCalculators =>
      'Busca por nombre o por lo que quieres calcular';

  @override
  String get sectionStartHere => 'Empieza aquí';

  @override
  String get hintStarToPin => 'Marca una herramienta con ★ para fijarla';

  @override
  String get hintTapToUnpin => 'Toca ★ para quitar la fijación';

  @override
  String get sectionResults => 'Resultados';

  @override
  String noCalculatorMatches(String query) {
    return 'Ninguna calculadora coincide con \"$query\"';
  }

  @override
  String resultsShownOfTotal(int shown, int total) {
    return '$shown de $total';
  }

  @override
  String summaryCalculators(int total) {
    return '$total calculadoras';
  }

  @override
  String summaryStarterPicks(int pinned) {
    return '$pinned sugeridas · todo funciona en tu dispositivo';
  }

  @override
  String summaryPinned(int favorites) {
    return '$favorites fijadas · todo funciona en tu dispositivo';
  }

  @override
  String get categoryTrading => 'Trading';

  @override
  String get categoryTradingHint => 'Entradas, salidas y tamaño de posición';

  @override
  String get categoryInvestment => 'Inversión';

  @override
  String get categoryInvestmentHint =>
      'Interés compuesto, asignación y rendimientos';

  @override
  String get toolCompoundTitle => 'Interés compuesto';

  @override
  String get toolCompoundSubtitle =>
      'Mira el poder del interés compuesto en el tiempo';

  @override
  String get toolRiskTitle => 'Riesgo / Beneficio';

  @override
  String get toolRiskSubtitle => 'Evalúa rápido si una operación vale la pena';

  @override
  String get toolPositionTitle => 'Costo de posición';

  @override
  String get toolPositionSubtitle =>
      'Sigue tu precio promedio entre varias entradas';

  @override
  String get toolSizeTitle => 'Tamaño de posición';

  @override
  String get toolSizeSubtitle => 'Calcula el tamaño según tu pérdida máxima';

  @override
  String get toolDividendTitle => 'Reinvertir dividendos';

  @override
  String get toolDividendSubtitle =>
      'Pon a trabajar tus dividendos en efectivo';

  @override
  String get toolAllocationTitle => 'Asignación de activos';

  @override
  String get toolAllocationSubtitle => 'Arma una cartera a tu medida';

  @override
  String get toolProfitTitle => 'Ganancias y pérdidas';

  @override
  String get toolProfitSubtitle => 'Ve de inmediato cuánto ganaste';

  @override
  String get toolTargetTitle => 'Precio objetivo';

  @override
  String get toolTargetSubtitle =>
      'Calcula el precio desde el rendimiento que buscas';

  @override
  String get toolRateTitle => 'Rendimiento anual';

  @override
  String get toolRateSubtitle => 'Obtén el rendimiento anualizado';

  @override
  String get toolTimeTitle => 'Tiempo para tu meta';

  @override
  String get toolTimeSubtitle => 'Cuánto falta para llegar a tu objetivo';

  @override
  String get toolRoiTitle => 'Calculadora de ROI';

  @override
  String get toolRoiSubtitle => 'Mide el rendimiento real de tu inversión';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get settingTheme => 'Tema';

  @override
  String get themeSystem => 'Seguir al sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingLanguage => 'Idioma';

  @override
  String get languageSystem => 'Seguir al sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageJapanese => '日本語';

  @override
  String get settingAutoSort => 'Ordenar por cambio diario';

  @override
  String get settingAutoSortSub =>
      'Ordena tu lista por el cambio porcentual de hoy';

  @override
  String get sectionQuotes => 'Cotizaciones';

  @override
  String get settingRefreshInterval => 'Intervalo de actualización';

  @override
  String minutesCount(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get settingRoundPrices => 'Redondear precios a 2 decimales';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get aboutDataSource => 'Fuente de datos';

  @override
  String get aboutDataSourceSub => 'Cotizaciones y gráficas de Yahoo Finance';

  @override
  String get aboutCalculators => 'Calculadoras';

  @override
  String get aboutCalculatorsSub =>
      'Las operaciones se hacen totalmente en tu dispositivo';

  @override
  String get aboutDisclaimer => 'Aviso';

  @override
  String get aboutDisclaimerSub =>
      'Solo como referencia — no es asesoría de inversión.';

  @override
  String get historyTitle => 'Resultados guardados';

  @override
  String get historyEmptyTitle => 'Aún no guardas resultados';

  @override
  String get historyEmptyBody => 'Guarda cualquier cálculo para tenerlo aquí.';

  @override
  String historyNote(String note) {
    return 'Nota: $note';
  }

  @override
  String get historyInputs => 'Datos';

  @override
  String get historyResults => 'Resultados';

  @override
  String get historyDeleteTitle => 'Eliminar resultado';

  @override
  String historyDeleteMessage(String title) {
    return '¿Eliminar \"$title\"? No se puede deshacer.';
  }

  @override
  String get searchTitle => 'Agregar símbolos';

  @override
  String get searchHint => 'Busca un símbolo o empresa (ej. AAPL)';

  @override
  String get searchTrending => 'Tendencias';

  @override
  String get searchTrendingFailed => 'No se pudieron cargar las tendencias';

  @override
  String get searchNoResults => 'No se encontraron símbolos';

  @override
  String get searchFailed => 'La búsqueda falló. Inténtalo de nuevo.';

  @override
  String searchAlreadyInWatchlist(String symbol) {
    return '$symbol ya está en tu lista';
  }

  @override
  String searchAddedToWatchlist(String symbol) {
    return '$symbol se agregó a tu lista';
  }

  @override
  String get detailRemoveFromWatchlist => 'Quitar de mi lista';

  @override
  String get detailAddToWatchlist => 'Agregar a mi lista';

  @override
  String get detailRefreshQuote => 'Actualizar cotización';

  @override
  String detailRemovedFromWatchlist(String symbol) {
    return '$symbol se quitó de tu lista';
  }

  @override
  String detailAddedToWatchlist(String symbol) {
    return '$symbol se agregó a tu lista';
  }

  @override
  String get detailChartFailed => 'No se pudo cargar la gráfica.';

  @override
  String get detailRefreshFailed => 'No se pudo actualizar la cotización';

  @override
  String get marketOpen => 'Mercado abierto';

  @override
  String get marketPreMarket => 'Premercado';

  @override
  String get marketAfterHours => 'Fuera de horario';

  @override
  String get marketClosed => 'Mercado cerrado';

  @override
  String get detailKeyStatistics => 'Estadísticas clave';

  @override
  String get statOpen => 'Apertura';

  @override
  String get statPreviousClose => 'Cierre anterior';

  @override
  String get statDayRange => 'Rango del día';

  @override
  String get statVolume => 'Volumen';

  @override
  String get statMarketCap => 'Capitalización';

  @override
  String get statPeRatio => 'P/U';

  @override
  String get stat52WeekRange => 'Rango de 52 semanas';

  @override
  String get stat50DayAvg => 'Promedio 50 días';

  @override
  String get stat200DayAvg => 'Promedio 200 días';

  @override
  String get detailRelatedNews => 'Noticias relacionadas';

  @override
  String get detailNoNews => 'Sin noticias disponibles';

  @override
  String get detailOpenArticleFailed => 'No se pudo abrir la nota';

  @override
  String get chartRangeMax => 'Máx';

  @override
  String get chartNotEnoughData => 'No hay suficientes datos para la gráfica';

  @override
  String calcLoaded(String title) {
    return 'Cargado: $title';
  }

  @override
  String recordSavedAs(String title) {
    return 'Guardado como \"$title\"';
  }

  @override
  String recordSaved(String title) {
    return 'Se guardó \"$title\"';
  }

  @override
  String get dialogSaveAsRecord => 'Guardar como nuevo';

  @override
  String get dialogSaveRecord => 'Guardar cálculo';

  @override
  String get fieldRecordName => 'Nombre del registro';

  @override
  String get fieldRecordNameHint => 'ej. plan 2026';

  @override
  String get fieldRecordNote => 'Nota (opcional)';

  @override
  String get errorRecordNameRequired => 'Escribe un nombre para el registro';

  @override
  String get fieldPrincipal => 'Capital';

  @override
  String get fieldTargetAmount => 'Monto objetivo';

  @override
  String get fieldInitialPrincipal => 'Capital inicial';

  @override
  String get fieldPeriodicContribution => 'Aportación periódica';

  @override
  String get fieldFrequency => 'Frecuencia';

  @override
  String get segmentMonthly => 'Mensual';

  @override
  String get segmentYearly => 'Anual';

  @override
  String get fieldAnnualRate => 'Tasa anual';

  @override
  String get fieldTerm => 'Plazo';

  @override
  String get suffixYears => 'años';

  @override
  String quickRate(String rate) {
    return 'Tasa $rate%';
  }

  @override
  String quickTermYears(String term) {
    return '$term a';
  }

  @override
  String get resultTotalBalance => 'Saldo total';

  @override
  String get resultTotalInterest => 'Interés total';

  @override
  String get resultTotalReturn => 'Rendimiento total';

  @override
  String get resultTotalInvested => 'Total invertido';

  @override
  String get resultYearlyBreakdown => 'Desglose anual';

  @override
  String get tableYear => 'Año';

  @override
  String get tablePrincipal => 'Capital';

  @override
  String get tableInterest => 'Interés';

  @override
  String get tableYearRate => 'Tasa anual';

  @override
  String get tableBalance => 'Saldo';

  @override
  String yearLabel(int year) {
    return 'Año $year';
  }

  @override
  String get sectionTradeSetup => 'Datos de la operación';

  @override
  String get segmentLong => 'Largo';

  @override
  String get segmentShort => 'Corto';

  @override
  String get segmentSpot => 'Spot';

  @override
  String get segmentFutures => 'Futuros';

  @override
  String get fieldEntryPrice => 'Precio de entrada';

  @override
  String get fieldStopPrice => 'Precio de stop';

  @override
  String get fieldTargetPrice => 'Precio objetivo';

  @override
  String get fieldQuantity => 'Cantidad';

  @override
  String get suffixUnits => 'unidades';

  @override
  String get fieldContractMultiplier => 'Multiplicador del contrato';

  @override
  String get suffixPerPoint => '/ punto';

  @override
  String get fieldMargin => 'Margen';

  @override
  String get fieldQuickStop => 'Stop rápido %';

  @override
  String labelStopPct(String pct) {
    return 'Stop $pct%';
  }

  @override
  String get fieldQuickRr => 'R/B rápido';

  @override
  String labelRrRatio(String ratio) {
    return 'R/B 1:$ratio';
  }

  @override
  String get resultRiskReward => 'Riesgo / Beneficio';

  @override
  String get resultTargetProfit => 'Ganancia objetivo';

  @override
  String get resultExpectedLoss => 'Pérdida esperada';

  @override
  String get resultMarginRequired => 'Margen requerido';

  @override
  String get resultReturnOnMargin => 'Retorno sobre margen';

  @override
  String get sectionPositionSetup => 'Datos de la posición';

  @override
  String get fieldMaxLoss => 'Pérdida máxima';

  @override
  String get resultMaxQuantity => 'Cantidad máxima';

  @override
  String get resultPositionValue => 'Valor de la posición';

  @override
  String get resultStopDistance => 'Distancia al stop';

  @override
  String get sectionTradeParameters => 'Parámetros de la operación';

  @override
  String get fieldExitPrice => 'Precio de salida';

  @override
  String get fieldFeeRate => 'Comisión (opcional)';

  @override
  String get resultPnl => 'G/P';

  @override
  String get resultReturn => 'Rendimiento';

  @override
  String get resultFees => 'Comisiones';

  @override
  String get sectionAddReduceRecords => 'Registros de compra / venta';

  @override
  String recordsCount(int count) {
    return '$count registros';
  }

  @override
  String get actionAddRecord => 'Agregar registro';

  @override
  String get actionReduce => 'Reducir';

  @override
  String get resultTotalPositionValue => 'Valor total de la posición';

  @override
  String get resultTotalQuantity => 'Cantidad total';

  @override
  String get resultAverageCost => 'Costo promedio';

  @override
  String get tableRecordDetails => 'Detalle de registros';

  @override
  String get tableDate => 'Fecha';

  @override
  String get tableSide => 'Lado';

  @override
  String get tablePrice => 'Precio';

  @override
  String get tableQty => 'Cant.';

  @override
  String get tableAmount => 'Importe';

  @override
  String get fieldPrice => 'Precio';

  @override
  String get fieldQty => 'Cant.';

  @override
  String get fieldAssetPrice => 'Precio del activo';

  @override
  String get fieldDividendPerShare => 'Dividendo por acción';

  @override
  String get fieldSharesHeld => 'Acciones en cartera';

  @override
  String get suffixShares => 'acciones';

  @override
  String get resultDividendYield => 'Rendimiento por dividendo';

  @override
  String get resultTotalDividend => 'Dividendo total';

  @override
  String get resultReinvestShares => 'Acciones reinvertidas';

  @override
  String get resultTotalSharesAfter => 'Acciones después';

  @override
  String get sectionTotalAssets => 'Activos totales';

  @override
  String get sectionAllocations => 'Asignaciones';

  @override
  String itemsCount(int count) {
    return '$count elementos';
  }

  @override
  String get actionAddAsset => 'Agregar activo';

  @override
  String get fieldAssetName => 'Nombre del activo';

  @override
  String get fieldAmount => 'Monto';

  @override
  String get fieldPercent => 'Porcentaje';

  @override
  String get resultAllocatedAmount => 'Monto asignado';

  @override
  String get resultAllocatedPct => '% asignado';

  @override
  String get resultRemaining => 'Restante';

  @override
  String get resultPctDifference => 'Diferencia %';

  @override
  String allocationRemainingHint(String amount) {
    return '$amount sin asignar';
  }

  @override
  String allocationExceedsHint(String amount) {
    return 'La asignación supera tus activos en $amount';
  }

  @override
  String allocationNotFullHint(String pct) {
    return 'La asignación no suma 100% (faltan $pct)';
  }

  @override
  String get segmentLongUpside => 'Largo · Alza';

  @override
  String get segmentShortDownside => 'Corto · Baja';

  @override
  String get fieldCurrentPrice => 'Precio actual';

  @override
  String get fieldExpectedReturn => 'Rendimiento esperado';

  @override
  String get fieldQuickReturn => 'Rendimiento rápido';

  @override
  String quickReturnPct(String rate) {
    return '$rate%';
  }

  @override
  String get resultTargetPrice => 'Precio objetivo';

  @override
  String get resultExpectedChange => 'Cambio esperado';

  @override
  String get resultYearsNeeded => 'Años necesarios';

  @override
  String get resultApprox => 'Aprox.';

  @override
  String yearsCount(String years) {
    return '$years años';
  }

  @override
  String yearsMonthsCount(int years, int months) {
    return '$years años $months meses';
  }

  @override
  String get resultAnnualizedReturn => 'Rendimiento anualizado';

  @override
  String get fieldInvestedCost => 'Costo invertido';

  @override
  String get segmentReturnAmount => 'Ganancia obtenida';

  @override
  String get segmentFinalValue => 'Valor final';

  @override
  String get resultRoi => 'ROI';

  @override
  String get resultNetProfit => 'Ganancia neta';

  @override
  String get errorUnableToFetchQuotes =>
      'No se pudieron obtener las cotizaciones';

  @override
  String get errorSymbolNotFound => 'Símbolo no encontrado';

  @override
  String get errorNoChartData => 'No hay datos de gráfica disponibles';
}
