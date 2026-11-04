CREATE TABLE [HubSpot].[Company]
(
    [companyId] BIGINT NOT NULL,
    [name] NVARCHAR(255) NOT NULL,
    [domain] NVARCHAR(255) NULL,
    [industry] NVARCHAR(100) NULL,
    [phone] NVARCHAR(50) NULL,
    [address] NVARCHAR(255) NULL,
    [city] NVARCHAR(100) NULL,
    [state] NVARCHAR(100) NULL,
    [zip] NVARCHAR(30) NULL,
    [country] NVARCHAR(100) NULL,
    [annualRevenue] DECIMAL(18, 2) NULL,
    [numberOfEmployees] INT NULL,
    [description] NVARCHAR(MAX) NULL,
    [ownerId] BIGINT NULL,
    [lifecyclestage] NVARCHAR(50) NOT NULL CONSTRAINT [DF_HubSpot_Company_lifecyclestage] DEFAULT (N'lead'),
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Company_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Company_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Company_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Company] PRIMARY KEY CLUSTERED ([companyId] ASC),
    CONSTRAINT [FK_HubSpot_Company_ownerId] FOREIGN KEY ([ownerId]) REFERENCES [HubSpot].[Owner] ([ownerId])
);
