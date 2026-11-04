CREATE TABLE [HubSpot].[Ticket]
(
    [ticketId] BIGINT NOT NULL,
    [subject] NVARCHAR(255) NOT NULL,
    [content] NVARCHAR(MAX) NULL,
    [pipelineId] NVARCHAR(50) NOT NULL,
    [ticketStatusStageId] NVARCHAR(50) NOT NULL,
    [priority] NVARCHAR(20) NOT NULL CONSTRAINT [DF_HubSpot_Ticket_priority] DEFAULT (N'MEDIUM'),
    [ownerId] BIGINT NULL,
    [createdAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Ticket_createdAt] DEFAULT (SYSUTCDATETIME()),
    [updatedAt] DATETIME2 NOT NULL CONSTRAINT [DF_HubSpot_Ticket_updatedAt] DEFAULT (SYSUTCDATETIME()),
    [archived] BIT NOT NULL CONSTRAINT [DF_HubSpot_Ticket_archived] DEFAULT (0),
    CONSTRAINT [PK_HubSpot_Ticket] PRIMARY KEY CLUSTERED ([ticketId] ASC),
    CONSTRAINT [FK_HubSpot_Ticket_pipelineId] FOREIGN KEY ([pipelineId]) REFERENCES [HubSpot].[Pipeline] ([pipelineId]),
    CONSTRAINT [FK_HubSpot_Ticket_ownerId] FOREIGN KEY ([ownerId]) REFERENCES [HubSpot].[Owner] ([ownerId])
);
