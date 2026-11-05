-- ============================================================================
-- Script: 00_Cleanup_All_Data.sql
-- Description: Cleans all records across Salesforce, HubSpot, and Dynamics 365
--              schemas in reverse foreign key dependency order.
-- ============================================================================

USE [CRMDatabaseMS];
GO

EXEC [dbo].[sp_CleanupAllCRMData];
GO
