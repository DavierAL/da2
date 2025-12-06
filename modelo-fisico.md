# Modelo Físico de Base de Datos - MascotifyDB

Este documento describe la implementación física de la base de datos en **Microsoft SQL Server**. Se detallan los tipos de datos exactos, restricciones de integridad, valores por defecto y campos calculados.

## 1. Diagrama Entidad-Relación (ERD Físico)

```mermaid
erDiagram
    %% ---------------------------------------------------------
    %% MÓDULO MAESTROS (TABLAS PARAMÉTRICAS)
    %% ---------------------------------------------------------
    Categoria {
        INT IdCategoria PK "IDENTITY(1,1)"
        NVARCHAR(50) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    Marca {
        INT IdMarca PK "IDENTITY(1,1)"
        NVARCHAR(50) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    Distrito {
        INT IdDistrito PK "IDENTITY(1,1)"
        NVARCHAR(50) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    Rol {
        INT IdRol PK "IDENTITY(1,1)"
        NVARCHAR(40) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    TipoDocumento {
        INT IdTipoDocumento PK "IDENTITY(1,1)"
        NVARCHAR(40) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    EstadoPedido {
        INT IdEstadoPedido PK "IDENTITY(1,1)"
        NVARCHAR(40) Nombre "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    %% ---------------------------------------------------------
    %% MÓDULO PERSONAS Y SEGURIDAD
    %% ---------------------------------------------------------
    Empleado {
        INT IdEmpleado PK "IDENTITY(1,1)"
        NVARCHAR(60) Nombres "NOT NULL"
        NVARCHAR(60) ApellidoPaterno "NOT NULL"
        NVARCHAR(60) ApellidoMaterno "NOT NULL"
        INT IdTipoDocumento FK
        VARCHAR(20) NumeroDocumento "UK, NOT NULL"
        NVARCHAR(150) Direccion
        VARCHAR(15) Telefono
        VARCHAR(15) Celular "NOT NULL"
        NVARCHAR(100) Correo "NOT NULL"
        INT IdDistrito FK
        INT IdRol FK
        VARCHAR(30) Usuario "UK, NOT NULL"
        VARCHAR(255) PasswordHash "NOT NULL"
        BIT Activo "DEFAULT 1"
    }

    Cliente {
        INT IdCliente PK "IDENTITY(1,1)"
        NVARCHAR(60) Nombres "NOT NULL"
        NVARCHAR(60) ApellidoPaterno "NOT NULL"
        NVARCHAR(60) ApellidoMaterno "NOT NULL"
        INT IdTipoDocumento FK
        VARCHAR(20) NumeroDocumento
        NVARCHAR(150) Direccion
        VARCHAR(15) Telefono
        VARCHAR(15) Celular
        NVARCHAR(100) Correo
        INT IdDistrito FK
        BIT Activo "DEFAULT 1"
    }

    %% ---------------------------------------------------------
    %% MÓDULO PRODUCTO E INVENTARIO
    %% ---------------------------------------------------------
    Producto {
        INT IdProducto PK "IDENTITY(1,1)"
        VARCHAR(50) SKU "UK, NOT NULL"
        VARCHAR(50) CodigoBarras
        NVARCHAR(200) Nombre "NOT NULL"
        NVARCHAR(500) Descripcion
        INT IdMarca FK
        INT IdCategoria FK
        DECIMAL(10,2) PrecioCosto
        DECIMAL(10,2) PrecioVenta "NOT NULL"
        VARCHAR(500) ImagenUrl
        BIT Activo "DEFAULT 1"
    }

    Inventario {
        INT IdInventario PK "IDENTITY(1,1)"
        INT IdProducto FK "UK, NOT NULL"
        INT StockActual "DEFAULT 0"
        INT StockMinimo "DEFAULT 5"
        VARCHAR(20) UbicacionPasillo
    }

    %% ---------------------------------------------------------
    %% MÓDULO TRANSACCIONAL
    %% ---------------------------------------------------------
    Pedido {
        INT IdPedido PK "IDENTITY(1,1)"
        VARCHAR(50) NumeroPedidoWeb
        INT IdCliente FK
        DATETIME FechaPedido "DEFAULT GETDATE()"
        VARCHAR(20) Estado
        VARCHAR(20) CanalVenta
        DECIMAL(10,2) Total
        VARCHAR(50) MetodoPago
    }

    DetallePedido {
        INT IdDetalle PK "IDENTITY(1,1)"
        INT IdPedido FK
        INT IdProducto FK
        INT Cantidad "NOT NULL"
        DECIMAL(10,2) PrecioUnitario "NOT NULL"
        DECIMAL(10,2) Subtotal "COMPUTED"
    }

    MovimientoInventario {
        INT IdMovimiento PK "IDENTITY(1,1)"
        INT IdProducto FK
        VARCHAR(20) TipoMovimiento
        INT Cantidad "NOT NULL"
        INT StockResultante "NOT NULL"
        DATETIME FechaMovimiento "DEFAULT GETDATE()"
        VARCHAR(100) Referencia
        INT IdEmpleado FK
    }

    %% RELACIONES
    TipoDocumento ||--o{ Empleado : "FK_Empleado_TipoDoc"
    Distrito ||--o{ Empleado : "FK_Empleado_Distrito"
    Rol ||--o{ Empleado : "FK_Empleado_Rol"

    TipoDocumento ||--o{ Cliente : "FK_Cliente_TipoDoc"
    Distrito ||--o{ Cliente : "FK_Cliente_Distrito"

    Marca ||--o{ Producto : "FK_Producto_Marca"
    Categoria ||--o{ Producto : "FK_Producto_Categoria"

    Producto ||--|| Inventario : "FK_Inventario_Producto"

    Cliente ||--o{ Pedido : "FK_Pedido_Cliente"
    Pedido ||--|{ DetallePedido : "FK_Detalle_Pedido"
    Producto ||--o{ DetallePedido : "FK_Detalle_Producto"

    Producto ||--o{ MovimientoInventario : "FK_Movimiento_Producto"
    Empleado ||--o{ MovimientoInventario : "FK_Movimiento_Empleado"
```

## 2. Diccionario de Datos

### Tablas Maestras

| Tabla         | Campo       | Tipo SQL     | Restricciones | Descripción                 |
| :------------ | :---------- | :----------- | :------------ | :-------------------------- |
| **Categoria** | IdCategoria | INT          | PK, IDENTITY  | Identificador único         |
|               | Nombre      | NVARCHAR(50) | NOT NULL      | Nombre de la categoría      |
| **Marca**     | IdMarca     | INT          | PK, IDENTITY  | Identificador único         |
|               | Nombre      | NVARCHAR(50) | NOT NULL      | Nombre de la marca          |
| **Distrito**  | IdDistrito  | INT          | PK, IDENTITY  | Ubicación geográfica        |
| **Rol**       | IdRol       | INT          | PK, IDENTITY  | Admin, Vendedor, Almacenero |

### Tablas de Negocio

| Tabla          | Campo       | Tipo SQL      | Restricciones    | Descripción                       |
| :------------- | :---------- | :------------ | :--------------- | :-------------------------------- |
| **Producto**   | SKU         | VARCHAR(50)   | UNIQUE, NOT NULL | Código interno único              |
|                | Nombre      | NVARCHAR(200) | NOT NULL         | Nombre comercial (soporta tildes) |
|                | PrecioVenta | DECIMAL(10,2) | NOT NULL         | Moneda con 2 decimales            |
| **Inventario** | IdProducto  | INT           | FK, UNIQUE       | Relación 1 a 1 con Producto       |
|                | StockActual | INT           | DEFAULT 0        | Cantidad física disponible        |

### Tablas Transaccionales

| Tabla             | Campo           | Tipo SQL | Restricciones     | Descripción                            |
| :---------------- | :-------------- | :------- | :---------------- | :------------------------------------- |
| **Pedido**        | FechaPedido     | DATETIME | DEFAULT GETDATE() | Fecha y hora del servidor              |
| **DetallePedido** | Subtotal        | DECIMAL  | COMPUTED          | Campo calculado `(Cantidad * Precio)`  |
| **Movimiento**    | StockResultante | INT      | NOT NULL          | Auditoría del saldo tras el movimiento |

---

_Generado para el proyecto Mascotify - Diciembre 2025_
