<?php
// Database connection parameters
$servername = "localhost";
$username = "root";  // Default XAMPP username
$password = "PRIYArai123";      // Default XAMPP password (empty)
$dbname = "FoodDeliverySystem2";  // Your database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// Set character set to UTF-8
$conn->set_charset("utf8mb4");
?>