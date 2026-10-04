<?php
class Medication {
    private $conn;

    public function __construct($db) {
        $this->conn = $db;
    }

    public function addForPatient($patient_id, $medication_id, $dosage_amount, $start_date, $end_date, $instructions) {
        $query = "INSERT INTO PATIENT_MEDICATIONS 
                SET patient_id=:patient_id, medication_id=:medication_id, dosage_amount=:dosage_amount, 
                    start_date=:start_date, end_date=:end_date, instructions=:instructions";
        
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(":patient_id", $patient_id);
        $stmt->bindParam(":medication_id", $medication_id);
        $stmt->bindParam(":dosage_amount", $dosage_amount);
        $stmt->bindParam(":start_date", $start_date);
        $stmt->bindParam(":end_date", $end_date);
        $stmt->bindParam(":instructions", $instructions);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    public function getForPatient($patient_id) {
        $query = "SELECT pm.patient_medication_id, m.medication_name, m.dosage_form, m.strength, 
                         pm.dosage_amount, pm.start_date, pm.end_date, pm.instructions,
                         (SELECT MIN(ms.intake_time) FROM MEDICATION_SCHEDULE ms 
                          WHERE ms.patient_medication_id = pm.patient_medication_id) AS intake_time
                  FROM PATIENT_MEDICATIONS pm
                  JOIN MEDICATIONS m ON pm.medication_id = m.medication_id
                  WHERE pm.patient_id = ?";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $patient_id);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function createSchedule($patient_medication_id, $intake_time, $frequency_per_day) {
        $query = "INSERT INTO MEDICATION_SCHEDULE 
                SET patient_medication_id=:patient_medication_id, intake_time=:intake_time, 
                    frequency_per_day=:frequency_per_day";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":patient_medication_id", $patient_medication_id);
        $stmt->bindParam(":intake_time", $intake_time);
        $stmt->bindParam(":frequency_per_day", $frequency_per_day);

        return $stmt->execute();
    }

    public function getTodaySchedules($patient_id) {
        $query = "SELECT ms.schedule_id, m.medication_name, ms.intake_time, pm.dosage_amount
                  FROM MEDICATION_SCHEDULE ms
                  JOIN PATIENT_MEDICATIONS pm ON ms.patient_medication_id = pm.patient_medication_id
                  JOIN MEDICATIONS m ON pm.medication_id = m.medication_id
                  WHERE pm.patient_id = ? AND (pm.end_date >= CURDATE() OR pm.end_date IS NULL)";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $patient_id);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // New: Function to add a base medication (for APIdog/Postman)
    public function createBaseMedication($name, $form, $strength, $description) {
        $query = "INSERT INTO MEDICATIONS 
                SET medication_name=:name, dosage_form=:form, strength=:strength, description=:description";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":name", $name);
        $stmt->bindParam(":form", $form);
        $stmt->bindParam(":strength", $strength);
        $stmt->bindParam(":description", $description);

        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        return false;
    }

    // New: Function to get all available base medications
    public function getAllMedications() {
        $query = "SELECT * FROM MEDICATIONS ORDER BY medication_name ASC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
