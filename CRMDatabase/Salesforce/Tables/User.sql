CREATE TABLE [Salesforce].[User]
(
    [Id] NVARCHAR(18) NOT NULL,
    [Username] NVARCHAR(80) NOT NULL,
    [LastName] NVARCHAR(80) NOT NULL,
    [FirstName] NVARCHAR(40) NULL,
    [Name] AS (ISNULL([FirstName] + N' ', N'') + [LastName]),
    [Email] NVARCHAR(128) NOT NULL,
    [IsActive] BIT NOT NULL CONSTRAINT [DF_Salesforce_User_IsActive] DEFAULT (1),
    [UserRoleId] NVARCHAR(18) NULL,
    [ProfileId] NVARCHAR(18) NULL,
    [Title] NVARCHAR(80) NULL,
    [Department] NVARCHAR(80) NULL,
    [Phone] NVARCHAR(40) NULL,
    [CreatedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_User_CreatedDate] DEFAULT (SYSUTCDATETIME()),
    [LastModifiedDate] DATETIME2 NOT NULL CONSTRAINT [DF_Salesforce_User_LastModifiedDate] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Salesforce_User] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Salesforce_User_Username] UNIQUE ([Username])
);
