CREATE TABLE [Salesforce].[Product2]
(
    [Id] NVARCHAR(18) NOT NULL,
    [Name] NVARCHAR(255) NOT NULL,
    [ProductCode] NVARCHAR(255) NULL,
    [Description] NVARCHAR(MAX) NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Salesforce_Product2_IsActive] DEFAULT (1),
    [Family] NVARCHAR(40) NULL,
    [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Salesforce_Product2_IsDeleted] DEFAULT (0),
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_Product2_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [CreatedById] NVARCHAR(18) NOT NULL,
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_Product2_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedById] NVARCHAR(18) NOT NULL,
    CONSTRAINT [PK_Salesforce_Product2] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_Product2_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [FK_Salesforce_Product2_LastModifiedById] FOREIGN KEY ([LastModifiedById]) REFERENCES [Salesforce].[User] ([Id])
);
