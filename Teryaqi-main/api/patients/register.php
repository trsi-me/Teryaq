<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

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

if(!empty($data->full_name) && !empty($data->national_id) && !empty($data->email) && !empty($data->password) && !empty($data->gender)) {
    if(!in_array($data->gender, array('Male', 'Female'), true)) {
        http_response_code(400);
        echo json_encode(array("message" => "gender must be Male or Female."));
        exit;
    }
    $patient->full_name = $data->full_name;
    $patient->national_id = $data->national_id;
    $patient->date_of_birth = !empty($data->date_of_birth) ? $data->date_of_birth : null;
    $patient->gender = $data->gender;
    $patient->phone = !empty($data->phone) ? $data->phone : null;
    $patient->email = $data->email;
    $patient->password = $data->password;

    if($patient->register()) {
        http_response_code(201);
        echo json_encode(array(
            "message" => "Patient registered successfully.",
            "patient_id" => $patient->patient_id
        ));
    } else {
        http_response_code(503);
        echo json_encode(array("message" => "Unable to register patient."));
    }
} else {
    http_response_code(400);
    echo json_encode(array("message" => "Incomplete data. Required: full_name, national_id, email, password, gender (Male|Female)."));
}
?>
