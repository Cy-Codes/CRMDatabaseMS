CREATE TABLE [Salesforce].[AccountContactRelation]
(
    [Id] NVARCHAR(18) NOT NULL,
    [AccountId] NVARCHAR(18) NOT NULL,
    [ContactId] NVARCHAR(18) NOT NULL,
    [Roles] NVARCHAR(255) NULL,
    [IsDirect] BIT NOT NULL CONSTRAINT [DF_Salesforce_AccountContactRelation_IsDirect] DEFAULT (0),
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Salesforce_AccountContactRelation_IsActive] DEFAULT (1),
    [StartDate] DATE NULL,
    [EndDate] DATE NULL,
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_AccountContactRelation_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_AccountContactRelation_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Salesforce_AccountContactRelation] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_AccountContactRelation_AccountId] FOREIGN KEY ([AccountId]) REFERENCES [Salesforce].[Account] ([Id]),
    CONSTRAINT [FK_Salesforce_AccountContactRelation_ContactId] FOREIGN KEY ([ContactId]) REFERENCES [Salesforce].[Contact] ([Id]),
    CONSTRAINT [UQ_Salesforce_AccountContactRelation_Account_Contact] UNIQUE ([AccountId], [ContactId])
);
