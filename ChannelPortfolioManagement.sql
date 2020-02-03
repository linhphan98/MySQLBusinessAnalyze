use mavenfuzzyfactory;

-- 1. We launched a second paid search channel, bsearch 
-- Can you pull weekly trended session volume since then and compare to gsearch nonbrand
select 
	yearweek(created_at) as weekly_session,
    min(date(created_at)) as week_start,
    count(website_session_id) as sessions,
    count(distinct case when utm_source = 'gsearch' then website_session_id else null end) as gsearch_session, 
    count(distinct case when utm_source = 'bsearch' then website_session_id else null end) as bsearch_session 
from website_sessions
where created_at > '2012-08-22'
and created_at < '2012-11-29'
and utm_campaign = 'nonbrand'
group by 1;

-- 2. Comparing the percentage of traffic coming on Mobile from gsearch to bsearch nonbrand
-- august 22nd to november 30, 2012
select
	utm_source, 
    count(distinct website_sessions.website_session_id) as sessions, 
    count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_sessions, 
	count(distinct case when device_type = 'mobile' then website_sessions.website_session_id else null end)/count(distinct website_sessions.website_session_id) as pct_mobile
from website_sessions
where created_at between '2012-08-22' and '2012-11-30' 
and utm_campaign = 'nonbrand'
group by 1;

-- 3. Pulling nonbrand conversion rates from session to order for gsearch and bsearch
-- and slice the data by decive type 
-- Analyze from '2012-08-22' to '2012-09-18'

select
	website_sessions.device_type,
	website_sessions.utm_source,
    count(distinct website_sessions.website_session_id) as sessions,
    count(distinct orders.order_id) as orders,
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as conversion_rate
from website_sessions 
left join orders
	on website_sessions.website_session_id = orders.website_session_id 
where website_sessions.created_at between '2012-08-22' and '2012-09-19' 
and utm_campaign = 'nonbrand'
group by 1,2;

-- 4. Pulling weekly session volume for gsearch and bsearch nonbrand, broken down by device
-- since '2012-11-04' to '2012-12-22'
-- bid down bsearch nonbrand on '2012-12-02'
-- include comparison metric to show bsearch as a percent of gsearch for each device

select
	min(date(created_at)) as week_start_date, 
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as g_desk_sessions,
	count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end) as b_desk_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'desktop' then website_session_id else null end)/
    count(distinct case when utm_source = 'gsearch' and device_type = 'desktop' then website_session_id else null end) as b_pct_of_g_desk, 
    count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as g_mobi_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end) as b_mobi_sessions,
    count(distinct case when utm_source = 'bsearch' and device_type = 'mobile' then website_session_id else null end)/
    count(distinct case when utm_source = 'gsearch' and device_type = 'mobile' then website_session_id else null end) as b_pct_of_g_mobi
from website_sessions 
where created_at > '2012-11-04'
and created_at < '2012-12-22' 
and utm_campaign = 'nonbrand'
group by yearweek(created_at);	-- yearweek() returns the year and week number(0-53), yearweek('2017-06-15') -> 201724

-- 5. Pulling organic search, direct type in, and paid brand search sessions by month
-- show these sessions as a % of paid search nonbrand 
select 
	year(created_at) as yearly,
	month(created_at) as monthly,
    count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as nonbrand, 
	count(distinct case when utm_campaign = 'brand' then website_session_id else null end) as brand, 
    count(distinct case when utm_campaign = 'brand' then website_session_id else null end)/
    count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as brand_pct_of_nonbrand,
	count(distinct case	when http_referer is null then website_session_id else null end) as direct_type_in,
    count(distinct case	when http_referer is null then website_session_id else null end)/
    count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as direct_pct_of_nonbrand,
	count(distinct case when http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') and utm_source is null then website_session_id else null end) as organic_search, 
	count(distinct case when http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') and utm_source is null then website_session_id else null end)/
	count(distinct case when utm_campaign = 'nonbrand' then website_session_id else null end) as organic_pct_of_nonbrand
from website_sessions
where created_at < '2012-12-23' 
group by 1, 2

