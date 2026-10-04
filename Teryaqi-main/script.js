const LS_PATIENT = 'teryaqi_patient_id';
const LS_NAME = 'teryaqi_full_name';

function apiUrl(path) {
  const base = (typeof window.TERYAQI_API_BASE === 'string' ? window.TERYAQI_API_BASE : 'http://localhost:8080').replace(/\/$/, '');
  return base + path;
}

function getPatientId() {
  try {
    const v = localStorage.getItem(LS_PATIENT);
    return v ? parseInt(v, 10) : null;
  } catch (e) {
    return null;
  }
}

function setSession(patientId, fullName) {
  if (patientId) localStorage.setItem(LS_PATIENT, String(patientId));
  else localStorage.removeItem(LS_PATIENT);
  if (fullName) localStorage.setItem(LS_NAME, fullName);
  else localStorage.removeItem(LS_NAME);
  updateAuthUi();
}

function updateAuthUi() {
  const id = getPatientId();
  const name = localStorage.getItem(LS_NAME) || '';
  const statusEl = document.getElementById('auth-status');
  const outBtn = document.getElementById('btn-logout');
  const formBlock = document.getElementById('medicine-form');
  if (statusEl) {
    statusEl.textContent = id
      ? 'مسجّل: ' + (name || 'مريض #' + id)
      : 'سجّل الدخول لحفظ الأدوية.';
  }
  if (outBtn) outBtn.style.display = id ? 'inline-block' : 'none';
  if (formBlock) {
    formBlock.querySelectorAll('input, select, textarea, button').forEach(function (el) {
      el.disabled = !id;
    });
  }
}

async function parseJson(res) {
  const text = await res.text();
  try {
    return text ? JSON.parse(text) : {};
  } catch (e) {
    return { message: text || 'استجابة غير صالحة' };
  }
}

async function apiLogin(email, password) {
  const res = await fetch(apiUrl('/api/patients/login.php'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: email, password: password }),
  });
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'فشل تسجيل الدخول');
  return data;
}

async function apiRegister(body) {
  const res = await fetch(apiUrl('/api/patients/register.php'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'فشل إنشاء الحساب');
  return data;
}

async function apiListMedications(patientId) {
  const res = await fetch(apiUrl('/api/medications/get_for_patient.php?patient_id=' + encodeURIComponent(patientId)));
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'تعذر جلب الأدوية');
  return Array.isArray(data) ? data : [];
}

async function apiCreateMedication(name, dosageForm, strength, description) {
  const res = await fetch(apiUrl('/api/medications/create_medications.php'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      medication_name: name,
      dosage_form: dosageForm,
      strength: strength || '',
      description: description || '',
    }),
  });
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'تعذر إنشاء الدواء');
  return data.medication_id;
}

async function apiAddForPatient(patientId, medicationId, dosageAmount, instructions, startDate) {
  const res = await fetch(apiUrl('/api/medications/add_for_patient.php'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      patient_id: patientId,
      medication_id: medicationId,
      dosage_amount: dosageAmount,
      start_date: startDate || undefined,
      instructions: instructions || '',
    }),
  });
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'تعذر ربط الدواء بالمريض');
  return data.patient_medication_id;
}

async function apiAddSchedule(patientMedicationId, intakeTime) {
  const t = intakeTime.length === 5 ? intakeTime + ':00' : intakeTime;
  const res = await fetch(apiUrl('/api/medications/add_schedule.php'), {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      patient_medication_id: patientMedicationId,
      intake_time: t,
      frequency_per_day: 1,
    }),
  });
  const data = await parseJson(res);
  if (!res.ok) throw new Error(data.message || 'تعذر حفظ وقت الجرعة');
  return data;
}

let medicines = [];

function formatTimeDisplay(t) {
  if (!t) return '—';
  const s = String(t);
  return s.length >= 5 ? s.slice(0, 5) : s;
}

function updateStats() {
  const total = medicines.length;
  document.getElementById('total-medicines').textContent = total;
  document.getElementById('taken-count').textContent = '0';
  document.getElementById('pending-count').textContent = total;
  document.getElementById('missed-count').textContent = '0';
}

function renderMedicines() {
  const container = document.getElementById('medicines-list');

  if (!medicines.length) {
    container.innerHTML =
      '<div id="empty-state" class="text-center py-20 flex flex-col items-center gap-4">' +
      '<div class="text-6xl opacity-20">📋</div>' +
      '<p class="text-gray-400 font-medium">لا توجد أدوية مسجلة حالياً</p>' +
      '</div>';
    return;
  }

  container.innerHTML = medicines
    .map(function (med) {
      const disease = (med.instructions || '').split('\n')[0] || '';
      const notes = med.instructions || '';
      return (
        '<div class="p-4 mb-3 rounded-2xl bg-white shadow-sm border-r-8 border-emerald-500 flex flex-col gap-2">' +
        '<div class="flex justify-between items-start">' +
        '<div>' +
        '<h3 class="font-bold text-gray-800">' +
        (med.medication_name || '') +
        '</h3>' +
        '<p class="text-[10px] text-gray-500">' +
        (med.dosage_amount || '') +
        (med.strength ? ' — ' + med.strength : '') +
        '</p>' +
        '</div>' +
        '<div class="text-left font-bold text-emerald-600 text-sm">' +
        formatTimeDisplay(med.intake_time) +
        '</div>' +
        '</div>' +
        (disease
          ? '<span class="text-[9px] w-fit px-2 py-0.5 rounded-full bg-blue-50 text-blue-600 font-bold">' +
            disease +
            '</span>'
          : '') +
        '<div class="bg-gray-50 p-2 rounded-lg border-t mt-1">' +
        '<p class="text-[10px] text-emerald-800 leading-relaxed font-bold italic">📝 ملاحظات: ' +
        (notes || 'لا توجد') +
        '</p>' +
        '</div>' +
        '</div>'
      );
    })
    .join('');
}

function showError(msg) {
  const el = document.getElementById('api-error');
  if (el) {
    el.textContent = msg || '';
    el.classList.toggle('hidden', !msg);
  } else if (msg) {
    alert(msg);
  }
}

async function refreshMedicines() {
  const pid = getPatientId();
  if (!pid) {
    medicines = [];
    renderMedicines();
    updateStats();
    return;
  }
  try {
    showError('');
    medicines = await apiListMedications(pid);
    renderMedicines();
    updateStats();
  } catch (e) {
    showError(e.message);
  }
}

document.addEventListener('DOMContentLoaded', function () {
  var regDialog = document.getElementById('register-dialog');
  var btnOpenReg = document.getElementById('btn-open-register');
  var btnCloseReg = document.getElementById('btn-close-register');
  if (btnOpenReg && regDialog) {
    btnOpenReg.addEventListener('click', function () {
      regDialog.showModal();
    });
  }
  if (btnCloseReg && regDialog) {
    btnCloseReg.addEventListener('click', function () {
      regDialog.close();
    });
  }

  document.getElementById('btn-login').addEventListener('click', async function () {
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    showError('');
    try {
      const data = await apiLogin(email, password);
      setSession(data.patient_id, data.full_name);
      await refreshMedicines();
    } catch (e) {
      showError(e.message);
    }
  });

  document.getElementById('btn-register').addEventListener('click', async function () {
    const body = {
      full_name: document.getElementById('reg-full-name').value.trim(),
      national_id: document.getElementById('reg-national-id').value.trim(),
      email: document.getElementById('reg-email').value.trim(),
      password: document.getElementById('reg-password').value,
      gender: document.getElementById('reg-gender').value,
      date_of_birth: document.getElementById('reg-dob').value || null,
      phone: document.getElementById('reg-phone').value.trim() || null,
    };
    showError('');
    try {
      const data = await apiRegister(body);
      if (data.patient_id) {
        setSession(data.patient_id, body.full_name);
        await refreshMedicines();
        if (regDialog) regDialog.close();
      }
    } catch (e) {
      showError(e.message);
    }
  });

  document.getElementById('btn-logout').addEventListener('click', function () {
    setSession(null, null);
    medicines = [];
    renderMedicines();
    updateStats();
  });

  document.getElementById('medicine-form').addEventListener('submit', async function (e) {
    e.preventDefault();
    const pid = getPatientId();
    if (!pid) {
      showError('سجّل الدخول أولاً.');
      return;
    }

    const medName = document.getElementById('medicine-name').value.trim();
    const dosage = document.getElementById('dosage').value.trim();
    const timeVal = document.getElementById('medicine-time').value;
    const disease = document.getElementById('disease-type').value;
    const notes = document.getElementById('personal-notes').value.trim();
    const instructions = [disease ? 'الحالة: ' + disease : '', notes].filter(Boolean).join('\n');

    try {
      showError('');
      const medId = await apiCreateMedication(medName, 'Tablet', '', instructions);
      const pmId = await apiAddForPatient(pid, medId, dosage, instructions, new Date().toISOString().slice(0, 10));
      await apiAddSchedule(pmId, timeVal);
      await refreshMedicines();
      e.target.reset();
    } catch (err) {
      showError(err.message);
    }
  });

  updateAuthUi();
  refreshMedicines();
});
