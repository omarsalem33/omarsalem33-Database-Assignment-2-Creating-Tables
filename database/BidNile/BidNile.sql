CREATE DATABASE BidNile;
GO 
USE BidNile;
GO

GO
CREATE SCHEMA Membership AUTHORIZATION dbo;
GO
CREATE SCHEMA Logistics AUTHORIZATION dbo;
GO
CREATE SCHEMA Catalog AUTHORIZATION dbo;
GO
CREATE SCHEMA Bidding     AUTHORIZATION dbo;
GO

--  Membership schema

CREATE TABLE Membership.Member
(
	MemberId     UNIQUEIDENTIFIER NOT NULL
                 CONSTRAINT DF_Member_MemberId DEFAULT NEWID(),
    FullName     NVARCHAR(100)    NOT NULL,
    Email        VARCHAR(254)     NOT NULL,
    Mobile       VARCHAR(16)      NOT NULL,
    NationalId   VARCHAR(20)      NOT NULL,
    BirthDate    DATE             NOT NULL,
    IsVerified   BIT              NOT NULL
                 CONSTRAINT DF_Member_IsVerified DEFAULT 0,
    RegisteredAt DATETIME2(3)     NOT NULL
                 CONSTRAINT DF_Member_RegisteredAt DEFAULT SYSUTCDATETIME(),
    CityId       INT              NOT NULL,
    InvitedById  UNIQUEIDENTIFIER NULL,
    CONSTRAINT PK_Member PRIMARY KEY (MemberId),
    CONSTRAINT UQ_Member_Email UNIQUE (Email),
    CONSTRAINT UQ_Member_NationalId UNIQUE (NationalId)
	
);
CREATE TABLE Membership.City
(
    CityId INT IDENTITY(1,1) NOT NULL,
		CONSTRAINT PK_City PRIMARY KEY (CityId),
    Name NVARCHAR(60) NOT NULL,
		CONSTRAINT CK_City_CountryCode  CHECK (CountryCode IN ('EG','SA','AE')),
    CountryCode CHAR(2) NOT NULL,
		CONSTRAINT UQ_City_Country_Name UNIQUE (CountryCode, Name)   
);

CREATE TABLE Membership.Wallet
(
    MemberId    UNIQUEIDENTIFIER NOT NULL,           
    Balance     DECIMAL(12,2)    NOT NULL            
                CONSTRAINT DF_Wallet_Balance DEFAULT 0
                CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),     
    HeldAmount  DECIMAL(12,2)    NOT NULL
                CONSTRAINT DF_Wallet_HeldAmount DEFAULT 0
                CONSTRAINT CK_Wallet_HeldAmount CHECK (HeldAmount >= 0),
    Currency    CHAR(3)          NOT NULL
                CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',
    UpdatedAt   DATETIME2(3)     NOT NULL
                CONSTRAINT DF_Wallet_UpdatedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Wallet PRIMARY KEY (MemberId),
    CONSTRAINT CK_Wallet_HeldNotAboveBalance CHECK (HeldAmount <= Balance)  
);


-- Logistics schema

CREATE TABLE Logistics.Warehouse
(
   WarehouseId INT IDENTITY(1,1) NOT NULL,
   Name NVARCHAR(80) NOT NULL,
   Capacity INT NOT NULL,
        CONSTRAINT CK_Warehouse_Capacity CHECK(Capacity>0),
   CityId INT NOT NULL, 
   Latitude FLOAT NOT NULL,
        CONSTRAINT CK_Warehouse_Latitude CHECK (Latitude BETWEEN -90 AND 90),
   ManagerId UNIQUEIDENTIFIER NULL, 
   ManagerSince DATE NULL,
   
   CONSTRAINT PK_Warehouse PRIMARY KEY (WarehouseId),
   CONSTRAINT UQ_Warehouse_Name UNIQUE (Name),
   CONSTRAINT CK_Warehouse_Manager CHECK ((ManagerId IS NULL AND ManagerSince IS NULL)
                                           OR (ManagerId IS NOT NULL AND ManagerSince IS NOT NULL))
);

CREATE TABLE Logistics.Employee
(
    MemberId UNIQUEIDENTIFIER NOT NULL,         
    WarehouseId INT NOT NULL,         
    CONSTRAINT PK_Employee PRIMARY KEY (MemberId)
);

-- Catalog schema 
CREATE TABLE Catalog.Category
(
    CategoryId INT NOT NULL,        
    ParentCategoryId INT NULL,         
    NameEn VARCHAR(50)   NOT NULL,
    NameAr NVARCHAR(50)  NULL,
    CommissionPct DECIMAL(4,2)  NOT NULL,       
    CONSTRAINT PK_Category PRIMARY KEY (CategoryId),
    CONSTRAINT UQ_Category_NameEn UNIQUE (NameEn),
    CONSTRAINT CK_Category_CommissionPct CHECK (CommissionPct BETWEEN 0 AND 30),
    CONSTRAINT CK_Category_NotOwnParent  CHECK (ParentCategoryId IS NULL OR ParentCategoryId <> CategoryId)
);

CREATE TABLE Catalog.Item
(
    ItemId INT IDENTITY(1,1) NOT NULL,
    SellerId UNIQUEIDENTIFIER NOT NULL,
    CategoryId INT NOT NULL,
    WarehouseId IT


);