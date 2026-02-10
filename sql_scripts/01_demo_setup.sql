-- ========================================================================
-- Snowflake AI Demo - Complete Setup Script (MiFibra Peru)
-- This script creates the database, schema, tables, and loads all data
-- Peru's fastest fiber optic ISP - 100% fiber infrastructure
-- ========================================================================

-- Switch to accountadmin role to create warehouse
USE ROLE accountadmin;

-- Enable Snowflake Intelligence by creating the Config DB & Schema
CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

-- Allow anyone to see the agents in this schema
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

CREATE OR REPLACE ROLE MiFibra_Demo;

SET current_user_name = CURRENT_USER();

-- Grant the role to current user
GRANT ROLE MiFibra_Demo TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE MiFibra_Demo;

-- Create a dedicated warehouse for the demo with auto-suspend/resume
CREATE OR REPLACE WAREHOUSE MiFibra_Demo_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse to demo role
GRANT USAGE ON WAREHOUSE MIFIBRA_DEMO_WH TO ROLE MiFibra_Demo;

-- Alter current user's default role and warehouse
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = MiFibra_Demo;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = MiFibra_Demo_WH;

-- Switch to MiFibra_Demo role to create demo objects
USE ROLE MiFibra_Demo;

-- Create database and schema
CREATE OR REPLACE DATABASE MIFIBRA_AI_DEMO;
USE DATABASE MIFIBRA_AI_DEMO;

CREATE SCHEMA IF NOT EXISTS MIFIBRA_SCHEMA;
USE SCHEMA MIFIBRA_SCHEMA;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT MIFIBRA_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

USE ROLE accountadmin;

-- Create API Integration for GitHub (public repository access)
CREATE OR REPLACE API INTEGRATION mifibra_git_api_integration
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/pmjose/')
    ENABLED = TRUE;

GRANT USAGE ON INTEGRATION MIFIBRA_GIT_API_INTEGRATION TO ROLE MiFibra_Demo;

USE ROLE MiFibra_Demo;
USE DATABASE MIFIBRA_AI_DEMO;
USE SCHEMA MIFIBRA_SCHEMA;

-- Create Git repository integration for the MiFibra Peru demo repository
CREATE OR REPLACE GIT REPOSITORY MIFIBRA_AI_DEMO_REPO
    API_INTEGRATION = mifibra_git_api_integration
    ORIGIN = 'https://github.com/pmjose/MiFibra.git';

-- Create internal stage for copied data files
CREATE OR REPLACE STAGE MIFIBRA_INTERNAL_STAGE
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    COMMENT = 'Internal stage for copied demo data files'
    DIRECTORY = (ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

ALTER GIT REPOSITORY MIFIBRA_AI_DEMO_REPO FETCH;

-- ========================================================================
-- COPY FILES FROM GIT TO INTERNAL STAGE
-- (COPY INTO from Git Repository is not supported - must stage first)
-- ========================================================================

-- Copy unstructured docs (PDF, DOCX, etc.) to internal stage for parsing
COPY FILES
INTO @MIFIBRA_INTERNAL_STAGE/unstructured_docs/
FROM @MIFIBRA_AI_DEMO_REPO/branches/main/unstructured_docs/;

-- Copy CSV data files to internal stage
COPY FILES
INTO @MIFIBRA_INTERNAL_STAGE/demo_data/
FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/;

-- Refresh stage directory
ALTER STAGE MIFIBRA_INTERNAL_STAGE REFRESH;

-- ========================================================================
-- DIMENSION TABLES
-- ========================================================================

-- Product Category Dimension
CREATE OR REPLACE TABLE MIFIBRA_PRODUCT_CATEGORY_DIM (
    category_key INT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    vertical VARCHAR(50) NOT NULL
);

-- Product Dimension
CREATE OR REPLACE TABLE MIFIBRA_PRODUCT_DIM (
    product_key INT PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_key INT NOT NULL,
    category_name VARCHAR(100),
    vertical VARCHAR(50)
);

-- Vendor Dimension
CREATE OR REPLACE TABLE MIFIBRA_VENDOR_DIM (
    vendor_key INT PRIMARY KEY,
    vendor_name VARCHAR(200) NOT NULL,
    vertical VARCHAR(50) NOT NULL,
    address VARCHAR(200),
    city VARCHAR(100),
    county VARCHAR(100),
    postcode VARCHAR(20)
);

-- Customer Dimension
CREATE OR REPLACE TABLE MIFIBRA_CUSTOMER_DIM (
    customer_key INT PRIMARY KEY,
    customer_name VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    vertical VARCHAR(50),
    address VARCHAR(200),
    city VARCHAR(100),
    county VARCHAR(100),
    postcode VARCHAR(20),
    latitude FLOAT,
    longitude FLOAT
);

-- Account Dimension (Finance)
CREATE OR REPLACE TABLE MIFIBRA_ACCOUNT_DIM (
    account_key INT PRIMARY KEY,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50)
);

-- Department Dimension
CREATE OR REPLACE TABLE MIFIBRA_DEPARTMENT_DIM (
    department_key INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL
);

-- Region Dimension
CREATE OR REPLACE TABLE MIFIBRA_REGION_DIM (
    region_key INT PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    latitude FLOAT,
    longitude FLOAT,
    capital_city VARCHAR(100),
    area_km2 INT
);

-- Sales Rep Dimension
CREATE OR REPLACE TABLE MIFIBRA_SALES_REP_DIM (
    sales_rep_key INT PRIMARY KEY,
    rep_name VARCHAR(200) NOT NULL,
    hire_date DATE
);

-- Campaign Dimension (Marketing)
CREATE OR REPLACE TABLE MIFIBRA_CAMPAIGN_DIM (
    campaign_key INT PRIMARY KEY,
    campaign_name VARCHAR(300) NOT NULL,
    objective VARCHAR(100)
);

-- Channel Dimension (Marketing)
CREATE OR REPLACE TABLE MIFIBRA_CHANNEL_DIM (
    channel_key INT PRIMARY KEY,
    channel_name VARCHAR(100) NOT NULL
);

-- Employee Dimension (HR)
CREATE OR REPLACE TABLE MIFIBRA_EMPLOYEE_DIM (
    employee_key INT PRIMARY KEY,
    employee_name VARCHAR(200) NOT NULL,
    gender VARCHAR(1),
    hire_date DATE
);

-- Job Dimension (HR)
CREATE OR REPLACE TABLE MIFIBRA_JOB_DIM (
    job_key INT PRIMARY KEY,
    job_title VARCHAR(100) NOT NULL,
    job_level INT
);

-- Location Dimension (HR)
CREATE OR REPLACE TABLE MIFIBRA_LOCATION_DIM (
    location_key INT PRIMARY KEY,
    location_name VARCHAR(200) NOT NULL,
    city VARCHAR(100),
    department VARCHAR(100),
    location_type VARCHAR(50),
    latitude FLOAT,
    longitude FLOAT
);

-- Network Status Dimension (Infrastructure)
CREATE OR REPLACE TABLE MIFIBRA_NETWORK_STATUS_DIM (
    node_id INT PRIMARY KEY,
    region_key INT NOT NULL,
    city_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    node_type VARCHAR(50),
    status VARCHAR(50),
    capacity_gbps INT,
    utilization_pct FLOAT,
    households_passed INT,
    active_subscribers INT,
    penetration_pct FLOAT,
    latency_ms FLOAT,
    uptime_pct FLOAT,
    olt_count INT,
    ont_deployed INT,
    fiber_km FLOAT,
    technology VARCHAR(50),
    last_maintenance DATE,
    next_maintenance DATE,
    noc_region VARCHAR(100),
    latitude FLOAT,
    longitude FLOAT
);

-- Network Incidents Fact Table (VARCHAR ID to match CSV format INC-2026-XXXX)
CREATE OR REPLACE TABLE MIFIBRA_NETWORK_INCIDENTS_FACT (
    incident_id VARCHAR(50) PRIMARY KEY,
    node_id INT NOT NULL,
    region_key INT NOT NULL,
    incident_date DATE NOT NULL,
    incident_type VARCHAR(100),
    severity VARCHAR(50),
    status VARCHAR(50),
    affected_subscribers INT,
    duration_hours FLOAT,
    root_cause VARCHAR(200),
    resolution VARCHAR(200),
    reported_by VARCHAR(100),
    resolved_by VARCHAR(100)
);

-- Network Maintenance Schedule Table (VARCHAR ID to match CSV format MAINT-2026-XXX)
CREATE OR REPLACE TABLE MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE (
    maintenance_id VARCHAR(50) PRIMARY KEY,
    node_id INT NOT NULL,
    region_key INT NOT NULL,
    scheduled_date DATE NOT NULL,
    maintenance_type VARCHAR(100),
    duration_hours FLOAT,
    affected_subscribers_estimate INT,
    status VARCHAR(50),
    description VARCHAR(500),
    assigned_team VARCHAR(100),
    impact_level VARCHAR(50)
);

-- ========================================================================
-- FACT TABLES
-- ========================================================================

-- Sales Fact Table
CREATE OR REPLACE TABLE MIFIBRA_SALES_FACT (
    sale_id INT PRIMARY KEY,
    date DATE NOT NULL,
    customer_key INT NOT NULL,
    product_key INT NOT NULL,
    sales_rep_key INT NOT NULL,
    region_key INT NOT NULL,
    vendor_key INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    units INT NOT NULL
);

-- Finance Transactions Fact Table
CREATE OR REPLACE TABLE MIFIBRA_FINANCE_TRANSACTIONS (
    transaction_id INT PRIMARY KEY,
    date DATE NOT NULL,
    account_key INT NOT NULL,
    department_key INT NOT NULL,
    vendor_key INT NOT NULL,
    product_key INT NOT NULL,
    customer_key INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    approval_status VARCHAR(20) DEFAULT 'Pending',
    procurement_method VARCHAR(50),
    approver_id INT,
    approval_date DATE,
    purchase_order_number VARCHAR(50),
    contract_reference VARCHAR(100)
) COMMENT = 'Financial transactions with compliance tracking';

-- Marketing Campaign Fact Table
CREATE OR REPLACE TABLE MIFIBRA_MARKETING_CAMPAIGN_FACT (
    campaign_fact_id INT PRIMARY KEY,
    date DATE NOT NULL,
    campaign_key INT NOT NULL,
    product_key INT NOT NULL,
    channel_key INT NOT NULL,
    region_key INT NOT NULL,
    spend DECIMAL(10,2) NOT NULL,
    leads_generated INT NOT NULL,
    impressions INT NOT NULL
);

-- HR Employee Fact Table
CREATE OR REPLACE TABLE MIFIBRA_HR_EMPLOYEE_FACT (
    hr_fact_id INT PRIMARY KEY,
    date DATE NOT NULL,
    employee_key INT NOT NULL,
    department_key INT NOT NULL,
    job_key INT NOT NULL,
    location_key INT NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    attrition_flag INT NOT NULL
);

-- ========================================================================
-- SALESFORCE CRM TABLES
-- ========================================================================

-- Salesforce Accounts Table
CREATE OR REPLACE TABLE MIFIBRA_SF_ACCOUNTS (
    account_id VARCHAR(20) PRIMARY KEY,
    account_name VARCHAR(200) NOT NULL,
    customer_key INT NOT NULL,
    industry VARCHAR(100),
    vertical VARCHAR(50),
    billing_street VARCHAR(200),
    billing_city VARCHAR(100),
    billing_state VARCHAR(100),
    billing_postal_code VARCHAR(20),
    account_type VARCHAR(50),
    annual_revenue DECIMAL(15,2),
    employees INT,
    created_date DATE
);

-- Salesforce Opportunities Table
CREATE OR REPLACE TABLE MIFIBRA_SF_OPPORTUNITIES (
    opportunity_id VARCHAR(20) PRIMARY KEY,
    sale_id INT,
    account_id VARCHAR(20) NOT NULL,
    opportunity_name VARCHAR(200) NOT NULL,
    stage_name VARCHAR(100) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    probability DECIMAL(5,2),
    close_date DATE,
    created_date DATE,
    lead_source VARCHAR(100),
    type VARCHAR(100),
    campaign_id INT
);

-- Salesforce Contacts Table
CREATE OR REPLACE TABLE MIFIBRA_SF_CONTACTS (
    contact_id VARCHAR(20) PRIMARY KEY,
    account_id VARCHAR(20) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(200),
    phone VARCHAR(50),
    title VARCHAR(100),
    department VARCHAR(100),
    created_date DATE
);

-- ========================================================================
-- LOAD DIMENSION DATA FROM INTERNAL STAGE
-- ========================================================================

COPY INTO MIFIBRA_PRODUCT_CATEGORY_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/product_category_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_PRODUCT_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/product_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_VENDOR_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/vendor_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_CUSTOMER_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/customer_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_ACCOUNT_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/account_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_DEPARTMENT_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/department_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_REGION_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/region_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_SALES_REP_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/sales_rep_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_CAMPAIGN_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/campaign_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_CHANNEL_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/channel_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_EMPLOYEE_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/employee_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_JOB_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/job_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_LOCATION_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/location_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_NETWORK_STATUS_DIM
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/network_status_dim.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_NETWORK_INCIDENTS_FACT
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/network_incidents_fact.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/network_maintenance_schedule.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

-- ========================================================================
-- LOAD FACT DATA FROM INTERNAL STAGE
-- ========================================================================

COPY INTO MIFIBRA_SALES_FACT
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/sales_fact.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_FINANCE_TRANSACTIONS
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/finance_transactions.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_MARKETING_CAMPAIGN_FACT
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/marketing_campaign_fact.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_HR_EMPLOYEE_FACT
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/hr_employee_fact.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

-- ========================================================================
-- LOAD SALESFORCE DATA FROM INTERNAL STAGE
-- ========================================================================

COPY INTO MIFIBRA_SF_ACCOUNTS
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/sf_accounts.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_SF_OPPORTUNITIES
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/sf_opportunities.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

COPY INTO MIFIBRA_SF_CONTACTS
FROM @MIFIBRA_INTERNAL_STAGE/demo_data/sf_contacts.csv
FILE_FORMAT = MIFIBRA_CSV_FORMAT ON_ERROR = 'CONTINUE';

-- ========================================================================
-- VERIFICATION - Data Load Counts
-- ========================================================================

SELECT 'DIMENSION TABLES' as category, '' as table_name, NULL as row_count
UNION ALL SELECT '', 'MIFIBRA_PRODUCT_CATEGORY_DIM', COUNT(*) FROM MIFIBRA_PRODUCT_CATEGORY_DIM
UNION ALL SELECT '', 'MIFIBRA_PRODUCT_DIM', COUNT(*) FROM MIFIBRA_PRODUCT_DIM
UNION ALL SELECT '', 'MIFIBRA_VENDOR_DIM', COUNT(*) FROM MIFIBRA_VENDOR_DIM
UNION ALL SELECT '', 'MIFIBRA_CUSTOMER_DIM', COUNT(*) FROM MIFIBRA_CUSTOMER_DIM
UNION ALL SELECT '', 'MIFIBRA_ACCOUNT_DIM', COUNT(*) FROM MIFIBRA_ACCOUNT_DIM
UNION ALL SELECT '', 'MIFIBRA_DEPARTMENT_DIM', COUNT(*) FROM MIFIBRA_DEPARTMENT_DIM
UNION ALL SELECT '', 'MIFIBRA_REGION_DIM', COUNT(*) FROM MIFIBRA_REGION_DIM
UNION ALL SELECT '', 'MIFIBRA_SALES_REP_DIM', COUNT(*) FROM MIFIBRA_SALES_REP_DIM
UNION ALL SELECT '', 'MIFIBRA_CAMPAIGN_DIM', COUNT(*) FROM MIFIBRA_CAMPAIGN_DIM
UNION ALL SELECT '', 'MIFIBRA_CHANNEL_DIM', COUNT(*) FROM MIFIBRA_CHANNEL_DIM
UNION ALL SELECT '', 'MIFIBRA_EMPLOYEE_DIM', COUNT(*) FROM MIFIBRA_EMPLOYEE_DIM
UNION ALL SELECT '', 'MIFIBRA_JOB_DIM', COUNT(*) FROM MIFIBRA_JOB_DIM
UNION ALL SELECT '', 'MIFIBRA_LOCATION_DIM', COUNT(*) FROM MIFIBRA_LOCATION_DIM
UNION ALL SELECT '', 'MIFIBRA_NETWORK_STATUS_DIM', COUNT(*) FROM MIFIBRA_NETWORK_STATUS_DIM
UNION ALL SELECT '', 'MIFIBRA_NETWORK_INCIDENTS_FACT', COUNT(*) FROM MIFIBRA_NETWORK_INCIDENTS_FACT
UNION ALL SELECT '', 'MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE', COUNT(*) FROM MIFIBRA_NETWORK_MAINTENANCE_SCHEDULE
UNION ALL SELECT '', '', NULL
UNION ALL SELECT 'FACT TABLES', '', NULL
UNION ALL SELECT '', 'MIFIBRA_SALES_FACT', COUNT(*) FROM MIFIBRA_SALES_FACT
UNION ALL SELECT '', 'MIFIBRA_FINANCE_TRANSACTIONS', COUNT(*) FROM MIFIBRA_FINANCE_TRANSACTIONS
UNION ALL SELECT '', 'MIFIBRA_MARKETING_CAMPAIGN_FACT', COUNT(*) FROM MIFIBRA_MARKETING_CAMPAIGN_FACT
UNION ALL SELECT '', 'MIFIBRA_HR_EMPLOYEE_FACT', COUNT(*) FROM MIFIBRA_HR_EMPLOYEE_FACT
UNION ALL SELECT '', '', NULL
UNION ALL SELECT 'SALESFORCE TABLES', '', NULL
UNION ALL SELECT '', 'MIFIBRA_SF_ACCOUNTS', COUNT(*) FROM MIFIBRA_SF_ACCOUNTS
UNION ALL SELECT '', 'MIFIBRA_SF_OPPORTUNITIES', COUNT(*) FROM MIFIBRA_SF_OPPORTUNITIES
UNION ALL SELECT '', 'MIFIBRA_SF_CONTACTS', COUNT(*) FROM MIFIBRA_SF_CONTACTS;

-- ========================================================================
-- SEMANTIC VIEWS
-- ========================================================================

USE DATABASE MIFIBRA_AI_DEMO;
USE SCHEMA MIFIBRA_SCHEMA;

-- FINANCE SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW MIFIBRA_FINANCE_SEMANTIC_VIEW
    TABLES (
        TRANSACTIONS AS MIFIBRA_FINANCE_TRANSACTIONS PRIMARY KEY (TRANSACTION_ID) COMMENT 'Financial transactions',
        ACCOUNTS AS MIFIBRA_ACCOUNT_DIM PRIMARY KEY (ACCOUNT_KEY) COMMENT 'Account dimension',
        DEPARTMENTS AS MIFIBRA_DEPARTMENT_DIM PRIMARY KEY (DEPARTMENT_KEY) COMMENT 'Department dimension',
        VENDORS AS MIFIBRA_VENDOR_DIM PRIMARY KEY (VENDOR_KEY) COMMENT 'Vendor information',
        PRODUCTS AS MIFIBRA_PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY) COMMENT 'Product dimension',
        CUSTOMERS AS MIFIBRA_CUSTOMER_DIM PRIMARY KEY (CUSTOMER_KEY) COMMENT 'Customer dimension'
    )
    RELATIONSHIPS (
        TRANSACTIONS (ACCOUNT_KEY) REFERENCES ACCOUNTS,
        TRANSACTIONS (DEPARTMENT_KEY) REFERENCES DEPARTMENTS,
        TRANSACTIONS (VENDOR_KEY) REFERENCES VENDORS,
        TRANSACTIONS (PRODUCT_KEY) REFERENCES PRODUCTS,
        TRANSACTIONS (CUSTOMER_KEY) REFERENCES CUSTOMERS
    )
    FACTS (
        TRANSACTIONS.TXN_AMOUNT AS TRANSACTIONS.AMOUNT COMMENT 'Transaction amount in Soles'
    )
    DIMENSIONS (
        TRANSACTIONS.TXN_DATE AS TRANSACTIONS.DATE COMMENT 'Transaction date',
        ACCOUNTS.ACCT_NAME AS ACCOUNTS.ACCOUNT_NAME COMMENT 'Account name',
        DEPARTMENTS.DEPT_NAME AS DEPARTMENTS.DEPARTMENT_NAME COMMENT 'Department name',
        VENDORS.VEND_NAME AS VENDORS.VENDOR_NAME COMMENT 'Vendor name',
        PRODUCTS.PROD_NAME AS PRODUCTS.PRODUCT_NAME COMMENT 'Product name',
        CUSTOMERS.CUST_NAME AS CUSTOMERS.CUSTOMER_NAME COMMENT 'Customer name',
        CUSTOMERS.CUST_INDUSTRY AS CUSTOMERS.INDUSTRY COMMENT 'Industry',
        CUSTOMERS.CUST_VERTICAL AS CUSTOMERS.VERTICAL COMMENT 'Customer segment',
        CUSTOMERS.CUST_LAT AS CUSTOMERS.LATITUDE COMMENT 'Customer latitude',
        CUSTOMERS.CUST_LNG AS CUSTOMERS.LONGITUDE COMMENT 'Customer longitude',
        CUSTOMERS.CUST_CITY AS CUSTOMERS.CITY COMMENT 'Customer city',
        CUSTOMERS.CUST_COUNTY AS CUSTOMERS.COUNTY COMMENT 'Customer county'
    )
    METRICS (
        TRANSACTIONS.TOTAL_AMOUNT AS SUM(TRANSACTIONS.TXN_AMOUNT) COMMENT 'Total amount'
    )
    COMMENT = 'Finance semantic view';

-- SALES SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW MIFIBRA_SALES_SEMANTIC_VIEW
    TABLES (
        CUSTOMERS AS MIFIBRA_CUSTOMER_DIM PRIMARY KEY (CUSTOMER_KEY) COMMENT 'Customer information',
        PRODUCTS AS MIFIBRA_PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY) COMMENT 'Product catalog',
        CATEGORIES AS MIFIBRA_PRODUCT_CATEGORY_DIM PRIMARY KEY (CATEGORY_KEY) COMMENT 'Product categories',
        REGIONS AS MIFIBRA_REGION_DIM PRIMARY KEY (REGION_KEY) COMMENT 'Regional information',
        SALES AS MIFIBRA_SALES_FACT PRIMARY KEY (SALE_ID) COMMENT 'Sales transactions',
        SALES_REPS AS MIFIBRA_SALES_REP_DIM PRIMARY KEY (SALES_REP_KEY) COMMENT 'Sales representatives',
        VENDORS AS MIFIBRA_VENDOR_DIM PRIMARY KEY (VENDOR_KEY) COMMENT 'Vendor information'
    )
    RELATIONSHIPS (
        PRODUCTS (CATEGORY_KEY) REFERENCES CATEGORIES,
        SALES (CUSTOMER_KEY) REFERENCES CUSTOMERS,
        SALES (PRODUCT_KEY) REFERENCES PRODUCTS,
        SALES (REGION_KEY) REFERENCES REGIONS,
        SALES (SALES_REP_KEY) REFERENCES SALES_REPS,
        SALES (VENDOR_KEY) REFERENCES VENDORS
    )
    FACTS (
        SALES.SALE_AMOUNT AS SALES.AMOUNT COMMENT 'Sale amount in Soles',
        SALES.SALE_UNITS AS SALES.UNITS COMMENT 'Units sold'
    )
    DIMENSIONS (
        CUSTOMERS.CUST_NAME AS CUSTOMERS.CUSTOMER_NAME COMMENT 'Customer name',
        CUSTOMERS.CUST_INDUSTRY AS CUSTOMERS.INDUSTRY COMMENT 'Customer industry',
        PRODUCTS.PROD_NAME AS PRODUCTS.PRODUCT_NAME COMMENT 'Product name',
        CATEGORIES.CAT_NAME AS CATEGORIES.CATEGORY_NAME COMMENT 'Category name',
        CATEGORIES.CAT_VERTICAL AS CATEGORIES.VERTICAL COMMENT 'Category vertical',
        REGIONS.REG_NAME AS REGIONS.REGION_NAME COMMENT 'Region name',
        REGIONS.REG_LAT AS REGIONS.LATITUDE COMMENT 'Region latitude',
        REGIONS.REG_LNG AS REGIONS.LONGITUDE COMMENT 'Region longitude',
        SALES.SALE_DATE AS SALES.DATE COMMENT 'Sale date',
        SALES_REPS.REP AS SALES_REPS.REP_NAME COMMENT 'Sales rep name',
        VENDORS.VEND_NAME AS VENDORS.VENDOR_NAME COMMENT 'Vendor name'
    )
    METRICS (
        SALES.REVENUE AS SUM(SALES.SALE_AMOUNT) COMMENT 'Total revenue',
        SALES.TOTALUNITS AS SUM(SALES.SALE_UNITS) COMMENT 'Total units sold'
    )
    COMMENT = 'Sales semantic view for MiFibra Peru';

-- MARKETING SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW MIFIBRA_MARKETING_SEMANTIC_VIEW
    TABLES (
        ACCOUNTS AS MIFIBRA_SF_ACCOUNTS PRIMARY KEY (ACCOUNT_ID) COMMENT 'Customer accounts',
        CAMPAIGNS AS MIFIBRA_MARKETING_CAMPAIGN_FACT PRIMARY KEY (CAMPAIGN_FACT_ID) COMMENT 'Campaign data',
        CAMPAIGN_DETAILS AS MIFIBRA_CAMPAIGN_DIM PRIMARY KEY (CAMPAIGN_KEY) COMMENT 'Campaign details',
        CHANNELS AS MIFIBRA_CHANNEL_DIM PRIMARY KEY (CHANNEL_KEY) COMMENT 'Marketing channels',
        CONTACTS AS MIFIBRA_SF_CONTACTS PRIMARY KEY (CONTACT_ID) COMMENT 'Contact records',
        OPPORTUNITIES AS MIFIBRA_SF_OPPORTUNITIES PRIMARY KEY (OPPORTUNITY_ID) COMMENT 'Sales opportunities',
        PRODUCTS AS MIFIBRA_PRODUCT_DIM PRIMARY KEY (PRODUCT_KEY) COMMENT 'Products',
        REGIONS AS MIFIBRA_REGION_DIM PRIMARY KEY (REGION_KEY) COMMENT 'Regions'
    )
    RELATIONSHIPS (
        CAMPAIGNS (CHANNEL_KEY) REFERENCES CHANNELS,
        CAMPAIGNS (CAMPAIGN_KEY) REFERENCES CAMPAIGN_DETAILS,
        CAMPAIGNS (PRODUCT_KEY) REFERENCES PRODUCTS,
        CAMPAIGNS (REGION_KEY) REFERENCES REGIONS,
        CONTACTS (ACCOUNT_ID) REFERENCES ACCOUNTS,
        OPPORTUNITIES (ACCOUNT_ID) REFERENCES ACCOUNTS
    )
    FACTS (
        CAMPAIGNS.CMP_SPEND AS CAMPAIGNS.SPEND COMMENT 'Marketing spend in Soles',
        CAMPAIGNS.CMP_LEADS AS CAMPAIGNS.LEADS_GENERATED COMMENT 'Leads generated',
        CAMPAIGNS.CMP_IMPR AS CAMPAIGNS.IMPRESSIONS COMMENT 'Impressions',
        OPPORTUNITIES.OPP_AMT AS OPPORTUNITIES.AMOUNT COMMENT 'Opportunity revenue'
    )
    DIMENSIONS (
        ACCOUNTS.ACCT_NAME AS ACCOUNTS.ACCOUNT_NAME COMMENT 'Account name',
        ACCOUNTS.ACCT_INDUSTRY AS ACCOUNTS.INDUSTRY COMMENT 'Industry',
        CAMPAIGN_DETAILS.CMP_NAME AS CAMPAIGN_DETAILS.CAMPAIGN_NAME COMMENT 'Campaign name',
        CAMPAIGN_DETAILS.CMP_OBJ AS CAMPAIGN_DETAILS.OBJECTIVE COMMENT 'Campaign objective',
        CHANNELS.CHN_NAME AS CHANNELS.CHANNEL_NAME COMMENT 'Marketing channel',
        CONTACTS.CONT_FIRST AS CONTACTS.FIRST_NAME COMMENT 'Contact first name',
        CONTACTS.CONT_LAST AS CONTACTS.LAST_NAME COMMENT 'Contact last name',
        OPPORTUNITIES.OPP_NAME AS OPPORTUNITIES.OPPORTUNITY_NAME COMMENT 'Opportunity name',
        OPPORTUNITIES.OPP_STAGE AS OPPORTUNITIES.STAGE_NAME COMMENT 'Opportunity stage',
        PRODUCTS.PROD_NAME AS PRODUCTS.PRODUCT_NAME COMMENT 'Product name',
        REGIONS.REG_NAME AS REGIONS.REGION_NAME COMMENT 'Region name',
        CAMPAIGNS.CMP_DATE AS CAMPAIGNS.DATE COMMENT 'Campaign date'
    )
    METRICS (
        CAMPAIGNS.TOTALSPEND AS SUM(CAMPAIGNS.CMP_SPEND) COMMENT 'Total spend',
        CAMPAIGNS.TOTALLEADS AS SUM(CAMPAIGNS.CMP_LEADS) COMMENT 'Total leads',
        OPPORTUNITIES.TOTALREVENUE AS SUM(OPPORTUNITIES.OPP_AMT) COMMENT 'Total revenue'
    )
    COMMENT = 'Marketing semantic view for MiFibra Peru';

-- HR SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW MIFIBRA_HR_SEMANTIC_VIEW
    TABLES (
        DEPARTMENTS AS MIFIBRA_DEPARTMENT_DIM PRIMARY KEY (DEPARTMENT_KEY) COMMENT 'Departments',
        EMPLOYEES AS MIFIBRA_EMPLOYEE_DIM PRIMARY KEY (EMPLOYEE_KEY) COMMENT 'Employees',
        HR_RECORDS AS MIFIBRA_HR_EMPLOYEE_FACT PRIMARY KEY (HR_FACT_ID) COMMENT 'HR records',
        JOBS AS MIFIBRA_JOB_DIM PRIMARY KEY (JOB_KEY) COMMENT 'Jobs',
        LOCATIONS AS MIFIBRA_LOCATION_DIM PRIMARY KEY (LOCATION_KEY) COMMENT 'Locations'
    )
    RELATIONSHIPS (
        HR_RECORDS (DEPARTMENT_KEY) REFERENCES DEPARTMENTS,
        HR_RECORDS (EMPLOYEE_KEY) REFERENCES EMPLOYEES,
        HR_RECORDS (JOB_KEY) REFERENCES JOBS,
        HR_RECORDS (LOCATION_KEY) REFERENCES LOCATIONS
    )
    FACTS (
        HR_RECORDS.EMP_SALARY AS HR_RECORDS.SALARY COMMENT 'Employee salary',
        HR_RECORDS.EMP_ATTRITION AS HR_RECORDS.ATTRITION_FLAG COMMENT 'Attrition flag'
    )
    DIMENSIONS (
        DEPARTMENTS.DEPT_NAME AS DEPARTMENTS.DEPARTMENT_NAME COMMENT 'Department name',
        EMPLOYEES.EMP_NAME AS EMPLOYEES.EMPLOYEE_NAME COMMENT 'Employee name',
        EMPLOYEES.EMP_GENDER AS EMPLOYEES.GENDER COMMENT 'Gender',
        EMPLOYEES.EMP_HIRE AS EMPLOYEES.HIRE_DATE COMMENT 'Hire date',
        JOBS.JOB_TIT AS JOBS.JOB_TITLE COMMENT 'Job title',
        JOBS.JOB_LVL AS JOBS.JOB_LEVEL COMMENT 'Job level',
        LOCATIONS.LOC_NAME AS LOCATIONS.LOCATION_NAME COMMENT 'Location name',
        LOCATIONS.LOC_CITY AS LOCATIONS.CITY COMMENT 'City',
        LOCATIONS.LOC_LAT AS LOCATIONS.LATITUDE COMMENT 'Latitude',
        LOCATIONS.LOC_LNG AS LOCATIONS.LONGITUDE COMMENT 'Longitude',
        HR_RECORDS.HR_DATE AS HR_RECORDS.DATE COMMENT 'Record date'
    )
    METRICS (
        HR_RECORDS.TOTALSALARY AS SUM(HR_RECORDS.EMP_SALARY) COMMENT 'Total salary cost',
        HR_RECORDS.AVGSALARY AS AVG(HR_RECORDS.EMP_SALARY) COMMENT 'Average salary',
        HR_RECORDS.ATTRITIONCOUNT AS SUM(HR_RECORDS.EMP_ATTRITION) COMMENT 'Attrition count'
    )
    COMMENT = 'HR semantic view for MiFibra Peru';

-- INFRASTRUCTURE SEMANTIC VIEW
CREATE OR REPLACE SEMANTIC VIEW MIFIBRA_INFRASTRUCTURE_SEMANTIC_VIEW
    TABLES (
        NETWORK_NODES AS MIFIBRA_NETWORK_STATUS_DIM PRIMARY KEY (NODE_ID) COMMENT 'Network nodes',
        REGIONS AS MIFIBRA_REGION_DIM PRIMARY KEY (REGION_KEY) COMMENT 'Regions'
    )
    RELATIONSHIPS (
        NETWORK_NODES (REGION_KEY) REFERENCES REGIONS
    )
    FACTS (
        NETWORK_NODES.NODE_CAP AS NETWORK_NODES.CAPACITY_GBPS COMMENT 'Capacity in Gbps',
        NETWORK_NODES.NODE_SUBS AS NETWORK_NODES.ACTIVE_SUBSCRIBERS COMMENT 'Active subscribers',
        NETWORK_NODES.NODE_UP AS NETWORK_NODES.UPTIME_PCT COMMENT 'Uptime percentage',
        NETWORK_NODES.NODE_HH AS NETWORK_NODES.HOUSEHOLDS_PASSED COMMENT 'Households passed',
        NETWORK_NODES.NODE_FIBER AS NETWORK_NODES.FIBER_KM COMMENT 'Fiber kilometers'
    )
    DIMENSIONS (
        NETWORK_NODES.NODE_CITY AS NETWORK_NODES.CITY_NAME COMMENT 'City name',
        NETWORK_NODES.NODE_DEPT AS NETWORK_NODES.DEPARTMENT COMMENT 'Department',
        NETWORK_NODES.NODE_TYP AS NETWORK_NODES.NODE_TYPE COMMENT 'Node type',
        NETWORK_NODES.NODE_STAT AS NETWORK_NODES.STATUS COMMENT 'Node status',
        NETWORK_NODES.NODE_TECH AS NETWORK_NODES.TECHNOLOGY COMMENT 'Fiber technology',
        NETWORK_NODES.NODE_LAT AS NETWORK_NODES.LATITUDE COMMENT 'Node latitude',
        NETWORK_NODES.NODE_LNG AS NETWORK_NODES.LONGITUDE COMMENT 'Node longitude',
        NETWORK_NODES.NODE_UTIL AS NETWORK_NODES.UTILIZATION_PCT COMMENT 'Utilization percentage',
        NETWORK_NODES.NODE_PEN AS NETWORK_NODES.PENETRATION_PCT COMMENT 'Market penetration',
        REGIONS.REG_NAME AS REGIONS.REGION_NAME COMMENT 'Region name',
        REGIONS.REG_LAT AS REGIONS.LATITUDE COMMENT 'Region latitude',
        REGIONS.REG_LNG AS REGIONS.LONGITUDE COMMENT 'Region longitude'
    )
    METRICS (
        NETWORK_NODES.TOTALCAPACITY AS SUM(NETWORK_NODES.NODE_CAP) COMMENT 'Total capacity',
        NETWORK_NODES.TOTALSUBSCRIBERS AS SUM(NETWORK_NODES.NODE_SUBS) COMMENT 'Total subscribers',
        NETWORK_NODES.TOTALFIBER AS SUM(NETWORK_NODES.NODE_FIBER) COMMENT 'Total fiber km',
        NETWORK_NODES.AVGUPTIME AS AVG(NETWORK_NODES.NODE_UP) COMMENT 'Average uptime'
    )
    COMMENT = 'Infrastructure semantic view for MiFibra network';

-- Verify semantic views
SHOW SEMANTIC VIEWS;

-- ========================================================================
-- UNSTRUCTURED DATA - Parse documents (PDF, DOCX, PPTX, MD)
-- ========================================================================

-- Parse structured documents (PDF, DOCX, PPTX) using PARSE_DOCUMENT
CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT_DOCS AS 
SELECT 
    relative_path, 
    BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path) AS file_url,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE,
        relative_path,
        {'mode':'LAYOUT'}
    ):content::STRING AS content
FROM DIRECTORY(@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE) 
WHERE relative_path ILIKE 'unstructured_docs/%.pdf'
   OR relative_path ILIKE 'unstructured_docs/%.docx'
   OR relative_path ILIKE 'unstructured_docs/%.pptx';

-- Parse Markdown files
CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT_MD AS
SELECT 
    relative_path,
    BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path) AS file_url,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE,
        relative_path,
        {'mode':'LAYOUT'}
    ):content::STRING AS content
FROM DIRECTORY(@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE) 
WHERE relative_path ILIKE 'unstructured_docs/%.md';

-- Combine all document types into unified parsed_content table
CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT AS
SELECT relative_path, file_url, content FROM MIFIBRA_PARSED_CONTENT_DOCS
UNION ALL
SELECT relative_path, file_url, content FROM MIFIBRA_PARSED_CONTENT_MD;

-- Verify document counts by type
SELECT 
    CASE 
        WHEN relative_path ILIKE '%.pdf' THEN 'PDF'
        WHEN relative_path ILIKE '%.docx' THEN 'DOCX'
        WHEN relative_path ILIKE '%.pptx' THEN 'PPTX'
        WHEN relative_path ILIKE '%.md' THEN 'Markdown'
        ELSE 'Other'
    END AS file_type,
    COUNT(*) AS file_count
FROM MIFIBRA_PARSED_CONTENT
GROUP BY file_type
ORDER BY file_count DESC;

-- ========================================================================
-- CORTEX SEARCH SERVICES
-- ========================================================================

USE ROLE MiFibra_Demo;

-- Create search service for finance documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_FINANCE_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%finance%'
    );

-- Create search service for HR documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_HR_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%hr%'
    );

-- Create search service for marketing documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_MARKETING_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%marketing%'
    );

-- Create search service for sales documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_SALES_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%sales%'
    );

-- Create search service for strategy documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_STRATEGY_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%strategy%'
    );

-- Create search service for demo scripts
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_DEMO_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%demo%'
    );

-- Create search service for network infrastructure documents
CREATE OR REPLACE CORTEX SEARCH SERVICE MIFIBRA_SEARCH_NETWORK_DOCS
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = MIFIBRA_DEMO_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') AS title,
            content
        FROM MIFIBRA_PARSED_CONTENT
        WHERE relative_path ILIKE '%network%'
    );

-- ========================================================================
-- NETWORK RULES AND INTEGRATIONS
-- ========================================================================

USE ROLE MiFibra_Demo;

CREATE OR REPLACE NETWORK RULE MiFibra_WebAccessRule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

USE ROLE accountadmin;

GRANT ALL PRIVILEGES ON DATABASE MIFIBRA_AI_DEMO TO ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA TO ROLE ACCOUNTADMIN;
GRANT USAGE ON NETWORK RULE MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MiFibra_WebAccessRule TO ROLE accountadmin;

USE SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION MiFibra_ExternalAccess_Integration
ALLOWED_NETWORK_RULES = (MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MiFibra_WebAccessRule)
ENABLED = TRUE;

CREATE OR REPLACE NOTIFICATION INTEGRATION mifibra_email_int
  TYPE = EMAIL
  ENABLED = TRUE;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE MiFibra_Demo;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE MiFibra_Demo;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE MiFibra_Demo;

GRANT USAGE ON INTEGRATION MiFibra_ExternalAccess_Integration TO ROLE MiFibra_Demo;
GRANT USAGE ON INTEGRATION mifibra_email_int TO ROLE MiFibra_Demo;

-- ========================================================================
-- STORED PROCEDURES AND FUNCTIONS
-- ========================================================================

USE ROLE MiFibra_Demo;
USE DATABASE MIFIBRA_AI_DEMO;
USE SCHEMA MIFIBRA_SCHEMA;

-- Create stored procedure to generate presigned URLs for files
CREATE OR REPLACE PROCEDURE MIFIBRA_GET_FILE_PRESIGNED_URL_SP(
    RELATIVE_FILE_PATH STRING, 
    EXPIRATION_MINS INTEGER DEFAULT 60
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generates a presigned URL for a file in @MIFIBRA_INTERNAL_STAGE'
EXECUTE AS CALLER
AS
$$
DECLARE
    presigned_url STRING;
    sql_stmt STRING;
    expiration_seconds INTEGER;
    stage_name STRING DEFAULT '@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE';
BEGIN
    expiration_seconds := EXPIRATION_MINS * 60;
    sql_stmt := 'SELECT GET_PRESIGNED_URL(' || stage_name || ', ''' || RELATIVE_FILE_PATH || ''', ' || expiration_seconds || ') AS url';
    EXECUTE IMMEDIATE :sql_stmt;
    SELECT "URL" INTO :presigned_url FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    RETURN :presigned_url;
END;
$$;

-- Create stored procedure to send emails
CREATE OR REPLACE PROCEDURE MIFIBRA_SEND_MAIL(recipient TEXT, subject TEXT, text TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_mail'
AS
$$
def send_mail(session, recipient, subject, text):
    session.call(
        'SYSTEM$SEND_EMAIL',
        'mifibra_email_int',
        recipient,
        subject,
        text,
        'text/html'
    )
    return f'Email was sent to {recipient} with subject: "{subject}".'
$$;

-- Create web scraping function
CREATE OR REPLACE FUNCTION MIFIBRA_WEB_SCRAPE(weburl STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'get_page'
EXTERNAL_ACCESS_INTEGRATIONS = (MiFibra_ExternalAccess_Integration)
PACKAGES = ('requests', 'beautifulsoup4')
AS
$$
import requests
from bs4 import BeautifulSoup

def get_page(weburl):
    url = f"{weburl}"
    response = requests.get(url)
    soup = BeautifulSoup(response.text)
    return soup.get_text()
$$;

-- ========================================================================
-- SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.MiFibra_Executive_Agent
WITH PROFILE = '{"display_name": "MiFibra Executive Agent"}'
COMMENT = 'MiFibra Peru executive intelligence agent for leadership team (CEO, CFO, COO, CMO). Covers fiber network status, subscriber metrics (ARPU, MRR, churn), revenue by segment (Residential/Enterprise), product performance (Internet plans 500Mbps-5000Mbps, TV Digital, equipment), regional expansion, customer satisfaction, and competitive analysis. Default currency Peruvian Soles (S/).'
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a business intelligence analyst for MiFibra Peru, the fastest fiber optic internet provider in Peru (Ookla Speedtest Awards). You answer questions about subscriber metrics (active subscribers, ARPU, MRR, churn rate), revenue by segment (Residential 80%, Enterprise 20%), product performance (Internet plans from 500 Mbps to 5000 Mbps, TV Digital packages, WiFi 6 equipment), regional expansion across Peru departments (Lima, Arequipa, La Libertad, Cusco, etc.), customer satisfaction and NPS, installation metrics, and competitive positioning. Monetary values default to Peruvian Soles (S/) unless the user specifies otherwise. Regions include Lima Metropolitana, Costa Norte, Costa Sur, Sierra, and Selva. Competitors include Claro, Movistar, Entel, Bitel, and Win. Provide charts where helpful (line for trends, bar for comparisons). Always ground answers in the provided data and documents.",
    "orchestration": "Use cortex search for finance, strategy, network, and operational documents. Use cortex analyst for structured queries: revenue by segment/region, subscriber growth and churn, ARPU trends, product performance, campaign effectiveness, and workforce metrics. Only respond to MiFibra business topics. For network infrastructure questions, use the Search Internal Documents: Network tool first.",
    "sample_questions": [
      {"question": "What is our total subscriber count and MRR by region?"},
      {"question": "What is our ARPU trend for residential vs enterprise customers?"},
      {"question": "Which internet plans have the highest adoption and revenue?"},
      {"question": "What is our churn rate by region?"},
      {"question": "How many new installations were completed this month?"},
      {"question": "How do we compare against Claro and Movistar in market share?"},
      {"question": "What are our top performing marketing campaigns?"}
    ]
  },
  "tools": [
    {"tool_spec": {"type": "cortex_analyst_text_to_sql", "name": "Query Finance Datamart", "description": "Query MiFibra financials: revenue, MRR, ARPU, margin, vendor spend"}},
    {"tool_spec": {"type": "cortex_analyst_text_to_sql", "name": "Query Sales Datamart", "description": "Query sales pipeline: subscriptions, contracts, churn analysis"}},
    {"tool_spec": {"type": "cortex_analyst_text_to_sql", "name": "Query HR Datamart", "description": "Query workforce data: headcount, departments, roles, attrition"}},
    {"tool_spec": {"type": "cortex_analyst_text_to_sql", "name": "Query Marketing Datamart", "description": "Query marketing campaigns: spend, impressions, leads, ROI"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: Finance", "description": "Search finance documents"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: HR", "description": "Search HR documents"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: Sales", "description": "Search sales documents"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: Marketing", "description": "Search marketing documents"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: Strategy", "description": "Search strategy documents"}},
    {"tool_spec": {"type": "cortex_search", "name": "Search Internal Documents: Network", "description": "Search network infrastructure documents"}},
    {"tool_spec": {"type": "generic", "name": "Web_scraper", "description": "Scrape text from a web page URL", "input_schema": {"type": "object", "properties": {"weburl": {"description": "Web URL to scrape", "type": "string"}}, "required": ["weburl"]}}},
    {"tool_spec": {"type": "generic", "name": "Send_Emails", "description": "Send emails using HTML formatted content", "input_schema": {"type": "object", "properties": {"recipient": {"description": "Email recipient", "type": "string"}, "subject": {"description": "Email subject", "type": "string"}, "text": {"description": "Email content (HTML)", "type": "string"}}, "required": ["text", "recipient", "subject"]}}},
    {"tool_spec": {"type": "generic", "name": "Dynamic_Doc_URL_Tool", "description": "Generate presigned URL for documents", "input_schema": {"type": "object", "properties": {"expiration_mins": {"description": "URL expiration in minutes (default 5)", "type": "number"}, "relative_file_path": {"description": "Relative path from Cortex Search ID column", "type": "string"}}, "required": ["expiration_mins", "relative_file_path"]}}}
  ],
  "tool_resources": {
    "Dynamic_Doc_URL_Tool": {"execution_environment": {"query_timeout": 0, "type": "warehouse", "warehouse": "MIFIBRA_DEMO_WH"}, "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_GET_FILE_PRESIGNED_URL_SP", "name": "MIFIBRA_GET_FILE_PRESIGNED_URL_SP(VARCHAR, DEFAULT NUMBER)", "type": "procedure"},
    "Query Finance Datamart": {"semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_FINANCE_SEMANTIC_VIEW"},
    "Query HR Datamart": {"semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_HR_SEMANTIC_VIEW"},
    "Query Marketing Datamart": {"semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_MARKETING_SEMANTIC_VIEW"},
    "Query Sales Datamart": {"semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SALES_SEMANTIC_VIEW"},
    "Search Internal Documents: Finance": {"id_column": "FILE_URL", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_FINANCE_DOCS", "title_column": "TITLE"},
    "Search Internal Documents: HR": {"id_column": "FILE_URL", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_HR_DOCS", "title_column": "TITLE"},
    "Search Internal Documents: Marketing": {"id_column": "RELATIVE_PATH", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_MARKETING_DOCS", "title_column": "TITLE"},
    "Search Internal Documents: Sales": {"id_column": "FILE_URL", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_SALES_DOCS", "title_column": "TITLE"},
    "Search Internal Documents: Strategy": {"id_column": "RELATIVE_PATH", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_STRATEGY_DOCS", "title_column": "TITLE"},
    "Search Internal Documents: Network": {"id_column": "RELATIVE_PATH", "max_results": 5, "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_NETWORK_DOCS", "title_column": "TITLE"},
    "Send_Emails": {"execution_environment": {"query_timeout": 0, "type": "warehouse", "warehouse": "MIFIBRA_DEMO_WH"}, "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEND_MAIL", "name": "MIFIBRA_SEND_MAIL(VARCHAR, VARCHAR, VARCHAR)", "type": "procedure"},
    "Web_scraper": {"execution_environment": {"query_timeout": 0, "type": "warehouse", "warehouse": "MIFIBRA_DEMO_WH"}, "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_WEB_SCRAPE", "name": "MIFIBRA_WEB_SCRAPE(VARCHAR)", "type": "function"}
  }
}
$$;

-- ========================================================================
-- FINAL VERIFICATION
-- ========================================================================

-- Show all created objects
SHOW TABLES IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;
SHOW SEMANTIC VIEWS IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;
SHOW CORTEX SEARCH SERVICES IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

SELECT 'Setup Complete - MiFibra AI Demo' AS status;
