use mavenfuzzyfactory; 

-- 1. Pulling monthly trends to date for number of sales, total revenue and total margin generated
select 
	year(created_at) as yr,
	month(created_at) as mth, 
    sum(items_purchased) as item_sales, 
    sum(price_usd) as total_rev, 
    sum(price_usd)-sum(cogs_usd) as total_margin
from orders
where created_at < '2013-01-04' 
group by 1, 2;

-- 2. Monthly order volume, overall conversion rates, revenue per session,
-- a breakdown of sales by product since april 1 2012. Requested April 5 2013

select 
	year(website_sessions.created_at) as yr,
	month(website_sessions.created_at) as mth, 
    count(distinct order_id) as orders,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct order_id)/count(distinct website_sessions.website_session_id) as conversion_rate,
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as rev_by_session,
	count(distinct case when primary_product_id = 1 then order_id else null end) as product_one_order,
	count(distinct case when primary_product_id = 2 then order_id else null end) as product_two_order
from orders
	right join website_sessions 
		on orders.website_session_id = website_sessions.website_session_id
where website_sessions.created_at > '2012-04-01' 
and website_sessions.created_at < '2013-04-01'
group by 1,2;

-- 3. Looking at sessions which hit the /products page and see where they went next
-- pulling clickthrough rates from /products since the new prduct launch 
-- on January 6th 2013, by product, comparing to the 3 months leading up to launch as a baseline

-- Step 1: Finding the /products pageviews we care about
create temporary table products_pageview2
select 
	website_session_id, 
    website_pageview_id, 
    created_at,
    case 
		when created_at < '2013-01-06' then 'A. Pre_product_2'
        when created_at >= '2013-01-06' then 'B. Post_product_2'
        else 'check logic'
	end as time_period
from website_pageviews
where created_at < '2013-04-06' 
and created_at > '2012-10-06' 
and pageview_url = '/products';

-- Step 2: find the next pageview id that occurs after the product pageview
create temporary table session_with_next_pageview_id
select 
	products_pageview2.time_period, 
    products_pageview2.website_session_id, 
    website_pageviews.website_pageview_id as min_next_page
from products_pageview2
	left join website_pageviews 
		on website_pageviews.website_session_id = products_pageview2.website_session_id
        and website_pageviews.website_pageview_id > products_pageview2.website_pageview_id
        -- this is to get the session_id, pageview_id, and things that already go past the product page
group by 1,2,3;


-- Step 3: find the pageview_url associated with any applicable next pageview_id
create temporary table session_with_next_pageview_url
select 
	session_with_next_pageview_id.time_period, 
    session_with_next_pageview_id.website_session_id,
    website_pageviews.pageview_url as next_page_url
from session_with_next_pageview_id
	left join website_pageviews
		on session_with_next_pageview_id.min_next_page = website_pageviews.website_pageview_id;

-- Step 4: summarize the data and analyze the pre and post period 
select 
	time_period, 
    count(distinct website_session_id) as totalSessions, 
    count(distinct case when next_page_url is not null then website_session_id else null end) as w_next_pg, 
	count(distinct case when next_page_url is not null then website_session_id else null end)/count(distinct website_session_id) as pct_w_next_pg, 
    count(distinct case when next_page_url = '/the-original-mr-fuzzy' then website_session_id else null end) as to_mrfuzzy,
	count(distinct case when next_page_url = '/the-original-mr-fuzzy' then website_session_id else null end)/count(distinct website_session_id) as pct_to_mrfuzzy,
    count(distinct case when next_page_url = '/the-forever-love-bear' then website_session_id else null end) as to_lovebear,
	count(distinct case when next_page_url = '/the-forever-love-bear' then website_session_id else null end)/count(distinct website_session_id) as pct_to_lovebear
from session_with_next_pageview_url
group by 1;

-- 4. Analyze the conversion funnels from each products page to conversion 
-- Producing a comparison between the two conversion funnels, for all website traffic

-- Step 1: Select all pageviews for relevant sessions
-- Step 2: figure out which pageviews urls to look for 
-- Step 3: pull all pageviews and identify the funnel steps
-- Step 4: create the session-level conversion funnel view
-- Step 5: aggregate the data to assess funnel performance 

create temporary table session_seeing_product_page
select 
	website_session_id,
    website_pageview_id,
    pageview_url as product_page_seen
from website_pageviews
where created_at < '2013-04-10'
	and created_at > '2013-01-06'
    and pageview_url in ('/the-original-mr-fuzzy', '/the-forever-love-bear');
    
-- getting the url after that session_id going into the original and love bear 
-- there will be null value because people will stop there and not buying it 
select
	website_pageviews.pageview_url
from session_seeing_product_page
left join website_pageviews 
on session_seeing_product_page.website_session_id = website_pageviews.website_session_id
and session_seeing_product_page.website_pageview_id < website_pageviews.website_pageview_id
group by 1;

-- summary with flag
create temporary table funnel_table
select 
	website_session_id, 
	case 
		when product_page_seen = '/the-original-mr-fuzzy' then 'mrFuzzy'
        when product_page_seen = '/the-forever-love-bear' then 'lovebear'
		else 'check logic'
	end as product_seen,
    max(cart_page) as to_cartPage,
    max(shipping_page) as to_shippingPage,
    max(billing_page) as to_billingPage, 
    max(thankyou_page) as to_thankyouPage
from(
	select 
		session_seeing_product_page.website_session_id, 
		session_seeing_product_page.product_page_seen,
		case when website_pageviews.pageview_url = '/cart' then 1 else 0 end as cart_page,
		case when website_pageviews.pageview_url = '/shipping' then 1 else 0 end as shipping_page,
		case when website_pageviews.pageview_url = '/billing-2' then 1 else 0 end as billing_page,
		case when website_pageviews.pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
	from session_seeing_product_page
	left join website_pageviews 
	on session_seeing_product_page.website_session_id = website_pageviews.website_session_id
	and session_seeing_product_page.website_pageview_id < website_pageviews.website_pageview_id
	order by 1,2
) as pageview_level
group by 1,2;

select
	product_seen,
	count(distinct case when to_cartPage = 1 then website_session_id else null end) as to_cart,
	count(distinct case when to_shippingPage = 1 then website_session_id else null end) as to_shipping,
	count(distinct case when to_billingPage = 1 then website_session_id else null end) as to_billing,
	count(distinct case when to_thankyouPage = 1 then website_session_id else null end) as to_thankyou
from funnel_table
group by 1;

-- same thing but click rate
select
	product_seen,
	count(distinct case when to_cartPage = 1 then website_session_id else null end)/count(distinct website_session_id) as to_cart_clickrate,
	count(distinct case when to_shippingPage = 1 then website_session_id else null end)/count(distinct case when to_cartPage = 1 then website_session_id else null end) as to_shipping_clickrate,
	count(distinct case when to_billingPage = 1 then website_session_id else null end)/count(distinct case when to_shippingPage = 1 then website_session_id else null end) as to_billing_clickrate,
	count(distinct case when to_thankyouPage = 1 then website_session_id else null end)/count(distinct case when to_billingPage = 1 then website_session_id else null end) as to_thankyou_clickrate
from funnel_table
group by 1;

select 
	orders.primary_product_id,
    order_items.product_id as cross_sell_product,
    count(distinct orders.order_id) as orders
from orders 
left join order_items
		on order_items.order_id = orders.order_id
		and order_items.is_primary_item = 0 -- cross sell only set to 0, if buy with another item set to 1
group by 1, 2; 

-- 5. Cross_Sell_Analysis: compare the month before and the month after the change on September 25th 2013
-- Click through rate from the /cart page, AVG products per order, Average Order Value, revenue per /cart page view

-- Step 1. Identify the relevant /cart page views and their sessions
-- Step 2. See which of those /cart sessions clicked through to the shipping page 
-- Step 3. Find the orders associated with the /cart session. analyze products purchased, AOV
-- Step 4. Aggregate and analyze a summary of our finding


-- 6. A month before and after 2013-12-12 analysis comparing session-to-order conversion rate, 
-- average order value, products per order and revenue per session 
select 
	case 
		when website_sessions.created_at < '2013-12-12' then 'A. Pre_Birthday_Bear'
        when website_sessions.created_at >= '2013-12-12' then 'B. Post_Birthday_Bear'
		else 'check logic'
	end as time_period, 
	count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conv_rate,
    sum(price_usd)/count(distinct orders.order_id) as avg_order_value,
	sum(items_purchased)/count(distinct orders.order_id) as products_per_order,
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
left join orders
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at > '2013-11-12'
and website_sessions.created_at < '2014-01-12'
group by 1;

-- 7. Pulling monthly product refund rates, by product , and confirm
-- our quality issues are now fixed from '2014-09-16' to '2014-10-15'

select 
	year(order_items.created_at) as yr,
	month(order_items.created_at) as mth,
    count(distinct case when order_items.product_id = 1 then order_items.order_id else null end) as p1_orders,
	count(distinct case when order_items.product_id = 1 then order_item_refunds.order_item_refund_id else null end)/
    count(distinct case when order_items.product_id = 1 then order_items.order_id else null end) as p1_refund_rate,
	count(distinct case when order_items.product_id = 2 then order_items.order_id else null end) as p2_orders,
	count(distinct case when order_items.product_id = 2 then order_item_refunds.order_item_refund_id else null end)/
    count(distinct case when order_items.product_id = 2 then order_items.order_id else null end) as p2_refund_rate,
	count(distinct case when order_items.product_id = 3 then order_items.order_id else null end) as p3_orders,
	count(distinct case when order_items.product_id = 3 then order_item_refunds.order_item_refund_id else null end)/
    count(distinct case when order_items.product_id = 3 then order_items.order_id else null end) as p3_refund_rate,
	count(distinct case when order_items.product_id = 4 then order_items.order_id else null end) as p4_orders,
	count(distinct case when order_items.product_id = 4 then order_item_refunds.order_item_refund_id else null end)/
    count(distinct case when order_items.product_id = 4 then order_items.order_id else null end) as p4_refund_rate
from order_items
left join order_item_refunds
	on order_item_refunds.order_item_id = order_items.order_item_id
where order_items.created_at < '2014-10-15'
group by 1,2