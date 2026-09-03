/*======================================================================
🥈 Silver Layer — Step 3: Data Transformation & Loading
========================================================================
📌 Overview

* This script performs the core Silver Layer transformation and loading process. It reads the raw data from the Bronze Layer,
  applies the cleaning, standardization, validation, and enrichment rules identified during the data exploration stage, and inserts the transformed data into the corresponding Silver Layer tables.
* The Bronze Layer remains completely unchanged and continues to preserve the original source data. 
  All cleaning and transformation logic is applied only while transferring data from Bronze → Silver, ensuring that the Silver Layer becomes a clean, standardized, and reliable version of the source data.
--------------------------------
🎯 Purpose

The primary objectives of this process are:
* Load data from Bronze tables into Silver tables.
* Preserve the original raw data in the Bronze Layer.
* Remove duplicate and invalid records where required.
* Remove unnecessary spaces and unwanted characters.
* Standardize categorical values such as gender, marital status, and country.
* Convert invalid date values and correct data types.
* Validate and correct sales, quantity, and price values.
* Create derived columns required for table relationships.
* Enrich data using business logic.
* Record the loading duration of individual tables and the complete batch.
* Automate the entire transformation process using a stored procedure.
--------------------------------
⚙️ Why Is the Entire Process Placed Inside a Stored Procedure?

The complete Silver Layer loading process is placed inside the silver.load_silver stored procedure to make the transformation process repeatable, automated, and consistent.
Instead of manually executing the truncation, transformation, and insertion queries every time new data needs to be loaded, the entire Silver Layer process can be executed using a single command:*/

EXEC silver.load_silver;
-- =============================================================================
-- SILVER LAYER LOADING PROCESS
-- =============================================================================
-- This stored procedure loads cleaned and standardized data from the Bronze
-- Layer into the Silver Layer without modifying the original Bronze tables.
--
-- The process performs:
-- 1. Truncation of existing Silver data.
-- 2. Extraction of data from Bronze tables.
-- 3. Data cleaning and standardization.
-- 4. Data validation and enrichment.
-- 5. Loading transformed data into Silver tables.
-- 6. Individual table and complete batch duration tracking.
-- 7. Error handling using TRY...CATCH.
-- =============================================================================
# sql scripts :

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE
        @start_time DATETIME,
        @end_time DATETIME,
        @startbatchtime DATETIME,
        @endbatchtime DATETIME;
    BEGIN TRY

        SET @startbatchtime = GETDATE();
        PRINT '==========================================================================================';
        PRINT '>> LOADING SILVER LAYER <<';
        PRINT '=========================================================================================='

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 1 : CRM_CUST_INFO';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : Silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;
        PRINT '>> Inserting Data Into : Silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_maritl_status,
            cst_gndr,
            cst_create_date)
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,  -- Removal of excess spacing within customer names.
            TRIM(cst_lastname) AS cst_lastname,
            CASE  -- Normalizing marital status values.
                WHEN TRIM(UPPER(cst_maritl_status)) = 'S' THEN 'Single'
                WHEN TRIM(UPPER(cst_maritl_status)) = 'M' THEN 'Married'
                ELSE 'Unkownn'
            END AS cst_maritl_status,
            CASE    -- Normalizing gender values.
                WHEN TRIM(UPPER(cst_gndr)) = 'M' THEN 'Male'
                WHEN TRIM(UPPER(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'Unknown'
            END AS cst_gndr,
            cst_create_date
        FROM (-- Intermediate result used to remove duplicate records and exclude NULL primary keys.
            SELECT *,
                ROW_NUMBER() OVER ( PARTITION BY cst_id ORDER BY cst_create_date DESC ) AS rn
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULl ) t
        WHERE rn = 1;

        SET @end_time = GETDATE();

        PRINT '>> Load duration :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
        ---------------------------------------- -------------------------------------------
        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 2 : CRM_PRD_INFO';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : Silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;
        PRINT '>> Inserting Data Into : Silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_key,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt)
        SELECT
            prd_id,
            REPLACE(LEFT(prd_key, 5), '-', '_') AS cat_key,  -- Extracting category key for creating relationships with ERP category tables.
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,   -- Extracting the product key that matches the sales details table.
            prd_nm,
            ISNULL(prd_cost, 0) AS prd_cost, -- Replacing NULL product costs with zero.
            CASE UPPER(TRIM(prd_line))  -- Standardizing product line values.
                WHEN 'R' THEN 'Road'
                WHEN 'M' THEN 'Mountain'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'Unkown'
            END AS prd_line,
            prd_start_dt,
            -- Data enrichment: Calculating the product end date based on the next product start date.
            DATEADD( DAY,-1, LEAD(prd_start_dt) OVER ( PARTITION BY prd_key ORDER BY prd_start_dt)) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Load duration :' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ ' seconds';
        ------------------------------------------- -------------------------------------------
        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 3 : CRM_SALES_DETAILS';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();
        PRINT '>> Truncating Table : Silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;
        PRINT '>> Inserting Data Into : Silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_order_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price)
        SELECT
            sls_order_num,
            sls_prd_key,
            sls_cust_id,
            -- Converting invalid dates to NULL and
            -- converting valid INT values into DATE.
            CASE
                WHEN sls_order_dt <= 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST( CAST(sls_order_dt AS NVARCHAR) AS DATE )
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST( CAST(sls_ship_dt AS NVARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt <= 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS NVARCHAR)AS DATE)
            END AS sls_due_dt,
            -- Validating sales values and recalculating incorrect or missing sales values.
            CASE 
                WHEN sls_sales <= 0 OR sls_sales IS NULL  OR sls_sales != sls_quantity * ABS(sls_price) THEN sls_quantity * ABS(sls_price)
                ELSE ABS(sls_sales)
            END AS sls_sales,
            sls_quantity,
            CASE  -- Correcting invalid or missing price values.
                WHEN sls_price <= 0 OR sls_price IS NULL THEN ABS(sls_sales) / NULLIF(sls_quantity, 0)
                ELSE ABS(sls_price)
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Load duration :'+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ ' seconds';
        ---------------------------------------- -------------------------------------------

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 4 : ERP_CUST_AZ12';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table : Silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;
        PRINT '>> Inserting Data Into : Silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen )
        SELECT
            CASE  -- Removing unwanted NAS prefix.
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            CASE  -- Handling future date outliers.
                WHEN bdate > GETDATE() THEN NULL
                ELSE bdate
            END AS bdate,
            CASE   -- Normalizing gender values.
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'Unkwown'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Load duration :'+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ ' seconds';
        ---------------------------------------- -------------------------------------------

        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 5 : ERP_LOC_A101';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table : Silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;
        PRINT '>> Inserting Data Into : Silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry )
        SELECT
            REPLACE(cid, '-', '') AS cid, -- Removing unwanted characters.
            CASE -- Standardizing country values.
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN cntry IS NULL OR TRIM(cntry) = '' THEN 'Unkown'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;


        SET @end_time = GETDATE();
        PRINT '>> Load duration :'+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ ' seconds';

        ---------------------------------------- -------------------------------------------
        PRINT '------------------------------------------------------------------------------------------';
        PRINT '>> TABLE 6 : ERP_PX_CAT_G1V2';
        PRINT '------------------------------------------------------------------------------------------';

        SET @start_time = GETDATE();

        PRINT '>> Truncating Table : Silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;
        PRINT '>> Inserting Data Into : Silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance)
        SELECT
            id,
            cat,
            subcat,
            maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Load duration :'+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR)+ ' seconds';
        PRINT '------------------------------------------------------------------------------------------';
        -- =========================================================================
        -- COMPLETE BATCH DURATION
        -- =========================================================================
        SET @endbatchtime = GETDATE();

        PRINT '>> Batch Loading duration :'+ CAST( DATEDIFF(second,@startbatchtime,@endbatchtime)AS NVARCHAR)+ ' seconds';
    END TRY
    -- =========================================================================
    -- ERROR HANDLING
    -- =========================================================================
    BEGIN CATCH
        PRINT '----------------------------------';
        PRINT '>> ERROR OCCURRED DURING LOADING SILVER LAYER';
        PRINT '>> Error Message : '+ ERROR_MESSAGE();
        PRINT '>> Error Number : '+ CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT '----------------------------------';
    END CATCH

END;
-- =============================================================================
-- EXECUTE SILVER LAYER LOADING PROCEDURE
EXEC silver.load_silver;
