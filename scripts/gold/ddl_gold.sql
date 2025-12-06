
-- GOLD LAYER CUSTOMER DIMENSION
CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	cl.cntry as country,
	ci.cst_marital_status as marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' then  ci.cst_gndr -- CRM is Maa=ster for gender
			 ELSE COALESCE(ca.gen, 'n/a')
		END as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date

FROM silver.crm_cust_info ci
LEFT JOIN SILVER.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN SILVER.erp_loc_a101 cl
on ci.cst_key = cl.cid;


--WILL BE MODIFIED LATER

--GOLD LAYER PRODUCT DIMENSION
CREATE VIEW gold.dim_product as
select 
	ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt,pn.prd_key) as product_key, -- product key for each product
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
		
from silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id = pc.id
WHERE prd_end_dt IS NULL; -- Filter out all historical data


create view gold.fact_sales as
SELECT
	sd.sls_ord_num as order_number,
	pr.product_key,
	cu.customer_id,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales_amount,
	sd.sls_quantity as quantity,
	sd.sls_price as price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_product pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id;





