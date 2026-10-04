<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

include_once '../../config/database.php';
include_once '../../includes/medication.php';

$database = new Database();
$db = $database->getConnection();

$medication = new Medication($db);

if (!isset($_GET['patient_id']) || $_GET['patient_id'] === '') {
    http_response_code(400);
    echo json_encode(array("message" => "Required: patient_id."));
    exit;
}

$patient_id = $_GET['patient_id'];

$medications_list = $medication->getForPatient($patient_id);

// fetchAll يعيد مصفوفة فارغة [] وليست false — كان يُعامل خطأً كـ 404
http_response_code(200);
echo json_encode(is_array($medications_list) ? $medications_list : array());
?>
