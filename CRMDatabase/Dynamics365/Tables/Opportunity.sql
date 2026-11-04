CREATE TABLE [Dynamics365].[Opportunity]
(
    [opportunityid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_Opportunity_opportunityid] DEFAULT (NEWID()),
    [name] NVARCHAR(300) NOT NULL,
    [parentaccountid] UNIQUEIDENTIFIER NULL,
    [parentcontactid] UNIQUEIDENTIFIER NULL,
    [pricelevelid] UNIQUEIDENTIFIER NULL,
    [originatingleadid] UNIQUEIDENTIFIER NULL,
    [estimatedvalue] DECIMAL(18, 2) NULL,
    [actualvalue] DECIMAL(18, 2) NULL,
    [estimatedclosedate] DATE NULL,
    [actualclosedate] DATE NULL,
    [closeprobability] INT NULL,
    [stepname] NVARCHAR(200) NULL,
    [salesstage] INT NULL,
    [description] NVARCHAR(MAX) NULL,
    [ownerid] UNIQUEIDENTIFIER NOT NULL,
    [owningbusinessunit] UNIQUEIDENTIFIER NOT NULL,
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Opportunity_statecode] DEFAULT (0), -- 0=Open, 1=Won, 2=Lost
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Opportunity_statuscode] DEFAULT (1), -- 1=In Progress, 2=On Hold, 3=Won, 4=Canceled, 5=Out-Sold
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Opportunity_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Opportunity_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_Opportunity] PRIMARY KEY CLUSTERED ([opportunityid] ASC),
    CONSTRAINT [FK_Dynamics365_Opportunity_parentaccountid] FOREIGN KEY ([parentaccountid]) REFERENCES [Dynamics365].[Account] ([accountid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_parentcontactid] FOREIGN KEY ([parentcontactid]) REFERENCES [Dynamics365].[Contact] ([contactid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_pricelevelid] FOREIGN KEY ([pricelevelid]) REFERENCES [Dynamics365].[PriceLevel] ([pricelevelid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_originatingleadid] FOREIGN KEY ([originatingleadid]) REFERENCES [Dynamics365].[Lead] ([leadid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_ownerid] FOREIGN KEY ([ownerid]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_owningbusinessunit] FOREIGN KEY ([owningbusinessunit]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Opportunity_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
