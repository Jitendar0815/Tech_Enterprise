using System;
using System.Data;
using System.Data.SqlClient;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using Microsoft.SqlServer.Dts.Pipeline.Wrapper;
using Microsoft.SqlServer.Dts.Runtime.Wrapper;

namespace MediaEntertainmentAnalytics.Components
{
    /// <summary>
    /// Advanced Content Analytics Engine for Media Entertainment SSIS Platform
    /// Handles content performance analysis, audience engagement, and recommendation algorithms
    /// </summary>
    public class ContentAnalyticsEngine : IDTSComponentMetaData100
    {
        private IDTSComponentMetaData100 componentMetaData;
        private IDTSVirtualInput100 virtualInput;
        private IDTSOutput100 output;

        public ContentAnalyticsEngine()
        {
            // Initialize component
        }

        /// <summary>
        /// Content Performance Analyzer for comprehensive content metrics
        /// </summary>
        public class ContentPerformanceAnalyzer
        {
            private readonly string connectionString;

            public ContentPerformanceAnalyzer(string connString)
            {
                connectionString = connString;
            }

            public ContentPerformanceResult AnalyzeContentPerformance(long contentId, DateTime analysisDate)
            {
                var result = new ContentPerformanceResult
                {
                    ContentID = contentId,
                    AnalysisDate = analysisDate,
                    PerformanceMetrics = new ContentMetrics(),
                    AudienceInsights = new List<AudienceInsight>(),
                    RevenueAnalysis = new RevenueMetrics(),
                    SocialEngagement = new SocialMetrics(),
                    Recommendations = new List<string>()
                };

                try
                {
                    using (var connection = new SqlConnection(connectionString))
                    {
                        connection.Open();
                        
                        // Analyze core performance metrics
                        AnalyzeCoreMetrics(connection, contentId, analysisDate, result);
                        
                        // Analyze audience engagement patterns
                        AnalyzeAudienceEngagement(connection, contentId, analysisDate, result);
                        
                        // Analyze revenue performance
                        AnalyzeRevenuePerformance(connection, contentId, analysisDate, result);
                        
                        // Analyze social media engagement
                        AnalyzeSocialEngagement(connection, contentId, analysisDate, result);
                        
                        // Generate performance insights and recommendations
                        GenerateInsightsAndRecommendations(result);
                        
                        // Calculate overall performance score
                        CalculateOverallPerformanceScore(result);
                    }
                }
                catch (Exception ex)
                {
                    result.ErrorMessage = ex.Message;
                }

                return result;
            }

            private void AnalyzeCoreMetrics(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        SUM(cp.Total_Views) as TotalViews,
                        AVG(cp.Average_Watch_Time_Minutes) as AvgWatchTime,
                        AVG(cp.Completion_Rate) as CompletionRate,
                        AVG(cp.Engagement_Rate) as EngagementRate,
                        AVG(cp.Retention_Rate) as RetentionRate,
                        AVG(cp.Average_Rating) as AverageRating,
                        SUM(cp.Social_Shares) as TotalShares,
                        SUM(cp.Comments_Count) as TotalComments,
                        SUM(cp.Likes_Count) as TotalLikes,
                        COUNT(DISTINCT cp.PlatformTypeID) as PlatformCount,
                        MAX(cp.Trending_Score) as MaxTrendingScore
                    FROM Media.Content_Performance cp
                    WHERE cp.ContentID = @ContentID 
                      AND cp.Metric_Date <= @AnalysisDate
                      AND cp.Metric_Date >= @StartDate";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            result.PerformanceMetrics = new ContentMetrics
                            {
                                TotalViews = reader.IsDBNull("TotalViews") ? 0 : reader.GetInt64("TotalViews"),
                                AverageWatchTime = reader.IsDBNull("AvgWatchTime") ? 0 : reader.GetDouble("AvgWatchTime"),
                                CompletionRate = reader.IsDBNull("CompletionRate") ? 0 : reader.GetDouble("CompletionRate"),
                                EngagementRate = reader.IsDBNull("EngagementRate") ? 0 : reader.GetDouble("EngagementRate"),
                                RetentionRate = reader.IsDBNull("RetentionRate") ? 0 : reader.GetDouble("RetentionRate"),
                                AverageRating = reader.IsDBNull("AverageRating") ? 0 : reader.GetDouble("AverageRating"),
                                TotalShares = reader.IsDBNull("TotalShares") ? 0 : reader.GetInt32("TotalShares"),
                                TotalComments = reader.IsDBNull("TotalComments") ? 0 : reader.GetInt32("TotalComments"),
                                TotalLikes = reader.IsDBNull("TotalLikes") ? 0 : reader.GetInt32("TotalLikes"),
                                PlatformCount = reader.IsDBNull("PlatformCount") ? 0 : reader.GetInt32("PlatformCount"),
                                TrendingScore = reader.IsDBNull("MaxTrendingScore") ? 0 : reader.GetDouble("MaxTrendingScore")
                            };
                        }
                    }
                }

                // Calculate view velocity and growth trends
                CalculateViewVelocity(connection, contentId, analysisDate, result);
            }

            private void AnalyzeAudienceEngagement(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        d.AgeGroup,
                        d.Gender,
                        d.Geographic_Region,
                        COUNT(DISTINCT cc.AudienceID) as UniqueViewers,
                        AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration,
                        AVG(cc.Completion_Percentage) as AvgCompletionRate,
                        AVG(cc.Engagement_Score) as AvgEngagementScore,
                        AVG(cc.User_Rating) as AvgUserRating
                    FROM Media.Content_Consumption cc
                    INNER JOIN Media.Audience_Master am ON cc.AudienceID = am.AudienceID
                    LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
                    WHERE cc.ContentID = @ContentID 
                      AND cc.Session_Start_Time <= @AnalysisDate
                      AND cc.Session_Start_Time >= @StartDate
                    GROUP BY d.AgeGroup, d.Gender, d.Geographic_Region
                    HAVING COUNT(DISTINCT cc.AudienceID) >= 10
                    ORDER BY UniqueViewers DESC";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            result.AudienceInsights.Add(new AudienceInsight
                            {
                                AgeGroup = reader.IsDBNull("AgeGroup") ? "Unknown" : reader.GetString("AgeGroup"),
                                Gender = reader.IsDBNull("Gender") ? "Unknown" : reader.GetString("Gender"),
                                GeographicRegion = reader.IsDBNull("Geographic_Region") ? "Unknown" : reader.GetString("Geographic_Region"),
                                UniqueViewers = reader.GetInt32("UniqueViewers"),
                                AverageWatchDuration = reader.IsDBNull("AvgWatchDuration") ? 0 : reader.GetDouble("AvgWatchDuration"),
                                AverageCompletionRate = reader.IsDBNull("AvgCompletionRate") ? 0 : reader.GetDouble("AvgCompletionRate"),
                                AverageEngagementScore = reader.IsDBNull("AvgEngagementScore") ? 0 : reader.GetDouble("AvgEngagementScore"),
                                AverageUserRating = reader.IsDBNull("AvgUserRating") ? 0 : reader.GetDouble("AvgUserRating")
                            });
                        }
                    }
                }

                // Analyze viewing patterns and behavior
                AnalyzeViewingPatterns(connection, contentId, analysisDate, result);
            }

            private void AnalyzeRevenuePerformance(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        SUM(ra.Gross_Revenue) as TotalGrossRevenue,
                        SUM(ra.Net_Revenue) as TotalNetRevenue,
                        AVG(ra.Profit_Margin) as AvgProfitMargin,
                        SUM(ra.Marketing_Cost) as TotalMarketingCost,
                        COUNT(DISTINCT ra.PlatformTypeID) as RevenuePlatforms,
                        SUM(CASE WHEN ra.Revenue_Type = 'Subscription' THEN ra.Gross_Revenue ELSE 0 END) as SubscriptionRevenue,
                        SUM(CASE WHEN ra.Revenue_Type = 'Advertisement' THEN ra.Gross_Revenue ELSE 0 END) as AdRevenue,
                        SUM(CASE WHEN ra.Revenue_Type = 'Pay-Per-View' THEN ra.Gross_Revenue ELSE 0 END) as PPVRevenue,
                        SUM(CASE WHEN ra.Revenue_Type = 'Licensing' THEN ra.Gross_Revenue ELSE 0 END) as LicensingRevenue
                    FROM Media.Revenue_Analytics ra
                    WHERE ra.ContentID = @ContentID 
                      AND ra.Revenue_Date <= @AnalysisDate
                      AND ra.Revenue_Date >= @StartDate";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        if (reader.Read())
                        {
                            result.RevenueAnalysis = new RevenueMetrics
                            {
                                TotalGrossRevenue = reader.IsDBNull("TotalGrossRevenue") ? 0 : reader.GetDecimal("TotalGrossRevenue"),
                                TotalNetRevenue = reader.IsDBNull("TotalNetRevenue") ? 0 : reader.GetDecimal("TotalNetRevenue"),
                                AverageProfitMargin = reader.IsDBNull("AvgProfitMargin") ? 0 : reader.GetDecimal("AvgProfitMargin"),
                                TotalMarketingCost = reader.IsDBNull("TotalMarketingCost") ? 0 : reader.GetDecimal("TotalMarketingCost"),
                                RevenuePlatforms = reader.IsDBNull("RevenuePlatforms") ? 0 : reader.GetInt32("RevenuePlatforms"),
                                SubscriptionRevenue = reader.IsDBNull("SubscriptionRevenue") ? 0 : reader.GetDecimal("SubscriptionRevenue"),
                                AdvertisementRevenue = reader.IsDBNull("AdRevenue") ? 0 : reader.GetDecimal("AdRevenue"),
                                PayPerViewRevenue = reader.IsDBNull("PPVRevenue") ? 0 : reader.GetDecimal("PPVRevenue"),
                                LicensingRevenue = reader.IsDBNull("LicensingRevenue") ? 0 : reader.GetDecimal("LicensingRevenue")
                            };

                            // Calculate revenue per view
                            if (result.PerformanceMetrics.TotalViews > 0)
                            {
                                result.RevenueAnalysis.RevenuePerView = result.RevenueAnalysis.TotalGrossRevenue / result.PerformanceMetrics.TotalViews;
                            }
                        }
                    }
                }
            }

            private void AnalyzeSocialEngagement(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        sme.Platform_Name,
                        SUM(sme.Engagement_Count) as TotalEngagement,
                        AVG(sme.Sentiment_Score) as AvgSentimentScore,
                        COUNT(CASE WHEN sme.Sentiment_Category = 'Positive' THEN 1 END) as PositiveEngagements,
                        COUNT(CASE WHEN sme.Sentiment_Category = 'Negative' THEN 1 END) as NegativeEngagements,
                        COUNT(CASE WHEN sme.Sentiment_Category = 'Neutral' THEN 1 END) as NeutralEngagements,
                        SUM(sme.Influencer_Reach) as TotalInfluencerReach
                    FROM Media.Social_Media_Engagement sme
                    WHERE sme.ContentID = @ContentID 
                      AND sme.Engagement_Date <= @AnalysisDate
                      AND sme.Engagement_Date >= @StartDate
                    GROUP BY sme.Platform_Name";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        var totalEngagement = 0;
                        var totalSentiment = 0.0;
                        var totalInfluencerReach = 0;
                        var platformCount = 0;

                        while (reader.Read())
                        {
                            platformCount++;
                            var engagement = reader.GetInt32("TotalEngagement");
                            var sentiment = reader.IsDBNull("AvgSentimentScore") ? 0 : reader.GetDouble("AvgSentimentScore");
                            var influencerReach = reader.IsDBNull("TotalInfluencerReach") ? 0 : reader.GetInt32("TotalInfluencerReach");

                            totalEngagement += engagement;
                            totalSentiment += sentiment;
                            totalInfluencerReach += influencerReach;
                        }

                        result.SocialEngagement = new SocialMetrics
                        {
                            TotalEngagement = totalEngagement,
                            AverageSentimentScore = platformCount > 0 ? totalSentiment / platformCount : 0,
                            TotalInfluencerReach = totalInfluencerReach,
                            PlatformCount = platformCount
                        };
                    }
                }

                // Analyze trending hashtags and mentions
                AnalyzeTrendingContent(connection, contentId, analysisDate, result);
            }

            private void CalculateViewVelocity(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        cp.Metric_Date,
                        cp.Total_Views
                    FROM Media.Content_Performance cp
                    WHERE cp.ContentID = @ContentID 
                      AND cp.Metric_Date <= @AnalysisDate
                      AND cp.Metric_Date >= @StartDate
                    ORDER BY cp.Metric_Date";

                var dailyViews = new List<DailyViewData>();

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            dailyViews.Add(new DailyViewData
                            {
                                Date = reader.GetDateTime("Metric_Date"),
                                Views = reader.GetInt64("Total_Views")
                            });
                        }
                    }
                }

                if (dailyViews.Count >= 7)
                {
                    // Calculate 7-day moving average and growth rate
                    var recentWeek = dailyViews.TakeLast(7).ToList();
                    var previousWeek = dailyViews.Skip(Math.Max(0, dailyViews.Count - 14)).Take(7).ToList();

                    var recentAvg = recentWeek.Average(d => d.Views);
                    var previousAvg = previousWeek.Any() ? previousWeek.Average(d => d.Views) : recentAvg;

                    result.PerformanceMetrics.ViewVelocity = recentAvg;
                    result.PerformanceMetrics.GrowthRate = previousAvg > 0 ? ((recentAvg - previousAvg) / previousAvg) * 100 : 0;
                }
            }

            private void AnalyzeViewingPatterns(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT 
                        DATEPART(HOUR, cc.Session_Start_Time) as ViewingHour,
                        DATEPART(WEEKDAY, cc.Session_Start_Time) as ViewingDayOfWeek,
                        COUNT(*) as SessionCount,
                        AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration
                    FROM Media.Content_Consumption cc
                    WHERE cc.ContentID = @ContentID 
                      AND cc.Session_Start_Time <= @AnalysisDate
                      AND cc.Session_Start_Time >= @StartDate
                    GROUP BY DATEPART(HOUR, cc.Session_Start_Time), DATEPART(WEEKDAY, cc.Session_Start_Time)
                    ORDER BY SessionCount DESC";

                var viewingPatterns = new List<ViewingPattern>();

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            viewingPatterns.Add(new ViewingPattern
                            {
                                Hour = reader.GetInt32("ViewingHour"),
                                DayOfWeek = reader.GetInt32("ViewingDayOfWeek"),
                                SessionCount = reader.GetInt32("SessionCount"),
                                AverageWatchDuration = reader.IsDBNull("AvgWatchDuration") ? 0 : reader.GetDouble("AvgWatchDuration")
                            });
                        }
                    }
                }

                // Identify peak viewing times
                if (viewingPatterns.Any())
                {
                    var peakHour = viewingPatterns.OrderByDescending(p => p.SessionCount).First();
                    result.PerformanceMetrics.PeakViewingHour = peakHour.Hour;
                    result.PerformanceMetrics.PeakViewingDay = peakHour.DayOfWeek;
                }
            }

            private void AnalyzeTrendingContent(SqlConnection connection, long contentId, DateTime analysisDate, ContentPerformanceResult result)
            {
                var query = @"
                    SELECT TOP 10
                        sme.Hashtags,
                        COUNT(*) as HashtagCount
                    FROM Media.Social_Media_Engagement sme
                    WHERE sme.ContentID = @ContentID 
                      AND sme.Engagement_Date <= @AnalysisDate
                      AND sme.Engagement_Date >= @StartDate
                      AND sme.Hashtags IS NOT NULL
                    GROUP BY sme.Hashtags
                    ORDER BY HashtagCount DESC";

                var trendingHashtags = new List<string>();

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@ContentID", contentId);
                    command.Parameters.AddWithValue("@AnalysisDate", analysisDate);
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-7));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            trendingHashtags.Add(reader.GetString("Hashtags"));
                        }
                    }
                }

                result.SocialEngagement.TrendingHashtags = trendingHashtags;
            }

            private void GenerateInsightsAndRecommendations(ContentPerformanceResult result)
            {
                var recommendations = new List<string>();

                // Completion rate analysis
                if (result.PerformanceMetrics.CompletionRate < 50)
                {
                    recommendations.Add("Low completion rate detected. Consider analyzing content pacing and engagement points.");
                }
                else if (result.PerformanceMetrics.CompletionRate > 80)
                {
                    recommendations.Add("Excellent completion rate. Consider creating similar content or extending the series.");
                }

                // Engagement analysis
                if (result.PerformanceMetrics.EngagementRate < 30)
                {
                    recommendations.Add("Low engagement rate. Consider improving content interactivity and call-to-actions.");
                }

                // Revenue analysis
                if (result.RevenueAnalysis.RevenuePerView < 0.01m)
                {
                    recommendations.Add("Low revenue per view. Consider optimizing monetization strategy or targeting higher-value audiences.");
                }

                // Social sentiment analysis
                if (result.SocialEngagement.AverageSentimentScore < 0)
                {
                    recommendations.Add("Negative social sentiment detected. Consider addressing audience concerns and improving content quality.");
                }
                else if (result.SocialEngagement.AverageSentimentScore > 0.5)
                {
                    recommendations.Add("Positive social sentiment. Leverage this momentum for marketing and promotion campaigns.");
                }

                // Growth analysis
                if (result.PerformanceMetrics.GrowthRate < -10)
                {
                    recommendations.Add("Declining viewership trend. Consider refreshing content strategy or re-marketing campaign.");
                }
                else if (result.PerformanceMetrics.GrowthRate > 20)
                {
                    recommendations.Add("Strong growth trend. Consider increasing content production or expanding to new platforms.");
                }

                // Audience diversity analysis
                if (result.AudienceInsights.Count < 3)
                {
                    recommendations.Add("Limited audience diversity. Consider targeting broader demographics or different geographic regions.");
                }

                result.Recommendations = recommendations;
            }

            private void CalculateOverallPerformanceScore(ContentPerformanceResult result)
            {
                var score = 0.0;

                // Views score (0-25 points)
                if (result.PerformanceMetrics.TotalViews > 1000000) score += 25;
                else if (result.PerformanceMetrics.TotalViews > 100000) score += 20;
                else if (result.PerformanceMetrics.TotalViews > 10000) score += 15;
                else if (result.PerformanceMetrics.TotalViews > 1000) score += 10;
                else score += 5;

                // Engagement score (0-25 points)
                score += Math.Min(25, result.PerformanceMetrics.EngagementRate * 0.25);

                // Completion rate score (0-20 points)
                score += Math.Min(20, result.PerformanceMetrics.CompletionRate * 0.2);

                // Revenue score (0-15 points)
                if (result.RevenueAnalysis.TotalGrossRevenue > 100000) score += 15;
                else if (result.RevenueAnalysis.TotalGrossRevenue > 10000) score += 12;
                else if (result.RevenueAnalysis.TotalGrossRevenue > 1000) score += 8;
                else score += 3;

                // Social engagement score (0-10 points)
                if (result.SocialEngagement.AverageSentimentScore > 0.5) score += 10;
                else if (result.SocialEngagement.AverageSentimentScore > 0) score += 7;
                else if (result.SocialEngagement.AverageSentimentScore > -0.5) score += 3;

                // Growth rate score (0-5 points)
                if (result.PerformanceMetrics.GrowthRate > 20) score += 5;
                else if (result.PerformanceMetrics.GrowthRate > 0) score += 3;
                else if (result.PerformanceMetrics.GrowthRate > -10) score += 1;

                result.OverallPerformanceScore = Math.Min(100, score);
            }
        }

        /// <summary>
        /// Audience Segmentation Engine for targeted content strategies
        /// </summary>
        public class AudienceSegmentationEngine
        {
            private readonly string connectionString;

            public AudienceSegmentationEngine(string connString)
            {
                connectionString = connString;
            }

            public List<AudienceSegment> GenerateAudienceSegments(DateTime analysisDate)
            {
                var segments = new List<AudienceSegment>();

                try
                {
                    using (var connection = new SqlConnection(connectionString))
                    {
                        connection.Open();
                        
                        // Generate behavioral segments
                        segments.AddRange(GenerateBehavioralSegments(connection, analysisDate));
                        
                        // Generate demographic segments
                        segments.AddRange(GenerateDemographicSegments(connection, analysisDate));
                        
                        // Generate engagement-based segments
                        segments.AddRange(GenerateEngagementSegments(connection, analysisDate));
                        
                        // Generate value-based segments
                        segments.AddRange(GenerateValueSegments(connection, analysisDate));
                    }
                }
                catch (Exception ex)
                {
                    // Log error
                }

                return segments;
            }

            private List<AudienceSegment> GenerateBehavioralSegments(SqlConnection connection, DateTime analysisDate)
            {
                var segments = new List<AudienceSegment>();

                var query = @"
                    SELECT 
                        am.AudienceID,
                        COUNT(DISTINCT cc.ContentID) as UniqueContentWatched,
                        AVG(cc.Watch_Duration_Minutes) as AvgWatchDuration,
                        AVG(cc.Completion_Percentage) as AvgCompletionRate,
                        COUNT(cc.ConsumptionID) as TotalSessions,
                        MAX(cc.Session_Start_Time) as LastActivity
                    FROM Media.Audience_Master am
                    LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
                    WHERE cc.Session_Start_Time >= @StartDate
                    GROUP BY am.AudienceID
                    HAVING COUNT(cc.ConsumptionID) > 0";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-90));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var audienceId = reader.GetInt64("AudienceID");
                            var uniqueContent = reader.GetInt32("UniqueContentWatched");
                            var avgWatchDuration = reader.IsDBNull("AvgWatchDuration") ? 0 : reader.GetDouble("AvgWatchDuration");
                            var avgCompletionRate = reader.IsDBNull("AvgCompletionRate") ? 0 : reader.GetDouble("AvgCompletionRate");
                            var totalSessions = reader.GetInt32("TotalSessions");
                            var lastActivity = reader.GetDateTime("LastActivity");

                            var segmentName = DetermineBehavioralSegment(uniqueContent, avgWatchDuration, avgCompletionRate, totalSessions, lastActivity, analysisDate);
                            
                            segments.Add(new AudienceSegment
                            {
                                AudienceID = audienceId,
                                SegmentName = segmentName,
                                SegmentCategory = "Behavioral",
                                SegmentCriteria = $"Content: {uniqueContent}, Duration: {avgWatchDuration:F1}min, Completion: {avgCompletionRate:F1}%",
                                EngagementLevel = DetermineEngagementLevel(totalSessions, avgCompletionRate),
                                SegmentDate = analysisDate
                            });
                        }
                    }
                }

                return segments;
            }

            private List<AudienceSegment> GenerateDemographicSegments(SqlConnection connection, DateTime analysisDate)
            {
                var segments = new List<AudienceSegment>();

                var query = @"
                    SELECT 
                        am.AudienceID,
                        d.AgeGroup,
                        d.Gender,
                        d.Geographic_Region,
                        d.Income_Range,
                        d.Education_Level
                    FROM Media.Audience_Master am
                    LEFT JOIN REF.Demographics d ON am.DemographicID = d.DemographicID
                    WHERE am.Is_Active = 1";

                using (var command = new SqlCommand(query, connection))
                {
                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var audienceId = reader.GetInt64("AudienceID");
                            var ageGroup = reader.IsDBNull("AgeGroup") ? "Unknown" : reader.GetString("AgeGroup");
                            var gender = reader.IsDBNull("Gender") ? "Unknown" : reader.GetString("Gender");
                            var region = reader.IsDBNull("Geographic_Region") ? "Unknown" : reader.GetString("Geographic_Region");
                            var income = reader.IsDBNull("Income_Range") ? "Unknown" : reader.GetString("Income_Range");
                            var education = reader.IsDBNull("Education_Level") ? "Unknown" : reader.GetString("Education_Level");

                            var segmentName = $"{ageGroup}_{gender}_{region}";
                            
                            segments.Add(new AudienceSegment
                            {
                                AudienceID = audienceId,
                                SegmentName = segmentName,
                                SegmentCategory = "Demographic",
                                SegmentCriteria = $"Age: {ageGroup}, Gender: {gender}, Region: {region}, Income: {income}, Education: {education}",
                                SegmentDate = analysisDate
                            });
                        }
                    }
                }

                return segments;
            }

            private List<AudienceSegment> GenerateEngagementSegments(SqlConnection connection, DateTime analysisDate)
            {
                var segments = new List<AudienceSegment>();

                var query = @"
                    SELECT 
                        am.AudienceID,
                        AVG(cc.Engagement_Score) as AvgEngagementScore,
                        COUNT(cc.ConsumptionID) as TotalSessions,
                        AVG(cc.User_Rating) as AvgUserRating,
                        SUM(CASE WHEN cc.User_Rating >= 4 THEN 1 ELSE 0 END) as HighRatings
                    FROM Media.Audience_Master am
                    LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
                    WHERE cc.Session_Start_Time >= @StartDate
                    GROUP BY am.AudienceID
                    HAVING COUNT(cc.ConsumptionID) >= 5";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-30));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var audienceId = reader.GetInt64("AudienceID");
                            var avgEngagementScore = reader.IsDBNull("AvgEngagementScore") ? 0 : reader.GetDouble("AvgEngagementScore");
                            var totalSessions = reader.GetInt32("TotalSessions");
                            var avgUserRating = reader.IsDBNull("AvgUserRating") ? 0 : reader.GetDouble("AvgUserRating");
                            var highRatings = reader.GetInt32("HighRatings");

                            var engagementLevel = DetermineEngagementLevel(totalSessions, avgEngagementScore);
                            var segmentName = $"{engagementLevel}_Engagement";
                            
                            segments.Add(new AudienceSegment
                            {
                                AudienceID = audienceId,
                                SegmentName = segmentName,
                                SegmentCategory = "Engagement",
                                SegmentCriteria = $"Engagement Score: {avgEngagementScore:F1}, Sessions: {totalSessions}, Avg Rating: {avgUserRating:F1}",
                                EngagementLevel = engagementLevel,
                                SegmentDate = analysisDate
                            });
                        }
                    }
                }

                return segments;
            }

            private List<AudienceSegment> GenerateValueSegments(SqlConnection connection, DateTime analysisDate)
            {
                var segments = new List<AudienceSegment>();

                // This would typically integrate with revenue/subscription data
                // For now, we'll use engagement as a proxy for value

                var query = @"
                    SELECT 
                        am.AudienceID,
                        am.Subscription_Type,
                        DATEDIFF(DAY, am.Subscription_Start_Date, GETDATE()) as SubscriptionDays,
                        COUNT(cc.ConsumptionID) as TotalSessions,
                        SUM(cc.Watch_Duration_Minutes) as TotalWatchTime
                    FROM Media.Audience_Master am
                    LEFT JOIN Media.Content_Consumption cc ON am.AudienceID = cc.AudienceID
                    WHERE am.Is_Active = 1
                      AND cc.Session_Start_Time >= @StartDate
                    GROUP BY am.AudienceID, am.Subscription_Type, am.Subscription_Start_Date";

                using (var command = new SqlCommand(query, connection))
                {
                    command.Parameters.AddWithValue("@StartDate", analysisDate.AddDays(-90));

                    using (var reader = command.ExecuteReader())
                    {
                        while (reader.Read())
                        {
                            var audienceId = reader.GetInt64("AudienceID");
                            var subscriptionType = reader.IsDBNull("Subscription_Type") ? "Free" : reader.GetString("Subscription_Type");
                            var subscriptionDays = reader.IsDBNull("SubscriptionDays") ? 0 : reader.GetInt32("SubscriptionDays");
                            var totalSessions = reader.GetInt32("TotalSessions");
                            var totalWatchTime = reader.IsDBNull("TotalWatchTime") ? 0 : reader.GetInt32("TotalWatchTime");

                            var valueSegment = DetermineValueSegment(subscriptionType, subscriptionDays, totalSessions, totalWatchTime);
                            
                            segments.Add(new AudienceSegment
                            {
                                AudienceID = audienceId,
                                SegmentName = valueSegment,
                                SegmentCategory = "Value",
                                SegmentCriteria = $"Subscription: {subscriptionType}, Days: {subscriptionDays}, Sessions: {totalSessions}, Watch Time: {totalWatchTime}min",
                                SegmentDate = analysisDate
                            });
                        }
                    }
                }

                return segments;
            }

            private string DetermineBehavioralSegment(int uniqueContent, double avgWatchDuration, double avgCompletionRate, int totalSessions, DateTime lastActivity, DateTime analysisDate)
            {
                var daysSinceLastActivity = (analysisDate - lastActivity).Days;

                if (daysSinceLastActivity > 30)
                    return "Inactive";
                
                if (totalSessions >= 50 && avgCompletionRate >= 80)
                    return "Power User";
                
                if (totalSessions >= 20 && avgCompletionRate >= 60)
                    return "Regular Viewer";
                
                if (uniqueContent >= 20 && avgWatchDuration >= 30)
                    return "Content Explorer";
                
                if (avgCompletionRate < 30)
                    return "Browser";
                
                return "Casual Viewer";
            }

            private string DetermineEngagementLevel(int totalSessions, double engagementScore)
            {
                if (totalSessions >= 30 && engagementScore >= 80)
                    return "High";
                
                if (totalSessions >= 10 && engagementScore >= 50)
                    return "Medium";
                
                return "Low";
            }

            private string DetermineValueSegment(string subscriptionType, int subscriptionDays, int totalSessions, int totalWatchTime)
            {
                if (subscriptionType.Contains("Premium") && subscriptionDays >= 365 && totalWatchTime >= 1000)
                    return "VIP Customer";
                
                if (subscriptionType.Contains("Premium") && totalSessions >= 20)
                    return "Premium User";
                
                if (subscriptionDays >= 180 && totalSessions >= 15)
                    return "Loyal Customer";
                
                if (totalSessions >= 10)
                    return "Active User";
                
                return "New User";
            }
        }
    }

    // Supporting data structures
    public class ContentPerformanceResult
    {
        public long ContentID { get; set; }
        public DateTime AnalysisDate { get; set; }
        public ContentMetrics PerformanceMetrics { get; set; }
        public List<AudienceInsight> AudienceInsights { get; set; }
        public RevenueMetrics RevenueAnalysis { get; set; }
        public SocialMetrics SocialEngagement { get; set; }
        public List<string> Recommendations { get; set; }
        public double OverallPerformanceScore { get; set; }
        public string ErrorMessage { get; set; }
    }

    public class ContentMetrics
    {
        public long TotalViews { get; set; }
        public double AverageWatchTime { get; set; }
        public double CompletionRate { get; set; }
        public double EngagementRate { get; set; }
        public double RetentionRate { get; set; }
        public double AverageRating { get; set; }
        public int TotalShares { get; set; }
        public int TotalComments { get; set; }
        public int TotalLikes { get; set; }
        public int PlatformCount { get; set; }
        public double TrendingScore { get; set; }
        public double ViewVelocity { get; set; }
        public double GrowthRate { get; set; }
        public int PeakViewingHour { get; set; }
        public int PeakViewingDay { get; set; }
    }

    public class AudienceInsight
    {
        public string AgeGroup { get; set; }
        public string Gender { get; set; }
        public string GeographicRegion { get; set; }
        public int UniqueViewers { get; set; }
        public double AverageWatchDuration { get; set; }
        public double AverageCompletionRate { get; set; }
        public double AverageEngagementScore { get; set; }
        public double AverageUserRating { get; set; }
    }

    public class RevenueMetrics
    {
        public decimal TotalGrossRevenue { get; set; }
        public decimal TotalNetRevenue { get; set; }
        public decimal AverageProfitMargin { get; set; }
        public decimal TotalMarketingCost { get; set; }
        public int RevenuePlatforms { get; set; }
        public decimal SubscriptionRevenue { get; set; }
        public decimal AdvertisementRevenue { get; set; }
        public decimal PayPerViewRevenue { get; set; }
        public decimal LicensingRevenue { get; set; }
        public decimal RevenuePerView { get; set; }
    }

    public class SocialMetrics
    {
        public int TotalEngagement { get; set; }
        public double AverageSentimentScore { get; set; }
        public int TotalInfluencerReach { get; set; }
        public int PlatformCount { get; set; }
        public List<string> TrendingHashtags { get; set; }
    }

    public class AudienceSegment
    {
        public long AudienceID { get; set; }
        public string SegmentName { get; set; }
        public string SegmentCategory { get; set; }
        public string SegmentCriteria { get; set; }
        public string EngagementLevel { get; set; }
        public DateTime SegmentDate { get; set; }
    }

    public class DailyViewData
    {
        public DateTime Date { get; set; }
        public long Views { get; set; }
    }

    public class ViewingPattern
    {
        public int Hour { get; set; }
        public int DayOfWeek { get; set; }
        public int SessionCount { get; set; }
        public double AverageWatchDuration { get; set; }
    }
}