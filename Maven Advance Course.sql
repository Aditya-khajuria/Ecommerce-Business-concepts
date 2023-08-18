use mavenfuzzyfactory;

select * from website_sessions
where website_session_id=1059;

select * from  website_pageviews
where website_session_id=1059;

select * from  orders
where website_session_id=1059;

-- Here we found out that against the maxt website sessions by utm_content, how many orders were converted

Select website_sessions.utm_content, 
count(distinct website_sessions.website_session_id) As Sessions,
count(distinct orders.order_id) as orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) As Session_to_order_conversion_rate 

-- the above query is used to find out the percentage of order converted i.e total orders/ total number of sessions

From website_sessions 
left join orders on website_sessions.website_session_id=orders.website_session_id
where website_sessions.website_session_id between 1000 and 2000
group by  website_sessions.utm_content
order by Sessions desc;

/*
1. Pull a list to see the breakdown by UTM source, campagin and referring domain.
*/

select utm_source, utm_campaign, http_referer, count(distinct website_session_id)
from website_sessions
where created_at<'2012-04-12'
group by 1,2,3
order by 4 desc;

/*
2. Seems like gseaerch nonbrand  is our major traffic source, now we have to calculate the concersion rate from sessios 
   to order.
*/
select 
count(distinct website_sessions.website_session_id) as sessions,
count(distinct orders.order_id) as orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as coversion_rate

from website_sessions

left join orders on website_sessions.website_session_id= orders.website_session_id
where website_sessions.created_at < '2012-04-14'
and utm_source='gsearch' 
      and utm_campaign= 'nonbrand';
      
/*
3. Based on my 	coversion rate analysis, they bid down gsearch nonbrand on 2012-04-15,
   Pull gsearch nonbrand trended session voulume, by week to see if the bid changes have caused voulme drop at all?
   */

select 
Min(date(website_sessions.created_at)) As week_started_at, 
count(orders.order_id) as Orders,
count(distinct website_sessions.website_session_id) as sessions
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id

where website_sessions.created_at < '2012-05-10'
and utm_source='gsearch' 
      and utm_campaign= 'nonbrand'
      group by 
      year(website_sessions.created_at), 
      week(website_sessions.created_at);
      
/*
4.pull the conversion rate from sessions to order by device type. 
*/

select 
website_sessions.device_type, 
count(orders.order_id) As orders,  
count(distinct orders.order_id )/ count(website_sessions.website_session_id) As conversion_rate
from website_sessions 
left join orders on website_sessions.website_session_id=orders.website_session_id
where website_sessions.created_at < '2012-05-11'
and utm_source='gsearch' 
      and utm_campaign= 'nonbrand'
group by 1;

/*
4.pull the weekly trends for both desktop and mobile so we can see the impact on volume.
*/
select 
-- year(website_sessions.created_at),
-- week(website_sessions.created_at),
min(date(website_sessions.created_at)) as Start_week,
count(website_sessions.website_session_id) As sessions,
count(orders.order_id) as Orders,
count(Case when device_type='desktop' then 1 else null end) As desktop,
count(Case when device_type='mobile' then 1 else null end) As mobile
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id

where website_sessions.created_at between '2012-04-15' and '2012-06-09'
and utm_source='gsearch' 
      and utm_campaign= 'nonbrand'
group by year(website_sessions.created_at),
week(website_sessions.created_at);
-- From the above data we can see that desktop is looking strong, thanks to bid changs we made based on my previous conversion rate.

/*
Finding top pages(URLs) against number of Page views
*/

select 
pageview_url,
count(website_pageview_id)  As Page_views
from website_pageviews
where website_pageview_id<1000

group by pageview_url
order by Page_views desc;


/*
Top entry pages analysis  -- For one session ID there will be multiple pageview IDs 
(home tab-1st pageviewid, products tab- 2nd pageviewid...)
That is why we will create a temporary table which includes only first pageview ID of the given Session ID.
*/

select website_session_id,
Min(website_pageview_id) as Min_Page_view_id     -- WIth this query we found the first page (by using min(website_pageview_id) ) viewed 
                                             --  by the customer (with session_ ID) 
from website_pageviews
group by website_session_id;

-- Now we will create a temporary table and join with the website pageview table

Create temporary table First_page_view
select website_session_id,
Min(website_pageview_id) as Min_Page_view_id    
from website_pageviews
where website_pageview_id<1000
group by website_session_id;

select * from First_page_view;

-- the below query is used to find out the top landing page i.e Home page and that's why we join temp table with main table based upn the 
-- min_page_view_id (from temp table )and pageview_id (main table)

select  website_pageviews.pageview_url As Landing_page,
Count(First_page_view.website_session_id ) as sessions_hitting_on_lander
 from  First_page_view 
 left join website_pageviews on First_page_view.Min_Page_view_id=website_pageviews.website_pageview_id
 group by 1 ;

 /* 
 1. Pull the most viewwed  website page and rank the sessions by volume. (That means top page view and number of page view ids 
 assiciated with the respective page view )
 */

Select pageview_url, 
count(distinct website_pageview_id) as sessions
 from website_pageviews
 where created_at <'2012-06-09'
 group by 1 
 order by 2 desc;
 
 /* 
 2. Pull the entry pages and rank them on entry volume.
 */

Create temporary table First_page_view_Morgan
select website_session_id,
Min(website_pageview_id) as Min_pageView_id
 from website_pageviews
 where created_at <'2012-06-12' 
 group by website_session_id;
 
 Select * from First_page_view_Morgan;
 
 Select website_pageviews.pageview_url as Entry_page,
 Count(First_page_view_Morgan.website_session_id) As Volume
 from First_page_view_Morgan
 left join website_pageviews on First_page_view_Morgan.Min_pageView_id= website_pageviews.website_pageview_id
 group by 1;
 
-- Business concept- We want to see landing page performance for a certain time period

-- First, we're going to find the first website page ID for each relevant session.
-- Second, we're going to identify the landing page URL of that session.
-- Third, we'll be counting the total number of page views for each session to to identify 'bounces'
-- Fourth, we'll summarize total sessions and bounce sessions by landing page, so we can figure out which landing pages are doing the best and which ones have the most opportunity for improvement.

/*
Finding the minmum website pageview id associated with each session we care about
*/

	select website_sessions.website_session_id,
	Min(website_pageview_id) as Min_pageView_id
	 from website_sessions
     inner  join website_pageviews on website_sessions.website_session_id= website_pageviews.website_session_id     
	 where website_sessions.created_at between '2014-01-01' and  '2014-02-01' 
	 group by 1;

/*
Same as above , but this time we are sorting the dataset as a temporary table
*/

Create temporary table First_Pageview_demo
select website_sessions.website_session_id,
	Min(website_pageview_id) as Min_pageView_id
	 from website_sessions
     left join website_pageviews on website_sessions.website_session_id= website_pageviews.website_session_id     
	 where website_sessions.created_at between '2014-01-01' and  '2014-02-01' 
	 group by website_session_id;
 
Select * from First_Pageview_demo; -- this table is ceated which consists of first page against the session id
     
/*
Now we will bring in the landing page to each session
*/
  
Select 
website_pageviews.website_session_id,
website_pageviews.pageview_url As Landing_page
from First_Pageview_demo 
left join website_pageviews on First_Pageview_demo.Min_pageView_id=website_pageviews.website_pageview_id;-- Website pageview is the landing page

-- Now we will create the above table as another temporary table with, session with landing page 

Create temporary table Sessions_w_landing_page_demo
Select 
website_pageviews.website_session_id,
website_pageviews.pageview_url As Landing_page
from First_Pageview_demo 
left join website_pageviews on First_Pageview_demo.Min_pageView_id=website_pageviews.website_pageview_id;

select * from  Sessions_w_landing_page_demo;


-- Now we will craete a table to include a count of pageviews per session (Since one session can have multiple pageviews, thatcis why we will use website pageviews table) 

Select Sessions_w_landing_page_demo.website_session_id,
Sessions_w_landing_page_demo.Landing_page,
count(website_pageviews.website_pageview_id) As Count_of_pages_viewed
from Sessions_w_landing_page_demo 
left join website_pageviews on Sessions_w_landing_page_demo.website_session_id=website_pageviews.website_session_id
group by 1
Having count(website_pageviews.website_pageview_id)=1; -- We used having to limit the number of pageviews per session to 1

-- Now will craete the above table as another temporary table with bounced session only.

Create temporary table bounced_session_only
Select Sessions_w_landing_page_demo.website_session_id,
Sessions_w_landing_page_demo.Landing_page,
count(website_pageviews.website_pageview_id) As Count_of_pages_viewed
from Sessions_w_landing_page_demo 
left join website_pageviews on Sessions_w_landing_page_demo.website_session_id=website_pageviews.website_session_id
group by 1
Having count(website_pageviews.website_pageview_id)=1;

Select * from  bounced_session_only;

-- we will write a query to find the bounced sessions based on the Sessions_w_landing_page_demo table and bounced_session_only table

select  Sessions_w_landing_page_demo.Landing_page,
 Sessions_w_landing_page_demo.website_session_id,
 bounced_session_only.website_session_id As bounced_website_session_id
 from Sessions_w_landing_page_demo
 left join bounced_session_only on Sessions_w_landing_page_demo.website_session_id= bounced_session_only.website_session_id
 order by Sessions_w_landing_page_demo.website_session_id;

--  we will use the same abouve query to find the count of the records\
-- will group by landing page and then will add a bouce rate column

select  Sessions_w_landing_page_demo.Landing_page,
 Count(Sessions_w_landing_page_demo.website_session_id) as Sessions,
 COunt(bounced_session_only.website_session_id)  As bounced_sessions,
 Count(bounced_session_only.website_session_id)/Count(Sessions_w_landing_page_demo.website_session_id)  As bounced_rate
 from Sessions_w_landing_page_demo
 left join bounced_session_only on Sessions_w_landing_page_demo.website_session_id= bounced_session_only.website_session_id
 Group by Sessions_w_landing_page_demo.Landing_page
 order by Sessions_w_landing_page_demo.website_session_id;


/*
Could you pull  bounce rates of traffic landing on the homepage? I would like to see 3 numbers; sessions, bounced sessions and bounces rate
*/
select website_session_id,
min(website_pageview_id) As Min_page_view_id
from website_pageviews
where created_at<'2012-06-14'
group by website_session_id;


Create temporary table Min_page_view_id_demo
select website_session_id,
min(website_pageview_id) As Min_page_view_id
from website_pageviews
where created_at<'2012-06-14'
group by website_session_id;


Select Min_page_view_id_demo.website_session_id,
website_pageviews.pageview_url As Landing_page
from Min_page_view_id_demo 
left join website_pageviews on Min_page_view_id_demo.Min_page_view_id=website_pageviews.website_pageview_id;

Create temporary table Sessions_w_home_landing_page
Select Min_page_view_id_demo.website_session_id,
website_pageviews.pageview_url As Landing_page
from Min_page_view_id_demo 
left join website_pageviews on Min_page_view_id_demo.Min_page_view_id=website_pageviews.website_pageview_id
where website_pageviews.pageview_url='/home';

Select * from Sessions_w_home_landing_page;


select Sessions_w_home_landing_page.website_session_id,
Sessions_w_home_landing_page.Landing_page As Landing_page,
Count(website_pageviews.website_pageview_id) As Count_of_pages_viewed
From Sessions_w_home_landing_page 
left join website_pageviews on Sessions_w_home_landing_page.website_session_id=website_pageviews.website_session_id
group by 1
Having Count_of_pages_viewed=1;

Create temporary table bounce_sessions
select Sessions_w_home_landing_page.website_session_id,
Sessions_w_home_landing_page.Landing_page As Landing_page,
Count(website_pageviews.website_pageview_id) As Count_of_pages_viewed
From Sessions_w_home_landing_page 
left join website_pageviews on Sessions_w_home_landing_page.website_session_id=website_pageviews.website_session_id
group by 1
Having Count_of_pages_viewed=1;

Select * from Sessions_w_home_landing_page;
Select * from bounce_sessions;

-- Now we will find the number of bounced sessions in home landing page (/will use  bounce_sessions table and Sessions_w_home_landing_page)

Select Sessions_w_home_landing_page.website_session_id,
Sessions_w_home_landing_page.Landing_page,
Count(bounce_sessions.website_session_id) As Bounce_website_session_id
from Sessions_w_home_landing_page 
left join bounce_sessions on Sessions_w_home_landing_page.website_session_id= bounce_sessions.website_session_id
order by 1;



Select 
Count(Sessions_w_home_landing_page.website_session_id) As total_sessions,
Count(bounce_sessions.website_session_id) As Bounceed_sessions,
Count(bounce_sessions.website_session_id)/Count(Sessions_w_home_landing_page.website_session_id) As Bounce_rate
from Sessions_w_home_landing_page 
left join bounce_sessions on Sessions_w_home_landing_page.website_session_id= bounce_sessions.website_session_id
order by 1;


-- Business concept
-- 1. We want to built a mini conversion funnel, from /lander-2 to /Cart
-- 2. We want to know how many people reach each step, and also dropoff rates
-- 3. for simplicity of the demo , we are looking at /lander-2 traffic only 
-- 4. for simplicity of the demo, we are looking at cx who like Mr. fuzzy only


-- Step 1. select all the pageviews for relevent sessions

-- Here first will join the 2 below tables to get the pageview_url, session id and created at 
-- Now will write a case query to individually evaluate the funnel path (to flag with 1).

select website_pageviews.pageview_url,
website_sessions.website_session_id,
website_pageviews.created_at As Pageview_created_at,
case when pageview_url='/products' then 1 else 0 end As Product_page,
case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end As Mr_Fuzzy_page,
case when pageview_url='/cart' then 1 else 0 end As Cart_page

from website_sessions
left join website_pageviews on website_sessions.website_session_id= website_pageviews.website_session_id
where website_pageviews.created_at between '2014-01-01' and '2014-02-01'
and website_pageviews.pageview_url IN('/lander-2','/products', '/the-original-mr-fuzzy','/cart')
order by website_sessions.website_session_id, website_pageviews.created_at;


-- Next we will put the previous query inside subquery (similar to temp table)
-- we will group by website_session_id and take MAx() of each of the flags
-- this Max() becomes a made_it flag for that session , to show the session made it there

Select website_session_id,
Max(Product_page) As Product_made_it,
Max(Mr_Fuzzy_page) As Mr_Fuzzy_made_it,
Max(Cart_page) As Cart_made_it

from (
select website_pageviews.pageview_url,
website_sessions.website_session_id,
website_pageviews.created_at As Pageview_created_at,
case when pageview_url='/products' then 1 else 0 end As Product_page,
case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end As Mr_Fuzzy_page,
case when pageview_url='/cart' then 1 else 0 end As Cart_page

from website_sessions
left join website_pageviews on website_sessions.website_session_id= website_pageviews.website_session_id
where website_pageviews.created_at between '2014-01-01' and '2014-02-01'
and website_pageviews.pageview_url IN('/lander-2','/products', '/the-original-mr-fuzzy','/cart')
order by website_sessions.website_session_id, website_pageviews.created_at) As pageview_level

group by website_session_id;


-- Now we will create a temporary table of the above table

Create temporary table session_level_made_it_to_flag
Select website_session_id,
Max(Product_page) As Product_made_it,
Max(Mr_Fuzzy_page) As Mr_Fuzzy_made_it,
Max(Cart_page) As Cart_made_it

from (
select website_pageviews.pageview_url,
website_sessions.website_session_id,
website_pageviews.created_at As Pageview_created_at,
case when pageview_url='/products' then 1 else 0 end As Product_page,
case when pageview_url='/the-original-mr-fuzzy' then 1 else 0 end As Mr_Fuzzy_page,
case when pageview_url='/cart' then 1 else 0 end As Cart_page

from website_sessions
left join website_pageviews on website_sessions.website_session_id= website_pageviews.website_session_id
where website_pageviews.created_at between '2014-01-01' and '2014-02-01'
and website_pageviews.pageview_url IN('/lander-2','/products', '/the-original-mr-fuzzy','/cart')
order by website_sessions.website_session_id, website_pageviews.created_at) As pageview_level

group by website_session_id;

Select * from session_level_made_it_to_flag;

-- this would produce the final output (Part 1)

Select 
count(distinct website_session_id) As sessions,
count(distinct case when Product_made_it=1 then website_session_id else NULL end ) as to_products,
count(distinct case when Mr_Fuzzy_made_it=1 then website_session_id else NULL end ) as to_Mrfuzzy,
count(distinct case when Cart_made_it=1 then website_session_id else NULL end ) as to_cart
 from session_level_made_it_to_flag;
 
 -- Now we will convert	the the above counts click counts for final O/p (click rate or conversion rate)
 -- Will use the same query above and show how to calcuate the rates
 
 Select 
count(distinct website_session_id) As sessions,
count(distinct case when Product_made_it=1 then website_session_id else NULL end )/
count(distinct website_session_id) As lander_clickthrough_rate,
count(distinct case when Mr_Fuzzy_made_it=1 then website_session_id else NULL end )/
count(distinct case when Product_made_it=1 then website_session_id else NULL end ) as product_clickthrough_rate,
count(distinct case when Cart_made_it=1 then website_session_id else NULL end )/
count(distinct case when Mr_Fuzzy_made_it=1 then website_session_id else NULL end ) As Myfuzzyclickthrough_rate
 from session_level_made_it_to_flag;
  /*
 In the above , we are calculating the click rate firstly from total sessions to product 
 and the from product to my fuzzy and then from my fuzzy to cart.
 */
 
-- Problem 1, start with /lander-1 and bulid the funnel all the way to our  thank you page. date: '2012-08-05' to '2012-09-05'

select website_sessions.website_session_id,
       website_pageviews.pageview_url,
       website_sessions.created_at As Pageview_created,
Case when website_pageviews.pageview_url='/lander-1' then 1 else 0 end As Lander_page,
Case when website_pageviews.pageview_url='/products' then 1 else 0 end As Product_page,
Case when website_pageviews.pageview_url='/the-original-mr-fuzz' then 1 else 0 end As MrFuzzy_page,
Case when website_pageviews.pageview_url='/cart' then 1 else 0 end As Cart_page,
Case when website_pageviews.pageview_url='/shipping' then 1 else 0 end As shipping_page,
Case when website_pageviews.pageview_url='/billing' then 1 else 0 end As billing_page,
Case when website_pageviews.pageview_url='/thank-you-for-your-order' then 1 else 0 end As thankyou_page

from   website_sessions 
left join   website_pageviews on  website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.created_at between '2012-08-05' and '2012-09-05'
and  website_pageviews.pageview_url IN
('/lander-1','/products', '/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
order by website_sessions.website_session_id,website_pageviews.pageview_url;


-- Now we will group by the sessions as per the flags 

Select 
website_session_id,
Max(Lander_page) as to_lander,
Max(Product_page)as to_product,
Max(MrFuzzy_page)as to_Mrfuzzy,
Max(Cart_page)as to_card,
Max(shipping_page)as to_shipping,
Max(billing_page)as to_billing,
Max(thankyou_page)as to_thankyou


from (select website_sessions.website_session_id,
       website_pageviews.pageview_url,
       website_sessions.created_at As Pageview_created,
Case when website_pageviews.pageview_url='/lander-1' then 1 else 0 end As Lander_page,
Case when website_pageviews.pageview_url='/products' then 1 else 0 end As Product_page,
Case when website_pageviews.pageview_url='/the-original-mr-fuzz' then 1 else 0 end As MrFuzzy_page,
Case when website_pageviews.pageview_url='/cart' then 1 else 0 end As Cart_page,
Case when website_pageviews.pageview_url='/shipping' then 1 else 0 end As shipping_page,
Case when website_pageviews.pageview_url='/billing' then 1 else 0 end As billing_page,
Case when website_pageviews.pageview_url='/thank-you-for-your-order' then 1 else 0 end As thankyou_page

from   website_sessions 
left join   website_pageviews on  website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.created_at between '2012-08-05' and '2012-09-05'
and  website_pageviews.pageview_url IN
('/lander-1','/products', '/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
order by website_sessions.website_session_id,website_pageviews.pageview_url) As pageview_level_


Group by pageview_level_.website_session_id;

-- We will craete the above table as temp table and count the session against the flags

create temporary table Session_level_made_it_to_flag_
Select 
website_session_id,
Max(Lander_page) as lander_made,
Max(Product_page)as product_made,
Max(MrFuzzy_page)as Mrfuzzy_made,
Max(Cart_page)as card_made,
Max(shipping_page)as shipping_made,
Max(billing_page)as billing_made,
Max(thankyou_page)as thankyou_made


from (select website_sessions.website_session_id,
       website_pageviews.pageview_url,
       website_sessions.created_at As Pageview_created,
Case when website_pageviews.pageview_url='/lander-1' then 1 else 0 end As Lander_page,
Case when website_pageviews.pageview_url='/products' then 1 else 0 end As Product_page,
Case when website_pageviews.pageview_url='/the-original-mr-fuzz' then 1 else 0 end As MrFuzzy_page,
Case when website_pageviews.pageview_url='/cart' then 1 else 0 end As Cart_page,
Case when website_pageviews.pageview_url='/shipping' then 1 else 0 end As shipping_page,
Case when website_pageviews.pageview_url='/billing' then 1 else 0 end As billing_page,
Case when website_pageviews.pageview_url='/thank-you-for-your-order' then 1 else 0 end As thankyou_page

from   website_sessions 
left join   website_pageviews on  website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.created_at between '2012-08-05' and '2012-09-05'
and  website_pageviews.pageview_url IN
('/lander-1','/products', '/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
order by website_sessions.website_session_id,website_pageviews.pageview_url) As pageview_level_


Group by pageview_level_.website_session_id;

select * from Session_level_made_it_to_flag_;

select 
count(website_session_id) As sessions,
count(distinct case when lander_made=1 then website_session_id else 0 end) as to_lander,
count(distinct case when product_made=1 then website_session_id else 0 end) as to_product,
count(distinct case when Mrfuzzy_made=1 then website_session_id else 0 end) as to_Mrfuzzy,
count(distinct case when card_made=1 then website_session_id else 0 end) as to_card,
count(distinct case when shipping_made=1 then website_session_id else 0 end) as to_shipping,
count(distinct case when billing_made=1 then website_session_id else 0 end) as to_billing,
count(distinct case when thankyou_made=1 then website_session_id else 0 end) as to_thankyou

from Session_level_made_it_to_flag_;

/*
Business concept- Channel Portfolio Analysis
*/
-- to Identify traffic coming from multiple marketing channels, we will use utm paramaters stored in our session table
-- we will left join to our orders table to understand which of the sessions are converted	to placing an order and generating revenue

Select website_sessions.utm_content,
count(website_sessions.website_session_id) As Sessions,
count(orders.order_id) As Orders,
count(orders.order_id)/count(website_sessions.website_session_id) As session_to_order_conversion_rate
from website_sessions 
left join orders on website_sessions.website_session_id=orders.website_session_id
where  website_sessions.created_at between '2014-01-01' and '2014-02-01'
group by website_sessions.utm_content
order by Sessions desc;


-- 1. We launched a second paid search channel, bsearch around Aug 22, pull weekly trended sessions volume since then and compare
      -- grearch nonbrand.
select
-- yearweek(created_at),
Min(Date(created_at)) As Week_start_date,
count(distinct website_session_id) As sessions,
count(distinct Case when  utm_source='gsearch' then website_session_id else Null end) As gsearch_sessions,
count(distinct Case when  utm_source='bsearch' then website_session_id else Null end )As bsearch_sessions
from website_sessions 
where website_sessions.created_at>'2012-08-22' 
and website_sessions.created_at<'2012-11-29'
and utm_campaign='nonbrand'
group by yearweek(created_at)	







