<?php
class Sensor {
    private $conn;

    public function __construct($db) {
        $this->conn = $db;
    }

    // Updated: Link to patient_id instead of box_id
    public function logIntake($patient_id, $schedule_id, $taken_status, $taken_time, $log_date) {
        $query = "INSERT INTO SENSOR_LOGS 
                SET patient_id=:patient_id, schedule_id=:schedule_id, taken_status=:taken_status, 
                    taken_time=:taken_time, log_date=:log_date";
        
        $stmt = $this->conn->prepare($query);

        $stmt->bindParam(":patient_id", $patient_id);
        $stmt->bindParam(":schedule_id", $schedule_id);
        $stmt->bindParam(":taken_status", $taken_status);
        $stmt->bindParam(":taken_time", $taken_time);
        $stmt->bindParam(":log_date", $log_date);

        return $stmt->execute();
    }

    public function getNotifications($patient_id) {
        $query = "SELECT n.notification_id, n.message, n.sent_time, n.status, m.medication_name
                  FROM NOTIFICATIONS n
                  JOIN MEDICATION_SCHEDULE ms ON n.schedule_id = ms.schedule_id
                  JOIN PATIENT_MEDICATIONS pm ON ms.patient_medication_id = pm.patient_medication_id
                  JOIN MEDICATIONS m ON pm.medication_id = m.medication_id
                  WHERE n.patient_id = ?
                  ORDER BY n.sent_time DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $patient_id);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
