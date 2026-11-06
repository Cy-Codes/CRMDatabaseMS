-- ============================================================================
-- Test Suite 1: Schema & Object Structure Verification
-- ============================================================================
SET NOCOUNT ON;

DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;

PRINT '========================================================================';
PRINT 'Test Suite 1: Verifying Schema Namespaces, Tables, and Key Constraints';
PRINT '========================================================================';

-- 1.1 Verify Schemas Exist
IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Salesforce')
    AND EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'HubSpot')
    AND EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Dynamics365')
BEGIN
    PRINT '  [PASS] All 3 CRM Schemas exist (Salesforce, HubSpot, Dynamics365)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Missing one or more required CRM schemas!';
    SET @FailCount = @FailCount + 1;
END

-- 1.2 Verify Salesforce Table Count (15 Tables)
DECLARE @SfTableCount INT;
SELECT @SfTableCount = COUNT(*) FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'Salesforce';

IF @SfTableCount = 15
BEGIN
    PRINT '  [PASS] Salesforce schema has exactly 15 tables';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Salesforce schema table count expected 15, found ' + CAST(@SfTableCount AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

-- 1.3 Verify HubSpot Table Count (11 Tables)
DECLARE @HsTableCount INT;
SELECT @HsTableCount = COUNT(*) FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'HubSpot';

IF @HsTableCount = 11
BEGIN
    PRINT '  [PASS] HubSpot schema has exactly 11 tables';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] HubSpot schema table count expected 11, found ' + CAST(@HsTableCount AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

-- 1.4 Verify Dynamics 365 Table Count (11 Tables)
DECLARE @D365TableCount INT;
SELECT @D365TableCount = COUNT(*) FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'Dynamics365';

IF @D365TableCount = 11
BEGIN
    PRINT '  [PASS] Dynamics 365 schema has exactly 11 tables';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Dynamics 365 schema table count expected 11, found ' + CAST(@D365TableCount AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

-- 1.5 Verify Total Table Count (37 Tables)
DECLARE @TotalTables INT = @SfTableCount + @HsTableCount + @D365TableCount;
IF @TotalTables = 37
BEGIN
    PRINT '  [PASS] Total CRM entity tables across all schemas is 37';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Total CRM tables expected 37, found ' + CAST(@TotalTables AS VARCHAR(10));
    SET @FailCount = @FailCount + 1;
END

-- 1.6 Verify Foreign Key Constraints are Registered
DECLARE @FkCount INT;
SELECT @FkCount = COUNT(*) FROM sys.foreign_keys;

IF @FkCount >= 30
BEGIN
    PRINT '  [PASS] Foreign Key constraints registered (' + CAST(@FkCount AS VARCHAR(10)) + ' found)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Insufficient Foreign Key constraints found (' + CAST(@FkCount AS VARCHAR(10)) + ')';
    SET @FailCount = @FailCount + 1;
END

-- 1.7 Verify Stored Procedures Exist in dbo
IF OBJECT_ID('dbo.sp_CleanupAllCRMData', 'P') IS NOT NULL
    AND OBJECT_ID('dbo.sp_SeedStandardData', 'P') IS NOT NULL
    AND OBJECT_ID('dbo.sp_SimulateHeavyETLLoad', 'P') IS NOT NULL
BEGIN
    PRINT '  [PASS] All 3 standard stored procedures exist (sp_CleanupAllCRMData, sp_SeedStandardData, sp_SimulateHeavyETLLoad)';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Missing one or more required stored procedures in dbo!';
    SET @FailCount = @FailCount + 1;
END

PRINT '------------------------------------------------------------------------';
PRINT 'Test Suite 1 Summary: ' + CAST(@PassCount AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount AS VARCHAR(10)) + ' Failed.';
PRINT '------------------------------------------------------------------------';

IF @FailCount > 0
    THROW 50001, 'Test Suite 1 Failed', 1;
