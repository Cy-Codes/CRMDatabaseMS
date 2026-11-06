-- ============================================================================
-- Test Suite 2: Data Seeding, Cascade Cleanup, & Referential Integrity Tests
-- ============================================================================
SET NOCOUNT ON;

DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

PRINT '========================================================================';
PRINT 'Test Suite 2: Verifying Cleanup, Standard Seeding (1,850 rows), & Integrity';
PRINT '========================================================================';

-- 2.1 Test sp_CleanupAllCRMData
EXEC [dbo].[sp_CleanupAllCRMData];

DECLARE @NonZeroTableCount INT;
SELECT @NonZeroTableCount = COUNT(*)
FROM sys.dm_db_partition_stats ps
INNER JOIN sys.tables t ON ps.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('Salesforce', 'HubSpot', 'Dynamics365')
  AND ps.index_id IN (0, 1)
  AND ps.row_count > 0;

IF @NonZeroTableCount = 0
BEGIN
    PRINT '  [PASS] sp_CleanupAllCRMData successfully truncated all 37 tables (0 rows remaining)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] sp_CleanupAllCRMData left data in ' + CAST(@NonZeroTableCount AS VARCHAR(10)) + ' tables!';
    SET @FailCount = @FailCount + 1;
END

-- 2.2 Test sp_SeedStandardData
EXEC [dbo].[sp_SeedStandardData] @CleanExisting = 1;

-- 2.3 Verify Total Row Count = 1,850 (37 tables * 50 rows)
DECLARE @TotalRowCount BIGINT;
SELECT @TotalRowCount = SUM(ps.row_count)
FROM sys.dm_db_partition_stats ps
INNER JOIN sys.tables t ON ps.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name IN ('Salesforce', 'HubSpot', 'Dynamics365')
  AND ps.index_id IN (0, 1);

IF @TotalRowCount = 1850
BEGIN
    PRINT '  [PASS] Standard Seed total rows across all 37 tables is exactly 1,850 (50 rows/table)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Standard Seed expected 1,850 total rows, found ' + CAST(@TotalRowCount AS VARCHAR(20));
    SET @FailCount = @FailCount + 1;
END

-- 2.4 Verify Every Table Has Exactly 50 Records
DECLARE @Non50TableCount INT;
SELECT @Non50TableCount = COUNT(*)
FROM (
    SELECT s.name AS SchemaName, t.name AS TableName, SUM(ps.row_count) AS RowCnt
    FROM sys.dm_db_partition_stats ps
    INNER JOIN sys.tables t ON ps.object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name IN ('Salesforce', 'HubSpot', 'Dynamics365')
      AND ps.index_id IN (0, 1)
    GROUP BY s.name, t.name
    HAVING SUM(ps.row_count) <> 50
) non50;

IF @Non50TableCount = 0
BEGIN
    PRINT '  [PASS] Every single table in Salesforce, HubSpot, and Dynamics365 contains exactly 50 rows';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Found ' + CAST(@Non50TableCount AS VARCHAR(10)) + ' tables with row count != 50!';
    SET @FailCount = @FailCount + 1;
END

-- 2.5 Verify Salesforce Relational Integrity (No orphaned contacts or opportunities)
DECLARE @SfOrphanContacts INT, @SfOrphanOpps INT;
SELECT @SfOrphanContacts = COUNT(*) FROM [Salesforce].[Contact] c
LEFT JOIN [Salesforce].[Account] a ON c.[AccountId] = a.[Id]
WHERE a.[Id] IS NULL;

SELECT @SfOrphanOpps = COUNT(*) FROM [Salesforce].[Opportunity] o
LEFT JOIN [Salesforce].[Account] a ON o.[AccountId] = a.[Id]
WHERE a.[Id] IS NULL;

IF @SfOrphanContacts = 0 AND @SfOrphanOpps = 0
BEGIN
    PRINT '  [PASS] Salesforce referential integrity intact (0 orphaned Contacts/Opportunities)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Salesforce has orphaned records (Contacts: ' + CAST(@SfOrphanContacts AS VARCHAR(10)) + ', Opps: ' + CAST(@SfOrphanOpps AS VARCHAR(10)) + ')';
    SET @FailCount = @FailCount + 1;
END

-- 2.6 Verify HubSpot Associations & Deals
DECLARE @HsOrphanLineItems INT;
SELECT @HsOrphanLineItems = COUNT(*) FROM [HubSpot].[LineItem] li
LEFT JOIN [HubSpot].[Deal] d ON li.[dealId] = d.[dealId]
WHERE d.[dealId] IS NULL;

IF @HsOrphanLineItems = 0
BEGIN
    PRINT '  [PASS] HubSpot referential integrity intact (0 orphaned LineItems)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] HubSpot has orphaned LineItems: ' + CAST(@HsOrphanLineItems AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

-- 2.7 Verify Dynamics 365 Hierarchies
DECLARE @D365OrphanContacts INT;
SELECT @D365OrphanContacts = COUNT(*) FROM [Dynamics365].[Contact] c
LEFT JOIN [Dynamics365].[Account] a ON c.[parentcustomerid] = a.[accountid]
WHERE a.[accountid] IS NULL;

IF @D365OrphanContacts = 0
BEGIN
    PRINT '  [PASS] Dynamics 365 parentcustomerid references intact (0 orphaned Contacts)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Dynamics 365 has orphaned Contacts: ' + CAST(@D365OrphanContacts AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

PRINT '------------------------------------------------------------------------';
PRINT 'Test Suite 2 Summary: ' + CAST(@PassCount AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount AS VARCHAR(10)) + ' Failed.';
PRINT '------------------------------------------------------------------------';

IF @FailCount > 0
    THROW 50002, 'Test Suite 2 Failed', 1;
