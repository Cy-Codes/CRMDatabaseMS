CREATE TABLE [Dynamics365].[OpportunityProduct]
(
    [opportunityproductid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_OpportunityProduct_opportunityproductid] DEFAULT (NEWID()),
    [opportunityid] UNIQUEIDENTIFIER NOT NULL,
    [productid] UNIQUEIDENTIFIER NULL,
    [productdescription] NVARCHAR(500) NULL,
    [priceperunit] DECIMAL(18, 2) NOT NULL,
    [quantity] DECIMAL(12, 2) NOT NULL CONSTRAINT [DF_Dynamics365_OpportunityProduct_quantity] DEFAULT (1.00),
    [extendedamount] AS (CAST([quantity] * [priceperunit] AS DECIMAL(18, 2))),
    [manualdiscountamount] DECIMAL(18, 2) NOT NULL CONSTRAINT [DF_Dynamics365_OpportunityProduct_manualdiscountamount] DEFAULT (0.00),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_OpportunityProduct_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_OpportunityProduct_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_OpportunityProduct] PRIMARY KEY CLUSTERED ([opportunityproductid] ASC),
    CONSTRAINT [FK_Dynamics365_OpportunityProduct_opportunityid] FOREIGN KEY ([opportunityid]) REFERENCES [Dynamics365].[Opportunity] ([opportunityid]),
    CONSTRAINT [FK_Dynamics365_OpportunityProduct_productid] FOREIGN KEY ([productid]) REFERENCES [Dynamics365].[Product] ([productid]),
    CONSTRAINT [FK_Dynamics365_OpportunityProduct_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_OpportunityProduct_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
