// Global variables
let cart = [];
let restaurants = [];
let currentRestaurantId = null;

// Initialize when the document is ready
document.addEventListener('DOMContentLoaded', function() {
    // Load all restaurants
    loadRestaurants();
    
    // Load all food items
    loadFoodItems();
    
    // Initialize cart from localStorage if available
    initializeCart();
    
    // Add event listener for order form submission
    const orderForm = document.getElementById('orderForm');
    if (orderForm) {
        orderForm.addEventListener('submit', placeOrder);
    }
});

/**
 * Load all restaurants from the API
 */
function loadRestaurants() {
    fetch('get_restaurants.php')
        .then(response => response.json())
        .then(data => {
            restaurants = data;
            displayRestaurants(data);
        })
        .catch(error => {
            console.error('Error loading restaurants:', error);
        });
}

/**
 * Display restaurants in the UI
 */
function displayRestaurants(restaurants) {
    const restaurantContainer = document.getElementById('restaurant-list');
    if (!restaurantContainer) return;
    
    restaurantContainer.innerHTML = '';
    
    restaurants.forEach(restaurant => {
        const restaurantElement = document.createElement('div');
        restaurantElement.className = 'restaurant-item';
        restaurantElement.innerHTML = `
            <h3>${restaurant.Name}</h3>
            <p>Rating: ${restaurant.Rating} ⭐</p>
            <p>${restaurant.Address}</p>
            <button class="view-menu-btn" data-id="${restaurant.RestaurantID}">View Menu</button>
        `;
        
        restaurantContainer.appendChild(restaurantElement);
        
        // Add event listener to the button
        const viewMenuBtn = restaurantElement.querySelector('.view-menu-btn');
        viewMenuBtn.addEventListener('click', function() {
            const restaurantId = this.getAttribute('data-id');
            loadFoodItemsByRestaurant(restaurantId);
            currentRestaurantId = restaurantId;
        });
    });
}

/**
 * Load all food items from the API
 */
function loadFoodItems() {
    fetch('get_food.php?action=all')
        .then(response => response.json())
        .then(data => {
            displayFoodItems(data);
        })
        .catch(error => {
            console.error('Error loading food items:', error);
        });
}

/**
 * Load food items by restaurant ID
 */
function loadFoodItemsByRestaurant(restaurantId) {
    fetch(`get_food.php?action=restaurant&id=${restaurantId}`)
        .then(response => response.json())
        .then(data => {
            displayFoodItems(data);
            
            // Also update the UI to show which restaurant is selected
            const restaurantName = restaurants.find(r => r.RestaurantID == restaurantId)?.Name || 'Unknown Restaurant';
            const menuTitle = document.getElementById('menu-title');
            if (menuTitle) {
                menuTitle.textContent = `Menu for ${restaurantName}`;
            }
        })
        .catch(error => {
            console.error('Error loading food items by restaurant:', error);
        });
}

/**
 * Display food items in the UI
 */
function displayFoodItems(foodItems) {
    const foodContainer = document.getElementById('food-list');
    if (!foodContainer) return;
    
    foodContainer.innerHTML = '';
    
    if (!Array.isArray(foodItems) || foodItems.length === 0 || foodItems.message) {
        foodContainer.innerHTML = '<p>No food items available.</p>';
        return;
    }
    
    foodItems.forEach(item => {
        const foodElement = document.createElement('div');
        foodElement.className = 'food-item';
        foodElement.innerHTML = `
            <h3>${item.Name}</h3>
            <p>${item.Description || 'No description available'}</p>
            <p class="price">$${parseFloat(item.Price).toFixed(2)}</p>
            <div class="item-controls">
                <button class="add-to-cart-btn" data-id="${item.FoodID}" data-name="${item.Name}" data-price="${item.Price}">Add to Cart</button>
            </div>
        `;
        
        foodContainer.appendChild(foodElement);
        
        // Add event listener to the button
        const addToCartBtn = foodElement.querySelector('.add-to-cart-btn');
        addToCartBtn.addEventListener('click', function() {
            const foodId = parseInt(this.getAttribute('data-id'));
            const foodName = this.getAttribute('data-name');
            const foodPrice = parseFloat(this.getAttribute('data-price'));
            
            addToCart(foodId, foodName, foodPrice);
        });
    });
}

/**
 * Initialize cart from localStorage
 */
function initializeCart() {
    const savedCart = localStorage.getItem('foodDeliveryCart');
    if (savedCart) {
        cart = JSON.parse(savedCart);
        updateCartUI();
    }
}

/**
 * Add an item to the cart
 */
function addToCart(foodId, foodName, foodPrice) {
    // Check if the item is already in the cart
    const existingItem = cart.find(item => item.foodId === foodId);
    
    if (existingItem) {
        // Update quantity if item exists
        existingItem.quantity += 1;
    } else {
        // Add new item to cart
        cart.push({
            foodId: foodId,
            name: foodName,
            price: foodPrice,
            quantity: 1
        });
    }
    
    // Save to localStorage
    localStorage.setItem('foodDeliveryCart', JSON.stringify(cart));
    
    // Update cart UI
    updateCartUI();
    
    // Show feedback
    alert(`${foodName} added to cart!`);
}

/**
 * Update the cart UI
 */
function updateCartUI() {
    const cartContainer = document.getElementById('cart-items');
    const cartTotal = document.getElementById('cart-total');
    
    if (!cartContainer || !cartTotal) return;
    
    cartContainer.innerHTML = '';
    
    if (cart.length === 0) {
        cartContainer.innerHTML = '<p>Your cart is empty.</p>';
        cartTotal.textContent = '$0.00';
        return;
    }
    
    let total = 0;
    
    cart.forEach((item, index) => {
        const itemTotal = item.price * item.quantity;
        total += itemTotal;
        
        const cartItemElement = document.createElement('div');
        cartItemElement.className = 'cart-item';
        cartItemElement.innerHTML = `
            <span>${item.name}</span>
            <span>$${item.price.toFixed(2)} x ${item.quantity}</span>
            <span>$${itemTotal.toFixed(2)}</span>
            <button class="remove-item-btn" data-index="${index}">Remove</button>
        `;
        
        cartContainer.appendChild(cartItemElement);
        
        // Add event listener to remove button
        const removeBtn = cartItemElement.querySelector('.remove-item-btn');
        removeBtn.addEventListener('click', function() {
            const itemIndex = parseInt(this.getAttribute('data-index'));
            removeFromCart(itemIndex);
        });
    });
    
    cartTotal.textContent = `$${total.toFixed(2)}`;
}

/**
 * Remove an item from the cart
 */
function removeFromCart(index) {
    if (index >= 0 && index < cart.length) {
        cart.splice(index, 1);
        
        // Save to localStorage
        localStorage.setItem('foodDeliveryCart', JSON.stringify(cart));
        
        // Update cart UI
        updateCartUI();
    }
}

/**
 * Clear the cart
 */
function clearCart() {
    cart = [];
    localStorage.removeItem('foodDeliveryCart');
    updateCartUI();
}

/**
 * Place an order
 */
function placeOrder(event) {
    event.preventDefault();
    
    // Check if cart is empty
    if (cart.length === 0) {
        alert('Your cart is empty. Please add items before placing an order.');
        return;
    }
    
    // Get customer information from form
    const customerName = document.getElementById('customerName').value;
    const customerContact = document.getElementById('customerContact').value;
    const customerEmail = document.getElementById('customerEmail').value;
    const paymentMethod = document.getElementById('paymentMethod').value;
    
    // Validate customer information
    if (!customerName || !customerContact || !customerEmail) {
        alert('Please fill in all customer information.');
        return;
    }
    
    // Prepare order data
    const orderData = {
        customer: {
            name: customerName,
            contact: customerContact,
            email: customerEmail
        },
        items: cart,
        payment: {
            method: paymentMethod
        }
    };
    
    // Send order to server
    fetch('process_order.php', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(orderData)
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            alert(`Order placed successfully! Order ID: ${data.order_id}. Total: $${data.order_total}`);
            clearCart();
            
            // Reset the form
            document.getElementById('orderForm').reset();
        } else {
            alert(`Error: ${data.error || 'Unknown error occurred'}`);
        }
    })
    .catch(error => {
        console.error('Error placing order:', error);
        alert('Failed to place order. Please try again later.');
    });
}