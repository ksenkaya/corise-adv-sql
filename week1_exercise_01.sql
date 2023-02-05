/*
Exercise 1: find which customers are eligible to order from Virtual Kitchen
            and which distributor will handle the orders that they place with the following information:
customer_id
customer_first_name
customer_last_name
customer_email
supplier_id
supplier_name
shipping_distance_km
*/

-- customers enriched with city and state
with customers as (

    select
        cd.customer_id,
        cd.first_name as customer_first_name,
        cd.last_name as customer_last_name,
        cd.email as customer_email,
        upper(trim(ca.customer_city)) as customer_city,
        upper(ca.customer_state) as customer_state
        
    from vk_data.customers.customer_data cd 
    inner join vk_data.customers.customer_address ca on cd.customer_id = ca.customer_id

),

-- cities deduped
cities as (

    select
        city_name as city,
        state_abbr as state,
        geo_location
    from vk_data.resources.us_cities
    qualify row_number() over (partition by city_name, state_abbr order by city_name) = 1

),

eligible_customers as (
    
    select 
        customers.*,
        cities.geo_location as customer_geo_location
    from customers
    inner join cities on customers.customer_city = cities.city and customers.customer_state = cities.state

),

suppliers as (

    select 
        supplier_id,
        supplier_name,
        c.geo_location as supplier_geo_location
    from vk_data.suppliers.supplier_info s 
    inner join cities c on upper(s.supplier_city) = c.city and s.supplier_state = c.state
    
),

-- closest shipping distance to customer
final as (

select
    customer_id,
    customer_first_name,
    customer_last_name,
    customer_email,
    supplier_id,
    supplier_name,
    (st_distance(customer_geo_location, supplier_geo_location) / 1000) as shipping_distance_km
    
from eligible_customers
cross join suppliers
qualify row_number() over (partition by customer_id order by shipping_distance_km) = 1 --returns min distance per customer_id
)

select *
from final
order by customer_last_name, customer_first_name
