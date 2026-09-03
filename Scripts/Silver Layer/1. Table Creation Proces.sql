-- ============================================================================
/* 🥈 Silver Layer — Step 1: Table Creation
-- ============================================================================
 📌 Overview

This script represents the **first step in building the Silver Layer** of the Data Warehouse: **creating the Silver Layer table structure**.

In this process, the required CRM and ERP tables are created inside the `silver` schema with the appropriate column names and data types. Before creating each table, the script checks whether the table already exists and drops it if necessary, ensuring that the Silver Layer structure can be recreated consistently.

The Silver tables are designed to receive data from the Bronze Layer during the upcoming transformation process. The tables also include a `dwh_create_date` column to record the Data Warehouse creation timestamp.*/
-- ============================================================================
/*  🎯 Purpose

The main objectives of this initial Silver Layer process are:

* Create the dedicated `silver` schema.
* Define the required CRM and ERP table structures.
* Assign the appropriate data types to each column.
* Drop and recreate existing tables when required.
* Add `dwh_create_date` for Data Warehouse record tracking.
* Prepare the Silver Layer for the upcoming data transformation and loading process.*/
-- ============================================================================
# 💻 SQL Script
----------------

# CRM Source Tables
  
-- >> CRM Customer Information
```sql
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info( 
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_maritl_status NVARCHAR(50),
    cst_gndr NVARCHAR(50),
    cst_create_date DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
----------------
-- >> CRM Product Information
```sql
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id INT, 
    cat_key NVARCHAR(50),
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_dt DATE,
    prd_end_dt DATE,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
----------------
-- >> CRM Sales Details
```sql
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details ( 
    sls_order_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt DATE,
    sls_ship_dt DATE, 
    sls_due_dt DATE,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
----------------------------------------------------------------
# ERP Source Tables

-- >> ERP Customer Information
```sql
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid NVARCHAR(50),
    bdate DATE,
    gen NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
----------------
-- >> ERP Location Information
```sql
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid NVARCHAR(50),
    cntry NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
----------------
-- >> ERP Product Category Information
```sql
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id NVARCHAR(50),
    cat NVARCHAR(50),
    subcat NVARCHAR(50),
    maintenance NVARCHAR(50),
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);```
-- ============================================================================
# 🔄 Table Creation Strategy

/* Each Silver Layer table follows a consistent approach:
```text
Check Whether Table Exists
           │
           ▼
      Table Exists?
       │         │
      YES        NO
       │         │
       ▼         │
   DROP TABLE    │
       │         │
       └────┬────┘
            ▼
      CREATE TABLE
            │
            ▼
 Silver Table Ready
```
This approach ensures that the required table structure is available and can be recreated whenever changes are made to the Data Warehouse design.*/
-- ============================================================================
# 🚀 Next Steps in the Silver Layer

/* After completing the **table creation process**, the Silver Layer will move through the following stages:

### 2. Identify Data Anomalies and Inconsistencies

The Bronze Layer data will be explored to identify potential issues such as duplicate records, missing values, inconsistent formats, invalid values, and other data quality problems.

### 3. Data Cleaning and Standardization

Based on the identified issues, transformation rules will be applied to clean the data, remove unnecessary spaces, standardize categorical values, handle missing values, correct formatting issues, and ensure consistent data types.

### 4. Data Validation

The transformed data will be validated using checks such as row counts, duplicate checks, NULL checks, and business-rule validation to ensure that the cleaned data is accurate and reliable.

### 5. Load Cleaned Data into the Silver Layer

Once the data has been transformed and validated, the cleaned data will be loaded from the Bronze Layer into the corresponding Silver tables.

### 6. Automate the Silver Layer Using a Stored Procedure

Finally, the complete Silver Layer loading and transformation process will be placed inside a stored procedure. This will allow the entire process to be executed repeatedly and consistently whenever the Data Warehouse needs to be refreshed.
-- ============================================================================
```text
STEP 1
Table Creation
     │
     ▼
STEP 2
Identify Anomalies &
Inconsistencies
     │
     ▼
STEP 3
Data Cleaning &
Standardization
     │
     ▼
STEP 4
Data Validation
     │
     ▼
STEP 5
Load Cleaned Data
into Silver Tables
     │
     ▼
STEP 6
Automate Using
Stored Procedure
     │
     ▼
Clean & Reliable
Silver Layer
```
This completes the **initial setup phase of the Silver Layer** and prepares the Data Warehouse for the core transformation process. */
-- ============================================================================
