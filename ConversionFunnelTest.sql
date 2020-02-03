-- test an updated billing page
-- seeing whether /billing-2 is doing better /billing original
-- what % of sessions on those pages end up placing order
-- test for all trafic, not just for our search visitors
-- assigned date '2012-11-10'

use mavenfuzzyfactory; 

-- figuring out when /billing-2 went live: 53550 
select 
	billing_version, 
    count(distinct website_session_id) as sessions, 
    count(distinct order_id) as orders,
    count(distinct order_id)/count(distinct website_session_id) as billing_to_order_rate
from(
select 
	website_pageviews.website_session_id, 
    website_pageviews.pageview_url as billing_version, 
    orders.order_id
from website_pageviews
left join orders
	on website_pageviews.website_session_id = orders.website_session_id
where website_pageviews.website_pageview_id > 53550
and website_pageviews.created_at < '2012-11-10'
and website_pageviews.pageview_url in ('/billing','/billing-2')
) as billing_session_with_order
group by 1