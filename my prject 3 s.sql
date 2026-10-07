-- Step 1: Create Database
CREATE DATABASE IF NOT EXISTS marketing_analytics;

-- Step 2: Set Active Context
USE marketing_analytics;

-- 3. Create Raw Staging Table (VARCHAR-only landing zone)
DROP TABLE IF EXISTS stg_marketing_campaigns;

CREATE TABLE stg_marketing_campaigns (
    raw_campaign_id VARCHAR(255),
    raw_campaign_name VARCHAR(255),
    raw_start_date VARCHAR(255),
    raw_end_date VARCHAR(255),
    raw_channel VARCHAR(255),
    raw_impressions VARCHAR(255),
    raw_clicks VARCHAR(255),
    raw_spend VARCHAR(255),
    raw_conversions VARCHAR(255),
    raw_is_active VARCHAR(255),
    raw_clicks_dup VARCHAR(255),
    raw_campaign_tag VARCHAR(255)
);


-- 4. load data
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/data Analysis/portfolio project 3/marketing_campaign_data_messy.csv'
INTO TABLE stg_marketing_campaigns
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 5. Create Production Table (Strict Data Types + Derived Attributes)
DROP TABLE IF EXISTS dim_marketing_campaigns;

CREATE TABLE dim_marketing_campaigns (
    campaign_id VARCHAR(255),
    campaign_name VARCHAR(255),
    quarter VARCHAR(50),
    campaign_type VARCHAR(100),
    start_date VARCHAR(255),
    end_date VARCHAR(255),
    channel VARCHAR(100),
    impressions VARCHAR(255),
    clicks VARCHAR(255),
    spend VARCHAR(255),
    conversions VARCHAR(255),
    is_active VARCHAR(100),
    campaign_tag VARCHAR(100),
    ctr_percent DECIMAL(5,2),
    cpc_amount DECIMAL(10,2)
);
-- 6. Raw copy into dim table
INSERT INTO dim_marketing_campaigns (
    campaign_id, campaign_name, start_date, end_date, 
    channel, impressions, clicks, spend, conversions, 
    is_active, campaign_tag
)
SELECT 
    raw_campaign_id, raw_campaign_name, raw_start_date, raw_end_date,
    raw_channel, raw_impressions, raw_clicks, raw_spend, raw_conversions,
    raw_is_active, raw_campaign_tag
FROM stg_marketing_campaigns
WHERE raw_campaign_id IS NOT NULL 
  AND raw_campaign_id != 'Campaign_ID';
#------------------------------------------------------------------------------------------------------------

-- Step 1: Whitespace Removal & NULL Standardization
UPDATE dim_marketing_campaigns
SET 
    campaign_id   = NULLIF(TRIM(campaign_id), ''),
    campaign_name = NULLIF(TRIM(campaign_name), ''),
    start_date    = NULLIF(TRIM(start_date), ''),
    end_date      = NULLIF(TRIM(end_date), ''),
    channel       = NULLIF(TRIM(channel), ''),
    impressions   = NULLIF(TRIM(impressions), ''),
    clicks        = NULLIF(TRIM(clicks), ''),
    spend         = NULLIF(TRIM(spend), ''),
    conversions   = NULLIF(TRIM(conversions), ''),
    is_active     = NULLIF(TRIM(is_active), ''),
    campaign_tag  = NULLIF(TRIM(campaign_tag), '');
    -- 0utput : 200 rows affected
    
-- Step 2: Duplicate Identification & Removal
SELECT 
    campaign_id, 
    COUNT(*) AS duplicate_count
FROM dim_marketing_campaigns
GROUP BY campaign_id
HAVING COUNT(*) > 1;

SELECT * 
FROM dim_marketing_campaigns 
WHERE campaign_id = 'CMP-00185';

-- delete duplicates
DELETE FROM dim_marketing_campaigns
WHERE campaign_id IN (
    SELECT campaign_id FROM (
        SELECT campaign_id,
               ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY campaign_id) AS row_num
        FROM dim_marketing_campaigns
    ) t
    WHERE t.row_num > 1
);
   
   SELECT 
    campaign_name, 
    quarter, 
    campaign_type 
FROM dim_marketing_campaigns 
LIMIT 10;

-- STEP 3:Standardize Channel Names
SELECT DISTINCT channel 
FROM dim_marketing_campaigns;

UPDATE dim_marketing_campaigns
SET channel = CASE 
    WHEN LOWER(channel) LIKE '%mail%' THEN 'Email'
    WHEN LOWER(channel) LIKE '%faceb%' THEN 'Facebook'
    WHEN LOWER(channel) LIKE '%gogl%' OR LOWER(channel) LIKE '%google%' THEN 'Google Ads'
    WHEN LOWER(channel) LIKE '%insta%' THEN 'Instagram'
    WHEN LOWER(channel) LIKE '%tik%' THEN 'TikTok'
    WHEN channel = 'N/A' THEN NULL
    ELSE TRIM(channel)
END;
# OUTPUT : 179 ROWS AFFECTED
SELECT DISTINCT channel FROM dim_marketing_campaigns;

-- Step 4: Clean start_date & end_date
UPDATE dim_marketing_campaigns
SET 
    start_date = CASE 
        WHEN start_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(start_date, '%d/%m/%Y'), '%Y-%m-%d')
        ELSE SUBSTRING(start_date, 1, 10)
    END,
    end_date = CASE 
        WHEN end_date LIKE '%/%' THEN DATE_FORMAT(STR_TO_DATE(end_date, '%d/%m/%Y'), '%Y-%m-%d')
        ELSE SUBSTRING(end_date, 1, 10)
    END;
    -- output 1832 rows affected
    select distinct start_date,end_date
    from dim_marketing_campaigns;
    
 -- Step 5: Clean spend column values
SELECT DISTINCT spend 
FROM dim_marketing_campaigns 
LIMIT 10;
 
UPDATE dim_marketing_campaigns
SET spend = TRIM(REPLACE(spend, '$', ''))
WHERE spend IS NOT NULL;
   
SELECT DISTINCT spend 
FROM dim_marketing_campaigns 
LIMIT 10;  

 -- Step 6: Clean conversions column values

UPDATE dim_marketing_campaigns
SET conversions = NULL
WHERE conversions IS NULL 
   OR TRIM(conversions) = ''
   OR conversions = 'null';

 -- Step 7: Clean is_active column values
 SELECT 
    DISTINCT is_active 
FROM dim_marketing_campaigns 
LIMIT 20;

UPDATE dim_marketing_campaigns
SET is_active = CASE 
    WHEN LOWER(TRIM(is_active)) IN ('y', 'yes', 'true', '1') THEN 'Yes'
    WHEN LOWER(TRIM(is_active)) IN ('n', 'no', 'false', '0') THEN 'No'
    ELSE NULL
END;

 -- Step 8: Clean compaign_tag column values
SELECT DISTINCT campaign_tag 
FROM dim_marketing_campaigns;

SELECT 
    channel, 
    campaign_tag, 
    COUNT(*) AS row_count
FROM dim_marketing_campaigns
GROUP BY channel, campaign_tag
ORDER BY channel, row_count DESC;


UPDATE dim_marketing_campaigns
SET campaign_tag = CASE 
    WHEN channel = 'Email' THEN 'EM'
    WHEN channel = 'Facebook' THEN 'FA'
    WHEN channel = 'Google Ads' THEN 'GO'
    WHEN channel = 'Instagram' THEN 'IN'
    WHEN channel = 'TikTok' THEN 'TI'
    ELSE NULL
END;

 -- Step 9: fix data types
ALTER TABLE dim_marketing_campaigns
    MODIFY COLUMN spend DECIMAL(10,2),
    MODIFY COLUMN impressions INT,
    MODIFY COLUMN clicks INT,
    MODIFY COLUMN conversions INT,
    MODIFY COLUMN is_active ENUM('Yes', 'No');
    
    DESCRIBE dim_marketing_campaigns;
    
 -- Step 10:   Dates Standardization
 SELECT start_date, end_date 
FROM dim_marketing_campaigns 
LIMIT 10;

ALTER TABLE dim_marketing_campaigns
    MODIFY COLUMN start_date DATE,
    MODIFY COLUMN end_date DATE;
    
    #------------------------------------------data cleaning done------------------------------------------
    #------------------------------------------------EDA---------------------------------------------------
 
 -- STEP 1:  Overall Performance & Summary Statistics 
 SELECT 
    COUNT(DISTINCT campaign_id) AS total_campaigns,
    SUM(spend) AS total_spend,
    SUM(impressions) AS total_impressions,
    SUM(clicks) AS total_clicks,
    SUM(conversions) AS total_conversions,
    ROUND((SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100, 2) AS overall_ctr_percent,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS overall_cpc,
    ROUND(SUM(spend) / NULLIF(SUM(conversions), 0), 2) AS overall_cost_per_conversion
FROM dim_marketing_campaigns;
/*OUTPUT:total_campaigns   total_spend     total_impressions     total_clicks    total_conversions
		  1980	            6179454.28	    98723516			2973447	      331450	         
         overall_ctr_percent    overall_cpc     overall_cost_per_conversion
           3.01	                 2.08	         18.64*/
    
-- Step 2: Channel-Wise Performance Analysis

SELECT 
    channel,
    COUNT(campaign_id) AS total_campaigns,
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    ROUND((SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100, 2) AS ctr_percent,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS avg_cpc,
    ROUND(SUM(spend) / NULLIF(SUM(conversions), 0), 2) AS cost_per_conversion
FROM dim_marketing_campaigns
GROUP BY channel
ORDER BY total_conversions DESC;

-- Step 3: Active vs Inactive Campaigns Performance
SELECT 
    channel,
    is_active,
    COUNT(campaign_id) AS total_campaigns,
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    ROUND(SUM(spend) / NULLIF(SUM(conversions), 0), 2) AS cost_per_conversion
FROM dim_marketing_campaigns
GROUP BY channel, is_active
ORDER BY channel, is_active;

-- STEP 3:  analyze campaign performance based on active duration in days

SELECT 
    CASE 
        WHEN DATEDIFF(end_date, start_date) < 7 THEN '1. Short-term (< 1 Week)'
        WHEN DATEDIFF(end_date, start_date) BETWEEN 7 AND 14 THEN '2. Medium-term (1-2 Weeks)'
        WHEN DATEDIFF(end_date, start_date) BETWEEN 15 AND 30 THEN '3. Standard (15-30 Days)'
        ELSE '4. Long-term (> 30 Days)'
    END AS duration_bracket,
    COUNT(campaign_id) AS total_campaigns,
    SUM(spend) AS total_spend,
    SUM(conversions) AS total_conversions,
    ROUND((SUM(clicks) / NULLIF(SUM(impressions), 0)) * 100, 2) AS avg_ctr_percent,
    ROUND(SUM(spend) / NULLIF(SUM(clicks), 0), 2) AS avg_cpc,
    ROUND(SUM(spend) / NULLIF(SUM(conversions), 0), 2) AS cost_per_conversion
FROM dim_marketing_campaigns
WHERE start_date IS NOT NULL AND end_date IS NOT NULL
GROUP BY duration_bracket
ORDER BY duration_bracket;