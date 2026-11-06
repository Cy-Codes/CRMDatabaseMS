-- ============================================================================
-- Script: 02_Simulate_Heavy_ETL_Load.sql
-- Description: Generates heavy production ETL volumes across Salesforce,
--              HubSpot, and Dynamics 365 schemas.
--
-- Parameters:
--   @ScaleFactor = 10   -> ~30,000 records total (Fast test)
--   @ScaleFactor = 100  -> ~300,000 records total (Standard ETL benchmark)
--   @ScaleFactor = 500  -> ~1,500,000 records total (Heavy stress test)
-- ============================================================================

USE [CRMDatabaseMS];
GO

EXEC [dbo].[sp_SimulateHeavyETLLoad] @ScaleFactor = 100, @CleanExisting = 1;
GO

-- Verify total row counts per table across all 3 CRM schemas
SELECT
    t.TABLE_SCHEMA AS [Schema],
    t.TABLE_NAME AS [Table],
    p.rows AS [RowCount]
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.tables st ON st.name = t.TABLE_NAME AND SCHEMA_NAME(st.schema_id) = t.TABLE_SCHEMA
INNER JOIN sys.partitions p ON p.object_id = st.object_id AND p.index_id IN (0, 1)
WHERE t.TABLE_SCHEMA IN ('Salesforce', 'HubSpot', 'Dynamics365')
ORDER BY t.TABLE_SCHEMA, [RowCount] DESC, t.TABLE_NAME;
GO

-- Total row count summary across the entire database
SELECT
    t.TABLE_SCHEMA AS [Schema],
    SUM(p.rows) AS [TotalRows]
FROM INFORMATION_SCHEMA.TABLES t
INNER JOIN sys.tables st ON st.name = t.TABLE_NAME AND SCHEMA_NAME(st.schema_id) = t.TABLE_SCHEMA
INNER JOIN sys.partitions p ON p.object_id = st.object_id AND p.index_id IN (0, 1)
WHERE t.TABLE_SCHEMA IN ('Salesforce', 'HubSpot', 'Dynamics365')
GROUP BY t.TABLE_SCHEMA
ORDER BY t.TABLE_SCHEMA;
GO
