# High Level Sales Analysis
#  What was the total quantity sold for all products?

select sum(qty) as quantity_sold
from sales;

-- There are 45216 no of product sold

# What is the total generated revenue for all products before discounts?

select sum(s.qty *p.price) as total_revenue_before_duscount
from sales s 
join product_prices p
using(price);
-- Totale revenue befor discount is 1362983 rs 
#What was the total discount amount for all products?
select sum(discount) as total_discount
from sales;

-- total amount of all discount is 182700

## Transaction Analysis --

# How many unique transactions were there?

select count(distinct txn_id) as unique_txn
from sales;

-- there are 2500 unique transaction 

# What is the average unique products purchased in each transaction?

select avg(  unique_product ) as avg_unique_product 
from (
		 select txn_id,
			count(distinct prod_id) as unique_product 
			from sales 
			group by txn_id
    ) as trans_product;
    
--     the average unique products purchased in each transaction is 6.0380

# What are the 25th, 50th and 75th percentile values for the revenue per transaction?    

          select 
				  percentile_cont(0.25) within group (order by total_revenue) as percentile_25,
				  percentile_cont(0.50) within group (order by total_revenue) as percentile_50,
				  percentile_cont(0.75) within group (order by total_revenue) as  percentile_75
          from (
			   select txn_id,
               sum(qty * price * (1-discount/100) ) as total_revenue 
               from sales
               group by txn_id
          )  as transaction_revenue ;
 # work in progress
 
 # What is the average discount value per transaction?
 
 select round(avg (qty*price*discount / 100),2) as discount_avg
   from sales;
-- the average discount value per transaction is 10.35

# What is the percentage split of all transactions for members vs non-members?

select sum(case when member_m = 't' then 1 else 0 end ) *100 / count(*) as mamber_per,
       sum(case when member_m = 'f' then 1 else 0 end) *100 / count(*) as non_mamber_per
from sales ; 
--     the percentage split of all transactions for members vs non-members is 60.0265 and 39.9735

# What is the average revenue for member transactions and non-member transactions?

select avg(case when member_m = 't' then (qty * price) * (1-discount/100)  end ) as mamber_avg,
       avg(case when member_m = 'f' then (qty * price )* (1-discount/100) end) as non_mamber_avg
from sales ; 
-- the average revenue for member transactions and non-member transactions is 75.43 and 74.53

# product analysis

# What are the top 3 products by total revenue before discount?

select s.prod_id,
       pd.product_name,
		sum(s.price*s.qty ) as total_revenue
   from sales s
   join product_details pd
  on pd.product_id = s.prod_id
   group by s.prod_id, pd.product_name
   order by s.prod_id
   limit 3 ;
   
  # What is the total quantity, revenue and discount for each segment? 
  
  select sum( qty) as total_qty,
		 sum(qty*price*(1-discount*0.01))  as total_revenue,
         sum((qty*price*discount) /100) as total_diacount,
         segment_name
      from sales 
      join product_details
      using (price)
      group by segment_name;
      
# What is the top selling product for each segment?
with cte as (select product_name,
			   Segment_name, 
			   sum(qty) as total_qty,
			   rank() over(partition by segment_name order by sum(qty) )as top_rank
			from sales 
			  join product_details
			  using (price)
			  group by segment_name,product_name
      )
      
      select segment_name,product_name,total_qty
      from cte 
      where top_rank = 1;
      
# What is the total quantity, revenue and discount for each category?    

select     category_name,
		   sum(qty) as total_qty,
		   sum(price*qty*(1-discount*0.01))  as total_revenue,
		   sum((price*qty*discount) / 100 ) as total_discount
      from sales
      join product_details
      using(price)
      group by category_name;
      
# What is the top selling product for each category?

 with cte as (
         select category_name,
			   product_name,
			   sum(qty) as total_qty,
			   rank()over(partition by category_name order by sum(qty) desc) as trk
		  from sales
		  join product_details 
		  using (price)
		  group by category_name,product_name
	)
       select category_name,
			   product_name,
                total_qty 
               from cte
               where trk= 1;
  
# What is the percentage split of revenue by product for each segment?

with cte as(  select product_name,
			   segment_name,
			   sum(price*qty*(1-discount*0.01)) as rev_product
			   from sales
			   join product_details
			   using (price)
			   group by product_name,segment_name
       )
       select product_name , segment_name ,round(rev_product*100/ (select sum(price*qty*(1-discount*0.01)) from sales),2) rev_Percentage
       from cte 
       order by product_name,segment_name;
       
# What is the percentage split of revenue by segment for each category?       
  
  
  with segm as (select segment_name,
         category_name,
         sum(qty*price*(1-discount*0.01)) as rev_seg
        from sales 
        join product_details
        using (price)
        group by segment_name,category_name
     )   
     select segment_name,
            category_name, 
            round(rev_seg*100 / (select sum(qty*price*(1-discount*0.01))from sales) , 2) as rev_per
            from segm
            order by segment_name;
            
# What is the percentage split of total revenue by category?  
  
  with cat as (select 
         category_name,
         sum(qty*price*(1-discount*0.01)) as rev_seg
        from sales 
        join product_details
        using (price)
        group by category_name
     )   
     select 
            category_name, 
            round(rev_seg*100 / (select sum(qty*price*(1-discount*0.01))from sales) , 2) as rev_per
            from cat
            order by category_name;
            
# What is the total transaction “penetration” for each product?
-- (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

select product_name,
       count(distinct txn_id)*100 / (select count(distinct txn_id)from sales) as penetration
       from sales
       join product_details
       using (price)
       where qty >= 1
       group by product_name
       order by product_name;
       
# What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
SELECT s.prod_id, t1.prod_id, t2.prod_id, COUNT(*) AS combination_cnt       
FROM sales s
JOIN sales t1 ON t1.txn_id = s.txn_id 
AND s.prod_id < t1.prod_id
JOIN sales t2 ON t2.txn_id = s.txn_id
AND t1.prod_id < t2.prod_id
GROUP BY 1, 2, 3
ORDER BY 4 DESC
LIMIT 1;



















       
       
       
       
       
       
       
            
            
            
            
            
            
  
  
  
  
  
       








      
		  
      
      
      
      
      
      
      










   
   
   
   
   
   
   
   
   
   
   
	








       
	
       