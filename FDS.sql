CREATE DATABASE FoodDeliverySystem2;
USE FoodDeliverySystem2;

-- Drop existing tables if they exist to ensure clean setup
DROP TABLE IF EXISTS Delivery;
DROP TABLE IF EXISTS Payment;
DROP TABLE IF EXISTS OrderDetails;
DROP TABLE IF EXISTS Food;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Customer;
DROP TABLE IF EXISTS Restaurant;
DROP TABLE IF EXISTS OrderStatus;
DROP TABLE IF EXISTS DeliveryStatus;
DROP TABLE IF EXISTS PaymentMethod;
DROP TABLE IF EXISTS PaymentStatus;
DROP FUNCTION IF EXISTS GetOrderTotal;
DROP PROCEDURE IF EXISTS ProcessPendingOrders;
DROP VIEW IF EXISTS CustomerOrderHistory;
DROP VIEW IF EXISTS OrderDetailsView;
DROP VIEW IF EXISTS PaymentView;
DROP VIEW IF EXISTS DeliveryView;

-- Create the Customer Table
CREATE TABLE IF NOT EXISTS Customer (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Contact VARCHAR(20) UNIQUE NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL
);

-- Create the Restaurant Table
CREATE TABLE IF NOT EXISTS Restaurant (
    RestaurantID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Rating DECIMAL(2,1) CHECK (Rating BETWEEN 1 AND 5),
    Address TEXT NOT NULL
);

-- Create the OrderStatus Table
CREATE TABLE IF NOT EXISTS OrderStatus (
    StatusID INT PRIMARY KEY AUTO_INCREMENT,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

-- Create the DeliveryStatus Table (normalized from ENUM)
CREATE TABLE IF NOT EXISTS DeliveryStatus (
    DeliveryStatusID INT PRIMARY KEY AUTO_INCREMENT,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

-- Create the PaymentMethod Table (normalized from ENUM)
CREATE TABLE IF NOT EXISTS PaymentMethod (
    PaymentMethodID INT PRIMARY KEY AUTO_INCREMENT,
    MethodName VARCHAR(50) NOT NULL UNIQUE
);

-- Create the PaymentStatus Table (normalized from ENUM)
CREATE TABLE IF NOT EXISTS PaymentStatus (
    PaymentStatusID INT PRIMARY KEY AUTO_INCREMENT,
    StatusName VARCHAR(50) NOT NULL UNIQUE
);

-- Create the Orders Table
CREATE TABLE IF NOT EXISTS Orders (
    OrderID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    OrderDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    StatusID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
    FOREIGN KEY (StatusID) REFERENCES OrderStatus(StatusID)
);

-- Create the Food Table
CREATE TABLE IF NOT EXISTS Food (
    FoodID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Price DECIMAL(10,2) NOT NULL,
    RestaurantID INT,
    FOREIGN KEY (RestaurantID) REFERENCES Restaurant(RestaurantID) ON DELETE CASCADE
);

-- Create the OrderDetails Table
CREATE TABLE IF NOT EXISTS OrderDetails (
    OrderDetailID INT PRIMARY KEY AUTO_INCREMENT,
    OrderID INT,
    FoodID INT,
    Quantity INT DEFAULT 1,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID) ON DELETE CASCADE,
    FOREIGN KEY (FoodID) REFERENCES Food(FoodID) ON DELETE CASCADE
);

-- Create the Payment Table
CREATE TABLE Payment (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT,
    PaymentMethod VARCHAR(50),
    Amount DECIMAL(10, 2),
    PaymentDate DATE,
    PaymentStatus VARCHAR(50),
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID)
);


-- Create the Delivery Table
CREATE TABLE Delivery (
    DeliveryID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT,
    DeliveryAddress VARCHAR(255),
    DeliveryTime TIME,
    DeliveryStatus VARCHAR(50),
    FOREIGN KEY (OrderID) REFERENCES orders(OrderID)
);


-- Insert data into reference tables first
INSERT INTO OrderStatus (StatusName) VALUES
('Pending'),
('Processing'),
('Completed');

INSERT INTO DeliveryStatus (StatusName) VALUES
('Dispatched'),
('In Transit'),
('Delivered');

INSERT INTO PaymentMethod (MethodName) VALUES
('Cash'),
('Card'),
('Online');

INSERT INTO PaymentStatus (StatusName) VALUES
('Pending'),
('Paid');

-- Insert example data into Customer
INSERT INTO Customer (Name, Contact, Email) VALUES
('Alice Johnson', '9876543210', 'alice@example.com'),
('Bob Smith', '8765432109', 'bob@example.com'),
('Charlie Brown', '7654321098', 'charlie@example.com');

-- Insert example data into Restaurant
INSERT INTO Restaurant (Name, Rating, Address) VALUES
('Tasty Bites', 4.5, '123 Main St, City A'),
('Food Haven', 4.2, '456 Market Rd, City B'),
('Spice Delight', 4.7, '789 Elm St, City C');

-- Insert example data into Food
INSERT INTO Food (Name, Description, Price, RestaurantID) VALUES
('Burger', 'Cheesy beef burger', 5.99, 1),
('Pizza', 'Pepperoni pizza', 8.99, 1),
('Pasta', 'Creamy Alfredo pasta', 7.49, 2),
('Sushi', 'Fresh salmon sushi', 12.99, 3),
('Salad', 'Healthy green salad', 4.99, 2);

-- Insert example data into Orders
INSERT INTO Orders (CustomerID, OrderDateTime, StatusID) VALUES
(1, '2025-03-06 12:30:00', 1),
(2, '2025-03-06 13:15:00', 2),
(3, '2025-03-06 14:00:00', 3);

-- Insert example data into OrderDetails
INSERT INTO OrderDetails (OrderID, FoodID, Quantity) VALUES
(1, 1, 2), -- Alice ordered 2 Burgers
(1, 3, 1), -- Alice ordered 1 Pasta
(2, 2, 1), -- Bob ordered 1 Pizza
(3, 4, 3), -- Charlie ordered 3 Sushi
(3, 5, 2); -- Charlie ordered 2 Salad

-- Insert example data into Payment
INSERT INTO Payment (OrderID, PaymentMethodID, PaymentStatusID, PaymentDateTime) VALUES
(1, 3, 2, '2025-03-06 12:35:00'),  -- Online, Paid
(2, 2, 1, '2025-03-06 13:20:00'),  -- Card, Pending
(3, 1, 2, '2025-03-06 14:05:00');  -- Cash, Paid

-- Insert example data into Delivery
INSERT INTO Delivery (OrderID, DeliveryDateTime, DeliveryStatusID) VALUES
(1, '2025-03-06 13:00:00', 1),  -- Dispatched
(2, '2025-03-06 13:45:00', 2),  -- In Transit
(3, '2025-03-06 14:30:00', 3);  -- Delivered

-- Create Function to Get Total of an Order
DELIMITER //

CREATE FUNCTION GetOrderTotal(orderID INT) RETURNS DECIMAL(10,2)
DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE total DECIMAL(10,2);
    
    SELECT SUM(f.Price * od.Quantity) INTO total
    FROM OrderDetails od
    JOIN Food f ON od.FoodID = f.FoodID
    WHERE od.OrderID = orderID;
    
    RETURN IFNULL(total, 0.00);
END//

DELIMITER ;

-- Create View for Customer Order History
CREATE OR REPLACE VIEW CustomerOrderHistory AS
SELECT 
    c.Name AS CustomerName, 
    o.OrderID, 
    o.OrderDateTime, 
    s.StatusName AS Status
FROM Customer c
JOIN Orders o ON c.CustomerID = o.CustomerID
JOIN OrderStatus s ON o.StatusID = s.StatusID;

-- Create View for Order Details with Food Information
CREATE OR REPLACE VIEW OrderDetailsView AS
SELECT
    od.OrderID,
    f.Name AS FoodName,
    f.Price AS UnitPrice,
    od.Quantity,
    (f.Price * od.Quantity) AS SubTotal
FROM OrderDetails od
JOIN Food f ON od.FoodID = f.FoodID;

-- Create View for Payment Information
CREATE OR REPLACE VIEW PaymentView AS
SELECT 
    PaymentID, 
    OrderID, 
    PaymentMethod, 
    Amount, 
    PaymentDate, 
    PaymentStatus
FROM payment;

-- Create View for Delivery Information
CREATE OR REPLACE VIEW DeliveryView AS
SELECT 
    DeliveryID, 
    OrderID, 
    DeliveryAddress, 
    DeliveryTime, 
    DeliveryStatus
FROM delivery;

-- Create comprehensive order summary view
CREATE OR REPLACE VIEW OrderSummaryView AS
SELECT
    o.OrderID,
    c.Name AS CustomerName,
    c.Contact AS CustomerContact,
    o.OrderDateTime,
    os.StatusName AS OrderStatus,
    pm.MethodName AS PaymentMethod,
    ps.StatusName AS PaymentStatus,
    ds.StatusName AS DeliveryStatus,
    d.DeliveryDateTime AS ExpectedDelivery,
    GetOrderTotal(o.OrderID) AS TotalAmount
FROM Orders o
JOIN Customer c ON o.CustomerID = c.CustomerID
JOIN OrderStatus os ON o.StatusID = os.StatusID
LEFT JOIN Payment p ON o.OrderID = p.OrderID
LEFT JOIN PaymentMethod pm ON p.PaymentMethodID = pm.PaymentMethodID
LEFT JOIN PaymentStatus ps ON p.PaymentStatusID = ps.PaymentStatusID
LEFT JOIN Delivery d ON o.OrderID = d.OrderID
LEFT JOIN DeliveryStatus ds ON d.DeliveryStatusID = ds.DeliveryStatusID;

DELIMITER //

-- Create Trigger to update order status after payment
CREATE TRIGGER update_order_stat
AFTER UPDATE ON Payment
FOR EACH ROW
BEGIN
    DECLARE proc_status_id INT;
    DECLARE paid_status_id INT;
    
    -- Get the status IDs
    SELECT StatusID INTO proc_status_id FROM OrderStatus WHERE StatusName = 'Processing' LIMIT 1;
    SELECT PaymentStatusID INTO paid_status_id FROM PaymentStatus WHERE StatusName = 'Paid' LIMIT 1;
    
    IF NEW.PaymentStatusID = paid_status_id AND proc_status_id IS NOT NULL THEN
        UPDATE Orders
        SET StatusID = proc_status_id
        WHERE OrderID = NEW.OrderID;
    END IF;
END//

-- Create Procedure to process pending orders
CREATE PROCEDURE ProcessPendingOrders()
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE orderID INT;
    DECLARE pendingStatusID INT;
    DECLARE processingStatusID INT;
    DECLARE cur CURSOR FOR 
        SELECT o.OrderID 
        FROM Orders o
        JOIN OrderStatus s ON o.StatusID = s.StatusID
        WHERE s.StatusName = 'Pending';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Get status IDs safely
    SELECT StatusID INTO pendingStatusID FROM OrderStatus WHERE StatusName = 'Pending' LIMIT 1;
    SELECT StatusID INTO processingStatusID FROM OrderStatus WHERE StatusName = 'Processing' LIMIT 1;

    -- Only proceed if both statuses exist
    IF pendingStatusID IS NOT NULL AND processingStatusID IS NOT NULL THEN
        OPEN cur;
        read_loop: LOOP
            FETCH cur INTO orderID;
            IF done THEN
                LEAVE read_loop;
            END IF;

            UPDATE Orders SET StatusID = processingStatusID WHERE OrderID = orderID;
        END LOOP;

        CLOSE cur;
    END IF;
END//



-- Create procedure to get restaurant revenue
CREATE PROCEDURE GetRestaurantRevenue(IN restaurantID INT, OUT totalRevenue DECIMAL(10,2))
BEGIN
    SELECT SUM(od.Quantity * f.Price) INTO totalRevenue
    FROM OrderDetails od
    JOIN Food f ON od.FoodID = f.FoodID
    JOIN Orders o ON od.OrderID = o.OrderID
    JOIN Payment p ON o.OrderID = p.OrderID
    JOIN PaymentStatus ps ON p.PaymentStatusID = ps.PaymentStatusID
    WHERE f.RestaurantID = restaurantID
    AND ps.StatusName = 'Paid';
    
    SET totalRevenue = IFNULL(totalRevenue, 0.00);
END//

-- Create procedure to update food prices
CREATE PROCEDURE UpdateFoodPrices(IN restaurantID INT, IN increasePercentage DECIMAL(5,2))
BEGIN
    DECLARE validPercentage DECIMAL(5,2);
    
    -- Ensure percentage is within reasonable limits (0-50%)
    IF increasePercentage < 0 THEN
        SET validPercentage = 0;
    ELSEIF increasePercentage > 50 THEN
        SET validPercentage = 50;
    ELSE
        SET validPercentage = increasePercentage;
    END IF;
    
    -- Update prices for the specified restaurant
    UPDATE Food
    SET Price = Price * (1 + (validPercentage / 100))
    WHERE RestaurantID = restaurantID;
END//

-- Create procedure to add a new order with multiple items
CREATE PROCEDURE AddNewOrder(
    IN customerID INT,
    IN statusName VARCHAR(50)
)
BEGIN
    DECLARE newOrderID INT;
    DECLARE statusID INT;
    
    -- Get status ID
    SELECT StatusID INTO statusID 
    FROM OrderStatus 
    WHERE StatusName = statusName;
    
    -- Insert new order
    INSERT INTO Orders (CustomerID, OrderDateTime, StatusID)
    VALUES (customerID, NOW(), IFNULL(statusID, 1));
    
    -- Get the new order ID
    SET newOrderID = LAST_INSERT_ID();
    
    -- Return the new order ID
    SELECT newOrderID AS NewOrderID;
END//

-- Create procedure to add items to an order
CREATE PROCEDURE AddOrderItem(
    IN orderID INT,
    IN foodID INT,
    IN quantity INT
)
BEGIN
    -- Check if item already exists in order
    DECLARE existingID INT;
    DECLARE existingQty INT;
    
    SELECT OrderDetailID, Quantity INTO existingID, existingQty
    FROM OrderDetails
    WHERE OrderID = orderID AND FoodID = foodID
    LIMIT 1;
    
    -- If item exists, update quantity; otherwise insert new item
    IF existingID IS NOT NULL THEN
        UPDATE OrderDetails
        SET Quantity = existingQty + quantity
        WHERE OrderDetailID = existingID;
    ELSE
        INSERT INTO OrderDetails (OrderID, FoodID, Quantity)
        VALUES (orderID, foodID, quantity);
    END IF;
    
    -- Return updated order details
    SELECT 
        od.OrderDetailID,
        f.Name AS FoodName,
        od.Quantity,
        f.Price AS UnitPrice,
        (od.Quantity * f.Price) AS Subtotal
    FROM OrderDetails od
    JOIN Food f ON od.FoodID = f.FoodID
    WHERE od.OrderID = orderID;
END//

DELIMITER ;

-- Sample queries to test the database
DESC Customer;
DESC Orders;
DESC Food;
DESC Payment;
DESC Delivery;
DESC Restaurant;
DESC OrderDetails;
DESC OrderStatus;
DESC DeliveryStatus;
DESC PaymentMethod;
DESC PaymentStatus;

-- Get all customer orders
SELECT * FROM CustomerOrderHistory;

-- Get order details
SELECT * FROM OrderDetailsView WHERE OrderID = 1;

-- Get payment information
SELECT * FROM PaymentView;

-- Get delivery status
SELECT * FROM DeliveryView;

-- Get comprehensive order summary
SELECT * FROM OrderSummaryView;

-- Calculate total for an order
SELECT GetOrderTotal(1) AS OrderTotal;

-- Call procedure to get restaurant revenue
CALL GetRestaurantRevenue(1, @revenue);
SELECT @revenue AS RestaurantRevenue;

-- Example of how to add a new order with items
-- CALL AddNewOrder(1, 'Pending');
-- CALL AddOrderItem(LAST_INSERT_ID(), 1, 2);
-- CALL AddOrderItem(LAST_INSERT_ID(), 3, 1);


