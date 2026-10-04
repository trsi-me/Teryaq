<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once '../../config/database.php';
include_once '../../includes/medication.php';

$database = new Database();
$db = $database->getConnection();

$medication = new Medication($db);

$meds = $medication->getAllMedications();

if($meds) {
    http_response_code(200);
    echo json_encode($meds);
} else {
    http_response_code(404);
    echo json_encode(array("message" => "No medications found."));
}
?>
