use mavenfuzzyfactory; 

-- 1. Pull overall session and order volume 
select
	year(website_sessions.created_at) as yr, 
    quarter(website_sessions.created_at) as qtr, 
    count(distinct website_sessions.website_session_id) as sessions, 
    count(distinct orders.order_id) as orders
from website_sessions
	left join orders
		on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 2. quarterly figures since we launched, for session-to-orer conversion rate, 
-- revenue per order, and revenue per session
select
	year(website_sessions.created_at) as yr, 
    quarter(website_sessions.created_at) as qtr, 
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as cv_rate, 
    sum(orders.price_usd)/count(distinct orders.order_id) as rev_per_order, 
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as rev_per_session
from website_sessions 
	left join orders
		on website_sessions.website_session_id = orders.website_session_id 
group by 1,2;

-- 3. Pull quarterly view of orders from Gsearch, Bsearch nonbrand, brand search overall
-- organic search, direct-type-in

select
	year(website_sessions.created_at) as yr, 
    quarter(website_sessions.created_at) as qtr,  
	count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as nonbrand_gsearch_orders, 
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end) as nonbrand_bsearch_orders, 
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end) as brand_overall_orders, 
	count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end) as organic_search_orders, 
	count(distinct case when utm_source is null and http_referer is null then orders.order_id else null end) as direct_type_in_orders
from website_sessions
left join orders 
	on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 4. overall session-to-order conversion rate for the same channels by quarter 

select
	year(website_sessions.created_at) as yr, 
    quarter(website_sessions.created_at) as qtr,  
	count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)/
    count(distinct case when utm_source = 'gsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_gsearch_cvrate, 
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then orders.order_id else null end)/
    count(distinct case when utm_source = 'bsearch' and utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_bsearch_cvrate, 
    count(distinct case when utm_campaign = 'brand' then orders.order_id else null end)/
    count(distinct case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_overall_cvrate, 
	count(distinct case when utm_source is null and http_referer is not null then orders.order_id else null end)/
    count(distinct case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_cvrate, 
	count(distinct case when utm_source is null and http_referer is null then orders.order_id else null end)/
    count(distinct case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_cvrate
from website_sessions
left join orders 
	on website_sessions.website_session_id = orders.website_session_id
group by 1,2;

-- 5. monthly trending for revenue and margin by product, total sales and revenue 

select
	year(order_items.created_at) as yr, 
    month(order_items.created_at) as mth,  
    sum(case when product_id = 1 then price_usd else null end) as mrFuzzy_rev, 
    sum(case when product_id = 1 then price_usd - cogs_usd else null end) as mrFuzzy_marg,
    sum(case when product_id = 2 then price_usd else null end) as loveBear_rev, 
    sum(case when product_id = 2 then price_usd - cogs_usd else null end) as loveBear_marg,
    sum(case when product_id = 3 then price_usd else null end) as birthdayBear_rev, 
    sum(case when product_id = 3 then price_usd - cogs_usd else null end) as birthdayBear_marg,
    sum(case when product_id = 4 then price_usd else null end) as miniBear_rev, 
    sum(case when product_id = 4 then price_usd - cogs_usd else null end) as miniBear_marg, 
    sum(price_usd) as total_sales, 
    sum(price_usd - cogs_usd) as total_margins
from order_items
group by 1,2; 

-- 6. monthly session to /product page, show % of those sessions clicking through another page
-- has changed overtime along with conversion from /product to placing an order 

-- get all the sessions in /product page 
create temporary table product_pageviews 
select 
	website_pageview_id, 
    website_session_id, 
    created_at as saw_product_page_at
from website_pageviews 
where pageview_url = '/products'; 

select 
	year(saw_product_page_at) as yr, 
    month(saw_product_page_at) as mth, 
    count(distinct product_pageviews.website_session_id) as session_to_product_page,
    count(distinct website_pageviews.website_session_id) as clicked_to_next_page, 
    count(distinct website_pageviews.website_session_id)/count(distinct product_pageviews.website_session_id) as clickthrough_rate,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct product_pageviews.website_session_id) as products_to_orders_rate
from product_pageviews
left join website_pageviews
	on product_pageviews.website_session_id = website_pageviews.website_session_id
    and product_pageviews.website_pageview_id < website_pageviews.website_pageview_id 
left join orders 
	on product_pageviews.website_session_id = orders.website_session_id
group by 1,2;

-- 7. making 4th product primary product on '2014-12-05' 
-- Pulling sales data since then and how well each product cross sell each other

create temporary table primary_products
select 
	order_id, 
	primary_product_id, 
    created_at as ordered_at
from orders 
where created_at > '2014-12-05'; 

select
	primary_product_id, 
    count(distinct order_id) as totalOrders, 
    count(distinct case when cross_sell_product_id = 1 then order_id else null end) as cross_sold_p1, 
	count(distinct case when cross_sell_product_id = 2 then order_id else null end) as cross_sold_p2, 
    count(distinct case when cross_sell_product_id = 3 then order_id else null end) as cross_sold_p3, 
    count(distinct case when cross_sell_product_id = 4 then order_id else null end) as cross_sold_p4, 
    count(distinct case when cross_sell_product_id = 1 then order_id else null end)/count(distinct order_id) as cross_sold_p1_rate, 
	count(distinct case when cross_sell_product_id = 2 then order_id else null end)/count(distinct order_id) as cross_sold_p2_rate, 
    count(distinct case when cross_sell_product_id = 3 then order_id else null end)/count(distinct order_id) as cross_sold_p3_rate, 
    count(distinct case when cross_sell_product_id = 4 then order_id else null end)/count(distinct order_id) as cross_sold_p4_rate
    
from(
select 
	primary_products.*, 
    order_items.product_id as cross_sell_product_id	
    -- can have null because they can cross sell the other item that is not recommended additional to that product 
from primary_products
left join order_items 
	on primary_products.order_id = order_items.order_id
	and order_items.is_primary_item = 0 -- cross sell only meaning that is_primary_item = 0 (either 0 or 1, 0 is no not primary, 1 is yes) 
) as primary_w_cross_sell
group by 1; 

-- 8. 
