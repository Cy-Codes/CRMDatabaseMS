CREATE TABLE [Salesforce].[PricebookEntry]
(
    [Id] NVARCHAR(18) NOT NULL,
    [Pricebook2Id] NVARCHAR(18) NOT NULL,
    [Product2Id] NVARCHAR(18) NOT NULL,
    [UnitPrice] DECIMAL(18, 2) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Salesforce_PricebookEntry_IsActive] DEFAULT (1),
    [UseStandardPrice] BIT NOT NULL CONSTRAINT [DF_Salesforce_PricebookEntry_UseStandardPrice] DEFAULT (0),
    [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Salesforce_PricebookEntry_IsDeleted] DEFAULT (0),
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_PricebookEntry_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [CreatedById] NVARCHAR(18) NOT NULL,
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_PricebookEntry_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedById] NVARCHAR(18) NOT NULL,
    CONSTRAINT [PK_Salesforce_PricebookEntry] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_PricebookEntry_Pricebook2Id] FOREIGN KEY ([Pricebook2Id]) REFERENCES [Salesforce].[Pricebook2] ([Id]),
    CONSTRAINT [FK_Salesforce_PricebookEntry_Product2Id] FOREIGN KEY ([Product2Id]) REFERENCES [Salesforce].[Product2] ([Id]),
    CONSTRAINT [FK_Salesforce_PricebookEntry_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [FK_Salesforce_PricebookEntry_LastModifiedById] FOREIGN KEY ([LastModifiedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [UQ_Salesforce_PricebookEntry_Pricebook_Product] UNIQUE ([Pricebook2Id], [Product2Id])
);
