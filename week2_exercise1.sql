/* Rework a Query to Improve Its Readability
Query to identify the impacted customers and their attributes in order to compose an offer to customers impacted

Approach taken:
- created CTEs to modularize logical units of code
- applied consisting casing on certain string fields
- added comments to explain certain CTEs
- applied consistent code style and formatting
*/

-- customers enriched with city and state
with customers as (

    select
        customer_data.customer_id,
        customer_data.first_name || ' ' || customer_data.last_name as customer_name,
        upper(trim(customer_address.customer_city)) as customer_city,
        upper(customer_address.customer_state) as customer_state
    from vk_data.customers.customer_data
    inner join vk_data.customers.customer_address on customer_data.customer_id = customer_address.customer_id

),

cities_cleaned as (

    select
        upper(trim(city_name)) as city,
        upper(trim(state_abbr)) as state,
        geo_location
    from vk_data.resources.us_cities

),

-- impacted customers based on state and city
impacted_customers as (

    select * 
    from customers
    where (customer_state = 'KY' and customer_city in ('CONCORD', 'GEORGETOWN', 'ASHLAND'))
         or (customer_state = 'CA' and customer_city in ('OAKLAND', 'PLEASANT HILL'))
         or (customer_state = 'TX'and customer_city in ('ARLINGTON', 'BROWNSVILLE'))   

),

-- geolocation of the grocery store in Chicago
chicago_geo as (

    select geo_location
    from cities_cleaned
    where city = 'CHICAGO' 
        and state = 'IL'
    
),

-- geolocation of the the grocery store in Gary
gary_geo as (

    select geo_location
    from cities_cleaned
    where city = 'GARY'  
        and state = 'IN'
 
),

-- # of food preferences per customer
food_pref_count_per_customer as (

    select 
        customer_id,
        count(*) as food_pref_count
    from vk_data.customers.customer_survey
    where is_active = true
    group by 1

),

-- distance to each store per customer
final as (

    select 
        impacted_customers.customer_name,
        impacted_customers.customer_city,
        impacted_customers.customer_state,
        food_pref_count_per_customer.food_pref_count,
        (st_distance(cities_cleaned.geo_location, chicago_geo.geo_location) / 1609)::int as chicago_distance_miles,
        (st_distance(cities_cleaned.geo_location, gary_geo.geo_location) / 1609)::int as gary_distance_miles
    from impacted_customers 
    inner join food_pref_count_per_customer on impacted_customers.customer_id = food_pref_count_per_customer.customer_id
    left join cities_cleaned on impacted_customers.customer_city = cities_cleaned.city 
                            and impacted_customers.customer_state = cities_cleaned.state
    cross join chicago_geo
    cross join gary_geo

)

select * from final
