CREATE PROCEDURE [dbo].[sp_SimulateHeavyETLLoad]
    @ScaleFactor INT = 100, -- Multiplier: 100 creates ~5,000 accounts, ~15,000 contacts, ~10,000 deals, ~25,000 line items, etc. per CRM
    @CleanExisting BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF @ScaleFactor < 1
        SET @ScaleFactor = 1;

    IF @CleanExisting = 1
    BEGIN
        EXEC [dbo].[sp_CleanupAllCRMData];
    END

    PRINT '========================================================================';
    PRINT 'Simulating heavy production CRM ETL data load (Scale Factor: ' + CAST(@ScaleFactor AS NVARCHAR(10)) + ')...';
    PRINT '========================================================================';

    DECLARE @AccountCount INT = 50 * @ScaleFactor;          -- e.g. 5,000 at scale 100
    DECLARE @ContactCount INT = 150 * @ScaleFactor;         -- e.g. 15,000 at scale 100
    DECLARE @OpportunityCount INT = 100 * @ScaleFactor;     -- e.g. 10,000 at scale 100
    DECLARE @LineItemCount INT = 250 * @ScaleFactor;        -- e.g. 25,000 at scale 100
    DECLARE @ActivityCount INT = 250 * @ScaleFactor;        -- e.g. 25,000 at scale 100
    DECLARE @CaseCount INT = 50 * @ScaleFactor;             -- e.g. 5,000 at scale 100
    DECLARE @UserCount INT = CASE WHEN 10 * @ScaleFactor > 1000 THEN 1000 ELSE 10 * @ScaleFactor END; -- e.g. 1,000 system users
    DECLARE @ProductCount INT = CASE WHEN 5 * @ScaleFactor > 500 THEN 500 ELSE 5 * @ScaleFactor END;   -- e.g. 500 catalog products

    PRINT 'Target volumes per CRM schema:';
    PRINT '  - Users / Owners: ' + CAST(@UserCount AS NVARCHAR(10));
    PRINT '  - Products / SKUs: ' + CAST(@ProductCount AS NVARCHAR(10));
    PRINT '  - Companies / Accounts: ' + CAST(@AccountCount AS NVARCHAR(10));
    PRINT '  - Contacts: ' + CAST(@ContactCount AS NVARCHAR(10));
    PRINT '  - Opportunities / Deals: ' + CAST(@OpportunityCount AS NVARCHAR(10));
    PRINT '  - Line Items: ' + CAST(@LineItemCount AS NVARCHAR(10));
    PRINT '  - Cases / Tickets: ' + CAST(@CaseCount AS NVARCHAR(10));
    PRINT '  - Activities / Engagements: ' + CAST(@ActivityCount AS NVARCHAR(10));

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Fast Tally table builder
        ;WITH 
            E1(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1), -- 10
            E2(N) AS (SELECT 1 FROM E1 a CROSS JOIN E1 b), -- 100
            E4(N) AS (SELECT 1 FROM E2 a CROSS JOIN E2 b), -- 10,000
            E8(N) AS (SELECT 1 FROM E4 a CROSS JOIN E4 b), -- 100,000,000
            Tally AS (SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N FROM E8)
        SELECT TOP (CASE WHEN @LineItemCount > @ActivityCount THEN @LineItemCount ELSE @ActivityCount END) N
        INTO #Tally
        FROM Tally;

        CREATE CLUSTERED INDEX CIX_Tally ON #Tally(N);

        -------------------------------------------------------------------------
        -- 1. HEAVY LOAD: SALESFORCE SCHEMA
        -------------------------------------------------------------------------
        PRINT '  -> Bulk inserting Salesforce production dataset...';

        -- Users
        INSERT INTO [Salesforce].[User] ([Id], [Username], [LastName], [FirstName], [Email], [IsActive], [Title], [Department], [Phone])
        SELECT 
            '005' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            'sf_user_' + CAST(N AS NVARCHAR(20)) + '@enterprise-etl.com',
            'RepLastName_' + CAST(N AS NVARCHAR(20)),
            'RepFirstName_' + CAST(N AS NVARCHAR(20)),
            'sf_user_' + CAST(N AS NVARCHAR(20)) + '@enterprise-etl.com',
            CASE WHEN (N % 20) = 0 THEN 0 ELSE 1 END,
            CASE (N % 5) WHEN 0 THEN 'Enterprise Account Executive' WHEN 1 THEN 'Sales Director' WHEN 2 THEN 'Solutions Engineer' WHEN 3 THEN 'SDR' ELSE 'Customer Success Manager' END,
            CASE (N % 3) WHEN 0 THEN 'Commercial Sales' WHEN 1 THEN 'Enterprise Sales' ELSE 'Customer Support' END,
            '+1-555-' + RIGHT('0000' + CAST(1000 + (N % 9000) AS NVARCHAR(10)), 4)
        FROM #Tally WHERE N <= @UserCount;

        -- Accounts
        INSERT INTO [Salesforce].[Account] (
            [Id], [IsDeleted], [Name], [Type], [BillingStreet], [BillingCity], [BillingState], [BillingPostalCode],
            [BillingCountry], [Phone], [Website], [Industry], [AnnualRevenue], [NumberOfEmployees], [Description],
            [OwnerId], [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '001' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            CASE WHEN (N % 50) = 0 THEN 1 ELSE 0 END, -- 2% soft deleted for ETL tombstone testing
            'Enterprise Corp ' + CAST(N AS NVARCHAR(20)),
            CASE (N % 4) WHEN 0 THEN 'Customer - Direct' WHEN 1 THEN 'Customer - Channel' WHEN 2 THEN 'Prospect' ELSE 'Partner' END,
            CAST((N % 999) + 1 AS NVARCHAR(10)) + ' Corporate Blvd Suite ' + CAST((N % 50) + 1 AS NVARCHAR(10)),
            CASE (N % 6) WHEN 0 THEN 'San Francisco' WHEN 1 THEN 'New York' WHEN 2 THEN 'Chicago' WHEN 3 THEN 'Austin' WHEN 4 THEN 'London' ELSE 'Tokyo' END,
            CASE (N % 6) WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'IL' WHEN 3 THEN 'TX' WHEN 4 THEN 'ENG' ELSE 'TOK' END,
            RIGHT('00000' + CAST(10000 + (N % 89999) AS NVARCHAR(10)), 5),
            CASE (N % 6) WHEN 4 THEN 'United Kingdom' WHEN 5 THEN 'Japan' ELSE 'United States' END,
            '+1-415-555-' + RIGHT('0000' + CAST(N % 10000 AS NVARCHAR(10)), 4),
            'https://www.corp' + CAST(N AS NVARCHAR(20)) + '-etl.com',
            CASE (N % 6) WHEN 0 THEN 'Technology' WHEN 1 THEN 'Finance' WHEN 2 THEN 'Healthcare' WHEN 3 THEN 'Manufacturing' WHEN 4 THEN 'Retail' ELSE 'Telecommunications' END,
            CAST(100000 + ((N * 37) % 50000000) AS DECIMAL(18,2)),
            10 + ((N * 13) % 25000),
            'ETL Benchmark Account entity record #' + CAST(N AS NVARCHAR(20)),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()), -- spread across past 2 years
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA'
        FROM #Tally WHERE N <= @AccountCount;

        -- Products
        INSERT INTO [Salesforce].[Product2] ([Id], [Name], [ProductCode], [Description], [IsActive], [Family], [CreatedById], [LastModifiedById])
        SELECT 
            '01t' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            'Salesforce Cloud Product SKU ' + CAST(N AS NVARCHAR(20)),
            'SKU-SF-ETL-' + RIGHT('000000' + CAST(N AS NVARCHAR(20)), 6),
            'Product catalog component for ETL benchmark SKU #' + CAST(N AS NVARCHAR(20)),
            1,
            CASE (N % 4) WHEN 0 THEN 'SaaS Software' WHEN 1 THEN 'Professional Services' WHEN 2 THEN 'Hardware Platform' ELSE 'Premium SLA' END,
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA'
        FROM #Tally WHERE N <= @ProductCount;

        -- Pricebook2 (Standard + Tiers)
        INSERT INTO [Salesforce].[Pricebook2] ([Id], [Name], [Description], [IsActive], [IsStandard], [CreatedById], [LastModifiedById])
        SELECT 
            '01s' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            CASE WHEN N = 1 THEN 'Standard Price Book' ELSE 'Commercial Enterprise Price Book Tier ' + CAST(N AS NVARCHAR(20)) END,
            'ETL Pricebook tier ' + CAST(N AS NVARCHAR(20)),
            1,
            CASE WHEN N = 1 THEN 1 ELSE 0 END,
            '005000000000001AAA', '005000000000001AAA'
        FROM #Tally WHERE N <= CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END;

        -- PricebookEntry
        INSERT INTO [Salesforce].[PricebookEntry] ([Id], [Pricebook2Id], [Product2Id], [UnitPrice], [IsActive], [UseStandardPrice], [CreatedById], [LastModifiedById])
        SELECT 
            '01u' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            '01s' + RIGHT('000000000000' + CAST(((N - 1) % (CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END)) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            '01t' + RIGHT('000000000000' + CAST(((N - 1) % @ProductCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            CAST(50.00 + ((N * 19) % 5000) AS DECIMAL(18,2)),
            1, 0,
            '005000000000001AAA', '005000000000001AAA'
        FROM #Tally WHERE N <= @ProductCount;

        -- Contacts
        INSERT INTO [Salesforce].[Contact] (
            [Id], [IsDeleted], [AccountId], [LastName], [FirstName], [Salutation], [Title], [Department],
            [Email], [Phone], [LeadSource], [OwnerId], [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '003' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            CASE WHEN (N % 50) = 0 THEN 1 ELSE 0 END,
            '001' + RIGHT('000000000000' + CAST(((N - 1) % @AccountCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            'ContactLast_' + CAST(N AS NVARCHAR(20)),
            'ContactFirst_' + CAST(N AS NVARCHAR(20)),
            CASE (N % 3) WHEN 0 THEN 'Mr.' WHEN 1 THEN 'Ms.' ELSE 'Dr.' END,
            CASE (N % 5) WHEN 0 THEN 'Chief Technology Officer' WHEN 1 THEN 'VP Sales' WHEN 2 THEN 'Head of Engineering' WHEN 3 THEN 'Director of Purchasing' ELSE 'Procurement Manager' END,
            CASE (N % 4) WHEN 0 THEN 'Executive' WHEN 1 THEN 'Engineering' WHEN 2 THEN 'Sales' ELSE 'Procurement' END,
            'contact' + CAST(N AS NVARCHAR(20)) + '@corp' + CAST(((N - 1) % @AccountCount) + 1 AS NVARCHAR(20)) + '-etl.com',
            '+1-555-' + RIGHT('0000' + CAST(N % 10000 AS NVARCHAR(10)), 4),
            CASE (N % 5) WHEN 0 THEN 'Web' WHEN 1 THEN 'Trade Show' WHEN 2 THEN 'Partner' WHEN 3 THEN 'Referral' ELSE 'Organic Search' END,
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA'
        FROM #Tally WHERE N <= @ContactCount;

        -- Leads
        INSERT INTO [Salesforce].[Lead] (
            [Id], [LastName], [FirstName], [Company], [Title], [Email], [Phone], [LeadSource],
            [Status], [Industry], [AnnualRevenue], [NumberOfEmployees], [IsConverted], [OwnerId],
            [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '00Q' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            'LeadLast_' + CAST(N AS NVARCHAR(20)),
            'LeadFirst_' + CAST(N AS NVARCHAR(20)),
            'Prospective Venture ' + CAST(N AS NVARCHAR(20)),
            'Director of Strategy',
            'lead' + CAST(N AS NVARCHAR(20)) + '@prospect' + CAST(N AS NVARCHAR(20)) + '.com',
            '+1-555-' + RIGHT('0000' + CAST(N % 10000 AS NVARCHAR(10)), 4),
            CASE (N % 4) WHEN 0 THEN 'Inbound Marketing' WHEN 1 THEN 'Webinar' WHEN 2 THEN 'Cold Outreach' ELSE 'Referral' END,
            CASE (N % 4) WHEN 0 THEN 'Open - Not Contacted' WHEN 1 THEN 'Working - Contacted' WHEN 2 THEN 'Closed - Converted' ELSE 'Closed - Not Converted' END,
            CASE (N % 4) WHEN 0 THEN 'Technology' WHEN 1 THEN 'Finance' WHEN 2 THEN 'Healthcare' ELSE 'Manufacturing' END,
            CAST(50000 + ((N * 23) % 5000000) AS DECIMAL(18,2)),
            5 + (N % 500),
            CASE WHEN (N % 4) = 2 THEN 1 ELSE 0 END,
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005000000000001AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005000000000001AAA'
        FROM #Tally WHERE N <= @ContactCount;

        -- Opportunities
        INSERT INTO [Salesforce].[Opportunity] (
            [Id], [AccountId], [Name], [StageName], [Amount], [Probability],
            [CloseDate], [Type], [LeadSource], [IsClosed], [IsWon], [ForecastCategoryName],
            [OwnerId], [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '006' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            '001' + RIGHT('000000000000' + CAST(((N - 1) % @AccountCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            'Deal - Cloud Migration Project #' + CAST(N AS NVARCHAR(20)),
            CASE (N % 6) WHEN 0 THEN 'Prospecting' WHEN 1 THEN 'Qualification' WHEN 2 THEN 'Needs Analysis' WHEN 3 THEN 'Proposal/Price Quote' WHEN 4 THEN 'Closed Won' ELSE 'Closed Lost' END,
            CAST(10000 + ((N * 47) % 500000) AS DECIMAL(18,2)),
            CASE (N % 6) WHEN 0 THEN 10.00 WHEN 1 THEN 25.00 WHEN 2 THEN 50.00 WHEN 3 THEN 75.00 WHEN 4 THEN 100.00 ELSE 0.00 END,
            DATEADD(DAY, (N % 180) - 90, CAST(SYSUTCDATETIME() AS DATE)),
            CASE (N % 3) WHEN 0 THEN 'New Business' WHEN 1 THEN 'Existing Customer - Upgrade' ELSE 'Existing Customer - Replacement' END,
            CASE (N % 4) WHEN 0 THEN 'Direct Sales' WHEN 1 THEN 'Partner' WHEN 2 THEN 'Web Inbound' ELSE 'Referral' END,
            CASE WHEN (N % 6) IN (4, 5) THEN 1 ELSE 0 END,
            CASE WHEN (N % 6) = 4 THEN 1 ELSE 0 END,
            CASE (N % 6) WHEN 0 THEN 'Pipeline' WHEN 1 THEN 'Pipeline' WHEN 2 THEN 'BestCase' WHEN 3 THEN 'Commit' WHEN 4 THEN 'Closed' ELSE 'Omitted' END,
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005000000000001AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005000000000001AAA'
        FROM #Tally WHERE N <= @OpportunityCount;

        -- OpportunityLineItems
        INSERT INTO [Salesforce].[OpportunityLineItem] (
            [Id], [OpportunityId], [PricebookEntryId], [Quantity], [UnitPrice], [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '00k' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            '006' + RIGHT('000000000000' + CAST(((N - 1) % @OpportunityCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            '01u' + RIGHT('000000000000' + CAST(((N - 1) % @ProductCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            CAST(1 + (N % 50) AS DECIMAL(12,2)),
            CAST(50.00 + ((N * 19) % 5000) AS DECIMAL(18,2)),
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005000000000001AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005000000000001AAA'
        FROM #Tally WHERE N <= @LineItemCount;

        -- Cases
        INSERT INTO [Salesforce].[Case] (
            [Id], [CaseNumber], [ContactId], [AccountId], [Type], [Status], [Origin], [Subject], [Priority], [Description], [OwnerId],
            [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '500' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            'SF-ETL-' + RIGHT('00000000' + CAST(N AS NVARCHAR(20)), 8),
            '003' + RIGHT('000000000000' + CAST(((N - 1) % @ContactCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            '001' + RIGHT('000000000000' + CAST(((N - 1) % @AccountCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            CASE (N % 3) WHEN 0 THEN 'Technical Incident' WHEN 1 THEN 'Billing Question' ELSE 'Feature Request' END,
            CASE (N % 4) WHEN 0 THEN 'New' WHEN 1 THEN 'Working' WHEN 2 THEN 'Escalated' ELSE 'Closed' END,
            CASE (N % 3) WHEN 0 THEN 'Web' WHEN 1 THEN 'Email' ELSE 'Phone' END,
            'Case Issue #' + CAST(N AS NVARCHAR(20)) + ': Production API Throughput',
            CASE (N % 4) WHEN 0 THEN 'Critical' WHEN 1 THEN 'High' WHEN 2 THEN 'Medium' ELSE 'Low' END,
            'Automated production ETL case payload record #' + CAST(N AS NVARCHAR(20)),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005000000000001AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005000000000001AAA'
        FROM #Tally WHERE N <= @CaseCount;

        -- Tasks / Activities
        INSERT INTO [Salesforce].[Task] (
            [Id], [WhoId], [WhatId], [Subject], [ActivityDate], [Status], [Priority], [IsHighPriority], [Description], [OwnerId],
            [CreatedDate], [CreatedById], [LastModifiedDate], [LastModifiedById]
        )
        SELECT 
            '00T' + RIGHT('000000000000' + CAST(N AS NVARCHAR(20)), 12) + 'AAA',
            '003' + RIGHT('000000000000' + CAST(((N - 1) % @ContactCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            '006' + RIGHT('000000000000' + CAST(((N - 1) % @OpportunityCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            CASE (N % 4) WHEN 0 THEN 'Follow-up Call' WHEN 1 THEN 'Email Contract' WHEN 2 THEN 'Schedule Demo' ELSE 'Quarterly Business Review' END,
            CAST(DATEADD(DAY, (N % 60) - 30, SYSUTCDATETIME()) AS DATE),
            CASE (N % 3) WHEN 0 THEN 'Not Started' WHEN 1 THEN 'In Progress' ELSE 'Completed' END,
            CASE (N % 3) WHEN 0 THEN 'High' WHEN 1 THEN 'Normal' ELSE 'Low' END,
            CASE WHEN (N % 3) = 0 THEN 1 ELSE 0 END,
            'Activity task item for high-volume ETL simulation record #' + CAST(N AS NVARCHAR(20)),
            '005' + RIGHT('000000000000' + CAST(((N - 1) % @UserCount) + 1 AS NVARCHAR(20)), 12) + 'AAA',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            '005000000000001AAA',
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            '005000000000001AAA'
        FROM #Tally WHERE N <= @ActivityCount;


        -------------------------------------------------------------------------
        -- 2. HEAVY LOAD: HUBSPOT SCHEMA
        -------------------------------------------------------------------------
        PRINT '  -> Bulk inserting HubSpot production dataset...';

        -- Owners
        INSERT INTO [HubSpot].[Owner] ([ownerId], [email], [firstName], [lastName], [userId], [createdAt], [updatedAt])
        SELECT 
            100000 + N,
            'hs_rep_' + CAST(N AS NVARCHAR(20)) + '@growth-etl.com',
            'HubRepFirst_' + CAST(N AS NVARCHAR(20)),
            'HubRepLast_' + CAST(N AS NVARCHAR(20)),
            500000 + N,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME())
        FROM #Tally WHERE N <= @UserCount;

        -- Companies
        INSERT INTO [HubSpot].[Company] (
            [companyId], [name], [domain], [industry], [phone], [city], [state], [country],
            [annualRevenue], [numberOfEmployees], [lifecyclestage], [ownerId], [createdAt], [updatedAt], [archived]
        )
        SELECT 
            200000 + N,
            'HubSpot Inbound Enterprise ' + CAST(N AS NVARCHAR(20)),
            'company' + CAST(N AS NVARCHAR(20)) + '-inbound.io',
            CASE (N % 5) WHEN 0 THEN 'INFORMATION_TECHNOLOGY_AND_SERVICES' WHEN 1 THEN 'FINANCIAL_SERVICES' WHEN 2 THEN 'MARKETING_AND_ADVERTISING' WHEN 3 THEN 'HEALTHCARE' ELSE 'RETAIL' END,
            '+1-617-555-' + RIGHT('0000' + CAST(N % 10000 AS NVARCHAR(10)), 4),
            CASE (N % 5) WHEN 0 THEN 'Boston' WHEN 1 THEN 'New York' WHEN 2 THEN 'San Francisco' WHEN 3 THEN 'Dublin' ELSE 'Singapore' END,
            CASE (N % 5) WHEN 0 THEN 'MA' WHEN 1 THEN 'NY' WHEN 2 THEN 'CA' WHEN 3 THEN 'LEI' ELSE 'SG' END,
            CASE (N % 5) WHEN 3 THEN 'Ireland' WHEN 4 THEN 'Singapore' ELSE 'United States' END,
            CAST(250000 + ((N * 41) % 75000000) AS DECIMAL(18,2)),
            20 + ((N * 17) % 15000),
            CASE (N % 4) WHEN 0 THEN 'lead' WHEN 1 THEN 'marketingqualifiedlead' WHEN 2 THEN 'salesqualifiedlead' ELSE 'customer' END,
            100000 + ((N - 1) % @UserCount) + 1,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            CASE WHEN (N % 50) = 0 THEN 1 ELSE 0 END
        FROM #Tally WHERE N <= @AccountCount;

        -- Contacts
        INSERT INTO [HubSpot].[Contact] (
            [contactId], [email], [firstName], [lastName], [phone], [jobTitle], [lifecyclestage],
            [leadStatus], [associatedCompanyId], [ownerId], [createdAt], [updatedAt], [archived]
        )
        SELECT 
            300000 + N,
            'inbound_user_' + CAST(N AS NVARCHAR(20)) + '@company' + CAST(((N - 1) % @AccountCount) + 1 AS NVARCHAR(20)) + '-inbound.io',
            'InboundFirst_' + CAST(N AS NVARCHAR(20)),
            'InboundLast_' + CAST(N AS NVARCHAR(20)),
            '+1-617-555-' + RIGHT('0000' + CAST(N % 10000 AS NVARCHAR(10)), 4),
            CASE (N % 5) WHEN 0 THEN 'Chief Marketing Officer' WHEN 1 THEN 'VP Demand Gen' WHEN 2 THEN 'Director of Growth' WHEN 3 THEN 'Sales Ops Manager' ELSE 'Marketing Analyst' END,
            CASE (N % 4) WHEN 0 THEN 'lead' WHEN 1 THEN 'marketingqualifiedlead' WHEN 2 THEN 'salesqualifiedlead' ELSE 'customer' END,
            CASE (N % 4) WHEN 0 THEN 'NEW' WHEN 1 THEN 'OPEN' WHEN 2 THEN 'IN_PROGRESS' ELSE 'CONNECTED' END,
            200000 + ((N - 1) % @AccountCount) + 1,
            100000 + ((N - 1) % @UserCount) + 1,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            CASE WHEN (N % 50) = 0 THEN 1 ELSE 0 END
        FROM #Tally WHERE N <= @ContactCount;

        -- Pipelines & Stages
        INSERT INTO [HubSpot].[Pipeline] ([pipelineId], [label], [displayOrder], [objectType], [createdAt], [updatedAt])
        SELECT 
            'pipe_' + CAST(400000 + N AS NVARCHAR(20)),
            'HubSpot Sales Pipeline Tier ' + CAST(N AS NVARCHAR(20)),
            N, 'deals',
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM #Tally WHERE N <= CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END;

        INSERT INTO [HubSpot].[DealStage] ([stageId], [pipelineId], [label], [displayOrder], [probability], [closedWon], [createdAt], [updatedAt])
        SELECT 
            'stage_' + CAST(500000 + N AS NVARCHAR(20)),
            'pipe_' + CAST(400000 + ((N - 1) % (CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END)) + 1 AS NVARCHAR(20)),
            CASE (N % 5) WHEN 0 THEN 'Appointment Scheduled' WHEN 1 THEN 'Qualified To Buy' WHEN 2 THEN 'Presentation Scheduled' WHEN 3 THEN 'Contract Sent' ELSE 'Closed Won' END,
            (N % 5) + 1,
            CASE (N % 5) WHEN 0 THEN 0.20 WHEN 1 THEN 0.40 WHEN 2 THEN 0.60 WHEN 3 THEN 0.80 ELSE 1.00 END,
            CASE WHEN (N % 5) = 4 THEN 1 ELSE 0 END,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM #Tally WHERE N <= (CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END) * 5;

        -- Deals
        INSERT INTO [HubSpot].[Deal] (
            [dealId], [dealName], [amount], [pipelineId], [dealStageId], [closedate], [dealType], [ownerId],
            [createdAt], [updatedAt], [archived]
        )
        SELECT 
            600000 + N,
            'HubSpot Growth Package Deal #' + CAST(N AS NVARCHAR(20)),
            CAST(5000 + ((N * 31) % 250000) AS DECIMAL(18,2)),
            'pipe_' + CAST(400000 + ((N - 1) % (CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END)) + 1 AS NVARCHAR(20)),
            'stage_' + CAST(500000 + ((N - 1) % ((CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END) * 5)) + 1 AS NVARCHAR(20)),
            DATEADD(DAY, (N % 120) - 60, SYSUTCDATETIME()),
            CASE (N % 2) WHEN 0 THEN 'newbusiness' ELSE 'existingbusiness' END,
            100000 + ((N - 1) % @UserCount) + 1,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME()),
            CASE WHEN (N % 50) = 0 THEN 1 ELSE 0 END
        FROM #Tally WHERE N <= @OpportunityCount;

        -- Products
        INSERT INTO [HubSpot].[Product] (
            [productId], [name], [description], [price], [cost], [recurringBillingFrequency], [createdAt], [updatedAt]
        )
        SELECT 
            800000 + N,
            'HubSpot Marketing Hub SKU ' + CAST(N AS NVARCHAR(20)),
            'High volume ETL product SKU description #' + CAST(N AS NVARCHAR(20)),
            CAST(500.00 + ((N * 29) % 5000) AS DECIMAL(18,2)),
            CAST(100.00 + ((N * 13) % 1500) AS DECIMAL(18,2)),
            CASE (N % 3) WHEN 0 THEN 'monthly' WHEN 1 THEN 'annually' ELSE 'quarterly' END,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM #Tally WHERE N <= @ProductCount;

        -- LineItems
        INSERT INTO [HubSpot].[LineItem] (
            [lineItemId], [dealId], [productId], [name], [quantity], [price], [discount], [createdAt], [updatedAt]
        )
        SELECT 
            900000 + N,
            600000 + ((N - 1) % @OpportunityCount) + 1,
            800000 + ((N - 1) % @ProductCount) + 1,
            'HubSpot Marketing Hub SKU ' + CAST(((N - 1) % @ProductCount) + 1 AS NVARCHAR(20)),
            CAST(1 + (N % 20) AS DECIMAL(12,2)),
            CAST(500.00 + ((N * 29) % 5000) AS DECIMAL(18,2)),
            CASE WHEN (N % 5) = 0 THEN 50.00 ELSE 0.00 END,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME())
        FROM #Tally WHERE N <= @LineItemCount;

        -- Engagements
        INSERT INTO [HubSpot].[Engagement] (
            [engagementId], [engagementType], [timestamp], [ownerId], [body], [status], [createdAt], [updatedAt]
        )
        SELECT 
            1000000 + N,
            CASE (N % 5) WHEN 0 THEN 'EMAIL' WHEN 1 THEN 'CALL' WHEN 2 THEN 'MEETING' WHEN 3 THEN 'NOTE' ELSE 'TASK' END,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            100000 + ((N - 1) % @UserCount) + 1,
            'ETL simulation client engagement transcript notes record #' + CAST(N AS NVARCHAR(20)),
            'COMPLETED',
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(N % 525600), SYSUTCDATETIME())
        FROM #Tally WHERE N <= @ActivityCount;

        -- ObjectAssociations (Polymorphic association engine benchmark, auto-incrementing IDENTITY)
        INSERT INTO [HubSpot].[ObjectAssociation] (
            [fromObjectType], [fromObjectId], [toObjectType], [toObjectId], [associationTypeId], [createdAt]
        )
        SELECT 
            'contact',
            300000 + N,
            'company',
            200000 + ((N - 1) % @AccountCount) + 1,
            1,
            DATEADD(MINUTE, -(N % 1051200), SYSUTCDATETIME())
        FROM #Tally WHERE N <= @ContactCount;


        -------------------------------------------------------------------------
        -- 3. HEAVY LOAD: DYNAMICS 365 SCHEMA
        -------------------------------------------------------------------------
        PRINT '  -> Bulk inserting Dynamics 365 production dataset...';

        -- Generate deterministic GUID mapping batches
        CREATE TABLE #D365_Bulk_BU (N INT PRIMARY KEY, BUId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Bulk_User (N INT PRIMARY KEY, UserId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Bulk_Product (N INT PRIMARY KEY, ProductId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Bulk_PriceLevel (N INT PRIMARY KEY, PriceLevelId UNIQUEIDENTIFIER);

        DECLARE @D365BUCount INT = CASE WHEN @UserCount / 10 < 10 THEN 10 ELSE @UserCount / 10 END;

        INSERT INTO #D365_Bulk_BU
        SELECT N, CAST(CAST(0xAA000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER)
        FROM #Tally WHERE N <= @D365BUCount;

        INSERT INTO #D365_Bulk_User
        SELECT N, CAST(CAST(0xBB000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER)
        FROM #Tally WHERE N <= @UserCount;

        INSERT INTO #D365_Bulk_Product
        SELECT N, CAST(CAST(0xCC000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER)
        FROM #Tally WHERE N <= @ProductCount;

        INSERT INTO #D365_Bulk_PriceLevel
        SELECT N, CAST(CAST(0xDD000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER)
        FROM #Tally WHERE N <= CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END;

        -- Business Units
        INSERT INTO [Dynamics365].[BusinessUnit] ([businessunitid], [name], [parentbusinessunitid], [isdisabled], [createdon], [modifiedon])
        SELECT 
            b.BUId,
            'Dynamics BU Regional Division #' + CAST(b.N AS NVARCHAR(20)),
            CASE WHEN b.N > 1 THEN (SELECT TOP 1 BUId FROM #D365_Bulk_BU WHERE N = 1) ELSE NULL END,
            0,
            SYSUTCDATETIME(), SYSUTCDATETIME()
        FROM #D365_Bulk_BU b;

        -- System Users
        INSERT INTO [Dynamics365].[SystemUser] (
            [systemuserid], [businessunitid], [domainname], [fullname], [firstname], [lastname], [internalemailaddress], [jobtitle], [isdisabled], [createdon], [modifiedon]
        )
        SELECT 
            u.UserId,
            b.BUId,
            'CORP\\d365_rep_' + CAST(u.N AS NVARCHAR(20)),
            'Dynamics User ' + CAST(u.N AS NVARCHAR(20)),
            'D365First_' + CAST(u.N AS NVARCHAR(20)),
            'D365Last_' + CAST(u.N AS NVARCHAR(20)),
            'd365_rep_' + CAST(u.N AS NVARCHAR(20)) + '@dataverse-etl.com',
            CASE (u.N % 4) WHEN 0 THEN 'Enterprise Account Manager' WHEN 1 THEN 'Solutions Consultant' WHEN 2 THEN 'Service Specialist' ELSE 'System Administrator' END,
            0,
            DATEADD(MINUTE, -(u.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(u.N % 525600), SYSUTCDATETIME())
        FROM #D365_Bulk_User u
        JOIN #D365_Bulk_BU b ON ((u.N - 1) % @D365BUCount) + 1 = b.N;

        -- Products
        INSERT INTO [Dynamics365].[Product] (
            [productid], [productnumber], [name], [description], [price], [standardcost], [currentcost], [quantityonhand], [statecode], [statuscode], [createdby], [modifiedby]
        )
        SELECT 
            p.ProductId,
            'MS-D365-ETL-' + RIGHT('000000' + CAST(p.N AS NVARCHAR(20)), 6),
            'Dataverse Enterprise Solution SKU ' + CAST(p.N AS NVARCHAR(20)),
            'High volume ETL Dataverse component SKU #' + CAST(p.N AS NVARCHAR(20)),
            CAST(150.00 + ((p.N * 23) % 4500) AS DECIMAL(18,2)),
            CAST(100.00 + ((p.N * 17) % 3000) AS DECIMAL(18,2)),
            CAST(120.00 + ((p.N * 20) % 3500) AS DECIMAL(18,2)),
            10000.00, 0, 1,
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1),
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1)
        FROM #D365_Bulk_Product p;

        -- Price Levels
        INSERT INTO [Dynamics365].[PriceLevel] (
            [pricelevelid], [name], [begindate], [enddate], [statecode], [statuscode], [createdby], [modifiedby]
        )
        SELECT 
            pl.PriceLevelId,
            'Dynamics Commercial Price List Tier ' + CAST(pl.N AS NVARCHAR(20)),
            DATEADD(YEAR, -2, CAST(SYSUTCDATETIME() AS DATE)),
            DATEADD(YEAR, 3, CAST(SYSUTCDATETIME() AS DATE)),
            0, 1,
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1),
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1)
        FROM #D365_Bulk_PriceLevel pl;

        -- Accounts
        INSERT INTO [Dynamics365].[Account] (
            [accountid], [accountnumber], [name], [telephone1], [websiteurl], [address1_line1], [address1_city],
            [address1_stateorprovince], [address1_postalcode], [address1_country], [revenue], [numberofemployees],
            [industrycode], [statecode], [statuscode], [ownerid], [owningbusinessunit], [createdby], [modifiedby],
            [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0xC1000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            'ACC-' + RIGHT('00000000' + CAST(t.N AS NVARCHAR(20)), 8),
            'Dataverse Global Corp ' + CAST(t.N AS NVARCHAR(20)),
            '+1-800-555-' + RIGHT('0000' + CAST(t.N % 10000 AS NVARCHAR(10)), 4),
            'https://www.dynamics-corp' + CAST(t.N AS NVARCHAR(20)) + '.com',
            CAST((t.N % 999) + 1 AS NVARCHAR(10)) + ' Technology Way',
            CASE (t.N % 5) WHEN 0 THEN 'Redmond' WHEN 1 THEN 'Seattle' WHEN 2 THEN 'Austin' WHEN 3 THEN 'London' ELSE 'Munich' END,
            CASE (t.N % 5) WHEN 0 THEN 'WA' WHEN 1 THEN 'WA' WHEN 2 THEN 'TX' WHEN 3 THEN 'ENG' ELSE 'BY' END,
            '98052',
            CASE (t.N % 5) WHEN 3 THEN 'United Kingdom' WHEN 4 THEN 'Germany' ELSE 'United States' END,
            CAST(500000 + ((t.N * 53) % 100000000) AS DECIMAL(18,2)),
            50 + ((t.N * 19) % 35000),
            (t.N % 10) + 1,
            CASE WHEN (t.N % 50) = 0 THEN 1 ELSE 0 END, -- 2% inactive for ETL state tracking
            CASE WHEN (t.N % 50) = 0 THEN 2 ELSE 1 END,
            u.UserId,
            b.BUId,
            u.UserId,
            u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        WHERE t.N <= @AccountCount;

        -- Contacts
        INSERT INTO [Dynamics365].[Contact] (
            [contactid], [fullname], [firstname], [lastname], [emailaddress1], [telephone1], [jobtitle],
            [parentcustomerid], [statecode], [statuscode], [ownerid], [owningbusinessunit], [createdby], [modifiedby],
            [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0xD2000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            'D365 Contact ' + CAST(t.N AS NVARCHAR(20)),
            'D365First_' + CAST(t.N AS NVARCHAR(20)),
            'D365Last_' + CAST(t.N AS NVARCHAR(20)),
            'contact' + CAST(t.N AS NVARCHAR(20)) + '@dynamics-corp' + CAST(((t.N - 1) % @AccountCount) + 1 AS NVARCHAR(20)) + '.com',
            '+1-800-555-' + RIGHT('0000' + CAST(t.N % 10000 AS NVARCHAR(10)), 4),
            CASE (t.N % 5) WHEN 0 THEN 'VP Information Technology' WHEN 1 THEN 'Director of Operations' WHEN 2 THEN 'Head of Procurement' WHEN 3 THEN 'Chief Architect' ELSE 'Senior Program Manager' END,
            CAST(CAST(0xC1000000 + (((t.N - 1) % @AccountCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            0, 1,
            u.UserId,
            b.BUId,
            u.UserId,
            u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        WHERE t.N <= @ContactCount;

        -- Leads
        INSERT INTO [Dynamics365].[Lead] (
            [leadid], [subject], [fullname], [firstname], [lastname], [companyname], [emailaddress1], [telephone1],
            [leadqualitycode], [leadsourcecode], [estimatedamount], [statecode], [statuscode],
            [ownerid], [owningbusinessunit], [createdby], [modifiedby], [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0x73000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            'Lead Opportunity Qualification #' + CAST(t.N AS NVARCHAR(20)),
            'D365 Lead ' + CAST(t.N AS NVARCHAR(20)),
            'LeadFirst_' + CAST(t.N AS NVARCHAR(20)),
            'LeadLast_' + CAST(t.N AS NVARCHAR(20)),
            'Enterprise Prospective Corp ' + CAST(t.N AS NVARCHAR(20)),
            'lead' + CAST(t.N AS NVARCHAR(20)) + '@prospectcorp' + CAST(t.N AS NVARCHAR(20)) + '.com',
            '+1-800-555-' + RIGHT('0000' + CAST(t.N % 10000 AS NVARCHAR(10)), 4),
            (t.N % 3) + 1,
            (t.N % 5) + 1,
            CAST(10000 + ((t.N * 33) % 500000) AS DECIMAL(18,2)),
            0, 1,
            u.UserId,
            b.BUId,
            u.UserId,
            u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        WHERE t.N <= @ContactCount;

        -- Opportunities
        INSERT INTO [Dynamics365].[Opportunity] (
            [opportunityid], [name], [description], [estimatedvalue], [actualvalue], [estimatedclosedate],
            [closeprobability], [parentaccountid], [pricelevelid], [statecode], [statuscode],
            [ownerid], [owningbusinessunit], [createdby], [modifiedby], [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0xE3000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            'Dynamics Enterprise Deal Package #' + CAST(t.N AS NVARCHAR(20)),
            'Dataverse digital transformation opportunity #' + CAST(t.N AS NVARCHAR(20)),
            CAST(25000 + ((t.N * 37) % 750000) AS DECIMAL(18,2)),
            CASE WHEN (t.N % 4) = 0 THEN CAST(25000 + ((t.N * 37) % 750000) AS DECIMAL(18,2)) ELSE NULL END,
            DATEADD(DAY, (t.N % 120) - 60, CAST(SYSUTCDATETIME() AS DATE)),
            30 + (t.N % 70),
            CAST(CAST(0xC1000000 + (((t.N - 1) % @AccountCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            pl.PriceLevelId,
            CASE WHEN (t.N % 4) = 0 THEN 1 ELSE 0 END,
            CASE WHEN (t.N % 4) = 0 THEN 3 ELSE 1 END,
            u.UserId,
            b.BUId,
            u.UserId,
            u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        JOIN #D365_Bulk_PriceLevel pl ON ((t.N - 1) % (CASE WHEN @ProductCount < 50 THEN @ProductCount ELSE 50 END)) + 1 = pl.N
        WHERE t.N <= @OpportunityCount;

        -- OpportunityProducts
        INSERT INTO [Dynamics365].[OpportunityProduct] (
            [opportunityproductid], [opportunityid], [productid], [priceperunit], [quantity], [manualdiscountamount], [createdby], [modifiedby], [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0xF4000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            CAST(CAST(0xE3000000 + (((t.N - 1) % @OpportunityCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            pr.ProductId,
            CAST(150.00 + ((t.N * 23) % 4500) AS DECIMAL(18,2)),
            CAST(1 + (t.N % 25) AS DECIMAL(12,2)),
            0.00,
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1),
            (SELECT TOP 1 UserId FROM #D365_Bulk_User WHERE N = 1),
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_Product pr ON ((t.N - 1) % @ProductCount) + 1 = pr.N
        WHERE t.N <= @LineItemCount;

        -- Incidents
        INSERT INTO [Dynamics365].[Incident] (
            [incidentid], [ticketnumber], [title], [description], [customerid_account], [customerid_contact],
            [prioritycode], [severitycode], [casetypecode], [statecode], [statuscode],
            [ownerid], [owningbusinessunit], [createdby], [modifiedby], [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0x15000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            'D365-ETL-CAS-' + RIGHT('00000000' + CAST(t.N AS NVARCHAR(20)), 8),
            'Customer Escalation SLA Ticket #' + CAST(t.N AS NVARCHAR(20)),
            'High volume ETL customer service incident ticket payload record #' + CAST(t.N AS NVARCHAR(20)),
            CAST(CAST(0xC1000000 + (((t.N - 1) % @AccountCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            CAST(CAST(0xD2000000 + (((t.N - 1) % @ContactCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            (t.N % 3) + 1,
            (t.N % 3) + 1,
            (t.N % 3) + 1,
            0, 1,
            u.UserId, b.BUId, u.UserId, u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        WHERE t.N <= @CaseCount;

        -- ActivityPointer
        INSERT INTO [Dynamics365].[ActivityPointer] (
            [activityid], [activitytypecode], [subject], [description], [statecode], [statuscode],
            [regardingobjectid_account], [regardingobjectid_opportunity], [ownerid], [owningbusinessunit],
            [createdby], [modifiedby], [createdon], [modifiedon]
        )
        SELECT 
            CAST(CAST(0x26000000 + t.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            CASE (t.N % 4) WHEN 0 THEN 'task' WHEN 1 THEN 'phonecall' WHEN 2 THEN 'email' ELSE 'appointment' END,
            'Activity #' + CAST(t.N AS NVARCHAR(20)) + ': Dataverse ETL Sync',
            'Synchronized ETL activity pointer payload record #' + CAST(t.N AS NVARCHAR(20)),
            0, 1,
            CAST(CAST(0xC1000000 + (((t.N - 1) % @AccountCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            CAST(CAST(0xE3000000 + (((t.N - 1) % @OpportunityCount) + 1) AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            u.UserId, b.BUId, u.UserId, u.UserId,
            DATEADD(MINUTE, -(t.N % 1051200), SYSUTCDATETIME()),
            DATEADD(MINUTE, -(t.N % 525600), SYSUTCDATETIME())
        FROM #Tally t
        JOIN #D365_Bulk_User u ON ((t.N - 1) % @UserCount) + 1 = u.N
        JOIN #D365_Bulk_BU b ON ((t.N - 1) % @D365BUCount) + 1 = b.N
        WHERE t.N <= @ActivityCount;

        DROP TABLE #D365_Bulk_BU;
        DROP TABLE #D365_Bulk_User;
        DROP TABLE #D365_Bulk_Product;
        DROP TABLE #D365_Bulk_PriceLevel;
        DROP TABLE #Tally;

        COMMIT TRANSACTION;
        PRINT 'Heavy ETL production load simulation successfully completed.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF OBJECT_ID('tempdb..#Tally') IS NOT NULL DROP TABLE #Tally;
        IF OBJECT_ID('tempdb..#D365_Bulk_BU') IS NOT NULL DROP TABLE #D365_Bulk_BU;
        IF OBJECT_ID('tempdb..#D365_Bulk_User') IS NOT NULL DROP TABLE #D365_Bulk_User;
        IF OBJECT_ID('tempdb..#D365_Bulk_Product') IS NOT NULL DROP TABLE #D365_Bulk_Product;
        IF OBJECT_ID('tempdb..#D365_Bulk_PriceLevel') IS NOT NULL DROP TABLE #D365_Bulk_PriceLevel;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
