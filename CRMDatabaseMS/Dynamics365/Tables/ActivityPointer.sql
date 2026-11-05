CREATE TABLE [Dynamics365].[ActivityPointer]
(
    [activityid] UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_Dynamics365_ActivityPointer_activityid] DEFAULT (NEWID()),
    [activitytypecode] NVARCHAR(64) NOT NULL, -- task, email, phonecall, appointment
    [subject] NVARCHAR(200) NOT NULL,
    [description] NVARCHAR(MAX) NULL,
    [regardingobjectid_account] UNIQUEIDENTIFIER NULL,
    [regardingobjectid_contact] UNIQUEIDENTIFIER NULL,
    [regardingobjectid_opportunity] UNIQUEIDENTIFIER NULL,
    [regardingobjectid_incident] UNIQUEIDENTIFIER NULL,
    [ownerid] UNIQUEIDENTIFIER NOT NULL,
    [owningbusinessunit] UNIQUEIDENTIFIER NOT NULL,
    [scheduledstart] DATETIME2 NULL,
    [scheduledend] DATETIME2 NULL,
    [actualstart] DATETIME2 NULL,
    [actualend] DATETIME2 NULL,
    [actualdurationminutes] INT NULL,
    [statecode] INT NOT NULL CONSTRAINT [DF_Dynamics365_ActivityPointer_statecode] DEFAULT (0), -- 0=Open, 1=Completed, 2=Canceled
    [statuscode] INT NOT NULL CONSTRAINT [DF_Dynamics365_ActivityPointer_statuscode] DEFAULT (1),
    [createdon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_ActivityPointer_createdon] DEFAULT (SYSUTCDATETIME()),
    [createdby] UNIQUEIDENTIFIER NOT NULL,
    [modifiedon] DATETIME2 NOT NULL CONSTRAINT [DF_Dynamics365_ActivityPointer_modifiedon] DEFAULT (SYSUTCDATETIME()),
    [modifiedby] UNIQUEIDENTIFIER NOT NULL,
    CONSTRAINT [PK_Dynamics365_ActivityPointer] PRIMARY KEY CLUSTERED ([activityid] ASC),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_regardingobjectid_account] FOREIGN KEY ([regardingobjectid_account]) REFERENCES [Dynamics365].[Account] ([accountid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_regardingobjectid_contact] FOREIGN KEY ([regardingobjectid_contact]) REFERENCES [Dynamics365].[Contact] ([contactid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_regardingobjectid_opportunity] FOREIGN KEY ([regardingobjectid_opportunity]) REFERENCES [Dynamics365].[Opportunity] ([opportunityid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_regardingobjectid_incident] FOREIGN KEY ([regardingobjectid_incident]) REFERENCES [Dynamics365].[Incident] ([incidentid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_ownerid] FOREIGN KEY ([ownerid]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_owningbusinessunit] FOREIGN KEY ([owningbusinessunit]) REFERENCES [Dynamics365].[BusinessUnit] ([businessunitid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_createdby] FOREIGN KEY ([createdby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid]),
    CONSTRAINT [FK_Dynamics365_ActivityPointer_modifiedby] FOREIGN KEY ([modifiedby]) REFERENCES [Dynamics365].[SystemUser] ([systemuserid])
);
