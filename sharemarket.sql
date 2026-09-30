USE StockMarketDB;
GO

CREATE TABLE HistoricalBalanceSheet (
    RecordID INT,
    ShareCapital DECIMAL(15,2),
    Reserves DECIMAL(15,2),
    Borrowings DECIMAL(15,2),
    OtherLiabilities DECIMAL(15,2),
    TotalLiabilities DECIMAL(15,2),
    FixedAssets DECIMAL(15,2),
    CWIP DECIMAL(15,2),
    Investments DECIMAL(15,2),
    OtherAssets DECIMAL(15,2),
    TotalAssets DECIMAL(15,2),
    FinancialPeriod VARCHAR(20),
    ScripCode INT);
DROP TABLE HistoricalBalanceSheet;
SELECT TOP 10 * FROM HistoricalBalanceSheet;
DROP TABLE HistoricalBalanceSheet;
GO
CREATE TABLE HistoricalBalanceSheet (
    RecordID INT,
    ShareCapital DECIMAL(18,2),
    Reserves DECIMAL(18,2),
    Borrowings DECIMAL(18,2),
    OtherLiabilities DECIMAL(18,2),
    TotalLiabilities DECIMAL(18,2),
    FixedAssets DECIMAL(18,2),
    CWIP DECIMAL(18,2),
    Investments DECIMAL(18,2),
    OtherAssets DECIMAL(18,2),
    TotalAssets DECIMAL(18,2),
    Quarter10Yrs VARCHAR(20),
    ScripCode INT);
USE StockMarketDB;
GO

SELECT COUNT(*) AS TotalRows FROM HistoricalBalanceSheet;
GO

SELECT TOP 10 * FROM HistoricalBalanceSheet;
GO
USE StockMarketDB;
GO

WITH RankedBorrowers AS (
    SELECT 
        ScripCode,
        quarter_10yrs AS FinancialPeriod,
        Borrowings,
        Total_Assets AS TotalAssets,
        ROUND((CAST(Borrowings AS FLOAT) / NULLIF(Total_Assets, 0)) * 100, 2) AS DebtToAssetRatioPct,
        DENSE_RANK() OVER (PARTITION BY quarter_10yrs ORDER BY Borrowings DESC) AS DebtRank
    FROM HistoricalBalanceSheet
    WHERE Borrowings IS NOT NULL AND Total_Assets IS NOT NULL)
SELECT 
    ScripCode,
    FinancialPeriod,
    Borrowings,
    TotalAssets,
    DebtToAssetRatioPct
FROM RankedBorrowers
WHERE DebtRank <= 3
ORDER BY FinancialPeriod, DebtRank;
USE StockMarketDB;
GO
WITH BorrowingTrends AS (
    SELECT 
        ScripCode,
        quarter_10yrs AS FinancialPeriod,
        Borrowings AS CurrentBorrowings,
        LAG(Borrowings, 1) OVER (
            PARTITION BY ScripCode 
            ORDER BY quarter_10yrs
        ) AS PreviousBorrowings
    FROM HistoricalBalanceSheet
    WHERE Borrowings IS NOT NULL)
SELECT 
    ScripCode,
    FinancialPeriod,
    CurrentBorrowings,
    PreviousBorrowings,
    (CurrentBorrowings - PreviousBorrowings) AS BorrowingChange,
    ROUND(
        ((CAST(CurrentBorrowings AS FLOAT) - PreviousBorrowings) / NULLIF(PreviousBorrowings, 0)) * 100, 2
    ) AS YoY_Growth_Pct
FROM BorrowingTrends
WHERE PreviousBorrowings IS NOT NULL
ORDER BY ScripCode, FinancialPeriod;