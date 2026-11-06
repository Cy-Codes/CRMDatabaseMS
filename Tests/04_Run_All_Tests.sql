-- ============================================================================
-- Master Test Runner: CRMDatabaseMS Schema & Data Verification
-- Engine: Microsoft SQL Server 2022+
-- Description: Executes all schema, integrity, and constraint verification suites.
-- ============================================================================
SET NOCOUNT ON;

PRINT '========================================================================';
PRINT '      STARTING CRMDatabaseMS AUTOMATED TEST SUITE EXECUTION             ';
PRINT '========================================================================';

BEGIN TRY
    -- Execute Suite 1: Schema Structure
    PRINT '';
    PRINT '>>> RUNNING TEST SUITE 1: SCHEMA STRUCTURE <<<';

    DECLARE @PassCount1 INT = 0;
    DECLARE @FailCount1 INT = 0;

    -- 1.1 Verify Schemas Exist
    IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Salesforce')
        AND EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'HubSpot')
        AND EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Dynamics365')
    BEGIN
        PRINT '  [PASS] All 3 CRM Schemas exist (Salesforce, HubSpot, Dynamics365)';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Missing one or more required CRM schemas!';
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.2 Verify Salesforce Table Count (15 Tables)
    DECLARE @SfTableCount INT;
    SELECT @SfTableCount = COUNT(*) FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'Salesforce';

    IF @SfTableCount = 15
    BEGIN
        PRINT '  [PASS] Salesforce schema has exactly 15 tables';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Salesforce schema table count expected 15, found ' + CAST(@SfTableCount AS VARCHAR(10));
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.3 Verify HubSpot Table Count (11 Tables)
    DECLARE @HsTableCount INT;
    SELECT @HsTableCount = COUNT(*) FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'HubSpot';

    IF @HsTableCount = 11
    BEGIN
        PRINT '  [PASS] HubSpot schema has exactly 11 tables';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] HubSpot schema table count expected 11, found ' + CAST(@HsTableCount AS VARCHAR(10));
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.4 Verify Dynamics 365 Table Count (11 Tables)
    DECLARE @D365TableCount INT;
    SELECT @D365TableCount = COUNT(*) FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'Dynamics365';

    IF @D365TableCount = 11
    BEGIN
        PRINT '  [PASS] Dynamics 365 schema has exactly 11 tables';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Dynamics 365 schema table count expected 11, found ' + CAST(@D365TableCount AS VARCHAR(10));
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.5 Verify Total Table Count (37 Tables)
    DECLARE @TotalTables INT = @SfTableCount + @HsTableCount + @D365TableCount;
    IF @TotalTables = 37
    BEGIN
        PRINT '  [PASS] Total CRM entity tables across all schemas is 37';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Total CRM tables expected 37, found ' + CAST(@TotalTables AS VARCHAR(10));
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.6 Verify Foreign Key Constraints are Registered
    DECLARE @FkCount INT;
    SELECT @FkCount = COUNT(*) FROM sys.foreign_keys;

    IF @FkCount >= 30
    BEGIN
        PRINT '  [PASS] Foreign Key constraints registered (' + CAST(@FkCount AS VARCHAR(10)) + ' found)';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Insufficient Foreign Key constraints found (' + CAST(@FkCount AS VARCHAR(10)) + ')';
        SET @FailCount1 = @FailCount1 + 1;
    END

    -- 1.7 Verify Stored Procedures Exist in dbo
    IF OBJECT_ID('dbo.sp_CleanupAllCRMData', 'P') IS NOT NULL
        AND OBJECT_ID('dbo.sp_SeedStandardData', 'P') IS NOT NULL
        AND OBJECT_ID('dbo.sp_SimulateHeavyETLLoad', 'P') IS NOT NULL
    BEGIN
        PRINT '  [PASS] All 3 standard stored procedures exist (sp_CleanupAllCRMData, sp_SeedStandardData, sp_SimulateHeavyETLLoad)';
        SET @PassCount1 = @PassCount1 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Missing one or more required stored procedures in dbo!';
        SET @FailCount1 = @FailCount1 + 1;
    END

    PRINT 'Suite 1 Result: ' + CAST(@PassCount1 AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount1 AS VARCHAR(10)) + ' Failed.';
    IF @FailCount1 > 0 THROW 50001, 'Suite 1 Failed', 1;


    -- Execute Suite 2: Data Integrity & Seeding
    PRINT '';
    PRINT '>>> RUNNING TEST SUITE 2: DATA INTEGRITY & SEEDING <<<';

    DECLARE @PassCount2 INT = 0;
    DECLARE @FailCount2 INT = 0;

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
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] sp_CleanupAllCRMData left data in ' + CAST(@NonZeroTableCount AS VARCHAR(10)) + ' tables!';
        SET @FailCount2 = @FailCount2 + 1;
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
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Standard Seed expected 1,850 total rows, found ' + CAST(@TotalRowCount AS VARCHAR(20));
        SET @FailCount2 = @FailCount2 + 1;
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
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Found ' + CAST(@Non50TableCount AS VARCHAR(10)) + ' tables with row count != 50!';
        SET @FailCount2 = @FailCount2 + 1;
    END

    -- 2.5 Verify Salesforce Relational Integrity
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
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Salesforce has orphaned records (Contacts: ' + CAST(@SfOrphanContacts AS VARCHAR(10)) + ', Opps: ' + CAST(@SfOrphanOpps AS VARCHAR(10)) + ')';
        SET @FailCount2 = @FailCount2 + 1;
    END

    -- 2.6 Verify HubSpot Associations & Deals
    DECLARE @HsOrphanLineItems INT;
    SELECT @HsOrphanLineItems = COUNT(*) FROM [HubSpot].[LineItem] li
    LEFT JOIN [HubSpot].[Deal] d ON li.[dealId] = d.[dealId]
    WHERE d.[dealId] IS NULL;

    IF @HsOrphanLineItems = 0
    BEGIN
        PRINT '  [PASS] HubSpot referential integrity intact (0 orphaned LineItems)';
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] HubSpot has orphaned LineItems: ' + CAST(@HsOrphanLineItems AS VARCHAR(10));
        SET @FailCount2 = @FailCount2 + 1;
    END

    -- 2.7 Verify Dynamics 365 Hierarchies
    DECLARE @D365OrphanContacts INT;
    SELECT @D365OrphanContacts = COUNT(*) FROM [Dynamics365].[Contact] c
    LEFT JOIN [Dynamics365].[Account] a ON c.[parentcustomerid] = a.[accountid]
    WHERE a.[accountid] IS NULL;

    IF @D365OrphanContacts = 0
    BEGIN
        PRINT '  [PASS] Dynamics 365 parentcustomerid references intact (0 orphaned Contacts)';
        SET @PassCount2 = @PassCount2 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Dynamics 365 has orphaned Contacts: ' + CAST(@D365OrphanContacts AS VARCHAR(10));
        SET @FailCount2 = @FailCount2 + 1;
    END

    PRINT 'Suite 2 Result: ' + CAST(@PassCount2 AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount2 AS VARCHAR(10)) + ' Failed.';
    IF @FailCount2 > 0 THROW 50002, 'Suite 2 Failed', 1;


    -- Execute Suite 3: Constraint Enforcement & Invariant Tests
    PRINT '';
    PRINT '>>> RUNNING TEST SUITE 3: CONSTRAINT ENFORCEMENT & INVARIANTS <<<';

    DECLARE @PassCount3 INT = 0;
    DECLARE @FailCount3 INT = 0;
    DECLARE @ErrorCaught BIT = 0;
    DECLARE @ComputedName NVARCHAR(121);
    DECLARE @ComputedVal DECIMAL(18, 2);

    -- 3.1 Foreign Key Violation Rejection
    SET @ErrorCaught = 0;
    BEGIN TRY
        INSERT INTO [Salesforce].[Contact] (
            [Id], [AccountId], [LastName], [FirstName], [Email], [OwnerId], [CreatedById], [LastModifiedById]
        ) VALUES (
            '003999999999999AAA', '001NONEXISTENT1AAA', 'OrphanTest', 'Test', 'orphan@test.com',
            '005000000000001AAA', '005000000000001AAA', '005000000000001AAA'
        );
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 547 SET @ErrorCaught = 1;
    END CATCH;

    IF @ErrorCaught = 1
    BEGIN
        PRINT '  [PASS] Foreign Key constraint prevented invalid child record insertion.';
        SET @PassCount3 = @PassCount3 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Foreign Key violation was NOT rejected by the database engine!';
        SET @FailCount3 = @FailCount3 + 1;
    END

    -- 3.2 NOT NULL Violation Rejection
    SET @ErrorCaught = 0;
    BEGIN TRY
        INSERT INTO [Salesforce].[Account] (
            [Id], [Name], [OwnerId], [CreatedById], [LastModifiedById]
        ) VALUES (
            '001999999999999AAA', NULL, '005000000000001AAA', '005000000000001AAA', '005000000000001AAA'
        );
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 515 SET @ErrorCaught = 1;
    END CATCH;

    IF @ErrorCaught = 1
    BEGIN
        PRINT '  [PASS] NOT NULL constraint prevented null mandatory field insertion.';
        SET @PassCount3 = @PassCount3 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] NOT NULL violation was NOT rejected by the database engine!';
        SET @FailCount3 = @FailCount3 + 1;
    END

    -- 3.3 Unique Constraint Rejection
    SET @ErrorCaught = 0;
    BEGIN TRY
        INSERT INTO [Salesforce].[User] ([Id], [Username], [LastName], [FirstName], [Email])
        VALUES ('005999999999999AAA', 'user1@example-crm.com', 'DuplicateUser', 'Test', 'duplicate@example.com');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 2627 OR ERROR_NUMBER() = 2601 SET @ErrorCaught = 1;
    END CATCH;

    IF @ErrorCaught = 1
    BEGIN
        PRINT '  [PASS] UNIQUE constraint prevented duplicate username insertion.';
        SET @PassCount3 = @PassCount3 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] UNIQUE constraint violation was NOT rejected by the database engine!';
        SET @FailCount3 = @FailCount3 + 1;
    END

    -- 3.4 Computed Column Expression Evaluation
    SELECT @ComputedName = [Name] FROM [Salesforce].[User] WHERE [Id] = '005000000000001AAA';
    IF @ComputedName IS NOT NULL AND CHARINDEX('Johnson', @ComputedName) > 0
    BEGIN
        PRINT '  [PASS] Computed column (Salesforce.User.Name) accurately evaluated: "' + @ComputedName + '"';
        SET @PassCount3 = @PassCount3 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Computed column evaluation failed. Found: "' + ISNULL(@ComputedName, 'NULL') + '"';
        SET @FailCount3 = @FailCount3 + 1;
    END

    -- 3.5 Computed Column Calculation
    SELECT @ComputedVal = [ExpectedRevenue] FROM [Salesforce].[Opportunity] WHERE [Id] = '006000000000001AAA';
    IF @ComputedVal = 16250.00
    BEGIN
        PRINT '  [PASS] Computed column (Salesforce.Opportunity.ExpectedRevenue) calculated: ' + CAST(@ComputedVal AS VARCHAR(20));
        SET @PassCount3 = @PassCount3 + 1;
    END
    ELSE
    BEGIN
        PRINT '  [FAIL] Computed column expected 16250.00, found ' + CAST(ISNULL(@ComputedVal, 0) AS VARCHAR(20));
        SET @FailCount3 = @FailCount3 + 1;
    END

    PRINT 'Suite 3 Result: ' + CAST(@PassCount3 AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount3 AS VARCHAR(10)) + ' Failed.';
    IF @FailCount3 > 0 THROW 50003, 'Suite 3 Failed', 1;

    PRINT '';
    PRINT '========================================================================';
    PRINT '     ALL CRMDatabaseMS TESTS COMPLETED SUCCESSFULLY!                    ';
    PRINT '     Total Passed: ' + CAST(@PassCount1 + @PassCount2 + @PassCount3 AS VARCHAR(10));
    PRINT '========================================================================';
END TRY
BEGIN CATCH
    PRINT '========================================================================';
    PRINT '❌ CRITICAL TEST FAILURE: ' + ERROR_MESSAGE();
    PRINT '========================================================================';
    THROW;
END CATCH;
