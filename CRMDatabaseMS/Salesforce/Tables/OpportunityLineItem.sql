CREATE TABLE [Salesforce].[OpportunityLineItem]
(
    [Id] NVARCHAR(18) NOT NULL,
    [OpportunityId] NVARCHAR(18) NOT NULL,
    [PricebookEntryId] NVARCHAR(18) NOT NULL,
    [Quantity] DECIMAL(12, 2) NOT NULL,
    [UnitPrice] DECIMAL(18, 2) NOT NULL,
    [TotalPrice] AS (CAST([Quantity] * [UnitPrice] AS DECIMAL(18, 2))),
    [ListPrice] DECIMAL(18, 2) NULL,
    [Description] NVARCHAR(255) NULL,
    [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Salesforce_OpportunityLineItem_IsDeleted] DEFAULT (0),
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_OpportunityLineItem_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [CreatedById] NVARCHAR(18) NOT NULL,
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_OpportunityLineItem_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedById] NVARCHAR(18) NOT NULL,
    CONSTRAINT [PK_Salesforce_OpportunityLineItem] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_OpportunityLineItem_OpportunityId] FOREIGN KEY ([OpportunityId]) REFERENCES [Salesforce].[Opportunity] ([Id]),
    CONSTRAINT [FK_Salesforce_OpportunityLineItem_PricebookEntryId] FOREIGN KEY ([PricebookEntryId]) REFERENCES [Salesforce].[PricebookEntry] ([Id]),
    CONSTRAINT [FK_Salesforce_OpportunityLineItem_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [FK_Salesforce_OpportunityLineItem_LastModifiedById] FOREIGN KEY ([LastModifiedById]) REFERENCES [Salesforce].[User] ([Id])
);
