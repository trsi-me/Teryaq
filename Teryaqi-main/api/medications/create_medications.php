<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit();
}

// Correct paths to go back two levels to reach config and includes
include_once '../../config/database.php';
include_once '../../includes/medication.php';

$database = new Database();
$db = $database->getConnection();

$medication = new Medication($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->medication_name) && !empty($data->dosage_form)) {
    $name = $data->medication_name;
    $form = $data->dosage_form;
    $strength = isset($data->strength) ? $data->strength : "";
    $description = isset($data->description) ? $data->description : "";

    $new_id = $medication->createBaseMedication($name, $form, $strength, $description);

    if($new_id) {
        http_response_code(201);
        echo json_encode(array(
            "message" => "Base medication created successfully.",
            "medication_id" => $new_id
        ));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to create medication."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Required: medication_name, dosage_form."));
}
?>
