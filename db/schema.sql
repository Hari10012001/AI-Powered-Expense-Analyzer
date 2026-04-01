CREATE DATABASE IF NOT EXISTS expense_db;
USE expense_db;

-- Table for Users
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL
);

-- Table for Income
CREATE TABLE IF NOT EXISTS income (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DOUBLE NOT NULL,
    source VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Table for Expenses
CREATE TABLE IF NOT EXISTS expense (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    amount DOUBLE NOT NULL,
    category VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Initial admin user for first login
INSERT INTO users (id, name, email, password)
SELECT 1, 'Admin', 'admin@example.com', 'admin123'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE id = 1);
