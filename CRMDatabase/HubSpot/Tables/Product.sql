CREATE TABLE [HubSpot].[Product]
(
    [productId] BIGINT NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [sku] NVARCHAR(100) NULL,
    [description] NVARCHAR(MAX) NULL,
    [price] DECIMAL(18, 2) NOT NULL,
    [cost] DECIMAL(18, 2) NULL,
    [recurringBillingFrequency] NVARCHAR(50) NULL,
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Product_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Product_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Product_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Product] PRIMARY KEY CLUSTERED ([productId] ASC)
);
