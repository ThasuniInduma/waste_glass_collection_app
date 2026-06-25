import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:waste_glass_collection/models/collection_record_model.dart';
import 'package:waste_glass_collection/models/supplier_model.dart';
import 'package:waste_glass_collection/providers/trip_provider.dart';
import 'package:waste_glass_collection/utils/colors.dart';


class ScanCollectScreen extends StatefulWidget {
  final Supplier supplier;
  const ScanCollectScreen({super.key, required this.supplier});

  @override
  State<ScanCollectScreen> createState() => _ScanCollectScreenState();
}

class _ScanCollectScreenState extends State<ScanCollectScreen> {
  final _scannerController  = MobileScannerController();
  final _clearKgController  = TextEditingController();
  final _colouredKgController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();

  String  _condition  = 'Good';
  bool    _scanned    = false;
  bool    _submitting = false;
  String? _scanError;

  @override
  void dispose() {
    _scannerController.dispose();
    _clearKgController.dispose();
    _colouredKgController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final scanned = barcode!.rawValue!.trim();

    if (scanned == widget.supplier.barcodeId) {
      // Correct supplier — unlock form
      setState(() {
        _scanned   = true;
        _scanError = null;
      });
      _scannerController.stop();
    } else {
      // Wrong supplier — block
      setState(() {
        _scanError = 'Wrong barcode. Expected: ${widget.supplier.name}';
      });
    }
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final record = CollectionRecord(
      supplierId:  widget.supplier.id,
      clearKg:     double.parse(_clearKgController.text.trim()),
      colouredKg:  double.parse(_colouredKgController.text.trim()),
      condition:   _condition,
      timestamp:   DateTime.now().toIso8601String(),
    );

    await context.read<TripProvider>().recordCollection(record);

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.supplier.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Destination info
            _buildDestinationInfo(),
            const SizedBox(height: 16),

            // Scanner or verified banner
            _scanned ? _buildVerifiedBanner() : _buildScanner(),
            const SizedBox(height: 16),

            // Collection form — locked until barcode scanned
            _buildForm(),
            const SizedBox(height: 24),

            // Confirm button
            if (_scanned) _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.supplier.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text('Expected: ${widget.supplier.expectedKg} kg'),
          Text(
            'GPS: ${widget.supplier.lat}, ${widget.supplier.lng}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scan Supplier Barcode',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        // Camera view
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 220,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
        ),

        // Wrong barcode error
        if (_scanError != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.danger),
            ),
            child: Text(
              _scanError!,
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerifiedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success),
          const SizedBox(width: 10),
          Text(
            'Barcode verified — ${widget.supplier.name}',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return AbsorbPointer(
      absorbing: !_scanned,
      child: Opacity(
        opacity: _scanned ? 1.0 : 0.4,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _scanned
                    ? 'Enter Collection Details'
                    : 'Scan barcode to unlock form',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              // Clear glass kg
              TextFormField(
                controller: _clearKgController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Clear Glass (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Coloured glass kg
              TextFormField(
                controller: _colouredKgController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Coloured Glass (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Condition
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: ['Good', 'Damaged', 'Mixed']
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: _submitting ? null : _confirm,
        child: _submitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Confirm Collection',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}