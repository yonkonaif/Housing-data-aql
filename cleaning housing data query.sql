SELECT *
FROM Housing.dbo.NashvilleHousing

--Data Cleaning
 --------------------------------------------------------------------------------------------------------------------------
-- Standardize Date Format

UPDATE Housing.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date, SaleDate)

 --------------------------------------------------------------------------------------------------------------------------
-- Populate Property Address data

SELECT *
FROM Housing.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER by ParcelID

SELECT one.ParcelID, one.PropertyAddress, two.ParcelID, two.PropertyAddress, ISNULL(one.PropertyAddress, two.PropertyAddress) as NewAdd -- property add to be populated
FROM Housing..NashvilleHousing one
JOIN Housing..NashvilleHousing two
	ON one.ParcelID = two.ParcelID
	AND one.[UniqueID] <> two.[UniqueID] --same parcelID but not same UniqueID
	WHERE one.PropertyAddress IS NULL

UPDATE one
SET PropertyAddress = ISNULL(one.PropertyAddress, two.PropertyAddress)
FROM Housing..NashvilleHousing one
JOIN Housing..NashvilleHousing two
	ON one.ParcelID = two.ParcelID
	AND one.[UniqueID] <> two.[UniqueID] --same parcelID but not same UniqueID

--------------------------------------------------------------------------------------------------------------------------
-- Breaking out Address into Individual Columns (Address, City, State)

SELECT *
FROM Housing.dbo.NashvilleHousing

SELECT PropertyAddress
FROM Housing..NashvilleHousing

--property address splitting w/ substring
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as Address
	  ,SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM Housing..NashvilleHousing

--altering, adding new collumns
ALTER TABLE Housing..NashvilleHousing
ADD PropertySplitAddress nvarchar(255)

UPDATE Housing..NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE Housing..NashvilleHousing
ADD PropertySplitCity nvarchar(255)


UPDATE Housing..NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

--owner address splitting w/ parsename
SELECT OwnerAddress
FROM Housing.dbo.NashvilleHousing

	 --Parse name is like substring but splits; replace the ',' -> '.' cuz parsename looks for '.'; numbers to split
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
       PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Housing..NashvilleHousing


--altering, adding new collumns
ALTER TABLE Housing..NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE Housing..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) --address


ALTER TABLE Housing..NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

UPDATE Housing..NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) --city


ALTER TABLE Housing..NashvilleHousing
ADD OwnerSplitState nvarchar(255)

UPDATE Housing..NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) --state


--------------------------------------------------------------------------------------------------------------------------
-- Change 1 and 0 to Yes and No in "Sold as Vacant" field

SELECT *
FROM Housing.dbo.NashvilleHousing

--counting
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Housing.dbo.NashvilleHousing
GROUP by SoldAsVacant

--checking
SELECT SoldAsVacant,
  CASE WHEN SoldAsVacant = 0 THEN 'NO'
	   WHEN SoldAsVacant = 1 THEN 'YES'
	   END
FROM Housing.dbo.NashvilleHousing

--add temp
ALTER TABLE Housing.dbo.NashvilleHousing
ADD TEMP varchar(50)

--set temp
UPDATE Housing.dbo.NashvilleHousing
SET TEMP =
  CASE WHEN SoldAsVacant = 0 THEN 'NO'
	   WHEN SoldAsVacant = 1 THEN 'YES'
	   END
FROM Housing.dbo.NashvilleHousing

--altering sav
ALTER TABLE Housing.dbo.NashvilleHousing
ALTER COLUMN SoldAsVacant VARCHAR(50);

--returning values
UPDATE Housing.dbo.NashvilleHousing
SET SoldAsVacant =
  CASE WHEN TEMP = 'NO' THEN 'NO'
	   WHEN TEMP = 'YES' THEN 'YES'
	   END
FROM Housing.dbo.NashvilleHousing

--droping temp
ALTER TABLE Housing.dbo.NashvilleHousing
DROP COLUMN TEMP

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

SELECT *
FROM Housing.dbo.NashvilleHousing


WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
				 UniqueID
				 ) AS row_num
FROM Housing..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress

---------------------------------------------------------------------------------------------------------
-- Delete Unused Columns


SELECT *
FROM Housing.dbo.NashvilleHousing

ALTER TABLE Housing.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress










-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

