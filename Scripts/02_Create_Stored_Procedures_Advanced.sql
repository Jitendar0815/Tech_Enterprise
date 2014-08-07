-- =============================================
-- Advanced Stored Procedures for Media Entertainment Analytics
-- Comprehensive procedures for content analytics, audience insights, and revenue optimization
-- =============================================

USE MediaEntertainmentDB;
GO

-- =============================================
-- Content Performance Analytics Procedures
-- =============================================

-- Procedure: Calculate Content Performance Metrics
CREATE OR ALTER PROCEDURE Media.sp_CalculateContentPerformanceMetrics
    @ContentID BIGINT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @PlatformTypeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DefaultStartDate DATE = DATEADD(DAY, -30, GETDATE());
    DECLARE @DefaultEndDate DATE = GETDATE();
    
    SET @StartDate = ISNULL(@StartDate, @DefaultStartDate);
    SET @EndDate = ISNULL(@EndDate, @DefaultEndDate);
    
    -- Calculate and update performance metrics
    WITH ContentMetrics AS (
        SELECT 
            cc.ContentID,
            cc.PlatformTypeID,
            CAST(cc.Session_Start_Time AS DATE) as MetricDate,
            COUNT(DISTINCT cc.AudienceID) as UniqueViewers,
            COUNT(*) as TotalSessions,
            SUM(cc.Watch_Duration_Minutes) as TotalWatchTime,
            AVG(cc.Watch_Duration_Minutes) as AvgWatchTime,
            AVG(cc.Completion_Percentage) as AvgCompletionRate,
            AVG(cc.Engagement_Score) as AvgEngagementScore,
            AVG(cc.User_Rating) as AvgUserRating,
            SUM(CASE WHEN cc.User_Rating >= 4 THEN 1 ELSE 0 END) as HighRatings,
            SUM(CASE WHEN cc.User_Rating <= 2 THEN 1 ELSE 0 END) as LowRatings,
            COUNT(CASE WHEN cc.Completion_Percentage >= 90 THEN 1 END) as CompletedViews,
            COUNT(CASE WHEN cc.Skip_Events > 0 THEN 1 END) as SkippedSessions,
            COUNT(CASE WHEN cc.Buffer_Events > 3 THEN 1 END) as BufferingIssues
        FROM Media.Content_Consumption cc
        WHERE (@ContentID IS NULL OR cc.ContentID = @ContentID)
          AND (@PlatformTypeID IS NULL OR cc.PlatformTypeID = @PlatformTypeID)
          AND CAST(cc.Session_Start_Time AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY cc.ContentID, cc.PlatformTypeID, CAST(cc.Session_Start_Time AS DATE)
    ),
    SocialMetrics AS (
        SELECT 
            sme.ContentID,
            CAST(sme.Engagement_Date AS DATE) as MetricDate,
            SUM(sme.Engagement_Count) as SocialShares,
            COUNT(*) as SocialMentions,
            AVG(sme.Sentiment_Score) as AvgSentiment,
            SUM(sme.Influencer_Reach) as InfluencerReach
        FROM Media.Social_Media_Engagement sme
        WHERE (@ContentID IS NULL OR sme.ContentID = @ContentID)
          AND CAST(sme.Engagement_Date AS DATE) BETWEEN @StartDate AND @EndDate
        GROUP BY sme.ContentID, CAST(sme.Engagement_Date AS DATE)
    )
    
    -- Merge or insert performance metrics
    MERGE Media.Content_Performance AS target
    USING (
        SELECT 
            cm.ContentID,
            cm.PlatformTypeID,
            cm.MetricDate,
            cm.TotalSessions as Total_Views,
            cm.UniqueViewers as Unique_Viewers,
            cm.AvgWatchTime as Average_Watch_Time_Minutes,
            cm.AvgCompletionRate as Completion_Rate,
            cm.AvgEngagementScore as Engagement_Rate,
            CASE 
                WHEN cm.TotalSessions > 0 
                THEN (CAST(cm.UniqueViewers AS DECIMAL) / cm.TotalSessions) * 100 
                ELSE 0 
            END as Retention_Rate,
            CASE 
                WHEN cm.TotalSessions > 0 
                THEN (CAST(cm.SkippedSessions AS DECIMAL) / cm.TotalSessions) * 100 
                ELSE 0 
            END as Churn_Rate,
            ISNULL(sm.SocialShares, 0) as Social_Shares,
            ISNULL(sm.SocialMentions, 0) as Comments_Count,
            cm.HighRatings as Likes_Count,
            cm.LowRatings as Dislikes_Count,
            cm.AvgUserRating as Average_Rating,
            -- Calculate trending score based on engagement velocity
            CASE 
                WHEN cm.TotalSessions >= 1000 AND cm.AvgEngagementScore >= 70 THEN 90 + (cm.AvgEngagementScore * 0.1)
                WHEN cm.TotalSessions >= 500 AND cm.AvgEngagementScore >= 50 THEN 70 + (cm.AvgEngagementScore * 0.2)
                WHEN cm.TotalSessions >= 100 AND cm.AvgEngagementScore >= 30 THEN 50 + (cm.AvgEngagementScore * 0.3)
                ELSE cm.AvgEngagementScore * 0.5
            END as Trending_Score,
            -- Calculate recommendation score
            (cm.AvgCompletionRate * 0.4) + (cm.AvgEngagementScore * 0.3) + (cm.AvgUserRating * 20 * 0.3) as Recommendation_Score
        FROM ContentMetrics cm
        LEFT JOIN SocialMetrics sm ON cm.ContentID = sm.ContentID AND cm.MetricDate = sm.MetricDate
    ) AS source ON target.ContentID = source.ContentID 
                 AND target.PlatformTypeID = source.PlatformTypeID 
                 AND target.Metric_Date = source.MetricDate
    
    WHEN MATCHED THEN
        UPDATE SET
            Total_Views = source.Total_Views,
            Unique_Viewers = source.Unique_Viewers,
            Average_Watch_Time_Minutes = source.Average_Watch_Time_Minutes,
            Completion_Rate = source.Completion_Rate,
            Engagement_Rate = source.Engagement_Rate,
            Retention_Rate = source.Retention_Rate,
            Churn_Rate = source.Churn_Rate,
            Social_Shares = source.Social_Shares,
            Comments_Count = source.Comments_Count,
            Likes_Count = source.Likes_Count,
            Dislikes_Count = source.Dislikes_Count,
            Average_Rating = source.Average_Rating,
            Trending_Score = source.Trending_Score,
            Recommendation_Score = source.Recommendation_Score
    
    WHEN NOT MATCHED THEN
        INSERT (ContentID, PlatformTypeID, Metric_Date, Total_Views, Unique_Viewers, 
                Average_Watch_Time_Minutes, Completion_Rate, Engagement_Rate, Retention_Rate,
                Churn_Rate, Social_Shares, Comments_Count, Likes_Count, Dislikes_Count,
                Average_Rating, Trending_Score, Recommendation_Score)
        VALUES (source.ContentID, source.PlatformTypeID, source.MetricDate, source.Total_Views,
                source.Unique_Viewers, source.Average_Watch_Time_Minutes, source.Completion_Rate,
                source.Engagement_Rate, source.Retention_Rate, source.Churn_Rate,
                source.Social_Shares, source.Comments_Count, source.Likes_Count,
                source.Dislikes_Count, source.Average_Rating, source.Trending_Score,
                source.Recommendation_Score);
    
    -- Log the process
    INSERT INTO LOG.ETL_Process_Log (Process_Name, Start_Time, End_Time, Status, Records_Processed)
    VALUES ('Calculate Content Performance Metrics', GETDATE(), GETDATE(), 'Success', @@ROWCOUNT);
    
    PRINT 'Content performance metrics calculated successfully.';
END;
GO

-- Procedure: Generate Content Recommendations
CREATE OR ALTER PROCEDURE Media.sp_GenerateContentRecommendations
    @AudienceID BIGINT = NULL,
    @TopN INT = 10,
    @IncludeWatched BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get audience preferences and viewing history
    WITH AudienceProfile AS (
        SELECT 
            am.AudienceID,
            am.DemographicID,
            am.Preferred_Genres,
            d.AgeGroup,
            d.Gender,
            d.Geographic_Region
        FROM Media.Audience_Master am
        LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
        WHERE (@AudienceID IS NULL OR am.AudienceID = @AudienceID)
          AND am.Is_Active = 1
    ),
    ViewingHistory AS (
        SELECT 
            cc.AudienceID,
            cc.ContentID,
            cm.GenreID,
            g.GenreName,
            AVG(cc.Completion_Percentage) as AvgCompletion,
            AVG(cc.User_Rating) as AvgRating,
            COUNT(*) as ViewCount,
            MAX(cc.Session_Start_Time) as LastViewed
        FROM Media.Content_Consumption cc
        INNER JOIN Media.Content_Master cm ON cc.ContentID = cm.ContentID
        LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
        WHERE cc.Session_Start_Time >= DATEADD(DAY, -90, GETDATE())
        GROUP BY cc.AudienceID, cc.ContentID, cm.GenreID, g.GenreName
    ),
    GenrePreferences AS (
        SELECT 
            vh.AudienceID,
            vh.GenreID,
            vh.GenreName,
            AVG(vh.AvgCompletion) as GenreCompletionRate,
            AVG(vh.AvgRating) as GenreRating,
            COUNT(*) as GenreViewCount,
            -- Calculate genre preference score
            (AVG(vh.AvgCompletion) * 0.4) + (AVG(vh.AvgRating) * 20 * 0.4) + (LOG(COUNT(*)) * 10 * 0.2) as GenreScore
        FROM ViewingHistory vh
        GROUP BY vh.AudienceID, vh.GenreID, vh.GenreName
    ),
    ContentScores AS (
        SELECT 
            ap.AudienceID,
            cm.ContentID,
            cm.Title,
            cm.GenreID,
            g.GenreName,
            cp.Average_Rating,
            cp.Trending_Score,
            cp.Recommendation_Score,
            gp.GenreScore,
            -- Calculate recommendation score
            CASE 
                WHEN gp.GenreScore IS NOT NULL THEN
                    (cp.Recommendation_Score * 0.3) + 
                    (cp.Trending_Score * 0.2) + 
                    (cp.Average_Rating * 10 * 0.2) + 
                    (gp.GenreScore * 0.3)
                ELSE
                    (cp.Recommendation_Score * 0.4) + 
                    (cp.Trending_Score * 0.3) + 
                    (cp.Average_Rating * 10 * 0.3)
            END as FinalRecommendationScore,
            CASE 
                WHEN gp.GenreScore IS NOT NULL THEN 'Genre Match'
                WHEN cp.Trending_Score > 80 THEN 'Trending Content'
                WHEN cp.Average_Rating > 4.0 THEN 'Highly Rated'
                ELSE 'Popular Content'
            END as RecommendationReason
        FROM AudienceProfile ap
        CROSS JOIN Media.Content_Master cm
        INNER JOIN REF.Genres g ON cm.GenreID = g.GenreID
        INNER JOIN Media.Content_Performance cp ON cm.ContentID = cp.ContentID
        LEFT JOIN GenrePreferences gp ON ap.AudienceID = gp.AudienceID AND cm.GenreID = gp.GenreID
        LEFT JOIN ViewingHistory vh ON ap.AudienceID = vh.AudienceID AND cm.ContentID = vh.ContentID
        WHERE cm.Content_Status = 'Active'
          AND cp.Metric_Date >= DATEADD(DAY, -7, GETDATE()) -- Recent performance data
          AND (@IncludeWatched = 1 OR vh.ContentID IS NULL) -- Exclude already watched unless specified
    )
    
    -- Insert recommendations
    INSERT INTO Media.Content_Recommendations (
        AudienceID, ContentID, Recommendation_Score, Recommendation_Reason, 
        Algorithm_Used, Recommendation_Date
    )
    SELECT TOP (@TopN)
        cs.AudienceID,
        cs.ContentID,
        cs.FinalRecommendationScore,
        cs.RecommendationReason,
        'Hybrid Collaborative-Content Based',
        GETDATE()
    FROM ContentScores cs
    WHERE (@AudienceID IS NULL OR cs.AudienceID = @AudienceID)
    ORDER BY cs.FinalRecommendationScore DESC;
    
    -- Return the recommendations
    SELECT 
        cr.RecommendationID,
        cr.AudienceID,
        cm.Title,
        g.GenreName,
        cr.Recommendation_Score,
        cr.Recommendation_Reason,
        cr.Recommendation_Date
    FROM Media.Content_Recommendations cr
    INNER JOIN Media.Content_Master cm ON cr.ContentID = cm.ContentID
    LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
    WHERE (@AudienceID IS NULL OR cr.AudienceID = @AudienceID)
      AND cr.Recommendation_Date >= DATEADD(HOUR, -1, GETDATE())
    ORDER BY cr.Recommendation_Score DESC;
    
    PRINT 'Content recommendations generated successfully.';
END;
GO

-- =============================================
-- Audience Analytics Procedures
-- =============================================

-- Procedure: Analyze Audience Engagement Patterns
CREATE OR ALTER PROCEDURE Media.sp_AnalyzeAudienceEngagement
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @AudienceSegment NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DefaultStartDate DATE = DATEADD(DAY, -30, GETDATE());
    DECLARE @DefaultEndDate DATE = GETDATE();
    
    SET @StartDate = ISNULL(@StartDate, @DefaultStartDate);
    SET @EndDate = ISNULL(@EndDate, @DefaultEndDate);
    
    -- Analyze engagement patterns by demographics
    SELECT 
        d.AgeGroup,
        d.Gender,
        d.Geographic_Region,
        COUNT(DISTINCT am.AudienceID) as TotalAudience,
        COUNT(cc.ConsumptionID) as TotalSessions,
        AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration,
        AVG(cc.Completion_Percentage) as AvgCompletionRate,
        AVG(cc.Engagement_Score) as AvgEngagementScore,
        AVG(cc.User_Rating) as AvgUserRating,
        COUNT(DISTINCT cc.ContentID) as UniqueContentWatched,
        -- Calculate engagement level
        CASE 
            WHEN AVG(cc.Engagement_Score) >= 80 THEN 'High'
            WHEN AVG(cc.Engagement_Score) >= 50 THEN 'Medium'
            ELSE 'Low'
        END as EngagementLevel,
        -- Calculate viewing frequency
        CASE 
            WHEN COUNT(cc.ConsumptionID) / NULLIF(COUNT(DISTINCT am.AudienceID), 0) >= 20 THEN 'Heavy Viewer'
            WHEN COUNT(cc.ConsumptionID) / NULLIF(COUNT(DISTINCT am.AudienceID), 0) >= 10 THEN 'Regular Viewer'
            WHEN COUNT(cc.ConsumptionID) / NULLIF(COUNT(DISTINCT am.AudienceID), 0) >= 5 THEN 'Casual Viewer'
            ELSE 'Light Viewer'
        END as ViewingFrequency
    FROM Media.Audience_Master am
    LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
    LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
        AND CAST(cc.Session_Start_Time AS DATE) BETWEEN @StartDate AND @EndDate
    WHERE am.Is_Active = 1
    GROUP BY d.AgeGroup, d.Gender, d.Geographic_Region
    HAVING COUNT(cc.ConsumptionID) > 0
    ORDER BY AvgEngagementScore DESC;
    
    -- Analyze content preferences by audience segment
    SELECT 
        g.GenreName,
        ct.ContentTypeName,
        COUNT(DISTINCT cc.AudienceID) as UniqueViewers,
        COUNT(cc.ConsumptionID) as TotalViews,
        AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration,
        AVG(cc.Completion_Percentage) as AvgCompletionRate,
        AVG(cc.User_Rating) as AvgUserRating,
        SUM(cc.Watch_Duration_Minutes) as TotalWatchTime
    FROM Media.Content_Consumption cc
    INNER JOIN Media.Content_Master cm ON cc.ContentID = cm.ContentID
    LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
    LEFT JOIN REF.Content_Types ct ON cm.ContentTypeID = ct.ContentTypeID
    WHERE CAST(cc.Session_Start_Time AS DATE) BETWEEN @StartDate AND @EndDate
    GROUP BY g.GenreName, ct.ContentTypeName
    ORDER BY TotalViews DESC;
    
    PRINT 'Audience engagement analysis completed successfully.';
END;
GO

-- Procedure: Generate Audience Segments
CREATE OR ALTER PROCEDURE Media.sp_GenerateAudienceSegments
    @AnalysisDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SET @AnalysisDate = ISNULL(@AnalysisDate, GETDATE());
    
    -- Clear existing segments for the analysis date
    DELETE FROM Media.Audience_Segments 
    WHERE Segment_Date = @AnalysisDate;
    
    -- Generate behavioral segments
    WITH BehavioralMetrics AS (
        SELECT 
            am.AudienceID,
            COUNT(DISTINCT cc.ContentID) as UniqueContentWatched,
            COUNT(cc.ConsumptionID) as TotalSessions,
            AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration,
            AVG(cc.Completion_Percentage) as AvgCompletionRate,
            AVG(cc.Engagement_Score) as AvgEngagementScore,
            MAX(cc.Session_Start_Time) as LastActivity,
            DATEDIFF(DAY, MAX(cc.Session_Start_Time), @AnalysisDate) as DaysSinceLastActivity
        FROM Media.Audience_Master am
        LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
        WHERE am.Is_Active = 1
          AND cc.Session_Start_Time >= DATEADD(DAY, -90, @AnalysisDate)
        GROUP BY am.AudienceID
    )
    
    INSERT INTO Media.Audience_Segments (
        AudienceID, Segment_Name, Segment_Category, Segment_Criteria, 
        Engagement_Level, Segment_Date
    )
    SELECT 
        bm.AudienceID,
        CASE 
            WHEN bm.DaysSinceLastActivity > 30 THEN 'Inactive'
            WHEN bm.TotalSessions >= 50 AND bm.AvgCompletionRate >= 80 THEN 'Power User'
            WHEN bm.TotalSessions >= 20 AND bm.AvgCompletionRate >= 60 THEN 'Regular Viewer'
            WHEN bm.UniqueContentWatched >= 20 AND bm.AvgWatchDuration >= 30 THEN 'Content Explorer'
            WHEN bm.AvgCompletionRate < 30 THEN 'Browser'
            ELSE 'Casual Viewer'
        END as SegmentName,
        'Behavioral' as SegmentCategory,
        CONCAT('Sessions: ', bm.TotalSessions, ', Completion: ', CAST(bm.AvgCompletionRate AS INT), '%') as SegmentCriteria,
        CASE 
            WHEN bm.AvgEngagementScore >= 80 THEN 'High'
            WHEN bm.AvgEngagementScore >= 50 THEN 'Medium'
            ELSE 'Low'
        END as EngagementLevel,
        @AnalysisDate
    FROM BehavioralMetrics bm
    WHERE bm.TotalSessions > 0;
    
    -- Generate demographic segments
    INSERT INTO Media.Audience_Segments (
        AudienceID, Segment_Name, Segment_Category, Segment_Criteria, Segment_Date
    )
    SELECT 
        am.AudienceID,
        CONCAT(ISNULL(d.AgeGroup, 'Unknown'), '_', ISNULL(d.Gender, 'Unknown')) as SegmentName,
        'Demographic' as SegmentCategory,
        CONCAT('Age: ', ISNULL(d.AgeGroup, 'Unknown'), ', Gender: ', ISNULL(d.Gender, 'Unknown'), 
               ', Region: ', ISNULL(d.Geographic_Region, 'Unknown')) as SegmentCriteria,
        @AnalysisDate
    FROM Media.Audience_Master am
    LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
    WHERE am.Is_Active = 1;
    
    -- Generate value-based segments
    WITH ValueMetrics AS (
        SELECT 
            am.AudienceID,
            am.Subscription_Type,
            DATEDIFF(DAY, am.Subscription_Start_Date, @AnalysisDate) as SubscriptionDays,
            COUNT(cc.ConsumptionID) as TotalSessions,
            SUM(cc.Watch_Duration_Minutes) as TotalWatchTime
        FROM Media.Audience_Master am
        LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
        WHERE am.Is_Active = 1
          AND cc.Session_Start_Time >= DATEADD(DAY, -90, @AnalysisDate)
        GROUP BY am.AudienceID, am.Subscription_Type, am.Subscription_Start_Date
    )
    
    INSERT INTO Media.Audience_Segments (
        AudienceID, Segment_Name, Segment_Category, Segment_Criteria, Segment_Date
    )
    SELECT 
        vm.AudienceID,
        CASE 
            WHEN vm.Subscription_Type LIKE '%Premium%' AND vm.SubscriptionDays >= 365 AND vm.TotalWatchTime >= 1000 THEN 'VIP Customer'
            WHEN vm.Subscription_Type LIKE '%Premium%' AND vm.TotalSessions >= 20 THEN 'Premium User'
            WHEN vm.SubscriptionDays >= 180 AND vm.TotalSessions >= 15 THEN 'Loyal Customer'
            WHEN vm.TotalSessions >= 10 THEN 'Active User'
            ELSE 'New User'
        END as SegmentName,
        'Value' as SegmentCategory,
        CONCAT('Subscription: ', ISNULL(vm.Subscription_Type, 'Free'), ', Days: ', vm.SubscriptionDays) as SegmentCriteria,
        @AnalysisDate
    FROM ValueMetrics vm;
    
    -- Return segment summary
    SELECT 
        Segment_Category,
        Segment_Name,
        COUNT(*) as AudienceCount,
        AVG(CASE WHEN Engagement_Level = 'High' THEN 1.0 ELSE 0.0 END) * 100 as HighEngagementPercentage
    FROM Media.Audience_Segments
    WHERE Segment_Date = @AnalysisDate
    GROUP BY Segment_Category, Segment_Name
    ORDER BY Segment_Category, AudienceCount DESC;
    
    PRINT 'Audience segments generated successfully.';
END;
GO

-- =============================================
-- Revenue Analytics Procedures
-- =============================================

-- Procedure: Calculate Revenue Performance Metrics
CREATE OR ALTER PROCEDURE Media.sp_CalculateRevenueMetrics
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @ContentID BIGINT = NULL,
    @PlatformTypeID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DefaultStartDate DATE = DATEADD(DAY, -30, GETDATE());
    DECLARE @DefaultEndDate DATE = GETDATE();
    
    SET @StartDate = ISNULL(@StartDate, @DefaultStartDate);
    SET @EndDate = ISNULL(@EndDate, @DefaultEndDate);
    
    -- Revenue performance by content
    SELECT 
        cm.ContentID,
        cm.Title,
        g.GenreName,
        pt.PlatformName,
        SUM(ra.Gross_Revenue) as TotalGrossRevenue,
        SUM(ra.Net_Revenue) as TotalNetRevenue,
        AVG(ra.Profit_Margin) as AvgProfitMargin,
        SUM(ra.Marketing_Cost) as TotalMarketingCost,
        SUM(cp.Total_Views) as TotalViews,
        CASE 
            WHEN SUM(cp.Total_Views) > 0 
            THEN SUM(ra.Gross_Revenue) / SUM(cp.Total_Views)
            ELSE 0 
        END as RevenuePerView,
        -- Calculate ROI
        CASE 
            WHEN SUM(ra.Marketing_Cost + ra.Content_Cost) > 0 
            THEN ((SUM(ra.Net_Revenue) - SUM(ra.Marketing_Cost + ra.Content_Cost)) / SUM(ra.Marketing_Cost + ra.Content_Cost)) * 100
            ELSE 0 
        END as ROI_Percentage
    FROM Media.Content_Master cm
    INNER JOIN Media.Revenue_Analytics ra ON cm.ContentID = ra.ContentID
    LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
    LEFT JOIN REF.Platform_Types pt ON ra.PlatformTypeID = pt.PlatformTypeID
    LEFT JOIN Media.Content_Performance cp ON cm.ContentID = cp.ContentID 
        AND ra.PlatformTypeID = cp.PlatformTypeID 
        AND ra.Revenue_Date = cp.Metric_Date
    WHERE ra.Revenue_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR cm.ContentID = @ContentID)
      AND (@PlatformTypeID IS NULL OR ra.PlatformTypeID = @PlatformTypeID)
    GROUP BY cm.ContentID, cm.Title, g.GenreName, pt.PlatformName
    ORDER BY TotalGrossRevenue DESC;
    
    -- Revenue trends by time period
    SELECT 
        ra.Revenue_Date,
        ra.Revenue_Type,
        SUM(ra.Gross_Revenue) as DailyGrossRevenue,
        SUM(ra.Net_Revenue) as DailyNetRevenue,
        COUNT(DISTINCT ra.ContentID) as UniqueContentCount,
        AVG(ra.Profit_Margin) as AvgProfitMargin
    FROM Media.Revenue_Analytics ra
    WHERE ra.Revenue_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR ra.ContentID = @ContentID)
      AND (@PlatformTypeID IS NULL OR ra.PlatformTypeID = @PlatformTypeID)
    GROUP BY ra.Revenue_Date, ra.Revenue_Type
    ORDER BY ra.Revenue_Date, ra.Revenue_Type;
    
    -- Platform performance comparison
    SELECT 
        pt.PlatformName,
        pt.PlatformCategory,
        COUNT(DISTINCT ra.ContentID) as ContentCount,
        SUM(ra.Gross_Revenue) as TotalRevenue,
        AVG(ra.Profit_Margin) as AvgProfitMargin,
        SUM(cp.Total_Views) as TotalViews,
        CASE 
            WHEN SUM(cp.Total_Views) > 0 
            THEN SUM(ra.Gross_Revenue) / SUM(cp.Total_Views)
            ELSE 0 
        END as RevenuePerView
    FROM REF.Platform_Types pt
    INNER JOIN Media.Revenue_Analytics ra ON pt.PlatformTypeID = ra.PlatformTypeID
    LEFT JOIN Media.Content_Performance cp ON ra.ContentID = cp.ContentID 
        AND ra.PlatformTypeID = cp.PlatformTypeID 
        AND ra.Revenue_Date = cp.Metric_Date
    WHERE ra.Revenue_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR ra.ContentID = @ContentID)
    GROUP BY pt.PlatformName, pt.PlatformCategory
    ORDER BY TotalRevenue DESC;
    
    PRINT 'Revenue performance metrics calculated successfully.';
END;
GO

-- =============================================
-- Social Media Analytics Procedures
-- =============================================

-- Procedure: Analyze Social Media Engagement
CREATE OR ALTER PROCEDURE Media.sp_AnalyzeSocialEngagement
    @ContentID BIGINT = NULL,
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @PlatformName NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DefaultStartDate DATE = DATEADD(DAY, -7, GETDATE());
    DECLARE @DefaultEndDate DATE = GETDATE();
    
    SET @StartDate = ISNULL(@StartDate, @DefaultStartDate);
    SET @EndDate = ISNULL(@EndDate, @DefaultEndDate);
    
    -- Social engagement summary by content
    SELECT 
        cm.ContentID,
        cm.Title,
        g.GenreName,
        sme.Platform_Name,
        COUNT(*) as TotalPosts,
        SUM(sme.Engagement_Count) as TotalEngagement,
        AVG(sme.Sentiment_Score) as AvgSentimentScore,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Positive' THEN 1 END) as PositiveEngagements,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Negative' THEN 1 END) as NegativeEngagements,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Neutral' THEN 1 END) as NeutralEngagements,
        SUM(sme.Influencer_Reach) as TotalInfluencerReach,
        -- Calculate engagement rate
        CASE 
            WHEN COUNT(*) > 0 
            THEN (COUNT(CASE WHEN sme.Sentiment_Category = 'Positive' THEN 1 END) * 100.0) / COUNT(*)
            ELSE 0 
        END as PositiveEngagementRate
    FROM Media.Content_Master cm
    INNER JOIN Media.Social_Media_Engagement sme ON cm.ContentID = sme.ContentID
    LEFT JOIN REF.Genres g ON cm.GenreID = g.GenreID
    WHERE sme.Engagement_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR cm.ContentID = @ContentID)
      AND (@PlatformName IS NULL OR sme.Platform_Name = @PlatformName)
    GROUP BY cm.ContentID, cm.Title, g.GenreName, sme.Platform_Name
    ORDER BY TotalEngagement DESC;
    
    -- Trending hashtags analysis
    SELECT TOP 20
        sme.Hashtags,
        COUNT(*) as HashtagCount,
        SUM(sme.Engagement_Count) as TotalEngagement,
        AVG(sme.Sentiment_Score) as AvgSentiment,
        COUNT(DISTINCT sme.ContentID) as UniqueContent
    FROM Media.Social_Media_Engagement sme
    WHERE sme.Engagement_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR sme.ContentID = @ContentID)
      AND (@PlatformName IS NULL OR sme.Platform_Name = @PlatformName)
      AND sme.Hashtags IS NOT NULL
    GROUP BY sme.Hashtags
    ORDER BY TotalEngagement DESC;
    
    -- Sentiment trends over time
    SELECT 
        sme.Engagement_Date,
        sme.Platform_Name,
        AVG(sme.Sentiment_Score) as AvgSentimentScore,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Positive' THEN 1 END) as PositiveCount,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Negative' THEN 1 END) as NegativeCount,
        COUNT(CASE WHEN sme.Sentiment_Category = 'Neutral' THEN 1 END) as NeutralCount,
        SUM(sme.Engagement_Count) as DailyEngagement
    FROM Media.Social_Media_Engagement sme
    WHERE sme.Engagement_Date BETWEEN @StartDate AND @EndDate
      AND (@ContentID IS NULL OR sme.ContentID = @ContentID)
      AND (@PlatformName IS NULL OR sme.Platform_Name = @PlatformName)
    GROUP BY sme.Engagement_Date, sme.Platform_Name
    ORDER BY sme.Engagement_Date, sme.Platform_Name;
    
    PRINT 'Social media engagement analysis completed successfully.';
END;
GO

-- =============================================
-- Data Quality and Monitoring Procedures
-- =============================================

-- Procedure: Monitor Data Quality
CREATE OR ALTER PROCEDURE Media.sp_MonitorDataQuality
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CheckDate DATETIME2 = GETDATE();
    
    -- Check for missing content metadata
    INSERT INTO LOG.Data_Quality_Log (Table_Name, Quality_Rule, Rule_Type, Records_Checked, Records_Failed, Check_Date)
    SELECT 
        'Media.Content_Master',
        'Title should not be null or empty',
        'Completeness',
        COUNT(*),
        COUNT(CASE WHEN Title IS NULL OR Title = '' THEN 1 END),
        @CheckDate
    FROM Media.Content_Master;
    
    -- Check for invalid ratings
    INSERT INTO LOG.Data_Quality_Log (Table_Name, Column_Name, Quality_Rule, Rule_Type, Records_Checked, Records_Failed, Check_Date)
    SELECT 
        'Media.Content_Consumption',
        'User_Rating',
        'User rating should be between 1 and 5',
        'Validity',
        COUNT(*),
        COUNT(CASE WHEN User_Rating < 1 OR User_Rating > 5 THEN 1 END),
        @CheckDate
    FROM Media.Content_Consumption
    WHERE User_Rating IS NOT NULL;
    
    -- Check for negative watch duration
    INSERT INTO LOG.Data_Quality_Log (Table_Name, Column_Name, Quality_Rule, Rule_Type, Records_Checked, Records_Failed, Check_Date)
    SELECT 
        'Media.Content_Consumption',
        'Watch_Duration_Minutes',
        'Watch duration should be positive',
        'Validity',
        COUNT(*),
        COUNT(CASE WHEN Watch_Duration_Minutes < 0 THEN 1 END),
        @CheckDate
    FROM Media.Content_Consumption;
    
    -- Check for completion percentage consistency
    INSERT INTO LOG.Data_Quality_Log (Table_Name, Column_Name, Quality_Rule, Rule_Type, Records_Checked, Records_Failed, Check_Date)
    SELECT 
        'Media.Content_Consumption',
        'Completion_Percentage',
        'Completion percentage should be between 0 and 100',
        'Validity',
        COUNT(*),
        COUNT(CASE WHEN Completion_Percentage < 0 OR Completion_Percentage > 100 THEN 1 END),
        @CheckDate
    FROM Media.Content_Consumption;
    
    -- Return data quality summary
    SELECT 
        Table_Name,
        Column_Name,
        Quality_Rule,
        Rule_Type,
        Records_Checked,
        Records_Failed,
        CASE 
            WHEN Records_Checked > 0 
            THEN (Records_Failed * 100.0) / Records_Checked 
            ELSE 0 
        END as Failure_Rate,
        CASE 
            WHEN Records_Checked > 0 
            THEN 100 - ((Records_Failed * 100.0) / Records_Checked)
            ELSE 100 
        END as Quality_Score
    FROM LOG.Data_Quality_Log
    WHERE Check_Date >= DATEADD(HOUR, -1, GETDATE())
    ORDER BY Failure_Rate DESC;
    
    PRINT 'Data quality monitoring completed successfully.';
END;
GO

-- =============================================
-- Performance Optimization Procedures
-- =============================================

-- Procedure: Update Statistics and Rebuild Indexes
CREATE OR ALTER PROCEDURE Media.sp_OptimizePerformance
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    -- Update statistics on key tables
    UPDATE STATISTICS Media.Content_Master;
    UPDATE STATISTICS Media.Content_Consumption;
    UPDATE STATISTICS Media.Content_Performance;
    UPDATE STATISTICS Media.Revenue_Analytics;
    UPDATE STATISTICS Media.Social_Media_Engagement;
    
    -- Rebuild fragmented indexes
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE index_cursor CURSOR FOR
    SELECT 
        'ALTER INDEX ' + i.name + ' ON ' + SCHEMA_NAME(t.schema_id) + '.' + t.name + ' REBUILD;'
    FROM sys.indexes i
    INNER JOIN sys.tables t ON i.object_id = t.object_id
    INNER JOIN sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps 
        ON i.object_id = ps.object_id AND i.index_id = ps.index_id
    WHERE ps.avg_fragmentation_in_percent > 30
      AND i.index_id > 0
      AND SCHEMA_NAME(t.schema_id) IN ('Media', 'REF');
    
    OPEN index_cursor;
    FETCH NEXT FROM index_cursor INTO @SQL;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_executesql @SQL;
        FETCH NEXT FROM index_cursor INTO @SQL;
    END;
    
    CLOSE index_cursor;
    DEALLOCATE index_cursor;
    
    -- Log the optimization process
    INSERT INTO LOG.ETL_Process_Log (Process_Name, Start_Time, End_Time, Status)
    VALUES ('Performance Optimization', @StartTime, GETDATE(), 'Success');
    
    PRINT 'Performance optimization completed successfully.';
END;
GO

PRINT 'Advanced stored procedures for Media Entertainment Analytics created successfully!';
PRINT 'Procedures include:';
PRINT '- Content performance metrics calculation';
PRINT '- Content recommendation generation';
PRINT '- Audience engagement analysis';
PRINT '- Audience segmentation';
PRINT '- Revenue performance metrics';
PRINT '- Social media engagement analysis';
PRINT '- Data quality monitoring';
PRINT '- Performance optimization';
GO