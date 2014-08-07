-- =============================================
-- Sample Data Generation for Media Entertainment Analytics
-- Comprehensive test data for content analytics, audience insights, and revenue optimization
-- =============================================

USE MediaEntertainmentDB;
GO

-- =============================================
-- Generate Sample Content Data
-- =============================================

-- Insert sample content
INSERT INTO Media.Content_Master (Title, ContentTypeID, GenreID, Description, Duration_Minutes, Release_Date, Production_Budget, Content_Rating, Language_Code, Country_Code, Director, Producer, Cast_List, Keywords)
VALUES 
-- Movies
('The Digital Revolution', 1, 5, 'A sci-fi thriller about AI taking over the world', 128, '2024-01-15', 50000000, 'PG-13', 'EN', 'US', 'Sarah Johnson', 'Michael Chen', 'Emma Stone, Ryan Gosling, Oscar Isaac', 'AI, technology, future, thriller'),
('Comedy Central Live', 1, 2, 'Stand-up comedy special featuring top comedians', 95, '2024-02-01', 5000000, 'R', 'EN', 'US', 'Dave Williams', 'Lisa Rodriguez', 'Kevin Hart, Amy Schumer, Dave Chappelle', 'comedy, stand-up, live, entertainment'),
('Ocean Mysteries', 1, 8, 'Documentary exploring deep sea creatures', 102, '2024-01-20', 8000000, 'G', 'EN', 'US', 'David Attenborough Jr.', 'National Geographic', 'David Attenborough Jr.', 'ocean, documentary, nature, marine life'),
('Love in Paris', 1, 7, 'Romantic drama set in modern-day Paris', 115, '2024-02-14', 25000000, 'PG-13', 'EN', 'FR', 'Claire Dubois', 'Pierre Martin', 'Margot Robbie, Timothée Chalamet', 'romance, Paris, love, drama'),
('Superhero Academy', 1, 1, 'Young heroes learn to control their powers', 142, '2024-03-01', 120000000, 'PG-13', 'EN', 'US', 'Russo Brothers', 'Marvel Studios', 'Tom Holland, Zendaya, Jacob Batalon', 'superhero, action, academy, powers'),

-- TV Series
('Tech Titans', 2, 3, 'Drama series about Silicon Valley entrepreneurs', 45, '2024-01-10', 2000000, 'TV-14', 'EN', 'US', 'Aaron Sorkin', 'HBO', 'Jesse Eisenberg, Rooney Mara', 'technology, business, drama, Silicon Valley'),
('Cooking Masters', 2, 15, 'Reality cooking competition show', 60, '2024-01-05', 500000, 'TV-G', 'EN', 'US', 'Gordon Ramsay', 'Fox Network', 'Gordon Ramsay, Christina Tosi', 'cooking, competition, reality, food'),
('Space Explorers', 2, 5, 'Sci-fi series about interstellar travel', 50, '2024-02-01', 5000000, 'TV-14', 'EN', 'US', 'J.J. Abrams', 'Netflix', 'John Boyega, Lupita Nyongo', 'space, sci-fi, exploration, future'),
('Crime Scene Investigation', 2, 3, 'Police procedural drama series', 42, '2024-01-15', 3000000, 'TV-14', 'EN', 'US', 'Dick Wolf', 'NBC', 'Mariska Hargitay, Ice-T', 'crime, police, investigation, drama'),
('Kids Adventure Club', 2, 14, 'Educational adventure series for children', 25, '2024-01-20', 1000000, 'TV-Y', 'EN', 'US', 'Sesame Workshop', 'PBS Kids', 'Various Child Actors', 'education, adventure, children, learning'),

-- Documentaries
('Climate Change Reality', 3, 8, 'In-depth look at global climate change', 90, '2024-01-25', 3000000, 'PG', 'EN', 'US', 'Al Gore Jr.', 'National Geographic', 'Various Scientists', 'climate, environment, documentary, science'),
('Music Legends', 3, 10, 'Documentary about iconic musicians', 105, '2024-02-10', 4000000, 'PG-13', 'EN', 'US', 'Martin Scorsese', 'Rolling Stone Films', 'Bob Dylan, Paul McCartney', 'music, biography, documentary, legends'),
('Ancient Civilizations', 3, 13, 'Educational series about historical civilizations', 55, '2024-01-30', 2000000, 'TV-G', 'EN', 'US', 'History Channel', 'A&E Networks', 'Various Historians', 'history, education, ancient, civilizations'),

-- Short Films
('Morning Coffee', 4, 7, 'Short romantic film about chance encounters', 12, '2024-02-05', 50000, 'PG', 'EN', 'US', 'Independent Director', 'Film School', 'Unknown Actors', 'romance, short, coffee, encounter'),
('Tech Support', 4, 2, 'Comedy short about IT helpdesk', 8, '2024-02-12', 25000, 'PG-13', 'EN', 'US', 'YouTube Creator', 'Independent', 'Comedy Actors', 'comedy, technology, support, workplace'),

-- Music Videos
('Pop Star Anthem', 5, 10, 'Latest hit from pop sensation', 4, '2024-02-20', 1000000, 'PG-13', 'EN', 'US', 'Music Video Director', 'Record Label', 'Taylor Swift', 'pop, music, anthem, hit'),
('Rock Revolution', 5, 10, 'Heavy metal music video', 5, '2024-02-18', 500000, 'PG-13', 'EN', 'US', 'Rock Director', 'Metal Records', 'Metallica', 'rock, metal, music, revolution');

-- =============================================
-- Generate Sample Platform Content Distribution
-- =============================================

-- Distribute content across platforms
INSERT INTO Media.Platform_Content (ContentID, PlatformTypeID, Platform_Content_ID, Availability_Start_Date, Availability_End_Date, Licensing_Cost, Revenue_Share_Percentage, Content_Quality, Is_Exclusive)
SELECT 
    cm.ContentID,
    pt.PlatformTypeID,
    CONCAT(pt.PlatformName, '_', cm.ContentID),
    DATEADD(DAY, -RAND() * 30, GETDATE()),
    DATEADD(DAY, RAND() * 365 + 30, GETDATE()),
    RAND() * 1000000,
    CASE 
        WHEN pt.PlatformName IN ('Netflix', 'Amazon Prime Video', 'Disney+') THEN RAND() * 30 + 70
        ELSE RAND() * 50 + 50
    END,
    CASE 
        WHEN RAND() > 0.7 THEN '4K'
        WHEN RAND() > 0.4 THEN 'HD'
        ELSE 'SD'
    END,
    CASE WHEN RAND() > 0.9 THEN 1 ELSE 0 END
FROM Media.Content_Master cm
CROSS JOIN REF.Platform_Types pt
WHERE pt.PlatformTypeID <= 10 -- Limit to first 10 platforms
  AND RAND() > 0.3; -- Randomly distribute content

-- =============================================
-- Generate Sample Audience Data
-- =============================================

-- Insert sample audience members
DECLARE @AudienceCount INT = 1000;
DECLARE @Counter INT = 1;

WHILE @Counter <= @AudienceCount
BEGIN
    INSERT INTO Media.Audience_Master (
        User_ID, PlatformTypeID, DemographicID, Registration_Date, 
        Subscription_Type, Subscription_Start_Date, Geographic_Location, 
        Device_Type, Preferred_Language
    )
    VALUES (
        CONCAT('USER_', RIGHT('000000' + CAST(@Counter AS VARCHAR), 6)),
        (ABS(CHECKSUM(NEWID())) % 10) + 1, -- Random platform
        (ABS(CHECKSUM(NEWID())) % 10) + 1, -- Random demographic
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 365, GETDATE()),
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Free'
            WHEN 1 THEN 'Basic'
            WHEN 2 THEN 'Standard'
            ELSE 'Premium'
        END,
        DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 180, GETDATE()),
        CASE ABS(CHECKSUM(NEWID())) % 5
            WHEN 0 THEN 'New York, NY'
            WHEN 1 THEN 'Los Angeles, CA'
            WHEN 2 THEN 'Chicago, IL'
            WHEN 3 THEN 'Houston, TX'
            ELSE 'Phoenix, AZ'
        END,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Mobile'
            WHEN 1 THEN 'Desktop'
            WHEN 2 THEN 'Tablet'
            ELSE 'Smart TV'
        END,
        'EN'
    );
    
    SET @Counter = @Counter + 1;
END;

-- =============================================
-- Generate Sample Content Consumption Data
-- =============================================

-- Generate viewing sessions
DECLARE @SessionCount INT = 10000;
SET @Counter = 1;

WHILE @Counter <= @SessionCount
BEGIN
    DECLARE @ContentID BIGINT = (SELECT TOP 1 ContentID FROM Media.Content_Master ORDER BY NEWID());
    DECLARE @AudienceID BIGINT = (SELECT TOP 1 AudienceID FROM Media.Audience_Master ORDER BY NEWID());
    DECLARE @PlatformID INT = (SELECT TOP 1 PlatformTypeID FROM Media.Audience_Master WHERE AudienceID = @AudienceID);
    DECLARE @SessionStart DATETIME2 = DATEADD(MINUTE, -ABS(CHECKSUM(NEWID())) % 43200, GETDATE()); -- Last 30 days
    DECLARE @WatchDuration INT = ABS(CHECKSUM(NEWID())) % 120 + 5; -- 5-125 minutes
    DECLARE @ContentDuration INT = (SELECT Duration_Minutes FROM Media.Content_Master WHERE ContentID = @ContentID);
    
    INSERT INTO Media.Content_Consumption (
        ContentID, AudienceID, PlatformTypeID, Session_Start_Time, Session_End_Time,
        Watch_Duration_Minutes, Completion_Percentage, Quality_Level, Device_Type,
        Geographic_Location, Bandwidth_Mbps, Buffer_Events, Skip_Events, Pause_Events,
        Rewind_Events, Fast_Forward_Events, User_Rating, Engagement_Score
    )
    VALUES (
        @ContentID,
        @AudienceID,
        @PlatformID,
        @SessionStart,
        DATEADD(MINUTE, @WatchDuration, @SessionStart),
        @WatchDuration,
        CASE 
            WHEN @ContentDuration > 0 THEN LEAST(100, (@WatchDuration * 100.0) / @ContentDuration)
            ELSE RAND() * 100
        END,
        CASE ABS(CHECKSUM(NEWID())) % 3
            WHEN 0 THEN 'HD'
            WHEN 1 THEN '4K'
            ELSE 'SD'
        END,
        CASE ABS(CHECKSUM(NEWID())) % 4
            WHEN 0 THEN 'Mobile'
            WHEN 1 THEN 'Desktop'
            WHEN 2 THEN 'Tablet'
            ELSE 'Smart TV'
        END,
        (SELECT Geographic_Location FROM Media.Audience_Master WHERE AudienceID = @AudienceID),
        RAND() * 100 + 10, -- 10-110 Mbps
        ABS(CHECKSUM(NEWID())) % 5, -- 0-4 buffer events
        ABS(CHECKSUM(NEWID())) % 3, -- 0-2 skip events
        ABS(CHECKSUM(NEWID())) % 8, -- 0-7 pause events
        ABS(CHECKSUM(NEWID())) % 3, -- 0-2 rewind events
        ABS(CHECKSUM(NEWID())) % 4, -- 0-3 fast forward events
        CASE 
            WHEN RAND() > 0.3 THEN RAND() * 4 + 1 -- 1-5 rating
            ELSE NULL
        END,
        RAND() * 100 -- 0-100 engagement score
    );
    
    SET @Counter = @Counter + 1;
END;

-- =============================================
-- Generate Sample Social Media Engagement Data
-- =============================================

-- Generate social media posts
INSERT INTO Media.Social_Media_Engagement (
    ContentID, Platform_Name, Post_ID, Engagement_Type, Engagement_Count,
    Sentiment_Score, Sentiment_Category, Influencer_Reach, Hashtags, Mentions, Engagement_Date
)
SELECT 
    cm.ContentID,
    CASE ABS(CHECKSUM(NEWID())) % 6
        WHEN 0 THEN 'Twitter'
        WHEN 1 THEN 'Facebook'
        WHEN 2 THEN 'Instagram'
        WHEN 3 THEN 'TikTok'
        WHEN 4 THEN 'YouTube'
        ELSE 'Reddit'
    END,
    CONCAT('POST_', ABS(CHECKSUM(NEWID()))),
    CASE ABS(CHECKSUM(NEWID())) % 5
        WHEN 0 THEN 'Like'
        WHEN 1 THEN 'Share'
        WHEN 2 THEN 'Comment'
        WHEN 3 THEN 'Mention'
        ELSE 'Hashtag'
    END,
    ABS(CHECKSUM(NEWID())) % 10000 + 1,
    (RAND() - 0.5) * 2, -- -1 to 1
    CASE 
        WHEN (RAND() - 0.5) * 2 > 0.2 THEN 'Positive'
        WHEN (RAND() - 0.5) * 2 < -0.2 THEN 'Negative'
        ELSE 'Neutral'
    END,
    CASE WHEN RAND() > 0.8 THEN ABS(CHECKSUM(NEWID())) % 100000 ELSE 0 END,
    CASE ABS(CHECKSUM(NEWID())) % 3
        WHEN 0 THEN '#trending #entertainment #mustwatch'
        WHEN 1 THEN '#movie #film #cinema #review'
        ELSE '#tv #series #binge #streaming'
    END,
    CASE WHEN RAND() > 0.7 THEN '@celebrity @director @producer' ELSE NULL END,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE())
FROM Media.Content_Master cm
CROSS JOIN (SELECT TOP 5 1 as dummy FROM sys.objects) t -- Generate 5 posts per content
WHERE RAND() > 0.2; -- 80% chance of social media presence

-- =============================================
-- Generate Sample Revenue Data
-- =============================================

-- Generate revenue records
INSERT INTO Media.Revenue_Analytics (
    ContentID, PlatformTypeID, Revenue_Date, Revenue_Type, Gross_Revenue,
    Net_Revenue, Platform_Fee, Marketing_Cost, Content_Cost, Subscriber_Count,
    Ad_Impressions, Ad_Clicks, Click_Through_Rate, Cost_Per_Click
)
SELECT 
    pc.ContentID,
    pc.PlatformTypeID,
    DATEADD(DAY, -ABS(CHECKSUM(NEWID())) % 30, GETDATE()),
    CASE ABS(CHECKSUM(NEWID())) % 4
        WHEN 0 THEN 'Subscription'
        WHEN 1 THEN 'Advertisement'
        WHEN 2 THEN 'Pay-Per-View'
        ELSE 'Licensing'
    END,
    RAND() * 100000 + 1000,
    RAND() * 80000 + 800,
    RAND() * 10000 + 100,
    RAND() * 20000 + 500,
    RAND() * 50000 + 1000,
    ABS(CHECKSUM(NEWID())) % 10000 + 100,
    ABS(CHECKSUM(NEWID())) % 1000000 + 1000,
    ABS(CHECKSUM(NEWID())) % 50000 + 100,
    RAND() * 5 + 0.5,
    RAND() * 2 + 0.1
FROM Media.Platform_Content pc
WHERE RAND() > 0.3; -- 70% of content has revenue data

-- =============================================
-- Calculate Initial Performance Metrics
-- =============================================

-- Execute the stored procedure to calculate performance metrics
EXEC Media.sp_CalculateContentPerformanceMetrics;

-- =============================================
-- Generate Sample Audience Segments
-- =============================================

-- Execute the stored procedure to generate audience segments
EXEC Media.sp_GenerateAudienceSegments;

-- =============================================
-- Generate Sample Content Recommendations
-- =============================================

-- Generate recommendations for first 100 audience members
DECLARE @AudienceCounter INT = 1;
DECLARE @MaxAudience INT = 100;

WHILE @AudienceCounter <= @MaxAudience
BEGIN
    EXEC Media.sp_GenerateContentRecommendations @AudienceID = @AudienceCounter, @TopN = 10;
    SET @AudienceCounter = @AudienceCounter + 1;
END;

-- =============================================
-- Data Summary Report
-- =============================================

PRINT 'Sample data generation completed successfully!';
PRINT '';
PRINT 'Data Summary:';
PRINT '=============';

SELECT 'Content Master' as TableName, COUNT(*) as RecordCount FROM Media.Content_Master
UNION ALL
SELECT 'Platform Content', COUNT(*) FROM Media.Platform_Content
UNION ALL
SELECT 'Audience Master', COUNT(*) FROM Media.Audience_Master
UNION ALL
SELECT 'Content Consumption', COUNT(*) FROM Media.Content_Consumption
UNION ALL
SELECT 'Social Media Engagement', COUNT(*) FROM Media.Social_Media_Engagement
UNION ALL
SELECT 'Revenue Analytics', COUNT(*) FROM Media.Revenue_Analytics
UNION ALL
SELECT 'Content Performance', COUNT(*) FROM Media.Content_Performance
UNION ALL
SELECT 'Audience Segments', COUNT(*) FROM Media.Audience_Segments
UNION ALL
SELECT 'Content Recommendations', COUNT(*) FROM Media.Content_Recommendations;

-- Sample analytics queries
PRINT '';
PRINT 'Sample Analytics Results:';
PRINT '========================';

-- Top performing content
SELECT TOP 5
    cm.Title,
    cp.Total_Views,
    cp.Average_Rating,
    cp.Engagement_Rate
FROM Media.Content_Master cm
INNER JOIN Media.Content_Performance cp ON cm.ContentID = cp.ContentID
ORDER BY cp.Total_Views DESC;

-- Audience engagement by demographic
SELECT 
    d.AgeGroup,
    d.Gender,
    COUNT(DISTINCT am.AudienceID) as AudienceCount,
    AVG(cc.Engagement_Score) as AvgEngagementScore
FROM Media.Audience_Master am
LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
GROUP BY d.AgeGroup, d.Gender
ORDER BY AvgEngagementScore DESC;

-- Revenue by platform
SELECT 
    pt.PlatformName,
    SUM(ra.Gross_Revenue) as TotalRevenue,
    COUNT(DISTINCT ra.ContentID) as ContentCount
FROM REF.Platform_Types pt
INNER JOIN Media.Revenue_Analytics ra ON pt.PlatformTypeID = ra.PlatformTypeID
GROUP BY pt.PlatformName
ORDER BY TotalRevenue DESC;

PRINT 'Sample data generation and analysis completed!';
GO