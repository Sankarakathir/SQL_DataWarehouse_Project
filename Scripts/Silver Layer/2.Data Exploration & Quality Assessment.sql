--===================================================================
-- 🥈 Silver Layer — Step 2: Data Exploration & Quality Assessment 
--===================================================================
/* 📌 Overview
This script represents the second step in the Silver Layer process, where the Bronze Layer tables are explored to identify data anomalies, inconsistencies, formatting issues, and potential transformation requirements.*/
--===================================================================
/* 🎯 Purpose
--===================================================================
The primary objectives of this data exploration process are:
* Identify data quality issues in the Bronze Layer.
* Detect unnecessary spaces and formatting inconsistencies.
* Identify invalid or incorrectly formatted dates.
* Validate sales, quantity, and price calculations.
* Examine customer and product keys for proper table connections.
* Identify future or extreme date values.
* Review inconsistent categorical values such as gender and country.
* Determine which columns require cleaning, standardization, enrichment, or transformation.
This process helps ensure that transformation rules are based on the actual issues identified within the source data. */

# sql scripts :
--===================================================================
-- TABLE 1 : BRONZE.CRM_CUST_INFO
--===================================================================
-- >>> Task 1 : checking null & duplicated columns by counts the primary keys
--Expected results : empty table
select cst_id, count(*) as counts
from bronze.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null ;	
---------------------------------------------
-- >>>  Task 2: checking for chacater spacing trailing space both front and back 
-- Expected results matching columns 
select
	cst_firstname,
	LEN( cst_firstname ) as before_trim,
	len(trim(cst_firstname)) as after_trim,
	LEN( cst_firstname )-len(trim(cst_firstname)) as len_diffence
from bronze.crm_cust_info
where LEN( cst_firstname )-len(trim(cst_firstname)) >=1;
-------------
select
	cst_lastname,
	LEN( cst_lastname ) as before_trim,
	len(trim(cst_lastname)) as after_trim,
	LEN( cst_lastname )-len(trim(cst_lastname)) as len_diffence
from bronze.crm_cust_info
where LEN( cst_lastname )-len(trim(cst_lastname)) >=1;
---------------------------------------------
-- >>>  Task 3: checking for distinct columns in marital status and rename the columns 
-- Expected results : normalized data & null handled 
select distinct cst_maritl_status
from bronze.crm_cust_info; -- we need to convert the null to unknow and provide full forms for other 
---------
select distinct cst_gndr
from bronze.crm_cust_info;

--===================================================================
-- TABLE 2 : BRONZE.CRM_PRD_INFO
--===================================================================
-- >>>  Task 1 : checking for duplicates and nulls in primary key
select prd_id , count(*) as counts
from bronze.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;
-----------------------------------------
-- >>>  Task 2 : Is extracting prd_key and spiltting into two columns making it more easier for data connection
-----------------------------------------
-- >>>  Task 3 : Checking for trailing spaces
select prd_nm from bronze.crm_prd_info
where prd_nm != trim(prd_nm);
-----------------------------------------
-- >>>  Task 4 : Null handling  
-- Expected results :  null handled with no null
select count(*)
from bronze.crm_prd_info
where prd_cost is null ;
-----------------------------------------
-- >>>  Task 5 : normalizing values by mapping them and replace the null value
-- expected results : Standardised values
select distinct prd_line
from bronze.crm_prd_info;
-----------------------------------------
-- >>>  Task 6 : checking the correctness of the dates field if end dt < start dt
select 
	prd_key,
	prd_start_dt,
	prd_end_dt
from bronze.crm_prd_info
where prd_end_dt <= prd_start_dt;
/* we have alot of dates field where end date is earlier to start date
so we will change the end dates to leading start date -1 */

--===================================================================
-- TABLE 3 : BRONZE.CRM_SALES_DETAILS
--===================================================================
-- >>>  Task 1: Column : sls_order_num
-- Checking for excess spacing within the column.
-- Expected result: No trailing spaces should be present.
SELECT *
FROM bronze.crm_sales_details
WHERE sls_order_num != TRIM(sls_order_num);
-----------------------------------------
-- >>>  Task 2: Date Columns
-- sls_order_dt, sls_ship_dt, sls_due_dt
-- Conversion from INT to DATE is required.
-- Checking for invalid data before conversion.
-- Zero and negative values must be handled before conversion.
-- Values with a length other than 8 are also identified.

SELECT sls_order_dt
FROM bronze.crm_sales_details -- Requires data enrichment by handling zero and negative values and converting them into NULL before conversion.
WHERE sls_order_dt <= 0 OR LEN(sls_order_dt) != 8;

SELECT sls_ship_dt
FROM bronze.crm_sales_details -- Requires conversion from INT to string and then string to DATE.
WHERE sls_ship_dt <= 0 OR LEN(sls_ship_dt) != 8;

SELECT sls_due_dt
FROM bronze.crm_sales_details -- Requires conversion from INT to string and then string to DATE.
WHERE sls_due_dt <= 0 OR LEN(sls_due_dt) != 8;
-----------------------------------------
-- >>> Task 3: Sales, Quantity and Price Validation
-- Columns: sls_sales, sls_quantity, sls_price
-- Checking for NULL values, negative values, and zero values.
-- Checking data quality by validating:
-- Sales = Quantity * Price
-- Price = Sales / Quantity

SELECT sls_sales
FROM bronze.crm_sales_details
WHERE sls_sales IS NULL OR sls_sales <= 0  -- Checking cases where sales is not equal to quantity * price.
OR sls_sales != sls_quantity * sls_price; -- Requires reformatting of sales amounts for negative and NULL values.
-- Otherwise, the existing sales amount remains unchanged.

SELECT sls_quantity
FROM bronze.crm_sales_details
WHERE sls_quantity IS NULL OR sls_quantity <= 0; -- sls_quantity does not require data enrichment.

SELECT sls_price
FROM bronze.crm_sales_details
WHERE sls_price <= 0 -- Checking whether the price matches the sales calculation.
OR sls_price != sls_sales / sls_quantity;
-- Requires reformatting of price values for negative and NULL values.
-- Otherwise, the existing price amount remains unchanged.

--===================================================================
-- TABLE 4 : BRONZE.ERP_CUST_AZ12
--===================================================================
/*
Checking whether a transformation function can be used during joining
and whether the extracted customer key matches crm_cust_info.cst_key.

SELECT
    erp.cid,
    SUBSTRING(cid, 4, LENGTH(cid)) AS cust_key,
    crm.cst_key,
    erp.bdate,
    erp.gen
FROM bronze.erp_cust_az12 erp
JOIN bronze.crm_cust_info crm
    ON SUBSTRING(cid, 4, LENGTH(cid)) = crm.cst_key; */

-- >>> Task 1: Check whether cid can be joined with crm_cust_info.
-- If not, identify the changes required for joining.
-- Requires extraction using SUBSTRING for values with the NAS prefix.
SELECT cid
FROM bronze.erp_cust_az12;

-- >>> Task 2: Checking for date outliers and extreme date values.
-- Future birth dates need to be identified and handled.
SELECT *
FROM bronze.erp_cust_az12
WHERE bdate > GETDATE();

-- >>> Task 3: Checking the different values in the gender column
-- for standardization and normalization using mapping.
-- Expected result: Male, Female, and Unknown.
SELECT COUNT(*), gen
FROM bronze.erp_cust_az12
GROUP BY gen
HAVING COUNT(*) > 1;

SELECT DISTINCT gen
FROM bronze.erp_cust_az12;


--===================================================================
-- TABLE 5 : BRONZE.ERP_LOC_A101
--===================================================================
-- >>> Task 1: Standardizing cid to match with cst_key.
-- Checking the identifier for unwanted characters and spacing.
-- Expected result: cid should be suitable for joining with
-- other customer-related tables.
SELECT
    cid,
    LEN(cid) AS len
FROM bronze.erp_loc_a101;

-- >>>  Task 2: Checking country names for standardization
-- and normalization.
-- Expected result: Country values can be mapped into
-- standardized country names.
SELECT DISTINCT cntry
FROM bronze.erp_loc_a101;

--===================================================================
-- TABLE 6 : BRONZE.ERP_PX_CAT_G1V2
--===================================================================
SELECT *
FROM bronze.erp_px_cat_g1v2;

-- >>> Task 1: Checking for Unwanted Spaces
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat);  -- No unwanted spacing identified in the cat column.

SELECT subcat
FROM bronze.erp_px_cat_g1v2
WHERE subcat != TRIM(subcat); -- No unwanted spacing identified in the subcat column.

SELECT maintenance
FROM bronze.erp_px_cat_g1v2
WHERE maintenance != TRIM(maintenance); -- No unwanted spacing identified in the maintenance column.

-- >>>  Task 2: Checking for Standardization Issues
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2; -- No standardization required.

SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2; -- No standardization required.

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2; -- No standardization required.
--===================================================================
