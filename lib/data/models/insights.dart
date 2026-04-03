class Insights {
  final double totalIncome;
  final double totalExpenses;
  final Map<String, double> categorySpending;

  Insights({
    required this.totalIncome,
    required this.totalExpenses,
    required this.categorySpending,
  });

  double get balance => totalIncome - totalExpenses;
}
