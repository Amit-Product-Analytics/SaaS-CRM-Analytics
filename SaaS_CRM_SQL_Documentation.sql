use crm_analytics;
-- =====================================================
-- PROJECT 4 : SAAS CRM PRODUCT ANALYTICS
-- Dataset  : Custom CRM SaaS Dataset
-- Author   : Amit Kumar
-- Tool     : MySQL
-- =====================================================

-- SECTION 1 : BUSINESS OVERVIEW
-- Query 1 : Total Customers

SELECT
COUNT(DISTINCT customer_id) AS total_customers
FROM crm_customers;

-- Query 2 : Total MRR (Monthly Recurring Revenue),ARR (Annual Recurring Revenue),ARPU (Average Revenue Per User)
SELECT
ROUND(SUM(mrr), 2) AS total_mrr,
ROUND(SUM(mrr) * 12, 2) AS total_arr,
ROUND(SUM(mrr) / COUNT(DISTINCT customer_id), 2) AS arpu
FROM crm_subscriptions
WHERE status = 'Active';

-- Query 3 : ARR (Annual Recurring Revenue)

SELECT
ROUND(SUM(mrr), 2) AS total_mrr
FROM crm_subscriptions
WHERE status = 'Active'
and billing_cycle ='Annual';

-- Query 4 : Revenue by Plan Type
SELECT *
FROM crm_subscriptions;
Select
plan_type,
count(distinct customer_id) as Total_users,
sum(case when billing_cycle ='Annual' then 1 else 0 end) as Annual_user_Paid,
sum(case when billing_cycle ='Monthly' then 1 else 0 end) as Monthly_user_Paid,
sum(mrr) as Total_Amount
from crm_subscriptions
where status = 'active'
and payment_status = 'Paid'
group by 1
order by 5 desc;




-- Query 5 : Trial to Paid Conversion Rate
select
sum(case when trial_converted = 'Yes' then 1 else 0 End ) as Total_User_Conv_During_Peroids,
sum(case when trial_converted = 'No' then 1 else 0 End ) as Total_User_Conv_During_Peroids,
count(*) as Total_users,
sum(case when trial_converted = 'Yes' then 1 else 0 End )*100 /count(*) as conv_rate
from crm_customers
;


-- SECTION 2 : CUSTOMER ANALYTICS
select *
from crm_customers;


-- Query 6 : Customers by Plan Type
select
plan_type,
count(*) as Total_users,
sum(case when trial_converted = 'Yes' then 1 else 0 end ) as Buyers,
sum(case when trial_converted = 'Yes' then plan_price else 0 end ) as Total_Amount,
round(sum(case when trial_converted = 'Yes' then 1 else 0 end )*100/count(*) ,2)as Conv_Rate_Plan,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
from crm_customers
group by 1
order by 4 desc;

-- Query 7 : Customers by Industry
select
industry,
count(*) as Total_users,
sum(case when trial_converted = 'Yes' then 1 else 0 end ) as Buyers,
sum(case when trial_converted ='yes' then plan_price else 0 end) as Total_Amount_by_Buyers,
round(sum(case when trial_converted = 'Yes' then 1 else 0 end )*100/count(*) ,2)as Conv_Rate_Plan,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_by_Industry
from crm_customers
group by 1
order by 5 desc;

-- Query 8 : Revenue by Industry (JOIN)
select *
from crm_subscriptions;
select
c.industry,
sum(case when c.trial_converted ='Yes'  then 1 else 0 end) as Buyers,
sum(case when s.payment_status ='Paid' then mrr else 0 end ) as Total_Amount,
avg(sum(case when s.payment_status ='Paid' then mrr else 0 end )) as avg_amount_spend
from crm_customers c join crm_subscriptions s on c.customer_id = s.customer_id
where s.status = 'Active'
group by 1
order by 2 desc;

-- Query 9 : Sales Rep Performance

SELECT
sales_rep,
COUNT(DISTINCT c.customer_id) AS customers,
ROUND(SUM(case when s.payment_status ='Paid' then mrr else 0 end ), 2) AS total_mrr
FROM crm_customers c
JOIN crm_subscriptions s ON c.customer_id = s.customer_id
WHERE s.status = 'Active'
GROUP BY 1
ORDER BY total_mrr DESC;

-- SECTION 3 : SUBSCRIPTION ANALYTICS

-- Query 10 : Subscription Status Breakdown
select
status,
count(*)  as Total_subscription,
round(count(*)*100/sum(count(*)) over (),2) as per_by_total
from crm_subscriptions
group by 1
order by 2 desc;


-- Query 11 : Payment Status Analysis

select
payment_status,
ROUND(SUM(mrr), 2) AS mrr_at_risk,
count(*) as Pament_by,
round(count(*)*100/sum(count(*)) over(),2) as per_by_payment
from crm_subscriptions
group by 1
order by 2 desc;

-- Query 12 : Average Subscription Duration
select
plan_type,
round(avg(datediff(end_date,start_date)),0) as avg_subcription_duration,
round(avg(datediff(end_date,start_date)/30),2) as avg_subcription_monthly
from crm_subscriptions
group by 1 
order by 2 desc ;
SELECT
plan_type,
ROUND(AVG(DATEDIFF(end_date, start_date)), 0) AS avg_subscription_days,
ROUND(AVG(DATEDIFF(end_date, start_date)) / 30, 1) AS avg_subscription_months
FROM crm_subscriptions
GROUP BY plan_type
ORDER BY avg_subscription_days DESC;

-- Query 13 : LTV (Customer Lifetime Value)
SELECT
c.plan_type,
ROUND(AVG(s.mrr), 2) AS avg_mrr,
ROUND(AVG(DATEDIFF(s.end_date, s.start_date)) / 30, 1) AS avg_months,
ROUND(AVG(s.mrr) * AVG(DATEDIFF(s.end_date, s.start_date) / 30), 2) AS avg_ltv
FROM crm_customers c
JOIN crm_subscriptions s ON c.customer_id = s.customer_id
GROUP BY c.plan_type
ORDER BY avg_ltv DESC;

-- SECTION 4 : CHURN ANALYSIS
-- Query 14 : Overall Churn Rate
select 
count(distinct customer_id) as Total_Users,
count(distinct case when status = 'Churned'then customer_id else 0 end ) as Churned_users,
round(count(distinct case when status = 'Churned'then customer_id else 0 end )*100/count(distinct customer_id),2) as Churn_rate
from crm_subscriptions;


-- Query 15 : Churn by Industry (CTE)


WITH churn_data AS (
    SELECT
    c.industry,
    s.customer_id,
    s.status
    FROM crm_customers c
    JOIN crm_subscriptions s ON c.customer_id = s.customer_id
)
SELECT
industry,
COUNT(DISTINCT customer_id) AS total_customers,
SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END) AS churned,
ROUND(SUM(CASE WHEN status = 'Churned' THEN 1 ELSE 0 END)
      * 100.0 / COUNT(*), 2) AS churn_rate
FROM churn_data
GROUP BY 1
ORDER BY 4 DESC;

-- Query 16 : MRR Lost to Churn

SELECT
DATE_FORMAT(end_date, '%Y-%m') AS churn_month,
COUNT(DISTINCT customer_id) AS churned_customers,
ROUND(SUM(mrr), 2) AS mrr_lost
FROM crm_subscriptions
WHERE status = 'Churned'
GROUP BY 1
ORDER BY 1;

-- SECTION 5 : GROWTH ANALYTICS

-- Query 17 : New MRR by Month
SELECT
DATE_FORMAT(start_date, '%Y-%m') AS month,
COUNT(DISTINCT customer_id) AS new_customers,
ROUND(SUM(mrr), 2) AS new_mrr
FROM crm_subscriptions
GROUP BY 1
ORDER BY 3 desc;

-- Query 18 : Upgrade Rate
select
count(distinct customer_id) as Total_users,
count(distinct case when status = 'upgraded' then customer_id end) as Upgrade_person,
round(sum(case when status = 'upgraded' then 1 else 0 end)*100/count(distinct customer_id),2) as Upgrade_rate
FROM crm_subscriptions;

-- Query 19 : Net Revenue Retention (NRR) (CTE)
-- PURPOSE  : Revenue retained including upgrades
--            NRR above 100% = expansion reven
WITH base_mrr AS (
    SELECT
    customer_id,
    SUM(mrr) AS starting_mrr
    FROM crm_subscriptions
    WHERE DATE_FORMAT(start_date, '%Y-%m') = '2022-01'
    GROUP BY customer_id
),
current_mrr AS (
    SELECT
    customer_id,
    SUM(mrr) AS ending_mrr
    FROM crm_subscriptions
    WHERE status = 'Active'
    GROUP BY customer_id
)
SELECT
ROUND(SUM(c.ending_mrr) * 100.0 / SUM(b.starting_mrr), 2) AS net_revenue_retention
FROM base_mrr b
JOIN current_mrr c ON b.customer_id = c.customer_id;



-- SECTION 6 : USAGE ANALYTICS (DAU/MAU)
-- -------------------------------------------------------
-- Query 20 : Average DAU and MAU
-- PURPOSE  : How many users actively use product daily
--            and monthly
-- INSIGHT  : Growing DAU/MAU = product engagement healthy
-- -------------------------------------------------------
SELECT
ROUND(AVG(dau), 0) AS avg_dau,
ROUND(AVG(mau), 0) AS avg_mau,
ROUND(AVG(dau), 0)/ROUND(AVG(mau), 0)*100 as st,
ROUND(AVG(stickiness), 2) AS avg_stickiness_percent
FROM crm_usage;

-- Query 21 : Stickiness by Plan Type (DAU/MAU ratio)

select 
c.plan_type,
ROUND(AVG(u.dau), 0) AS avg_dau,
ROUND(AVG(u.mau), 0) AS avg_mau,
ROUND(AVG(u.dau), 0)/ROUND(AVG(u.mau), 2)*100 AS avg_stickiness_percent
from crm_customers c join crm_usage u on u.customer_id = c.customer_id
group by 1;


SELECT
c.plan_type,
ROUND(AVG(u.dau), 0) AS avg_dau,
ROUND(AVG(u.mau), 0) AS avg_mau,
ROUND(AVG(u.stickiness), 2) AS avg_stickiness
FROM crm_customers c
JOIN crm_usage u ON c.customer_id = u.customer_id
GROUP BY c.plan_type
ORDER BY avg_stickiness DESC;

-- Query 22 : Feature Adoption Rate

select 
* from crm_usage;

SELECT
c.plan_type,
ROUND(AVG(u.features_used), 1) AS avg_features_used,
ROUND(AVG(u.login_count), 0) AS avg_logins
FROM crm_customers c
JOIN crm_usage u ON c.customer_id = u.customer_id
GROUP BY c.plan_type
ORDER BY avg_features_used DESC;

-- Query 23 : Support Ticket Analysis
select
c.plan_type,
c.company_size,
avg(u.support_tickets) as Avg_tickets_support,
ROUND(AVG(u.nps_score), 1) AS avg_nps_score
FROM crm_customers c
JOIN crm_usage u ON c.customer_id = u.customer_id
group by 1,2
order by 3 desc;


-- SECTION 7 : WINDOW FUNCTIONS
-- Query 24 : Customer MRR Ranking
select
plan_type
customer_id,
mrr,
rank() over (order by  mrr desc) as ranks,
dense_rank() over (order by  mrr desc) as dense_ranks,
row_number() over (order by  mrr desc) as num_ranks
from crm_subscriptions
where status = 'Active'
order by 3 desc
limit 10;
-- Query 25 : Top Customer Per Industry
WITH industry_ranking AS (
    SELECT
    c.customer_id,
    c.company_name,
    c.industry,
    c.plan_type,
    s.mrr,
    RANK() OVER(PARTITION BY c.industry
                ORDER BY s.mrr DESC) AS industry_rank
    FROM crm_customers c
    JOIN crm_subscriptions s ON c.customer_id = s.customer_id
    WHERE s.status = 'Active'
)
SELECT * FROM industry_ranking
WHERE industry_rank = 1
ORDER BY mrr DESC;


-- Query 26 : MRR Growth Month over Month (LAG)
WITH monthly_mrr AS (
    SELECT
    DATE_FORMAT(start_date, '%Y-%m') AS month,
    ROUND(SUM(mrr), 2) AS mrr
    FROM crm_subscriptions
    WHERE status = 'Active'
    GROUP BY 1
)
SELECT
month,
mrr,
LAG(mrr) OVER(ORDER BY month) AS prev_month_mrr,
ROUND((mrr - LAG(mrr) OVER(ORDER BY month))
      * 100.0 / LAG(mrr) OVER(ORDER BY month), 2) AS mom_growth
FROM monthly_mrr
ORDER BY month;


-- SECTION 8 : COHORT ANALYSIS
-- Query 27 : Monthly Signup Cohort
-- PURPOSE  : Track customer retention by signup month
WITH first_sub AS (
    SELECT
    customer_id,
    DATE_FORMAT(MIN(start_date), '%Y-%m') AS cohort_month
    FROM crm_subscriptions
    GROUP BY customer_id
),
cohort_activity AS (
    SELECT
    f.customer_id,
    f.cohort_month,
    PERIOD_DIFF(
        DATE_FORMAT(s.start_date, '%Y%m'),
        DATE_FORMAT(f.cohort_month, '%Y%m')
    ) AS month_number
    FROM first_sub f
    JOIN crm_subscriptions s ON f.customer_id = s.customer_id
)
SELECT
cohort_month,
COUNT(DISTINCT CASE WHEN month_number = 0 THEN customer_id END) AS month_0,
COUNT(DISTINCT CASE WHEN month_number = 1 THEN customer_id END) AS month_1,
COUNT(DISTINCT CASE WHEN month_number = 3 THEN customer_id END) AS month_3,
COUNT(DISTINCT CASE WHEN month_number = 6 THEN customer_id END) AS month_6,
COUNT(DISTINCT CASE WHEN month_number = 12 THEN customer_id END) AS month_12
FROM cohort_activity
GROUP BY cohort_month
ORDER BY cohort_month;


-- SECTION 9 : GEOGRAPHIC ANALYSIS
-- Query 28 : Top 10 Cities by MRR
SELECT
c.city,
COUNT(DISTINCT c.customer_id) AS customers,
ROUND(SUM(s.mrr), 2) AS total_mrr,
ROUND(AVG(s.mrr), 2) AS avg_mrr
FROM crm_customers c
JOIN crm_subscriptions s ON c.customer_id = s.customer_id
WHERE s.status = 'Active'
GROUP BY c.city
ORDER BY total_mrr DESC
LIMIT 10;



SELECT
DATE_FORMAT(start_date, '%Y-%m') AS month,
ROUND(SUM(mrr), 2) AS monthly_mrr,
ROUND(SUM(SUM(mrr)) OVER(ORDER BY DATE_FORMAT(start_date, '%Y-%m')), 2) AS cumulative_mrr
FROM crm_subscriptions
WHERE status = 'Active'
GROUP BY 1
ORDER BY 1;








