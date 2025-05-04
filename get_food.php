<?php
// Include database connection
require_once 'db_connect.php';

// Set headers for JSON response
header('Content-Type: application/json');

// Get action type from request
$action = isset($_GET['action']) ? $_GET['action'] : 'all';

// Switch based on requested action
switch ($action) {
    case 'all':
        // Get all food items
        $sql = "SELECT f.FoodID, f.Name, f.Description, f.Price, r.Name AS RestaurantName, r.Rating 
                FROM Food f
                JOIN Restaurant r ON f.RestaurantID = r.RestaurantID";
        $result = $conn->query($sql);
        
        if ($result->num_rows > 0) {
            $foodItems = array();
            while($row = $result->fetch_assoc()) {
                $foodItems[] = $row;
            }
            echo json_encode($foodItems);
        } else {
            echo json_encode(array('message' => 'No food items found'));
        }
        break;
        
    case 'restaurant':
        // Get food by restaurant ID
        $restaurantId = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($restaurantId > 0) {
            $stmt = $conn->prepare("SELECT FoodID, Name, Description, Price 
                                    FROM Food 
                                    WHERE RestaurantID = ?");
            $stmt->bind_param("i", $restaurantId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $foodItems = array();
                while($row = $result->fetch_assoc()) {
                    $foodItems[] = $row;
                }
                echo json_encode($foodItems);
            } else {
                echo json_encode(array('message' => 'No food items found for this restaurant'));
            }
            $stmt->close();
        } else {
            echo json_encode(array('error' => 'Invalid restaurant ID'));
        }
        break;
        
    case 'item':
        // Get a specific food item by ID
        $foodId = isset($_GET['id']) ? intval($_GET['id']) : 0;
        
        if ($foodId > 0) {
            $stmt = $conn->prepare("SELECT f.FoodID, f.Name, f.Description, f.Price, r.Name AS RestaurantName 
                                    FROM Food f
                                    JOIN Restaurant r ON f.RestaurantID = r.RestaurantID
                                    WHERE f.FoodID = ?");
            $stmt->bind_param("i", $foodId);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $foodItem = $result->fetch_assoc();
                echo json_encode($foodItem);
            } else {
                echo json_encode(array('error' => 'Food item not found'));
            }
            $stmt->close();
        } else {
            echo json_encode(array('error' => 'Invalid food ID'));
        }
        break;
        
    default:
        echo json_encode(array('error' => 'Invalid action'));
        break;
}

// Close connection
$conn->close();
?>