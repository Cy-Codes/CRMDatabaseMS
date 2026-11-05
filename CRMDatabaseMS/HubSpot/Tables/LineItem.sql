CREATE TABLE [HubSpot].[LineItem]
(
    [lineItemId] BIGINT NOT NULL,
    [dealId] BIGINT NOT NULL,
    [productId] BIGINT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [quantity] DECIMAL(12, 2) NOT NULL CONSTRAINT [DF_HubSpot_LineItem_quantity] DEFAULT (1),
    [price] DECIMAL(18, 2) NOT NULL,
    [amount] AS (CAST([quantity] * [price] AS DECIMAL(18, 2))),
    [discount] DECIMAL(18, 2) NOT NULL CONSTRAINT [DF_HubSpot_LineItem_discount] DEFAULT (0.00),
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_LineItem_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_LineItem_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_LineItem_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_LineItem] PRIMARY KEY CLUSTERED ([lineItemId] ASC),
    CONSTRAINT [FK_HubSpot_LineItem_dealId] FOREIGN KEY ([dealId]) REFERENCES [HubSpot].[Deal] ([dealId]),
    CONSTRAINT [FK_HubSpot_LineItem_productId] FOREIGN KEY ([productId]) REFERENCES [HubSpot].[Product] ([productId])
);
