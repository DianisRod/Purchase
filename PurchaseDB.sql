
Username: psql -U sebastian
password: Project001

\l //Listar bases de datos
\du //Lista roles de usaurios
\dt //Listar las tablas
\d users// Estructura de la tabla
\c login //Ingresa a la base de datos
-- Otorgar permisos de superusuario
ALTER USER sebastian WITH SUPERUSER;


-- Conectarse a PostgreSQL y crear la base de datos login (ejecutar en el terminal)
psql -U postgres

-- Crear la base de datos purchase
CREATE DATABASE purchase;

-- Conectarse a la base de datos purchase
\c purchase

-- Crear el usuario sebastian con todos los privilegios sobre la base de datos purchase
CREATE USER sebastian WITH PASSWORD 'Project001';
GRANT ALL PRIVILEGES ON DATABASE purchase TO sebastian;

-- Crear la tabla users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    status BOOLEAN DEFAULT TRUE
);

-- Crear la tabla eliminaciones_log
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
    email VARCHAR(255) NOT NULL UNIQUE,
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
    FOREIGN KEY (userID) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_cart_user UNIQUE (userID)
);

-- Crear la tabla cart_items
CREATE TABLE cart_items (
    cartItemID SERIAL PRIMARY KEY,
    cartID INTEGER NOT NULL,
    productID INTEGER NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cartID) REFERENCES carts(cartID) ON DELETE CASCADE,
    FOREIGN KEY (productID) REFERENCES products(productID) ON DELETE CASCADE,
    CONSTRAINT unique_cart_product UNIQUE (cartID, productID)
);

-- Crear la tabla orders
CREATE TABLE orders (
    orderID SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    orderDate DATE DEFAULT CURRENT_DATE,
    status BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Crear la tabla order_items
CREATE TABLE order_items (
    orderItemID SERIAL PRIMARY KEY,
    orderID INTEGER NOT NULL,
    productID INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    quantity INTEGER NOT NULL,
    FOREIGN KEY (orderID) REFERENCES orders(orderID) ON DELETE CASCADE,
    FOREIGN KEY (productID) REFERENCES products(productID) ON DELETE CASCADE
);

-- Crear la tabla eliminaciones_orders
CREATE TABLE eliminaciones_orders (
    id SERIAL PRIMARY KEY,
    tabla_afectada VARCHAR(100) NOT NULL,
    id_registro_eliminado INTEGER NOT NULL,
    fecha_hora TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(100) NOT NULL
);
-- Función para registrar eliminaciones en eliminaciones_log
CREATE OR REPLACE FUNCTION registrar_eliminacion()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO eliminaciones_log (tabla_afectada, id_registro_eliminado, usuario)
    VALUES (TG_TABLE_NAME, OLD.id, current_user);
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

--PRUEBAS

-- Insertar usuarios
INSERT INTO users (username, password) VALUES ('usuario1', 'password1');
INSERT INTO users (username, password) VALUES ('usuario2', 'password2');

-- Insertar productos
INSERT INTO products (productName, price) VALUES ('Producto 1', 9.99);
INSERT INTO products (productName, price) VALUES ('Producto 2', 19.99);

-- Insertar carritos
INSERT INTO carts (userID) VALUES (1);
INSERT INTO carts (userID) VALUES (2);

-- Insertar items en carritos
INSERT INTO cart_items (cartID, productID, quantity) VALUES 
 (1, 1, 2),
 (1, 2, 1),
 (2, 1, 1);

-- Insertar órdenes
INSERT INTO orders (orderID, user_id) VALUES 
(100, 1),
(200, 2);

-- Consultar usuarios
SELECT * FROM users;

-- Consultar clientes
SELECT * FROM customers;

-- Consultar productos
SELECT * FROM products;

-- Consultar carritos
SELECT * FROM carts;

-- Consultar items en carritos
SELECT * FROM cart_items;

-- Consultar órdenes
SELECT * FROM orders;

-- Consultar el log de eliminaciones
SELECT * FROM eliminaciones_log;

-- Consultar el log de eliminaciones de órdenes
SELECT * FROM eliminaciones_orders;

-- Eliminar un usuario
DELETE FROM users WHERE id = 1;

-- Eliminar una orden
DELETE FROM orders WHERE orderid = 200;

-- Consultar usuarios
SELECT * FROM users;

-- Consultar clientes
SELECT * FROM customers;

-- Consultar el log de eliminaciones
SELECT * FROM eliminaciones_log;

-- Consultar órdenes
SELECT * FROM orders;

-- Consultar el log de eliminaciones de órdenes
SELECT * FROM eliminaciones_orders;
