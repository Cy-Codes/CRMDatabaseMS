CREATE TABLE [HubSpot].[Pipeline]
(
    [pipelineId] NVARCHAR(50) NOT NULL,
    [label] NVARCHAR(100) NOT NULL,
    [displayOrder] INT NOT NULL CONSTRAINT [DF_HubSpot_Pipeline_displayOrder] DEFAULT (0),
    [objectType] NVARCHAR(50) NOT NULL,
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Pipeline_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Pipeline_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Pipeline_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Pipeline] PRIMARY KEY CLUSTERED ([pipelineId] ASC)
);
