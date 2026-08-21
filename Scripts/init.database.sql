/*
================================================================================
DATA WAREHOUSE INITIALIZATION
================================================================================

Project: Building Modern Data Warehouse
Architecture: Medallion Architecture
Database: datawarehouse

DESCRIPTION:
This script initializes the project's data warehouse environment.

The script performs the following steps:

1. Checks whether the 'datawarehouse' database already exists.
2. Drops the existing database if found.
3. Creates a fresh 'datawarehouse' database.
4. Switches the active database context to 'datawarehouse'.
5. Creates three schemas following the Medallion Architecture:
      - bronze : Raw / source data
      - silver : Cleaned and transformed data
      - gold   : Business-ready analytical data

This approach ensures that the development environment starts from a
clean and consistent state whenever the script is executed.

MEDALLION ARCHITECTURE:

                 SOURCE DATA
                     │
                     ▼
                ┌─────────┐
                │ BRONZE  │
                │ Raw Data│
                └────┬────┘
                     │
                     ▼
                ┌─────────┐
                │ SILVER  │
                │ Cleaned │
                │  Data   │
                └────┬────┘
                     │
                     ▼
                ┌─────────┐
                │  GOLD   │
                │Business │
                │  Data   │
                └─────────┘
                     │
                     ▼
             Power BI / Analytics

================================================================================
*/


/*
================================================================================
STEP 1: DROP EXISTING DATABASE
================================================================================

Purpose:
Remove the existing datawarehouse database if it already exists.

Why:
This allows the entire warehouse environment to be recreated from scratch
without manually deleting existing objects.

WARNING:
DROP DATABASE permanently removes all objects and data stored inside the
database.
================================================================================
*/

DROP DATABASE IF EXISTS datawarehouse;


/*
================================================================================
STEP 2: CREATE DATABASE
================================================================================

Purpose:
Create a new empty database that will contain all warehouse objects.

Database Name:
datawarehouse
================================================================================
*/

CREATE DATABASE datawarehouse;


/*
================================================================================
STEP 3: SELECT DATABASE
================================================================================

Purpose:
Set 'datawarehouse' as the active database so that subsequent schemas,
tables, views, and other objects are created inside this database.
================================================================================
*/

USE datawarehouse;


/*
================================================================================
STEP 4: CREATE BRONZE SCHEMA
================================================================================

Purpose:
The Bronze layer stores raw/source data with minimal transformation.

Typical contents:
- Raw CSV imports
- Source-system extracts
- Original transaction data
- Initial ingestion tables

Example:

bronze.customer_raw
bronze.sales_raw
bronze.product_raw

The Bronze layer acts as the historical/raw landing zone.
================================================================================
*/

CREATE SCHEMA bronze;


/*
================================================================================
STEP 5: CREATE SILVER SCHEMA
================================================================================

Purpose:
The Silver layer contains cleaned, standardized, and transformed data.

Typical activities:
- Removing duplicates
- Handling NULL values
- Standardizing text
- Correcting data types
- Validating records
- Applying business rules
- Resolving data-quality issues

Example:

silver.customer
silver.sales
silver.product

The Silver layer provides reliable and analysis-ready data.
================================================================================
*/

CREATE SCHEMA silver;


/*
================================================================================
STEP 6: CREATE GOLD SCHEMA
================================================================================

Purpose:
The Gold layer contains business-ready data designed for analytics,
reporting, dashboards, and decision-making.

Typical contents:
- Business KPIs
- Aggregated datasets
- Dimension tables
- Fact tables
- Analytical views
- Reporting-ready tables

Example:

gold.customer_summary
gold.product_performance
gold.sales_summary
gold.customer_segmentation

The Gold layer is the primary consumption layer for Power BI and
business intelligence reporting.
================================================================================
*/


CREATE SCHEMA gold;


/*
================================================================================
DATA WAREHOUSE INITIALIZATION COMPLETE
================================================================================

Database:
    datawarehouse

Schemas:
    bronze  -> Raw/source data
    silver  -> Cleaned/transformed data
    gold    -> Business-ready analytical data

NEXT STEPS:

1. Load source data into Bronze.
2. Clean and transform Bronze data into Silver.
3. Apply business logic and create analytical models in Gold.
4. Connect Power BI to the Gold layer.
5. Build dashboards and analytical reports.

================================================================================
*/
