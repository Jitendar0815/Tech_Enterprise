-- =============================================
-- Media Entertainment Analytics Database Creation Script
-- Comprehensive database schema for content analytics, audience measurement, and revenue optimization
-- =============================================

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MediaEntertainmentDB')
BEGIN
    CREATE DATABASE MediaEntertainmentDB
    ON (
        NAME = 'MediaEntertainmentDB_Data',
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\MediaEntertainmentDB.mdf',
        SIZE = 1GB,
        MAXSIZE = 100GB,
        FILEGROWTH = 100MB
    )
    LOG ON (
        NAME = 'MediaEntertainmentDB_Log',
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\MediaEntertainmentDB.ldf',
        SIZE = 100MB,
        MAXSIZE = 10GB,
        FILEGROWTH = 10MB
    );
END
GO

USE MediaEntertainmentDB;
GO

-- =============================================
-- Create Schemas for Organized Data Management
-- =============================================

-- Main business schema for core entities
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'Media')
    EXEC('CREATE SCHEMA Media');
GO

-- Staging schema for data processing
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'STG')
    EXEC('CREATE SCHEMA STG');
GO

-- Logging schema for audit and monitoring
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'LOG')
    EXEC('CREATE SCHEMA LOG');
GO

-- Reference schema for lookup data
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'REF')
    EXEC('CREATE SCHEMA REF');
GO

-- =============================================
-- Reference Tables
-- =============================================

-- Content Types Reference
CREATE TABLE REF.Content_Types (
    ContentTypeID INT IDENTITY(1,1) PRIMARY KEY,
    ContentTypeName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    Category NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Platform Types Reference
CREATE TABLE REF.Platform_Types (
    PlatformTypeID INT IDENTITY(1,1) PRIMARY KEY,
    PlatformName NVARCHAR(100) NOT NULL UNIQUE,
    PlatformCategory NVARCHAR(50), -- Streaming, Broadcast, Digital, Social
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- Genre Reference
CREATE TABLE REF.Genres (
    GenreID INT IDENTITY(1,1) PRIMARY KEY,
    GenreName NVARCHAR(100) NOT NULL UNIQUE,
    ParentGenreID INT NULL,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ParentGenreID) REFERENCES REF.Genres(GenreID)
);

-- Audience Demographics Reference
CREATE TABLE REF.Demographics (
    DemographicID INT IDENTITY(1,1) PRIMARY KEY,
    AgeGroup NVARCHAR(20),
    Gender NVARCHAR(10),
    Income_Range NVARCHAR(30),
    Education_Level NVARCHAR(30),
    Geographic_Region NVARCHAR(50),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- Core Business Tables
-- =============================================

-- Content Master Table
CREATE TABLE Media.Content_Master (
    ContentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    Title NVARCHAR(500) NOT NULL,
    ContentTypeID INT NOT NULL,
    GenreID INT,
    Description NVARCHAR(MAX),
    Duration_Minutes INT,
    Release_Date DATE,
    Production_Budget DECIMAL(15,2),
    Content_Rating NVARCHAR(10), -- G, PG, PG-13, R, etc.
    Language_Code NVARCHAR(10),
    Country_Code NVARCHAR(10),
    Director NVARCHAR(200),
    Producer NVARCHAR(200),
    Cast_List NVARCHAR(MAX),
    Keywords NVARCHAR(MAX),
    Thumbnail_URL NVARCHAR(500),
    Trailer_URL NVARCHAR(500),
    Content_Status NVARCHAR(20) DEFAULT 'Active', -- Active, Archived, Removed
    Created_Date DATETIME2 DEFAULT GETDATE(),
    Modified_Date DATETIME2 DEFAULT GETDATE(),
    Created_By NVARCHAR(100),
    Modified_By NVARCHAR(100),
    FOREIGN KEY (ContentTypeID) REFERENCES REF.Content_Types(ContentTypeID),
    FOREIGN KEY (GenreID) REFERENCES REF.Genres(GenreID)
);

-- Platform Content Distribution
CREATE TABLE Media.Platform_Content (
    PlatformContentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentID BIGINT NOT NULL,
    PlatformTypeID INT NOT NULL,
    Platform_Content_ID NVARCHAR(100), -- Platform-specific content ID
    Availability_Start_Date DATETIME2,
    Availability_End_Date DATETIME2,
    Licensing_Cost DECIMAL(15,2),
    Revenue_Share_Percentage DECIMAL(5,2),
    Geographic_Restrictions NVARCHAR(MAX),
    Content_Quality NVARCHAR(20), -- HD, 4K, 8K
    Subtitle_Languages NVARCHAR(200),
    Audio_Languages NVARCHAR(200),
    Is_Exclusive BIT DEFAULT 0,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID),
    FOREIGN KEY (PlatformTypeID) REFERENCES REF.Platform_Types(PlatformTypeID)
);

-- Audience Master
CREATE TABLE Media.Audience_Master (
    AudienceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    AudienceGUID UNIQUEIDENTIFIER DEFAULT NEWID(),
    User_ID NVARCHAR(100), -- Platform-specific user ID
    PlatformTypeID INT,
    DemographicID INT,
    Registration_Date DATETIME2,
    Subscription_Type NVARCHAR(50),
    Subscription_Start_Date DATETIME2,
    Subscription_End_Date DATETIME2,
    Geographic_Location NVARCHAR(100),
    Device_Type NVARCHAR(50),
    Preferred_Language NVARCHAR(10),
    Preferred_Genres NVARCHAR(MAX),
    Is_Active BIT DEFAULT 1,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (PlatformTypeID) REFERENCES REF.Platform_Types(PlatformTypeID),
    FOREIGN KEY (DemographicID) REFERENCES REF.Demographics(DemographicID)
);

-- Content Consumption Analytics
CREATE TABLE Media.Content_Consumption (
    ConsumptionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentID BIGINT NOT NULL,
    AudienceID BIGINT NOT NULL,
    PlatformTypeID INT NOT NULL,
    Session_Start_Time DATETIME2 NOT NULL,
    Session_End_Time DATETIME2,
    Watch_Duration_Minutes INT,
    Completion_Percentage DECIMAL(5,2),
    Quality_Level NVARCHAR(20),
    Device_Type NVARCHAR(50),
    Geographic_Location NVARCHAR(100),
    Bandwidth_Mbps DECIMAL(8,2),
    Buffer_Events INT DEFAULT 0,
    Skip_Events INT DEFAULT 0,
    Pause_Events INT DEFAULT 0,
    Rewind_Events INT DEFAULT 0,
    Fast_Forward_Events INT DEFAULT 0,
    User_Rating DECIMAL(3,1), -- 1.0 to 5.0
    User_Review NVARCHAR(MAX),
    Engagement_Score DECIMAL(5,2),
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID),
    FOREIGN KEY (AudienceID) REFERENCES Media.Audience_Master(AudienceID),
    FOREIGN KEY (PlatformTypeID) REFERENCES REF.Platform_Types(PlatformTypeID)
);

-- Social Media Engagement
CREATE TABLE Media.Social_Media_Engagement (
    EngagementID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentID BIGINT NOT NULL,
    Platform_Name NVARCHAR(50) NOT NULL, -- Twitter, Facebook, Instagram, TikTok
    Post_ID NVARCHAR(200),
    Engagement_Type NVARCHAR(50), -- Like, Share, Comment, Mention, Hashtag
    Engagement_Count INT DEFAULT 0,
    Sentiment_Score DECIMAL(3,2), -- -1.0 to 1.0
    Sentiment_Category NVARCHAR(20), -- Positive, Negative, Neutral
    Influencer_Reach INT DEFAULT 0,
    Hashtags NVARCHAR(MAX),
    Mentions NVARCHAR(MAX),
    Engagement_Date DATETIME2 NOT NULL,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID)
);

-- Revenue Analytics
CREATE TABLE Media.Revenue_Analytics (
    RevenueID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentID BIGINT NOT NULL,
    PlatformTypeID INT NOT NULL,
    Revenue_Date DATE NOT NULL,
    Revenue_Type NVARCHAR(50), -- Subscription, Advertisement, Pay-Per-View, Licensing
    Gross_Revenue DECIMAL(15,2) DEFAULT 0,
    Net_Revenue DECIMAL(15,2) DEFAULT 0,
    Platform_Fee DECIMAL(15,2) DEFAULT 0,
    Marketing_Cost DECIMAL(15,2) DEFAULT 0,
    Content_Cost DECIMAL(15,2) DEFAULT 0,
    Profit_Margin DECIMAL(15,2) DEFAULT 0,
    Currency_Code NVARCHAR(3) DEFAULT 'USD',
    Exchange_Rate DECIMAL(10,4) DEFAULT 1.0000,
    Subscriber_Count INT DEFAULT 0,
    Ad_Impressions BIGINT DEFAULT 0,
    Ad_Clicks BIGINT DEFAULT 0,
    Click_Through_Rate DECIMAL(5,4) DEFAULT 0,
    Cost_Per_Click DECIMAL(8,4) DEFAULT 0,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID),
    FOREIGN KEY (PlatformTypeID) REFERENCES REF.Platform_Types(PlatformTypeID)
);

-- Content Performance Metrics
CREATE TABLE Media.Content_Performance (
    PerformanceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    ContentID BIGINT NOT NULL,
    PlatformTypeID INT NOT NULL,
    Metric_Date DATE NOT NULL,
    Total_Views BIGINT DEFAULT 0,
    Unique_Viewers BIGINT DEFAULT 0,
    Average_Watch_Time_Minutes DECIMAL(8,2) DEFAULT 0,
    Completion_Rate DECIMAL(5,2) DEFAULT 0,
    Engagement_Rate DECIMAL(5,2) DEFAULT 0,
    Retention_Rate DECIMAL(5,2) DEFAULT 0,
    Churn_Rate DECIMAL(5,2) DEFAULT 0,
    Social_Shares INT DEFAULT 0,
    Comments_Count INT DEFAULT 0,
    Likes_Count INT DEFAULT 0,
    Dislikes_Count INT DEFAULT 0,
    Average_Rating DECIMAL(3,1) DEFAULT 0,
    Trending_Score DECIMAL(8,2) DEFAULT 0,
    Recommendation_Score DECIMAL(8,2) DEFAULT 0,
    Search_Ranking INT DEFAULT 0,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID),
    FOREIGN KEY (PlatformTypeID) REFERENCES REF.Platform_Types(PlatformTypeID)
);

-- Audience Segmentation
CREATE TABLE Media.Audience_Segments (
    SegmentID BIGINT IDENTITY(1,1) PRIMARY KEY,
    AudienceID BIGINT NOT NULL,
    Segment_Name NVARCHAR(100) NOT NULL,
    Segment_Category NVARCHAR(50), -- Behavioral, Demographic, Geographic, Psychographic
    Segment_Criteria NVARCHAR(MAX),
    Engagement_Level NVARCHAR(20), -- High, Medium, Low
    Lifetime_Value DECIMAL(15,2) DEFAULT 0,
    Churn_Risk_Score DECIMAL(5,2) DEFAULT 0,
    Preferred_Content_Types NVARCHAR(MAX),
    Viewing_Patterns NVARCHAR(MAX),
    Segment_Date DATE NOT NULL,
    Is_Active BIT DEFAULT 1,
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (AudienceID) REFERENCES Media.Audience_Master(AudienceID)
);

-- Content Recommendations
CREATE TABLE Media.Content_Recommendations (
    RecommendationID BIGINT IDENTITY(1,1) PRIMARY KEY,
    AudienceID BIGINT NOT NULL,
    ContentID BIGINT NOT NULL,
    Recommendation_Score DECIMAL(5,2) NOT NULL,
    Recommendation_Reason NVARCHAR(MAX),
    Algorithm_Used NVARCHAR(100),
    Recommendation_Date DATETIME2 NOT NULL,
    Was_Clicked BIT DEFAULT 0,
    Was_Watched BIT DEFAULT 0,
    Watch_Duration_Minutes INT DEFAULT 0,
    User_Feedback NVARCHAR(20), -- Liked, Disliked, Not_Interested
    Created_Date DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (AudienceID) REFERENCES Media.Audience_Master(AudienceID),
    FOREIGN KEY (ContentID) REFERENCES Media.Content_Master(ContentID)
);

-- =============================================
-- Staging Tables for Data Processing
-- =============================================

-- Staging table for content metadata
CREATE TABLE STG.Content_Metadata_Staging (
    StagingID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Source_System NVARCHAR(100),
    External_Content_ID NVARCHAR(200),
    Title NVARCHAR(500),
    Content_Type NVARCHAR(100),
    Genre NVARCHAR(100),
    Description NVARCHAR(MAX),
    Duration_Minutes INT,
    Release_Date DATE,
    Production_Budget DECIMAL(15,2),
    Content_Rating NVARCHAR(10),
    Language_Code NVARCHAR(10),
    Country_Code NVARCHAR(10),
    Director NVARCHAR(200),
    Producer NVARCHAR(200),
    Cast_List NVARCHAR(MAX),
    Keywords NVARCHAR(MAX),
    Thumbnail_URL NVARCHAR(500),
    Trailer_URL NVARCHAR(500),
    Processing_Status NVARCHAR(20) DEFAULT 'Pending',
    Error_Message NVARCHAR(MAX),
    Created_Date DATETIME2 DEFAULT GETDATE()
);

-- Staging table for streaming analytics
CREATE TABLE STG.Streaming_Analytics_Staging (
    StagingID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Source_System NVARCHAR(100),
    External_Content_ID NVARCHAR(200),
    External_User_ID NVARCHAR(200),
    Platform_Name NVARCHAR(100),
    Session_Start_Time DATETIME2,
    Session_End_Time DATETIME2,
    Watch_Duration_Minutes INT,
    Completion_Percentage DECIMAL(5,2),
    Quality_Level NVARCHAR(20),
    Device_Type NVARCHAR(50),
    Geographic_Location NVARCHAR(100),
    Bandwidth_Mbps DECIMAL(8,2),
    Buffer_Events INT,
    Skip_Events INT,
    Pause_Events INT,
    User_Rating DECIMAL(3,1),
    Processing_Status NVARCHAR(20) DEFAULT 'Pending',
    Error_Message NVARCHAR(MAX),
    Created_Date DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- Logging Tables
-- =============================================

-- ETL Process Logging
CREATE TABLE LOG.ETL_Process_Log (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Process_Name NVARCHAR(200) NOT NULL,
    Package_Name NVARCHAR(200),
    Start_Time DATETIME2 NOT NULL,
    End_Time DATETIME2,
    Status NVARCHAR(20) NOT NULL, -- Running, Success, Failed, Warning
    Records_Processed BIGINT DEFAULT 0,
    Records_Inserted BIGINT DEFAULT 0,
    Records_Updated BIGINT DEFAULT 0,
    Records_Deleted BIGINT DEFAULT 0,
    Records_Rejected BIGINT DEFAULT 0,
    Error_Message NVARCHAR(MAX),
    Server_Name NVARCHAR(100),
    Database_Name NVARCHAR(100),
    Execution_ID UNIQUEIDENTIFIER,
    Created_Date DATETIME2 DEFAULT GETDATE()
);

-- Data Quality Monitoring
CREATE TABLE LOG.Data_Quality_Log (
    QualityLogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    Table_Name NVARCHAR(200) NOT NULL,
    Column_Name NVARCHAR(200),
    Quality_Rule NVARCHAR(500) NOT NULL,
    Rule_Type NVARCHAR(50), -- Completeness, Accuracy, Consistency, Validity
    Records_Checked BIGINT DEFAULT 0,
    Records_Failed BIGINT DEFAULT 0,
    Failure_Rate DECIMAL(5,2) DEFAULT 0,
    Quality_Score DECIMAL(5,2) DEFAULT 0,
    Check_Date DATETIME2 NOT NULL,
    Details NVARCHAR(MAX),
    Created_Date DATETIME2 DEFAULT GETDATE()
);

-- =============================================
-- Indexes for Performance Optimization
-- =============================================

-- Content Master Indexes
CREATE NONCLUSTERED INDEX IX_Content_Master_ContentType ON Media.Content_Master(ContentTypeID);
CREATE NONCLUSTERED INDEX IX_Content_Master_Genre ON Media.Content_Master(GenreID);
CREATE NONCLUSTERED INDEX IX_Content_Master_ReleaseDate ON Media.Content_Master(Release_Date);
CREATE NONCLUSTERED INDEX IX_Content_Master_Status ON Media.Content_Master(Content_Status);

-- Content Consumption Indexes
CREATE NONCLUSTERED INDEX IX_Content_Consumption_ContentID ON Media.Content_Consumption(ContentID);
CREATE NONCLUSTERED INDEX IX_Content_Consumption_AudienceID ON Media.Content_Consumption(AudienceID);
CREATE NONCLUSTERED INDEX IX_Content_Consumption_SessionStart ON Media.Content_Consumption(Session_Start_Time);
CREATE NONCLUSTERED INDEX IX_Content_Consumption_Platform ON Media.Content_Consumption(PlatformTypeID);

-- Revenue Analytics Indexes
CREATE NONCLUSTERED INDEX IX_Revenue_Analytics_ContentID ON Media.Revenue_Analytics(ContentID);
CREATE NONCLUSTERED INDEX IX_Revenue_Analytics_Date ON Media.Revenue_Analytics(Revenue_Date);
CREATE NONCLUSTERED INDEX IX_Revenue_Analytics_Platform ON Media.Revenue_Analytics(PlatformTypeID);
CREATE NONCLUSTERED INDEX IX_Revenue_Analytics_Type ON Media.Revenue_Analytics(Revenue_Type);

-- Performance Metrics Indexes
CREATE NONCLUSTERED INDEX IX_Content_Performance_ContentID ON Media.Content_Performance(ContentID);
CREATE NONCLUSTERED INDEX IX_Content_Performance_Date ON Media.Content_Performance(Metric_Date);
CREATE NONCLUSTERED INDEX IX_Content_Performance_Platform ON Media.Content_Performance(PlatformTypeID);

-- Social Media Engagement Indexes
CREATE NONCLUSTERED INDEX IX_Social_Media_ContentID ON Media.Social_Media_Engagement(ContentID);
CREATE NONCLUSTERED INDEX IX_Social_Media_Platform ON Media.Social_Media_Engagement(Platform_Name);
CREATE NONCLUSTERED INDEX IX_Social_Media_Date ON Media.Social_Media_Engagement(Engagement_Date);

-- =============================================
-- Views for Business Intelligence
-- =============================================

-- Content Performance Summary View
CREATE VIEW Media.vw_Content_Performance_Summary AS
SELECT 
    cm.ContentID,
    cm.Title,
    ct.ContentTypeName,
    g.GenreName,
    cm.Release_Date,
    SUM(cp.Total_Views) as Total_Views,
    AVG(cp.Average_Watch_Time_Minutes) as Avg_Watch_Time,
    AVG(cp.Completion_Rate) as Avg_Completion_Rate,
    AVG(cp.Engagement_Rate) as Avg_Engagement_Rate,
    SUM(ra.Gross_Revenue) as Total_Revenue,
    AVG(cp.Average_Rating) as Avg_Rating,
    COUNT(DISTINCT cp.PlatformTypeID) as Platform_Count
FROM Media.Content_Master cm
LEFT JOIN REF.Content_Types ct ON cm.ContentTypeID = ct.ContentTypeID
LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
LEFT JOIN Media.Content_Performance cp ON cm.ContentID = cp.ContentID
LEFT JOIN Media.Revenue_Analytics ra ON cm.ContentID = ra.ContentID
WHERE cm.Content_Status = 'Active'
GROUP BY cm.ContentID, cm.Title, ct.ContentTypeName, g.GenreName, cm.Release_Date;
GO

-- Audience Engagement Summary View
CREATE VIEW Media.vw_Audience_Engagement_Summary AS
SELECT 
    am.AudienceID,
    am.User_ID,
    pt.PlatformName,
    d.AgeGroup,
    d.Gender,
    d.Geographic_Region,
    COUNT(cc.ConsumptionID) as Total_Sessions,
    SUM(cc.Watch_Duration_Minutes) as Total_Watch_Time,
    AVG(cc.Completion_Percentage) as Avg_Completion_Rate,
    AVG(cc.Engagement_Score) as Avg_Engagement_Score,
    COUNT(DISTINCT cc.ContentID) as Unique_Content_Watched
FROM Media.Audience_Master am
LEFT JOIN REF.Platform_Types pt ON am.PlatformTypeID = pt.PlatformTypeID
LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
WHERE am.Is_Active = 1
GROUP BY am.AudienceID, am.User_ID, pt.PlatformName, d.AgeGroup, d.Gender, d.Geographic_Region;
GO

-- Revenue Performance View
CREATE VIEW Media.vw_Revenue_Performance AS
SELECT 
    cm.ContentID,
    cm.Title,
    pt.PlatformName,
    ra.Revenue_Date,
    ra.Revenue_Type,
    ra.Gross_Revenue,
    ra.Net_Revenue,
    ra.Profit_Margin,
    cp.Total_Views,
    CASE 
        WHEN cp.Total_Views > 0 THEN ra.Gross_Revenue / cp.Total_Views 
        ELSE 0 
    END as Revenue_Per_View
FROM Media.Content_Master cm
INNER JOIN Media.Revenue_Analytics ra ON cm.ContentID = ra.ContentID
INNER JOIN REF.Platform_Types pt ON ra.PlatformTypeID = pt.PlatformTypeID
LEFT JOIN Media.Content_Performance cp ON cm.ContentID = cp.ContentID 
    AND ra.PlatformTypeID = cp.PlatformTypeID 
    AND ra.Revenue_Date = cp.Metric_Date;
GO

-- =============================================
-- Insert Reference Data
-- =============================================

-- Content Types
INSERT INTO REF.Content_Types (ContentTypeName, Description, Category) VALUES
('Movie', 'Feature-length films', 'Video'),
('TV Series', 'Television series and shows', 'Video'),
('Documentary', 'Documentary films and series', 'Video'),
('Short Film', 'Short-form video content', 'Video'),
('Music Video', 'Music videos and performances', 'Video'),
('Podcast', 'Audio podcast content', 'Audio'),
('Audiobook', 'Audio book content', 'Audio'),
('Live Stream', 'Live streaming content', 'Live'),
('Sports Event', 'Live and recorded sports events', 'Live'),
('News Program', 'News and current affairs', 'Video');

-- Platform Types
INSERT INTO REF.Platform_Types (PlatformName, PlatformCategory, Description) VALUES
('Netflix', 'Streaming', 'Video streaming platform'),
('Amazon Prime Video', 'Streaming', 'Video streaming platform'),
('Disney+', 'Streaming', 'Video streaming platform'),
('Hulu', 'Streaming', 'Video streaming platform'),
('HBO Max', 'Streaming', 'Video streaming platform'),
('YouTube', 'Digital', 'Video sharing platform'),
('TikTok', 'Social', 'Short-form video platform'),
('Instagram', 'Social', 'Social media platform'),
('Facebook', 'Social', 'Social media platform'),
('Twitter', 'Social', 'Social media platform'),
('Spotify', 'Streaming', 'Audio streaming platform'),
('Apple Music', 'Streaming', 'Audio streaming platform'),
('Broadcast TV', 'Broadcast', 'Traditional television'),
('Cable TV', 'Broadcast', 'Cable television'),
('Cinema', 'Theatrical', 'Movie theaters');

-- Genres
INSERT INTO REF.Genres (GenreName, Description) VALUES
('Action', 'Action and adventure content'),
('Comedy', 'Comedy and humor content'),
('Drama', 'Dramatic content'),
('Horror', 'Horror and thriller content'),
('Science Fiction', 'Science fiction content'),
('Fantasy', 'Fantasy content'),
('Romance', 'Romantic content'),
('Documentary', 'Documentary content'),
('Animation', 'Animated content'),
('Musical', 'Musical content'),
('Sports', 'Sports-related content'),
('News', 'News and current affairs'),
('Educational', 'Educational content'),
('Children', 'Children and family content'),
('Reality TV', 'Reality television content');

-- Demographics
INSERT INTO REF.Demographics (AgeGroup, Gender, Income_Range, Education_Level, Geographic_Region) VALUES
('18-24', 'Male', '$25,000-$50,000', 'High School', 'North America'),
('18-24', 'Female', '$25,000-$50,000', 'High School', 'North America'),
('25-34', 'Male', '$50,000-$75,000', 'Bachelor''s Degree', 'North America'),
('25-34', 'Female', '$50,000-$75,000', 'Bachelor''s Degree', 'North America'),
('35-44', 'Male', '$75,000-$100,000', 'Bachelor''s Degree', 'North America'),
('35-44', 'Female', '$75,000-$100,000', 'Bachelor''s Degree', 'North America'),
('45-54', 'Male', '$100,000+', 'Master''s Degree', 'North America'),
('45-54', 'Female', '$100,000+', 'Master''s Degree', 'North America'),
('55+', 'Male', '$75,000-$100,000', 'Bachelor''s Degree', 'North America'),
('55+', 'Female', '$75,000-$100,000', 'Bachelor''s Degree', 'North America');

PRINT 'Media Entertainment Analytics Database created successfully!';
PRINT 'Database includes:';
PRINT '- 4 schemas: Media (main), STG (staging), LOG (logging), REF (reference)';
PRINT '- 15+ core business tables for content, audience, and revenue analytics';
PRINT '- Comprehensive indexing for performance optimization';
PRINT '- Business intelligence views for reporting';
PRINT '- Reference data for content types, platforms, genres, and demographics';
GO