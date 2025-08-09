-- Restaurant Ordering System Database Schema for Supabase

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create tables

-- Menu Items Table
CREATE TABLE menu_items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category VARCHAR(100) NOT NULL,
    image_url TEXT,
    available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tables Table
CREATE TABLE tables (
    id SERIAL PRIMARY KEY,
    table_number INTEGER UNIQUE NOT NULL,
    waiter_id INTEGER,
    status VARCHAR(50) DEFAULT 'available', -- available, occupied, reserved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Orders Table
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    table_number INTEGER NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, preparing, ready, served, cancelled
    total_amount DECIMAL(10,2) NOT NULL,
    customer_name VARCHAR(255),
    special_instructions TEXT,
    payment_status VARCHAR(50) DEFAULT 'pending', -- pending, paid, failed
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (table_number) REFERENCES tables(table_number)
);

-- Order Items Table
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    menu_item_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    special_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
);

-- Payments Table
CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- stripe, mpesa, cash
    status VARCHAR(50) DEFAULT 'pending', -- pending, completed, failed
    transaction_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (order_id) REFERENCES orders(id)
);

-- Waiter Alerts Table
CREATE TABLE waiter_alerts (
    id SERIAL PRIMARY KEY,
    table_number INTEGER NOT NULL,
    message TEXT NOT NULL,
    alert_type VARCHAR(50) DEFAULT 'customer_request', -- customer_request, system_alert
    status VARCHAR(50) DEFAULT 'sent', -- sent, acknowledged, resolved
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    FOREIGN KEY (table_number) REFERENCES tables(table_number)
);

-- User Tokens Table (for FCM tokens)
CREATE TABLE user_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    fcm_token TEXT NOT NULL,
    role VARCHAR(50) NOT NULL, -- customer, waiter, kitchen, admin
    device_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, device_id)
);

-- Create indexes for better performance
CREATE INDEX idx_orders_table_number ON orders(table_number);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_menu_items_category ON menu_items(category);
CREATE INDEX idx_menu_items_available ON menu_items(available);
CREATE INDEX idx_tables_waiter_id ON tables(waiter_id);
CREATE INDEX idx_waiter_alerts_table_number ON waiter_alerts(table_number);
CREATE INDEX idx_user_tokens_role ON user_tokens(role);

-- Insert sample data

-- Sample menu items
INSERT INTO menu_items (name, description, price, category, image_url) VALUES
('Margherita Pizza', 'Classic pizza with tomato sauce, mozzarella, and basil', 12.99, 'Pizza', 'https://example.com/margherita.jpg'),
('Pepperoni Pizza', 'Pizza with pepperoni and mozzarella cheese', 14.99, 'Pizza', 'https://example.com/pepperoni.jpg'),
('Caesar Salad', 'Fresh romaine lettuce with Caesar dressing and croutons', 8.99, 'Salads', 'https://example.com/caesar.jpg'),
('Grilled Chicken', 'Grilled chicken breast with herbs and spices', 16.99, 'Main Course', 'https://example.com/chicken.jpg'),
('Beef Burger', 'Juicy beef patty with lettuce, tomato, and cheese', 13.99, 'Burgers', 'https://example.com/burger.jpg'),
('Fish and Chips', 'Battered fish with crispy fries', 15.99, 'Main Course', 'https://example.com/fish.jpg'),
('Chocolate Cake', 'Rich chocolate cake with chocolate frosting', 6.99, 'Desserts', 'https://example.com/cake.jpg'),
('Ice Cream', 'Vanilla ice cream with chocolate sauce', 4.99, 'Desserts', 'https://example.com/icecream.jpg'),
('Coca Cola', 'Refreshing cola drink', 2.99, 'Beverages', 'https://example.com/coke.jpg'),
('Coffee', 'Freshly brewed coffee', 3.99, 'Beverages', 'https://example.com/coffee.jpg');

-- Sample tables
INSERT INTO tables (table_number, status) VALUES
(1, 'available'),
(2, 'available'),
(3, 'available'),
(4, 'available'),
(5, 'available'),
(6, 'available'),
(7, 'available'),
(8, 'available'),
(9, 'available'),
(10, 'available');

-- Create functions for updated_at triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON menu_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tables_updated_at BEFORE UPDATE ON tables FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_tokens_updated_at BEFORE UPDATE ON user_tokens FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS) - Optional, can be configured based on requirements
-- ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE tables ENABLE ROW LEVEL SECURITY;

-- Create policies (examples - adjust based on your authentication setup)
-- CREATE POLICY "Public menu items are viewable by everyone" ON menu_items FOR SELECT USING (true);
-- CREATE POLICY "Orders are viewable by everyone" ON orders FOR SELECT USING (true);
-- CREATE POLICY "Tables are viewable by everyone" ON tables FOR SELECT USING (true);

