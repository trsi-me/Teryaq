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

if(!empty($data->patient_id) && !empty($data->medication_id) && !empty($data->dosage_amount)) {
    $patient_id = $data->patient_id;
    $medication_id = $data->medication_id;
    $dosage_amount = $data->dosage_amount;
    $start_date = isset($data->start_date) ? $data->start_date : date("Y-m-d");
    $end_date = isset($data->end_date) ? $data->end_date : null;
    $instructions = isset($data->instructions) ? $data->instructions : "";

    $patient_medication_id = $medication->addForPatient($patient_id, $medication_id, $dosage_amount, $start_date, $end_date, $instructions);

    if($patient_medication_id) {
        http_response_code(201);
        echo json_encode(array(
            "message" => "Medication assigned to patient successfully.",
            "patient_medication_id" => $patient_medication_id
        ));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to assign medication."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data."));
}
?>
