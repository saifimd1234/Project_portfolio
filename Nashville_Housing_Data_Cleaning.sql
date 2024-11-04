-- To get an overview of data.
SELECT *
FROM NashvilleHousing;

-- 1. Standardize Date Format
/*
SaleDate column initially had Datetime and the time does not serves any purpose.
So it is better to remove it.
*/
SELECT
	SaleDate,
	CONVERT(date, SaleDate) AS only_date
FROM NashvilleHousing;

-- below query does not works sometimes 
UPDATE NashvilleHousing
SET SaleDate=CONVERT(date, SaleDate);

/*
does not change the column data type of SaleDate to date. Instead, 
it updates the values in the SaleDate column by converting the existing 
values to the date data type. The CONVERT function is used here to 
convert each value in the SaleDate column to a date, but the underlying 
column type remains unchanged.
You can add a new column and then set it to type Date and copy the SaleDate here.
*/
ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE; -- method to change column datatype

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;  -- add a new column with date datatype

UPDATE NashvilleHousing
SET SaleDateConverted=CONVERT(date, SaleDate); -- populate the new column with date format of SaleDate

SELECT
	SaleDate,
	SaleDateConverted,
	CONVERT(date, SaleDate) AS only_date
FROM NashvilleHousing;

----------------------------------------------------------------------------------------------

-- 2. Populate Property Address data
-- Some property address have null values and we can populate them by the same ParcelID
-- bcz if u notice in data, same parcelID has same address. Eg, row44, 45 of below query.
SELECT
	*
FROM NashvilleHousing
-- WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT
	a.ParcelID, a.PropertyAddress,
	b.ParcelID, b.PropertyAddress,
	ISNULL(a.PropertyAddress, b.PropertyAddress) -- to update the column of a with b
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID=b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

UPDATE a -- here, you have to use the alias and not the table name
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
	ON a.ParcelID=b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress IS NULL;

-- Breaking out Address into Individual Columns (Address, City, State)
-- Delimeter is the one that seperates the addresses (here, comma)
SELECT
	PropertyAddress
FROM NashvilleHousing;

/*
The CHARINDEX() function searches for a substring in a string, and returns the position.
If the substring is not found, this function returns 0.
Note: This function performs a case-insensitive search.
CHARINDEX(substring, string, start)
*/
SELECT
	PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
ADD Address NVARCHAR(255);

UPDATE NashvilleHousing
SET Address=SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD City NVARCHAR(100);

UPDATE NashvilleHousing
SET city=SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT * FROM NashvilleHousing; -- to view the two columns that are added from above

SELECT OwnerAddress
FROM NashvilleHousing;

SELECT
	OwnerAddress,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)  
FROM NashvilleHousing;

-- PARSENAME works with periods(.), Therefore, we are replacing (,) with (.)
/*
The PARSENAME function is designed to allow you to easily parse and return individual 
segments from this convention. It's syntax is :

PARSENAME('object_name', object_piece)
Where object_piece represents which segment from the four parts you wish to retrieve. 
The numbering works from right to left so the object name is piece 1, owner is 2, 
database name is 3 and server name is 4. An example :

Declare @ObjectName nVarChar(1000)
Set @ObjectName = 'HeadOfficeSQL1.Northwind.dbo.Authors'
*/

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress=PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity=PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState=PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT * FROM NashvilleHousing; -- to view the two columns that are added from above

-------------------------------------------------------------------------------------

-- 3. Change Y and N to Yes and No in "Sold as Vacant" field
SELECT DISTINCT SoldAsVacant FROM NashvilleHousing;
-- to view all unique values in that column

SELECT
	DISTINCT(SoldAsVacant),
	COUNT(SoldAsVacant) AS "count" -- total count of unique values
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY COUNT(SoldAsVacant);

SELECT
	SoldAsVacant,
	CASE
		WHEN SoldAsVacant='Y' THEN 'Yes'  -- changes 'Y' to 'Yes'
		WHEN SoldAsVacant='N' THEN 'No'   -- changes 'N' to 'No'
		ELSE SoldAsVacant				  -- does no changes to the remaining
	END AS new_SoldAsVacant
FROM NashvilleHousing
WHERE SoldAsVacant IN ('Y','N');

UPDATE NashvilleHousing
SET SoldAsVacant =
	CASE
		WHEN SoldAsVacant='Y' THEN 'Yes'  -- changes 'Y' to 'Yes'
		WHEN SoldAsVacant='N' THEN 'No'   -- changes 'N' to 'No'
		ELSE SoldAsVacant				  -- does no changes to the remaining
	END

SELECT DISTINCT SoldAsVacant FROM NashvilleHousing;
-- to view the changes made in SoldAsVacant

--------------------------------------------------------------------------------------

-- 4. Remove Duplicates
WITH cte AS (
SELECT
	*,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num
FROM NashvilleHousing
)
DELETE FROM cte  -- this command will not run twice as once duplicates are deleted it won't show duplicates
WHERE row_num > 1;
-- to identify duplicates as row_num>1 indicates duplicate rows 
-- to delete duplicates from the given table then simply replace 'SELECT *' by 'DELETE'

WITH cte AS (
SELECT
	*,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY UniqueID) row_num
FROM NashvilleHousing
)
SELECT * FROM cte  -- to view that there are no duplicates
WHERE row_num > 1;

---------------------------------------------------------------------------------------

-- 5. Delete Unused Columns
SELECT * FROM NashvilleHousing;

ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, Saledate;

-- 6. Remove excess spaces in PropertyAddress and OwnerAddress
UPDATE NashvilleHousing
SET Address = RTRIM(LTRIM(REPLACE(Address, '  ', ' ')));

UPDATE NashvilleHousing
SET Address = RTRIM(LTRIM(REPLACE(Address, '  ', ' ')));

---------------------------------------------------------------------------------------

-- 7. Convert fields to title case using LOWER and UPPER functions
UPDATE NashvilleHousing
SET OwnerName = INITCAP(LOWER(OwnerName));
    LandUse = INITCAP(LOWER(LandUse)),
    PropertyAddress = INITCAP(LOWER(PropertyAddress)),
    OwnerAddress = INITCAP(LOWER(OwnerAddress));

-- Use median acreage based on ParcelID to fill missing values
WITH MedianAcreage AS (
    SELECT ParcelID, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Acreage) AS MedianAcre
    FROM NashvilleHousing
    GROUP BY ParcelID
)
UPDATE NashvilleHousing
SET Acreage = MA.MedianAcre
FROM NashvilleHousing NH
JOIN MedianAcreage MA ON NH.ParcelID = MA.ParcelID
WHERE NH.Acreage IS NULL;

-- Convert OwnerName to Title Case
UPDATE NashvilleHousing
SET OwnerName = CONCAT(
    UPPER(LEFT(OwnerName, 1)),
    LOWER(SUBSTRING(OwnerName, 2, LEN(OwnerName) - 1))
);

SELECT * FROM NashvilleHousing;

-- 3. Fill missing bedrooms with the average for each LandUse type
-- Impute Missing Values in Numeric Columns
WITH AvgValues AS (
    SELECT LandUse,
           AVG(CAST(Bedrooms AS FLOAT)) AS AvgBedrooms,
           AVG(CAST(FullBath AS FLOAT)) AS AvgFullBath,
           AVG(CAST(HalfBath AS FLOAT)) AS AvgHalfBath
    FROM NashvilleHousing
    GROUP BY LandUse
)
UPDATE nh
SET nh.Bedrooms = COALESCE(nh.Bedrooms, av.AvgBedrooms),
    nh.FullBath = COALESCE(nh.FullBath, av.AvgFullBath),
    nh.HalfBath = COALESCE(nh.HalfBath, av.AvgHalfBath)
FROM NashvilleHousing nh
JOIN AvgValues av ON nh.LandUse = av.LandUse
WHERE nh.Bedrooms IS NULL OR nh.FullBath IS NULL OR nh.HalfBath IS NULL;

-- 5.
-- Calculate Q1, Q3, and IQR for SalePrice to detect outliers
WITH Quartiles AS (
    SELECT SalePrice,
           NTILE(4) OVER (ORDER BY SalePrice) AS Quartile
    FROM NashvilleHousing
),
Stats AS (
    SELECT 
        MAX(CASE WHEN Quartile = 1 THEN SalePrice END) AS Q1,
        MAX(CASE WHEN Quartile = 3 THEN SalePrice END) AS Q3
    FROM Quartiles
),
Outliers AS (
    SELECT nh.*,
           (Q3 - Q1) * 1.5 AS IQR
    FROM NashvilleHousing nh, Stats
    WHERE nh.SalePrice < Q1 - (Q3 - Q1) * 1.5
       OR nh.SalePrice > Q3 + (Q3 - Q1) * 1.5
)
SELECT * FROM Outliers;


-- Standardize ParcelID to a consistent format if needed
UPDATE NashvilleHousing
SET ParcelID = FORMAT(ParcelID, '000-00-0-000.00');







