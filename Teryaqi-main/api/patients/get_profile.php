<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

// Correct paths to reach config and includes folders from api/patients/
include_once '../../config/database.php';
include_once '../../includes/patient.php';

$database = new Database();
$db = $database->getConnection();

$patient = new Patient($db);

// Get patient_id from URL parameter
$patient_id = isset($_GET['patient_id']) ? $_GET['patient_id'] : null;

if($patient_id != null) {
    $patient->patient_id = $patient_id;
    $profile = $patient->getProfile();

    if($profile) {
        http_response_code(200);
        // Returns profile without sensor data as requested
        echo json_encode($profile);
    } else {
        http_response_code(404);
        echo json_encode(array("message" => "Patient not found."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Required: patient_id."));
}
?>
