import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class TeryaqiException implements Exception {
  TeryaqiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// عميل REST يطابق واجهات PHP في `Teryaqi-main/api/`.
class TeryaqiApi {
  TeryaqiApi(this.baseUrl);

  String baseUrl;

  static const _timeout = Duration(seconds: 25);

  Uri _uri(String path) {
    final b = baseUrl.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$b$path');
  }

  String _networkHint() {
    final u = baseUrl.replaceAll(RegExp(r'/$'), '');
    return 'لم يصل أي رد من الخادم ($u).\n'
        'شغّل من مجلد Teryaqi-main: php -S 0.0.0.0:8080\n'
        'على الكمبيوتر جرّب في المتصفح: http://127.0.0.1:8080/health.php\n'
        '(لا تستخدم 10.0.2.2 على ويندوز — هذا للمحاكي فقط.)';
  }

  Never _throwNetwork() {
    throw TeryaqiException(_networkHint());
  }

  /// يحوّل أي فشل من [package:http] (بما فيها ClientException + SocketException داخلها) إلى [TeryaqiException].
  Never _mapAnyIoError(Object e) {
    if (e is TeryaqiException) throw e;
    if (e is SocketException ||
        e is TimeoutException ||
        e is http.ClientException ||
        e is HandshakeException) {
      _throwNetwork();
    }
    final s = e.toString().toLowerCase();
    if (s.contains('socketexception') ||
        s.contains('clientexception') ||
        s.contains('connection timed out') ||
        s.contains('connection refused') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable')) {
      _throwNetwork();
    }
    throw TeryaqiException('خطأ غير متوقع: $e');
  }

  Future<http.Response> _postJson(String path, String body) async {
    try {
      return await http
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: body,
          )
          .timeout(_timeout);
    } catch (e) {
      _mapAnyIoError(e);
    }
  }

  Future<http.Response> _get(String path) async {
    try {
      return await http.get(_uri(path)).timeout(_timeout);
    } catch (e) {
      _mapAnyIoError(e);
    }
  }

  dynamic _decode(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  String _errorMessage(dynamic decoded, String fallback) {
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
    return fallback;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _postJson(
      '/api/patients/login.php',
      jsonEncode({'email': email, 'password': password}),
    );
    final decoded = _decode(r.body);
    if (r.statusCode != 200) {
      throw TeryaqiException(_errorMessage(decoded, 'فشل تسجيل الدخول'));
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<Map<String, dynamic>> register({
    required String fullName,
    required String nationalId,
    required String email,
    required String password,
    required String gender,
    String? dateOfBirth,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'national_id': nationalId,
      'email': email,
      'password': password,
      'gender': gender,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'date_of_birth': dateOfBirth,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final r = await _postJson('/api/patients/register.php', jsonEncode(body));
    final decoded = _decode(r.body);
    if (r.statusCode != 201) {
      throw TeryaqiException(_errorMessage(decoded, 'فشل إنشاء الحساب'));
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<List<Map<String, dynamic>>> getMedications(int patientId) async {
    final r = await _get('/api/medications/get_for_patient.php?patient_id=$patientId');
    final decoded = _decode(r.body);
    if (r.statusCode != 200) {
      throw TeryaqiException(_errorMessage(decoded, 'تعذر جلب الأدوية'));
    }
    if (decoded is! List) {
      throw TeryaqiException('استجابة غير متوقعة');
    }
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<int> createMedication({
    required String name,
    String dosageForm = 'Tablet',
    String strength = '',
    String description = '',
  }) async {
    final r = await _postJson(
      '/api/medications/create_medications.php',
      jsonEncode({
        'medication_name': name,
        'dosage_form': dosageForm,
        'strength': strength,
        'description': description,
      }),
    );
    final decoded = _decode(r.body);
    if (r.statusCode != 201) {
      throw TeryaqiException(_errorMessage(decoded, 'تعذر إنشاء الدواء'));
    }
    final map = Map<String, dynamic>.from(decoded as Map);
    final id = map['medication_id'];
    if (id is int) return id;
    if (id is String) return int.parse(id);
    throw TeryaqiException('لا يوجد medication_id');
  }

  Future<int> addForPatient({
    required int patientId,
    required int medicationId,
    required String dosageAmount,
    String instructions = '',
    String? startDate,
  }) async {
    final r = await _postJson(
      '/api/medications/add_for_patient.php',
      jsonEncode({
        'patient_id': patientId,
        'medication_id': medicationId,
        'dosage_amount': dosageAmount,
        'instructions': instructions,
        if (startDate != null) 'start_date': startDate,
      }),
    );
    final decoded = _decode(r.body);
    if (r.statusCode != 201) {
      throw TeryaqiException(_errorMessage(decoded, 'تعذر ربط الدواء بالمريض'));
    }
    final map = Map<String, dynamic>.from(decoded as Map);
    final id = map['patient_medication_id'];
    if (id is int) return id;
    if (id is String) return int.parse(id);
    throw TeryaqiException('لا يوجد patient_medication_id');
  }

  Future<void> addSchedule({
    required int patientMedicationId,
    required String intakeTime,
    int frequencyPerDay = 1,
  }) async {
    var t = intakeTime;
    if (t.length == 5) t = '$t:00';
    final r = await _postJson(
      '/api/medications/add_schedule.php',
      jsonEncode({
        'patient_medication_id': patientMedicationId,
        'intake_time': t,
        'frequency_per_day': frequencyPerDay,
      }),
    );
    final decoded = _decode(r.body);
    if (r.statusCode != 201) {
      throw TeryaqiException(_errorMessage(decoded, 'تعذر حفظ وقت الجرعة'));
    }
  }
}
