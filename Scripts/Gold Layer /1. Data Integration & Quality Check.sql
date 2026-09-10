-- ==========================================================================================================================
-- >> GOLD LAYER : QUALITY CHECKS
-- ==========================================================================================================================
-- 1. CUSTOMER QUALITY CHECKS
-- CRM CUSTOMER + ERP CUSTOMER + ERP LOCATION
-- -------------------------------------------------------------
-- TASK 1 : CHECK FOR DUPLICATED CUSTOMER DATA
SELECT
    customer_key, COUNT(*) AS duplicate_count
FROM (SELECT
        ci.cst_id AS customer_number,
        ci.cst_key AS customer_key,
        ci.cst_firstname AS first_name,
        ci.cst_lastname AS last_name,
        ci.cst_maritl_status AS marital_status,
        ci.cst_gndr,
        ci.cst_create_date AS create_date,
        ca.bdate AS birthdate,
        ca.gen,
        lc.cntry AS country
    FROM silver.crm_cust_info ci
    LEFT JOIN silver.erp_cust_az12 ca
        ON ci.cst_key = ca.cid
    LEFT JOIN silver.erp_loc_a101 lc
        ON ci.cst_key = lc.cid) t
GROUP BY customer_key
HAVING COUNT(*) > 1;
-- -------------------------------------------------------------
-- TASK 2 : CHECK CUSTOMER GENDER INTEGRATION
-- CRM IS USED AS MASTER SOURCE
SELECT DISTINCT
    ci.cst_gndr AS crm_gender,
    ca.gen AS erp_gender,
    CASE
        WHEN ci.cst_gndr <> 'Unknown' THEN ci.cst_gndr
        ELSE IFNULL(ca.gen, 'Unknown')
    END AS final_gender
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 lc
    ON ci.cst_key = lc.cid;
-- -------------------------------------------------------------
-- TASK 3 : CHECK FINAL CUSTOMER VIEW
SELECT * FROM gold.dim_customer;

-- =============================================================
-- 2. PRODUCT QUALITY CHECKS
-- CRM PRODUCT + ERP CATEGORY
-- -------------------------------------------------------------
-- TASK 1 : CHECK CURRENT PRODUCT RECORDS
-- SCD TYPE 1 APPROACH KEEPING ONLY CURRENT PRODUCTS ARE REQUIRED
SELECT
    pr.prd_id,
    pr.cat_key,
    pr.prd_key,
    pr.prd_nm,
    pr.prd_cost,
    pr.prd_line,
    pr.prd_start_dt,
    ca.cat,
    ca.subcat,
    ca.maintenance
FROM silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ca
    ON pr.cat_key = ca.id
WHERE pr.prd_end_dt IS NULL;
-- -------------------------------------------------------------
-- TASK 2 : CHECK FOR DUPLICATED PRODUCT DATA
SELECT
    prd_id,COUNT(*) AS duplicate_count
FROM ( SELECT
        pr.prd_id,
        pr.cat_key,
        pr.prd_key,
        pr.prd_nm,
        pr.prd_cost,
        pr.prd_line,
        pr.prd_start_dt,
        ca.cat,
        ca.subcat,
        ca.maintenance
    FROM silver.crm_prd_info pr
    LEFT JOIN silver.erp_px_cat_g1v2 ca
        ON pr.cat_key = ca.id
    WHERE pr.prd_end_dt IS NULL) t
GROUP BY prd_id
HAVING COUNT(*) > 1;
-- ------------------------------------------------------------
-- TASK 3 : CHECK FINAL PRODUCT VIEW
SELECT * FROM gold.dim_product;

-- =============================================================
-- 3. SALES QUALITY CHECKS
-- CRM SALES + CUSTOMER + PRODUCT
-- -------------------------------------------------------------
-- TASK 1 : CHECK SOURCE SALES RECORD COUNT
SELECT  COUNT(*) AS sales_record_count
FROM silver.crm_sales_details;
-- -------------------------------------------------------------
-- TASK 2 : CHECK FINAL SALES VIEW
SELECT * FROM gold.fact_sales;
-- -------------------------------------------------------------
-- TASK 3 : CHECK FOR MISSING CUSTOMER KEYS
-- Every sale should connect to a customer dimension record
SELECT COUNT(*) AS missing_customer_key
FROM gold.fact_sales
WHERE customer_key IS NULL;
-- -------------------------------------------------------------
-- TASK 4 : CHECK FOR MISSING PRODUCT KEYS
-- Every sale should connect to a product dimension record
SELECT COUNT(*) AS missing_product_key
FROM gold.fact_sales
WHERE product_key IS NULL;
-- -------------------------------------------------------------
-- TASK 6 : CHECK FOR DUPLICATED SALES ORDERS
SELECT order_number, COUNT(*) AS duplicate_count
FROM gold.fact_sales
GROUP BY order_number
HAVING COUNT(*) > 1;
