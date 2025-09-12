import 'package:flutter/material.dart';
import '../core/theme/algeria_theme.dart';
import '../core/utils/currency_formatter.dart';
import '../widgets/accessible/accessible_button.dart';
import '../widgets/accessible/accessible_text_field.dart';

/// 🇩🇿 Demo Screen showcasing Algeria-specific features
class AlgeriaDemoScreen extends StatefulWidget {
  const AlgeriaDemoScreen({super.key});

  @override
  State<AlgeriaDemoScreen> createState() => _AlgeriaDemoScreenState();
}

class _AlgeriaDemoScreenState extends State<AlgeriaDemoScreen> {
  final _priceController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();
  
  double _samplePrice = 15000.0;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL for Arabic
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض توضيحي للجزائر'),
          leading: AccessibleIconButton(
            icon: Icons.arrow_forward,
            label: 'رجوع',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Algeria Colors Demo
              _buildColorsSection(),
              const SizedBox(height: 24),
              
              // Currency Formatting Demo
              _buildCurrencySection(),
              const SizedBox(height: 24),
              
              // Accessible Widgets Demo
              _buildAccessibleWidgetsSection(),
              const SizedBox(height: 24),
              
              // Banking Demo
              _buildBankingSection(),
              const SizedBox(height: 24),
              
              // RTL Text Demo
              _buildRTLTextSection(),
            ],
          ),
        ),
        floatingActionButton: AccessibleFAB(
          icon: Icons.add_shopping_cart,
          label: 'إضافة إلى السلة',
          hint: 'اضغط لإضافة المنتج إلى سلة التسوق',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم إضافة المنتج إلى السلة')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildColorsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ألوان الجزائر الرسمية',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildColorBox(AlgeriaTheme.algeriaGreen, 'أخضر جزائري'),
                const SizedBox(width: 8),
                _buildColorBox(AlgeriaTheme.algeriaGreenLight, 'أخضر فاتح'),
                const SizedBox(width: 8),
                _buildColorBox(AlgeriaTheme.algeriaGreenMedium, 'أخضر متوسط'),
                const SizedBox(width: 8),
                _buildColorBox(AlgeriaTheme.algeriaGreenAccent, 'أخضر مميز'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBox(Color color, String name) {
    return Semantics(
      label: 'لون $name',
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تنسيق العملة الجزائرية (DZD)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildCurrencyExample('عادي', CurrencyFormatter.formatDZD(_samplePrice)),
            _buildCurrencyExample('عربي', CurrencyFormatter.formatDZDArabic(_samplePrice)),
            _buildCurrencyExample('مضغوط', CurrencyFormatter.formatDZD(_samplePrice, compact: true)),
            _buildCurrencyExample('بدون رمز', CurrencyFormatter.formatDZD(_samplePrice, showSymbol: false)),
            const SizedBox(height: 16),
            AccessiblePriceField(
              label: 'أدخل سعر جديد',
              controller: _priceController,
              onChanged: (value) {
                final price = CurrencyFormatter.parseDZD(value);
                if (price > 0) {
                  setState(() {
                    _samplePrice = price;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyExample(String type, String formatted) {
    return Semantics(
      label: 'مثال تنسيق $type: $formatted',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$type:'),
            Text(
              formatted,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibleWidgetsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'عناصر واجهة يمكن الوصول إليها',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AccessibleSearchField(
              hint: 'البحث في المنتجات...',
              controller: _searchController,
              onChanged: (value) {
                // Handle search
              },
            ),
            const SizedBox(height: 16),
            AccessiblePhoneField(
              controller: _phoneController,
              onChanged: (value) {
                // Handle phone input
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AccessibleButton(
                    text: 'زر عادي',
                    semanticLabel: 'زر للإجراء العادي',
                    onPressed: () => _showMessage('تم الضغط على الزر العادي'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AccessibleButton(
                    text: 'زر محدد',
                    type: ButtonType.outlined,
                    semanticLabel: 'زر للاختيار',
                    onPressed: () => _showMessage('تم الضغط على الزر المحدد'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AccessibleButton(
              text: 'جاري التحميل...',
              isLoading: _isLoading,
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                Future.delayed(const Duration(seconds: 2), () {
                  setState(() {
                    _isLoading = false;
                  });
                  _showMessage('تم الانتهاء من التحميل');
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'البنوك الجزائرية المدعومة',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildBankOption('CIB', 'بنك الائتمان الشعبي الجزائري', Icons.credit_card),
            _buildBankOption('EDAHABIA', 'بريد الجزائر - الذهبية', Icons.account_balance),
            _buildBankOption('BNA', 'البنك الوطني الجزائري', Icons.business),
            _buildBankOption('BEA', 'البنك الخارجي الجزائري', Icons.public),
          ],
        ),
      ),
    );
  }

  Widget _buildBankOption(String code, String name, IconData icon) {
    return Semantics(
      label: 'بنك $name',
      hint: 'اضغط للدفع عبر $name',
      button: true,
      child: ListTile(
        leading: Icon(icon, color: AlgeriaTheme.algeriaGreen),
        title: Text(name),
        subtitle: Text(code),
        trailing: const Icon(Icons.arrow_back_ios),
        onTap: () => _showMessage('تم اختيار $name للدفع'),
      ),
    );
  }

  Widget _buildRTLTextSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نص عربي مع دعم RTL',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'مرحباً بكم في السوق الجزائرية الإلكترونية. نحن نقدم أفضل المنتجات بأسعار تنافسية مع دعم كامل للغة العربية واتجاه النص من اليمين إلى اليسار.',
              textAlign: TextAlign.justify,
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AlgeriaTheme.algeriaGreenAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '💡 نصيحة: يمكنك التبديل بين العربية والفرنسية في أي وقت من إعدادات التطبيق.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AlgeriaTheme.algeriaGreen,
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _phoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}