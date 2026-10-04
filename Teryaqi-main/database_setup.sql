CREATE DATABASE IF NOT EXISTS smart_medicine;
USE smart_medicine;

-- 1. Updated PATIENTS Table (Includes Smart Pill Box Data)
CREATE TABLE IF NOT EXISTS PATIENTS (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    national_id VARCHAR(20) UNIQUE NOT NULL,
    date_of_birth DATE,
    gender ENUM('Male','Female') NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255) NOT NULL,
    fcm_token TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Smart Pill Box Data integrated into PATIENTS
    box_serial_number VARCHAR(100) UNIQUE,
    box_activation_date DATE,
    box_status ENUM('Active','Inactive') DEFAULT 'Active'
);

-- 2. CHRONIC_DISEASES Table
CREATE TABLE IF NOT EXISTS CHRONIC_DISEASES (
    disease_id INT AUTO_INCREMENT PRIMARY KEY,
    disease_name VARCHAR(100) NOT NULL,
    description TEXT
);

-- 3. PATIENT_DISEASES Table
CREATE TABLE IF NOT EXISTS PATIENT_DISEASES (
    patient_disease_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    disease_id INT NOT NULL,
    diagnosed_date DATE,
    FOREIGN KEY (patient_id) REFERENCES PATIENTS(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES CHRONIC_DISEASES(disease_id) ON DELETE CASCADE
);

-- 4. MEDICATIONS Table
CREATE TABLE IF NOT EXISTS MEDICATIONS (
    medication_id INT AUTO_INCREMENT PRIMARY KEY,
    medication_name VARCHAR(100) NOT NULL,
    dosage_form ENUM('Tablet','Capsule','Syrup') NOT NULL,
    strength VARCHAR(50),
    description TEXT
);

-- 5. PATIENT_MEDICATIONS Table
CREATE TABLE IF NOT EXISTS PATIENT_MEDICATIONS (
    patient_medication_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage_amount VARCHAR(50),
    start_date DATE,
    end_date DATE,
    instructions TEXT,
    FOREIGN KEY (patient_id) REFERENCES PATIENTS(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (medication_id) REFERENCES MEDICATIONS(medication_id) ON DELETE CASCADE
);

-- 6. MEDICATION_SCHEDULE Table
CREATE TABLE IF NOT EXISTS MEDICATION_SCHEDULE (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_medication_id INT NOT NULL,
    intake_time TIME NOT NULL,
    frequency_per_day INT,
    FOREIGN KEY (patient_medication_id) REFERENCES PATIENT_MEDICATIONS(patient_medication_id) ON DELETE CASCADE
);

-- 7. Updated SENSOR_LOGS Table (Linked to patient_id instead of box_id)
CREATE TABLE IF NOT EXISTS SENSOR_LOGS (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    schedule_id INT NOT NULL,
    taken_status ENUM('Taken','Missed') NOT NULL,
    taken_time TIME,
    log_date DATE,
    FOREIGN KEY (patient_id) REFERENCES PATIENTS(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES MEDICATION_SCHEDULE(schedule_id) ON DELETE CASCADE
);

-- 8. NOTIFICATIONS Table
CREATE TABLE IF NOT EXISTS NOTIFICATIONS (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    schedule_id INT NOT NULL,
    message TEXT,
    sent_time DATETIME,
    status ENUM('Sent','Read','Ignored') DEFAULT 'Sent',
    FOREIGN KEY (patient_id) REFERENCES PATIENTS(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (schedule_id) REFERENCES MEDICATION_SCHEDULE(schedule_id) ON DELETE CASCADE
);
