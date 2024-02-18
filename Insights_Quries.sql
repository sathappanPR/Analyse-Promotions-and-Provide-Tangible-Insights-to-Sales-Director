select * from c9.model;
select * from c9.fact_events;
select * from c9.dataset;

-- ad hoc request - -
-- 1. base proce 500 and bogof --
SELECT Products as Product, count(Products) as total_products
FROM c9.dataset
WHERE base_price > 500 and promo_type = "BOGOF"
GROUP BY Products, base_price
ORDER BY base_price DESC;

-- 2. number of stores in each city -- 
select city, count(store_id) as store_counts 
from dim_stores
group by city
order by store_counts desc;

-- 3. revenue generated before and after in millions -- 
select 
	campaign_id, 
    round(SUM(Reveneu_before_promo)/1000000,2) AS Reveneu_before_promo,
    round(sum(Reveneu_after_promo)/1000000,2) AS Reveneu_after_promo
from dataset
group by campaign_id;

-- 4. ISU% in diwali for categories --
SELECT
    campaign_id,
    Category,
    ISU,
    ISU_percentage,
    RANK() OVER (ORDER BY ISU_percentage) AS ISU_rank
FROM (
    SELECT
        campaign_id,
        Category,
        SUM(quantity_sold_after_promo) - SUM(quantity_sold_before_promo) AS ISU,
        ((SUM(quantity_sold_after_promo) - SUM(quantity_sold_before_promo)) / NULLIF(SUM(quantity_sold_before_promo), 0)) * 100 AS ISU_percentage
    FROM
        dataset
    WHERE
        campaign_id = 'Diwali'
    GROUP BY
        Category
) AS subquery;

-- 5. IR% for top 5 products--
select 
    Products,
    Category, 	
    round(sum(IR/1000000),2)as IR_millions,
    rounD(((sum(IR)) / SUM(Reveneu_before_promo)) * 100, 2) as IR_percentage
from dataset
group by Products, Category
order by IR_percentage Desc 
limit 5;


-- IR and IR% based on promotions -- 
SELECT 
    Promotions as promo_types,
    round(sum(IR/1000000),2)as IR_millions,
    ROUND(((sum(IR)) / SUM(Reveneu_before_promo)) * 100, 2) as IR_percentage
FROM dataset
GROUP BY promo_types
ORDER BY IR_millions DESC;


-- ISU and ISU% based on promotions -- 
select 
	Promotions as promo_types,
	sum(ISU) AS ISU,
	round(((sum(ISU)) /
	NULLIF(SUM(quantity_sold_before_promo), 0)) * 100,2) AS ISU_percentage
from dataset
group by promo_types
order by  ISU Desc ;

-- SELECT 
--     dataset.*,
--     fact_events.store_id
-- FROM dataset
-- JOIN fact_events ON dataset.ï»¿Events_id= fact_events.event_id;

-- Insights --
-- STore promotion analysis 
-- 1. Top 10 stores based on IR -- 
select 
 Cities,
 store_id,
 round(sum(IR/1000000),2) as IR_millions
from dataset
group by store_id, Cities
order by IR_millions desc
limit 10;

-- 2. Bottom 10 stores based on ISU-- 
select 
 Cities,
 store_id,
 sum(ISU) as ISU
from dataset
group by store_id, Cities
order by ISU   
limit 10 ;

-- 3. performance of store by cities -- 
select 
 Cities,
 sum(ISU) as ISU
from dataset
group by Cities
order by ISU desc;

-- promotion type analysis 
-- 1. Top 2 promotions based on IR
select 
	Promotions,
	round(sum(IR/1000000),2) as IR_millions
from dataset
group by Promotions
order by IR_millions desc
limit 2;

-- 2. Bottom 2 promotions based on ISU
select 
	Promotions,
	sum(ISU) as ISU
from dataset
group by Promotions
order by ISU 
limit 2;

-- 3. DIffrence based o promotions
SELECT
    CASE
        WHEN Promotions IN ('25% OFF', '50% OFF', '33% OFF') THEN 'Discount'
        WHEN Promotions IN ('500 Cashback') THEN 'Cashback'
        WHEN Promotions IN ('BOGOF') THEN 'BOGOF'
    END AS promotion_category,
    ROUND(SUM(IR) / 1000000, 2) AS Incremental_Revenue
FROM
    dataset
WHERE
    Promotions IN ('25% OFF', '50% OFF', '33% OFF', 'BOGOF', '500 Cashback')
GROUP BY
    promotion_category;

-- 4. Increment sold units vs incremental revenue 
select
	Category,
    round(sum(IR/1000000),2) as Incremental_Revenue,
    sum(ISU) as Incremental_sold_units
from dataset
group by Category
ORDER BY Incremental_Revenue desc;

-- Product category analysis --
-- 1. product has most significant lift in salse --
select 
	Products,
    round(sum(IR/1000000),2) as Incremental_Revenue
from dataset
group by Products
order by Incremental_Revenue;

select 
	Products,
    campaign_id,
    round(sum(IR/1000000),2) as Incremental_Revenue,
    CASE
        WHEN Promotions IN ('25% OFF', '50% OFF', '33% OFF') THEN 'Discount'
        WHEN Promotions IN ('500 Cashback') THEN 'Cashback'
        WHEN Promotions IN ('BOGOF') THEN 'BOGOF'
    END AS promotion_category
from dataset
where Products in ('Atliq_waterproof_Immersion_Rod', 'Atliq_Farm_Chakki_Atta (1KG)')
group by Products, promotion_category, campaign_id;

-- 2. well vs poor among Products
select 
	Products,
    Category,
    round(sum(IR/1000000),2) as Incremental_Revenue,
    CASE
        WHEN Promotions IN ('25% OFF', '50% OFF', '33% OFF') THEN 'Discount'
        WHEN Promotions IN ('500 Cashback') THEN 'Cashback'
        WHEN Promotions IN ('BOGOF') THEN 'BOGOF'
    END AS promotion_category
from dataset
group by Products,promotion_category,Category
order by Incremental_Revenue;

-- more insights --
-- Top Performing Cities: --
SELECT 
    Cities,
    ROUND(SUM(IR/1000000), 2) AS Incremental_Revenue,
    campaign_id,
    RANK() OVER (ORDER BY ROUND(SUM(IR/1000000), 2) DESC) AS revenue_rank
FROM dataset
GROUP BY Cities, campaign_id; 

-- City-specific Product Preferences: -- 
select 
	Cities,
    Products, 
    sum(ISU) as ISU
from  dataset 
group by Products, Cities
order by ISU desc
limit 5;

select
	round(sum(Reveneu_before_promo)/1000000,2) as Reveneu_before_promo,
    round(sum(Reveneu_after_promo)/1000000,2) as Reveneu_after_promo,
    round(sum(IR)/1000000,2) as IR,
    sum(ISU) as ISU ,
    sum(quantity_sold_before_promo) as quantity_sold_before_promo ,
    sum(quantity_sold_after_promo) as quantity_sold_after_promo
from dataset;

select
	Products,
	round(sum(IR)/1000000,2) as IR,
    sum(ISU) as ISU ,
CASE
        WHEN Promotions IN ('25% OFF', '50% OFF', '33% OFF') THEN 'Discount'
        WHEN Promotions IN ('BOGOF') THEN 'BOGOF'
    END AS promotion_category,
    ROUND(SUM(IR) / 1000000, 2) AS Incremental_Revenue
FROM
    dataset
WHERE
    Promotions IN ('25% OFF', '50% OFF', '33% OFF', 'BOGOF') and 
	Products in ('Atliq_Farm_Chakki_Atta (1KG)', 'Atliq_Suflower_Oil (1L)','Atliq_Farm_Chakki_Atta (1KG)')
group by promotion_category, Products;

-- Top selling category in Bengaluru-- 
select
    Category,
    Cities,
    sum(ISU) as ISU
FROM
    dataset
WHERE
    Cities = 'Bengaluru'
 group by Category, Cities
 order by ISU;   
    
-- best selling Products in Bengaluru based on category-- 
select
    Category,
    Products,
    Cities,
    campaign_id,
    sum(ISU) as ISU
FROM
    dataset
WHERE
    Cities = 'Bengaluru' and Category = 'Grocery & Staples' and Products = 'Atliq_Farm_Chakki_Atta (1KG)'
 group by Category, Cities, campaign_id
 order by ISU desc;   
 
 -- best selling Products in Trivandrum based on category-- 
select
    Category,
    Products,
    Cities,
    sum(ISU) as ISU
FROM
    dataset
WHERE
    Cities = 'Trivandrum' and Category = 'Grocery & Staples' 
 group by Category, Cities, Products
 order by ISU desc;   
 

