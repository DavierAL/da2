-- cerrar todas las conexiones a la base de datos
use master
go
IF EXISTS(SELECT * from sys.databases WHERE name='MascotifyDB')
BEGIN
    alter database MascotifyDB set single_user
    with rollback immediate
END
go

-- buscamos si existe la base de datos
IF EXISTS(SELECT * from sys.databases WHERE name='MascotifyDB')
BEGIN
    drop DATABASE MascotifyDB
END
go

-- creacion de la base de datos
create database MascotifyDB
go

-- seleccionamos la base de datos
use MascotifyDB
go

-- simples
create table categoria(
codcat integer primary key identity(1,1),
nomcat varchar(50) not null,
estcat bit not null
)
go

create table marca(
codmar integer primary key identity(1,1),
nommar varchar(50) not null,
estmar bit not null
)
go

create table distrito(
coddis integer primary key identity(1,1),
nomdis varchar(50) not null,
estdis bit not null
)
go

create table rol(
codrol integer primary key identity(1,1),
nomrol varchar(40) not null,
estrol bit not null
)
go

create table tipodocumento(
codtipd integer primary key identity(1,1),
nomtipd varchar(40) not null,
esttipd bit not null
)
go

-- cruzadas
create table producto(
codpro integer primary key identity(1,1),
sku varchar(30) not null unique,
codbar varchar(50),
nompro varchar(200) not null,
despro varchar(500),
precos money,
preven money not null,
imgpro varchar(500),
canpro int not null default 0,
estpro bit not null,
codcat integer not null,
codmar integer not null,
foreign key (codcat) references categoria(codcat),
foreign key (codmar) references marca(codmar)
)
go

create table empleado(
codemp integer primary key identity(1,1),
nomemp varchar(60) not null,
apepemp varchar(60) not null,
apememp varchar(60) not null,
docemp varchar(20) not null,
diremp varchar(150),
telemp varchar(15),
celemp varchar(15) not null,
coremp varchar(100) not null,
usuemp varchar(30) not null unique,
claemp varchar(255) not null,
estemp bit not null,
codrol integer not null,
coddis integer not null,
codtipd integer not null,
foreign key (codrol) references rol(codrol),
foreign key (coddis) references distrito(coddis),
foreign key (codtipd) references tipodocumento(codtipd)
)
go

create table cliente(
codcli integer primary key identity(1,1),
nomcli varchar(60) not null,
apepcli varchar(60) not null,
apemcli varchar(60) not null,
doccli varchar(20),
dircli varchar(150),
telcli varchar(15),
celcli varchar(15),
corcli varchar(100),
estcli bit not null,
coddis integer not null,
codtipd integer,
foreign key (coddis) references distrito(coddis),
foreign key (codtipd) references tipodocumento(codtipd)
)
go

-- maestro y detalle
create table ticketpedido(
nroped integer primary key identity(1,1),
fecped datetime not null default getdate(),
codemp integer not null,
codcli integer not null,
estped bit not null default 1,
foreign key (codemp) references empleado(codemp),
foreign key (codcli) references cliente(codcli)
)
go

create table detalleticketpedido(
nrodet integer primary key identity(1,1),
canent integer not null,
preent money not null,
nroped integer not null,
codpro integer not null,
foreign key (nroped) references ticketpedido(nroped),
foreign key (codpro) references producto(codpro)
)
go

-- insertando datos
-- simples
insert into categoria values('Alimento Perros',1)
insert into categoria values('Alimento Gatos',1)
insert into categoria values('Snacks y Premios',1)
insert into categoria values('Juguetes',1)
insert into categoria values('Higiene',1)
insert into categoria values('Accesorios',1)
insert into categoria values('Medicamentos',1)
go

insert into marca values('Royal Canin',1)
insert into marca values('Pedigree',1)
insert into marca values('Pro Plan',1)
insert into marca values('Whiskas',1)
insert into marca values('Cat Chow',1)
insert into marca values('Ricocan',1)
insert into marca values('Mimaskot',1)
go

INSERT INTO distrito VALUES
('Miraflores',1),('San Isidro',1),('Surco',1),('San Borja',1),
('La Molina',1),('Barranco',1),('Magdalena',1),('San Miguel',1)
GO

INSERT INTO rol VALUES
('Administrador',1),('Vendedor',1),('Almacenero',1)
GO

INSERT INTO tipodocumento VALUES
('DNI',1),('RUC',1),('Pasaporte',1),('Carnet Extranjeria',1)
GO

-- cruzadas
insert into empleado values
('Carlos','Admin','Mascotify','00000001','Av. Principal 123','44556677','987654321','admin@mascotify.pe','admin','admin123',1,1,1,1),
('María','López','Ramírez','71234567','Jr. Las Flores 456','','987123456','maria@mascotify.pe','maria','maria123',1,2,2,1),
('José','García','Torres','72345678','Calle Almacén 100','','988112233','jose@mascotify.pe','jose','jose123',1,3,3,1)
GO

insert into cliente values
('Juan','Pérez','Gómez','12345678','Av. Larco 1234','4455667','987654321','juan@gmail.com',1,1,1),
('Ana','Rojas','Torres','87654321','Jr. Los Pinos 567','','987112233','ana@hotmail.com',1,2,1),
('Luis','Mendoza','Cruz','44555666','Calle 28 de Julio 321','','988223344','luis@gmail.com',1,4,1)
GO

insert into producto values
('ROY001','7751001002001','Royal Canin Maxi Adult 15kg','Alimento premium perros grandes',280.00,349.90,'/img/royal.jpg',25,1,1,1),
('PED002','7752002003002','Pedigree Adulto 21kg','Alimento balanceado perros',110.00,149.90,'/img/pedigree.jpg',40,1,2,1),
('WHI003','7753003004003','Whiskas Pescado 10kg','Alimento gatos adultos',95.00,129.90,'/img/whiskas.jpg',30,1,4,2)
go

-- Mostrando informacion de la base de datos
-- simples
select * from categoria
select * from marca
select * from distrito
select * from tipodocumento
select * from rol
select * from empleado
select * from cliente
select * from producto
go

-- cruzadas
select p.codpro, p.sku, p.nompro, p.preven, p.canpro, p.estpro,
       c.nomcat, m.nommar 
from producto p 
inner join categoria c on p.codcat=c.codcat 
inner join marca m on p.codmar=m.codmar
go

-- maestro detalle (ejemplo de un pedido)
select * from ticketpedido
select * from detalleticketpedido
go