CREATE TABLE [HubSpot].[Deal]
(
    [dealId] BIGINT NOT NULL,
    [dealName] NVARCHAR(255) NOT NULL,
    [pipelineId] NVARCHAR(50) NOT NULL,
    [dealStageId] NVARCHAR(50) NOT NULL,
    [amount] DECIMAL(18, 2) NULL,
    [closedate] DATETIME2 NULL,
    [dealType] NVARCHAR(50) NULL,
    [ownerId] BIGINT NULL,
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Deal_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Deal_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Deal_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Deal] PRIMARY KEY CLUSTERED ([dealId] ASC),
    CONSTRAINT [FK_HubSpot_Deal_pipelineId] FOREIGN KEY ([pipelineId]) REFERENCES [HubSpot].[Pipeline] ([pipelineId]),
    CONSTRAINT [FK_HubSpot_Deal_dealStageId] FOREIGN KEY ([dealStageId]) REFERENCES [HubSpot].[DealStage] ([stageId]),
    CONSTRAINT [FK_HubSpot_Deal_ownerId] FOREIGN KEY ([ownerId]) REFERENCES [HubSpot].[Owner] ([ownerId])
);
