use mavenfuzzyfactory;
					-- 2012-11-27
-- 1. gsearch seems to be the biggest driver of our business. Could you pull monthly trend
-- for gsearch sessions and orders so that we can show case the growth here 

select 
	MONTH(website_sessions.created_at) as monthly,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.website_session_id) as orders, 
    count(distinct orders.website_session_id)/count(distinct website_sessions.website_session_id) as order_conversion_rate
from website_sessions 
left join orders
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
and website_sessions.utm_source = 'gsearch'
group by 1;

-- 2. It would be great to see a similar monthly trends for Gsearch, but this time splitting
-- nonbrand and brand campaigns separately. I am wondering if brand is picking up at all 
select 
	MONTH(website_sessions.created_at) as monthly,
    count(distinct case when website_sessions.utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as session_nonbrand, 
	count(distinct case when website_sessions.utm_campaign = 'brand' then website_sessions.website_session_id else null end) as session_brand, 
	count(distinct case when website_sessions.utm_campaign = 'nonbrand' then orders.website_session_id else null end) as orders_nonbrand, 
	count(distinct case when website_sessions.utm_campaign = 'brand' then orders.website_session_id else null end) as orders_brand
from website_sessions 
left join orders
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
and website_sessions.utm_source = 'gsearch'
group by 1;

-- 3. While we are on Gsearch, could you dive into nonbrand, and pull monthly 
-- sessions and orders split by device type 

select 
	month(website_sessions.created_at) as monthly,
    count(distinct case when website_sessions.device_type = 'desktop' then  website_sessions.website_session_id else null end) as desktop_sessions,
    count(distinct case when website_sessions.device_type = 'mobile' then  website_sessions.website_session_id else null end) as mobile_sessions, 
    count(distinct case when website_sessions.device_type = 'desktop' then  orders.order_id else null end) as desktop_orders,
    count(distinct case when website_sessions.device_type = 'mobile' then  orders.order_id else null end) as mobile_orders
from website_sessions 
left join orders
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
and website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand' 
group by 1;

-- 4. large % of traffic from Gsearch 
-- Pull monthly trends for Gsearch along with each of other channel

select 
	month(created_at) as monthly, 
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_session, 
	count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_session,
	count(distinct case when utm_source is null and http_referer is not null then website_session_id else null end) as organic_search_sessions, 
	count(distinct case when utm_source is null and http_referer is null then website_session_id else null end) as direct_type_in_sessions
from website_sessions
where website_sessions.created_at < '2012-11-27'
group by 1;

-- 5. Pulling session to order conversion rates, by month 
select 
	month(website_sessions.created_at) as monthly_session,
	count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders, 
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as order_to_session_conversion_rate
from website_sessions 
left join orders
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
group by 1;

-- 6. For the gsearch lander test, estimate the revenue that test earned us 
-- Look at the increase in CVR from the test (Jun 19 - July 28) and use nonbrand sessions 
-- and revenue since then to calculate incremental value 

-- first we gonna figure out the minimum website_view id where the test started 
select 
	min(website_pageview_id) as first_test_pv
from website_pageviews 
where pageview_url = '/lander-1';

-- create the min_pageview_id with session_id 
-- next we will bring in the landing page to each session but restricting to lander-1 and home
create temporary table first_test_pageviews
select 
	website_sessions.website_session_id, 
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_sessions
left join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at < '2012-07-28' 
and website_pageviews.website_pageview_id >= 23504
and website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand'
group by 1;

create temporary table nonbrand_test_sessionID_with_landing_page2
select 
	first_test_pageviews.website_session_id, 
    website_pageviews.pageview_url as landing_page
from first_test_pageviews
left join website_pageviews 
	on website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
where website_pageviews.pageview_url in ('/home','/lander-1');

create temporary table nonbrand_test_session_with_orders 
select 
	nonbrand_test_sessionID_with_landing_page2.website_session_id, 
    nonbrand_test_sessionID_with_landing_page2.landing_page, 
    orders.order_id as order_id
from nonbrand_test_sessionID_with_landing_page2
left join orders 
	on nonbrand_test_sessionID_with_landing_page2.website_session_id = orders.website_session_id;

select
	landing_page, 
    count(distinct order_id) as orders,
    count(distinct website_session_id) as sessions, 
    count(distinct order_id)/count(distinct website_session_id) as orders_to_sessions_conversion_rate
from nonbrand_test_session_with_orders
group by 1; 

-- 0.0319 for /home and 0.0406 for /lander-1
-- 0.0087 additional orders per session

-- we want to find the total number of sessions since the last /home to the most recent /lander-1

-- Finding the most recent pageview for gsearch nonbrand where the traffic is sent to /home
select 
max(website_sessions.website_session_id) as most_recent_id_visited
from website_sessions
left join website_pageviews 
	on website_sessions.website_session_id = website_pageviews.website_session_id 
where website_sessions.created_at < '2012-11-27' 
and website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand'
and website_pageviews.pageview_url = '/home';

select 
	count(website_sessions.website_session_id) as session_since_test
from website_sessions
where website_sessions.created_at < '2012-11-27' 
and website_sessions.website_session_id > 17145
and website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand';

-- 22972 website sessions since the test 
-- X.0087 incremental conversion = 202 incremental orders since 7/29
-- roughly 4 months, so 50 extras per month 

-- 7. Show a full conversion funnel for the landing page from each of the two pages to orders
-- same time periods (June 19 - July 28) 

create temporary table test_funnel3
select 
	website_session_id, 
    max(homepage) as maxhomepage,
    max(landerpage) as maxlanderpage,
    max(productpage) as maxproductpage,
    max(fuzzypage) as maxfuzzypage,
    max(cartpage) as maxcartpage,
    max(shippingpage) as maxshippingpage,
    max(billingpage) as maxbillingpage,
    max(thankyoupage) as maxthankyoupage
from(
select 
	website_sessions.website_session_id, 
    website_pageviews.pageview_url, 
    case when pageview_url = '/home' then 1 else 0 end as homepage, 
	case when pageview_url = '/lander-1' then 1 else 0 end as landerpage, 
	case when pageview_url = '/products' then 1 else 0 end as productpage, 
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as fuzzypage, 
    case when pageview_url = '/cart' then 1 else 0 end as cartpage,
	case when pageview_url = '/shipping' then 1 else 0 end as shippingpage, 
    case when pageview_url = '/billing' then 1 else 0 end as billingpage, 
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyoupage
from website_sessions
left join website_pageviews 
	on website_sessions.website_session_id = website_pageviews.website_session_id 
where website_sessions.created_at > '2012-06-19'
and website_sessions.created_at < '2012-07-28' 
and website_sessions.utm_campaign = 'nonbrand' 
and website_sessions.utm_source = 'gsearch' 
order by 	
	website_sessions.website_session_id, 
	website_pageviews.created_at
) as pageview_level

group by website_session_id;


select 
	case 
		when maxhomepage = 1 then 'saw_homepage' 
        when maxlanderpage = 1 then 'saw_landerpage'
        else 'check logic'
	end as segment,
    count(distinct website_session_id) as sessions, 
    count(distinct case when maxproductpage = 1 then website_session_id else null end) as to_product,
	count(distinct case when maxfuzzypage = 1 then website_session_id else null end) as to_fuzzy,
    count(distinct case when maxcartpage = 1 then website_session_id else null end) as to_cart,
    count(distinct case when maxshippingpage = 1 then website_session_id else null end) as to_shipping,
    count(distinct case when maxbillingpage = 1 then website_session_id else null end) as to_billing,
    count(distinct case when maxthankyoupage = 1 then website_session_id else null end) as to_thankyou
from test_funnel3
group by segment;

-- click reate as final outputs
select 
	case 
		when maxhomepage = 1 then 'saw_homepage' 
        when maxlanderpage = 1 then 'saw_landerpage'
        else 'check logic'
	end as segment,
    count(distinct case when maxproductpage = 1 then website_session_id else null end)/count(distinct website_session_id) as lander_clickrate,
	count(distinct case when maxfuzzypage = 1 then website_session_id else null end)/count(distinct case when maxproductpage = 1 then website_session_id else null end) as lander_clickrate,
    count(distinct case when maxcartpage = 1 then website_session_id else null end)/count(distinct case when maxfuzzypage = 1 then website_session_id else null end) as mrFuzzy_clickrate,
    count(distinct case when maxshippingpage = 1 then website_session_id else null end)/count(distinct case when maxcartpage = 1 then website_session_id else null end) as cart_clickrate,
    count(distinct case when maxbillingpage = 1 then website_session_id else null end)/count(distinct case when maxshippingpage = 1 then website_session_id else null end) as shipping_clickrate,
    count(distinct case when maxthankyoupage = 1 then website_session_id else null end)/count(distinct case when maxbillingpage = 1 then website_session_id else null end) as billing_clickrate
from test_funnel3
group by segment;

-- 8. Analyze the lift generated from the test (Sep 10 - Nov 10), in terms of revenue per billing page session
-- then pull the number of billing page sessions for the past month to understand monthly impact

select 
	billing_version_seen, 
    count(distinct website_session_id) as sessions,
    sum(price_usd)/count(distinct website_session_id) as revenue_per_billingpage_seen
from (
select 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url as billing_version_seen, 
    orders.order_id, 
    orders.price_usd
from website_pageviews
	left join orders
		on orders.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at > '2012-09-10'
and website_pageviews.created_at < '2012-11-10' 
and website_pageviews.pageview_url in ('/billing','/billing-2')
) as billing_pageview_and_order_data
group by 1; 

-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: $8.51 per billing page view

select
	count(website_session_id) as billing_session_past_month
from website_pageviews
where pageview_url in ('/billing', '/billing-2')
	and created_at between '2012-10-27' and '2012-11-27'
    
-- 1194 billing sessions past month
-- LIFT: $8.51 per billing session 
-- VALUE OF BILLING TEST: $10,160 over the past month