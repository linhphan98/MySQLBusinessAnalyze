use mavenfuzzyfactory; 

	-- 1. Pulling data on how many of our website visiots come back for another session? 
    -- '2014-01-01' to '2014-11-01'
    
    -- Step 1: Identify the relevant new sessions 
    -- Step 2: User the user_id values from step 1 to find any repeat session those users have
    -- Step 3: Analyze data at the user level (How many sessions did each users have) 
    -- Step 4: Aggregate the user-level analysis to generate ypur behavioral analysis
    
create temporary table sessions_with_repeats
select
	new_sessions.user_id, 
    new_sessions.website_session_id as new_session_id, 
    website_sessions.website_session_id as repeated_session_id
from(
select 
	user_id, 
    website_session_id
from website_sessions
where created_at > '2014-01-01' 
and created_at < '2014-11-01'
and is_repeat_session = 0
) as new_sessions -- get new sessions only
	left join website_sessions	-- when we join we only bring in repeated sessions
		on website_sessions.user_id = new_sessions.user_id
        and website_sessions.is_repeat_session = 1
        and website_sessions.created_at >= '2014-01-01' 
		and website_sessions.created_at < '2014-11-01';

select
	repeated_sessions, 
    count(distinct user_id) as users	
    -- this way we are counting how many user_id have repeated once, twice or third time or they quit after the first time
from(
select 
	user_id,
    count(distinct new_session_id) as new_sessions,
    count(distinct repeated_session_id) as repeated_sessions
from sessions_with_repeats
group by 1
order by 3 desc
) as user_level
group by 1;

-- 2. The minimum and maximum and average time between the first and second session
-- for customers who come back? '2013-01-01' to '2014-11-03'

create temporary table session_with_repeates_for_timeDiff
select
	new_sessions.user_id, 
    new_sessions.website_session_id as new_session_id, 
    new_sessions.created_at as new_session_created_at,
    website_sessions.website_session_id as repeated_session_id,
    website_sessions.created_at as repeated_session_created_at
from(
select 
	user_id, 
    website_session_id,
    created_at
from website_sessions
where created_at > '2014-01-01' 
and created_at < '2014-11-01'
and is_repeat_session = 0
) as new_sessions -- get new sessions only
	left join website_sessions	-- when we join we only bring in repeated sessions
		on website_sessions.user_id = new_sessions.user_id
        and website_sessions.is_repeat_session = 1
        and website_sessions.created_at >= '2014-01-01' 
		and website_sessions.created_at < '2014-11-01';
 
create temporary table users_first_to_second
 select 
	user_id, 
    datediff(second_created_at, new_session_created_at) as day_first_to_second_session
from(
 select 
	user_id, 
    new_session_id,
    new_session_created_at, 
    min(repeated_session_id) as second_session_id,
    min(repeated_session_created_at) as second_created_at
 from session_with_repeates_for_timeDiff
 where repeated_session_id is not null
 group by 1,2,3
) as first_second;

select 
	avg(day_first_to_second_session) as average, 
    min(day_first_to_second_session) as minimum,
    max(day_first_to_second_session) as maximum
from users_first_to_second;

-- 3. Comparing the new vs repeat sessions by channel from '2014-01-01' to '2014-11-05'
-- utm_source is null and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') organic_search
-- utm_campaign nonbrand, brand is paid_nonbrand, paid_brand 
-- utm_source is null and http_referer is null then 'direct-type-in'
-- utm_source = 'socialbook' then paid_social 
select
	case 
		when utm_source is null and http_referer in ('https://www.gsearch.com', 'https://www.bsearch.com') then 'organic_search'
        when utm_campaign = 'nonbrand' then 'paid_nonbrand' 
        when utm_campaign = 'brand' then 'paid_brand'
        when utm_source is null and http_referer is null then 'direct_type_in'
        when utm_source = 'socialbook' then 'paid_socialbook'
	end as channel_group, 
    count(distinct case when is_repeat_session = 0 then user_id else null end) as new_sessions, 
	count(distinct case when is_repeat_session = 1 then user_id else null end) as repeat_sessions
from website_sessions
where created_at > '2014-01-01'
and created_at < '2014-11-05'
group by 1; 

-- 4. Comparison of conversion rates and revenue per session for repeat session vs new session
-- from '2014-01-01' to '2014-11-08' 
select 
	website_sessions.is_repeat_session, 
    count(distinct website_sessions.website_session_id) as sessions, 
    count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as cov_rate, 
    sum(orders.price_usd)/count(distinct website_sessions.website_session_id) as rev_per_session
from website_sessions
left join orders 
	on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at > '2014-01-01'
and website_sessions.created_at < '2014-11-08'
group by 1;

