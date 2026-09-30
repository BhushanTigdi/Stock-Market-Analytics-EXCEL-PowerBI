USE StockMarketDB;
GO

SELECT TOP 10 * FROM AdaniStockData;
GO
USE StockMarketDB;
GO

WITH StockCalculations AS (
    SELECT 
        CAST([Ticker] AS DATE) AS TradeDate,
        CAST([ADANIENT_NS4] AS FLOAT) AS ClosingPrice,
        -- Daily Return (%)
        ROUND(
            ((CAST([ADANIENT_NS4] AS FLOAT) - LAG(CAST([ADANIENT_NS4] AS FLOAT), 1) OVER (ORDER BY CAST([Ticker] AS DATE))) / 
            NULLIF(LAG(CAST([ADANIENT_NS4] AS FLOAT), 1) OVER (ORDER BY CAST([Ticker] AS DATE)), 0)) * 100, 2
        ) AS DailyReturnPct,
        -- 7-Day Simple Moving Average (SMA)
        ROUND(
            AVG(CAST([ADANIENT_NS4] AS FLOAT)) OVER (
                ORDER BY CAST([Ticker] AS DATE) 
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
            ), 2
        ) AS [7Day_SMA]
    FROM AdaniStockData
)
SELECT 
    TradeDate,
    ClosingPrice,
    DailyReturnPct,
    [7Day_SMA]
FROM StockCalculations
ORDER BY TradeDate DESC;
USE StockMarketDB;
GO

WITH DailyReturns AS (
    SELECT 
        CAST([Ticker] AS DATE) AS TradeDate,
        CAST([ADANIENT_NS4] AS FLOAT) AS ClosingPrice,
        ROUND(
            ((CAST([ADANIENT_NS4] AS FLOAT) - LAG(CAST([ADANIENT_NS4] AS FLOAT), 1) OVER (ORDER BY CAST([Ticker] AS DATE))) / 
            NULLIF(LAG(CAST([ADANIENT_NS4] AS FLOAT), 1) OVER (ORDER BY CAST([Ticker] AS DATE)), 0)) * 100, 2
        ) AS DailyReturnPct
    FROM AdaniStockData
)
SELECT 
    TradeDate,
    ClosingPrice,
    DailyReturnPct,
    -- 30-Day Moving Volatility (Standard Deviation)
    ROUND(
        STDEV(DailyReturnPct) OVER (
            ORDER BY TradeDate 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ), 2
    ) AS [30Day_Volatility_StdDev],
    -- Identify Major Price Movements (> 3% Gain or Loss)
    CASE 
        WHEN DailyReturnPct >= 3.0 THEN 'High Bullish Day (Gain > 3%)'
        WHEN DailyReturnPct <= -3.0 THEN 'High Bearish Day (Drop > 3%)'
        ELSE 'Normal Movement'
    END AS MarketSentiment
FROM DailyReturns
ORDER BY TradeDate DESC;