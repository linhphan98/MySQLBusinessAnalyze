use mavenfuzzyfactory; 

select 
	website_session_id, 
    weekday(created_at) as wkday, -- 0 = Mon, 1 = Tues, etc
	quarter(created_at) as qtr -- 1: Jan to March, 2: Apr to June, 3: July to Sep, 4: Oct to Dec
from website_sessions; 

-- 1. Taking a look at 2012's monthly and weekly volume patterns,
-- Pulling session volume and order volume 
		-- monthly
select 
	year(website_sessions.created_at) as yr, 
    month(website_sessions.created_at) as mth,
    count(distinct website_sessions.website_session_id) as sessions, 
    count(distinct orders.order_id) as orders
from website_sessions
left join orders 
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2013-01-01'
group by 1,2; 

		-- weekly
select 
	year(website_sessions.created_at) as yr, 
    week(website_sessions.created_at) as week,
    min(date(website_sessions.created_at)) as week_start_date,
    count(distinct website_sessions.website_session_id) as sessions, 
    count(distinct orders.order_id) as orders
from website_sessions
left join orders 
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2013-01-01'
group by 1,2;

-- 2. Average website session volume, by hour of day and by day of week 

-- on one day (monday), there is 24 hours and on one hour(5) there can be many sessions 
-- on the same day, 7th hour can have many other sessions 
-- so we take average based on the hour in that one day by getting total sessions in one day/24

select
	hr,
    avg(website_session_id) as ave_sessions,
    round(avg(case when wkday = 0 then website_session_id else null end),1) as monday, 
    round(avg(case when wkday = 1 then website_session_id else null end),1) as tuesday,
    round(avg(case when wkday = 2 then website_session_id else null end),1) as wednesday,
    round(avg(case when wkday = 3 then website_session_id else null end),1) as thursday,
    round(avg(case when wkday = 4 then website_session_id else null end),1) as friday,
    round(avg(case when wkday = 5 then website_session_id else null end),1) as saturday,
    round(avg(case when wkday = 6 then website_session_id else null end),1) as sunday
from (
select 
	date(created_at) as created_date,
    weekday(created_at) as wkday, 
    hour(created_at) as hr, 
    count(distinct website_session_id) as website_session_id
from website_sessions
where created_at between '2012-09-15' and '2012-11-15'
group by 1,2,3	-- there can be 4-5 sessions in one hour and 2-3 sessions in one hour of the same week day
) as daily_hourly_session
group by 1
order by 1