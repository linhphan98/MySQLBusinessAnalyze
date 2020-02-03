-- Build a full conversion tunnel, analyzing how many customers
-- make it to each step 
-- start with /lander-1 make it to thank-you-page 
-- use data since 2012-08-05 to 2012-09-05

use mavenfuzzyfactory; 

-- Step 1: select all pageviews for relevant sessions
-- Step 2: identify each pageview as specific funnel step
-- Step 3: create the session-level conversion funnel view
-- Step 4: aggregate the data to assess funnel performance

create temporary table session_level_made_it_flag2
select 
	website_sessions.website_session_id,
	website_pageviews.pageview_url,    
    case when pageview_url = '/products' then 1 else 0 end as product_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as fuzzy_page,
	case when pageview_url = '/cart' then 1 else 0 end as cart_page,
	case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
	case when pageview_url = '/billing' then 1 else 0 end as billing_page,
	case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankYou_page
from website_sessions 
left join website_pageviews
	on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-08-05'
and website_sessions.created_at < '2012-09-05'
and website_sessions.utm_campaign = 'nonbrand'
and website_sessions.utm_source = 'gsearch'
order by 
website_sessions.website_session_id, 
website_pageviews.created_at;

select
	count(distinct case when product_page = 1 then website_session_id else null end) as to_products,
	count(distinct case when fuzzy_page = 1 then website_session_id else null end) as to_fuzzy,
	count(distinct case when cart_page = 1 then website_session_id else null end) as to_carts,
	count(distinct case when shipping_page = 1 then website_session_id else null end) as to_shipping,
	count(distinct case when billing_page = 1 then website_session_id else null end) as to_billing,
	count(distinct case when thankYou_page = 1 then website_session_id else null end) as to_thankYou
from session_level_made_it_flag2;

-- click rates
select 
count(distinct case when product_page = 1 then website_session_id else null end)/count(distinct website_session_id) as lander_click_rate,
count(distinct case when fuzzy_page = 1 then website_session_id else null end)/count(distinct case when product_page = 1 then website_session_id else null end) as product_click_rate,
count(distinct case when cart_page = 1 then website_session_id else null end)/count(distinct case when fuzzy_page = 1 then website_session_id else null end) as fuzzy_click_rate,
count(distinct case when product_page = 1 then website_session_id else null end)/count(distinct case when cart_page = 1 then website_session_id else null end) as cart_click_rate,
count(distinct case when shipping_page = 1 then website_session_id else null end)/count(distinct case when cart_page = 1 then website_session_id else null end) as shipping_click_rate,
count(distinct case when billing_page = 1 then website_session_id else null end) /count(distinct case when shipping_page = 1 then website_session_id else null end) as billing_click_rate,
count(distinct case when thankYou_page = 1 then website_session_id else null end)/count(distinct case when billing_page = 1 then website_session_id else null end) as thankYou_click_rate
from session_level_made_it_flag2
      



 