# تِرياقي

## 1. ما هو المشروع؟

تطبيق دواء اسمه تِرياقي. المجلد الخارجي `Teryaq` يحتوي مجلد العمل `Teryaqi-main` فقط. داخله واجهة ويب (`index.html` و `script.js`) وواجهة PHP تتصل بـ MySQL، وتطبيق Flutter اسم الحزمة `teryaqi_app`.

ملف `Teryaqi-main/README.md` يذكر فريق العمل. ملف `README_SETUP_AND_CHANGES.md` يشرح الربط والتشغيل. التطبيق الذي يُشغَّل هو ما في `Teryaqi-main` لا ملفًا في جذر `Teryaq`.

## 2. لماذا يوجد هذا المشروع؟

الجداول تغطي مريضًا وأمراضًا مزمنة وأدوية وجدولة جرعات وسجل حساس إشعارات، وحقول علبة دواء على جدول المريض (`box_serial_number` و `box_status`). الواجهة الحالية للويب وFlutter، حسب دليل الإعداد، تسجّل المريض وتضيف دواءً وجدولة. العتاد مذكور كتوزيع مهام في README الفريق لا كمشروع مضمن داخل هذا المجلد.

## 3. من يستخدمه؟

| الطرف | في الملفات |
| --- | --- |
| مريض | تسجيل ودخول في `api/patients` ثم أدويته |
| الواجهة الويب | `index.html` |
| تطبيق الجوال | `flutter_app` الحزمة `teryaqi_app` |
| فريق موثق في `Teryaqi-main/README.md` | اجواد الغامدي (قيادة وعتاد)، زهراء بخيت (واجهة ويب)، لمى الحربي (قاعدة)، دانة الحربي وهلا الشهراني (جوال)، رحيل البقمي وشدا عسيري (خادم) |

لا أدوار صلاحيات متعددة داخل الجداول. الحساب هو المريض.

## 4. ماذا يستطيع النظام أن يفعل؟

| القدرة | المسار |
| --- | --- |
| تسجيل مريض | `api/patients/register.php` |
| دخول | `api/patients/login.php` |
| ملف المريض | `api/patients/get_profile.php` |
| إنشاء دواء أساسي | `api/medications/create_medications.php` |
| كل الأدوية | `api/medications/get_all.php` |
| ربط دواء بمريض | `api/medications/add_for_patient.php` |
| أدوية المريض | `api/medications/get_for_patient.php` |
| جدولة جرعة | `api/medications/add_schedule.php` |
| فحص أن PHP يعمل | `health.php` يعيد JSON فيه `ok` وإصدار PHP |
| عتاد/حساس في الكود | الصنف `Sensor` في `includes/sensor.php` دوال `logIntake` و `getNotifications` |

دليل الإعداد يقول مسار الإضافة: إنشاء دواء، ثم ربطه بالمريض، ثم جدولة وقت الجرعة.

أشكال الدواء في SQL: `Tablet` و `Capsule` و `Syrup`. الجنس: `Male` أو `Female`. حالة العلبة: `Active` أو `Inactive`. حالة التناول في السجل: `Taken` أو `Missed`. حالة الإشعار: `Sent` أو `Read` أو `Ignored`.

## 5. كيف يعمل النظام؟

```
المتصفح index.html
  -> api-config.js يضع TERYAQI_API_BASE = أصل الصفحة
  -> script.js
  -> PHP في api/
  -> includes/patient.php أو medication.php
  -> config/database.php
  -> MySQL smart_medicine

Flutter flutter_app/lib/main.dart
  -> lib/api (عميل HTTP حسب دليل الإعداد)
  -> نفس PHP
  -> لا يتصل Flutter بـ MySQL مباشرة
```

`main.dart` في جذر `Teryaqi-main` قديم حسب دليل الإعداد. التطبيق الحالي تحت `flutter_app/lib/main.dart`.

## 6. أمثلة واقعية

### حساب جديد

1. الواجهة تجمع الحقول ومنها الجنس ورقم الهوية.
2. `POST` إلى `api/patients/register.php`.
3. `Patient::register` يخزّن كلمة المرور بـ `password_hash` وخوارزمية `PASSWORD_BCRYPT`.
4. الاستجابة تعيد `patient_id` حسب دليل الإعداد.
5. الويب يحفظ المعرّف في `localStorage`، وFlutter في `shared_preferences`.

### دخول

1. `api/patients/login.php`.
2. `Patient::login` يستخدم `password_verify`.
3. عند النجاح تُستخدم الجلسة المحلية في الواجهة لطلبات الأدوية.

### إضافة دواء

1. `create_medications.php` ينشئ صف `MEDICATIONS` عبر `createBaseMedication`.
2. `add_for_patient.php` ينشئ `PATIENT_MEDICATIONS`.
3. `add_schedule.php` يستدعي `createSchedule` ويكتب `MEDICATION_SCHEDULE` (`intake_time` و `frequency_per_day`).
4. `get_for_patient.php` يعيد القائمة، وقائمة فارغة بحالة 200 إذا لا أدوية، حسب دليل الإعداد.

## 7. رحلة المستخدم

1. تشغيل PHP من `Teryaqi-main` ثم فتح `http://localhost:8080/index.html`، أو تشغيل Flutter.
2. إنشاء حساب أو دخول.
3. حفظ `patient_id` محليًا.
4. إضافة دواء ثم ربط ثم جدولة.
5. جلب قائمة الأدوية.
6. الخروج من الواجهة يمسح الجلسة المحلية. لا جدول جلسات على الخادم في الملفات المقروءة.

## 8. الوحدات والأقسام

| الوحدة | الملفات | الوظيفة |
| --- | --- | --- |
| ويب | `index.html` `style.css` `script.js` `api-config.js` | حساب وأدوية |
| مرضى | `api/patients/*` `includes/patient.php` | تسجيل ودخول وملف ورمز FCM وعلبة |
| أدوية | `api/medications/*` `includes/medication.php` | الكتالوج والربط والجدول |
| حساس | `includes/sensor.php` | تسجيل تناول وإشعارات. لا مجلد `api` باسم sensor في الشجرة |
| قاعدة | `database_setup.sql` `config/database.php` | جداول واتصال |
| جوال | `flutter_app/` | نفس العمليات عبر HTTP |
| تشغيل | `start-php-server.bat` `health.php` | خادم وفحص |

## 9. الشركات والكيانات

غير موجود في الملفات الحالية. مستخدم النظام هو المريض.

## 10. الصلاحيات

لا أدوار. من يملك `patient_id` بعد الدخول يطلب أدويته. دليل الإعداد يذكر التحقق من `patient_id` في جلب الأدوية. لا لوحة مدير.

## 11. الأتمتة وWorkflows

غير موجود كمجدول. جدول `NOTIFICATIONS` وحقل `fcm_token` موجودان. إرسال Firebase الفعلي غير موثق كملف خدمة في الشجرة الحالية. الصنف `Sensor` يستطيع تسجيل `Taken` أو `Missed` إذا استُدعيت دواله.

## 12. التكامل بين الوحدات

المريض في `PATIENTS`. الأمراض عبر `PATIENT_DISEASES` نحو `CHRONIC_DISEASES`. الدواء العام في `MEDICATIONS` ثم الربط في `PATIENT_MEDICATIONS` ثم `MEDICATION_SCHEDULE`. `SENSOR_LOGS` يرتبط بالمريض والجدولة. `NOTIFICATIONS` يرتبط بالمريض والجدولة. الويب وFlutter يشاركان نفس PHP.

## 13. المصطلحات

| المصطلح | المعنى |
| --- | --- |
| تِرياقي / Teryaqi | اسم المنتج في ملفات README |
| `smart_medicine` | اسم القاعدة في `database_setup.sql` |
| `patient_id` | مفتاح المريض ويُخزَّن في الواجهة بعد الدخول |
| علبة الدواء | أعمدة `box_*` داخل `PATIENTS` لا جدول علبة منفصل |
| `TERYAQI_API_BASE` | أصل عنوان الواجهة في المتصفح، أو `--dart-define` في Flutter |

## 14. الأسئلة الشائعة

**أين أشغّل الأوامر؟**  
من `Teryaq/Teryaqi-main` لا من المجلد الأب الفارغ إلا للدخول إلى المجلد الداخلي.

**هل أفتح index.html بالنقر المزدوج؟**  
دليل الإعداد يقول لا. العنوان لازم يكون خادم PHP حتى يُبنى عنوان API من `window.location.origin`.

**لماذا المحاكي لا يصل؟**  
دليل الإعداد: Android يستخدم `http://10.0.2.2:8080` إذا استمع PHP على `0.0.0.0`. `health.php` مذكور لهذا الفحص.

**ما وصف حزمة Flutter؟**  
`pubspec.yaml` يقول `A new Flutter project.` وهذا وصف القالب. سلوك الدواء موثق في دليل الإعداد وملفات `lib`.

## 15. المعمارية

```
Teryaq/
  Teryaqi-main/
     index.html + script.js
     flutter_app/lib/main.dart
            |
            v
     api/patients  api/medications
            |
            v
     includes/*.php
            |
            v
     MySQL smart_medicine
```

## 16. التقنيات

| الجزء | التقنية |
| --- | --- |
| ويب | HTML و CSS و JavaScript |
| خادم | PHP و PDO |
| قاعدة | MySQL، الجداول بحروف كبيرة في SQL |
| جوال | Flutter، SDK في pubspec `^3.8.1`، الحزم `http` ^1.2.2 و `shared_preferences` ^2.3.3 و `cupertino_icons` |
| المنصات داخل flutter_app | android و ios و web و windows و linux و macos |

إصدار الحزمة في pubspec: `1.0.0+1`. لا يُغيَّر من هذا التوثيق.

## 17. هيكل المشروع

```
Teryaq/
  README.md                  <- هذا الملف في الجذر الخارجي
  Teryaqi-main/
    index.html script.js style.css api-config.js
    health.php start-php-server.bat main.dart   (الجذر قديم)
    database_setup.sql
    config/database.php
    api/patients/  api/medications/
    includes/patient.php medication.php sensor.php
    flutter_app/
      pubspec.yaml
      lib/main.dart
      android ios web windows linux macos test
    README.md
    README_SETUP_AND_CHANGES.md
```

دليل الإعداد يذكر `flutter_app/lib/api/` و `lib/config/api_config.dart`. الشجرة المختصرة عند الفحص أظهرت `lib/main.dart` حتى عمق العرض. إن غاب مجلد `lib/api` عن نسختك فالعميل موثق في دليل الإعداد كملفات مضافة؛ تحقق من المجلد قبل الاعتماد على المسار.

## 18. الواجهة

الويب: صفحة `index.html` مع `script.js` و `style.css`. العنوان يُشتق في `api-config.js` من أصل الصفحة، والاحتياط `http://localhost:8080`. دليل الإعداد: نموذج واحد، والحساب في الهيدر (دخول وخروج وحساب جديد).

Flutter: `lib/main.dart` لوحة مع مصادقة وجلسة وأدوية حسب الدليل. `publish_to: none`.

أيقونة ويب Flutter: `flutter_app/web/favicon.png`. أيقونة تبويب لـ `index.html` في جذر PHP غير مؤكدة في هذا الفحص.

## 19. الخادم

الأصناف:

- `Patient`: `register` و `login` و `getProfile` و `updateFcmToken` و `updateBoxInfo`.
- `Medication`: `addForPatient` و `getForPatient` و `createSchedule` و `getTodaySchedules` و `createBaseMedication` و `getAllMedications`.
- `Sensor`: `logIntake` و `getNotifications`.

`health.php` لا يفتح MySQL. يعيد إصدار PHP في JSON مع CORS `*`.

## 20. مسار الطلب

```
المتصفح على :8080/index.html
  -> TERYAQI_API_BASE = origin
  -> POST api/patients/login.php
  -> Patient::login
  -> password_verify
  -> patient_id إلى localStorage
  -> GET/POST api/medications/*
  -> JSON إلى الصفحة
```

Flutter يعيد نفس السلسلة بعنوان منصة مختلف.

## 21. قاعدة البيانات

`database_setup.sql` ينشئ `smart_medicine`.

| الجدول | مفاتيح وعلاقات |
| --- | --- |
| `PATIENTS` | `patient_id`، `national_id` فريد، `email` فريد، كلمة مرور مجزأة، حقول العلبة، `fcm_token` |
| `CHRONIC_DISEASES` | `disease_id` |
| `PATIENT_DISEASES` | مفتاحان أجنبيان مع حذف متسلسل |
| `MEDICATIONS` | `medication_id` |
| `PATIENT_MEDICATIONS` | مريض ودواء |
| `MEDICATION_SCHEDULE` | `intake_time` و `frequency_per_day` |
| `SENSOR_LOGS` | مريض وجدولة، `taken_status` |
| `NOTIFICATIONS` | مريض وجدولة |

الاتصال في `config/database.php` (المضيف واسم القاعدة والمستخدم). دليل الإعداد يطلب ضبطها لتطابق `smart_medicine`. لا تُنسخ كلمات مرور من ذلك الملف هنا.

## 22. واجهة البرمجة

| الطريقة المتوقعة من الاستخدام | المسار | الغرض | مصادقة |
| --- | --- | --- | --- |
| POST | `api/patients/register.php` | تسجيل، يعيد `patient_id` | لا |
| POST | `api/patients/login.php` | دخول | لا |
| طلب ملف | `api/patients/get_profile.php` | ملف | `patient_id` |
| POST | `api/medications/create_medications.php` | دواء أساسي | غير موثق كجلسة خادم |
| طلب | `api/medications/get_all.php` | قائمة الأدوية | غير موثق |
| POST | `api/medications/add_for_patient.php` | ربط | معرفات المريض والدواء |
| طلب | `api/medications/get_for_patient.php` | أدوية المريض | `patient_id` |
| POST | `api/medications/add_schedule.php` | جدولة | معرف الربط والوقت |
| GET | `health.php` | فحص PHP | لا |

دليل الإعداد يذكر دعم `OPTIONS` للـ CORS في التسجيل والدخول وإنشاء الدواء والربط والجدولة.

## 23. المصادقة والصلاحيات

كلمة المرور bcrypt في العمود `password`. الدخول `password_verify`. المعرّف يُحفظ على الجهاز لا في جلسة PHP موثقة. رقم الهوية والبريد فريدان. الجنس مطلوب بقيم التعداد.

## 24. الأمان

الموجود: تجزئة كلمة المرور، قيود فريدة على الهوية والبريد، مفاتيح أجنبية.

`health.php` يعيد رقم إصدار PHP للعموم مع CORS مفتوح. هذا يكشف تقنية الخادم. لا CSRF موثق. لا حد محاولات دخول في الملفات المقروءة. تطوير أندرويد يسمح بـ HTTP المحلي (`usesCleartextTraffic`) حسب الدليل، وiOS `NSAllowsLocalNetworking`.

## 25. الإعدادات

| المكان | ماذا يضبط |
| --- | --- |
| `config/database.php` | اتصال MySQL |
| `api-config.js` | عنوان API من أصل الصفحة |
| `flutter run --dart-define=TERYAQI_API_BASE=...` | عنوان بديل للجوال |
| `android/local.properties` | مسار Flutter محلي على الجهاز، لا يُنسخ كمحتوى |

لا `.env` في الشجرة المختصرة.

## 26. التكاملات

حقل `fcm_token` جاهز لرمز إشعارات. ملف خدمة Firebase غير ظاهر في شجرة `Teryaqi-main` المفحوصة. غير موثق كإرسال فعّال.

## 27. المهام المجدولة

غير موجود في الملفات الحالية. `getTodaySchedules` دالة قراءة لجدول اليوم إذا استُدعيت.

## 28. تخزين الملفات

لا مجلد رفع أدوية. البيانات في MySQL. صورة لقطة شاشة عربية الاسم موجودة بجانب ملفات `Teryaqi-main`. أيقونة ويب Flutter في `flutter_app/web/favicon.png`.

## 29. السجلات والمراقبة

`SENSOR_LOGS` و `NOTIFICATIONS` جداول. `health.php` فحص يدوي. لا منصة مراقبة.

## 30. التثبيت

1. PHP مع PDO MySQL، وMySQL.
2. نفّذ `Teryaqi-main/database_setup.sql`.
3. اضبط `config/database.php` على `smart_medicine`.
4. من `Teryaqi-main`:

```
php -S 0.0.0.0:8080
```

أو `start-php-server.bat`.

5. افتح `http://localhost:8080/index.html`.
6. للجوال، من `flutter_app`: `flutter pub get` ثم `flutter run`.
7. محاكي أندرويد: `http://10.0.2.2:8080`. سطح المكتب و iOS: `http://127.0.0.1:8080`. ويب Flutter: `http://localhost:8080`. هاتف حقيقي: عنوان IP الجهاز.

## 31. دليل التطوير

- صفحة ويب: عدّل `index.html` و `script.js` واستدعِ مسارًا تحت `api/`.
- مسار جديد: ملف PHP يستعمل الأصناف في `includes`.
- جدول: عدّل `database_setup.sql` ثم الأصناف.
- شاشة Flutter: `flutter_app/lib/main.dart` والعميل بجانبها.
- لا تضف منطق قاعدة داخل Flutter. الدليل يثبت أن الوصول عبر PHP فقط.
- `main.dart` في جذر `Teryaqi-main` ليس مصدر التطبيق الحالي.

## 32. النشر

غير موثق كإنتاج. الإعداد الحالي تطوير محلي على المنفذ 8080 و HTTP واضح للجوال. `health.php` لا يناسب أن يبقى مكشوفًا بإصدار PHP على إنتاج.

## 33. النسخ الاحتياطي

غير موجود كسكربت. صدّر `smart_medicine`.

## 34. استكشاف الأخطاء

| العرض | المطابق للدليل والملفات |
| --- | --- |
| الويب يعمل والمحاكي لا يصل | الخادم على localhost فقط لا على `0.0.0.0` |
| هاتف حقيقي لا يصل | استخدام localhost بدل IP الشبكة |
| خطأ قاعدة | `database.php` أو عدم تنفيذ SQL |
| تسجيل يفشل | هوية أو بريد مكرر، أو جنس خارج `Male`/`Female` |
| لا أدوية وتُعامل كخطأ | الدليل يقول `get_for_patient.php` يعيد `[]` مع 200 |
| تعديل الملف الخطأ | `Teryaqi-main/main.dart` قديم |

## 35. الاعتماديات

Flutter SDK `^3.8.1`. `http` ^1.2.2. `shared_preferences` ^2.3.3. `cupertino_icons` ^1.0.8. PHP PDO MySQL بلا رقم إصدار في المشروع. `pubspec.lock` موجود ويثبت النسخ المحسومة للجهاز الذي ولّده.

## 36. القيود المعروفة

- مجلد خارجي فارغ إلا من `Teryaqi-main`.
- وصف pubspec عام لا يذكر الدواء.
- صنف الحساس بلا مسار `api` ظاهر.
- `health.php` يكشف إصدار PHP.
- إشعارات FCM عمود بلا خدمة ظاهرة.
- لقطة شاشة داخل المجلد ليست توثيقًا تشغيليًا.

## 37. حالة النظام الحالية

| الحالة | التفاصيل |
| --- | --- |
| موجود | ويب، PHP، SQL لثمانية جداول، مشروع Flutter |
| موثق تشغيلًا | `README_SETUP_AND_CHANGES.md` |
| موثق فريقًا | `Teryaqi-main/README.md` |
| غير مكتمل في الشجرة | مسار HTTP للحساس، إرسال FCM |
| قديم | `Teryaqi-main/main.dart` في الجذر |

## 38. القرارات المعمارية

استنتاج من الكود ومن دليل الإعداد: قاعدة MySQL لا تُفتح من Flutter. PHP هو الباب. علبة الدواء أعمدة في `PATIENTS` بعد أن كان التصميم يشير إلى صندوق منفصل (تعليق SQL: الربط بـ `patient_id` بدل `box_id`). كلمة المرور تُجزأ في `register` لا تُخزَّن كما كُتبت.

## 39. سجل التغييرات

لا ملف إصدارات مستقل. `README_SETUP_AND_CHANGES.md` هو سجل التعديلات المعتمد: ربط الويب بالـ API، إرجاع قائمة فارغة، `patient_id` بعد التسجيل، مسار `add_schedule.php`، حقل `intake_time` في الجلب، CORS لطلبات OPTIONS، وإنشاء `flutter_app`. إصدار الحزمة `1.0.0+1` في pubspec.

## System Overview

```
مريض
  -> ويب :8080 أو Flutter
        |
        v
  PHP api/patients + api/medications
        |
        v
  MySQL smart_medicine
     PATIENTS  MEDICATIONS  SCHEDULE
     DISEASES  SENSOR_LOGS  NOTIFICATIONS
```

## Quick Reference

| الجزء | التقنية | الموقع | الوظيفة |
| --- | --- | --- | --- |
| ويب | HTML/JS | `Teryaqi-main/index.html` | الواجهة |
| عنوان API | JS | `api-config.js` | أصل الصفحة |
| مرضى | PHP | `api/patients/` | حساب |
| أدوية | PHP | `api/medications/` | كتالوج وجدولة |
| منطق | PHP | `includes/` | أصناف |
| قاعدة | SQL | `database_setup.sql` | `smart_medicine` |
| جوال | Flutter | `flutter_app/` | نفس API |
| فحص | PHP | `health.php` | PHP يعمل |

## Quick Start

من `Teryaqi-main` بعد استيراد SQL وضبط الاتصال:

```
php -S 0.0.0.0:8080
```

ثم `http://localhost:8080/index.html`.

## For Non-Technical Users

- ما هو النظام؟ تِرياقي لمتابعة أدوية المريض.
- ماذا يفعل؟ إنشاء حساب، دخول، إضافة دواء ووقت جرعة، وعرض الأدوية.
- كيف يُستخدم؟ فتح صفحة الموقع بعد تشغيل البرنامج، أو تطبيق الجوال المرتبط بنفس الخادم.
- أهم الأقسام: الحساب، الأدوية، الجدولة. العتاد مذكور كمهمة فريق ولم يُعرض كشاشة مستقلة في الملفات المفحوصة.
- التطبيق داخل مجلد `Teryaqi-main`.

## For Developers

- التقنيات: PHP و MySQL و JavaScript و Flutter.
- المعمارية: عميلان على API واحدة.
- قاعدة البيانات: `smart_medicine` والجداول الثمانية بحروف كبيرة.
- API: مجلدات `api/patients` و `api/medications`.
- أهم الملفات: `config/database.php`، `includes/patient.php`، `includes/medication.php`، `script.js`، `flutter_app/lib/main.dart`، `database_setup.sql`.
- لا تطوّر على `Teryaqi-main/main.dart` القديم. كلمة المرور bcrypt. لا تنسخ أسرار الاتصال إلى التوثيق.
