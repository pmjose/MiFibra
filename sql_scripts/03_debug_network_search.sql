-- Debug: Check if network documents exist in parsed_content
USE DATABASE MIFIBRA_AI_DEMO;
USE SCHEMA MIFIBRA_SCHEMA;

-- 1. Check what files exist on the stage
SELECT * FROM DIRECTORY('@MIFIBRA_DOC_STAGE') 
WHERE RELATIVE_PATH ILIKE '%network%';

-- 2. Check if network documents are in parsed_content
SELECT relative_path, file_url, LEFT(content, 500) as content_preview
FROM parsed_content
WHERE relative_path ILIKE '%network%';

-- 3. Check all paths in parsed_content (to see folder structure)
SELECT DISTINCT 
    REGEXP_SUBSTR(relative_path, '[^/]+', 1, 2) as folder_name,
    COUNT(*) as file_count
FROM parsed_content
GROUP BY folder_name
ORDER BY folder_name;

-- 4. Test the search service directly
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA.SEARCH_NETWORK_DOCS',
    '{
        "query": "data centre locations network capacity",
        "columns": ["content", "relative_path"],
        "limit": 3
    }'
);

-- 5. If no results, check if search service exists
SHOW CORTEX SEARCH SERVICES IN SCHEMA MIFIBRA_AI_DEMO.MIFIBRA_SCHEMA;

