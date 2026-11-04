CREATE TABLE [Dynamics365].[Product]
(
    [productid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_Product_productid] DEFAULT (NEWID()),
    [productnumber] NVARCHAR(100) NOT NULL,
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [price] DECIMAL(18, 2) NULL,
    [standardcost] DECIMAL(18, 2) NULL,
    [currentcost] DECIMAL(18, 2) NULL,
    [quantityonhand] DECIMAL(12, 2) NOT NULL CONSTRAINT [DF_Dynamics365_Product_quantityonhand] DEFAULT (0.00),
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Product_statecode] DEFAULT (0),
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Product_statuscode] DEFAULT (1),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Product_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Product_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_Product] PRIMARY KEY CLUSTERED ([productid] ASC),
    CONSTRAINT [FK_Dynamics365_Product_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Product_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
