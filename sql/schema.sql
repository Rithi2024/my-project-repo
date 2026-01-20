/* ===============================
   Database: flutter_test
   SQL Server schema
   =============================== */

IF DB_ID('flutter_test') IS NULL
BEGIN
    CREATE DATABASE flutter_test;
END
GO

USE flutter_test;
GO

/* ===============================
   Table: Categories
   =============================== */
IF OBJECT_ID('dbo.Categories', 'U') IS NOT NULL
    DROP TABLE dbo.Categories;
GO

CREATE TABLE dbo.Categories (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(500) NULL,
    created_at DATETIME DEFAULT GETDATE()
);
GO

/* ===============================
   Table: Users
   =============================== */
IF OBJECT_ID('dbo.Users', 'U') IS NOT NULL
    DROP TABLE dbo.Users;
GO

CREATE TABLE dbo.Users (
    id INT IDENTITY(1,1) PRIMARY KEY,
    email NVARCHAR(255) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);
GO

/* ===============================
   Table: PasswordOtps
   =============================== */
IF OBJECT_ID('dbo.PasswordOtps', 'U') IS NOT NULL
    DROP TABLE dbo.PasswordOtps;
GO

CREATE TABLE dbo.PasswordOtps (
    id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL,
    otp NVARCHAR(6),
    expires_at DATETIME,
    CONSTRAINT FK_PasswordOtps_Users
        FOREIGN KEY (user_id) REFERENCES dbo.Users(id)
);
GO

/* ===============================
   Table: Products
   =============================== */
IF OBJECT_ID('dbo.Products', 'U') IS NOT NULL
    DROP TABLE dbo.Products;
GO

CREATE TABLE dbo.Products (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(500),
    category_id INT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0,
    image_url NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Products_Categories
        FOREIGN KEY (category_id) REFERENCES dbo.Categories(id)
);
GO

/* ===============================
   Indexes (optional)
   =============================== */
CREATE INDEX IX_Categories_Name ON dbo.Categories(name);
CREATE INDEX IX_Products_Name ON dbo.Products(name);
CREATE INDEX IX_Products_Category ON dbo.Products(category_id);
GO

/* ===============================
   Sample data (optional)
   =============================== */
-- INSERT INTO Categories(name, description) VALUES
-- (N'Electronics', N'Electronic items'),
-- (N'Books', N'Books category');

PRINT 'Database schema created successfully';
GO
