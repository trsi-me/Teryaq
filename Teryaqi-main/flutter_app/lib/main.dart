import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/teryaqi_api.dart';
import 'config/api_config.dart';

void main() => runApp(const TeriaqiApp());

class TeriaqiApp extends StatelessWidget {
  const TeriaqiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ترياقي',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF065F46)),
      ),
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
  static const _kApiBase = 'teryaqi_api_base';
  static const _kPatientId = 'teryaqi_patient_id';
  static const _kFullName = 'teryaqi_full_name';

  String _apiBase = defaultApiBaseUrl();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _regFullNameController = TextEditingController();
  final _regNationalIdController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPhoneController = TextEditingController();
  final _regDobController = TextEditingController();

  final _medNameController = TextEditingController();
  final _doseController = TextEditingController();
  final _noteController = TextEditingController();

  String? _regGender;
  String? _selectedDisease;
  TimeOfDay _selectedTime = TimeOfDay.now();

  int? _patientId;
  String? _fullName;
  List<Map<String, dynamic>> _medicines = [];
  bool _busy = false;
  bool _prefsLoaded = false;

  final List<String> _diseases = const [
    'مرض ضغط الدم',
    'خمول الغدة الدرقية',
    'هشاشة العظام',
    'ارتفاع الكوليسترول',
    'أمراض سيولة الدم',
    'المرض السكري النوع الثاني',
    'أخرى / عام',
  ];

  TeryaqiApi get _api => TeryaqiApi(_apiBase.trim());

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    // محاكي/جهاز أندرويد: ثابت في الكود (لا يُستبدل بقيمة قديمة من التخزين).
    if (defaultTargetPlatform == TargetPlatform.android) {
      _apiBase = defaultApiBaseUrl();
      await p.setString(_kApiBase, _apiBase);
    } else {
      _apiBase = p.getString(_kApiBase) ?? defaultApiBaseUrl();
    }
    final id = p.getInt(_kPatientId);
    _fullName = p.getString(_kFullName);
    setState(() {
      _patientId = id;
      _prefsLoaded = true;
    });
    if (id != null) {
      await _refreshMedicines();
    }
  }

  Future<void> _persistSession() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kApiBase, _apiBase.trim());
    if (_patientId != null) {
      await p.setInt(_kPatientId, _patientId!);
      if (_fullName != null) await p.setString(_kFullName, _fullName!);
    } else {
      await p.remove(_kPatientId);
      await p.remove(_kFullName);
    }
  }

  Future<void> _refreshMedicines() async {
    final id = _patientId;
    if (id == null) {
      setState(() => _medicines = []);
      return;
    }
    setState(() => _busy = true);
    try {
      final list = await _api.getMedications(id);
      if (mounted) setState(() => _medicines = list);
    } on TeryaqiException catch (e) {
      if (mounted) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _login() async {
    final email = _loginEmailController.text.trim();
    final password = _loginPasswordController.text;
    if (email.isEmpty || password.isEmpty) {
      _snack('أدخل البريد وكلمة المرور');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await _api.login(email, password);
      final pid = data['patient_id'];
      final name = data['full_name']?.toString();
      setState(() {
        _patientId = pid is int ? pid : int.parse(pid.toString());
        _fullName = name;
      });
      _loginPasswordController.clear();
      await _persistSession();
      await _refreshMedicines();
    } on TeryaqiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _register() async {
    if (_regGender == null || _regGender!.isEmpty) {
      _snack('اختر الجنس');
      return;
    }
    setState(() => _busy = true);
    try {
      final data = await _api.register(
        fullName: _regFullNameController.text.trim(),
        nationalId: _regNationalIdController.text.trim(),
        email: _regEmailController.text.trim(),
        password: _regPasswordController.text,
        gender: _regGender!,
        dateOfBirth: _regDobController.text.trim().isEmpty ? null : _regDobController.text.trim(),
        phone: _regPhoneController.text.trim().isEmpty ? null : _regPhoneController.text.trim(),
      );
      final pid = data['patient_id'];
      setState(() {
        _patientId = pid is int ? pid : int.parse(pid.toString());
        _fullName = _regFullNameController.text.trim();
      });
      await _persistSession();
      await _refreshMedicines();
      _regPasswordController.clear();
      _snack('تم إنشاء الحساب وتسجيل الدخول');
    } on TeryaqiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    setState(() {
      _patientId = null;
      _fullName = null;
      _medicines = [];
    });
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPatientId);
    await p.remove(_kFullName);
    await p.setString(_kApiBase, _apiBase.trim());
  }

  Future<void> _addMedicine() async {
    final pid = _patientId;
    if (pid == null) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    final name = _medNameController.text.trim();
    final dose = _doseController.text.trim();
    if (name.isEmpty || dose.isEmpty) {
      _snack('أدخل اسم الدواء والجرعة');
      return;
    }
    final disease = _selectedDisease ?? '';
    final notes = _noteController.text.trim();
    final instructions = [
      if (disease.isNotEmpty) 'الحالة: $disease',
      if (notes.isNotEmpty) notes,
    ].join('\n');

    setState(() => _busy = true);
    try {
      final medId = await _api.createMedication(
        name: name,
        description: instructions,
      );
      final today = DateTime.now().toIso8601String().split('T').first;
      final pmId = await _api.addForPatient(
        patientId: pid,
        medicationId: medId,
        dosageAmount: dose,
        instructions: instructions,
        startDate: today,
      );
      final t = _selectedTime;
      final hh = t.hour.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      await _api.addSchedule(
        patientMedicationId: pmId,
        intakeTime: '$hh:$mm',
      );
      _medNameController.clear();
      _doseController.clear();
      _noteController.clear();
      setState(() => _selectedDisease = null);
      await _refreshMedicines();
      _snack('تم حفظ الدواء');
    } on TeryaqiException catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatIntake(dynamic t) {
    if (t == null) return '—';
    final s = t.toString();
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regFullNameController.dispose();
    _regNationalIdController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regPhoneController.dispose();
    _regDobController.dispose();
    _medNameController.dispose();
    _doseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFF065F46),
        body: Stack(
          children: [
            SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildAuthCard(),
                  const SizedBox(height: 16),
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, c) {
                      final narrow = c.maxWidth < 900;
                      if (narrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildPatientForm(),
                            const SizedBox(height: 24),
                            _buildPrecautionsSection(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildPrecautionsSection()),
                          const SizedBox(width: 25),
                          Expanded(flex: 1, child: _buildPatientForm()),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  _buildMedTable(),
                ],
              ),
            ),
            if (_busy)
              const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Color(0xFF00C48C),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Card(
      color: Colors.white.withValues(alpha: 0.95),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'تسجيل الدخول',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final narrow = c.maxWidth < 420;
                final email = TextField(
                  controller: _loginEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'البريد',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                );
                final password = TextField(
                  controller: _loginPasswordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (!_busy) _login();
                  },
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                );
                final actions = Row(
                  children: [
                    FilledButton(
                      onPressed: _busy ? null : _login,
                      child: const Text('دخول'),
                    ),
                    const SizedBox(width: 8),
                    if (_patientId != null)
                      OutlinedButton(
                        onPressed: _busy ? null : _logout,
                        child: const Text('خروج'),
                      ),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      email,
                      const SizedBox(height: 8),
                      password,
                      const SizedBox(height: 12),
                      actions,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: email),
                        const SizedBox(width: 8),
                        Expanded(child: password),
                      ],
                    ),
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              },
            ),
            Text(
              _patientId != null
                  ? 'مسجّل: ${_fullName ?? "مريض"} (رقم $_patientId)'
                  : 'غير مسجّل — سجّل الدخول لحفظ الأدوية على الخادم.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('إنشاء حساب مريض جديد'),
              children: [
                TextField(
                  controller: _regFullNameController,
                  decoration: const InputDecoration(labelText: 'الاسم الكامل'),
                ),
                TextField(
                  controller: _regNationalIdController,
                  decoration: const InputDecoration(labelText: 'رقم الهوية (فريد)'),
                ),
                TextField(
                  controller: _regEmailController,
                  decoration: const InputDecoration(labelText: 'البريد'),
                ),
                TextField(
                  controller: _regPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                ),
                DropdownButtonFormField<String>(
                  value: _regGender,
                  hint: const Text('الجنس'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('ذكر')),
                    DropdownMenuItem(value: 'Female', child: Text('أنثى')),
                  ],
                  onChanged: (v) => setState(() => _regGender = v),
                ),
                TextField(
                  controller: _regDobController,
                  decoration: const InputDecoration(
                    labelText: 'تاريخ الميلاد (اختياري)',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                TextField(
                  controller: _regPhoneController,
                  decoration: const InputDecoration(labelText: 'الجوال (اختياري)'),
                ),
                FilledButton.tonal(
                  onPressed: _busy ? null : _register,
                  child: const Text('تسجيل'),
                ),
              ],
            ),
          ],
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
    final n = _medicines.length;
    final cards = <Widget>[
      _statCard('إجمالي الأدوية', '$n', Colors.blue, Icons.assignment),
      _statCard('تم تناوله', '0', Colors.green, Icons.check_circle),
      _statCard('في الانتظار', '$n', Colors.orange, Icons.access_time),
      _statCard('فائت', '0', Colors.red, Icons.warning),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 15),
            Expanded(child: cards[1]),
            const SizedBox(width: 15),
            Expanded(child: cards[2]),
            const SizedBox(width: 15),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }

  Widget _statCard(String t, String v, Color c, IconData i) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(i, color: c.withValues(alpha: 0.35), size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
                Text(
                  v,
                  style: TextStyle(
                    color: c,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.75,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: c,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d,
            style: const TextStyle(
              fontSize: 10,
              height: 1.35,
              color: Colors.black87,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientForm() {
    final locked = _patientId == null;
    return Opacity(
      opacity: locked ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          children: [
            Text(
              locked ? 'بيانات الدواء (يتطلب تسجيل الدخول)' : 'بيانات الدواء',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _medNameController,
              enabled: !locked && !_busy,
              decoration: const InputDecoration(
                hintText: 'اكتب اسم الدواء',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doseController,
              enabled: !locked && !_busy,
              decoration: const InputDecoration(
                hintText: 'مثال: حبة واحدة - 500 ملغ',
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: locked || _busy ? null : _pickTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedTime.format(context),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedDisease,
              hint: const Text('-- اختر الحالة المرضية --', style: TextStyle(fontSize: 13)),
              isExpanded: true,
              items: _diseases
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: locked || _busy ? null : (v) => setState(() => _selectedDisease = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              enabled: !locked && !_busy,
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
              onPressed: locked || _busy ? null : _addMedicine,
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
          if (_medicines.isEmpty)
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
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medicines.length,
              itemBuilder: (context, i) {
                final m = _medicines[i];
                final name = m['medication_name']?.toString() ?? '';
                final dose = m['dosage_amount']?.toString() ?? '';
                final inst = m['instructions']?.toString() ?? '';
                final time = _formatIntake(m['intake_time']);
                return Card(
                  color: Colors.teal[50],
                  child: ListTile(
                    leading: const Icon(Icons.medication, color: Color(0xFF00C48C)),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      dose + (inst.isNotEmpty ? '\n$inst' : ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: inst.length > 40,
                    trailing: Text(
                      time,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
