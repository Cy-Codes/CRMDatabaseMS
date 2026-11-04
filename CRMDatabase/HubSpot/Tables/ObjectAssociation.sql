CREATE TABLE [HubSpot].[ObjectAssociation]
(
    [associationId] BIGINT IDENTITY(1, 1) NOT NULL,
    [fromObjectType] NVARCHAR(50) NOT NULL, -- contact, company, deal, ticket, engagement
    [fromObjectId] BIGINT NOT NULL,
    [toObjectType] NVARCHAR(50) NOT NULL,
    [toObjectId] BIGINT NOT NULL,
    [associationTypeId] INT NOT NULL CONSTRAINT [DF_HubSpot_ObjectAssociation_associationTypeId] DEFAULT (1),
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_ObjectAssociation_createdAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_HubSpot_ObjectAssociation] PRIMARY KEY CLUSTERED ([associationId] ASC),
    CONSTRAINT [UQ_HubSpot_ObjectAssociation] UNIQUE ([fromObjectType], [fromObjectId], [toObjectType], [toObjectId], [associationTypeId])
);
