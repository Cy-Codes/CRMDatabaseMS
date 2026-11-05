CREATE TABLE [Salesforce].[CampaignMember]
(
    [Id] NVARCHAR(18) NOT NULL,
    [IsDeleted] BIT NOT NULL CONSTRAINT [DF_Salesforce_CampaignMember_IsDeleted] DEFAULT (0),
    [CampaignId] NVARCHAR(18) NOT NULL,
    [LeadId] NVARCHAR(18) NULL,
    [ContactId] NVARCHAR(18) NULL,
    [Status] NVARCHAR(40) NULL,
    [HasResponded] BIT NOT NULL CONSTRAINT [DF_Salesforce_CampaignMember_HasResponded] DEFAULT (0),
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_CampaignMember_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [CreatedById] NVARCHAR(18) NOT NULL,
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_CampaignMember_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedById] NVARCHAR(18) NOT NULL,
    CONSTRAINT [PK_Salesforce_CampaignMember] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Salesforce_CampaignMember_CampaignId] FOREIGN KEY ([CampaignId]) REFERENCES [Salesforce].[Campaign] ([Id]),
    CONSTRAINT [FK_Salesforce_CampaignMember_LeadId] FOREIGN KEY ([LeadId]) REFERENCES [Salesforce].[Lead] ([Id]),
    CONSTRAINT [FK_Salesforce_CampaignMember_ContactId] FOREIGN KEY ([ContactId]) REFERENCES [Salesforce].[Contact] ([Id]),
    CONSTRAINT [FK_Salesforce_CampaignMember_CreatedById] FOREIGN KEY ([CreatedById]) REFERENCES [Salesforce].[User] ([Id]),
    CONSTRAINT [FK_Salesforce_CampaignMember_LastModifiedById] FOREIGN KEY ([LastModifiedById]) REFERENCES [Salesforce].[User] ([Id])
);
