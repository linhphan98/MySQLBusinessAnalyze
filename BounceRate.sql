use mavenfuzzyfactory; 
	
	-- A bounce rate meaning that we divide the total number of bounce ids over the total number of website_pageView_id 
	
	-- website_session_id is the specific id assigned when one user access the page 
	-- that user can have that same website_session_id but different website_pageView_id 
	-- website_pageView_id is the id whenever there is a new user access the page (any page) with different url 
	-- There cannot be a duplicate of website_pageView_id but website_session_id can have duplicate

	-- In this assignment we have many website_session_id that have bounced or go to different pages 
	-- Meaning that the same website_session_id will have different website_pageView_id and we have to eleminate those ids 
	-- Step 1: Finding the first website_session_id for relevant session
    -- Step 2: Identifying the landing page of each session 
    -- Step 3: Counting pageviews for eac session, to identify "bounces"
    -- Step 4: Summarizing by counting total sessions and bounced sessions
    
create temporary table first_pageviews
select 
    website_session_id, 
    min(website_pageview_id) as min_pageview -- to get the very first page the id lands on
from website_pageviews 
where website_pageviews.created_at < "2012-06-14"
group by 1;



	-- next, we will bring up the landing page restricting to home page only 
create temporary table session_home_landing_page
select 
	first_pageviews.website_session_id, 
    website_pageviews.pageview_url as landing_page
from first_pageviews
left join website_pageviews
	on website_pageviews.website_pageview_id = first_pageviews.min_pageview
where website_pageviews.pageview_url = '/home';
    
    
    
    -- then a table to have count of pageviews per session 
    -- then limit it to just bounced_sessions
create temporary table bounced_session
select 
	session_home_landing_page.website_session_id, 
    session_home_landing_page.landing_page,
    count(website_pageviews.website_pageview_id) as count_of_pageviews
from session_home_landing_page
left join website_pageviews
	on website_pageviews.website_session_id = session_home_landing_page.website_session_id
group by 1, 2
having 
	count(website_pageviews.website_pageview_id) = 1; -- this eliminates website_session_id whose has bounced into different url
    
select *
from session_home_landing_page
	left join bounced_session
		on session_home_landing_page.website_session_id = bounced_session.website_session_id
order by
	session_home_landing_page.website_session_id; 

select 
	count(distinct session_home_landing_page.website_session_id) as sessions, 
    count(distinct bounced_session.website_session_id) as sessions, 
    count(distinct session_home_landing_page.website_session_id)/count(distinct bounced_session.website_session_id) as bounceRate
from session_home_landing_page
	left join bounced_session
		on session_home_landing_page.website_session_id = bounced_session.website_session_id
order by
	session_home_landing_page.website_session_id; 


-- this will give a headstart in comparing the landing page lander-1 and home 
-- the last part will be the same code above

use mavenfuzzyfactory;	

select 
	min(created_at) as first_created_at, -- in other word this is the time when we launch the page with the first website_pageview_id
	min(website_pageview_id) as first_pageview_id
from website_pageviews
where pageview_url = '/lander-1'
	and created_at IS NOT NULL; 

create temporary table first_test_pageview
select 
	website_pageviews.website_session_id, 
    min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
	inner join website_sessions
		on website_sessions.website_session_id = website_pageviews.website_session_id
        and website_sessions.created_at < '2012-07-28' -- prescribed by the assignment
        and website_pageviews.website_pageview_id > 23504 -- the first_pageview_id we found
		and utm_source = 'gsearch'
        and utm_campaign = 'nonbrand'
group by 
	website_pageviews.website_session_id; 
    
create temporary table nonbrand_test_session_withLandingPage
select 
	first_test_pageview.website_session_id, 
    website_pageviews.pageview_url as landing_page
from first_test_pageview
left join website_pageviews
	on website_pageviews.website_pageview_id = first_test_pageview.min_pageview_id
where website_pageviews.pageview_url in ('/home', '/lander-1');
    


