CREATE TABLE [Dynamics365].[Incident]
(
    [incidentid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_Incident_incidentid] DEFAULT (NEWID()),
    [ticketnumber] NVARCHAR(100) NOT NULL,
    [title] NVARCHAR(200) NOT NULL,
    [customerid_account] UNIQUEIDENTIFIER NULL,
    [customerid_contact] UNIQUEIDENTIFIER NULL,
    [prioritycode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Incident_prioritycode] DEFAULT (2), -- 1=High, 2=Normal, 3=Low
    [severitycode] INT NULL,
    [casetypecode] INT NULL,
    [casesubject] NVARCHAR(500) NULL,
    [description] NVARCHAR(MAX) NULL,
    [ownerid] UNIQUEIDENTIFIER NOT NULL,
    [owningbusinessunit] UNIQUEIDENTIFIER NOT NULL,
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Incident_statecode] DEFAULT (0), -- 0=Active, 1=Resolved, 2=Canceled
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_Incident_statuscode] DEFAULT (1), -- 1=In Progress, 2=On Hold, 3=Waiting for Details, etc.
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Incident_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_Incident_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_Incident] PRIMARY KEY CLUSTERED ([incidentid] ASC),
    CONSTRAINT [FK_Dynamics365_Incident_customerid_account] FOREIGN KEY ([customerid_account]) REFERENCES [Dynamics365].[Account] ([accountid]),
    CONSTRAINT [FK_Dynamics365_Incident_customerid_contact] FOREIGN KEY ([customerid_contact]) REFERENCES [Dynamics365].[Contact] ([contactid]),
    CONSTRAINT [FK_Dynamics365_Incident_ownerid] FOREIGN KEY ([ownerid]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Incident_owningbusinessunit] FOREIGN KEY ([owningbusinessunit]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid]),
    CONSTRAINT [FK_Dynamics365_Incident_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_Incident_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
