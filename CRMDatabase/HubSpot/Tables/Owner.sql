CREATE TABLE [HubSpot].[Owner]
(
    [ownerId] BIGINT NOT NULL,
    [email] NVARCHAR(255) NOT NULL,
    [firstName] NVARCHAR(100) NULL,
    [lastName] NVARCHAR(100) NULL,
    [userId] BIGINT NULL,
    [isActive] BIT NOT NULL CONSTRAINT [DF_HubSpot_Owner_isActive] DEFAULT (1),
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Owner_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Owner_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Owner_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Owner] PRIMARY KEY CLUSTERED ([ownerId] ASC),
    CONSTRAINT [UQ_HubSpot_Owner_email] UNIQUE ([email])
);
