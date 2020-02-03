-- Pull the volumn of paid search nonbrand traffic landing on
-- /home and /lander-1, trended weekly since June 1st
-- pull our overall paid search bounce rate trended weekly
-- the date she sent out was '2012-08-31'

use mavenfuzzyfactory;

-- Step 1: finding the first website_pageview_id for relevant sessions

create temporary table sessions_min_pv_id_and_view_count
select 
	website_sessions.website_session_id, 
    min(website_pageviews.website_pageview_id) as first_pageView_id,
    count(distinct website_pageviews.website_pageview_id) as count_pageViews
from website_sessions
left join website_pageviews
	on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.created_at > '2012-06-1'
and website_sessions.created_at < '2012-08-31'
and website_sessions.utm_source = 'gsearch'
and website_sessions.utm_campaign = 'nonbrand'
group by website_sessions.website_session_id;

-- Step 2: identifying the landing page of each session
-- Step 3: Counting pageviews for each session, to identify bounce

create temporary table session_counts_lander_and_created_at
select 
	sessions_min_pv_id_and_view_count.website_session_id, 
    sessions_min_pv_id_and_view_count.first_pageView_id, 
    sessions_min_pv_id_and_view_count.count_pageViews, 
    website_pageviews.created_at as sessions_createdAt, 
    website_pageviews.pageview_url as landingPage
from sessions_min_pv_id_and_view_count
left join website_pageviews
	on sessions_min_pv_id_and_view_count.first_pageView_id = website_pageviews.website_pageview_id;
    
-- Step 4: Summarizing by week ( bounce rate, sessions to each lander)
select 
	-- YEARWEEK(sessions_createdAt) as year_week, 
    min(date(sessions_createdAt) as week_start_date, 
    -- count(distinct website_session_id) as total_session_in_aWeek
    -- count(distinct case when count_pageViews = 1 then website_session_id else null end) as bounced_session, 
	count(distinct case when landingPage = '/home'  then website_session_id else null end) as home_session, 
	count(distinct case when landingPage = '/lander-1'  then website_session_id else null end) as lander_session, 

from session_counts_lander_and_created_at
group by YEARWEEK(sessions_createdAt) 

