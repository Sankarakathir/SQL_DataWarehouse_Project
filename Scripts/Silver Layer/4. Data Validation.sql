/* ==============================================================
🥈 Silver Layer — Step 4: Data Validation
==================================================================
📌 Overview :
--------------------------------
* This script represents the final data validation stage of the Silver Layer. After the Bronze data has been cleaned, standardized, transformed, and loaded into the Silver tables, these queries are used to verify whether the required transformations have been successfully completed.
* The validation focuses on checking standardized values, date relationships, sales calculations, price and quantity consistency, customer identifiers, future-date outliers, gender values, and country values. 
  The purpose is to confirm that the Silver Layer contains clean and logically consistent data before it is used for the next stage of the Data Warehouse.

🎯 Purpose :
--------------------------------
The primary objectives of this validation process are:
* Verify that categorical values have been standardized.
* Confirm that product start and end dates are logically correct.
* Validate order, shipment, and due-date relationships.
* Confirm that sales values are consistent with quantity and price.
* Verify that price calculations are correct.
* Check customer identifiers after transformation.
* Confirm that future birth-date outliers have been handled.
* Verify standardized gender values.
* Confirm standardized country values.
--------------------------------------------------------------------*/
# Sql Scripts :

-------------------------------------------------------------------------------------------
-- Data Validation Process : 
-------------------------------------------------------------------------------------------
/* change the schema names from bronze into silver and run the query we used to identify data integrety & errors
if all the tables return empty and standardised then the table is standardised */
------------------------------------------------------------------------------------------
-- TABLE 1 : SILVER.CRM_CST_CUST_INFO 
------------------------------------------------------------------------------------------
-- step 1 : checking null & duplicated columns by counts the primary keys
-- Expected results : empty table
select cst_id, count(*) as counts
from silver.crm_cust_info
group by cst_id
having count(*) >1 or cst_id is null ;	
------------------------------------------------
-- step 2: checking for chacater spacing trailing space both front and back 
-- Expected results empty  columns
select
	cst_firstname,
	LEN( cst_firstname ) as before_trim,
	len(trim(cst_firstname)) as after_trim,
	LEN( cst_firstname )-len(trim(cst_firstname)) as len_diffence
from silver.crm_cust_info
where LEN( cst_firstname )-len(trim(cst_firstname)) >=1;
-------------
select
	cst_lastname,
	LEN( cst_lastname ) as before_trim,
	len(trim(cst_lastname)) as after_trim,
	LEN( cst_lastname )-len(trim(cst_lastname)) as len_diffence
from silver.crm_cust_info
where LEN( cst_lastname )-len(trim(cst_lastname)) >=1;
----------------------------------------------------
-- step 3: checking for distinct columns in marital status and rename the columns 
-- Expected results : normalized data & null handled 
select distinct cst_maritl_status
from silver.crm_cust_info; -- we need to convert the null to unknow and provide full forms for other 
--------------
select distinct cst_gndr
from silver.crm_cust_info;

------------------------------------------------------------------------------------------
-- TABLE 2 : SILVER.CRM_CST_PRD_INFO 
------------------------------------------------------------------------------------------
select * from silver.crm_prd_info;

-- Task 1 : checking for duplicates and nulls in primary key
select prd_id , count(*) as counts
from silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;
----------------------------------------
-- Task 2 : Is extracting prd_key and spiltting into two columns making it more easier for data connection
----------------------------------------
-- Task 3 : Checking for trailing spaces
select prd_nm from silver.crm_prd_info
where prd_nm != trim(prd_nm);
-----------------------------------------
-- Task 4 : Null handling  
-- Expected results :  null handled with no null
select count(*)
from silver.crm_prd_info
where prd_cost is null ;
-----------------------------------------
-- Task 5 : normalizing values by mapping them and replace the null value
-- expected results : Standardised values
select distinct prd_line
from silver.crm_prd_info;
-----------------------------------------
-- Task 6 : checking the correctness of the dates field if end dt < start dt
select 
	prd_key,
	prd_start_dt,
	prd_end_dt
from silver.crm_prd_info
where prd_end_dt <= prd_start_dt;

------------------------------------------------------------------------------------------
-- TABLE 3 : SILVER.CRM_CST_SALES_DETAILS 
------------------------------------------------------------------------------------------
-- Task 1: column : sls_order_dt, sls_ship_dt, sls_due_dt conversion of int to date is required
-- also check is theres any  negative, zero c present in the order_date all <0 values maust be converted to null before conversion
-- also check for any data with less len than required for an date format 8
-- check if all the above required are completed 
-- ----------------------------------------------------------
select * from silver.crm_sales_details
where sls_order_dt > sls_ship_dt or sls_order_dt > sls_due_dt;

-- Task 2: column : sls_sales,sls_quantity , sls_price checking for null values , handling negative and zeros 
-- checking for data quality by multiplying price * quantity and check if it matchs sales
-- checking is prices values match the formula sales/quantity 
-- check if all the above required are completed 

select sls_sales,sls_quantity,sls_price
from silver.crm_sales_details
where sls_sales is null or sls_sales <=0 -- checked for zeros and negative and null values
or sls_sales != sls_quantity * sls_price; -- checking fro times when sales is not equal to price* quantity
-- requires reformulatting the sales amount for negative and null values else remains the same amount

select sls_price,sls_quantity,sls_price
from silver.crm_sales_details
where sls_price <= 0 -- checking if price is negative or 0
 or sls_price != sls_sales/sls_quantity ; -- checking if price amount is correct 
 -- requires reformulatting the price amount for negative and null values else remains the same amount

 ------------------------------------------------------------------------------------------
-- TABLE 4 : SILVER.CRM_ERP_CUST_AZ12
------------------------------------------------------------------------------------------
-- Task 1: column : Check if cid can be joined with cust_info if not make the changes required to join them
-- Requires extractiion of cid  substring(cid,4,length(cid)) for only values with nas as prefix
select cid from silver.erp_cust_az12;

-- Task 2 : Checking for outlier in the date field for extreme date fields
-- always for date field check the outliers
select * from silver.erp_cust_az12
where bdate > getdate();-- need to replace these futuristic dbate values

-- Task 3 : Checking for the types of gen from the gender column to standardise and normalise them using mapping
-- Expected results : should be normalized top male , female , Unkowwn
select count(*),gen 
from silver.erp_cust_az12
group by gen
having count(*) >1;

select distinct  gen from silver.erp_cust_az12;
 ------------------------------------------------------------------------------------------
-- TABLE 5 : SILVER.CRM_ERP_LOC_A101
------------------------------------------------------------------------------------------
-- Task 1 : Standardizing the cid to match with cst_key requires removal of unwanted characters and spacing 
-- expected results : being able to join with other cust tables
select cid, len(cid) as len from silver.erp_loc_a101;

-- Task 2 : Requires standardisation and normalization of country names
-- Expected results : map them into provided standardized names 
select distinct cntry from silver.erp_loc_a101;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
