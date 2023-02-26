# Project 4: Evaluate a Candidate's SQL Tech Exercise
Instructions:
We need to develop a report to analyze AUTOMOBILE customers who have placed URGENT orders. We expect to see one row per customer, with the following columns:

* C_CUSTKEY
* LAST_ORDER_DATE: The date when the last URGENT order was placed
* ORDER_NUMBERS: A comma-separated list of the order_keys for the three highest dollar urgent orders
* TOTAL_SPENT: The total dollar amount of the three highest orders
* PART_1_KEY: The identifier for the part with the highest dollar amount spent, across all urgent orders 
* PART_1_QUANTITY: The quantity ordered
* PART_1_TOTAL_SPENT: Total dollars spent on the part 
* PART_2_KEY: The identifier for the part with the second-highest dollar amount spent, across all urgent orders  
* PART_2_QUANTITY: The quantity ordered
* PART_2_TOTAL_SPENT: Total dollars spent on the part 
* PART_3_KEY: The identifier for the part with the third-highest dollar amount spent, across all urgent orders 
* PART_3_QUANTITY: The quantity ordered
* PART_3_TOTAL_SPENT: Total dollars spent on the part 

The output should be sorted by *LAST_ORDER_DATE* descending.

![image](https://user-images.githubusercontent.com/8420258/221325864-028914d7-2c05-4314-a7a0-b3159eb06d4a.png)

### 1. Create a query to provide the report requested. Your query should have a LIMIT 100 when you submit it for review. Remember that you are creating this as a tech exercise for a job evaluation. Your query should be well-formatted, with clear names and comments.

``` sql
with auto_customers_with_urgent_orders as (
    
    select 
        c_custkey::varchar as customer_key,
        o_orderkey::varchar as order_key,
        l_partkey::varchar as part_key,
        o_orderdate as order_date,
        l_quantity as part_quantity,
        l_extendedprice as part_price,
        dense_rank() over (partition by customer_key order by part_price desc) as top_order_rank
    from snowflake_sample_data.tpch_sf1.customer
    inner join snowflake_sample_data.tpch_sf1.orders on c_custkey = o_custkey
    inner join snowflake_sample_data.tpch_sf1.lineitem on o_orderkey = l_orderkey
    where c_mktsegment = 'AUTOMOBILE'
        and o_orderpriority = '1-URGENT'

),

-- TOP 3 urgent orders per customer
top_three_orders as (

    select
        customer_key,
        listagg(order_key, ', ') as order_numbers,
        sum(part_price) as total_spent,
        max(order_date) as last_order_date
    from auto_customers_with_urgent_orders
    where top_order_rank <= 3
    group by 1
    
),

-- TOP 3 parts based on top_order_rank
top_three_parts as (

    select 
        customer_key,
        max(case when top_order_rank = 1 then part_key end) part_1_key,
        max(case when top_order_rank = 1 then part_quantity end) part_1_quantity,
        max(case when top_order_rank = 1 then part_price end) part_1_total_spent,
        max(case when top_order_rank = 2 then part_key end) part_2_key,
        max(case when top_order_rank = 2 then part_quantity end) part_2_quantity,
        max(case when top_order_rank = 2 then part_price end) part_2_total_spent,
        max(case when top_order_rank = 3 then part_key end) part_3_key,
        max(case when top_order_rank = 3 then part_quantity end) part_3_quantity,
        max(case when top_order_rank = 3 then part_price end) part_3_total_spent
    from auto_customers_with_urgent_orders
    group by 1

),

final as (

    select 
        orders.customer_key,
        orders.last_order_date,
        orders.order_numbers,
        orders.total_spent,
        parts.part_1_key,
        parts.part_1_quantity,
        parts.part_1_total_spent,
        parts.part_2_key,
        parts.part_2_quantity,
        parts.part_2_total_spent,
        parts.part_3_key,
        parts.part_3_quantity,
        parts.part_3_total_spent
    from top_three_orders orders 
    inner join top_three_parts parts on orders.customer_key = parts.customer_key
    
)

select count(*), customer_key
from final
order by last_order_date desc
limit 100
```

### 2. Review the candidate's tech exercise below, and provide a one-paragraph assessment of the SQL quality. Provide examples/suggestions for improvement if you think the candidate could have chosen a better approach.

*Do you agree with the results returned by the query?*
* In general, yes. However, the query includes a filter on the self joins that elimintes customers who order less than 3 parts. My assumption it shouldn't be the case.

*Is it easy to understand?*
It's okay, but could be improved with the followings:
* adding brief and meaningful comments
* fully qualified aliases with the table names instead of using abbreviations
* leveraging CTEs to reduce the number of self-joins against the urgent_orders table

*Could the code be more efficient?*

It took 3.2sec, with 25 partitions scanned. Most expensive node was to scan lineitem and orders tables.
It could be improved at least with the followings:
* remove the order by clauses from the urgent_orders and top orders CTEs
* remove the join to parts table in urgent_orders CTE as no attributes coming from this table