-- ============================================================================
-- Script: 01_Seed_Standard_50Records.sql
-- Description: Seeds 50 realistic records with sane defaults into every table
--              across Salesforce, HubSpot, and Dynamics 365 (1,850 records total).
-- ============================================================================

USE [CRMDatabaseMS];
GO

EXEC [dbo].[sp_SeedStandardData] @CleanExisting = 1;
GO

-- Verify row counts across all 3 CRM schemas
SELECT
    t.TABLE_SCHEMA AS [Schema],
    t.TABLE_NAME AS [Table],
    p.rows AS [RowCount]
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.tables st ON st.name = t.TABLE_NAME AND SCHEMA_NAME(st.schema_id) = t.TABLE_SCHEMA
INNER JOIN sys.partitions p ON p.object_id = st.object_id AND p.index_id IN (0, 1)
WHERE t.TABLE_SCHEMA IN ('Salesforce', 'HubSpot', 'Dynamics365')
ORDER BY t.TABLE_SCHEMA, t.TABLE_NAME;
GO
