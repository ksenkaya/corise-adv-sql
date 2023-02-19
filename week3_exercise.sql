/* 
Create a daily report to track the followings:
- Total unique sessions
- The average length of sessions in seconds
- The average number of searches completed before displaying a recipe 
- The ID of the recipe that was most viewed 
*/

with events_deduped as (

	select
    	event_id,
        session_id,
        event_timestamp as event_ts,
        parse_json(event_details):recipe_id::varchar as recipe_id,
        parse_json(event_details):event::varchar as event_name
    from vk_data.events.website_activity
	group by 1, 2, 3, 4, 5

),

-- # of unique sessions, session length and # of searches per session
session_metrics as (

	select 
    	event_ts::date as event_date,
        session_id,
        timediff(second, min(event_ts), max(event_ts)) as session_length_in_sec,
        count_if(event_name = 'search') as num_searches
    from events_deduped
    group by 1, 2

),

-- most viewed recipe per day
top_recipe as (
	
    select 
    	event_ts::date as event_date,
        recipe_id as top_recipe_id,          
        count(*) as num_views
    from events_deduped
    where recipe_id is not null 
    group by 1, 2
    qualify 
    	row_number() over (partition by event_date order by num_views desc) = 1

)

-- metrics per day
	select
		session_metrics.event_date,
        top_recipe.top_recipe_id,
        count(session_metrics.session_id) as num_unique_sessions,
        avg(session_metrics.session_length_in_sec) as avg_session_length_in_sec,
        avg(session_metrics.num_searches) as avg_num_searches
        
    from session_metrics
    inner join top_recipe on session_metrics.event_date = top_recipe.event_date
    group by 1, 2
    order by 1
