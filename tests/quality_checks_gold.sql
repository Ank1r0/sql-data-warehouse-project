-- GOLD LAYER DUBLICATION TEST


SELECT cst_id, count(*) FROM
	(SELECT 
		ci.cst_id,
		ci.cst_key,
		ci.cst_firstname,
		ci.cst_lastname,
		ci.cst_marital_status,
		ci.cst_gndr,
		ci.cst_create_date,
		ca.bdate,
		ca.gen,
		cl.cntry
	FROM silver.crm_cust_info ci
	LEFT JOIN SILVER.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
	LEFT JOIN SILVER.erp_loc_a101 cl
	on ci.cst_key = cl.cid
)T GROUP BY  cst_id
HAVING count(*) > 1


--GENDER JOIN CHECK
SELECT distinct
	ci.cst_gndr,
	ca.gen,
	CASE WHEN ci.cst_gndr != 'n/a' then  ci.cst_gndr -- CRM is Maa=ster for gender
		 ELSE COALESCE(ca.gen, 'n/a')
	END as new_gen
FROM silver.crm_cust_info ci
LEFT JOIN SILVER.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN SILVER.erp_loc_a101 cl
on ci.cst_key = cl.cid
order by 1,2


-- Check after creating the view/dimension in Gold Layer
SELECT distinct gender FROM gold.dim_customers


/*
-----------------------------------
Product
-----------------------------------
*/

--check uniqueness and historical data removal
select prd_key, count(*) from
(
	select 
		pn.prd_id,
		pn.cat_id,
		pn.prd_key,
		pn.prd_nm,
		pn.prd_cost,
		pn.prd_line,
		pn.prd_start_dt,
		pn.prd_end_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	from silver.crm_prd_info pn
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pn.cat_id = pc.id
	WHERE prd_end_dt IS NULL -- Filter out all historical data
) t group by prd_key
having count(*) > 1;

-- sorting everything into logical groups


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
WHERE prd_end_dt IS NULL -- Filter out all historical data


/*

FACT TABLE

*/


select * from gold.dim_customers


create or alter view gold.fact_sales as
SELECT
	sd.sls_ord_num as order_number,
	pr.product_key,
	cu.customer_key,
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
ON sd.sls_cust_id = cu.customer_id



-- check did we link everything correctly
select 
* 
from gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
left join gold.dim_product p
on p.product_key = f.product_key
where p.product_key IS NULL or c.customer_key is NULL



select * from gold.dim_customers;
