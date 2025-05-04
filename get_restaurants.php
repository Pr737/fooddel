<?php
// Include database connection
require_once 'db_connect.php';

// Set headers for JSON response
header('Content-Type: application/json');

// Get all restaurants
$sql = "SELECT RestaurantID, Name, Rating, Address FROM Restaurant";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    $restaurants = array();
    while($row = $result->fetch_assoc()) {
        $restaurants[] = $row;
    }
    echo json_encode($restaurants);
} else {
    echo json_encode(array('message' => 'No restaurants found'));
}

// Close connection
$conn->close();
?>