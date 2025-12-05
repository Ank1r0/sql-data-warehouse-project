/*
Queries that were used to check the quality of the data.
*/

--QUERIES IS MISSING BECAUSE OF THE FILE ERROR, ALL THE QUERIES THAT WERE USED WILL BE ADDED LATER
-- BASED ON THIS PROJECT WERE WRITTEN MY OWN MATERIAL, Google Docs:https://docs.google.com/document/d/11j_mEWk9x7XYfco9rIrojGwntOCK1VID31NixYglSg0/edit?usp=sharing


--check the cid

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



select 
bdate 
from silver.erp_cust_az12
where bdate < '1924-01-01' OR bdate > GETDATE()

select distinct gen
from silver.erp_cust_az12

select * from silver.erp_cust_az12;
-- LOC


SELECT 
REPLACE(cid,'-','') cid,
cntry
FROM bronze.erp_loc_a101 



SELECT 
REPLACE(cid,'-','') cid,
CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
	 WHEN TRIM(cntry) IN ('US','USA') THEN 'United States'
	 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n\a'
	 ELSE cntry
end as cntry
FROM bronze.erp_loc_a101 

select distinct cntry
from silver.erp_loc_a101;


---
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


--unwanted spaces
SELECT * FROM bronze.erp_px_cat_g1v2
WHERE id != TRIM(id) OR cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

select distinct 
maintenance
FROM bronze.erp_px_cat_g1v2;

select * from silver.erp_px_cat_g1v2;


