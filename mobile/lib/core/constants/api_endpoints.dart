class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const register   = '/auth/register';
  static const login      = '/auth/login';
  static const logout     = '/auth/logout';
  static const me         = '/auth/me';
  static const mode       = '/auth/mode';

  // Dashboard
  static const dashboard  = '/dashboard';

  // Income
  static const income        = '/income';
  static const incomeSummary = '/income/summary';
  static const incomeStreams = '/income/streams';

  // Expenses
  static const expenses            = '/expenses';
  static const expensesSummary     = '/expenses/summary';
  static const expensesHeatmap     = '/expenses/heatmap';
  static const expensesSubscriptions = '/expenses/subscriptions';

  // Loans & Cards
  static const loans       = '/loans';
  static const loansScore  = '/loans/score';
  static const loansForecast = '/loans/forecast';
  static const loansDebtfree = '/loans/debtfree';
  static const loansSimulate = '/loans/simulate';
  static const cards       = '/loans/cards';

  // Trades
  static const trades        = '/trades';
  static const tradesPnl     = '/trades/pnl';
  static const tradesAnalytics  = '/trades/analytics';
  static const tradesTaxSummary = '/trades/taxsummary';

  // Investments
  static const investments           = '/investments';
  static const investmentsAllocation = '/investments/allocation';
  static const investmentsXirr       = '/investments/xirr';

  // Creator
  static const creator        = '/creator';
  static const creatorSummary = '/creator/summary';
  static const creatorRpm     = '/creator/rpm_trend';

  // Tax
  static const taxSummary      = '/tax/summary';
  static const taxDeductions   = '/tax/deductions';
  static const taxAdvance      = '/tax/advance';
  static const taxCarryForward = '/tax/carryforward';
  static const taxSuggestions  = '/tax/suggestions';

  // Net Worth
  static const networth         = '/networth';
  static const networthHistory  = '/networth/history';
  static const networthSnapshot = '/networth/snapshot';
  static const networthForecast = '/networth/forecast';

  // Friends
  static const friends        = '/friends';
  static const friendsSummary = '/friends/summary';

  // Insurance
  static const insurance        = '/insurance';
  static const insuranceSummary = '/insurance/summary';

  // Simulator
  static const simulatorScenario = '/simulator/scenario';
  static const simulatorSkipEmi  = '/simulator/skipemi';

  // Reports
  static const reportMonthly    = '/reports/monthly';
  static const reportMonthlyPdf = '/reports/monthly/pdf';
  static const reportTax        = '/reports/tax';
  static const reportTaxPdf     = '/reports/tax/pdf';
}
