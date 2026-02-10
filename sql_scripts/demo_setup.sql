


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


    create or replace role MiFibra_Demo;


    SET current_user_name = CURRENT_USER();
    
    -- Step 2: Use the variable to grant the role
    GRANT ROLE MiFibra_Demo TO USER IDENTIFIER($current_user_name);
    GRANT CREATE DATABASE ON ACCOUNT TO ROLE MiFibra_Demo;
    
    -- Create a dedicated warehouse for the demo with auto-suspend/resume
    CREATE OR REPLACE WAREHOUSE MiFibra_Demo_WH 
        WITH WAREHOUSE_SIZE = 'XSMALL'
        AUTO_SUSPEND = 300
        AUTO_RESUME = TRUE;


    -- Grant usage on warehouse to admin role
    GRANT USAGE ON WAREHOUSE MIFIBRA_DEMO_WH TO ROLE MiFibra_Demo;


  -- Alter current user's default role and warehouse to the ones used here
    ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = MiFibra_Demo;
    ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = MiFibra_Demo_WH;
    

    -- Switch to MiFibra_Demo role to create demo objects
    use role MiFibra_Demo;
  
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


use role accountadmin;
    -- Create API Integration for GitHub (public repository access)
    CREATE OR REPLACE API INTEGRATION mifibra_git_api_integration
        API_PROVIDER = git_https_api
        API_ALLOWED_PREFIXES = ('https://github.com/pmjose/')
        ENABLED = TRUE;


GRANT USAGE ON INTEGRATION MIFIBRA_GIT_API_INTEGRATION TO ROLE MiFibra_Demo;


use role MiFibra_Demo;
    -- Create Git repository integration for the Eutelsat UK demo repository
    CREATE OR REPLACE GIT REPOSITORY MIFIBRA_AI_DEMO_REPO
        API_INTEGRATION = mifibra_git_api_integration
        ORIGIN = 'https://github.com/pmjose/MiFibra.git';

    -- Create internal stage for copied data files
    CREATE OR REPLACE STAGE MIFIBRA_INTERNAL_STAGE
        FILE_FORMAT = MIFIBRA_CSV_FORMAT
        COMMENT = 'Internal stage for copied demo data files'
        DIRECTORY = ( ENABLE = TRUE)
        ENCRYPTION = (   TYPE = 'SNOWFLAKE_SSE');

    ALTER GIT REPOSITORY MIFIBRA_AI_DEMO_REPO FETCH;

    -- ========================================================================
    -- COPY UNSTRUCTURED DOCS FROM GIT TO INTERNAL STAGE
    -- (Required for PARSE_DOCUMENT - CSV data loads directly from Git)
    -- ========================================================================

    -- Copy unstructured docs (PDF, DOCX, etc.) to internal stage for parsing
    COPY FILES
    INTO @MIFIBRA_INTERNAL_STAGE/unstructured_docs/
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/unstructured_docs/;

    -- Refresh stage directory
    ALTER STAGE MIFIBRA_INTERNAL_STAGE refresh;

  

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
        state VARCHAR(10),
        zip VARCHAR(20)
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
        contract_reference VARCHAR(100),
        CONSTRAINT fk_approver FOREIGN KEY (approver_id) REFERENCES MIFIBRA_EMPLOYEE_DIM(employee_key)
    ) COMMENT = 'Financial transactions with compliance tracking. approval_status should be Approved/Pending/Rejected. procurement_method should be RFP/Quotes/Emergency/Contract';

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
        billing_state VARCHAR(10),
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
        opportunity_id VARCHAR(20) NOT NULL,
        account_id VARCHAR(20) NOT NULL,
        first_name VARCHAR(100),
        last_name VARCHAR(100),
        email VARCHAR(200),
        phone VARCHAR(50),
        title VARCHAR(100),
        department VARCHAR(100),
        lead_source VARCHAR(100),
        campaign_no INT,
        created_date DATE
    );

    -- ========================================================================
    -- LOAD DIMENSION DATA FROM INTERNAL STAGE
    -- ========================================================================

    -- Load Product Category Dimension
    COPY INTO MIFIBRA_PRODUCT_CATEGORY_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/product_category_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Product Dimension
    COPY INTO MIFIBRA_PRODUCT_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/product_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Vendor Dimension
    COPY INTO MIFIBRA_VENDOR_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/vendor_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Customer Dimension
    COPY INTO MIFIBRA_CUSTOMER_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/customer_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Account Dimension
    COPY INTO MIFIBRA_ACCOUNT_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/account_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Department Dimension
    COPY INTO MIFIBRA_DEPARTMENT_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/department_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Region Dimension
    COPY INTO MIFIBRA_REGION_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/region_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Sales Rep Dimension
    COPY INTO MIFIBRA_SALES_REP_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/sales_rep_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Campaign Dimension
    COPY INTO MIFIBRA_CAMPAIGN_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/campaign_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Channel Dimension
    COPY INTO MIFIBRA_CHANNEL_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/channel_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Employee Dimension
    COPY INTO MIFIBRA_EMPLOYEE_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/employee_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Job Dimension
    COPY INTO MIFIBRA_JOB_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/job_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Location Dimension
    COPY INTO MIFIBRA_LOCATION_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/location_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Network Status Dimension
    COPY INTO MIFIBRA_NETWORK_STATUS_DIM
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/network_status_dim.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- ========================================================================
    -- LOAD FACT DATA FROM INTERNAL STAGE
    -- ========================================================================

    -- Load Sales Fact
    COPY INTO MIFIBRA_SALES_FACT
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/sales_fact.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Finance Transactions
    COPY INTO MIFIBRA_FINANCE_TRANSACTIONS
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/finance_transactions.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Marketing Campaign Fact
    COPY INTO MIFIBRA_MARKETING_CAMPAIGN_FACT
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/marketing_campaign_fact.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load HR Employee Fact
    COPY INTO MIFIBRA_HR_EMPLOYEE_FACT
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/hr_employee_fact.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- ========================================================================
    -- LOAD SALESFORCE DATA FROM INTERNAL STAGE
    -- ========================================================================

    -- Load Salesforce Accounts
    COPY INTO MIFIBRA_SF_ACCOUNTS
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/sf_accounts.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Salesforce Opportunities
    COPY INTO MIFIBRA_SF_OPPORTUNITIES
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/sf_opportunities.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- Load Salesforce Contacts
    COPY INTO MIFIBRA_SF_CONTACTS
    FROM @MIFIBRA_AI_DEMO_REPO/branches/main/demo_data/sf_contacts.csv
    FILE_FORMAT = MIFIBRA_CSV_FORMAT
    ON_ERROR = 'CONTINUE';

    -- ========================================================================
    -- VERIFICATION
    -- ========================================================================

    -- Verify Git integration and file copy
    SHOW GIT REPOSITORIES;
  -- SELECT 'Internal Stage Files' as stage_type, COUNT(*) as file_count FROM (LS @MIFIBRA_INTERNAL_STAGE);

    -- Verify data loads
    SELECT 'DIMENSION TABLES' as category, '' as table_name, NULL as row_count
    UNION ALL
    SELECT '', 'MIFIBRA_PRODUCT_CATEGORY_DIM', COUNT(*) FROM MIFIBRA_PRODUCT_CATEGORY_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_PRODUCT_DIM', COUNT(*) FROM MIFIBRA_PRODUCT_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_VENDOR_DIM', COUNT(*) FROM MIFIBRA_VENDOR_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_CUSTOMER_DIM', COUNT(*) FROM MIFIBRA_CUSTOMER_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_ACCOUNT_DIM', COUNT(*) FROM MIFIBRA_ACCOUNT_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_DEPARTMENT_DIM', COUNT(*) FROM MIFIBRA_DEPARTMENT_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_REGION_DIM', COUNT(*) FROM MIFIBRA_REGION_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_SALES_REP_DIM', COUNT(*) FROM MIFIBRA_SALES_REP_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_CAMPAIGN_DIM', COUNT(*) FROM MIFIBRA_CAMPAIGN_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_CHANNEL_DIM', COUNT(*) FROM MIFIBRA_CHANNEL_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_EMPLOYEE_DIM', COUNT(*) FROM MIFIBRA_EMPLOYEE_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_JOB_DIM', COUNT(*) FROM MIFIBRA_JOB_DIM
    UNION ALL
    SELECT '', 'MIFIBRA_LOCATION_DIM', COUNT(*) FROM MIFIBRA_LOCATION_DIM
    UNION ALL
    SELECT '', '', NULL
    UNION ALL
    SELECT 'FACT TABLES', '', NULL
    UNION ALL
    SELECT '', 'MIFIBRA_SALES_FACT', COUNT(*) FROM MIFIBRA_SALES_FACT
    UNION ALL
    SELECT '', 'MIFIBRA_FINANCE_TRANSACTIONS', COUNT(*) FROM MIFIBRA_FINANCE_TRANSACTIONS
    UNION ALL
    SELECT '', 'MIFIBRA_MARKETING_CAMPAIGN_FACT', COUNT(*) FROM MIFIBRA_MARKETING_CAMPAIGN_FACT
    UNION ALL
    SELECT '', 'MIFIBRA_HR_EMPLOYEE_FACT', COUNT(*) FROM MIFIBRA_HR_EMPLOYEE_FACT
    UNION ALL
    SELECT '', '', NULL
    UNION ALL
    SELECT 'SALESFORCE TABLES', '', NULL
    UNION ALL
    SELECT '', 'MIFIBRA_SF_ACCOUNTS', COUNT(*) FROM MIFIBRA_SF_ACCOUNTS
    UNION ALL
    SELECT '', 'MIFIBRA_SF_OPPORTUNITIES', COUNT(*) FROM MIFIBRA_SF_OPPORTUNITIES
    UNION ALL
    SELECT '', 'MIFIBRA_SF_CONTACTS', COUNT(*) FROM MIFIBRA_SF_CONTACTS;

    -- Show all tables
    SHOW TABLES IN SCHEMA MIFIBRA_SCHEMA; 




  -- ========================================================================
  -- Snowflake AI Demo - Semantic Views for Cortex Analyst
  -- Creates business unit-specific semantic views for natural language queries
  -- Based on: https://docs.snowflake.com/en/user-guide/views-semantic/sql
  -- ========================================================================
  USE ROLE MiFibra_Demo;
  USE DATABASE MIFIBRA_AI_DEMO;
  USE SCHEMA MIFIBRA_SCHEMA;

  -- ========================================================================
  -- FINANCE SEMANTIC VIEW
  -- ========================================================================

create or replace semantic view MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_FINANCE_SEMANTIC_VIEW
    tables (
        TRANSACTIONS as MIFIBRA_FINANCE_TRANSACTIONS primary key (TRANSACTION_ID) with synonyms=('finance transactions','financial data') comment='All financial transactions across departments',
        ACCOUNTS as MIFIBRA_ACCOUNT_DIM primary key (ACCOUNT_KEY) with synonyms=('chart of accounts','account types') comment='Account dimension for financial categorization',
        DEPARTMENTS as MIFIBRA_DEPARTMENT_DIM primary key (DEPARTMENT_KEY) with synonyms=('business units','departments') comment='Department dimension for cost center analysis',
        VENDORS as MIFIBRA_VENDOR_DIM primary key (VENDOR_KEY) with synonyms=('suppliers','vendors') comment='Vendor information for spend analysis',
        PRODUCTS as MIFIBRA_PRODUCT_DIM primary key (PRODUCT_KEY) with synonyms=('products','items') comment='Product dimension for transaction analysis',
        CUSTOMERS as MIFIBRA_CUSTOMER_DIM primary key (CUSTOMER_KEY) with synonyms=('clients','customers') comment='Customer dimension for revenue analysis'
    )
    relationships (
        TRANSACTIONS_TO_ACCOUNTS as TRANSACTIONS(ACCOUNT_KEY) references ACCOUNTS(ACCOUNT_KEY),
        TRANSACTIONS_TO_DEPARTMENTS as TRANSACTIONS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
        TRANSACTIONS_TO_VENDORS as TRANSACTIONS(VENDOR_KEY) references VENDORS(VENDOR_KEY),
        TRANSACTIONS_TO_PRODUCTS as TRANSACTIONS(PRODUCT_KEY) references PRODUCTS(PRODUCT_KEY),
        TRANSACTIONS_TO_CUSTOMERS as TRANSACTIONS(CUSTOMER_KEY) references CUSTOMERS(CUSTOMER_KEY)
    )
    facts (
        TRANSACTIONS.TRANSACTION_AMOUNT as amount comment='Transaction amount in Peruvian Soles (S/)',
        TRANSACTIONS.TRANSACTION_RECORD as 1 comment='Count of transactions'
    )
    dimensions (
        TRANSACTIONS.TRANSACTION_DATE as date with synonyms=('date','transaction date') comment='Date of the financial transaction',
        TRANSACTIONS.TRANSACTION_MONTH as MONTH(date) comment='Month of the transaction',
        TRANSACTIONS.TRANSACTION_YEAR as YEAR(date) comment='Year of the transaction',
        ACCOUNTS.ACCOUNT_NAME as account_name with synonyms=('account','account type') comment='Name of the account',
        ACCOUNTS.ACCOUNT_TYPE as account_type with synonyms=('type','category') comment='Type of account (Income/Expense)',
        DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','business unit') comment='Name of the department',
        VENDORS.VENDOR_NAME as vendor_name with synonyms=('vendor','supplier') comment='Name of the vendor',
        PRODUCTS.PRODUCT_NAME as product_name with synonyms=('product','item') comment='Name of the product',
        CUSTOMERS.CUSTOMER_NAME as customer_name with synonyms=('customer','client') comment='Name of the customer',
        CUSTOMERS.INDUSTRY as INDUSTRY with synonyms=('industry','customer industry','sector') comment='Customer industry sector',
        CUSTOMERS.VERTICAL as VERTICAL with synonyms=('vertical','segment','customer segment') comment='Customer vertical/segment (SMB/Enterprise/Public Sector/Partner)',
        CUSTOMERS.LATITUDE as CUSTOMER_LATITUDE with synonyms=('customer lat','customer latitude') comment='Customer location latitude (WGS84)',
        CUSTOMERS.LONGITUDE as CUSTOMER_LONGITUDE with synonyms=('customer long','customer longitude') comment='Customer location longitude (WGS84)',
        CUSTOMERS.CITY as CUSTOMER_CITY with synonyms=('customer city') comment='Customer city',
        CUSTOMERS.COUNTY as CUSTOMER_DEPARTMENT with synonyms=('customer department') comment='Customer department (Peru region)',
        CUSTOMERS.LATITUDE as CUSTOMER_LATITUDE with synonyms=('customer lat','customer latitude') comment='Customer location latitude (WGS84)',
        CUSTOMERS.LONGITUDE as CUSTOMER_LONGITUDE with synonyms=('customer long','customer longitude') comment='Customer location longitude (WGS84)',
        CUSTOMERS.CITY as CUSTOMER_CITY with synonyms=('customer city','city') comment='Customer city',
        CUSTOMERS.COUNTY as CUSTOMER_DEPARTMENT with synonyms=('customer department','department') comment='Customer department (Peru administrative region)',
        TRANSACTIONS.APPROVAL_STATUS as approval_status with synonyms=('approval','status','approval state') comment='Transaction approval status (Approved/Pending/Rejected)',
        TRANSACTIONS.PROCUREMENT_METHOD as procurement_method with synonyms=('procurement','method','purchase method') comment='Method of procurement (RFP/Quotes/Emergency/Contract)',
        TRANSACTIONS.APPROVER_ID as approver_id with synonyms=('approver','approver employee id') comment='Employee ID of the approver from HR',
        TRANSACTIONS.APPROVAL_DATE as approval_date with synonyms=('approved date','date approved') comment='Date when transaction was approved',
        TRANSACTIONS.PURCHASE_ORDER_NUMBER as purchase_order_number with synonyms=('PO number','PO','purchase order') comment='Purchase order number for tracking',
        TRANSACTIONS.CONTRACT_REFERENCE as contract_reference with synonyms=('contract','contract number','contract ref') comment='Reference to related contract'
    )
    metrics (
        TRANSACTIONS.AVERAGE_AMOUNT as AVG(transactions.amount) comment='Average transaction amount',
        TRANSACTIONS.TOTAL_AMOUNT as SUM(transactions.amount) comment='Total transaction amount',
        TRANSACTIONS.TOTAL_TRANSACTIONS as COUNT(transactions.transaction_record) comment='Total number of transactions'
    )
    comment='Semantic view for financial analysis and reporting';



  -- ========================================================================
  -- SALES SEMANTIC VIEW
  -- ========================================================================

create or replace semantic view MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SALES_SEMANTIC_VIEW
  tables (
    CUSTOMERS as MIFIBRA_CUSTOMER_DIM primary key (CUSTOMER_KEY) with synonyms=('clients','customers','accounts') comment='Customer information for sales analysis',
    PRODUCTS as MIFIBRA_PRODUCT_DIM primary key (PRODUCT_KEY) with synonyms=('products','items','SKUs') comment='Product catalog for sales analysis',
    MIFIBRA_PRODUCT_CATEGORY_DIM primary key (CATEGORY_KEY),
    REGIONS as MIFIBRA_REGION_DIM primary key (REGION_KEY) with synonyms=('territories','regions','areas') comment='Regional information for territory analysis',
    SALES as MIFIBRA_SALES_FACT primary key (SALE_ID) with synonyms=('sales transactions','sales data') comment='All sales transactions and deals',
    SALES_REPS as MIFIBRA_SALES_REP_DIM primary key (SALES_REP_KEY) with synonyms=('sales representatives','reps','salespeople') comment='Sales representative information',
    VENDORS as MIFIBRA_VENDOR_DIM primary key (VENDOR_KEY) with synonyms=('suppliers','vendors') comment='Vendor information for supply chain analysis'
  )
  relationships (
    PRODUCT_TO_CATEGORY as PRODUCTS(CATEGORY_KEY) references MIFIBRA_PRODUCT_CATEGORY_DIM(CATEGORY_KEY),
    SALES_TO_CUSTOMERS as SALES(CUSTOMER_KEY) references CUSTOMERS(CUSTOMER_KEY),
    SALES_TO_PRODUCTS as SALES(PRODUCT_KEY) references PRODUCTS(PRODUCT_KEY),
    SALES_TO_REGIONS as SALES(REGION_KEY) references REGIONS(REGION_KEY),
    SALES_TO_REPS as SALES(SALES_REP_KEY) references SALES_REPS(SALES_REP_KEY),
    SALES_TO_VENDORS as SALES(VENDOR_KEY) references VENDORS(VENDOR_KEY)
  )
  facts (
    SALES.SALE_AMOUNT as amount comment='Sale amount in Peruvian Soles (S/)',
    SALES.SALE_RECORD as 1 comment='Count of sales transactions',
    SALES.UNITS_SOLD as units comment='Number of units sold'
  )
  dimensions (
    CUSTOMERS.INDUSTRY as INDUSTRY with synonyms=('industry','customer type','customer industry') comment='Customer industry sector',
    CUSTOMERS.CUSTOMER_KEY as CUSTOMER_KEY,
    CUSTOMERS.CUSTOMER_NAME as customer_name with synonyms=('customer','client','account') comment='Name of the customer',
    PRODUCTS.CATEGORY_KEY as CATEGORY_KEY with synonyms=('category_id','product_category','category_code','classification_key','group_key','product_group_id') comment='Unique identifier for the product category.',
    PRODUCTS.PRODUCT_KEY as PRODUCT_KEY,
    PRODUCTS.PRODUCT_NAME as product_name with synonyms=('product','item') comment='Name of the product',
    PRODUCT_CATEGORY_DIM.CATEGORY_KEY as CATEGORY_KEY with synonyms=('category_id','category_code','product_category_number','category_identifier','classification_key') comment='Unique identifier for a product category.',
    MIFIBRA_PRODUCT_CATEGORY_DIM.CATEGORY_NAME as CATEGORY_NAME with synonyms=('category_title','product_group','classification_name','category_label','product_category_description') comment='The category to which a product belongs, such as electronics, clothing, or software as a service.',
    MIFIBRA_PRODUCT_CATEGORY_DIM.VERTICAL as VERTICAL with synonyms=('industry','sector','market','category_group','business_area','domain') comment='The industry or sector in which a product is categorized, such as retail, technology, or manufacturing.',
    REGIONS.REGION_KEY as REGION_KEY,
    REGIONS.REGION_NAME as region_name with synonyms=('region','territory','area') comment='Name of the region',
    REGIONS.LATITUDE as REGION_LATITUDE with synonyms=('region lat','region latitude') comment='Region center latitude (WGS84)',
    REGIONS.LONGITUDE as REGION_LONGITUDE with synonyms=('region long','region longitude') comment='Region center longitude (WGS84)',
    REGIONS.CAPITAL_CITY as REGION_CAPITAL with synonyms=('capital','regional capital') comment='Capital city of the region',
    REGIONS.AREA_KM2 as REGION_AREA_KM2 with synonyms=('area','region size','square kilometers') comment='Region area in square kilometers',
    SALES.CUSTOMER_KEY as CUSTOMER_KEY,
    SALES.PRODUCT_KEY as PRODUCT_KEY,
    SALES.REGION_KEY as REGION_KEY,
    SALES.SALES_REP_KEY as SALES_REP_KEY,
    SALES.SALE_DATE as date with synonyms=('date','sale date','transaction date') comment='Date of the sale',
    SALES.SALE_ID as SALE_ID,
    SALES.SALE_MONTH as MONTH(date) comment='Month of the sale',
    SALES.SALE_YEAR as YEAR(date) comment='Year of the sale',
    SALES.VENDOR_KEY as VENDOR_KEY,
    SALES_REPS.SALES_REP_KEY as SALES_REP_KEY,
    SALES_REPS.SALES_REP_NAME as REP_NAME with synonyms=('sales rep','representative','salesperson') comment='Name of the sales representative',
    VENDORS.VENDOR_KEY as VENDOR_KEY,
    VENDORS.VENDOR_NAME as vendor_name with synonyms=('vendor','supplier','provider') comment='Name of the vendor'
  )
  metrics (
    SALES.AVERAGE_DEAL_SIZE as AVG(sales.amount) comment='Average deal size',
    SALES.AVERAGE_UNITS_PER_SALE as AVG(sales.units) comment='Average units per sale',
    SALES.TOTAL_DEALS as COUNT(sales.sale_record) comment='Total number of deals',
    SALES.TOTAL_REVENUE as SUM(sales.amount) comment='Total sales revenue',
    SALES.TOTAL_UNITS as SUM(sales.units) comment='Total units sold'
  )
  comment='Semantic view for MiFibra Peru fiber optic ISP sales analysis'
  with extension (CA='{"tables":[{"name":"CUSTOMERS","dimensions":[{"name":"CUSTOMER_KEY"},{"name":"CUSTOMER_NAME","sample_values":["Banco de Credito del Peru","Maria Quispe Huaman","Jose Garcia Rodriguez","Wong","Universidad de Lima"]},{"name":"INDUSTRY","sample_values":["Banking","Retail","Education","Healthcare","Residential","Mining","Hospitality"]}]},{"name":"PRODUCTS","dimensions":[{"name":"CATEGORY_KEY","unique":false},{"name":"PRODUCT_KEY"},{"name":"PRODUCT_NAME","sample_values":["Internet Hogar 500 Mbps","Internet Hogar 5000 Mbps","Duo 1500 Mbps + MiFibra TvGo + L1MAX","Empresas Enterprise 5000 Mbps","Router WiFi 6 Ultra Velocidad"]}]},{"name":"PRODUCT_CATEGORY_DIM","dimensions":[{"name":"CATEGORY_KEY","sample_values":["1","2","3","4","5","6","7","8","9"]},{"name":"CATEGORY_NAME","sample_values":["Internet Hogar","Duos Internet + TV","Internet Empresas","TV Digital","Equipamiento","Servicios Adicionales","Servicios","Seguridad","Promociones"]},{"name":"VERTICAL","sample_values":["Residential","Enterprise","All"]}]},{"name":"REGIONS","dimensions":[{"name":"REGION_KEY"},{"name":"REGION_NAME","sample_values":["Lima","Arequipa","La Libertad","Cusco","Piura","Lambayeque"]}]},{"name":"SALES","dimensions":[{"name":"CUSTOMER_KEY"},{"name":"PRODUCT_KEY"},{"name":"REGION_KEY"},{"name":"SALES_REP_KEY"},{"name":"SALE_DATE","sample_values":["2024-01-01","2024-06-15","2024-12-01"]},{"name":"SALE_ID"},{"name":"SALE_MONTH"},{"name":"SALE_YEAR"},{"name":"VENDOR_KEY"}],"facts":[{"name":"SALE_AMOUNT"},{"name":"SALE_RECORD"},{"name":"UNITS_SOLD"}],"metrics":[{"name":"AVERAGE_DEAL_SIZE"},{"name":"AVERAGE_UNITS_PER_SALE"},{"name":"TOTAL_DEALS"},{"name":"TOTAL_REVENUE"},{"name":"TOTAL_UNITS"}]},{"name":"SALES_REPS","dimensions":[{"name":"SALES_REP_KEY"},{"name":"SALES_REP_NAME","sample_values":["Carlos Garcia Mendoza","Maria Rodriguez Torres","Juan Quispe Huaman"]}]},{"name":"VENDORS","dimensions":[{"name":"VENDOR_KEY"},{"name":"VENDOR_NAME","sample_values":["Huawei Peru","Furukawa Electric LatAm","Nokia Peru","L1MAX Peru","Claro Peru"]}]}]}'); UK","Cisco UK","Amazon Web Services UK","BT Openreach","8x8 UK"]}]}],"relationships":[{"name":"PRODUCT_TO_CATEGORY"},{"name":"SALES_TO_CUSTOMERS","relationship_type":"many_to_one"},{"name":"SALES_TO_PRODUCTS","relationship_type":"many_to_one"},{"name":"SALES_TO_REGIONS","relationship_type":"many_to_one"},{"name":"SALES_TO_REPS","relationship_type":"many_to_one"},{"name":"SALES_TO_VENDORS","relationship_type":"many_to_one"}]}');


-- ========================================================================
  -- MARKETING SEMANTIC VIEW
  -- ========================================================================
create or replace semantic view MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_MARKETING_SEMANTIC_VIEW
  tables (
    ACCOUNTS as MIFIBRA_SF_ACCOUNTS primary key (ACCOUNT_ID) with synonyms=('customers','accounts','clients') comment='Customer account information for revenue analysis',
    CAMPAIGNS as MIFIBRA_MARKETING_CAMPAIGN_FACT primary key (CAMPAIGN_FACT_ID) with synonyms=('marketing campaigns','campaign data') comment='Marketing campaign performance data',
    CAMPAIGN_DETAILS as MIFIBRA_CAMPAIGN_DIM primary key (CAMPAIGN_KEY) with synonyms=('campaign info','campaign details') comment='Campaign dimension with objectives and names',
    CHANNELS as MIFIBRA_CHANNEL_DIM primary key (CHANNEL_KEY) with synonyms=('marketing channels','channels') comment='Marketing channel information',
    CONTACTS as MIFIBRA_SF_CONTACTS primary key (CONTACT_ID) with synonyms=('leads','contacts','prospects') comment='Contact records generated from marketing campaigns',
    CONTACTS_FOR_OPPORTUNITIES as MIFIBRA_SF_CONTACTS primary key (CONTACT_ID) with synonyms=('opportunity contacts') comment='Contact records generated from marketing campaigns, specifically for opportunities, not leads',
    OPPORTUNITIES as MIFIBRA_SF_OPPORTUNITIES primary key (OPPORTUNITY_ID) with synonyms=('deals','opportunities','sales pipeline') comment='Sales opportunities and revenue data',
    PRODUCTS as MIFIBRA_PRODUCT_DIM primary key (PRODUCT_KEY) with synonyms=('products','items') comment='Product dimension for campaign-specific analysis',
    REGIONS as MIFIBRA_REGION_DIM primary key (REGION_KEY) with synonyms=('territories','regions','markets') comment='Regional information for campaign analysis'
  )
  relationships (
    CAMPAIGNS_TO_CHANNELS as CAMPAIGNS(CHANNEL_KEY) references CHANNELS(CHANNEL_KEY),
    CAMPAIGNS_TO_DETAILS as CAMPAIGNS(CAMPAIGN_KEY) references CAMPAIGN_DETAILS(CAMPAIGN_KEY),
    CAMPAIGNS_TO_PRODUCTS as CAMPAIGNS(PRODUCT_KEY) references PRODUCTS(PRODUCT_KEY),
    CAMPAIGNS_TO_REGIONS as CAMPAIGNS(REGION_KEY) references REGIONS(REGION_KEY),
    CONTACTS_TO_ACCOUNTS as CONTACTS(ACCOUNT_ID) references ACCOUNTS(ACCOUNT_ID),
    CONTACTS_TO_CAMPAIGNS as CONTACTS(CAMPAIGN_NO) references CAMPAIGNS(CAMPAIGN_FACT_ID),
    CONTACTS_TO_OPPORTUNITIES as CONTACTS_FOR_OPPORTUNITIES(OPPORTUNITY_ID) references OPPORTUNITIES(OPPORTUNITY_ID),
    OPPORTUNITIES_TO_ACCOUNTS as OPPORTUNITIES(ACCOUNT_ID) references ACCOUNTS(ACCOUNT_ID),
    OPPORTUNITIES_TO_CAMPAIGNS as OPPORTUNITIES(CAMPAIGN_ID) references CAMPAIGNS(CAMPAIGN_FACT_ID)
  )
  facts (
    PUBLIC CAMPAIGNS.CAMPAIGN_RECORD as 1 comment='Count of campaign activities',
    PUBLIC CAMPAIGNS.CAMPAIGN_SPEND as spend comment='Marketing spend in Peruvian Soles (S/)',
    PUBLIC CAMPAIGNS.IMPRESSIONS as IMPRESSIONS comment='Number of impressions',
    PUBLIC CAMPAIGNS.LEADS_GENERATED as LEADS_GENERATED comment='Number of leads generated',
    PUBLIC CONTACTS.CONTACT_RECORD as 1 comment='Count of contacts generated',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_RECORD as 1 comment='Count of opportunities created',
    PUBLIC OPPORTUNITIES.REVENUE as AMOUNT comment='Opportunity revenue in Peruvian Soles (S/)'
  )
  dimensions (
    PUBLIC ACCOUNTS.ACCOUNT_ID as ACCOUNT_ID,
    PUBLIC ACCOUNTS.ACCOUNT_NAME as ACCOUNT_NAME with synonyms=('customer name','client name','company') comment='Name of the customer account',
    PUBLIC ACCOUNTS.ACCOUNT_TYPE as ACCOUNT_TYPE with synonyms=('customer type','account category') comment='Type of customer account',
    PUBLIC ACCOUNTS.ANNUAL_REVENUE as ANNUAL_REVENUE with synonyms=('customer revenue','company revenue') comment='Customer annual revenue',
    PUBLIC ACCOUNTS.EMPLOYEES as EMPLOYEES with synonyms=('company size','employee count') comment='Number of employees at customer',
    PUBLIC ACCOUNTS.INDUSTRY as INDUSTRY with synonyms=('industry','sector') comment='Customer industry',
    PUBLIC ACCOUNTS.SALES_CUSTOMER_KEY as CUSTOMER_KEY with synonyms=('Customer No','Customer ID') comment='This is the customer key thank links the Salesforce account to customers table.',
    PUBLIC CAMPAIGNS.CAMPAIGN_DATE as date with synonyms=('date','campaign date') comment='Date of the campaign activity',
    PUBLIC CAMPAIGNS.CAMPAIGN_FACT_ID as CAMPAIGN_FACT_ID,
    PUBLIC CAMPAIGNS.CAMPAIGN_KEY as CAMPAIGN_KEY,
    PUBLIC CAMPAIGNS.CAMPAIGN_MONTH as MONTH(date) comment='Month of the campaign',
    PUBLIC CAMPAIGNS.CAMPAIGN_YEAR as YEAR(date) comment='Year of the campaign',
    PUBLIC CAMPAIGNS.CHANNEL_KEY as CHANNEL_KEY,
    PUBLIC CAMPAIGNS.PRODUCT_KEY as PRODUCT_KEY with synonyms=('product_id','product identifier') comment='Product identifier for campaign targeting',
    PUBLIC CAMPAIGNS.REGION_KEY as REGION_KEY,
    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_KEY as CAMPAIGN_KEY,
    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_NAME as CAMPAIGN_NAME with synonyms=('campaign','campaign title') comment='Name of the marketing campaign',
    PUBLIC CAMPAIGN_DETAILS.CAMPAIGN_OBJECTIVE as OBJECTIVE with synonyms=('objective','goal','purpose') comment='Campaign objective',
    PUBLIC CHANNELS.CHANNEL_KEY as CHANNEL_KEY,
    PUBLIC CHANNELS.CHANNEL_NAME as CHANNEL_NAME with synonyms=('channel','marketing channel') comment='Name of the marketing channel',
    PUBLIC CONTACTS.ACCOUNT_ID as ACCOUNT_ID,
    PUBLIC CONTACTS.CAMPAIGN_NO as CAMPAIGN_NO,
    PUBLIC CONTACTS.CONTACT_ID as CONTACT_ID,
    PUBLIC CONTACTS.DEPARTMENT as DEPARTMENT with synonyms=('department','business unit') comment='Contact department',
    PUBLIC CONTACTS.EMAIL as EMAIL with synonyms=('email','email address') comment='Contact email address',
    PUBLIC CONTACTS.FIRST_NAME as FIRST_NAME with synonyms=('first name','contact name') comment='Contact first name',
    PUBLIC CONTACTS.LAST_NAME as LAST_NAME with synonyms=('last name','surname') comment='Contact last name',
    PUBLIC CONTACTS.LEAD_SOURCE as LEAD_SOURCE with synonyms=('lead source','source') comment='How the contact was generated',
    PUBLIC CONTACTS.OPPORTUNITY_ID as OPPORTUNITY_ID,
    PUBLIC CONTACTS.TITLE as TITLE with synonyms=('job title','position') comment='Contact job title',
    PUBLIC OPPORTUNITIES.ACCOUNT_ID as ACCOUNT_ID,
    PUBLIC OPPORTUNITIES.CAMPAIGN_ID as CAMPAIGN_ID with synonyms=('campaign fact id','marketing campaign id') comment='Campaign fact ID that links opportunity to marketing campaign',
    PUBLIC OPPORTUNITIES.CLOSE_DATE as CLOSE_DATE with synonyms=('close date','expected close') comment='Expected or actual close date',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_ID as OPPORTUNITY_ID,
    PUBLIC OPPORTUNITIES.OPPORTUNITY_LEAD_SOURCE as lead_source with synonyms=('opportunity source','deal source') comment='Source of the opportunity',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_NAME as OPPORTUNITY_NAME with synonyms=('deal name','opportunity title') comment='Name of the sales opportunity',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_STAGE as STAGE_NAME comment='Stage name of the opportinity. Closed Won indicates an actual sale with revenue',
    PUBLIC OPPORTUNITIES.OPPORTUNITY_TYPE as TYPE with synonyms=('deal type','opportunity type') comment='Type of opportunity',
    PUBLIC OPPORTUNITIES.SALES_SALE_ID as SALE_ID with synonyms=('sales id','invoice no') comment='Sales_ID for sales_fact table that links this opp to a sales record.',
    PUBLIC PRODUCTS.PRODUCT_CATEGORY as CATEGORY_NAME with synonyms=('category','product category') comment='Category of the product',
    PUBLIC PRODUCTS.PRODUCT_KEY as PRODUCT_KEY,
    PUBLIC PRODUCTS.PRODUCT_NAME as PRODUCT_NAME with synonyms=('product','item','product title') comment='Name of the product being promoted',
    PUBLIC PRODUCTS.PRODUCT_VERTICAL as VERTICAL with synonyms=('vertical','industry') comment='Business vertical of the product',
    PUBLIC REGIONS.REGION_KEY as REGION_KEY,
    PUBLIC REGIONS.REGION_NAME as REGION_NAME with synonyms=('region','market','territory') comment='Name of the region',
    PUBLIC REGIONS.LATITUDE as REGION_LATITUDE with synonyms=('region lat','region latitude') comment='Region center latitude (WGS84)',
    PUBLIC REGIONS.LONGITUDE as REGION_LONGITUDE with synonyms=('region long','region longitude') comment='Region center longitude (WGS84)',
    PUBLIC REGIONS.CAPITAL_CITY as REGION_CAPITAL with synonyms=('capital','regional capital') comment='Capital city of the region',
    PUBLIC REGIONS.AREA_KM2 as REGION_AREA_KM2 with synonyms=('area','region size') comment='Region area in square kilometers'
  )
  metrics (
    PUBLIC CAMPAIGNS.AVERAGE_SPEND as AVG(CAMPAIGNS.spend) comment='Average campaign spend',
    PUBLIC CAMPAIGNS.TOTAL_CAMPAIGNS as COUNT(CAMPAIGNS.campaign_record) comment='Total number of campaign activities',
    PUBLIC CAMPAIGNS.TOTAL_IMPRESSIONS as SUM(CAMPAIGNS.impressions) comment='Total impressions across campaigns',
    PUBLIC CAMPAIGNS.TOTAL_LEADS as SUM(CAMPAIGNS.leads_generated) comment='Total leads generated from campaigns',
    PUBLIC CAMPAIGNS.TOTAL_SPEND as SUM(CAMPAIGNS.spend) comment='Total marketing spend',
    PUBLIC CONTACTS.TOTAL_CONTACTS as COUNT(CONTACTS.contact_record) comment='Total contacts generated from campaigns',
    PUBLIC OPPORTUNITIES.AVERAGE_DEAL_SIZE as AVG(OPPORTUNITIES.revenue) comment='Average opportunity size from marketing',
    PUBLIC OPPORTUNITIES.CLOSED_WON_REVENUE as SUM(CASE WHEN OPPORTUNITIES.opportunity_stage = 'Closed Won' THEN OPPORTUNITIES.revenue ELSE 0 END) comment='Revenue from closed won opportunities',
    PUBLIC OPPORTUNITIES.TOTAL_OPPORTUNITIES as COUNT(OPPORTUNITIES.opportunity_record) comment='Total opportunities from marketing',
    PUBLIC OPPORTUNITIES.TOTAL_REVENUE as SUM(OPPORTUNITIES.revenue) comment='Total revenue from marketing-driven opportunities'
  )
  comment='Enhanced semantic view for marketing campaign analysis with complete revenue attribution and ROI tracking'
  with extension (CA='{"tables":[{"name":"ACCOUNTS","dimensions":[{"name":"ACCOUNT_ID"},{"name":"ACCOUNT_NAME"},{"name":"ACCOUNT_TYPE"},{"name":"ANNUAL_REVENUE"},{"name":"EMPLOYEES"},{"name":"INDUSTRY"},{"name":"SALES_CUSTOMER_KEY"}]},{"name":"CAMPAIGNS","dimensions":[{"name":"CAMPAIGN_DATE"},{"name":"CAMPAIGN_FACT_ID"},{"name":"CAMPAIGN_KEY"},{"name":"CAMPAIGN_MONTH"},{"name":"CAMPAIGN_YEAR"},{"name":"CHANNEL_KEY"},{"name":"PRODUCT_KEY"},{"name":"REGION_KEY"}],"facts":[{"name":"CAMPAIGN_RECORD"},{"name":"CAMPAIGN_SPEND"},{"name":"IMPRESSIONS"},{"name":"LEADS_GENERATED"}],"metrics":[{"name":"AVERAGE_SPEND"},{"name":"TOTAL_CAMPAIGNS"},{"name":"TOTAL_IMPRESSIONS"},{"name":"TOTAL_LEADS"},{"name":"TOTAL_SPEND"}]},{"name":"CAMPAIGN_DETAILS","dimensions":[{"name":"CAMPAIGN_KEY"},{"name":"CAMPAIGN_NAME"},{"name":"CAMPAIGN_OBJECTIVE"}]},{"name":"CHANNELS","dimensions":[{"name":"CHANNEL_KEY"},{"name":"CHANNEL_NAME"}]},{"name":"CONTACTS","dimensions":[{"name":"ACCOUNT_ID"},{"name":"CAMPAIGN_NO"},{"name":"CONTACT_ID"},{"name":"DEPARTMENT"},{"name":"EMAIL"},{"name":"FIRST_NAME"},{"name":"LAST_NAME"},{"name":"LEAD_SOURCE"},{"name":"OPPORTUNITY_ID"},{"name":"TITLE"}],"facts":[{"name":"CONTACT_RECORD"}],"metrics":[{"name":"TOTAL_CONTACTS"}]},{"name":"CONTACTS_FOR_OPPORTUNITIES"},{"name":"OPPORTUNITIES","dimensions":[{"name":"ACCOUNT_ID"},{"name":"CAMPAIGN_ID"},{"name":"CLOSE_DATE"},{"name":"OPPORTUNITY_ID"},{"name":"OPPORTUNITY_LEAD_SOURCE"},{"name":"OPPORTUNITY_NAME"},{"name":"OPPORTUNITY_STAGE","sample_values":["Closed Won","Perception Analysis","Qualification"]},{"name":"OPPORTUNITY_TYPE"},{"name":"SALES_SALE_ID"}],"facts":[{"name":"OPPORTUNITY_RECORD"},{"name":"REVENUE"}],"metrics":[{"name":"AVERAGE_DEAL_SIZE"},{"name":"CLOSED_WON_REVENUE"},{"name":"TOTAL_OPPORTUNITIES"},{"name":"TOTAL_REVENUE"}]},{"name":"PRODUCTS","dimensions":[{"name":"PRODUCT_CATEGORY"},{"name":"PRODUCT_KEY"},{"name":"PRODUCT_NAME"},{"name":"PRODUCT_VERTICAL"}]},{"name":"REGIONS","dimensions":[{"name":"REGION_KEY"},{"name":"REGION_NAME"}]}],"relationships":[{"name":"CAMPAIGNS_TO_CHANNELS","relationship_type":"many_to_one"},{"name":"CAMPAIGNS_TO_DETAILS","relationship_type":"many_to_one"},{"name":"CAMPAIGNS_TO_PRODUCTS","relationship_type":"many_to_one"},{"name":"CAMPAIGNS_TO_REGIONS","relationship_type":"many_to_one"},{"name":"CONTACTS_TO_ACCOUNTS","relationship_type":"many_to_one"},{"name":"CONTACTS_TO_CAMPAIGNS","relationship_type":"many_to_one"},{"name":"CONTACTS_TO_OPPORTUNITIES","relationship_type":"many_to_one"},{"name":"OPPORTUNITIES_TO_ACCOUNTS","relationship_type":"many_to_one"},{"name":"OPPORTUNITIES_TO_CAMPAIGNS"}],"verified_queries":[{"name":"include opps that turned in to sales deal","question":"include opps that turned in to sales deal","sql":"WITH campaign_impressions AS (\\n  SELECT\\n    c.campaign_key,\\n    cd.campaign_name,\\n    SUM(c.impressions) AS total_impressions\\n  FROM\\n    campaigns AS c\\n    LEFT OUTER JOIN campaign_details AS cd ON c.campaign_key = cd.campaign_key\\n  WHERE\\n    c.campaign_year = 2025\\n  GROUP BY\\n    c.campaign_key,\\n    cd.campaign_name\\n),\\ncampaign_opportunities AS (\\n  SELECT\\n    c.campaign_key,\\n    COUNT(o.opportunity_record) AS total_opportunities,\\n    COUNT(\\n      CASE\\n        WHEN o.opportunity_stage = ''Closed Won'' THEN o.opportunity_record\\n      END\\n    ) AS closed_won_opportunities\\n  FROM\\n    campaigns AS c\\n    LEFT OUTER JOIN opportunities AS o ON c.campaign_fact_id = o.campaign_id\\n  WHERE\\n    c.campaign_year = 2025\\n  GROUP BY\\n    c.campaign_key\\n)\\nSELECT\\n  ci.campaign_name,\\n  ci.total_impressions,\\n  COALESCE(co.total_opportunities, 0) AS total_opportunities,\\n  COALESCE(co.closed_won_opportunities, 0) AS closed_won_opportunities\\nFROM\\n  campaign_impressions AS ci\\n  LEFT JOIN campaign_opportunities AS co ON ci.campaign_key = co.campaign_key\\nORDER BY\\n  ci.total_impressions DESC NULLS LAST","use_as_onboarding_question":false,"verified_by":"Nick Akincilar","verified_at":1757262696}]}');



  -- ========================================================================
  -- HR SEMANTIC VIEW
  -- ========================================================================
create or replace semantic view MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_HR_SEMANTIC_VIEW
  tables (
    DEPARTMENTS as MIFIBRA_DEPARTMENT_DIM primary key (DEPARTMENT_KEY) with synonyms=('departments','business units') comment='Department dimension for organizational analysis',
    EMPLOYEES as MIFIBRA_EMPLOYEE_DIM primary key (EMPLOYEE_KEY) with synonyms=('employees','staff','workforce') comment='Employee dimension with personal information',
    HR_RECORDS as MIFIBRA_HR_EMPLOYEE_FACT primary key (HR_FACT_ID) with synonyms=('hr data','employee records') comment='HR employee fact data for workforce analysis',
    JOBS as MIFIBRA_JOB_DIM primary key (JOB_KEY) with synonyms=('job titles','positions','roles') comment='Job dimension with titles and levels',
    LOCATIONS as MIFIBRA_LOCATION_DIM primary key (LOCATION_KEY) with synonyms=('locations','offices','sites') comment='Location dimension for geographic analysis'
  )
  relationships (
    HR_TO_DEPARTMENTS as HR_RECORDS(DEPARTMENT_KEY) references DEPARTMENTS(DEPARTMENT_KEY),
    HR_TO_EMPLOYEES as HR_RECORDS(EMPLOYEE_KEY) references EMPLOYEES(EMPLOYEE_KEY),
    HR_TO_JOBS as HR_RECORDS(JOB_KEY) references JOBS(JOB_KEY),
    HR_TO_LOCATIONS as HR_RECORDS(LOCATION_KEY) references LOCATIONS(LOCATION_KEY)
  )
  facts (
    HR_RECORDS.ATTRITION_FLAG as attrition_flag with synonyms=('turnover_indicator','employee_departure_flag','separation_flag','employee_retention_status','churn_status','employee_exit_indicator') comment='Attrition flag. value is 0 if employee is currently active. 1 if employee quit & left the company. Always filter by 0 to show active employees unless specified otherwise',
    HR_RECORDS.EMPLOYEE_RECORD as 1 comment='Count of employee records',
    HR_RECORDS.EMPLOYEE_SALARY as salary comment='Employee salary in Peruvian Soles (S/)'
  )
  dimensions (
    DEPARTMENTS.DEPARTMENT_KEY as DEPARTMENT_KEY,
    DEPARTMENTS.DEPARTMENT_NAME as department_name with synonyms=('department','business unit','division') comment='Name of the department',
    EMPLOYEES.EMPLOYEE_KEY as EMPLOYEE_KEY,
    EMPLOYEES.EMPLOYEE_NAME as employee_name with synonyms=('employee','staff member','person','sales rep','manager','director','executive') comment='Name of the employee',
    EMPLOYEES.GENDER as gender with synonyms=('gender','sex') comment='Employee gender',
    EMPLOYEES.HIRE_DATE as hire_date with synonyms=('hire date','start date') comment='Date when employee was hired',
    HR_RECORDS.DEPARTMENT_KEY as DEPARTMENT_KEY,
    HR_RECORDS.EMPLOYEE_KEY as EMPLOYEE_KEY,
    HR_RECORDS.HR_FACT_ID as HR_FACT_ID,
    HR_RECORDS.JOB_KEY as JOB_KEY,
    HR_RECORDS.LOCATION_KEY as LOCATION_KEY,
    HR_RECORDS.RECORD_DATE as date with synonyms=('date','record date') comment='Date of the HR record',
    HR_RECORDS.RECORD_MONTH as MONTH(date) comment='Month of the HR record',
    HR_RECORDS.RECORD_YEAR as YEAR(date) comment='Year of the HR record',
    JOBS.JOB_KEY as JOB_KEY,
    JOBS.JOB_LEVEL as job_level with synonyms=('level','grade','seniority') comment='Job level or grade',
    JOBS.JOB_TITLE as job_title with synonyms=('job title','position','role') comment='Employee job title',
    LOCATIONS.LOCATION_KEY as LOCATION_KEY,
    LOCATIONS.LOCATION_NAME as location_name with synonyms=('location','office','site') comment='Work location',
    LOCATIONS.CITY as LOCATION_CITY with synonyms=('city','office city') comment='City where office is located',
    LOCATIONS.DEPARTMENT as LOCATION_DEPARTMENT with synonyms=('department','office department','region') comment='Peru department where office is located',
    LOCATIONS.LOCATION_TYPE as LOCATION_TYPE with synonyms=('office type','site type') comment='Type of location (Headquarters/Regional Office/etc)',
    LOCATIONS.LATITUDE as LOCATION_LATITUDE with synonyms=('office lat','location latitude') comment='Office location latitude (WGS84)',
    LOCATIONS.LONGITUDE as LOCATION_LONGITUDE with synonyms=('office long','location longitude') comment='Office location longitude (WGS84)'
  )
  metrics (
    HR_RECORDS.ATTRITION_COUNT as SUM(hr_records.attrition_flag) comment='Number of employees who left',
    HR_RECORDS.AVG_SALARY as AVG(hr_records.employee_salary) comment='average employee salary',
    HR_RECORDS.TOTAL_EMPLOYEES as COUNT(hr_records.employee_record) comment='Total number of employees',
    HR_RECORDS.TOTAL_SALARY_COST as SUM(hr_records.EMPLOYEE_SALARY) comment='Total salary cost'
  )
  comment='Semantic view for HR analytics and workforce management'
  with extension (CA='{"tables":[{"name":"DEPARTMENTS","dimensions":[{"name":"DEPARTMENT_KEY"},{"name":"DEPARTMENT_NAME","sample_values":["Operaciones de Red","Soporte Tecnico","Ventas Residencial","Finanzas","Atencion al Cliente"]}]},{"name":"EMPLOYEES","dimensions":[{"name":"EMPLOYEE_KEY"},{"name":"EMPLOYEE_NAME","sample_values":["Carlos Garcia Rodriguez","Maria Quispe Huaman","Jose Fernandez Torres"]},{"name":"GENDER"},{"name":"HIRE_DATE"}]},{"name":"HR_RECORDS","dimensions":[{"name":"DEPARTMENT_KEY"},{"name":"EMPLOYEE_KEY"},{"name":"HR_FACT_ID"},{"name":"JOB_KEY"},{"name":"LOCATION_KEY"},{"name":"RECORD_DATE"},{"name":"RECORD_MONTH"},{"name":"RECORD_YEAR"}],"facts":[{"name":"ATTRITION_FLAG","sample_values":["0","1"]},{"name":"EMPLOYEE_RECORD"},{"name":"EMPLOYEE_SALARY"}],"metrics":[{"name":"ATTRITION_COUNT"},{"name":"AVG_SALARY"},{"name":"TOTAL_EMPLOYEES"},{"name":"TOTAL_SALARY_COST"}]},{"name":"JOBS","dimensions":[{"name":"JOB_KEY"},{"name":"JOB_LEVEL"},{"name":"JOB_TITLE","sample_values":["Gerente General","Tecnico de Instalaciones","Ejecutivo de Ventas","Ingeniero de Red"]}]},{"name":"LOCATIONS","dimensions":[{"name":"LOCATION_KEY"},{"name":"LOCATION_NAME","sample_values":["Sede Central - San Isidro Lima","Oficina Regional Arequipa","Call Center San Borja"]}]}],"relationships":[{"name":"HR_TO_DEPARTMENTS","relationship_type":"many_to_one"},{"name":"HR_TO_EMPLOYEES","relationship_type":"many_to_one"},{"name":"HR_TO_JOBS","relationship_type":"many_to_one"},{"name":"HR_TO_LOCATIONS","relationship_type":"many_to_one"}],"verified_queries":[{"name":"List of all active employees","question":"List of all active employees","sql":"select\\n  h.employee_key,\\n  e.employee_name,\\nfrom\\n  employees e\\n  left join hr_records h on e.employee_key = h.employee_key\\ngroup by\\n  all\\nhaving\\n  sum(h.attrition_flag) = 0;","use_as_onboarding_question":false,"verified_by":"MiFibra Admin","verified_at":1753846263},{"name":"List of all inactive employees","question":"List of all inactive employees","sql":"SELECT\\n  h.employee_key,\\n  e.employee_name\\nFROM\\n  employees AS e\\n  LEFT JOIN hr_records AS h ON e.employee_key = h.employee_key\\nGROUP BY\\n  ALL\\nHAVING\\n  SUM(h.attrition_flag) > 0","use_as_onboarding_question":false,"verified_by":"MiFibra Admin","verified_at":1753846300}],"custom_instructions":"- Each employee can have multiple hr_employee_fact records. \\n- Only one hr_employee_fact record per employee is valid and that is the one which has the highest date value."}');ncilar","verified_at":1753846300}],"custom_instructions":"- Each employee can have multiple hr_employee_fact records. \\n- Only one hr_employee_fact record per employee is valid and that is the one which has the highest date value."}');
  -- ========================================================================
  -- INFRASTRUCTURE SEMANTIC VIEW (Network Status)
  -- ========================================================================
create or replace semantic view MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INFRASTRUCTURE_SEMANTIC_VIEW
  tables (
    NETWORK_NODES as MIFIBRA_NETWORK_STATUS_DIM primary key (NODE_ID) with synonyms=('network nodes','infrastructure','fiber nodes','POPs') comment='Network infrastructure nodes across Peru',
    REGIONS as MIFIBRA_REGION_DIM primary key (REGION_KEY) with synonyms=('regions','territories','departments') comment='Regional dimension for geographic analysis'
  )
  relationships (
    NODES_TO_REGIONS as NETWORK_NODES(REGION_KEY) references REGIONS(REGION_KEY)
  )
  facts (
    NETWORK_NODES.NODE_RECORD as 1 comment='Count of network nodes',
    NETWORK_NODES.CAPACITY_GBPS as CAPACITY_GBPS comment='Node capacity in Gbps',
    NETWORK_NODES.ACTIVE_SUBSCRIBERS as ACTIVE_SUBSCRIBERS comment='Number of active subscribers',
    NETWORK_NODES.UPTIME_PCT as UPTIME_PCT comment='Node uptime percentage',
    NETWORK_NODES.HOUSEHOLDS_PASSED as HOUSEHOLDS_PASSED comment='Homes passed by fiber',
    NETWORK_NODES.FIBER_KM as FIBER_KM comment='Kilometers of fiber deployed'
  )
  dimensions (
    NETWORK_NODES.NODE_ID as NODE_ID,
    NETWORK_NODES.CITY_NAME as CITY with synonyms=('city','location','node city') comment='City where node is located',
    NETWORK_NODES.DEPARTMENT as DEPARTMENT with synonyms=('department','region','administrative region') comment='Peru department',
    NETWORK_NODES.NODE_TYPE as NODE_TYPE with synonyms=('node type','infrastructure type') comment='Type of node (Primary Hub/Secondary Hub/Distribution Node/Access Node)',
    NETWORK_NODES.STATUS as NODE_STATUS with synonyms=('status','operational status') comment='Node operational status',
    NETWORK_NODES.TECHNOLOGY as FIBER_TECHNOLOGY with synonyms=('technology','fiber type') comment='Fiber technology (XGS-PON/GPON)',
    NETWORK_NODES.LAST_MAINTENANCE as LAST_MAINTENANCE with synonyms=('maintenance date','last service') comment='Date of last maintenance',
    NETWORK_NODES.NEXT_MAINTENANCE as NEXT_MAINTENANCE with synonyms=('next maintenance','scheduled maintenance') comment='Next scheduled maintenance date',
    NETWORK_NODES.NOC_REGION as NOC_REGION with synonyms=('NOC','network operations center') comment='NOC region assignment',
    NETWORK_NODES.UTILIZATION_PCT as UTILIZATION_PCT with synonyms=('utilization','capacity usage') comment='Node utilization percentage',
    NETWORK_NODES.PENETRATION_PCT as PENETRATION_PCT with synonyms=('penetration','market penetration') comment='Market penetration percentage',
    NETWORK_NODES.LATENCY_MS as LATENCY_MS with synonyms=('latency','ping') comment='Network latency in milliseconds',
    NETWORK_NODES.OLT_COUNT as OLT_COUNT with synonyms=('OLT','optical line terminals') comment='Number of OLT devices',
    NETWORK_NODES.ONT_DEPLOYED as ONT_DEPLOYED with synonyms=('ONT','optical network terminals') comment='Number of ONT devices deployed',
    NETWORK_NODES.LATITUDE as NODE_LATITUDE with synonyms=('node lat','latitude') comment='Node location latitude (WGS84)',
    NETWORK_NODES.LONGITUDE as NODE_LONGITUDE with synonyms=('node long','longitude') comment='Node location longitude (WGS84)',
    NETWORK_NODES.REGION_KEY as REGION_KEY,
    REGIONS.REGION_KEY as REGION_KEY,
    REGIONS.REGION_NAME as REGION_NAME with synonyms=('region','territory') comment='Name of the region',
    REGIONS.LATITUDE as REGION_LATITUDE with synonyms=('region lat') comment='Region center latitude',
    REGIONS.LONGITUDE as REGION_LONGITUDE with synonyms=('region long') comment='Region center longitude',
    REGIONS.CAPITAL_CITY as REGION_CAPITAL with synonyms=('capital') comment='Regional capital city',
    REGIONS.AREA_KM2 as REGION_AREA_KM2 with synonyms=('area') comment='Region area in km2'
  )
  metrics (
    NETWORK_NODES.TOTAL_NODES as COUNT(network_nodes.node_record) comment='Total number of network nodes',
    NETWORK_NODES.TOTAL_CAPACITY as SUM(network_nodes.capacity_gbps) comment='Total network capacity in Gbps',
    NETWORK_NODES.TOTAL_SUBSCRIBERS as SUM(network_nodes.active_subscribers) comment='Total active subscribers',
    NETWORK_NODES.TOTAL_HOUSEHOLDS_PASSED as SUM(network_nodes.households_passed) comment='Total homes passed by fiber',
    NETWORK_NODES.TOTAL_FIBER_KM as SUM(network_nodes.fiber_km) comment='Total fiber kilometers deployed',
    NETWORK_NODES.AVG_UPTIME as AVG(network_nodes.uptime_pct) comment='Average network uptime percentage',
    NETWORK_NODES.AVG_UTILIZATION as AVG(network_nodes.utilization_pct) comment='Average node utilization',
    NETWORK_NODES.AVG_PENETRATION as AVG(network_nodes.penetration_pct) comment='Average market penetration'
  )
  comment='Semantic view for MiFibra network infrastructure analysis and CARTO mapping';

  -- ========================================================================
  -- VERIFICATION
  -- ========================================================================

  -- Show all semantic views
  SHOW SEMANTIC VIEWS;

  -- Show dimensions for each semantic view
  SHOW SEMANTIC DIMENSIONS;

  -- Show metrics for each semantic view
  SHOW SEMANTIC METRICS; 







    -- ========================================================================
    -- UNSTRUCTURED DATA - Parse all document types (PDF, DOCX, PPTX, MD)
    -- ========================================================================
    
    -- Parse structured documents (PDF, DOCX, PPTX) using PARSE_DOCUMENT
    CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT_DOCS AS 
    SELECT 
        relative_path, 
        BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path) as file_url,
        TO_FILE(BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path)) as file_object,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE,
            relative_path,
            {'mode':'LAYOUT'}
        ):content::string as content
    FROM directory(@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE) 
    WHERE relative_path ilike 'unstructured_docs/%.pdf'
       OR relative_path ilike 'unstructured_docs/%.docx'
       OR relative_path ilike 'unstructured_docs/%.pptx';

    -- Parse Markdown files using PARSE_DOCUMENT (supports plain text extraction)
    CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT_MD AS
    SELECT 
        relative_path,
        BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path) as file_url,
        TO_FILE(BUILD_STAGE_FILE_URL('@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE', relative_path)) as file_object,
        SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
            @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE,
            relative_path,
            {'mode':'LAYOUT'}
        ):content::string as content
    FROM directory(@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE) 
    WHERE relative_path ilike 'unstructured_docs/%.md';

    -- Combine all document types into unified parsed_content table
    CREATE OR REPLACE TABLE MIFIBRA_PARSED_CONTENT AS
    SELECT relative_path, file_url, file_object, content FROM MIFIBRA_PARSED_CONTENT_DOCS
    UNION ALL
    SELECT relative_path, file_url, file_object, content FROM MIFIBRA_PARSED_CONTENT_MD;
    
    -- Verify document counts by type
    SELECT 
        CASE 
            WHEN relative_path ILIKE '%.pdf' THEN 'PDF'
            WHEN relative_path ILIKE '%.docx' THEN 'DOCX'
            WHEN relative_path ILIKE '%.pptx' THEN 'PPTX'
            WHEN relative_path ILIKE '%.md' THEN 'Markdown'
            ELSE 'Other'
        END as file_type,
        COUNT(*) as file_count
    FROM MIFIBRA_PARSED_CONTENT
    GROUP BY file_type
    ORDER BY file_count DESC;

--select *, GET_PATH(PARSE_JSON(content), 'content')::string as extracted_content from parsed_content;


    -- Switch to admin role for remaining operations
    USE ROLE MiFibra_Demo;

    -- Create search service for finance documents
    -- This enables semantic search over finance-related content
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
                REGEXP_SUBSTR(relative_path, '[^/]+
    
    -- Create search service for HR documents
    -- This enables semantic search over HR-related content
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
                REGEXP_SUBSTR(relative_path, '[^/]+

    -- Create search service for marketing documents
    -- This enables semantic search over marketing-related content
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
                REGEXP_SUBSTR(relative_path, '[^/]+

    -- Create search service for sales documents
    -- This enables semantic search over sales-related content
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
                REGEXP_SUBSTR(relative_path, '[^/]+

    -- Create search service for strategy documents
    -- This enables semantic search over CEO/strategy-related content (UK Telecom)
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
                REGEXP_SUBSTR(relative_path, '[^/]+

    -- Create search service for demo scripts
    -- This enables semantic search over demo presentation materials
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
                REGEXP_SUBSTR(relative_path, '[^/]+

    -- Create search service for network infrastructure documents
    -- This enables semantic search over data center, network capacity, and platform uptime content
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
                REGEXP_SUBSTR(relative_path, '[^/]+


use role mifibra_demo;


  -- NETWORK rule is part of db schema
CREATE OR REPLACE NETWORK RULE MiFibra_WebAccessRule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');


use role accountadmin;

GRANT ALL PRIVILEGES ON DATABASE MIFIBRA_AI_DEMO TO ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA TO ROLE ACCOUNTADMIN;
GRANT USAGE ON NETWORK RULE mifibra_webaccessrule TO ROLE accountadmin;

USE SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION MiFibra_ExternalAccess_Integration
ALLOWED_NETWORK_RULES = (MiFibra_WebAccessRule)
ENABLED = true;

CREATE OR REPLACE NOTIFICATION INTEGRATION mifibra_email_int
  TYPE=EMAIL
  ENABLED=TRUE;

GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE MiFibra_Demo;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE MiFibra_Demo;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE MiFibra_Demo;

GRANT USAGE ON INTEGRATION MiFibra_ExternalAccess_Integration TO ROLE MiFibra_Demo;

GRANT USAGE ON INTEGRATION MIFIBRA_EMAIL_INT TO ROLE MIFIBRA_DEMO;


use role MiFibra_Demo;
-- CREATES A SNOWFLAKE INTELLIGENCE AGENT WITH MULTIPLE TOOLS

-- Create stored procedure to generate presigned URLs for files in internal stages
CREATE OR REPLACE PROCEDURE MIFIBRA_GET_FILE_PRESIGNED_URL_SP(
    RELATIVE_FILE_PATH STRING, 
    EXPIRATION_MINS INTEGER DEFAULT 60
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generates a presigned URL for a file in the static @MIFIBRA_INTERNAL_STAGE. Input is the relative file path.'
EXECUTE AS CALLER
AS
$
DECLARE
    presigned_url STRING;
    sql_stmt STRING;
    expiration_seconds INTEGER;
    stage_name STRING DEFAULT '@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE';
BEGIN
    expiration_seconds := EXPIRATION_MINS * 60;

    sql_stmt := 'SELECT GET_PRESIGNED_URL(' || stage_name || ', ' || '''' || RELATIVE_FILE_PATH || '''' || ', ' || expiration_seconds || ') AS url';
    
    EXECUTE IMMEDIATE :sql_stmt;
    
    
    SELECT "URL"
    INTO :presigned_url
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    
    RETURN :presigned_url;
END;
$$;

-- Create stored procedure to send emails to verified recipients in Snowflake

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

CREATE OR REPLACE FUNCTION MIFIBRA_WEB_SCRAPE(weburl STRING)
RETURNS STRING
LANGUAGE PYTHON
RUNTIME_VERSION = 3.11
HANDLER = 'get_page'
EXTERNAL_ACCESS_INTEGRATIONS = (MiFibra_ExternalAccess_Integration)
PACKAGES = ('requests', 'beautifulsoup4')
--SECRETS = ('cred' = oauth_token )
AS
$$
import _snowflake
import requests
from bs4 import BeautifulSoup

def get_page(weburl):
  url = f"{weburl}"
  response = requests.get(url)
  soup = BeautifulSoup(response.text)
  return soup.get_text()
$$;


CREATE OR REPLACE PROCEDURE MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_GENERATE_STREAMLIT_APP("USER_INPUT" VARCHAR)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'generate_app'
EXECUTE AS OWNER
AS '
def generate_app(session, user_input):
    import re
    import tempfile
    import os
    
    # Build the prompt for AI_COMPLETE
    prompt = f"""Generate a Streamlit in Snowflake code that has an existing session. 
- Output should only contain the code and nothing else. 

- Total number of characters in the entire python code should be less than 32000 chars

- create session object like this: 
from snowflake.snowpark.context import get_active_session
session = get_active_session()

- Never CREATE, DROP , TRUNCATE OR ALTER  tables. You are only allowed to use SQL SELECT statements.

- Use only native Streamlit visualizations and no html formatting

- ignore & remove VERTICAL=''Retail'' filter in all source SQL queries.

- Use ONLY SQL queries provided in the input as the data source for all dataframes placing them into CTE to generate new ones. You can remove LIMIT or modify WHERE clauses to remove or modify filters. Example:

WITH cte AS (
    SELECT original_query_from_prompt modified 
    WHERE x=1 --this portion can be removed or modified
    LIMIT 5   -- this needs to be removed
)
SELECT *
FROM cte as new_query for dataframe;


- DO NOT use any table or column other than what was listed in the source queries below. 

- all table column names should be in UPPER CASE

- Include filters for users such as for dates ranges & all dimensions discussed within the user conversation to make it more interactive. Queries used for user selections using distinct values should not use any filters for VERTICAL = RETAIL.

- Can have up to 2 tabs. Each tab can have up maximum 4 visualizatons (chart & kpis)

- Use only native Streamlit visualizations and no html formatting. 

- For Barcharts showing Metric by Dimension_Name, bars should be sorted from highest metric value to lowest . 

- dont use st.Scatter_chart, st.bokeh_chart, st.set_page_config The page_title, page_icon, and menu_items properties of the st.set_page_config command are not supported. 

- Dont use plotly. 

- When generating code that involves loading data from a SQL source (like Snowflake/Snowpark)
into a Pandas DataFrame for use in a visualization library (like Streamlit), you must explicitly ensure all date and timestamp columns are correctly cast as Pandas datetime objects.

Specific Steps:

Identify all columns derived from SQL date/timestamp functions (e.g., DATE, MONTH, SALE_DATE).

Immediately after calling the .to_pandas() method to load the data into the DataFrame df, insert code to apply pd.to_datetime() to these column

- App should perform the following:
<input>
{user_input}
</input>"""
    
    # Escape single quotes for SQL
    escaped_prompt = prompt.replace("''", "''''")
    
    # Execute AI_COMPLETE query
    # query = f"SELECT AI_COMPLETE(''claude-4-sonnet'', ''{escaped_prompt}'')::string as result"

    # Build model_parameters as a separate string to avoid f-string escaping issues
    model_params = "{''temperature'': 0, ''max_tokens'': 8192}"
    
    # Execute AI_COMPLETE query with model parameters
    query = f"""SELECT AI_COMPLETE(model => ''claude-4-sonnet'',
                                prompt => ''{escaped_prompt}'',
                                model_parameters => {model_params}
                                )::string as result"""
    
    result = session.sql(query).collect()
    
    if result and len(result) > 0:
        code_response = result[0][''RESULT'']
        
        # Strip markdown code block markers using regex
        cleaned_code = code_response.strip()
        
        # Remove ```python, ```, or ```py markers at start
        cleaned_code = re.sub(r''^```(?:python|py)?\\s*\\n?'', '''', cleaned_code)
        # Remove ``` at end
        cleaned_code = re.sub(r''\\n?```\\s*$'', '''', cleaned_code)
        
        # Remove any leading/trailing whitespace
        cleaned_code = cleaned_code.strip()
        
        # Prepare environment.yml content
        environment_yml_content = """# Snowflake environment file for Streamlit in Snowflake (SiS)
# This file specifies Python package dependencies for your Streamlit app

name: streamlit_app_env
channels:
  - snowflake

dependencies:
  - plotly=6.3.0
"""
        
        # Write files to temporary directory
        temp_dir = tempfile.gettempdir()
        temp_py_file = os.path.join(temp_dir, ''test.py'')
        temp_yml_file = os.path.join(temp_dir, ''environment.yml'')
        
        try:
            # Write the Python code to temporary file
            with open(temp_py_file, ''w'') as f:
                f.write(cleaned_code)
            
            # Write the environment.yml to temporary file
            with open(temp_yml_file, ''w'') as f:
                f.write(environment_yml_content)
            
            # Upload both files to Snowflake stage
            stage_path = ''@MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE''
            
            # Upload Python file
            session.file.put(
                temp_py_file,
                stage_path,
                auto_compress=False,
                overwrite=True
            )
            
            # Upload environment.yml file
            session.file.put(
                temp_yml_file,
                stage_path,
                auto_compress=False,
                overwrite=True
            )
            
            # Clean up temporary files
            os.remove(temp_py_file)
            os.remove(temp_yml_file)
            
            # Create Streamlit app
            app_name = ''AUTO_GENERATED_1''
            warehouse = ''mifibra_demo_wh''
            
            create_streamlit_sql = f"""
            CREATE OR REPLACE STREAMLIT MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_{app_name}
                FROM @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE
                MAIN_FILE = ''test.py''
                QUERY_WAREHOUSE = {warehouse}
            """
            
            try:
                session.sql(create_streamlit_sql).collect()
                
                # Get account information for URL
                account_info = session.sql("SELECT CURRENT_ACCOUNT_NAME() AS account, CURRENT_ORGANIZATION_NAME() AS org").collect()
                account_name = account_info[0][''ACCOUNT'']
                org_name = account_info[0][''ORG'']
                
                # Construct app URL
                app_url = f"https://app.snowflake.com/{org_name}/{account_name}/#/streamlit-apps/MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_{app_name}"
                
                # Return only the URL if successful
                return app_url
                
            except Exception as create_error:
                return f"""✅ Files saved to {stage_path}/
   - test.py
   - environment.yml

⚠️  Warning: Could not auto-create Streamlit app: {str(create_error)}

To create manually, run:
CREATE OR REPLACE STREAMLIT MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_{app_name}
    FROM @MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_INTERNAL_STAGE
    MAIN_FILE = ''test.py''
    QUERY_WAREHOUSE = {warehouse};

--- Generated Code ---
{cleaned_code}"""
            
        except Exception as e:
            # Clean up temp files if they exist
            if os.path.exists(temp_py_file):
                os.remove(temp_py_file)
            if os.path.exists(temp_yml_file):
                os.remove(temp_yml_file)
            return f"❌ Error saving to stage: {str(e)}\\n\\n--- Generated Code ---\\n{cleaned_code}"
    else:
        return "Error: No response from AI_COMPLETE"
';




CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.MiFibra_Executive_Agent
WITH PROFILE='{ "display_name": "MiFibra Executive Agent" }'
    COMMENT=$ MiFibra Peru executive intelligence agent for leadership team (CEO, CFO, COO, CMO). Covers fiber network status, subscriber metrics (ARPU, MRR, churn), revenue by segment (Residential/Enterprise), product performance (Internet plans 500Mbps-5000Mbps, TV Digital, equipment), regional expansion, customer satisfaction, and competitive analysis. Default currency Peruvian Soles (S/). $
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": ""
  },
  "instructions": {
    "response": "You are a business intelligence analyst for MiFibra Peru, the fastest fiber optic internet provider in Peru (Ookla Speedtest Awards). You answer questions about subscriber metrics (active subscribers, ARPU, MRR, churn rate), revenue by segment (Residential 80%, Enterprise 20%), product performance (Internet plans from 500 Mbps to 5000 Mbps, TV Digital packages, WiFi 6 equipment), regional expansion across Peru departments (Lima, Arequipa, La Libertad, Cusco, etc.), customer satisfaction and NPS, installation metrics, and competitive positioning. Monetary values default to Peruvian Soles (S/) unless the user specifies otherwise. Regions include Lima Metropolitana, Costa Norte, Costa Sur, Sierra, and Selva. Competitors include Claro, Movistar, Entel, Bitel, and Win. Provide charts where helpful (line for trends, bar for comparisons). Always ground answers in the provided data and documents.",
    "orchestration": "Use cortex search for finance, strategy, network, and operational documents in the staged repository (e.g., quarterly financial report, subscriber metrics, board presentation, market analysis, network coverage, expansion plans). Use cortex analyst for structured queries: revenue by segment/region, subscriber growth and churn, ARPU trends, product performance, campaign effectiveness, and workforce metrics.\n\n**GUARDRAIL CHECK:** Only respond to MiFibra business topics (fiber internet services, TV Digital, equipment sales, residential/enterprise customers, Peru regional operations). If asked about unrelated topics (weather, politics, general trivia), politely decline and redirect to MiFibra business questions.\n\nFor network infrastructure questions (fiber coverage, node capacity, uptime, NOC metrics, installation backlogs), ALWAYS use the 'Search Internal Documents: Network' tool first.\n\n",
    "sample_questions": [
      {
        "question": "What is our total subscriber count and MRR by region (Lima, Arequipa, La Libertad, etc.)?"
      },
      {
        "question": "What is our ARPU trend for residential vs enterprise customers over the last 6 months?"
      },
      {
        "question": "Which internet plans (500Mbps to 5000Mbps) have the highest adoption and revenue?"
      },
      {
        "question": "What is our churn rate by region and what are the main reasons for cancellation?"
      },
      {
        "question": "How many new installations were completed this month and what is the average time to install?"
      },
      {
        "question": "How do we compare against Claro and Movistar in market share by region?"
      },
      {
        "question": "What are our top performing marketing campaigns for customer acquisition?"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Finance Datamart",
        "description": "Query MiFibra financials: revenue by segment (Residential/Enterprise), MRR, ARPU, margin, CapEx/OpEx for network expansion, vendor spend for equipment. Default currency Peruvian Soles (S/)."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Sales Datamart",
        "description": "Query sales pipeline: new subscriptions by plan and region, enterprise contracts, partner/reseller performance, upsell opportunities, churn risk analysis."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query HR Datamart",
        "description": "Query workforce data: headcount, departments, roles, certifications, attrition."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Query Marketing Datamart",
        "description": "Query marketing campaigns: demand generation for residential and enterprise segments, digital channels (Facebook, Google, Instagram, TikTok), traditional media, spend, impressions, leads, ROI."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: Finance",
        "description": "Search finance documents: quarterly reports, revenue analysis, subscriber metrics, cost management, vendor contracts."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: HR",
        "description": "Search HR documents: employee handbook, performance guidelines, department structures, and workforce policies."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: Sales",
        "description": "Search sales documents: subscription playbooks, churn mitigation strategies, enterprise sales materials, customer success stories."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: Marketing",
        "description": "Search marketing documents including campaign strategies, competitive/market analysis, NPS, ROI."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: Strategy",
        "description": "Search strategy documents covering expansion roadmap, market position, competitive landscape (Claro, Movistar, Entel, Bitel, Win), investor relations, board presentations, regulatory compliance with OSIPTEL."
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Internal Documents: Network",
        "description": "Search network infrastructure documents: fiber coverage maps, node capacity, uptime and SLA metrics, NOC operations, installation queues, maintenance schedules, equipment inventory, redundancy plans."
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Web_scraper",
        "description": "This tool should be used if the user wants to analyse contents of a given web page. This tool will use a web url (https or https) as input and will return the text content of that web page for further analysis",
        "input_schema": {
          "type": "object",
          "properties": {
            "weburl": {
              "description": "Agent should ask web url ( that includes http:// or https:// ). It will scrape text from the given url and return as a result.",
              "type": "string"
            }
          },
          "required": [
            "weburl"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Send_Emails",
        "description": "This tool is used to send emails to a email recipient. It can take an email, subject & content as input to send the email. Always use HTML formatted content for the emails.",
        "input_schema": {
          "type": "object",
          "properties": {
            "recipient": {
              "description": "recipient of email",
              "type": "string"
            },
            "subject": {
              "description": "subject of email",
              "type": "string"
            },
            "text": {
              "description": "content of email",
              "type": "string"
            }
          },
          "required": [
            "text",
            "recipient",
            "subject"
          ]
        }
      }
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Dynamic_Doc_URL_Tool",
        "description": "This tools uses the ID Column coming from Cortex Search tools for reference docs and returns a temp URL for users to view & download the docs.\n\nReturned URL should be presented as a HTML Hyperlink where doc title should be the text and out of this tool should be the url.\n\nURL format for PDF docs that are are like this which has no PDF in the url. Create the Hyperlink format so the PDF doc opens up in a browser instead of downloading the file.\nhttps://domain/path/unique_guid",
        "input_schema": {
          "type": "object",
          "properties": {
            "expiration_mins": {
              "description": "default should be 5",
              "type": "number"
            },
            "relative_file_path": {
              "description": "This is the ID Column value Coming from Cortex Search tool.",
              "type": "string"
            }
          },
          "required": [
            "expiration_mins",
            "relative_file_path"
          ]
        }
      }
    }
  ],
  "tool_resources": {
    "Dynamic_Doc_URL_Tool": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "MIFIBRA_DEMO_WH"
      },
      "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_GET_FILE_PRESIGNED_URL_SP",
      "name": "MIFIBRA_GET_FILE_PRESIGNED_URL_SP(VARCHAR, DEFAULT NUMBER)",
      "type": "procedure"
    },
    "Query Finance Datamart": {
      "semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_FINANCE_SEMANTIC_VIEW"
    },
    "Query HR Datamart": {
      "semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_HR_SEMANTIC_VIEW"
    },
    "Query Marketing Datamart": {
      "semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_MARKETING_SEMANTIC_VIEW"
    },
    "Query Sales Datamart": {
      "semantic_view": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SALES_SEMANTIC_VIEW"
    },
    "Search Internal Documents: Finance": {
      "id_column": "FILE_URL",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_FINANCE_DOCS",
      "title_column": "TITLE"
    },
    "Search Internal Documents: HR": {
      "id_column": "FILE_URL",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_HR_DOCS",
      "title_column": "TITLE"
    },
    "Search Internal Documents: Marketing": {
      "id_column": "RELATIVE_PATH",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_MARKETING_DOCS",
      "title_column": "TITLE"
    },
    "Search Internal Documents: Sales": {
      "id_column": "FILE_URL",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_SALES_DOCS",
      "title_column": "TITLE"
    },
    "Search Internal Documents: Strategy": {
      "id_column": "RELATIVE_PATH",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_STRATEGY_DOCS",
      "title_column": "TITLE"
    },
    "Search Internal Documents: Network": {
      "id_column": "RELATIVE_PATH",
      "max_results": 5,
      "name": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEARCH_NETWORK_DOCS",
      "title_column": "TITLE"
    },
    "Send_Emails": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "MIFIBRA_DEMO_WH"
      },
      "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_SEND_MAIL",
      "name": "MIFIBRA_SEND_MAIL(VARCHAR, VARCHAR, VARCHAR)",
      "type": "procedure"
    },
    "Web_scraper": {
      "execution_environment": {
        "query_timeout": 0,
        "type": "warehouse",
        "warehouse": "MIFIBRA_DEMO_WH"
      },
      "identifier": "MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.MIFIBRA_WEB_SCRAPE",
      "name": "MIFIBRA_WEB_SCRAPE(VARCHAR)",
      "type": "function"
    }
  }
}
$$;
