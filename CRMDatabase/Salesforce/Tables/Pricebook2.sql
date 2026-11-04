CREATE TABLE [Salesforce].[Pricebook2]
(
    [Id] NVARCHAR(18) NOT NULL,
    [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Salesforce_Pricebook2_IsDeleted] DEFAULT (0),
    [Name] NVARCHAR(255) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Salesforce_Pricebook2_IsActive] DEFAULT (1),
    [IsStandard] BIT NOT NULL CONSTRAINT [DF_Salesforce_Pricebook2_IsStandard] DEFAULT (0),
    [Description] NVARCHAR(255) NULL,
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_Pricebook2_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [CreatedById] NVARCHAR(18) NOT NULL,
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_Pricebook2_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedById] NVARCHAR(18) NOT NULL,
    CONSTRAINT [PK_Salesforce_Pricebook2] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_Pricebook2_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [FK_Salesforce_Pricebook2_LastModifiedById] FOREIGN KEY ([LastModifiedById]) REFERENCES [Salesforce].[User] ([Id])
);
