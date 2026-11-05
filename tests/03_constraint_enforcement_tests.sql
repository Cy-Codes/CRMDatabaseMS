-- ============================================================================
-- Test Suite: 03_constraint_enforcement_tests.sql
-- Engine: Microsoft SQL Server (T-SQL)
-- Scope: Negative tests verifying database engine enforcement of FK, NOT NULL,
--        UNIQUE constraints, and computed generated columns
-- ============================================================================
SET NOCOUNT ON;

DECLARE @PassCount INT = 0;
DECLARE @FailCount INT = 0;
DECLARE @ErrorCaught BIT = 0;
DECLARE @ComputedName NVARCHAR(121);
DECLARE @ComputedVal DECIMAL(18, 2);

PRINT '========================================================================';
PRINT 'Test Suite 3: Constraint Enforcement & Invariant Tests (SQL Server)';
PRINT '========================================================================';

-- Test 3.1: Foreign Key Violation Rejection
SET @ErrorCaught = 0;
BEGIN TRY
    INSERT INTO [Salesforce].[Contact] (
        [Id], [AccountId], [LastName], [FirstName], [Email], [OwnerId], [CreatedById], [LastModifiedById]
    ) VALUES (
        '003999999999999AAA',
        '001NONEXISTENT1AAA', -- Invalid AccountId foreign key
        'OrphanTest',
        'Test',
        'orphan@test.com',
        '005000000000001AAA',
        '005000000000001AAA',
        '005000000000001AAA'
    );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 547 -- Foreign Key violation error code in SQL Server
    BEGIN
        SET @ErrorCaught = 1;
    END
END CATCH;

IF @ErrorCaught = 1
BEGIN
    PRINT '  [PASS] Test 3.1: Foreign Key constraint prevented invalid child record insertion.';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.1: Foreign Key violation was NOT rejected by the database engine!';
    SET @FailCount = @FailCount + 1;
END

-- Test 3.2: NOT NULL Constraint Violation Rejection
SET @ErrorCaught = 0;
BEGIN TRY
    INSERT INTO [Salesforce].[Account] (
        [Id], [Name], [OwnerId], [CreatedById], [LastModifiedById]
    ) VALUES (
        '001999999999999AAA',
        NULL, -- Violates NOT NULL on Name
        '005000000000001AAA',
        '005000000000001AAA',
        '005000000000001AAA'
    );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 515 -- Cannot insert NULL error in SQL Server
    BEGIN
        SET @ErrorCaught = 1;
    END
END CATCH;

IF @ErrorCaught = 1
BEGIN
    PRINT '  [PASS] Test 3.2: NOT NULL constraint prevented null mandatory field insertion.';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.2: NOT NULL violation was NOT rejected by the database engine!';
    SET @FailCount = @FailCount + 1;
END

-- Test 3.3: Unique Constraint Rejection
SET @ErrorCaught = 0;
BEGIN TRY
    INSERT INTO [Salesforce].[User] (
        [Id], [Username], [LastName], [FirstName], [Email]
    ) VALUES (
        '005999999999999AAA',
        'user1@example-crm.com', -- Already exists in standard seed
        'DuplicateUser',
        'Test',
        'duplicate@example.com'
    );
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 2627 OR ERROR_NUMBER() = 2601 -- Unique constraint / unique index violation
    BEGIN
        SET @ErrorCaught = 1;
    END
END CATCH;

IF @ErrorCaught = 1
BEGIN
    PRINT '  [PASS] Test 3.3: UNIQUE constraint prevented duplicate username insertion.';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.3: UNIQUE constraint violation was NOT rejected by the database engine!';
    SET @FailCount = @FailCount + 1;
END

-- Test 3.4: Computed Column Expression Evaluation (Salesforce.User.Name)
SELECT @ComputedName = [Name]
FROM [Salesforce].[User]
WHERE [Id] = '005000000000001AAA';

IF @ComputedName IS NOT NULL AND CHARINDEX('Johnson', @ComputedName) > 0
BEGIN
    PRINT '  [PASS] Test 3.4: Computed column (Salesforce.User.Name) accurately evaluated: "' + @ComputedName + '"';
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.4: Computed column evaluation failed. Found: "' + ISNULL(@ComputedName, 'NULL') + '"';
    SET @FailCount = @FailCount + 1;
END

-- Test 3.5: Computed Column Expression Evaluation (Salesforce.Opportunity.ExpectedRevenue)
SELECT @ComputedVal = [ExpectedRevenue]
FROM [Salesforce].[Opportunity]
WHERE [Id] = '006000000000001AAA';

-- Row 1: Amount = 65000, Probability = 25.00 -> ExpectedRevenue = 16250.00
IF @ComputedVal = 16250.00
BEGIN
    PRINT '  [PASS] Test 3.5: Computed column (Salesforce.Opportunity.ExpectedRevenue) accurately calculated: ' + CAST(@ComputedVal AS VARCHAR(20));
    SET @PassCount = @PassCount + 1;
END
ELSE
BEGIN
    PRINT '  [FAIL] Test 3.5: Computed column expected 16250.00, found ' + CAST(ISNULL(@ComputedVal, 0) AS VARCHAR(20));
    SET @FailCount = @FailCount + 1;
END

PRINT '------------------------------------------------------------------------';
PRINT 'Test Suite 3 Summary: ' + CAST(@PassCount AS VARCHAR(10)) + ' Passed, ' + CAST(@FailCount AS VARCHAR(10)) + ' Failed.';
PRINT '------------------------------------------------------------------------';

IF @FailCount > 0
    THROW 50003, 'Test Suite 3 Failed', 1;
