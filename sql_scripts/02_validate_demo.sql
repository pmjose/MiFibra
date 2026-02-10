-- ========================================================================
-- MiFibra Demo Validation Script
-- Validates all tables created, data loaded, and unstructured docs parsed
-- ========================================================================

USE ROLE MiFibra_Demo;
USE DATABASE MIFIBRA_AI_DEMO;
USE SCHEMA MIFIBRA_SCHEMA;
USE WAREHOUSE MIFIBRA_DEMO_WH;

-- ========================================================================
-- SECTION 1: INFRASTRUCTURE VALIDATION
-- ========================================================================

SELECT '=== INFRASTRUCTURE VALIDATION ===' AS section;

-- Check database exists
SELECT 'Database' AS object_type, 
       DATABASE_NAME AS object_name,
       CASE WHEN DATABASE_NAME IS NOT NULL THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM INFORMATION_SCHEMA.DATABASES 
WHERE DATABASE_NAME = 'MIFIBRA_AI_DEMO';

-- Check schema exists
SELECT 'Schema' AS object_type,
       SCHEMA_NAME AS object_name,
       CASE WHEN SCHEMA_NAME IS NOT NULL THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM INFORMATION_SCHEMA.SCHEMATA 
WHERE SCHEMA_NAME = 'MIFIBRA_SCHEMA';

-- Check warehouse exists
SHOW WAREHOUSES LIKE 'MIFIBRA_DEMO_WH';

-- Check Git repository
SHOW GIT REPOSITORIES LIKE 'MIFIBRA_AI_DEMO_REPO';

-- Check internal stage
SHOW STAGES LIKE 'MIFIBRA_INTERNAL_STAGE';

-- ========================================================================
-- SECTION 2: DIMENSION TABLES VALIDATION
-- ========================================================================

SELECT '=== DIMENSION TABLES VALIDATION ===' AS section;

SELECT 'MIFIBRA_PRODUCT_CATEGORY_DIM' AS table_name, COUNT(*) AS row_count, 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END AS status 
FROM MIFIBRA_PRODUCT_CATEGORY_DIM
UNION ALL
SELECT 'MIFIBRA_PRODUCT_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_PRODUCT_DIM
UNION ALL
SELECT 'MIFIBRA_VENDOR_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_VENDOR_DIM
UNION ALL
SELECT 'MIFIBRA_CUSTOMER_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_CUSTOMER_DIM
UNION ALL
SELECT 'MIFIBRA_ACCOUNT_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_ACCOUNT_DIM
UNION ALL
SELECT 'MIFIBRA_DEPARTMENT_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_DEPARTMENT_DIM
UNION ALL
SELECT 'MIFIBRA_REGION_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_REGION_DIM
UNION ALL
SELECT 'MIFIBRA_SALES_REP_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_SALES_REP_DIM
UNION ALL
SELECT 'MIFIBRA_CAMPAIGN_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_CAMPAIGN_DIM
UNION ALL
SELECT 'MIFIBRA_CHANNEL_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_CHANNEL_DIM
UNION ALL
SELECT 'MIFIBRA_EMPLOYEE_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_EMPLOYEE_DIM
UNION ALL
SELECT 'MIFIBRA_JOB_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_JOB_DIM
UNION ALL
SELECT 'MIFIBRA_LOCATION_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_LOCATION_DIM
UNION ALL
SELECT 'MIFIBRA_NETWORK_STATUS_DIM', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_NETWORK_STATUS_DIM
ORDER BY table_name;

-- ========================================================================
-- SECTION 3: FACT TABLES VALIDATION
-- ========================================================================

SELECT '=== FACT TABLES VALIDATION ===' AS section;

SELECT 'MIFIBRA_SALES_FACT' AS table_name, COUNT(*) AS row_count, 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END AS status 
FROM MIFIBRA_SALES_FACT
UNION ALL
SELECT 'MIFIBRA_FINANCE_TRANSACTIONS', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_FINANCE_TRANSACTIONS
UNION ALL
SELECT 'MIFIBRA_MARKETING_CAMPAIGN_FACT', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_MARKETING_CAMPAIGN_FACT
UNION ALL
SELECT 'MIFIBRA_HR_EMPLOYEE_FACT', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_HR_EMPLOYEE_FACT
UNION ALL
SELECT 'MIFIBRA_NETWORK_INCIDENTS_FACT', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_NETWORK_INCIDENTS_FACT
UNION ALL
SELECT 'MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE
ORDER BY table_name;

-- ========================================================================
-- SECTION 4: SALESFORCE TABLES VALIDATION
-- ========================================================================

SELECT '=== SALESFORCE TABLES VALIDATION ===' AS section;

SELECT 'MIFIBRA_SF_ACCOUNTS' AS table_name, COUNT(*) AS row_count, 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END AS status 
FROM MIFIBRA_SF_ACCOUNTS
UNION ALL
SELECT 'MIFIBRA_SF_OPPORTUNITIES', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_SF_OPPORTUNITIES
UNION ALL
SELECT 'MIFIBRA_SF_CONTACTS', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ LOADED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_SF_CONTACTS
ORDER BY table_name;

-- ========================================================================
-- SECTION 5: UNSTRUCTURED DATA VALIDATION
-- ========================================================================

SELECT '=== UNSTRUCTURED DATA VALIDATION ===' AS section;

-- Check files in internal stage
SELECT 'Files in MIFIBRA_INTERNAL_STAGE' AS check_type;
SELECT COUNT(*) AS file_count, 
       CASE WHEN COUNT(*) > 0 THEN '✓ FILES PRESENT' ELSE '✗ NO FILES' END AS status
FROM DIRECTORY(@MIFIBRA_INTERNAL_STAGE);

-- List unstructured doc files
SELECT 'Unstructured Documents' AS check_type;
SELECT relative_path, size, last_modified
FROM DIRECTORY(@MIFIBRA_INTERNAL_STAGE)
WHERE relative_path ILIKE 'unstructured_docs/%'
ORDER BY relative_path;

-- Check parsed content tables
SELECT 'MIFIBRA_PARSED_CONTENT_DOCS' AS table_name, COUNT(*) AS row_count, 
       CASE WHEN COUNT(*) > 0 THEN '✓ PARSED' ELSE '✗ EMPTY' END AS status 
FROM MIFIBRA_PARSED_CONTENT_DOCS
UNION ALL
SELECT 'MIFIBRA_PARSED_CONTENT_MD', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ PARSED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_PARSED_CONTENT_MD
UNION ALL
SELECT 'MIFIBRA_PARSED_CONTENT', COUNT(*), 
       CASE WHEN COUNT(*) > 0 THEN '✓ PARSED' ELSE '✗ EMPTY' END 
FROM MIFIBRA_PARSED_CONTENT
ORDER BY table_name;

-- Show parsed document details
SELECT 'Parsed Documents Detail' AS check_type;
SELECT relative_path, LENGTH(content) AS content_length
FROM MIFIBRA_PARSED_CONTENT
ORDER BY relative_path;

-- ========================================================================
-- SECTION 6: SEMANTIC VIEWS VALIDATION
-- ========================================================================

SELECT '=== SEMANTIC VIEWS VALIDATION ===' AS section;

SHOW SEMANTIC VIEWS IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

-- Validate each semantic view exists
SELECT 'Semantic View Check' AS check_type;
SELECT 'MIFIBRA_FINANCE_SEMANTIC_VIEW' AS view_name, 
       CASE WHEN COUNT(*) > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END AS status
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' AND TABLE_NAME = 'MIFIBRA_FINANCE_SEMANTIC_VIEW'
UNION ALL
SELECT 'MIFIBRA_SALES_SEMANTIC_VIEW', 
       CASE WHEN COUNT(*) > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' AND TABLE_NAME = 'MIFIBRA_SALES_SEMANTIC_VIEW'
UNION ALL
SELECT 'MIFIBRA_MARKETING_SEMANTIC_VIEW', 
       CASE WHEN COUNT(*) > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' AND TABLE_NAME = 'MIFIBRA_MARKETING_SEMANTIC_VIEW'
UNION ALL
SELECT 'MIFIBRA_HR_SEMANTIC_VIEW', 
       CASE WHEN COUNT(*) > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' AND TABLE_NAME = 'MIFIBRA_HR_SEMANTIC_VIEW'
UNION ALL
SELECT 'MIFIBRA_INFRASTRUCTURE_SEMANTIC_VIEW', 
       CASE WHEN COUNT(*) > 0 THEN '✓ EXISTS' ELSE '✗ MISSING' END
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' AND TABLE_NAME = 'MIFIBRA_INFRASTRUCTURE_SEMANTIC_VIEW';

-- ========================================================================
-- SECTION 7: CORTEX SEARCH SERVICES VALIDATION
-- ========================================================================

SELECT '=== CORTEX SEARCH SERVICES VALIDATION ===' AS section;

SHOW CORTEX SEARCH SERVICES IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

-- ========================================================================
-- SECTION 8: GEOSPATIAL DATA VALIDATION
-- ========================================================================

SELECT '=== GEOSPATIAL DATA VALIDATION ===' AS section;

-- Check customers have lat/long
SELECT 'Customers with Geospatial' AS check_type,
       COUNT(*) AS total_customers,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete
FROM MIFIBRA_CUSTOMER_DIM;

-- Check regions have lat/long
SELECT 'Regions with Geospatial' AS check_type,
       COUNT(*) AS total_regions,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete
FROM MIFIBRA_REGION_DIM;

-- Check locations have lat/long
SELECT 'Locations with Geospatial' AS check_type,
       COUNT(*) AS total_locations,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete
FROM MIFIBRA_LOCATION_DIM;

-- Check network nodes have lat/long
SELECT 'Network Nodes with Geospatial' AS check_type,
       COUNT(*) AS total_nodes,
       SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) AS with_coordinates,
       ROUND(100.0 * SUM(CASE WHEN latitude IS NOT NULL AND longitude IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_complete
FROM MIFIBRA_NETWORK_STATUS_DIM;

-- ========================================================================
-- SECTION 9: DATA QUALITY CHECKS
-- ========================================================================

SELECT '=== DATA QUALITY CHECKS ===' AS section;

-- Check for Peru-specific data (no UK references)
SELECT 'Peru Data Validation' AS check_type,
       'Customers in Peru regions' AS metric,
       COUNT(*) AS count
FROM MIFIBRA_CUSTOMER_DIM
WHERE city IN ('Lima', 'Arequipa', 'Trujillo', 'Chiclayo', 'Piura', 'Cusco', 'Huancayo', 'Iquitos', 'Tacna', 'Puno');

-- Check SF Accounts are Peru-based
SELECT 'SF Accounts Peru Check' AS check_type,
       SUM(CASE WHEN billing_state IN ('Lima', 'Arequipa', 'La Libertad', 'Lambayeque', 'Piura', 'Cusco', 'Junin', 'Loreto', 'Tacna', 'Puno', 'Callao', 'Ica') THEN 1 ELSE 0 END) AS peru_accounts,
       COUNT(*) AS total_accounts,
       ROUND(100.0 * SUM(CASE WHEN billing_state IN ('Lima', 'Arequipa', 'La Libertad', 'Lambayeque', 'Piura', 'Cusco', 'Junin', 'Loreto', 'Tacna', 'Puno', 'Callao', 'Ica') THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_peru
FROM MIFIBRA_SF_ACCOUNTS;

-- Check SF Contacts have Peru phone numbers
SELECT 'SF Contacts Peru Phone Check' AS check_type,
       SUM(CASE WHEN phone LIKE '+51%' THEN 1 ELSE 0 END) AS peru_phones,
       COUNT(*) AS total_contacts,
       ROUND(100.0 * SUM(CASE WHEN phone LIKE '+51%' THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_peru
FROM MIFIBRA_SF_CONTACTS;

-- ========================================================================
-- SECTION 10: SUMMARY REPORT
-- ========================================================================

SELECT '=== VALIDATION SUMMARY ===' AS section;

WITH table_counts AS (
    SELECT 'Dimension Tables' AS category, 14 AS expected,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' 
            AND TABLE_NAME LIKE 'MIFIBRA_%_DIM') AS actual
    UNION ALL
    SELECT 'Fact Tables', 4,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' 
            AND TABLE_NAME LIKE 'MIFIBRA_%_FACT')
    UNION ALL
    SELECT 'Salesforce Tables', 3,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' 
            AND TABLE_NAME LIKE 'MIFIBRA_SF_%')
    UNION ALL
    SELECT 'Parsed Content Tables', 3,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES 
            WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' 
            AND TABLE_NAME LIKE 'MIFIBRA_PARSED_%')
    UNION ALL
    SELECT 'Semantic Views', 5,
           (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS 
            WHERE TABLE_SCHEMA = 'MIFIBRA_SCHEMA' 
            AND TABLE_NAME LIKE 'MIFIBRA_%_SEMANTIC_VIEW')
)
SELECT category,
       expected,
       actual,
       CASE WHEN actual >= expected THEN '✓ PASS' ELSE '✗ FAIL' END AS status
FROM table_counts;

-- Total row counts
SELECT 'Total Data Rows' AS metric,
       (SELECT COUNT(*) FROM MIFIBRA_CUSTOMER_DIM) +
       (SELECT COUNT(*) FROM MIFIBRA_SALES_FACT) +
       (SELECT COUNT(*) FROM MIFIBRA_SF_ACCOUNTS) +
       (SELECT COUNT(*) FROM MIFIBRA_SF_OPPORTUNITIES) +
       (SELECT COUNT(*) FROM MIFIBRA_SF_CONTACTS) AS total_rows;

SELECT '=== VALIDATION COMPLETE ===' AS section;
