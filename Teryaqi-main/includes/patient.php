<?php
class Patient {
    private $conn;
    private $table_name = "PATIENTS";

    public $patient_id;
    public $full_name;
    public $national_id;
    public $date_of_birth;
    public $gender;
    public $phone;
    public $email;
    public $password;
    public $fcm_token;
    
    // Smart Pill Box Fields (Commented out for now as requested)
    /*
    public $box_serial_number;
    public $box_activation_date;
    public $box_status;
    */

    public function __construct($db) {
        $this->conn = $db;
    }

    public function register() {
        $query = "INSERT INTO " . $this->table_name . " 
                SET full_name=:full_name, national_id=:national_id, date_of_birth=:date_of_birth, 
                    gender=:gender, phone=:phone, email=:email, password=:password";
        
        $stmt = $this->conn->prepare($query);

        $this->password = password_hash($this->password, PASSWORD_BCRYPT);

        $stmt->bindParam(":full_name", $this->full_name);
        $stmt->bindParam(":national_id", $this->national_id);
        $stmt->bindParam(":date_of_birth", $this->date_of_birth);
        $stmt->bindParam(":gender", $this->gender);
        $stmt->bindParam(":phone", $this->phone);
        $stmt->bindParam(":email", $this->email);
        $stmt->bindParam(":password", $this->password);

        if($stmt->execute()) {
            $this->patient_id = (int) $this->conn->lastInsertId();
            return true;
        }
        return false;
    }

    public function login() {
        $query = "SELECT patient_id, full_name, password FROM " . $this->table_name . " WHERE email = ? LIMIT 0,1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->email);
        $stmt->execute();
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if($row && password_verify($this->password, $row['password'])) {
            $this->patient_id = $row['patient_id'];
            $this->full_name = $row['full_name'];
            return true;
        }
        return false;
    }

    public function getProfile() {
        // Corrected SQL query: removed trailing comma and fixed formatting
        // Sensor fields are commented out from the SELECT statement
        $query = "SELECT patient_id, full_name, national_id, date_of_birth, gender, phone, email, fcm_token
                  /* , box_serial_number, box_activation_date, box_status */
                  FROM " . $this->table_name . " 
                  WHERE patient_id = ? 
                  LIMIT 0,1";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(1, $this->patient_id);
        
        if($stmt->execute()) {
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            if($row) {
                return $row;
            }
        }
        return false;
    }

    public function updateFcmToken() {
        $query = "UPDATE " . $this->table_name . " SET fcm_token = :fcm_token WHERE patient_id = :patient_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":fcm_token", $this->fcm_token);
        $stmt->bindParam(":patient_id", $this->patient_id);
        return $stmt->execute();
    }

    // Smart Pill Box update functionality commented out
    /*
    public function updateBoxInfo() {
        $query = "UPDATE " . $this->table_name . " 
                  SET box_serial_number = :box_serial_number, 
                      box_activation_date = CURDATE(), 
                      box_status = :box_status 
                  WHERE patient_id = :patient_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(":box_serial_number", $this->box_serial_number);
        $stmt->bindParam(":box_status", $this->box_status);
        $stmt->bindParam(":patient_id", $this->patient_id);
        
        return $stmt->execute();
    }
    */
}
?>
