-- 1. CONTROL DE BASE DE DATOS
USE master;
GO

IF EXISTS(SELECT * FROM sys.databases WHERE name='MascotifyDB')
BEGIN
    ALTER DATABASE MascotifyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MascotifyDB;
END
GO

CREATE DATABASE MascotifyDB;
GO

USE MascotifyDB;
GO

-- =============================================
-- 2. TABLAS MAESTRAS (CATÁLOGOS)
-- =============================================

CREATE TABLE Categoria (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL,
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Marca (
    IdMarca INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL,
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Distrito (
    IdDistrito INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(50) NOT NULL,
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Rol (
    IdRol INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(40) NOT NULL, -- Admin, Vendedor, Almacenero
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE TipoDocumento (
    IdTipoDocumento INT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(40) NOT NULL, -- DNI, RUC, Carnet Ext.
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE EstadoPedido (
    IdEstadoPedido NT IDENTITY(1,1) PRIMARY KEY,
    Nombre NVARCHAR(40) NOT NULL, -- Pendiente, Pagado, Despachado, Cancelado
    Activo BIT DEFAULT 1
);

-- =============================================
-- 3. ENTIDADES PRINCIPALES (PERSONAS)
-- =============================================

CREATE TABLE Empleado (
    IdEmpleado INT IDENTITY(1,1) PRIMARY KEY,
    Nombres NVARCHAR(60) NOT NULL,
    ApellidoPaterno NVARCHAR(60) NOT NULL,
    ApellidoMaterno NVARCHAR(60) NOT NULL,
    IdTipoDocumento INT FOREIGN KEY REFERENCES TipoDocumento(IdTipoDocumento),
    NumeroDocumento VARCHAR(20) UNIQUE NOT NULL,
    Direccion NVARCHAR(150),
    Telefono VARCHAR(15),
    Celular VARCHAR(15) NOT NULL,
    Correo NVARCHAR(100) NOT NULL,
    IdDistrito INT FOREIGN KEY REFERENCES Distrito(IdDistrito),
    IdRol INT FOREIGN KEY REFERENCES Rol(IdRol),
    
    -- Credenciales de Acceso (Login)
    Usuario VARCHAR(30) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL, -- En producción, esto debe estar encriptado
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Cliente (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    Nombres NVARCHAR(60) NOT NULL,
    ApellidoPaterno NVARCHAR(60) NOT NULL,
    ApellidoMaterno NVARCHAR(60) NOT NULL,
    IdTipoDocumento INT FOREIGN KEY REFERENCES TipoDocumento(IdTipoDocumento),
    NumeroDocumento VARCHAR(20),
    Direccion NVARCHAR(150),
    Telefono VARCHAR(15),
    Celular VARCHAR(15),
    Correo NVARCHAR(100),
    IdDistrito INT FOREIGN KEY REFERENCES Distrito(IdDistrito),
    Activo BIT DEFAULT 1
);
GO

-- =============================================
-- 4. PRODUCTOS E INVENTARIO
-- =============================================

CREATE TABLE Producto (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    SKU VARCHAR(50) UNIQUE NOT NULL,       -- Código interno único
    CodigoBarras VARCHAR(50),              -- Código escaneable
    Nombre NVARCHAR(200) NOT NULL,
    Descripcion NVARCHAR(500),
    IdMarca INT FOREIGN KEY REFERENCES Marca(IdMarca),
    IdCategoria INT FOREIGN KEY REFERENCES Categoria(IdCategoria),
    PrecioCosto DECIMAL(10,2),             -- Cuánto nos costó
    PrecioVenta DECIMAL(10,2) NOT NULL,    -- A cuánto lo vendemos
    ImagenUrl VARCHAR(500),
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE Inventario (
    IdInventario INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT UNIQUE FOREIGN KEY REFERENCES Producto(IdProducto),
    StockActual INT NOT NULL DEFAULT 0,
    StockMinimo INT DEFAULT 5,
    UbicacionPasillo VARCHAR(20) -- Ejemplo: 'A-12'
);
GO

-- =============================================
-- 5. TRANSACCIONAL (PEDIDOS)
-- =============================================

CREATE TABLE Pedido (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY,
    NumeroPedidoWeb VARCHAR(50), -- Para integrar con WooCommerce
    IdCliente INT FOREIGN KEY REFERENCES Cliente(IdCliente),
    FechaPedido DATETIME DEFAULT GETDATE(),
    Estado VARCHAR(20) DEFAULT 'Pendiente', -- Pendiente, Pagado, Despachado, Cancelado
    CanalVenta VARCHAR(20), -- Web, Tienda, WhatsApp
    Total DECIMAL(10,2),
    MetodoPago VARCHAR(50) -- Yape, Tarjeta, Efectivo
);
GO

CREATE TABLE DetallePedido (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT FOREIGN KEY REFERENCES Pedido(IdPedido),
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED -- Campo calculado automático
);
GO

CREATE TABLE MovimientoInventario (
    IdMovimiento INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    TipoMovimiento VARCHAR(20), -- Entrada, Salida, Ajuste
    Cantidad INT NOT NULL, 
    StockResultante INT NOT NULL, -- Auditoría: cuánto había después de mover
    FechaMovimiento DATETIME DEFAULT GETDATE(),
    Referencia VARCHAR(100), -- Nro Pedido o Factura Compra
    IdEmpleado INT FOREIGN KEY REFERENCES Empleado(IdEmpleado) -- Quién hizo el movimiento
);
GO

-- =============================================
-- 6. INSERTANDO DATOS (SEED DATA)
-- =============================================

-- Maestros
INSERT INTO Categoria (Nombre) VALUES ('Alimento Perros'),('Alimento Gatos'),('Snacks'),('Juguetes'),('Higiene'),('Accesorios'),('Medicamentos');
INSERT INTO Marca (Nombre) VALUES ('Royal Canin'),('Pedigree'),('Pro Plan'),('Whiskas'),('Cat Chow'),('Ricocan'),('Mimaskot');
INSERT INTO Distrito (Nombre) VALUES ('Miraflores'),('San Isidro'),('Surco'),('San Borja'),('La Molina'),('Barranco'),('Magdalena'),('San Miguel');
INSERT INTO Rol (Nombre) VALUES ('Administrador'),('Vendedor'),('Almacenero');
INSERT INTO TipoDocumento (Nombre) VALUES ('DNI'),('RUC'),('Pasaporte'),('Carnet Extranjeria');
GO

-- Empleados
-- Nota: IdTipoDocumento 1 es DNI, IdDistrito 1 es Miraflores, IdRol 1 es Admin
INSERT INTO Empleado (Nombres, ApellidoPaterno, ApellidoMaterno, IdTipoDocumento, NumeroDocumento, Direccion, Telefono, Celular, Correo, IdDistrito, IdRol, Usuario, PasswordHash) VALUES
('Carlos', 'Admin', 'Mascotify', 1, '00000001', 'Av. Principal 123', '44556677', '987654321', 'admin@mascotify.pe', 1, 1, 'admin', 'admin123'),
('María', 'López', 'Ramírez', 1, '71234567', 'Jr. Las Flores 456', NULL, '987123456', 'maria@mascotify.pe', 2, 2, 'maria', 'maria123'),
('José', 'García', 'Torres', 1, '72345678', 'Calle Almacén 100', NULL, '988112233', 'jose@mascotify.pe', 3, 3, 'jose', 'jose123');
GO

-- Clientes
INSERT INTO Cliente (Nombres, ApellidoPaterno, ApellidoMaterno, IdTipoDocumento, NumeroDocumento, Direccion, Telefono, Celular, Correo, IdDistrito) VALUES
('Juan', 'Pérez', 'Gómez', 1, '12345678', 'Av. Larco 1234', '4455667', '987654321', 'juan@gmail.com', 1),
('Ana', 'Rojas', 'Torres', 1, '87654321', 'Jr. Los Pinos 567', NULL, '987112233', 'ana@hotmail.com', 2),
('Luis', 'Mendoza', 'Cruz', 1, '44555666', 'Calle 28 de Julio 321', NULL, '988223344', 'luis@gmail.com', 4);
GO

-- Productos (Datos fijos)
INSERT INTO Producto (SKU, CodigoBarras, Nombre, Descripcion, IdMarca, IdCategoria, PrecioCosto, PrecioVenta, ImagenUrl, Activo) VALUES
('ROY001', '7751001002001', 'Royal Canin Maxi Adult 15kg', 'Alimento premium perros grandes', 1, 1, 280.00, 349.90, '/img/royal.jpg', 1),
('PED002', '7752002003002', 'Pedigree Adulto 21kg', 'Alimento balanceado perros', 2, 1, 110.00, 149.90, '/img/pedigree.jpg', 1),
('WHI003', '7753003004003', 'Whiskas Pescado 10kg', 'Alimento gatos adultos', 4, 2, 95.00, 129.90, '/img/whiskas.jpg', 1);
GO

-- Inventario (Stock Inicial)
-- Nota: IdProducto 1, 2, 3 se generaron arriba.
INSERT INTO Inventario (IdProducto, StockActual, StockMinimo, UbicacionPasillo) VALUES
(1, 25, 5, 'A-01'), -- Royal Canin
(2, 40, 10, 'B-05'), -- Pedigree
(3, 30, 5, 'C-02'); -- Whiskas
GO

-- =============================================
-- 7. CONSULTAS DE PRUEBA
-- =============================================

-- Consulta de Productos con su Stock y Marcas (Join Completo)
SELECT 
    p.SKU, 
    p.Nombre AS Producto, 
    m.Nombre AS Marca, 
    c.Nombre AS Categoria, 
    p.PrecioVenta, 
    i.StockActual, 
    i.UbicacionPasillo
FROM Producto p
INNER JOIN Marca m ON p.IdMarca = m.IdMarca
INNER JOIN Categoria c ON p.IdCategoria = c.IdCategoria
LEFT JOIN Inventario i ON p.IdProducto = i.IdProducto;
GO