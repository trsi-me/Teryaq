<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

include_once '../../config/database.php';
include_once '../../includes/medication.php';

$database = new Database();
$db = $database->getConnection();

$medication = new Medication($db);

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->patient_medication_id) && !empty($data->intake_time)) {
    $frequency = isset($data->frequency_per_day) ? (int) $data->frequency_per_day : 1;
    if ($medication->createSchedule($data->patient_medication_id, $data->intake_time, $frequency)) {
        http_response_code(201);
        echo json_encode(array("message" => "Schedule created successfully."));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create schedule."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Required: patient_medication_id, intake_time (HH:MM or HH:MM:SS)."));
}
?>
