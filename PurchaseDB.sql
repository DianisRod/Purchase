
Username: psql -U sebastian
password: Project001

\l //Listar bases de datos
\du //Lista roles de usaurios
\dt //Listar las tablas
\d users// Estructura de la tabla
\c login //Ingresa a la base de datos


-- Conectarse a PostgreSQL y crear la base de datos login (ejecutar en el terminal)
psql -U postgres

-- Crear la base de datos purchase
CREATE DATABASE purchase;

-- Conectarse a la base de datos purchase
\c purchase

-- Crear el usuario sebastian con todos los privilegios sobre la base de datos purchase
CREATE USER sebastian WITH PASSWORD 'Project001';
GRANT ALL PRIVILEGES ON DATABASE purchase TO sebastian;

-- Crear la tabla users con estado por defecto TRUE y un trigger para actualizar el estado al eliminar
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    status BOOLEAN DEFAULT TRUE
);

-- Crear la tabla eliminaciones_log para registrar eliminaciones
CREATE TABLE eliminaciones_log (
    id SERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro_eliminado INTEGER NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) NOT NULL
);

-- Crear la tabla customers
CREATE TABLE customers (
    user_id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT NULL,
    CONSTRAINT fk_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Crear la tabla products
CREATE TABLE products (
    productID SERIAL PRIMARY KEY,
    productName VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL 
);

-- Crear la tabla carts
CREATE TABLE carts (
    cartID SERIAL PRIMARY KEY,
    userID INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE
);

-- Crear la tabla cart_items
CREATE TABLE cart_items (
    cartItemID SERIAL PRIMARY KEY,
    cartID INTEGER NOT NULL,
    productID INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cartID) REFERENCES carts(cartID) ON DELETE CASCADE,
    FOREIGN KEY (productID) REFERENCES products(productID) ON DELETE CASCADE
);

-- Crear la tabla orders
CREATE TABLE orders (
    orderID SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    orderDate DATE DEFAULT CURRENT_DATE,
    productID INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    status BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (productID) REFERENCES products(productID) ON DELETE CASCADE
);

-- Crear la tabla eliminaciones_orders para registrar eliminaciones
CREATE TABLE eliminaciones_orders (
    orderID SERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro_eliminado INTEGER NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) NOT NULL
);

-- FUNCIONES

-- Función para registrar eliminaciones en eliminaciones_log
CREATE OR REPLACE FUNCTION registrar_eliminacion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO eliminaciones_log (tabla_afectada, id_registro_eliminado, usuario)
    VALUES ('users', OLD.id, current_user);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Función para crear un cliente asociado al usuario
CREATE OR REPLACE FUNCTION crear_cliente()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO customers (user_id, name, email, address)
    VALUES (NEW.id, NEW.username || ' Name', NEW.username || '@example.com', 'Default Address');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar el estado a FALSE al eliminar un registro en users
CREATE OR REPLACE FUNCTION actualizar_estado()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE users
        SET status = FALSE
        WHERE id = OLD.id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Función para registrar eliminaciones en eliminaciones_orders
CREATE OR REPLACE FUNCTION order_eliminacion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO eliminaciones_orders (tabla_afectada, id_registro_eliminado, usuario)
    VALUES ('orders', OLD.orderID, current_user);
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Función para actualizar el estado a FALSE al eliminar un registro en orders
CREATE OR REPLACE FUNCTION actualizar_order()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        UPDATE orders
        SET status = FALSE
        WHERE orderID = OLD.orderID;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS

-- Trigger para ejecutar la función actualizar_estado después de DELETE en users
CREATE TRIGGER trigger_actualizar_estado
AFTER DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION actualizar_estado();

-- Trigger para ejecutar la función registrar_eliminacion después de DELETE en users
CREATE TRIGGER after_delete_trigger
AFTER DELETE ON users
FOR EACH ROW
EXECUTE FUNCTION registrar_eliminacion();

-- Trigger para ejecutar la función crear_cliente después de INSERT en users
CREATE TRIGGER after_insert_user
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION crear_cliente();

-- Trigger para ejecutar la función actualizar_order después de DELETE en orders
CREATE TRIGGER trigger_actualizar_order
AFTER DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION actualizar_order();

-- Trigger para ejecutar la función order_eliminacion después de DELETE en orders
CREATE TRIGGER after_delete_order
AFTER DELETE ON orders
FOR EACH ROW
EXECUTE FUNCTION order_eliminacion();


-- PRUEBAS

-- Insertar datos de ejemplo en la tabla users
INSERT INTO users (username, password) VALUES 
('usuario1', 'contraseña1'),
('usuario2', 'contraseña2'),
('usuario3', 'contraseña3');

-- Insertar datos de ejemplo en la tabla products
INSERT INTO products (productName, price) VALUES 
('Product1', 10.00),
('Product2', 20.00),
('Product3', 30.00);

-- Crear un carrito para usuario1
INSERT INTO carts (userID) VALUES (1);

-- Agregar productos al carrito de usuario1
INSERT INTO cart_items (cartID, productID, quantity) VALUES
(1, 1, 2),
(1, 2, 1);

-- Insertar una orden para usuario1
INSERT INTO orders (user_id, orderDate, productID, price) VALUES
(1, CURRENT_DATE, 1, 10.00),
(1, CURRENT_DATE, 2, 20.00);

-- Consultar datos en la tabla users
SELECT * FROM users;

-- Consultar datos en la tabla customers
SELECT * FROM customers;

-- Consultar datos en la tabla products
SELECT * FROM products;

-- Consultar datos en la tabla carts
SELECT * FROM carts;

-- Consultar datos en la tabla cart_items
SELECT * FROM cart_items;

-- Consultar datos en la tabla orders
SELECT * FROM orders;

-- Eliminar un usuario y verificar los registros de eliminación
DELETE FROM users WHERE id = 2;

-- Consultar los registros de eliminaciones
SELECT * FROM eliminaciones_log;




