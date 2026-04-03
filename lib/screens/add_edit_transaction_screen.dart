import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/formatters.dart';
import '../utils/constants.dart';

class AddEditTransactionScreen extends ConsumerStatefulWidget {
  final Transaction? transaction;
  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  ConsumerState<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends ConsumerState<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TransactionType _type;
  late String _category;
  late DateTime _date;

  List<String> get _currentCategories {
    return _type == TransactionType.expense ? expenseCategories : incomeCategories;
  }

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.transaction?.amount.toString() ?? '');
    _noteController = TextEditingController(text: widget.transaction?.note ?? '');
    _type = widget.transaction?.type ?? TransactionType.expense;
    final initialCategory = widget.transaction?.category;
    final currentList = _type == TransactionType.expense ? expenseCategories : incomeCategories;
    if (initialCategory != null && currentList.contains(initialCategory)) {
      _category = initialCategory;
    } else {
      _category = currentList.first;
    }
    _date = widget.transaction?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      final id = widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = Transaction(
        id: id,
        amount: double.parse(_amountController.text),
        type: _type,
        category: _category,
        date: _date,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );
      if (widget.transaction == null) {
        await ref.read(transactionListProvider.notifier).addTransaction(transaction);
      } else {
        await ref.read(transactionListProvider.notifier).updateTransaction(transaction);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${transaction.category} ${widget.transaction == null ? 'added' : 'updated'}'), duration: const Duration(seconds: 1)),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure category is always valid
    if (!_currentCategories.contains(_category)) {
      _category = _currentCategories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Amount field with modern design
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Amount is required';
                    if (double.tryParse(value) == null) return 'Enter valid number';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Type selector
              SegmentedButton<TransactionType>(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return _type == TransactionType.expense ? Colors.red.shade100 : Colors.green.shade100;
                    }
                    return null;
                  }),
                ),
                segments: const [
                  ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle)),
                  ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.add_circle)),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> newSet) {
                  final newType = newSet.first;
                  setState(() {
                    _type = newType;
                    _category = newType == TransactionType.expense ? expenseCategories.first : incomeCategories.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Category dropdown
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: _currentCategories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) => setState(() => _category = newValue!),
                ),
              ),
              const SizedBox(height: 16),
              // Date picker
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date'),
                      Row(
                        children: [
                          Text(formatDate(_date)),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Note field
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('SAVE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}