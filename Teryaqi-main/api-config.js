(function () {
  try {
    // نفس منفذ الصفحة والخادم — لا حاجة لإدخال عنوان يدوياً
    var o = window.location && window.location.origin;
    window.TERYAQI_API_BASE = o && o !== 'null' ? o : 'http://localhost:8080';
  } catch (e) {
    window.TERYAQI_API_BASE = 'http://localhost:8080';
  }
})();
