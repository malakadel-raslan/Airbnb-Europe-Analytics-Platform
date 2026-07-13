USE AirbnbDWH;
GO

-- ============================================================================
IF OBJECT_ID('gold.fact_listing', 'U') IS NOT NULL DROP TABLE gold.fact_listing;
IF OBJECT_ID('gold.dim_city', 'U') IS NOT NULL DROP TABLE gold.dim_city;
IF OBJECT_ID('gold.dim_room_type', 'U') IS NOT NULL DROP TABLE gold.dim_room_type;
IF OBJECT_ID('gold.dim_host', 'U') IS NOT NULL DROP TABLE gold.dim_host;
IF OBJECT_ID('gold.dim_day_type', 'U') IS NOT NULL DROP TABLE gold.dim_day_type;
IF OBJECT_ID('gold.dim_amenities', 'U') IS NOT NULL DROP TABLE gold.dim_amenities;
GO

-- ============================================================================
-- dim_city 
-- ============================================================================
CREATE TABLE gold.dim_city (
    city_key INT IDENTITY(1,1) PRIMARY KEY,
    city NVARCHAR(100) UNIQUE,
    country NVARCHAR(100),
    region NVARCHAR(100),
    sub_region NVARCHAR(100),
    population NVARCHAR(100),
    area_km2 NVARCHAR(100),
    annual_tourists NVARCHAR(100),
    currency NVARCHAR(50),
    language NVARCHAR(100),
    majority_religion NVARCHAR(100),
    famous_foods NVARCHAR(MAX),
    cost_of_living NVARCHAR(100),
    cost_score FLOAT,
    safety NVARCHAR(100),
    safety_index FLOAT,
    crime_index FLOAT,
    tourism_season NVARCHAR(100),
    best_months NVARCHAR(400),
    cultural_significance NVARCHAR(MAX),
    city_description NVARCHAR(MAX),
    city_avg_rating FLOAT,
    city_avg_price FLOAT,
    city_popularity FLOAT
);
GO

INSERT INTO gold.dim_city (
    city, country, region, sub_region, population, area_km2, annual_tourists,
    currency, language, majority_religion, famous_foods, cost_of_living,
    cost_score, safety, safety_index, crime_index, tourism_season, best_months,
    cultural_significance, city_description, city_avg_rating, city_avg_price, city_popularity
)
SELECT
    city, MAX(Country), MAX(region), MAX(sub_region),
    MAX(CAST(Population AS NVARCHAR(100))),
    MAX(CAST([Area in km2 ] AS NVARCHAR(100))),
    MAX(CAST([Approximate Annual Tourists] AS NVARCHAR(100))),
    MAX(Currency), MAX(Language), MAX([Majority Religion]), MAX([Famous Foods]),
    MAX(CAST([Cost of Living] AS NVARCHAR(100))),
    MAX(TRY_CAST(cost_score AS FLOAT)),
    MAX(Safety), MAX(TRY_CAST(Safety_Index AS FLOAT)), MAX(TRY_CAST(Crime_Index AS FLOAT)),
    MAX(Tourism_Season), MAX(Best_Months),
    MAX([Cultural Significance]), MAX(Description),
    MAX(TRY_CAST(city_avg_rating AS FLOAT)),
    MAX(TRY_CAST(city_avg_price AS FLOAT)),
    MAX(TRY_CAST(city_popularity AS FLOAT))
FROM dbo.silver_airbnb_master
WHERE city IS NOT NULL
GROUP BY city;
GO

-- ============================================================================
-- dim_room_type 
-- ============================================================================
CREATE TABLE gold.dim_room_type (
    room_type_key INT IDENTITY(1,1) PRIMARY KEY,
    room_type NVARCHAR(100),
    room_shared NVARCHAR(10),
    room_private NVARCHAR(10),
    property_type NVARCHAR(100),      -- 🔧 مُضاف
    person_capacity INT,
    accommodates INT,                 -- 🔧 مُضاف
    bedrooms FLOAT,
    bathrooms FLOAT,
    beds FLOAT
);
GO

INSERT INTO gold.dim_room_type (
    room_type, room_shared, room_private, property_type,
    person_capacity, accommodates, bedrooms, bathrooms, beds
)
SELECT DISTINCT
    room_type, room_shared, room_private, property_type,
    TRY_CAST(person_capacity AS INT),
    TRY_CAST(accommodates AS INT),
    TRY_CAST(bedrooms AS FLOAT),
    TRY_CAST(bathrooms AS FLOAT),
    TRY_CAST(beds AS FLOAT)
FROM dbo.silver_airbnb_master;
GO

-- ============================================================================
-- dim_host ( multi, biz)
-- ============================================================================
CREATE TABLE gold.dim_host (
    host_key INT IDENTITY(1,1) PRIMARY KEY,
    host_is_superhost BIT,
    host_identity_verified BIT,
    host_total_listings_count INT,
    multi BIGINT,          
    biz BIGINT              
);
GO

INSERT INTO gold.dim_host (
    host_is_superhost, host_identity_verified, host_total_listings_count, multi, biz
)
SELECT DISTINCT
    CASE WHEN LOWER(CAST(host_is_superhost AS VARCHAR(10))) = 't' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
    CASE WHEN LOWER(CAST(host_identity_verified AS VARCHAR(10))) = 't' THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END,
    TRY_CAST(host_total_listings_count AS INT),
    TRY_CAST(multi AS BIGINT),
    TRY_CAST(biz AS BIGINT)
FROM dbo.silver_airbnb_master;
GO

-- ============================================================================
-- dim_day_type 
-- ============================================================================
CREATE TABLE gold.dim_day_type (
    day_type_key INT IDENTITY(1,1) PRIMARY KEY,
    day_type NVARCHAR(20)
);
GO

INSERT INTO gold.dim_day_type (day_type)
SELECT DISTINCT day_type
FROM dbo.silver_airbnb_master
WHERE day_type IS NOT NULL;
GO

-- ============================================================================
-- dim_amenities 
-- ============================================================================
CREATE TABLE gold.dim_amenities (
    amenities_key INT IDENTITY(1,1) PRIMARY KEY,
    amenities NVARCHAR(MAX),
    amenities_count FLOAT,
    wifi BIT,
    parking BIT,
    kitchen BIT,
    air_conditioning BIT
);
GO

INSERT INTO gold.dim_amenities (amenities, amenities_count, wifi, parking, kitchen, air_conditioning)
SELECT DISTINCT
    amenities,
    TRY_CAST(amenities_count AS FLOAT),
    TRY_CAST(wifi AS BIT),
    TRY_CAST(parking AS BIT),
    TRY_CAST(kitchen AS BIT),
    TRY_CAST(air_conditioning AS BIT)
FROM dbo.silver_airbnb_master;
GO

-- ============================================================================
-- fact_listing ( day_type_key, amenities_key + POI + lat/lng/year)
-- ============================================================================
CREATE TABLE gold.fact_listing (
    listing_key INT IDENTITY(1,1) PRIMARY KEY,

    city_key INT,
    room_type_key INT,
    host_key INT,
    day_type_key INT,       
    amenities_key INT,       

    price FLOAT,
    cleanliness_rating FLOAT,
    guest_satisfaction_overall FLOAT,

    review_scores_rating FLOAT,
    review_scores_location FLOAT,
    review_scores_cleanliness FLOAT,

    number_of_reviews INT,
    reviews_per_month FLOAT,

    dist FLOAT,
    metro_dist FLOAT,

    attr_index FLOAT,
    attr_index_norm FLOAT,   
    rest_index FLOAT,
    rest_index_norm FLOAT,   

    amenities_score FLOAT,
    rating_score FLOAT,
    location_score FLOAT,

    availability_365 INT,

    lat FLOAT,                
    lng FLOAT,                
    year INT,                 
    price_vs_cost_of_living FLOAT,  

    attraction_count INT,
    nearest_attraction_km FLOAT,
    nearest_attraction_name NVARCHAR(200),

    restaurant_count INT,
    nearest_restaurant_km FLOAT,
    nearest_restaurant_name NVARCHAR(200),

    cafe_count INT,
    nearest_cafe_km FLOAT,
    nearest_cafe_name NVARCHAR(200),

    hotel_count INT,
    nearest_hotel_km FLOAT,
    nearest_hotel_name NVARCHAR(200),

    park_count INT,
    nearest_park_km FLOAT,
    nearest_park_name NVARCHAR(200),

    hospital_count INT,
    nearest_hospital_km FLOAT,
    nearest_hospital_name NVARCHAR(200),

    airport_count INT,
    nearest_airport_km FLOAT,
    nearest_airport_name NVARCHAR(200)
);
GO

INSERT INTO gold.fact_listing (
    city_key, room_type_key, host_key, day_type_key, amenities_key,
    price, cleanliness_rating, guest_satisfaction_overall,
    review_scores_rating, review_scores_location, review_scores_cleanliness,
    number_of_reviews, reviews_per_month, dist, metro_dist,
    attr_index, attr_index_norm, rest_index, rest_index_norm,
    amenities_score, rating_score, location_score, availability_365,
    lat, lng, year, price_vs_cost_of_living,
    attraction_count, nearest_attraction_km, nearest_attraction_name,
    restaurant_count, nearest_restaurant_km, nearest_restaurant_name,
    cafe_count, nearest_cafe_km, nearest_cafe_name,
    hotel_count, nearest_hotel_km, nearest_hotel_name,
    park_count, nearest_park_km, nearest_park_name,
    hospital_count, nearest_hospital_km, nearest_hospital_name,
    airport_count, nearest_airport_km, nearest_airport_name
)
SELECT
    dc.city_key, dr.room_type_key, dh.host_key, ddt.day_type_key, da.amenities_key,

    TRY_CAST(s.realSum AS FLOAT),
    TRY_CAST(s.cleanliness_rating AS FLOAT),
    TRY_CAST(s.guest_satisfaction_overall AS FLOAT),
    TRY_CAST(s.review_scores_rating AS FLOAT),
    TRY_CAST(s.review_scores_location AS FLOAT),
    TRY_CAST(s.review_scores_cleanliness AS FLOAT),
    TRY_CAST(s.number_of_reviews AS INT),
    TRY_CAST(s.reviews_per_month AS FLOAT),
    TRY_CAST(s.dist AS FLOAT),
    TRY_CAST(s.metro_dist AS FLOAT),
    TRY_CAST(s.attr_index AS FLOAT),
    TRY_CAST(s.attr_index_norm AS FLOAT),
    TRY_CAST(s.rest_index AS FLOAT),
    TRY_CAST(s.rest_index_norm AS FLOAT),
    TRY_CAST(s.amenities_score AS FLOAT),
    TRY_CAST(s.rating_score AS FLOAT),
    TRY_CAST(s.location_score AS FLOAT),
    TRY_CAST(s.availability_365 AS INT),
    TRY_CAST(s.lat AS FLOAT),
    TRY_CAST(s.lng AS FLOAT),
    TRY_CAST(s.year AS INT),
    TRY_CAST(s.price_vs_cost_of_living AS FLOAT),

    TRY_CAST(s.attraction_count AS INT), TRY_CAST(s.nearest_attraction_km AS FLOAT), s.nearest_attraction_name,
    TRY_CAST(s.restaurant_count AS INT), TRY_CAST(s.nearest_restaurant_km AS FLOAT), s.nearest_restaurant_name,
    TRY_CAST(s.cafe_count AS INT), TRY_CAST(s.nearest_cafe_km AS FLOAT), s.nearest_cafe_name,
    TRY_CAST(s.hotel_count AS INT), TRY_CAST(s.nearest_hotel_km AS FLOAT), s.nearest_hotel_name,
    TRY_CAST(s.park_count AS INT), TRY_CAST(s.nearest_park_km AS FLOAT), s.nearest_park_name,
    TRY_CAST(s.hospital_count AS INT), TRY_CAST(s.nearest_hospital_km AS FLOAT), s.nearest_hospital_name,
    TRY_CAST(s.airport_count AS INT), TRY_CAST(s.nearest_airport_km AS FLOAT), s.nearest_airport_name

FROM dbo.silver_airbnb_master s

LEFT JOIN gold.dim_city dc
    ON s.city = dc.city

LEFT JOIN gold.dim_room_type dr
    ON ISNULL(s.room_type,'') = ISNULL(dr.room_type,'')
   AND ISNULL(s.property_type,'') = ISNULL(dr.property_type,'')
   AND ISNULL(TRY_CAST(s.person_capacity AS INT),-1) = ISNULL(dr.person_capacity,-1)
   AND ISNULL(TRY_CAST(s.accommodates AS INT),-1) = ISNULL(dr.accommodates,-1)
   AND ISNULL(TRY_CAST(s.bedrooms AS FLOAT),-1) = ISNULL(dr.bedrooms,-1)
   AND ISNULL(TRY_CAST(s.bathrooms AS FLOAT),-1) = ISNULL(dr.bathrooms,-1)
   AND ISNULL(TRY_CAST(s.beds AS FLOAT),-1) = ISNULL(dr.beds,-1)

LEFT JOIN gold.dim_host dh
    ON ISNULL(TRY_CAST(s.host_total_listings_count AS INT),-1) = ISNULL(dh.host_total_listings_count,-1)
   AND ISNULL(TRY_CAST(s.multi AS BIGINT),-1) = ISNULL(dh.multi,-1)
   AND ISNULL(TRY_CAST(s.biz AS BIGINT),-1) = ISNULL(dh.biz,-1)

LEFT JOIN gold.dim_day_type ddt
    ON s.day_type = ddt.day_type

LEFT JOIN gold.dim_amenities da
    ON ISNULL(s.amenities,'') = ISNULL(da.amenities,'')
   AND ISNULL(TRY_CAST(s.amenities_count AS FLOAT),-1) = ISNULL(da.amenities_count,-1);
GO

-- ============================================================================
-- Foreign Keys
-- ============================================================================
ALTER TABLE gold.fact_listing ADD CONSTRAINT FK_fact_city FOREIGN KEY (city_key) REFERENCES gold.dim_city(city_key);
ALTER TABLE gold.fact_listing ADD CONSTRAINT FK_fact_room_type FOREIGN KEY (room_type_key) REFERENCES gold.dim_room_type(room_type_key);
ALTER TABLE gold.fact_listing ADD CONSTRAINT FK_fact_host FOREIGN KEY (host_key) REFERENCES gold.dim_host(host_key);
ALTER TABLE gold.fact_listing ADD CONSTRAINT FK_fact_day_type FOREIGN KEY (day_type_key) REFERENCES gold.dim_day_type(day_type_key);
ALTER TABLE gold.fact_listing ADD CONSTRAINT FK_fact_amenities FOREIGN KEY (amenities_key) REFERENCES gold.dim_amenities(amenities_key);
GO

-- ============================================================================
-- final Check
-- ============================================================================
SELECT
    (SELECT COUNT(*) FROM dbo.silver_airbnb_master) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_listing) AS fact_rows,
    (SELECT COUNT(*) FROM gold.fact_listing WHERE city_key IS NULL) AS null_city,
    (SELECT COUNT(*) FROM gold.fact_listing WHERE room_type_key IS NULL) AS null_room_type,
    (SELECT COUNT(*) FROM gold.fact_listing WHERE host_key IS NULL) AS null_host,
    (SELECT COUNT(*) FROM gold.fact_listing WHERE day_type_key IS NULL) AS null_day_type,
    (SELECT COUNT(*) FROM gold.fact_listing WHERE amenities_key IS NULL) AS null_amenities;
GO

-- ==================================================================================================
-- 
DROP VIEW IF EXISTS dbo.vw_airbnb_summary;
GO
-- Grain: one row per listing. Feeds map, avg satisfaction/price by city,
-- room type distribution, and the top KPI cards.
-- ============================================================================

CREATE VIEW gold.vw_market_overview AS
SELECT
    f.listing_key,
    dc.city,
    dc.country,
    dr.room_type,
    dr.property_type,
    dr.person_capacity,
    dh.host_is_superhost,
    ddt.day_type,
    f.price,
    f.review_scores_rating          AS guest_satisfaction,
    f.lat,
    f.lng,
    f.availability_365
FROM gold.fact_listing f
LEFT JOIN gold.dim_city dc      ON f.city_key = dc.city_key
LEFT JOIN gold.dim_room_type dr ON f.room_type_key = dr.room_type_key
LEFT JOIN gold.dim_host dh      ON f.host_key = dh.host_key
LEFT JOIN gold.dim_day_type ddt ON f.day_type_key = ddt.day_type_key;
GO

-- ============================================================================
-- PAGE 2 — Compare European Destinations
-- Grain: one row per city. Pre-aggregated so Value Score / rankings
-- don't need to be recomputed as measures over the full fact grain.
-- ============================================================================
CREATE VIEW gold.vw_compare_destinations AS
SELECT
    dc.city,
    dc.country,
    COUNT(f.listing_key)                                   AS listings_count,
    AVG(f.price)                                            AS avg_price,
    AVG(f.review_scores_rating)                             AS avg_satisfaction,
    AVG(CASE WHEN dh.host_is_superhost = 1 THEN 1.0 ELSE 0.0 END) AS superhost_rate,
    dc.safety_index,
    dc.crime_index,
    -- Value Score: higher satisfaction & safety, lower price => higher score
    ( AVG(f.review_scores_rating) * 10
      + ISNULL(dc.safety_index, 0)
      - (AVG(f.price) / 10.0)
    )                                                        AS value_score
FROM gold.fact_listing f
LEFT JOIN gold.dim_city dc ON f.city_key = dc.city_key
LEFT JOIN gold.dim_host dh ON f.host_key = dh.host_key
GROUP BY dc.city, dc.country, dc.safety_index, dc.crime_index;
GO

-- ============================================================================
-- PAGE 3 — Safety & Lifestyle
-- Grain: one row per city. Combines dim_city safety/cost fields with
-- amenity availability rolled up from dim_amenities via the fact table.
-- ============================================================================
CREATE VIEW gold.vw_safety_lifestyle AS
SELECT
    dc.city,
    dc.country,
    dc.safety,
    dc.safety_index,
    dc.crime_index,
    dc.cost_of_living,
    dc.cost_score,
    dc.tourism_season,
    dc.best_months,
    AVG(f.price_vs_cost_of_living)                         AS avg_price_vs_cost_of_living,
    AVG(CASE WHEN da.wifi = 1 THEN 1.0 ELSE 0.0 END)             AS pct_wifi,
    AVG(CASE WHEN da.parking = 1 THEN 1.0 ELSE 0.0 END)          AS pct_parking,
    AVG(CASE WHEN da.kitchen = 1 THEN 1.0 ELSE 0.0 END)          AS pct_kitchen,
    AVG(CASE WHEN da.air_conditioning = 1 THEN 1.0 ELSE 0.0 END) AS pct_ac,
    AVG(da.amenities_count)                                 AS avg_amenities_count,
    CASE
        WHEN dc.crime_index < 40 THEN 'Safe'
        WHEN dc.crime_index < 55 THEN 'Moderate'
        ELSE 'High Risk'
    END                                                      AS safety_status
FROM gold.fact_listing f
LEFT JOIN gold.dim_city dc      ON f.city_key = dc.city_key
LEFT JOIN gold.dim_amenities da ON f.amenities_key = da.amenities_key
GROUP BY dc.city, dc.country, dc.safety, dc.safety_index, dc.crime_index,
         dc.cost_of_living, dc.cost_score, dc.tourism_season, dc.best_months;
GO

-- ============================================================================
-- PAGE 4 — Find Your Perfect Stay
-- Grain: one row per listing. Feeds Key Influencers, superhost impact,
-- amenities analysis, room type satisfaction, and the perfect-stay score.
-- ============================================================================
CREATE VIEW gold.vw_perfect_stay AS
SELECT
    f.listing_key,
    dc.city,
    dr.room_type,
    dr.property_type,
    dr.person_capacity,
    dh.host_is_superhost,
    f.cleanliness_rating,
    f.review_scores_rating,
    f.review_scores_location,
    f.review_scores_cleanliness,
    f.guest_satisfaction_overall,
    f.amenities_score,
    da.amenities_count,
    f.price,
    -- Perfect Stay Score: weighted composite of the four quality signals
    ( ISNULL(f.cleanliness_rating, 0)       * 0.25
    + ISNULL(f.review_scores_rating, 0)     * 0.35
    + ISNULL(f.review_scores_location, 0)   * 0.20
    + ISNULL(f.amenities_score, 0) * 100    * 0.20
    )                                                        AS perfect_stay_score
FROM gold.fact_listing f
LEFT JOIN gold.dim_city dc      ON f.city_key = dc.city_key
LEFT JOIN gold.dim_room_type dr ON f.room_type_key = dr.room_type_key
LEFT JOIN gold.dim_host dh      ON f.host_key = dh.host_key
LEFT JOIN gold.dim_amenities da ON f.amenities_key = da.amenities_key;
GO

-- ============================================================================
-- PAGE 5 — Smart Recommendation
-- Grain: one row per city. Combines compare + safety_lifestyle logic into
-- a single Overall Score so this page produces a genuinely different
-- "winner" than the raw Value Score used on Page 2.
-- ============================================================================
CREATE VIEW gold.vw_recommendation AS
SELECT
    cmp.city,
    cmp.country,
    cmp.avg_price,
    cmp.avg_satisfaction,
    cmp.superhost_rate,
    cmp.value_score,
    dc.safety_index,
    dc.crime_index,
    dc.cost_of_living,
    -- Overall Score = weighted blend of satisfaction, safety, and value
    ( (cmp.avg_satisfaction / 100.0)          * 0.4
    + (ISNULL(dc.safety_index, 0) / 100.0)    * 0.3
    + (cmp.value_score / NULLIF((SELECT MAX(value_score) FROM gold.vw_compare_destinations), 0)) * 0.3
    ) * 100                                                   AS overall_score
FROM gold.vw_compare_destinations cmp
LEFT JOIN gold.dim_city dc ON cmp.city = dc.city;
GO

-- ============================================================================
-- Sanity check — row counts per view
-- ============================================================================
SELECT 'vw_market_overview'      AS view_name, COUNT(*) AS row_count FROM gold.vw_market_overview
UNION ALL
SELECT 'vw_compare_destinations', COUNT(*) FROM gold.vw_compare_destinations
UNION ALL
SELECT 'vw_safety_lifestyle',     COUNT(*) FROM gold.vw_safety_lifestyle
UNION ALL
SELECT 'vw_perfect_stay',         COUNT(*) FROM gold.vw_perfect_stay
UNION ALL
SELECT 'vw_recommendation',       COUNT(*) FROM gold.vw_recommendation;
GO

