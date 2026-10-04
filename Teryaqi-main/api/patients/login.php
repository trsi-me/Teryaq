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
include_once '../../includes/patient.php';

$database = new Database();
$db = $database->getConnection();

$patient = new Patient($db);

$data = json_decode(file_get_contents("php://input"));

if(!empty($data->email) && !empty($data->password)) {
    $patient->email = $data->email;
    $patient->password = $data->password;

    if($patient->login()) {
        http_response_code(200);
        echo json_encode(array(
            "message" => "Login successful.",
            "patient_id" => $patient->patient_id,
            "full_name" => $patient->full_name
        ));
    } else {
        http_response_code(401);
        echo json_encode(array("message" => "Login failed. Invalid email or password."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete login data."));
}
?>
