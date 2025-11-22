CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME,@batch_end_time DATETIME;

	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '=============================================';
		PRINT 'LOADING BRONZE LAYER';
		PRINT '=============================================';

		--CRM BULK INSERT
		PRINT '---------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '---------------------------------------------';

		SET @start_time = GETDATE();
		Print '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;

		Print '>> Inserting Data Into: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\OwnP\datasets\source_crm\cust_info.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_time = GETDATE();
		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		PRINT '---------';

		SET @start_time = GETDATE();
		Print '>> Truncating Table: bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info;

		Print '>> Inserting Data Into: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		FROM 'C:\OwnP\datasets\source_crm\prd_info.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		PRINT '---------';

		SET @start_time = GETDATE();
		Print '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;

		Print '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\OwnP\datasets\source_crm\sales_details.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';

		--ERP BULK INSERT
		PRINT '---------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '---------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;

		PRINT '>> Inserting Data Into: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		FROM 'C:\OwnP\datasets\source_erp\cust_az12.csv'
		with (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		PRINT '---------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;

		PRINT '>> Inserting Data Into: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		FROM 'C:\OwnP\datasets\source_erp\loc_a101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)
		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		PRINT '---------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table: bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;

		PRINT '>> Inserting Data Into: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'C:\OwnP\datasets\source_erp\px_cat_g1v2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		)

		PRINT ' >> Load Duration: ' + CAST( DATEDIFF(second, @start_time,@end_time) AS NVARCHAR ) + ' seconds.';
		SET @batch_end_time = GETDATE();
		PRINT '=============================================';
		PRINT 'LOADING BRONZE LAYER IS COMPLETED';
		PRINT 'OVERALL LOADING TIME: ' + CAST(DATEDIFF(SECOND, @batch_start_time,@batch_end_time) AS NVARCHAR)
		PRINT '=============================================';
	END TRY

	BEGIN CATCH
		PRINT '=============================================';
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Number' + CAST (ERROR_MESSAGE() AS NVARCHAR);
		PRINT 'Error State' + CAST (ERROR_STATE() AS NVARCHAR) + 'SECONDS.';
		PRINT '=============================================';
	END CATCH
END;
