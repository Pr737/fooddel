<?php
// Include database connection
require_once 'db_connect.php';

// Set headers for JSON response
header('Content-Type: application/json');

// Check if the request is POST
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Get JSON data from request body
    $json = file_get_contents('php://input');
    $data = json_decode($json, true);
    
    // Validate required data
    if (!isset($data['customer']) || !isset($data['items']) || empty($data['items'])) {
        echo json_encode(array('error' => 'Missing required data'));
        exit;
    }
    
    // Start transaction
    $conn->begin_transaction();
    
    try {
        // Insert or get customer
        $customer = $data['customer'];
        $customerID = null;
        
        // Check if customer exists by email
        $stmt = $conn->prepare("SELECT CustomerID FROM Customer WHERE Email = ?");
        $stmt->bind_param("s", $customer['email']);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            // Customer exists
            $row = $result->fetch_assoc();
            $customerID = $row['CustomerID'];
            
            // Update customer information
            $stmt = $conn->prepare("UPDATE Customer SET Name = ?, Contact = ? WHERE CustomerID = ?");
            $stmt->bind_param("ssi", $customer['name'], $customer['contact'], $customerID);
            $stmt->execute();
        } else {
            // Create new customer
            $stmt = $conn->prepare("INSERT INTO Customer (Name, Contact, Email) VALUES (?, ?, ?)");
            $stmt->bind_param("sss", $customer['name'], $customer['contact'], $customer['email']);
            $stmt->execute();
            $customerID = $conn->insert_id;
        }
        
        // Create order
        $stmt = $conn->prepare("INSERT INTO Orders (CustomerID, StatusID) VALUES (?, 1)"); // Status 1 = Pending
        $stmt->bind_param("i", $customerID);
        $stmt->execute();
        $orderID = $conn->insert_id;
        
        // Add items to order
        foreach ($data['items'] as $item) {
            $stmt = $conn->prepare("INSERT INTO OrderDetails (OrderID, FoodID, Quantity) VALUES (?, ?, ?)");
            $stmt->bind_param("iii", $orderID, $item['foodId'], $item['quantity']);
            $stmt->execute();
        }
        
        // Add payment info if provided
        if (isset($data['payment']) && isset($data['payment']['method'])) {
            // Get payment method ID
            $paymentMethod = $data['payment']['method'];
            $stmt = $conn->prepare("SELECT PaymentMethodID FROM PaymentMethod WHERE MethodName = ?");
            $stmt->bind_param("s", $paymentMethod);
            $stmt->execute();
            $result = $stmt->get_result();
            
            if ($result->num_rows > 0) {
                $row = $result->fetch_assoc();
                $paymentMethodID = $row['PaymentMethodID'];
                
                // Insert payment record
                $stmt = $conn->prepare("INSERT INTO Payment (OrderID, PaymentMethodID, PaymentStatusID) VALUES (?, ?, 1)"); // Status 1 = Pending
                $stmt->bind_param("ii", $orderID, $paymentMethodID);
                $stmt->execute();
            }
        }
        
        // Commit the transaction
        $conn->commit();
        
        // Calculate order total
        $stmt = $conn->prepare("SELECT GetOrderTotal(?) AS OrderTotal");
        $stmt->bind_param("i", $orderID);
        $stmt->execute();
        $result = $stmt->get_result();
        $orderTotal = 0;
        
        if ($result->num_rows > 0) {
            $row = $result->fetch_assoc();
            $orderTotal = $row['OrderTotal'];
        }
        
        // Return success response
        echo json_encode(array(
            'success' => true,
            'message' => 'Order placed successfully',
            'order_id' => $orderID,
            'order_total' => $orderTotal
        ));
        
    } catch (Exception $e) {
        // Rollback transaction on error
        $conn->rollback();
        echo json_encode(array('error' => 'Order processing failed: ' . $e->getMessage()));
    }
    
} else {
    echo json_encode(array('error' => 'Only POST requests are accepted'));
}

// Close connection
$conn->close();
?>