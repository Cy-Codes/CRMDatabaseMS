CREATE TABLE [Dynamics365].[Account]
(
    [accountid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_Account_accountid] DEFAULT (NEWID()),
    [name] NVARCHAR(160) NOT NULL,
    [accountnumber] NVARCHAR(20) NULL,
    [parentaccountid] UNIQUEIDENTIFIER NULL,
    [telephone1] NVARCHAR(50) NULL,
    [emailaddress1] NVARCHAR(100) NULL,
    [websiteurl] NVARCHAR(200) NULL,
    [address1_line1] NVARCHAR(250) NULL,
    [address1_city] NVARCHAR(80) NULL,
    [address1_stateorprovince] NVARCHAR(50) NULL,
    [address1_postalcode] NVARCHAR(20) NULL,
    [address1_country] NVARCHAR(80) NULL,
    [revenue] DECIMAL(18, 2) NULL,
    [numberofemployees] INT NULL,
    [industrycode] INT NULL,
    [description] NVARCHAR(MAX) NULL,
    [ownerid] UNIQUEIDENTIFIER NOT NULL,
    [owningbusinessunit] UNIQUEIDENTIFIER NOT NULL,
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Account_statecode] DEFAULT (0), -- 0=Active, 1=Inactive
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Account_statuscode] DEFAULT (1), -- 1=Active, 2=Inactive
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Account_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Account_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_Account] PRIMARY KEY CLUSTERED ([accountid] ASC),
    CONSTRAINT [FK_Dynamics365_Account_parentaccountid] FOREIGN KEY ([parentaccountid]) REFERENCES [Dynamics365].[Account] ([accountid]),
    CONSTRAINT [FK_Dynamics365_Account_ownerid] FOREIGN KEY ([ownerid]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Account_owningbusinessunit] FOREIGN KEY ([owningbusinessunit]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid]),
    CONSTRAINT [FK_Dynamics365_Account_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Account_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
