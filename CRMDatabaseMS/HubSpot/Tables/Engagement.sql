CREATE TABLE [HubSpot].[Engagement]
(
    [engagementId] BIGINT NOT NULL,
    [engagementType] NVARCHAR(50) NOT NULL, -- NOTE, EMAIL, TASK, CALL, MEETING
    [ownerId] BIGINT NULL,
    [timestamp] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Engagement_timestamp] DEFAULT (SYSUTCDATETIME()),
    [body] NVARCHAR(MAX) NULL,
    [status] NVARCHAR(50) NULL,
    [activityDurationMilliseconds] BIGINT NULL,
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Engagement_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Engagement_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Engagement_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Engagement] PRIMARY KEY CLUSTERED ([engagementId] ASC),
    CONSTRAINT [FK_HubSpot_Engagement_ownerId] FOREIGN KEY ([ownerId]) REFERENCES [HubSpot].[Owner] ([ownerId])
);
