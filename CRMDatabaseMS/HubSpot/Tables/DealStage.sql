CREATE TABLE [HubSpot].[DealStage]
(
    [stageId] NVARCHAR(50) NOT NULL,
    [pipelineId] NVARCHAR(50) NOT NULL,
    [label] NVARCHAR(100) NOT NULL,
    [displayOrder] INT NOT NULL CONSTRAINT [DF_HubSpot_DealStage_displayOrder] DEFAULT (0),
    [probability] DECIMAL(5, 2) NOT NULL CONSTRAINT [DF_HubSpot_DealStage_probability] DEFAULT (0.00),
    [closedWon] BIT NOT NULL CONSTRAINT [DF_HubSpot_DealStage_closedWon] DEFAULT (0),
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_DealStage_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_DealStage_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_DealStage_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_DealStage] PRIMARY KEY CLUSTERED ([stageId] ASC),
    CONSTRAINT [FK_HubSpot_DealStage_pipelineId] FOREIGN KEY ([pipelineId]) REFERENCES [HubSpot].[Pipeline] ([pipelineId])
);
