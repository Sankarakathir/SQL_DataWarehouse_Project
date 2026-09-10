/*=============================================================================
Gold Layer – Business Data Transformation
===============================================================================
📌 Project Description :
-----------------------------
The Gold Layer is the final layer of the data warehouse where cleaned and integrated data from the Silver Layer is transformed into business-ready datasets.

In this project, the Gold Layer combines data from the CRM and ERP systems and organizes it into a dimensional data model consisting of:
* Customer Dimension (dim_customer)
* Product Dimension (dim_product)
* Sales Fact (fact_sales)

The purpose of this layer is to provide a simple, consistent, and analysis-ready structure for reporting, dashboards, SQL analysis, and business intelligence tools such as Power BI.
The Gold Layer uses CRM as the master source for customer information, while ERP information is integrated where required. The sales fact table then connects sales transactions to the customer and product dimensions using surrogate keys.*/

/* =============================================================================
Purpose of the Gold Layer :
-----------------------------
The Gold Layer transforms technically cleaned Silver-layer data into business-friendly data.

Main objectives:
* DATA INTEGRATION → Combine CRM and ERP information into unified business entities.
* DATA VALIDATION → Check for duplicate records before performing joins.
* DATA STANDARDIZATION → Resolve conflicting attributes such as customer gender using CRM as the master source.
* DATA MODELING → Create dimension and fact views for analytical use.
* SURROGATE KEYS → Generate stable analytical keys using ROW_NUMBER().
* BUSINESS READY → Present meaningful column names and relationships for reporting and BI.
* SCD TYPE 1 → Use the latest/current product structure without maintaining historical product versions.

================================================================================= */
/* 🏗️ Gold Layer Structure

┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│crm_cust_info    │   │erp_cust_az12    │   │erp_loc_a101     │   │crm_prd_info     │   │erp_px_cat_g1v2  │   │crm_sales_details│
│   SILVER        │   │   SILVER        │   │   SILVER        │   │   SILVER        │   │   SILVER        │   │     SILVER      │
└───────┬─────────┘   └───────┬─────────┘   └───────┬─────────┘   └───────┬─────────┘   └───────┬─────────┘   └───────┬─────────┘
        │                     │                     │                     │                     │                     │
        └─────────────────────┼─────────────────────┘                     │                     │                     │
                              │                                           └─────── ─┬── ────────┘                     │
                              ▼                                                     │                                 │
                    ┌─────────────────────┐                                         │                                 │
                    │   gold.dim_customer │                                         │                                 │
                    │        VIEW         │                                         │                                 │
                    └──────────┬──────────┘                                         │                                 │
                               │                                                    ▼                                 │
                               │                                          ┌─────────────────────┐                     │
                               │                                          │   gold.dim_product  │                     │
                               │                                          │        VIEW         │                     │
                               │                                          └──────────┬──────────┘                     │
                               │                                                     │                                │
                               └──────────────────────────────┬──────────────────────┘                                │
                                                              │                                                       │
                                                              │                                                       │
                                                              └──────────────────────────┬────────────────────────────┘
                                                                                         ▼
                                                                               ┌─────────────────────┐
                                                                               │   gold.fact_sales   │
                                                                               │        VIEW         │
                                                                               └─────────────────────┘
*/

Scripts :
-- =============================================================
-- GOLD LAYER : CUSTOMER TABLE
-- CRM + ERP CUSTOMER + ERP LOCATION
-- =============================================================
CREATE VIEW gold.dim_customer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key,
    ci.cst_id AS customer_id,
    ci.cst_key AS customer_number,
    ci.cst_firstname AS first_name,
    ci.cst_lastname AS last_name,
    lc.cntry AS country,
    ci.cst_maritl_status AS marital_status,
    CASE
        WHEN ci.cst_gndr != 'Unknown' THEN ci.cst_gndr
        WHEN ca.gen = 'Unkwown' THEN 'Unknown'
        ELSE ISNULL(ca.gen, 'Unknown')
    END AS gender,
    ca.bdate AS birthdate,
    ci.cst_create_date AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 lc
    ON ci.cst_key = lc.cid;

-- =============================================================
-- GOLD LAYER : PRODUCT TABLE
-- CRM PRODUCT + ERP CATEGORY
-- =============================================================
CREATE VIEW gold.dim_product AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pr.prd_start_dt, pr.prd_key) AS product_key,
    pr.prd_id AS product_id,
    pr.prd_key AS product_number,
    pr.prd_nm AS product_name,
    pr.cat_key AS category_key,
    ca.cat AS category,
    ca.subcat AS subcategory,
    ca.maintenance,
    pr.prd_cost AS product_cost,
    pr.prd_line AS product_line,
    pr.prd_start_dt AS start_date
FROM silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 ca
    ON pr.cat_key = ca.id
WHERE pr.prd_end_dt IS NULL;

-- =============================================================
-- GOLD LAYER : SALES TABLE
-- =============================================================
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_order_num AS order_number,
    dp.product_key,
    dc.customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt AS shipping_date,
    sd.sls_due_dt AS due_date,
    sd.sls_sales AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_customer dc
    ON sd.sls_cust_id = dc.customer_id
LEFT JOIN gold.dim_product dp
    ON sd.sls_prd_key = dp.product_number;





