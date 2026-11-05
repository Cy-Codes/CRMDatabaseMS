CREATE PROCEDURE [dbo].[sp_CleanupAllCRMData]
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Starting cleanup of all CRM data across Salesforce, HubSpot, and Dynamics365 schemas...';

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Clean Salesforce in reverse foreign-key dependency order
        DELETE FROM [Salesforce].[OpportunityLineItem];
        DELETE FROM [Salesforce].[PricebookEntry];
        DELETE FROM [Salesforce].[Pricebook2];
        DELETE FROM [Salesforce].[Product2];
        DELETE FROM [Salesforce].[Opportunity];
        DELETE FROM [Salesforce].[CampaignMember];
        DELETE FROM [Salesforce].[Campaign];
        DELETE FROM [Salesforce].[Case];
        DELETE FROM [Salesforce].[Task];
        DELETE FROM [Salesforce].[Event];
        DELETE FROM [Salesforce].[AccountContactRelation];
        DELETE FROM [Salesforce].[Contact];
        DELETE FROM [Salesforce].[Lead];
        DELETE FROM [Salesforce].[Account];
        DELETE FROM [Salesforce].[User];

        -- 2. Clean HubSpot in reverse foreign-key dependency order
        DELETE FROM [HubSpot].[ObjectAssociation];
        DELETE FROM [HubSpot].[LineItem];
        DELETE FROM [HubSpot].[Product];
        DELETE FROM [HubSpot].[Deal];
        DELETE FROM [HubSpot].[DealStage];
        DELETE FROM [HubSpot].[Ticket];
        DELETE FROM [HubSpot].[Pipeline];
        DELETE FROM [HubSpot].[Engagement];
        DELETE FROM [HubSpot].[Contact];
        DELETE FROM [HubSpot].[Company];
        DELETE FROM [HubSpot].[Owner];

        -- 3. Clean Dynamics 365 in reverse foreign-key dependency order
        DELETE FROM [Dynamics365].[OpportunityProduct];
        DELETE FROM [Dynamics365].[ActivityPointer];
        DELETE FROM [Dynamics365].[Incident];
        DELETE FROM [Dynamics365].[Opportunity];
        DELETE FROM [Dynamics365].[Product];
        DELETE FROM [Dynamics365].[PriceLevel];
        DELETE FROM [Dynamics365].[Lead];
        DELETE FROM [Dynamics365].[Contact];
        DELETE FROM [Dynamics365].[Account];
        DELETE FROM [Dynamics365].[SystemUser];
        DELETE FROM [Dynamics365].[BusinessUnit];

        COMMIT TRANSACTION;
        PRINT 'All CRM table data successfully cleaned.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
