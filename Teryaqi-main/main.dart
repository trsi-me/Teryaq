// تم نقل تطبيق Flutter إلى المجلد flutter_app — شغّل: cd flutter_app ثم flutter run
// الملف النشط: flutter_app/lib/main.dart
import 'package:flutter/material.dart';

void main() => runApp(const TeriaqiApp());

class TeriaqiApp extends StatelessWidget {
  const TeriaqiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Tajawal'),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Map<String, String>> medicines = [];
  String? selectedDisease;
  TimeOfDay selectedTime = TimeOfDay.now();

  final nameController = TextEditingController();
  final medNameController = TextEditingController();
  final doseController = TextEditingController();
  final noteController = TextEditingController();

  final List<String> diseases = [
    'مرض ضغط الدم',
    'خمول الغدة الدرقية',
    'هشاشة العظام',
    'ارتفاع الكوليسترول',
    'أمراض سيولة الدم',
    'المرض السكري النوع الثاني',
    'أخرى / عام',
  ];

  // دالة اختيار الوقت مثل الصورة
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  void _addMedicine() {
    setState(() {
      medicines.add({
        'patient': nameController.text,
        'med': medNameController.text,
        'time': selectedTime.format(context),
      });
      nameController.clear();
      medNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF065F46),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              _buildStatsRow(),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الاحترازات على اليسار (Flex 2)
                  Expanded(flex: 2, child: _buildPrecautionsSection()),
                  const SizedBox(width: 25),
                  // بيانات المريض على اليمين (Flex 1)
                  Expanded(flex: 1, child: _buildPatientForm()),
                ],
              ),
              const SizedBox(height: 25),
              _buildMedTable(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Text(
                'المستشعر متصل',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              SizedBox(width: 8),
              Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            ],
          ),
        ),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'ترياقي 🩺',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'نظام مراقبة الدواء الذكي',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard(
          'إجمالي الأدوية',
          '${medicines.length}',
          Colors.blue,
          Icons.assignment,
        ),
        const SizedBox(width: 15),
        _statCard('تم تناوله', '0', Colors.green, Icons.check_circle),
        const SizedBox(width: 15),
        _statCard(
          'في الانتظار',
          '${medicines.length}',
          Colors.orange,
          Icons.access_time,
        ),
        const SizedBox(width: 15),
        _statCard('فائت', '0', Colors.red, Icons.warning),
      ],
    );
  }

  Widget _statCard(String t, String v, Color c, IconData i) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(i, color: c.withOpacity(0.3), size: 35),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  t,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  v,
                  style: TextStyle(
                    color: c,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrecautionsSection() {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            '🛡️ دليل الاحترازات العامة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.8,
          children: [
            _precBox(
              '1. ضغط الدم',
              '• مدرات البول: صباحاً لتجنب الأرق.\n• تجنب الجريب فروت مع العلاج.',
              Colors.blue,
            ),
            _precBox(
              '2. خمول الغدة',
              '• الثايروكسين: فجراً على الريق.\n• فصل الكالسيوم عنه 4 ساعات.',
              Colors.purple,
            ),
            _precBox(
              '3. السكري',
              '• الميتفورمين: بعد الأكل مباشرة.\n• فحص السكر قبل جرعة الأنسولين.',
              Colors.teal,
            ),
            _precBox(
              '4. سيولة الدم',
              '• الالتزام بنفس الوقت يومياً.\n• مراقبة أي نزيف أو كدمات مفاجئة.',
              Colors.redAccent,
            ),
            _precBox(
              '5. الكوليسترول',
              '• الستاتينات: يفضل تناولها مساءً.\n• تقليل الدهون المشبعة في الأكل.',
              Colors.orange,
            ),
            _precBox(
              '6. الربو',
              '• البخاخ: غسل الفم جيداً بعده.\n• بخاخ الطوارئ متاح دائماً معك.',
              Colors.cyan,
            ),
            _precBox(
              '7. هشاشة العظام',
              '• الكالسيوم: يفضل مع وجبة الطعام.\n• البقاء مستقيماً بعد الجرعة بـ 30د.',
              Colors.brown,
            ),
            _precBox(
              '8. نقص الحديد',
              '• مع فيتامين C لزيادة الامتصاص.\n• تجنب الشاي والقهوة لمدة ساعتين.',
              Colors.pink,
            ),
          ],
        ),
      ],
    );
  }

  Widget _precBox(String t, String d, Color c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border(right: BorderSide(color: c, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            d,
            style: const TextStyle(
              fontSize: 10,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          const Text(
            'بيانات المريض',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _input('اسم المريض', nameController),
          _input('اكتب اسم الدواء', medNameController),
          _input('مثال: حبة واحدة - 500 ملغ', doseController),
          // خانة اختيار الوقت (Time Picker)
          InkWell(
            onTap: () => _selectTime(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          // القائمة المنسدلة للحالة المرضية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedDisease,
                hint: const Text(
                  '-- اختر الحالة المرضية --',
                  style: TextStyle(fontSize: 13),
                ),
                isExpanded: true,
                items: diseases
                    .map(
                      (s) => DropdownMenuItem(
                        value: s,
                        child: Text(s, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => selectedDisease = v),
              ),
            ),
          ),
          // ملاحظات الطبيب
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'اكتب تعليمات الطبيب أو ملاحظاتك هنا...',
              hintStyle: const TextStyle(fontSize: 12),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _addMedicine,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C48C),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'إضافة الدواء',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedTable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تحديث مباشر',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                '📅 جدول الأدوية والمراقبة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 30),
          if (medicines.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'لا توجد أدوية مسجلة حالياً',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              itemCount: medicines.length,
              itemBuilder: (context, i) => Card(
                color: Colors.teal[50],
                child: ListTile(
                  leading: const Icon(
                    Icons.medication,
                    color: Color(0xFF00C48C),
                  ),
                  title: Text(
                    medicines[i]['med']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('المريض: ${medicines[i]['patient']}'),
                  trailing: Text(
                    medicines[i]['time']!,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _input(String h, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(fontSize: 13),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
