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
    WarehouseId INT  NULL,
    InspectorId UNIQUEIDENTIFIER NULL,
    Title NVARCHAR(150) NOT NULL,
    Description NVARCHAR(MAX) NULL,
    ConditionScore TINYINT NOT NULL,
        CONSTRAINT CK_Item_ConditionScore CHECK(ConditionScore BETWEEN 1 AND 10),
    Specifications  NVARCHAR(MAX) NOT NULL
        CONSTRAINT CK_Item_Specifications CHECK (ISJSON(Specifications) = 1),
    ListedAt DATETIME2(3) NOT NULL
        CONSTRAINT DF_Item_ListedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_Item PRIMARY KEY (ItemId),
    CONSTRAINT CK_Item_InspectorNotSeller CHECK (InspectorId IS NULL OR InspectorId <> SellerId)
);

CREATE TABLE Catalog.ItemPhoto
(
    ItemId INT NOT NULL,              
    Position TINYINT NOT NULL
        CONSTRAINT CK_ItemPhoto_Position CHECK (Position BETWEEN 1 AND 20),
    Url VARCHAR(500) NOT NULL,
    IsMain BIT NOT NULL
        CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,
    CONSTRAINT PK_ItemPhoto PRIMARY KEY (ItemId, Position)  
);


-- Bidding Shcema     
CREATE TABLE Bidding.Auction
(
    AuctionId      INT IDENTITY(1,1) NOT NULL,
    ItemId         INT               NOT NULL,       
    StartingPrice  DECIMAL(12,2)     NOT NULL
                   CONSTRAINT CK_Auction_StartingPrice CHECK (StartingPrice > 0),
    ReservePrice   DECIMAL(12,2)     NULL,           
    BidIncrement   DECIMAL(12,2)     NOT NULL
                   CONSTRAINT DF_Auction_BidIncrement DEFAULT 50.00
                   CONSTRAINT CK_Auction_BidIncrement CHECK (BidIncrement > 0),
    StartsAt       DATETIMEOFFSET    NOT NULL,     
    EndsAt         DATETIMEOFFSET    NOT NULL,
    Status         VARCHAR(15)       NOT NULL
                   CONSTRAINT DF_Auction_Status DEFAULT 'Draft',
    CONSTRAINT PK_Auction         PRIMARY KEY (AuctionId),
    CONSTRAINT CK_Auction_Status  CHECK (Status IN ('Draft','Live','Ended','Cancelled')),
    CONSTRAINT CK_Auction_Reserve CHECK (ReservePrice IS NULL OR ReservePrice >= StartingPrice),
    CONSTRAINT CK_Auction_Dates   CHECK (EndsAt > StartsAt)
);
GO

CREATE TABLE Bidding.Bid
(
    BidId       BIGINT IDENTITY(1,1) NOT NULL,
    AuctionId   INT                  NOT NULL,     
    MemberId    UNIQUEIDENTIFIER     NOT NULL,      
    Amount      DECIMAL(12,2)        NOT NULL
                CONSTRAINT CK_Bid_Amount CHECK (Amount > 0),
    PlacedAt    DATETIME2(3)         NOT NULL
                CONSTRAINT DF_Bid_PlacedAt DEFAULT SYSUTCDATETIME(),
    IpAddress   VARCHAR(45)          NOT NULL,       
    CONSTRAINT PK_Bid PRIMARY KEY (BidId),
    CONSTRAINT UQ_Bid_Auction_Amount UNIQUE (AuctionId, Amount)   
);

CREATE TABLE Bidding.AuctionFollow
(
    MemberId    UNIQUEIDENTIFIER NOT NULL,         
    AuctionId   INT              NOT NULL,          
    FollowedAt  DATETIME2(3)     NOT NULL
                CONSTRAINT DF_AuctionFollow_FollowedAt DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AuctionFollow PRIMARY KEY (MemberId, AuctionId)  
);

-- Task 3 --
-- 3.1
ALTER TABLE Membership.Member
    ADD CONSTRAINT FK_Member_City FOREIGN KEY ( CityId)
    REFERENCES Membership.City (CityId) ON DELETE NO ACTION;
GO
ALTER TABLE Membership.Member
    ADD CONSTRAINT FK_Member_Member_Inviter FOREIGN KEY (InvitedById)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Membership.Wallet
    ADD CONSTRAINT FK_Wallet_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT FK_Warehouse_City FOREIGN KEY (CityId)
        REFERENCES Membership.City (CityId) ON DELETE NO ACTION;
GO
ALTER TABLE Logistics.Employee
    ADD CONSTRAINT FK_Employee_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Logistics.Employee
    ADD CONSTRAINT FK_Employee_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES Logistics.Warehouse (WarehouseId) ON DELETE NO ACTION;
GO
ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT FK_Warehouse_Employee_Manager FOREIGN KEY (ManagerId)
        REFERENCES Logistics.Employee (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.Category
    ADD CONSTRAINT FK_Category_Category_Parent FOREIGN KEY (ParentCategoryId)
        REFERENCES Catalog.Category (CategoryId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Member_Seller FOREIGN KEY (SellerId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Member_Inspector FOREIGN KEY (InspectorId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Category FOREIGN KEY (CategoryId)
        REFERENCES Catalog.Category (CategoryId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.Item
    ADD CONSTRAINT FK_Item_Warehouse FOREIGN KEY (WarehouseId)
        REFERENCES Logistics.Warehouse (WarehouseId) ON DELETE NO ACTION;
GO
ALTER TABLE Catalog.ItemPhoto
    ADD CONSTRAINT FK_ItemPhoto_Item FOREIGN KEY (ItemId)
        REFERENCES Catalog.Item (ItemId) ON DELETE CASCADE;
GO
ALTER TABLE Bidding.Auction
    ADD CONSTRAINT FK_Auction_Item FOREIGN KEY (ItemId)
        REFERENCES Catalog.Item (ItemId) ON DELETE NO ACTION;
GO
ALTER TABLE Bidding.Bid
    ADD CONSTRAINT FK_Bid_Auction FOREIGN KEY (AuctionId)
        REFERENCES Bidding.Auction (AuctionId) ON DELETE NO ACTION;
GO
ALTER TABLE Bidding.Bid
    ADD CONSTRAINT FK_Bid_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Bidding.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Member FOREIGN KEY (MemberId)
        REFERENCES Membership.Member (MemberId) ON DELETE NO ACTION;
GO
ALTER TABLE Bidding.AuctionFollow
    ADD CONSTRAINT FK_AuctionFollow_Auction FOREIGN KEY (AuctionId)
        REFERENCES Bidding.Auction (AuctionId) ON DELETE NO ACTION;
GO

-- 3.2 
ALTER TABLE Membership.Member
    ADD AppLanguage CHAR(2) NOT NULL
        CONSTRAINT DF_Member_AppLanguage DEFAULT 'ar'
        CONSTRAINT CK_Member_AppLanguage CHECK(AppLanguage IN('ar','en'));

-- 3.3
ALTER TABLE Catalog.Item
    ADD IsFeatured BIT NOT NULL
        CONSTRAINT DF_Item_IsFeatured DEFAULT 0;
-- 3.4 

-- 3.5
ALTER TABLE Membership.Member
    ALTER COLUMN FullName NVARCHAR(150) NOT NULL;

--3.6
ALTER TABLE Logistics.Warehouse
    DROP CONSTRAINT CK_Warehouse_Capacity;

ALTER TABLE Logistics.Warehouse
    ALTER COLUMN Capacity SMALLINT NOT NULL;

ALTER TABLE Logistics.Warehouse
    ADD CONSTRAINT  CK_Warehouse_Capacity CHECK (Capacity > 0 AND Capacity<=30000);

--3.7
ALTER TABLE Catalog.Category
    DROP CONSTRAINT CK_Category_CommissionPct;
ALTER TABLE Catalog.Category
    ADD CONSTRAINT CK_Category_CommissionPct CHECK (CommissionPct BETWEEN 0 AND 25);

-- 3.8

ALTER TABLE Bidding.Auction
    DROP CONSTRAINT CK_Auction_Status ;

ALTER TABLE Bidding.Auction
    ADD CONSTRAINT CK_Auction_Status CHECK (Status IN ('PendingReview','Draft','Live','Ended','Cancelled'));

ALTER TABLE Bidding.Auction
    DROP CONSTRAINT DF_Auction_Status;
ALTER TABLE Bidding.Auction
    ADD CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview' FOR Status;

--3.9
ALTER TABLE Bidding.Auction
    ADD  BuyNowPrice DECIMAL(12,2) NULL;

ALTER TABLE Bidding.Auction WITH CHECK
    ADD CONSTRAINT CK_Auction_BuyNowPrice
        CHECK (BuyNowPrice IS NULL OR BuyNowPrice > StartingPrice);
--      WITH CHECK makes the constraint trusted so the optimizer can rely on it
--      WITH NOCHECK would leave it untrusted for no benefit

--3.10
ALTER TABLE Membership.Member 
    ADD CONSTRAINT UQ_Mobile UNIQUE (Mobile);

--3.11
ALTER TABLE Membership.Member 
    ADD VerifiedAt DATETIME2(3) NULL;

ALTER TABLE Membership.Member
    DROP CONSTRAINT DF_Member_IsVerified;

UPDATE Membership.Member
    SET VerifiedAt = SYSUTCDATETIME()
WHERE IsVerified = 1;

ALTER TABLE Membership.Member
    DROP COLUMN IsVerified;
-- 3.12
GO
CREATE SCHEMA Marketing AUTHORIZATION dbo;
GO
ALTER SCHEMA Marketing TRANSFER Bidding.AuctionFollow;