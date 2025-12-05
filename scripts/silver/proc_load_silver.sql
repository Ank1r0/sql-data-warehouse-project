/*
Procedure: Load silver layer(Bronze -> silver)
Purpose: Extract the data from Bronze layer, transform the data and load into the silver layer

Param: None
Doesn't take or return any paramenters.

Usage: Exec silver.load_silver.


WARNING: THE TABLES BEFORE LOADING NEW DATA WILL BE TRUNCATED(THE DATA INSIDE THE TABLES WOULD BE DELETED PERMANENTLY)
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME,@batch_end_time DATETIME;

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=============================================';
		PRINT 'LOADING SILVER LAYER';
		PRINT '=============================================';

	
		--CRM BULK INSERT
		PRINT '---------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------';
		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info ;
		PRINT '>> Inserting Data Into: silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info ( -- with this query we inserted the clean data into the silver layer
				cst_id,
				cst_key,
				cst_firstname,
				cst_lastname,
				cst_material_status,
				cst_gndr,
				cst_create_date)
		SELECT 
		cst_id,
		cst_key,
		TRIM(cst_firstname) as cst_firstname, -- removing the unwanted spaces from the cst_firstname
		TRIM(cst_lastname) as cst_lastname, -- removing the unwanted spaces from the cst_lastname  
		case when UPPER(TRIM(cst_material_status)) = 'S' then 'Single' -- 
			when UPPER(TRIM(cst_material_status)) = 'M' then 'Married' -- 
			else 'n/a'
			end cst_material_status,
		case when UPPER(TRIM(cst_gndr)) = 'F' then 'Female' -- case when to place a full word name instead of F or M, F -> Female , M -> Male
			when UPPER(TRIM(cst_gndr)) = 'M' then 'Male' -- trim and upper used to remove spaces and transform data info upper case 
			else 'n/a'
			end cst_gndr,
		cst_create_date -- the date is already in correct type, no reason right now to work with it
		FROM (
		SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
		FROM bronze.crm_cust_info
		where cst_id is not null
		)t where flag_last = 1;

		SET @end_time = GETDATE();
		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		PRINT '---------';

		--//-- CRM_PRD_INFO --//-- CRM_PRD_INFO --//-- CRM_PRD_INFO --//--

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info ;
		PRINT '>> Inserting Data Into: silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info (
			prd_id,	
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
			)
		select prd_id,
			REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id, -- transform AA-AA into AA_AA like in bronze.erp_px_cat_g1v2 to match it
			SUBSTRING(prd_key,7,LEN(prd_key)) as prd_key, -- len(per_key) used because the lenght of the key is not static and could be changed from 13 to 16..
			prd_nm,
			ISNULL(prd_cost,0),
			case UPPER(TRIM(prd_line)) -- better case when function
				 when 'M' then 'Mountain' -- most common thing is to ask the source system expert to understand abbreviations and what they mean
				 when 'R' then 'Road'
				 when 'S' then 'Other Sales'
				 when 'T' then 'Touring'
				 else 'n/a'
				 end as prd_line,
			CAST(prd_start_dt AS DATE) as prd_start_dt,
			CAST(
				LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 
				AS DATE
			) as prd_end_dt
		from bronze.crm_prd_info

		SET @end_time = GETDATE();
			PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
			PRINT '---------';

		--//-- CRM_SALES_DETAILS --//-- CRM_SALES_DETAILS --//-- CRM_SALES_DETAILS --//--

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details ;
		PRINT '>> Inserting Data Into: silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt, 
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
		END AS sls_order_dt, -- we cannot convert the data from int to date, we have to convert it to varchar and then to date
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
		END AS sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
		END AS sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity* ABS(sls_price)
				THEN sls_quantity* ABS(sls_price)
			ELSE sls_sales
		END AS sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <= 0
				THEN sls_sales / NULLIF(sls_quantity,0) -- put a NULL instead of 0 to avoid error
			ELSE sls_price
		END AS sls_price
		from bronze.crm_sales_details;

		SET @end_time = GETDATE();
			PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
			PRINT '---------';

		PRINT '---------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------------';

		--//-- ERP_CUST_AZ12 --//-- ERP_CUST_AZ12 --//-- ERP_CUST_AZ12 --//--

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12 ;
		PRINT '>> Inserting Data Into: silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12
		(cid,
		bdate,
		gen
		)
		select 
		CASE WHEN cid  LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
			ELSE cid
			END AS temp_cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') then 'Female'
			 WHEN UPPER(TRIM(gen)) IN ('M','MALE') then 'Male'
			 ELSE 'n/a'
		END as gen
		from bronze.erp_cust_az12

		SET @end_time = GETDATE();
			PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
			PRINT '---------';

		--//-- ERP_LOC_A101 --//-- ERP_LOC_A101 --//-- ERP_LOC_A101 --//--

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101 ;
		PRINT '>> Inserting Data Into: silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101 (cid,cntry)
		SELECT 
		REPLACE(cid,'-','') cid,
		CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
			 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
			 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n\a'
			 ELSE cntry
		end as cntry
		FROM bronze.erp_loc_a101 

		SET @end_time = GETDATE();
			PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
			PRINT '---------';

		--//-- ERP_PX_CAT_G1V2 --//-- ERP_LOC_A101 --//-- ERP_LOC_A101 --//--

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2 ;
		PRINT '>> Inserting Data Into: silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2
		(id,
		cat,
		subcat,
		maintenance)
		SELECT 
		id,
		cat,
		subcat,
		maintenance
		from bronze.erp_px_cat_g1v2;
		SET @end_time = GETDATE();
			PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
			PRINT '---------';

		SET @batch_end_time = GETDATE();
		PRINT '=============================================';
		PRINT 'LOADING SILVER LAYER IS COMPLETED';
		PRINT 'OVERALL LOADING TIME: ' + CAST(DATEDIFF(SECOND, @batch_start_time,@batch_end_time) AS NVARCHAR)
		PRINT '=============================================';

	END TRY

	BEGIN CATCH
		PRINT '=============================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_MESSAGE() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR) + 'SECONDS.';
		PRINT '=============================================';
	END CATCH
END
