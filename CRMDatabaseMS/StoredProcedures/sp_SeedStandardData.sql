CREATE PROCEDURE [dbo].[sp_SeedStandardData]
    @CleanExisting BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @CleanExisting = 1
    BEGIN
        EXEC [dbo].[sp_CleanupAllCRMData];
    END

    PRINT 'Seeding standard CRM data (50 records per entity with sane defaults)...';

    BEGIN TRANSACTION;
    BEGIN TRY
        -------------------------------------------------------------------------
        -- Tally table generation for 50 records (1 to 50)
        -------------------------------------------------------------------------
        ;WITH
            Digits(N) AS (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9),
            Numbers AS (
                SELECT TOP (50) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS N
                FROM Digits a CROSS JOIN Digits b
            )
        SELECT N INTO #N FROM Numbers;

        -------------------------------------------------------------------------
        -- 1. SALESFORCE SCHEMA SEEDING (50 records each)
        -------------------------------------------------------------------------
        PRINT '  -> Seeding Salesforce schema...';

        -- 1.1 Users (18-char ID: '005000000000001AAA' to '005000000000050AAA')
        INSERT INTO [Salesforce].[User] ([Id], [Username], [LastName], [FirstName], [Email], [IsActive], [Title], [Department], [Phone])
        SELECT
            '005000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'user' + CAST(N AS NVARCHAR(10)) + '@example-crm.com',
            CASE (N % 5)
                WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams'
                WHEN 3 THEN 'Brown' ELSE 'Davis'
            END + CAST(N AS NVARCHAR(10)),
            CASE (N % 4)
                WHEN 0 THEN 'Alex' WHEN 1 THEN 'Jordan' WHEN 2 THEN 'Taylor' ELSE 'Morgan'
            END,
            'user' + CAST(N AS NVARCHAR(10)) + '@example-crm.com',
            1,
            CASE (N % 5)
                WHEN 0 THEN 'VP Sales' WHEN 1 THEN 'Enterprise Account Executive'
                WHEN 2 THEN 'Sales Development Rep' WHEN 3 THEN 'Customer Success Manager'
                ELSE 'Solutions Architect'
            END,
            CASE (N % 3) WHEN 0 THEN 'Sales' WHEN 1 THEN 'Customer Support' ELSE 'Executive' END,
            '+1-555-' + RIGHT('0000' + CAST(1000 + N AS NVARCHAR(10)), 4)
        FROM #N;

        -- 1.2 Accounts ('001000000000001AAA'..'001000000000050AAA')
        INSERT INTO [Salesforce].[Account] (
            [Id], [ParentId], [Name], [Type], [BillingStreet], [BillingCity], [BillingState], [BillingPostalCode],
            [BillingCountry], [ShippingStreet], [ShippingCity], [ShippingState], [ShippingPostalCode], [ShippingCountry],
            [Phone], [Website], [Industry], [AnnualRevenue], [NumberOfEmployees], [Description], [OwnerId],
            [CreatedById], [LastModifiedById]
        )
        SELECT
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE WHEN N > 10 AND N % 4 = 0 THEN '001000000000' + RIGHT('000' + CAST((N % 10) + 1 AS NVARCHAR(10)), 3) + 'AAA' ELSE NULL END,
            CASE (N % 10)
                WHEN 0 THEN 'Acme Enterprise ' WHEN 1 THEN 'Global Dynamics ' WHEN 2 THEN 'Apex Technologies '
                WHEN 3 THEN 'Nexus Logistics ' WHEN 4 THEN 'Summit Health ' WHEN 5 THEN 'Vanguard Capital '
                WHEN 6 THEN 'Starlight Energy ' WHEN 7 THEN 'Horizon Media ' WHEN 8 THEN 'Omni Retail '
                ELSE 'BlueWave Biotech '
            END + CAST(N AS NVARCHAR(10)),
            CASE (N % 3) WHEN 0 THEN 'Customer - Direct' WHEN 1 THEN 'Customer - Channel' ELSE 'Prospect' END,
            CAST(100 + N AS NVARCHAR(10)) + ' Market Street',
            CASE (N % 5) WHEN 0 THEN 'San Francisco' WHEN 1 THEN 'New York' WHEN 2 THEN 'Austin' WHEN 3 THEN 'Chicago' ELSE 'Seattle' END,
            CASE (N % 5) WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'IL' ELSE 'WA' END,
            RIGHT('00000' + CAST(94000 + N AS NVARCHAR(10)), 5),
            'USA',
            CAST(100 + N AS NVARCHAR(10)) + ' Market Street',
            CASE (N % 5) WHEN 0 THEN 'San Francisco' WHEN 1 THEN 'New York' WHEN 2 THEN 'Austin' WHEN 3 THEN 'Chicago' ELSE 'Seattle' END,
            CASE (N % 5) WHEN 0 THEN 'CA' WHEN 1 THEN 'NY' WHEN 2 THEN 'TX' WHEN 3 THEN 'IL' ELSE 'WA' END,
            RIGHT('00000' + CAST(94000 + N AS NVARCHAR(10)), 5),
            'USA',
            '+1-415-555-' + RIGHT('0000' + CAST(2000 + N AS NVARCHAR(10)), 4),
            'https://www.account' + CAST(N AS NVARCHAR(10)) + '.example.com',
            CASE (N % 5) WHEN 0 THEN 'Technology' WHEN 1 THEN 'Finance' WHEN 2 THEN 'Healthcare' WHEN 3 THEN 'Manufacturing' ELSE 'Retail' END,
            500000.00 + (N * 250000.00),
            50 + (N * 25),
            'Standard seed enterprise account record #' + CAST(N AS NVARCHAR(10)),
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA'
        FROM #N;

        -- 1.3 Contacts ('003000000000001AAA'..'003000000000050AAA')
        INSERT INTO [Salesforce].[Contact] (
            [Id], [AccountId], [LastName], [FirstName], [Salutation], [Title], [Department], [Email],
            [Phone], [MobilePhone], [LeadSource], [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'ContactLast' + CAST(N AS NVARCHAR(10)),
            'ContactFirst' + CAST(N AS NVARCHAR(10)),
            CASE (N % 3) WHEN 0 THEN 'Mr.' WHEN 1 THEN 'Ms.' ELSE 'Dr.' END,
            CASE (N % 5) WHEN 0 THEN 'Chief Executive Officer' WHEN 1 THEN 'VP of Operations' WHEN 2 THEN 'Head of Procurement' WHEN 3 THEN 'Director of IT' ELSE 'Senior Product Manager' END,
            CASE (N % 4) WHEN 0 THEN 'Executive' WHEN 1 THEN 'Operations' WHEN 2 THEN 'Procurement' ELSE 'IT' END,
            'contact' + CAST(N AS NVARCHAR(10)) + '@account' + CAST(N AS NVARCHAR(10)) + '.example.com',
            '+1-555-' + RIGHT('0000' + CAST(3000 + N AS NVARCHAR(10)), 4),
            '+1-555-' + RIGHT('0000' + CAST(7000 + N AS NVARCHAR(10)), 4),
            CASE (N % 4) WHEN 0 THEN 'Web' WHEN 1 THEN 'Trade Show' WHEN 2 THEN 'Partner Referral' ELSE 'Inbound Call' END,
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA'
        FROM #N;

        -- 1.4 AccountContactRelation ('07k000000000001AAA'..'07k000000000050AAA')
        INSERT INTO [Salesforce].[AccountContactRelation] (
            [Id], [AccountId], [ContactId], [Roles], [IsDirect], [IsActive]
        )
        SELECT
            '07k000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 4) WHEN 0 THEN 'Decision Maker' WHEN 1 THEN 'Economic Buyer' WHEN 2 THEN 'Influencer' ELSE 'Technical Buyer' END,
            1, 1
        FROM #N;

        -- 1.5 Leads ('00Q000000000001AAA'..'00Q000000000050AAA')
        INSERT INTO [Salesforce].[Lead] (
            [Id], [LastName], [FirstName], [Company], [Title], [Email], [Phone], [LeadSource],
            [Status], [Industry], [AnnualRevenue], [NumberOfEmployees], [IsConverted], [OwnerId],
            [CreatedById], [LastModifiedById]
        )
        SELECT
            '00Q000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'LeadLast' + CAST(N AS NVARCHAR(10)),
            'LeadFirst' + CAST(N AS NVARCHAR(10)),
            'Prospect Corp ' + CAST(N AS NVARCHAR(10)),
            'Director of Business Strategy',
            'lead' + CAST(N AS NVARCHAR(10)) + '@prospect' + CAST(N AS NVARCHAR(10)) + '.example.com',
            '+1-555-' + RIGHT('0000' + CAST(4000 + N AS NVARCHAR(10)), 4),
            CASE (N % 4) WHEN 0 THEN 'Webinar' WHEN 1 THEN 'Advertisement' WHEN 2 THEN 'Cold Call' ELSE 'Employee Referral' END,
            CASE (N % 4) WHEN 0 THEN 'Open - Not Contacted' WHEN 1 THEN 'Working - Contacted' WHEN 2 THEN 'Closed - Converted' ELSE 'Closed - Not Converted' END,
            CASE (N % 4) WHEN 0 THEN 'Technology' WHEN 1 THEN 'Healthcare' WHEN 2 THEN 'Financial Services' ELSE 'Manufacturing' END,
            250000.00 + (N * 50000.00),
            20 + N,
            0,
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.6 Campaigns ('701000000000001AAA'..'701000000000050AAA')
        INSERT INTO [Salesforce].[Campaign] (
            [Id], [Name], [Type], [Status], [StartDate], [EndDate], [ExpectedRevenue], [BudgetedCost],
            [ActualCost], [IsActive], [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '701000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 5)
                WHEN 0 THEN 'Q1 Global Cloud Summit ' WHEN 1 THEN 'Enterprise Modernization Webinar '
                WHEN 2 THEN 'Dreamforce Partner Showcase ' WHEN 3 THEN 'Mid-Market Nurture Campaign '
                ELSE 'AI Innovation Roadshow '
            END + CAST(N AS NVARCHAR(10)),
            CASE (N % 4) WHEN 0 THEN 'Conference' WHEN 1 THEN 'Webinar' WHEN 2 THEN 'Email' ELSE 'Direct Mail' END,
            CASE (N % 3) WHEN 0 THEN 'In Progress' WHEN 1 THEN 'Completed' ELSE 'Planned' END,
            DATEADD(DAY, -30 + N, CAST(SYSUTCDATETIME() AS DATE)),
            DATEADD(DAY, 60 + N, CAST(SYSUTCDATETIME() AS DATE)),
            100000.00 + (N * 20000.00),
            25000.00 + (N * 5000.00),
            22000.00 + (N * 4800.00),
            1,
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.7 CampaignMembers ('00v000000000001AAA'..'00v000000000050AAA')
        INSERT INTO [Salesforce].[CampaignMember] (
            [Id], [CampaignId], [ContactId], [Status], [HasResponded], [CreatedById], [LastModifiedById]
        )
        SELECT
            '00v000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '701000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 3) WHEN 0 THEN 'Responded' WHEN 1 THEN 'Sent' ELSE 'Attended' END,
            CASE WHEN (N % 3) = 1 THEN 0 ELSE 1 END,
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.8 Opportunities ('006000000000001AAA'..'006000000000050AAA')
        INSERT INTO [Salesforce].[Opportunity] (
            [Id], [AccountId], [Name], [StageName], [Amount], [Probability],
            [CloseDate], [Type], [LeadSource], [IsClosed], [IsWon], [ForecastCategoryName], [CampaignId],
            [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '006000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'Deal - ' + CAST(N AS NVARCHAR(10)) + ' Cloud Transformation',
            CASE (N % 6)
                WHEN 0 THEN 'Prospecting' WHEN 1 THEN 'Qualification' WHEN 2 THEN 'Needs Analysis'
                WHEN 3 THEN 'Proposal/Price Quote' WHEN 4 THEN 'Closed Won' ELSE 'Closed Lost'
            END,
            50000.00 + (N * 15000.00),
            CASE (N % 6)
                WHEN 0 THEN 10.00 WHEN 1 THEN 25.00 WHEN 2 THEN 50.00
                WHEN 3 THEN 75.00 WHEN 4 THEN 100.00 ELSE 0.00
            END,
            DATEADD(DAY, (N * 3), CAST(SYSUTCDATETIME() AS DATE)),
            CASE (N % 3) WHEN 0 THEN 'New Customer' WHEN 1 THEN 'Existing Customer - Upgrade' ELSE 'Existing Customer - Replacement' END,
            CASE (N % 4) WHEN 0 THEN 'Partner' WHEN 1 THEN 'Web' WHEN 2 THEN 'Trade Show' ELSE 'Inbound' END,
            CASE WHEN (N % 6) IN (4, 5) THEN 1 ELSE 0 END,
            CASE WHEN (N % 6) = 4 THEN 1 ELSE 0 END,
            CASE (N % 6) WHEN 0 THEN 'Pipeline' WHEN 1 THEN 'Pipeline' WHEN 2 THEN 'BestCase' WHEN 3 THEN 'Commit' WHEN 4 THEN 'Closed' ELSE 'Omitted' END,
            '701000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.9 Product2 ('01t000000000001AAA'..'01t000000000050AAA')
        INSERT INTO [Salesforce].[Product2] (
            [Id], [Name], [ProductCode], [Description], [IsActive], [Family], [CreatedById], [LastModifiedById]
        )
        SELECT
            '01t000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 5)
                WHEN 0 THEN 'Sales Cloud Enterprise License Tier '
                WHEN 1 THEN 'Service Cloud Unlimited Support Plan '
                WHEN 2 THEN 'Marketing Automation Pro Suite '
                WHEN 3 THEN 'Einstein AI Analytics Connector '
                ELSE 'Enterprise API Integration Gateway '
            END + CAST(N AS NVARCHAR(10)),
            'SKU-SF-' + RIGHT('0000' + CAST(100 + N AS NVARCHAR(10)), 4),
            'High reliability CRM enterprise solution component #' + CAST(N AS NVARCHAR(10)),
            1,
            CASE (N % 4) WHEN 0 THEN 'Software' WHEN 1 THEN 'Support' WHEN 2 THEN 'Analytics' ELSE 'Integration' END,
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.10 Pricebook2 ('01s000000000001AAA'..'01s000000000050AAA')
        INSERT INTO [Salesforce].[Pricebook2] (
            [Id], [Name], [Description], [IsActive], [IsStandard], [CreatedById], [LastModifiedById]
        )
        SELECT
            '01s000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE WHEN N = 1 THEN 'Standard Price Book' ELSE 'Commercial Price Book Tier ' + CAST(N AS NVARCHAR(10)) END,
            'Salesforce price catalog tier #' + CAST(N AS NVARCHAR(10)),
            1,
            CASE WHEN N = 1 THEN 1 ELSE 0 END,
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.11 PricebookEntry ('01u000000000001AAA'..'01u000000000050AAA')
        INSERT INTO [Salesforce].[PricebookEntry] (
            [Id], [Pricebook2Id], [Product2Id], [UnitPrice], [IsActive], [UseStandardPrice], [CreatedById], [LastModifiedById]
        )
        SELECT
            '01u000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '01s000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '01t000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            250.00 + (N * 50.00),
            1,
            0,
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.12 OpportunityLineItem ('00k000000000001AAA'..'00k000000000050AAA')
        INSERT INTO [Salesforce].[OpportunityLineItem] (
            [Id], [OpportunityId], [PricebookEntryId], [Quantity], [UnitPrice], [Description], [CreatedById], [LastModifiedById]
        )
        SELECT
            '00k000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '006000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '01u000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            5.00 + (N % 10),
            250.00 + (N * 50.00),
            'Product line subscription #' + CAST(N AS NVARCHAR(10)),
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.13 Case ('500000000000001AAA'..'500000000000050AAA')
        INSERT INTO [Salesforce].[Case] (
            [Id], [CaseNumber], [ContactId], [AccountId], [Type], [Status], [Reason], [Origin], [Subject], [Priority], [Description], [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '500000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'SF-CASE-' + RIGHT('00000' + CAST(1000 + N AS NVARCHAR(10)), 5),
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 4) WHEN 0 THEN 'Problem' WHEN 1 THEN 'Feature Request' WHEN 2 THEN 'Question' ELSE 'Configuration' END,
            CASE (N % 3) WHEN 0 THEN 'New' WHEN 1 THEN 'Working' ELSE 'Closed' END,
            CASE (N % 3) WHEN 0 THEN 'Installation' WHEN 1 THEN 'Performance' ELSE 'User Training' END,
            CASE (N % 3) WHEN 0 THEN 'Web' WHEN 1 THEN 'Email' ELSE 'Phone' END,
            'Support Ticket #' + CAST(N AS NVARCHAR(10)) + ': Configuration Assistance',
            CASE (N % 3) WHEN 0 THEN 'High' WHEN 1 THEN 'Medium' ELSE 'Low' END,
            'Customer requested technical walkthrough for integration module #' + CAST(N AS NVARCHAR(10)),
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.14 Task ('00T000000000001AAA'..'00T000000000050AAA')
        INSERT INTO [Salesforce].[Task] (
            [Id], [WhoId], [WhatId], [Subject], [ActivityDate], [Status], [Priority], [IsHighPriority], [Description], [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '00T000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '006000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            CASE (N % 4) WHEN 0 THEN 'Follow-up Call' WHEN 1 THEN 'Send Contract Proposal' WHEN 2 THEN 'Schedule Architecture Review' ELSE 'Quarterly Check-in' END,
            DATEADD(DAY, N % 14, CAST(SYSUTCDATETIME() AS DATE)),
            CASE (N % 3) WHEN 0 THEN 'Not Started' WHEN 1 THEN 'In Progress' ELSE 'Completed' END,
            CASE (N % 3) WHEN 0 THEN 'High' WHEN 1 THEN 'Normal' ELSE 'Low' END,
            CASE WHEN (N % 3) = 0 THEN 1 ELSE 0 END,
            'Follow up regarding contract terms for record #' + CAST(N AS NVARCHAR(10)),
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -- 1.15 Event ('00U000000000001AAA'..'00U000000000050AAA')
        INSERT INTO [Salesforce].[Event] (
            [Id], [WhoId], [WhatId], [Subject], [Location], [IsAllDayEvent], [ActivityDateTime], [ActivityDate], [DurationInMinutes], [StartDateTime], [EndDateTime], [Description], [OwnerId], [CreatedById], [LastModifiedById]
        )
        SELECT
            '00U000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '003000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            '001000000000' + RIGHT('000' + CAST(N AS NVARCHAR(10)), 3) + 'AAA',
            'Executive Briefing #' + CAST(N AS NVARCHAR(10)),
            'Virtual Zoom Room ' + CAST(N AS NVARCHAR(10)),
            0,
            DATEADD(HOUR, N, SYSUTCDATETIME()),
            CAST(DATEADD(HOUR, N, SYSUTCDATETIME()) AS DATE),
            60,
            DATEADD(HOUR, N, SYSUTCDATETIME()),
            DATEADD(MINUTE, 60, DATEADD(HOUR, N, SYSUTCDATETIME())),
            'Technical overview and platform demonstration #' + CAST(N AS NVARCHAR(10)),
            '005000000000' + RIGHT('000' + CAST(((N - 1) % 50) + 1 AS NVARCHAR(10)), 3) + 'AAA',
            '005000000000001AAA', '005000000000001AAA'
        FROM #N;

        -------------------------------------------------------------------------
        -- 2. HUBSPOT SCHEMA SEEDING (50 records each)
        -------------------------------------------------------------------------
        PRINT '  -> Seeding HubSpot schema...';

        -- 2.1 Owners (ownerId: 1001..1050)
        INSERT INTO [HubSpot].[Owner] ([ownerId], [email], [firstName], [lastName], [userId])
        SELECT
            1000 + N,
            'hs_owner' + CAST(N AS NVARCHAR(10)) + '@example-crm.com',
            CASE (N % 4) WHEN 0 THEN 'Sam' WHEN 1 THEN 'Chris' WHEN 2 THEN 'Pat' ELSE 'Robin' END,
            'HubSpotRep' + CAST(N AS NVARCHAR(10)),
            20000 + N
        FROM #N;

        -- 2.2 Companies (companyId: 2001..2050)
        INSERT INTO [HubSpot].[Company] (
            [companyId], [name], [domain], [industry], [phone], [city], [state], [country],
            [annualRevenue], [numberOfEmployees], [lifecyclestage], [ownerId]
        )
        SELECT
            2000 + N,
            'Inbound Growth Corp ' + CAST(N AS NVARCHAR(10)),
            'growth' + CAST(N AS NVARCHAR(10)) + '.example.io',
            CASE (N % 5) WHEN 0 THEN 'INFORMATION_TECHNOLOGY_AND_SERVICES' WHEN 1 THEN 'FINANCIAL_SERVICES' WHEN 2 THEN 'MARKETING_AND_ADVERTISING' WHEN 3 THEN 'HOSPITAL_AND_HEALTH_CARE' ELSE 'LOGISTICS' END,
            '+1-617-555-' + RIGHT('0000' + CAST(1000 + N AS NVARCHAR(10)), 4),
            CASE (N % 4) WHEN 0 THEN 'Boston' WHEN 1 THEN 'Cambridge' WHEN 2 THEN 'Austin' ELSE 'San Francisco' END,
            CASE (N % 4) WHEN 0 THEN 'MA' WHEN 1 THEN 'MA' WHEN 2 THEN 'TX' ELSE 'CA' END,
            'United States',
            750000.00 + (N * 180000.00),
            40 + (N * 15),
            CASE (N % 4) WHEN 0 THEN 'lead' WHEN 1 THEN 'marketingqualifiedlead' WHEN 2 THEN 'salesqualifiedlead' ELSE 'customer' END,
            1000 + ((N - 1) % 50) + 1
        FROM #N;

        -- 2.3 Contacts (contactId: 3001..3050)
        INSERT INTO [HubSpot].[Contact] (
            [contactId], [email], [firstName], [lastName], [phone], [jobTitle], [lifecyclestage],
            [leadStatus], [associatedCompanyId], [ownerId]
        )
        SELECT
            3000 + N,
            'hs_contact' + CAST(N AS NVARCHAR(10)) + '@growth' + CAST(N AS NVARCHAR(10)) + '.example.io',
            'HubContactFirst' + CAST(N AS NVARCHAR(10)),
            'HubContactLast' + CAST(N AS NVARCHAR(10)),
            '+1-617-555-' + RIGHT('0000' + CAST(2000 + N AS NVARCHAR(10)), 4),
            CASE (N % 4) WHEN 0 THEN 'VP Marketing' WHEN 1 THEN 'Chief Revenue Officer' WHEN 2 THEN 'Director of Demand Gen' ELSE 'Sales Manager' END,
            CASE (N % 4) WHEN 0 THEN 'lead' WHEN 1 THEN 'marketingqualifiedlead' WHEN 2 THEN 'salesqualifiedlead' ELSE 'customer' END,
            CASE (N % 4) WHEN 0 THEN 'NEW' WHEN 1 THEN 'OPEN' WHEN 2 THEN 'IN_PROGRESS' ELSE 'CONNECTED' END,
            2000 + N,
            1000 + ((N - 1) % 50) + 1
        FROM #N;

        -- 2.4 Pipelines (pipelineId: 4001..4050)
        INSERT INTO [HubSpot].[Pipeline] ([pipelineId], [label], [displayOrder], [objectType])
        SELECT
            'pipe_' + CAST(4000 + N AS NVARCHAR(10)),
            CASE (N % 4) WHEN 0 THEN 'Direct Sales Pipeline ' WHEN 1 THEN 'Enterprise Solution Funnel ' WHEN 2 THEN 'Channel Partner Pipeline ' ELSE 'Renewals & Upgrades ' END + CAST(N AS NVARCHAR(10)),
            N,
            'deals'
        FROM #N;

        -- 2.5 DealStages (stageId: 5001..5050)
        INSERT INTO [HubSpot].[DealStage] ([stageId], [pipelineId], [label], [displayOrder], [probability], [closedWon])
        SELECT
            'stage_' + CAST(5000 + N AS NVARCHAR(10)),
            'pipe_' + CAST(4000 + N AS NVARCHAR(10)),
            CASE (N % 5)
                WHEN 0 THEN 'Appointment Scheduled'
                WHEN 1 THEN 'Qualified To Buy'
                WHEN 2 THEN 'Decision Maker Bought-In'
                WHEN 3 THEN 'Contract Sent'
                ELSE 'Closed Won'
            END,
            (N % 5) + 1,
            CASE (N % 5) WHEN 0 THEN 0.20 WHEN 1 THEN 0.40 WHEN 2 THEN 0.60 WHEN 3 THEN 0.80 ELSE 1.00 END,
            CASE WHEN (N % 5) = 4 THEN 1 ELSE 0 END
        FROM #N;

        -- 2.6 Deals (dealId: 6001..6050)
        INSERT INTO [HubSpot].[Deal] ([dealId], [dealName], [amount], [pipelineId], [dealStageId], [closedate], [dealType], [ownerId])
        SELECT
            6000 + N,
            'Deal Package ' + CAST(N AS NVARCHAR(10)),
            45000.00 + (N * 12000.00),
            'pipe_' + CAST(4000 + N AS NVARCHAR(10)),
            'stage_' + CAST(5000 + N AS NVARCHAR(10)),
            DATEADD(DAY, N * 2, SYSUTCDATETIME()),
            CASE (N % 2) WHEN 0 THEN 'newbusiness' ELSE 'existingbusiness' END,
            1000 + ((N - 1) % 50) + 1
        FROM #N;

        -- 2.7 Tickets (ticketId: 7001..7050)
        INSERT INTO [HubSpot].[Ticket] ([ticketId], [subject], [content], [pipelineId], [ticketStatusStageId], [priority], [ownerId])
        SELECT
            7000 + N,
            'HubSpot Inbound Issue #' + CAST(N AS NVARCHAR(10)),
            'Inquiry regarding campaign tracking script installation #' + CAST(N AS NVARCHAR(10)),
            'pipe_' + CAST(4000 + N AS NVARCHAR(10)),
            'stage_' + CAST(5000 + N AS NVARCHAR(10)),
            CASE (N % 4) WHEN 0 THEN 'LOW' WHEN 1 THEN 'MEDIUM' WHEN 2 THEN 'HIGH' ELSE 'URGENT' END,
            1000 + ((N - 1) % 50) + 1
        FROM #N;

        -- 2.8 Products (productId: 8001..8050)
        INSERT INTO [HubSpot].[Product] ([productId], [name], [description], [price], [cost], [recurringBillingFrequency])
        SELECT
            8000 + N,
            'HubSpot Add-on Module ' + CAST(N AS NVARCHAR(10)),
            'Automated workflow & attribution reporting tier #' + CAST(N AS NVARCHAR(10)),
            1200.00 + (N * 150.00),
            300.00 + (N * 30.00),
            CASE (N % 3) WHEN 0 THEN 'monthly' WHEN 1 THEN 'annually' ELSE 'quarterly' END
        FROM #N;

        -- 2.9 LineItems (lineItemId: 9001..9050)
        INSERT INTO [HubSpot].[LineItem] ([lineItemId], [dealId], [productId], [name], [quantity], [price], [discount])
        SELECT
            9000 + N,
            6000 + N,
            8000 + N,
            'HubSpot Add-on Module ' + CAST(N AS NVARCHAR(10)),
            2.00 + (N % 5),
            1200.00 + (N * 150.00),
            CASE WHEN (N % 4) = 0 THEN 100.00 ELSE 0.00 END
        FROM #N;

        -- 2.10 Engagements (engagementId: 10001..10050)
        INSERT INTO [HubSpot].[Engagement] ([engagementId], [engagementType], [timestamp], [ownerId], [body], [status])
        SELECT
            10000 + N,
            CASE (N % 5) WHEN 0 THEN 'EMAIL' WHEN 1 THEN 'CALL' WHEN 2 THEN 'MEETING' WHEN 3 THEN 'NOTE' ELSE 'TASK' END,
            DATEADD(HOUR, -N * 6, SYSUTCDATETIME()),
            1000 + ((N - 1) % 50) + 1,
            'Recorded customer engagement activity #' + CAST(N AS NVARCHAR(10)) + ' with client notes.',
            'COMPLETED'
        FROM #N;

        -- 2.11 ObjectAssociations (auto-incrementing IDENTITY)
        INSERT INTO [HubSpot].[ObjectAssociation] ([fromObjectType], [fromObjectId], [toObjectType], [toObjectId], [associationTypeId])
        SELECT
            'contact',
            3000 + N,
            'company',
            2000 + N,
            1 -- Standard Contact-to-Company association type ID
        FROM #N;

        -------------------------------------------------------------------------
        -- 3. DYNAMICS 365 SCHEMA SEEDING (50 records each)
        -------------------------------------------------------------------------
        PRINT '  -> Seeding Dynamics 365 schema...';

        -- Generate deterministic GUID tables for relational links
        CREATE TABLE #D365_BU (N INT PRIMARY KEY, BUId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_User (N INT PRIMARY KEY, UserId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Account (N INT PRIMARY KEY, AccountId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Contact (N INT PRIMARY KEY, ContactId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Lead (N INT PRIMARY KEY, LeadId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_PriceLevel (N INT PRIMARY KEY, PriceLevelId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Product (N INT PRIMARY KEY, ProductId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Opportunity (N INT PRIMARY KEY, OppId UNIQUEIDENTIFIER);
        CREATE TABLE #D365_Incident (N INT PRIMARY KEY, IncidentId UNIQUEIDENTIFIER);

        INSERT INTO #D365_BU SELECT N, CAST(CAST(0xA1000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_User SELECT N, CAST(CAST(0xB2000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Account SELECT N, CAST(CAST(0xC3000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Contact SELECT N, CAST(CAST(0xD4000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Lead SELECT N, CAST(CAST(0xE5000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_PriceLevel SELECT N, CAST(CAST(0xF6000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Product SELECT N, CAST(CAST(0x17000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Opportunity SELECT N, CAST(CAST(0x28000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;
        INSERT INTO #D365_Incident SELECT N, CAST(CAST(0x39000000 + N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER) FROM #N;

        -- 3.1 BusinessUnit
        INSERT INTO [Dynamics365].[BusinessUnit] ([businessunitid], [name], [parentbusinessunitid], [isdisabled])
        SELECT
            b.BUId,
            CASE (n.N % 5)
                WHEN 0 THEN 'Corporate Headquarters '
                WHEN 1 THEN 'North America Sales BU '
                WHEN 2 THEN 'EMEA Regional Operations '
                WHEN 3 THEN 'APAC Commercial Division '
                ELSE 'Global Services Unit '
            END + CAST(n.N AS NVARCHAR(10)),
            CASE WHEN n.N > 1 THEN (SELECT TOP 1 BUId FROM #D365_BU WHERE N = 1) ELSE NULL END,
            0
        FROM #N n JOIN #D365_BU b ON n.N = b.N;

        -- 3.2 SystemUser
        INSERT INTO [Dynamics365].[SystemUser] ([systemuserid], [businessunitid], [domainname], [fullname], [firstname], [lastname], [internalemailaddress], [jobtitle], [isdisabled])
        SELECT
            u.UserId,
            b.BUId,
            'CORP\\d365user' + CAST(n.N AS NVARCHAR(10)),
            'Dynamics User ' + CAST(n.N AS NVARCHAR(10)),
            'Dynamics' + CAST(n.N AS NVARCHAR(10)),
            'User' + CAST(n.N AS NVARCHAR(10)),
            'd365user' + CAST(n.N AS NVARCHAR(10)) + '@dynamics-org.com',
            CASE (n.N % 4) WHEN 0 THEN 'Senior CRM Specialist' WHEN 1 THEN 'Enterprise Account Manager' WHEN 2 THEN 'Service Lead' ELSE 'Solutions Architect' END,
            0
        FROM #N n
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.3 Account
        INSERT INTO [Dynamics365].[Account] (
            [accountid], [accountnumber], [name], [telephone1], [websiteurl], [address1_line1], [address1_city],
            [address1_stateorprovince], [address1_postalcode], [address1_country], [revenue], [numberofemployees],
            [industrycode], [statecode], [statuscode], [ownerid], [owningbusinessunit], [createdby], [modifiedby]
        )
        SELECT
            a.AccountId,
            'D365-ACC-' + RIGHT('00000' + CAST(1000 + n.N AS NVARCHAR(10)), 5),
            'Dataverse Enterprise ' + CAST(n.N AS NVARCHAR(10)),
            '+1-800-555-' + RIGHT('0000' + CAST(1000 + n.N AS NVARCHAR(10)), 4),
            'https://www.dynamicsclient' + CAST(n.N AS NVARCHAR(10)) + '.com',
            CAST(500 + n.N AS NVARCHAR(10)) + ' Technology Way',
            CASE (n.N % 4) WHEN 0 THEN 'Redmond' WHEN 1 THEN 'Bellevue' WHEN 2 THEN 'Chicago' ELSE 'Atlanta' END,
            CASE (n.N % 4) WHEN 0 THEN 'WA' WHEN 1 THEN 'WA' WHEN 2 THEN 'IL' ELSE 'GA' END,
            '98052',
            'USA',
            1200000.00 + (n.N * 350000.00),
            120 + (n.N * 30),
            (n.N % 10) + 1,
            0, -- Active
            1, -- Active Status
            u.UserId,
            b.BUId,
            u.UserId,
            u.UserId
        FROM #N n
        JOIN #D365_Account a ON n.N = a.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.4 Contact
        INSERT INTO [Dynamics365].[Contact] (
            [contactid], [fullname], [firstname], [lastname], [emailaddress1], [telephone1], [jobtitle],
            [parentcustomerid], [statecode], [statuscode], [ownerid], [owningbusinessunit], [createdby], [modifiedby]
        )
        SELECT
            c.ContactId,
            'Dynamics Contact ' + CAST(n.N AS NVARCHAR(10)),
            'D365First' + CAST(n.N AS NVARCHAR(10)),
            'D365Last' + CAST(n.N AS NVARCHAR(10)),
            'd365contact' + CAST(n.N AS NVARCHAR(10)) + '@dynamicsclient' + CAST(n.N AS NVARCHAR(10)) + '.com',
            '+1-800-555-' + RIGHT('0000' + CAST(2000 + n.N AS NVARCHAR(10)), 4),
            CASE (n.N % 4) WHEN 0 THEN 'Director of Operations' WHEN 1 THEN 'IT Director' WHEN 2 THEN 'Procurement Officer' ELSE 'VP Technology' END,
            a.AccountId,
            0, 1,
            u.UserId, b.BUId, u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Contact c ON n.N = c.N
        JOIN #D365_Account a ON n.N = a.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.5 Lead
        INSERT INTO [Dynamics365].[Lead] (
            [leadid], [subject], [fullname], [firstname], [lastname], [companyname], [emailaddress1], [telephone1],
            [leadqualitycode], [leadsourcecode], [estimatedamount], [statecode], [statuscode],
            [ownerid], [owningbusinessunit], [createdby], [modifiedby]
        )
        SELECT
            l.LeadId,
            'Prospective Lead Qualification #' + CAST(n.N AS NVARCHAR(10)),
            'D365 Lead ' + CAST(n.N AS NVARCHAR(10)),
            'LeadFirst' + CAST(n.N AS NVARCHAR(10)),
            'LeadLast' + CAST(n.N AS NVARCHAR(10)),
            'Prospective Corp ' + CAST(n.N AS NVARCHAR(10)),
            'd365lead' + CAST(n.N AS NVARCHAR(10)) + '@prospect' + CAST(n.N AS NVARCHAR(10)) + '.com',
            '+1-800-555-' + RIGHT('0000' + CAST(3000 + n.N AS NVARCHAR(10)), 4),
            (n.N % 3) + 1, -- 1=Hot, 2=Warm, 3=Cold
            (n.N % 5) + 1,
            150000.00 + (n.N * 25000.00),
            0, 1,
            u.UserId, b.BUId, u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Lead l ON n.N = l.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.6 PriceLevel
        INSERT INTO [Dynamics365].[PriceLevel] (
            [pricelevelid], [name], [begindate], [enddate], [statecode], [statuscode],
            [createdby], [modifiedby]
        )
        SELECT
            p.PriceLevelId,
            CASE (n.N % 4) WHEN 0 THEN 'Default Commercial Price List ' WHEN 1 THEN 'Enterprise Volume Tier ' WHEN 2 THEN 'Public Sector & Edu ' ELSE 'Strategic Partner Tier ' END + CAST(n.N AS NVARCHAR(10)),
            DATEADD(YEAR, -1, CAST(SYSUTCDATETIME() AS DATE)),
            DATEADD(YEAR, 2, CAST(SYSUTCDATETIME() AS DATE)),
            0, 1,
            u.UserId, u.UserId
        FROM #N n
        JOIN #D365_PriceLevel p ON n.N = p.N
        JOIN #D365_User u ON n.N = u.N;

        -- 3.7 Product
        INSERT INTO [Dynamics365].[Product] (
            [productid], [productnumber], [name], [description], [price], [standardcost], [currentcost],
            [quantityonhand], [statecode], [statuscode], [createdby], [modifiedby]
        )
        SELECT
            pr.ProductId,
            'MS-D365-SKU-' + RIGHT('0000' + CAST(n.N AS NVARCHAR(10)), 4),
            CASE (n.N % 4) WHEN 0 THEN 'Dynamics 365 Sales Enterprise SKU ' WHEN 1 THEN 'Dataverse Storage Capacity Add-on ' WHEN 2 THEN 'Power Automate Enterprise Processor ' ELSE 'Dynamics Customer Insights Platform ' END + CAST(n.N AS NVARCHAR(10)),
            'Dataverse & Dynamics 365 solution component #' + CAST(n.N AS NVARCHAR(10)),
            150.00 + (n.N * 30.00),
            100.00 + (n.N * 20.00),
            120.00 + (n.N * 25.00),
            1000.00,
            0, 1,
            u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Product pr ON n.N = pr.N
        JOIN #D365_User u ON n.N = u.N;

        -- 3.8 Opportunity
        INSERT INTO [Dynamics365].[Opportunity] (
            [opportunityid], [name], [description], [estimatedvalue], [actualvalue], [estimatedclosedate],
            [closeprobability], [parentaccountid], [originatingleadid], [pricelevelid],
            [statecode], [statuscode], [ownerid], [owningbusinessunit], [createdby], [modifiedby]
        )
        SELECT
            o.OppId,
            'Dynamics 365 Enterprise Rollout #' + CAST(n.N AS NVARCHAR(10)),
            'Strategic Dataverse and Power Platform migration #' + CAST(n.N AS NVARCHAR(10)),
            180000.00 + (n.N * 30000.00),
            CASE WHEN (n.N % 3) = 0 THEN 180000.00 + (n.N * 30000.00) ELSE NULL END,
            DATEADD(DAY, n.N * 4, CAST(SYSUTCDATETIME() AS DATE)),
            60 + (n.N % 40),
            a.AccountId,
            l.LeadId,
            p.PriceLevelId,
            CASE WHEN (n.N % 4) = 0 THEN 1 ELSE 0 END, -- 0=Open, 1=Won
            CASE WHEN (n.N % 4) = 0 THEN 3 ELSE 1 END,
            u.UserId, b.BUId, u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Opportunity o ON n.N = o.N
        JOIN #D365_Account a ON n.N = a.N
        JOIN #D365_Lead l ON n.N = l.N
        JOIN #D365_PriceLevel p ON n.N = p.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.9 OpportunityProduct
        INSERT INTO [Dynamics365].[OpportunityProduct] (
            [opportunityproductid], [opportunityid], [productid], [priceperunit], [quantity], [manualdiscountamount], [createdby], [modifiedby]
        )
        SELECT
            CAST(CAST(0x4A000000 + n.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            o.OppId,
            pr.ProductId,
            120.00 + (n.N * 25.00),
            10.00 + (n.N % 15),
            0.00,
            u.UserId,
            u.UserId
        FROM #N n
        JOIN #D365_Opportunity o ON n.N = o.N
        JOIN #D365_Product pr ON n.N = pr.N
        JOIN #D365_User u ON n.N = u.N;

        -- 3.10 Incident
        INSERT INTO [Dynamics365].[Incident] (
            [incidentid], [ticketnumber], [title], [description], [customerid_account], [customerid_contact],
            [prioritycode], [severitycode], [casetypecode], [statecode], [statuscode],
            [ownerid], [owningbusinessunit], [createdby], [modifiedby]
        )
        SELECT
            inc.IncidentId,
            'D365-CAS-' + RIGHT('00000' + CAST(1000 + n.N AS NVARCHAR(10)), 5),
            'Service Incident #' + CAST(n.N AS NVARCHAR(10)) + ' SLA Escalation',
            'Customer logged inquiry regarding Dataverse sync latency #' + CAST(n.N AS NVARCHAR(10)),
            a.AccountId,
            c.ContactId,
            (n.N % 3) + 1,
            (n.N % 3) + 1,
            (n.N % 3) + 1,
            0, 1,
            u.UserId, b.BUId, u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Incident inc ON n.N = inc.N
        JOIN #D365_Account a ON n.N = a.N
        JOIN #D365_Contact c ON n.N = c.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        -- 3.11 ActivityPointer
        INSERT INTO [Dynamics365].[ActivityPointer] (
            [activityid], [activitytypecode], [subject], [description], [statecode], [statuscode],
            [regardingobjectid_account], [regardingobjectid_opportunity], [ownerid], [owningbusinessunit],
            [createdby], [modifiedby]
        )
        SELECT
            CAST(CAST(0x5B000000 + n.N AS BINARY(4)) + 0x000000000000000000000000 AS UNIQUEIDENTIFIER),
            CASE (n.N % 4) WHEN 0 THEN 'task' WHEN 1 THEN 'phonecall' WHEN 2 THEN 'email' ELSE 'appointment' END,
            'Activity #' + CAST(n.N AS NVARCHAR(10)) + ': Architecture Sync',
            'Synchronized milestone review with executive stakeholders #' + CAST(n.N AS NVARCHAR(10)),
            0, 1,
            a.AccountId,
            o.OppId,
            u.UserId, b.BUId, u.UserId, u.UserId
        FROM #N n
        JOIN #D365_Account a ON n.N = a.N
        JOIN #D365_Opportunity o ON n.N = o.N
        JOIN #D365_User u ON n.N = u.N
        JOIN #D365_BU b ON n.N = b.N;

        DROP TABLE #D365_BU;
        DROP TABLE #D365_User;
        DROP TABLE #D365_Account;
        DROP TABLE #D365_Contact;
        DROP TABLE #D365_Lead;
        DROP TABLE #D365_PriceLevel;
        DROP TABLE #D365_Product;
        DROP TABLE #D365_Opportunity;
        DROP TABLE #D365_Incident;
        DROP TABLE #N;

        COMMIT TRANSACTION;
        PRINT 'Standard seed data generation complete: 50 records created for each table across all 3 CRM schemas (1,850 records total).';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF OBJECT_ID('tempdb..#N') IS NOT NULL DROP TABLE #N;
        IF OBJECT_ID('tempdb..#D365_BU') IS NOT NULL DROP TABLE #D365_BU;
        IF OBJECT_ID('tempdb..#D365_User') IS NOT NULL DROP TABLE #D365_User;
        IF OBJECT_ID('tempdb..#D365_Account') IS NOT NULL DROP TABLE #D365_Account;
        IF OBJECT_ID('tempdb..#D365_Contact') IS NOT NULL DROP TABLE #D365_Contact;
        IF OBJECT_ID('tempdb..#D365_Lead') IS NOT NULL DROP TABLE #D365_Lead;
        IF OBJECT_ID('tempdb..#D365_PriceLevel') IS NOT NULL DROP TABLE #D365_PriceLevel;
        IF OBJECT_ID('tempdb..#D365_Product') IS NOT NULL DROP TABLE #D365_Product;
        IF OBJECT_ID('tempdb..#D365_Opportunity') IS NOT NULL DROP TABLE #D365_Opportunity;
        IF OBJECT_ID('tempdb..#D365_Incident') IS NOT NULL DROP TABLE #D365_Incident;

        THROW;
    END CATCH
END;
