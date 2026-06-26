import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:fitnesbuster/core/theme/dynamic_theme.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});
  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  bool _loading = false;
  String _status = 'Наведите камеру на штрихкод продукта';

  @override
  void initState() {
    super.initState();
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'FitnesBuster',
      version: '1.0',
      comment: 'Flutter fitness app',
    );
    OpenFoodAPIConfiguration.globalLanguages = [
      OpenFoodFactsLanguage.RUSSIAN,
      OpenFoodFactsLanguage.ENGLISH,
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned || _loading) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() { _scanned = true; _loading = true; _status = 'Поиск продукта...'; });

    try {
      final config = ProductQueryConfiguration(
        code,
        version: ProductQueryVersion.v3,
        fields: [
          ProductField.NAME,
          ProductField.NAME_IN_LANGUAGES,
          ProductField.NUTRIMENTS,
          ProductField.QUANTITY,
          ProductField.BRANDS,
        ],
        language: OpenFoodFactsLanguage.RUSSIAN,
        country: OpenFoodFactsCountry.RUSSIA,
      );
      final result = await OpenFoodAPIClient.getProductV3(config)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (result.status == ProductResultV3.statusSuccess && result.product != null) {
        final product = result.product!;
        // Try Russian name first, then any available name
        final ruName = product.productNameInLanguages?[OpenFoodFactsLanguage.RUSSIAN];
        final enName = product.productNameInLanguages?[OpenFoodFactsLanguage.ENGLISH];
        final brand = product.brands?.split(',').first.trim() ?? '';
        final rawName = ruName ?? enName ?? product.productName ?? '';
        final name = rawName.isNotEmpty
            ? rawName.trim()
            : (brand.isNotEmpty ? brand : 'Продукт $code');
        final kcalPer100 = product.nutriments?.getValue(
          Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0.0;
        setState(() { _loading = false; });
        await _showResultDialog(name, kcalPer100, code);
      } else {
        if (!mounted) return;
        setState(() {
          _status = 'Продукт не найден в базе.\nПопробуйте другой штрихкод.';
          _scanned = false;
          _loading = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() { _status = 'Сервер не отвечает. Проверьте интернет.'; _scanned = false; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      // Show actual error text so connectivity issues are diagnosable
      final msg = e.toString().replaceAll('Exception: ', '').replaceAll('ClientException: ', '');
      setState(() {
        _status = 'Ошибка: ${msg.length > 80 ? msg.substring(0, 80) : msg}';
        _scanned = false;
        _loading = false;
      });
    }
  }

  Future<void> _showResultDialog(String name, double kcalPer100, String barcode) async {
    final c = AppTheme.of(context);
    final gramsCtrl = TextEditingController(text: '100');
    String mealType = 'Перекус';
    const types = ['Завтрак', 'Обед', 'Перекус', 'Ужин'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, localSet) {
          final grams = int.tryParse(gramsCtrl.text) ?? 0;
          final kcal = ((kcalPer100 * grams) / 100).round();

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: c.surfaceCard, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(name, style: TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w800, color: c.textPrimary))),
                  IconButton(onPressed: () => Navigator.pop(ctx2), icon: Icon(Icons.close_rounded, color: c.textMuted)),
                ]),
                const SizedBox(height: 4),
                Text('Баркод: $barcode', style: TextStyle(fontSize: 11, color: c.textMuted)),
                if (kcalPer100 > 0) Text('${kcalPer100.toInt()} ккал / 100г', style: TextStyle(fontSize: 12, color: c.primary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Meal type chips
                SizedBox(
                  height: 34,
                  child: ListView(scrollDirection: Axis.horizontal, children: types.map((t) =>
                    GestureDetector(
                      onTap: () => localSet(() => mealType = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(color: mealType == t ? c.primary : c.elevated, borderRadius: BorderRadius.circular(10)),
                        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: mealType == t ? c.textOnPrimary : c.textMuted)),
                      ),
                    ),
                  ).toList()),
                ),
                const SizedBox(height: 14),

                // Grams input
                Row(children: [
                  Expanded(child: TextField(
                    controller: gramsCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => localSet(() {}),
                    style: TextStyle(color: c.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Количество (г)',
                      hintStyle: TextStyle(color: c.textMuted),
                      prefixIcon: Icon(Icons.scale_rounded, size: 18, color: c.textMuted),
                      filled: true, fillColor: c.elevated,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  )),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: c.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    child: Text('$kcal\nккал', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Syne', fontSize: 13, fontWeight: FontWeight.w800, color: c.primary)),
                  ),
                ]),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: grams <= 0 ? null : () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(ctx2);
                      Navigator.pop(context, {
                        'name': name,
                        'grams': grams,
                        'kcal': kcal,
                        'mealType': mealType,
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Добавить в дневник', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx2);
                      setState(() { _scanned = false; _status = 'Наведите камеру на штрихкод продукта'; });
                    },
                    child: Text('Сканировать снова', style: TextStyle(color: c.textMuted)),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );

    if (mounted && _scanned) {
      setState(() { _scanned = false; _status = 'Наведите камеру на штрихкод продукта'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        MobileScanner(controller: _ctrl, onDetect: _onDetect),

        // Top bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _ctrl.toggleTorch(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),

        // Scanner overlay
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 260, height: 180,
            decoration: BoxDecoration(border: Border.all(color: c.primary, width: 2), borderRadius: BorderRadius.circular(16)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
            child: Text(
              _loading ? 'Поиск...' : _status,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          if (_loading) ...[
            const SizedBox(height: 12),
            const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ])),
      ]),
    );
  }
}
