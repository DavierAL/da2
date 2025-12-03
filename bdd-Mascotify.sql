CREATE DATABASE MascotifyDB;
GO
USE MascotifyDB;
GO

-- 1. Tabla de Usuarios (Para el Login del sistema MVC)
CREATE TABLE Usuario (
    IdUsuario INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    PasswordHash VARCHAR(255) NOT NULL, 
    Rol VARCHAR(20) NOT NULL CHECK (Rol IN ('Admin', 'Almacenero', 'Vendedor')),
    Estado BIT DEFAULT 1 -- 1: Activo, 0: Inactivo
);

-- 2. Tablas Maestras (Normalización)
CREATE TABLE Marca (
    IdMarca INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

CREATE TABLE Categoria (
    IdCategoria INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL
);

-- 3. Tabla Producto (Datos Maestros / Fijos)
CREATE TABLE Producto (
    IdProducto INT IDENTITY(1,1) PRIMARY KEY,
    SKU VARCHAR(50) UNIQUE NOT NULL,       -- Código único (Ej. MON001...)
    CodigoBarras VARCHAR(50),              -- Código escaneable
    Nombre VARCHAR(200) NOT NULL,
    Descripcion VARCHAR(500),
    IdMarca INT FOREIGN KEY REFERENCES Marca(IdMarca),
    IdCategoria INT FOREIGN KEY REFERENCES Categoria(IdCategoria),
    PrecioCosto DECIMAL(10,2),             -- Costo promedio
    PrecioVenta DECIMAL(10,2) NOT NULL,    -- Precio público
    ImagenUrl VARCHAR(500),
    Estado BIT DEFAULT 1
);

-- 4. Tabla Inventario (Datos Transaccionales / Volátiles)
CREATE TABLE Inventario (
    IdInventario INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT UNIQUE FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad INT NOT NULL DEFAULT 0, -- Stock Físico Real
    StockMinimo INT DEFAULT 5,       -- Para alertas de reabastecimiento
    UbicacionPasillo VARCHAR(20)     -- Dónde está en la estantería de Miraflores
);

-- 5. Tabla Clientes
CREATE TABLE Cliente (
    IdCliente INT IDENTITY(1,1) PRIMARY KEY,
    NombreCompleto VARCHAR(150) NOT NULL,
    DNI_RUC VARCHAR(20),
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    DireccionEntrega VARCHAR(255),
    Distrito VARCHAR(50)
);

-- 6. Tabla Pedidos (Cabecera)
CREATE TABLE Pedido (
    IdPedido INT IDENTITY(1,1) PRIMARY KEY,
    NumeroPedidoWeb VARCHAR(50), -- Nro Orden WooCommerce (#163272)
    IdCliente INT FOREIGN KEY REFERENCES Cliente(IdCliente),
    FechaPedido DATETIME DEFAULT GETDATE(),
    Estado VARCHAR(20) DEFAULT 'Pendiente', 
    -- Estados: 'Pendiente', 'Pagado', 'EnPicking', 'Despachado', 'Entregado', 'Cancelado'
    CanalVenta VARCHAR(20), -- 'Web', 'WhatsApp', 'TiendaFisica'
    Total DECIMAL(10,2),
    MetodoPago VARCHAR(50) -- Yape, Plin, Tarjeta, Efectivo
);

-- 7. Tabla Detalle de Pedido
CREATE TABLE DetallePedido (
    IdDetalle INT IDENTITY(1,1) PRIMARY KEY,
    IdPedido INT FOREIGN KEY REFERENCES Pedido(IdPedido),
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    Cantidad INT NOT NULL,
    PrecioUnitario DECIMAL(10,2) NOT NULL,
    Subtotal AS (Cantidad * PrecioUnitario) PERSISTED
);

-- 8. Tabla MovimientoInventario (Kardex / Auditoría)
-- Registra CADA cambio en el stock para saber quién fue y por qué.
CREATE TABLE MovimientoInventario (
    IdMovimiento INT IDENTITY(1,1) PRIMARY KEY,
    IdProducto INT FOREIGN KEY REFERENCES Producto(IdProducto),
    TipoMovimiento VARCHAR(20), 
    -- Tipos: 'EntradaCompra', 'SalidaVentaWeb', 'SalidaVentaTienda', 'AjusteInventario'
    Cantidad INT NOT NULL, -- Positivo (+) entra, Negativo (-) sale
    StockResultante INT NOT NULL, -- Cuánto quedó después del movimiento (Foto del momento)
    FechaMovimiento DATETIME DEFAULT GETDATE(),
    Referencia VARCHAR(100), -- Nro Pedido o Factura Proveedor
    IdUsuario INT FOREIGN KEY REFERENCES Usuario(IdUsuario) -- Quién hizo la acción
);