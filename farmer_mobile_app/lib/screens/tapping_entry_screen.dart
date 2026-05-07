import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TappingEntryScreen extends StatefulWidget {
  const TappingEntryScreen({super.key});

  @override
  State<TappingEntryScreen> createState() => _TappingEntryScreenState();
}

class _TappingEntryScreenState extends State<TappingEntryScreen> {
  final _latexQuantityController = TextEditingController();
  final _ammoniaAmountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _tappingTime = const TimeOfDay(hour: 5, minute: 30);
  TimeOfDay _collectionTime = const TimeOfDay(hour: 8, minute: 0);
  bool _ammoniaAdded = false;
  String _containerType = 'Closed Container';
  bool _isLoading = false;

  final List<String> _containerTypes = [
    'Closed Container',
    'Open Container',
    'Bucket',
    'Cup',
  ];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTappingTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _tappingTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _tappingTime = picked);
  }

  Future<void> _selectCollectionTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _collectionTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _collectionTime = picked);
  }

  double _calculateCollectionGap() {
    final tapping = _tappingTime.hour * 60 + _tappingTime.minute;
    final collection = _collectionTime.hour * 60 + _collectionTime.minute;
    final gap = (collection - tapping) / 60;
    return gap < 0 ? gap + 24 : gap;
  }

  Future<void> _saveTappingRecord() async {
    if (_latexQuantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter latex quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ammoniaAdded && _ammoniaAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter ammonia amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final collectionGap = _calculateCollectionGap();

      await FirebaseFirestore.instance.collection('tapping_records').add({
        'farmerId': user.uid,
        'tappingDate': _selectedDate.toIso8601String(),
        'tappingTime':
            '${_tappingTime.hour}:${_tappingTime.minute.toString().padLeft(2, '0')}',
        'collectionTime':
            '${_collectionTime.hour}:${_collectionTime.minute.toString().padLeft(2, '0')}',
        'collectionGapHours': collectionGap.toStringAsFixed(2),
        'latexQuantity':
            double.tryParse(_latexQuantityController.text.trim()) ?? 0,
        'ammoniaAdded': _ammoniaAdded,
        'ammoniaAmount': _ammoniaAdded
            ? double.tryParse(_ammoniaAmountController.text.trim()) ?? 0
            : 0,
        'containerType': _containerType,
        'notes': _notesController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tapping record saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      setState(() {
        _latexQuantityController.clear();
        _ammoniaAmountController.clear();
        _notesController.clear();
        _ammoniaAdded = false;
        _selectedDate = DateTime.now();
        _tappingTime = const TimeOfDay(hour: 5, minute: 30);
        _collectionTime = const TimeOfDay(hour: 8, minute: 0);
        _containerType = 'Closed Container';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: const Color(0xFF2E7D32)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        automaticallyImplyLeading: false,
        title: const Text(
          'Tapping Entry',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.grass, color: Color(0xFF2E7D32), size: 30),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Tapping Record',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      Text(
                        'Record your daily latex collection',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Date & Time Section
            _buildSectionTitle('Date & Time'),

            // Date picker
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tapping Date',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            // Tapping time
            GestureDetector(
              onTap: _selectTappingTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tapping Time',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          _tappingTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            // Collection time
            GestureDetector(
              onTap: _selectCollectionTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Collection Time',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(
                          _collectionTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Gap: ${_calculateCollectionGap().toStringAsFixed(1)} hrs',
                        style: const TextStyle(
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Latex Section
            _buildSectionTitle('Latex Collection'),

            // Latex quantity
            TextField(
              controller: _latexQuantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Latex Quantity (kg)',
                prefixIcon:
                    const Icon(Icons.water_drop, color: Color(0xFF2E7D32)),
                suffixText: 'kg',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            // Container type
            DropdownButtonFormField<String>(
              value: _containerType,
              decoration: InputDecoration(
                labelText: 'Container Type',
                prefixIcon: const Icon(Icons.science, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _containerTypes.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) =>
                  setState(() => _containerType = newValue!),
            ),

            // Ammonia Section
            _buildSectionTitle('Preservation'),

            // Ammonia toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science, color: Color(0xFF2E7D32)),
                  const SizedBox(width: 12),
                  const Text('Ammonia Added?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const Spacer(),
                  Switch(
                    value: _ammoniaAdded,
                    onChanged: (value) =>
                        setState(() => _ammoniaAdded = value),
                    activeColor: const Color(0xFF2E7D32),
                  ),
                ],
              ),
            ),

            // Ammonia amount (show only if ammonia added)
            if (_ammoniaAdded) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _ammoniaAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Ammonia Amount (ml)',
                  prefixIcon: const Icon(Icons.water,
                      color: Color(0xFF2E7D32)),
                  suffixText: 'ml',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF2E7D32), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],

            // Notes Section
            _buildSectionTitle('Additional Notes'),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                prefixIcon:
                    const Icon(Icons.notes, color: Color(0xFF2E7D32)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTappingRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Save Tapping Record',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}