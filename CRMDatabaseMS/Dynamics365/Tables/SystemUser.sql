CREATE TABLE [Dynamics365].[SystemUser]
(
    [systemuserid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_SystemUser_systemuserid] DEFAULT (NEWID()),
    [businessunitid] UNIQUEIDENTIFIER NOT NULL,
    [domainname] NVARCHAR(1024) NOT NULL,
    [fullname] NVARCHAR(200) NOT NULL,
    [firstname] NVARCHAR(50) NULL,
    [lastname] NVARCHAR(50) NOT NULL,
    [internalemailaddress] NVARCHAR(100) NULL,
    [jobtitle] NVARCHAR(100) NULL,
    [isdisabled] BIT NOT NULL CONSTRAINT [DF_Dynamics365_SystemUser_isdisabled] DEFAULT (0),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_SystemUser_createdon] DEFAULT (SYSUTCDATETIME()),
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_SystemUser_modifiedon] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Dynamics365_SystemUser] PRIMARY KEY CLUSTERED ([systemuserid] ASC),
    CONSTRAINT [FK_Dynamics365_SystemUser_businessunitid] FOREIGN KEY ([businessunitid]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid])
);
