CREATE TABLE [Dynamics365].[BusinessUnit]
(
    [businessunitid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_BusinessUnit_businessunitid] DEFAULT (NEWID()),
    [name] NVARCHAR(160) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [parentbusinessunitid] UNIQUEIDENTIFIER NULL,
    [isdisabled] BIT NOT NULL CONSTRAINT [DF_Dynamics365_BusinessUnit_isdisabled] DEFAULT (0),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_BusinessUnit_createdon] DEFAULT (SYSUTCDATETIME()),
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_BusinessUnit_modifiedon] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_Dynamics365_BusinessUnit] PRIMARY KEY CLUSTERED ([businessunitid] ASC),
    CONSTRAINT [FK_Dynamics365_BusinessUnit_parentbusinessunitid] FOREIGN KEY ([parentbusinessunitid]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid])
);
