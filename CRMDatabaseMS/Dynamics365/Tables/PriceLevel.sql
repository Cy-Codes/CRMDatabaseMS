CREATE TABLE [Dynamics365].[PriceLevel]
(
    [pricelevelid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_PriceLevel_pricelevelid] DEFAULT (NEWID()),
    [name] NVARCHAR(100) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [begindate] DATE NULL,
    [enddate] DATE NULL,
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_PriceLevel_statecode] DEFAULT (0),
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_PriceLevel_statuscode] DEFAULT (1),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_PriceLevel_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_PriceLevel_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_PriceLevel] PRIMARY KEY CLUSTERED ([pricelevelid] ASC),
    CONSTRAINT [FK_Dynamics365_PriceLevel_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_PriceLevel_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
