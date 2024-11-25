-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: Nov 23, 2024 at 06:59 AM
-- Server version: 8.0.34
-- PHP Version: 8.2.18

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bbms_property_module`
--

DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS `deleteOwner`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteOwner` (IN `owner_id_input` VARCHAR(5))   BEGIN
    DECLARE contract_count INT;
    DECLARE error_message TEXT;

    -- Check if the owner is part of any contract
    SELECT COUNT(*) INTO contract_count
    FROM contract
    WHERE owner_id = owner_id_input;

    -- If the owner is part of any contract, prevent deletion and raise an error
    IF contract_count > 0 THEN
        -- Create the error message
        SET error_message = CONCAT('Cannot delete owner with ID ', owner_id_input, ' as they are part of one or more contracts.');

        -- Trigger an error with the custom message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    ELSE
        -- Proceed to delete the owner if not part of any contract
        DELETE FROM property_owner
        WHERE owner_id = owner_id_input;
    END IF;

END$$

DROP PROCEDURE IF EXISTS `deleteProperty`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteProperty` (IN `property_id_input` VARCHAR(5))   BEGIN
    DECLARE contract_end_date DATE;
    DECLARE contract_number VARCHAR(5);
    DECLARE error_message TEXT;
    DECLARE contract_count INT;

    -- Check if the property is part of any contract
    SELECT COUNT(*) INTO contract_count
    FROM contract
    WHERE property_id = property_id_input;

    -- If the property is part of any contract, fetch the contract details
    IF contract_count > 0 THEN
        SELECT contract_number, end_date
        INTO contract_number, contract_end_date
        FROM contract
        WHERE property_id = property_id_input
        LIMIT 1;

        -- Create the error message with contract details
        SET error_message = CONCAT('Cannot delete property as it is part of contract ', contract_number, ' which ends on ', contract_end_date);

        -- Trigger an error with the custom message
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = error_message;
    ELSE
        -- Proceed to delete the property if not part of any contract
        DELETE FROM property
        WHERE property_id = property_id_input;
    END IF;

END$$

DROP PROCEDURE IF EXISTS `getActiveContractsByDate`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getActiveContractsByDate` (IN `check_date` DATE)   BEGIN
    SELECT contract_number, owner_id, branch_id, property_id, sign_date, start_date, end_date, contract_period, amount_per_installment, total_amount
    FROM contract
    WHERE end_date > check_date;
    END$$

DROP PROCEDURE IF EXISTS `getAllPropertiesInCity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllPropertiesInCity` (IN `city_param` VARCHAR(100))   BEGIN
SET @row_num = 0;
SELECT
(@row_num := @row_num + 1) AS `Sl No.`,
p.property_id, p.survey_number, p.property_type, p.location_type,
po.owner_name, po.owner_phone, po.owner_email
FROM property p
JOIN property_owner po ON p.owner_id = po.owner_id
WHERE p.city = city_param;
END$$

DROP PROCEDURE IF EXISTS `getAllPropertiesInCity1`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAllPropertiesInCity1` (IN `city_param` VARCHAR(100))   BEGIN
SET @row_num = 0;
SELECT
(@row_num := @row_num + 1) AS `Sl No.`,
p.property_id, p.survey_number, p.property_type, p.location_type,
po.owner_name, po.owner_phone, po.owner_email, p.availability
FROM property p
JOIN property_owner po ON p.owner_id = po.owner_id
WHERE p.city = city_param;
END$$

DROP PROCEDURE IF EXISTS `getAvailablePropertiesInCity`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAvailablePropertiesInCity` (IN `city_param` VARCHAR(100))   BEGIN
SET @row_num = 0;
SELECT
(@row_num := @row_num + 1) AS `Sl No.`,
p.property_id, p.survey_number, p.property_type, p.location_type,
po.owner_name, po.owner_phone, po.owner_email
FROM property p
JOIN property_owner po ON p.owner_id = po.owner_id
WHERE p.city = city_param AND p.availability = TRUE;
END$$

DROP PROCEDURE IF EXISTS `getAvailablePropertiesInCity1`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getAvailablePropertiesInCity1` (IN `city_param` VARCHAR(100))   BEGIN
SET @row_num = 0;
SELECT
(@row_num := @row_num + 1) AS `Sl No.`,
p.property_id, p.survey_number, p.property_type, p.location_type,
po.owner_name, po.owner_phone, po.owner_email, p.availability
FROM property p
JOIN property_owner po ON p.owner_id = po.owner_id
WHERE p.city = city_param AND p.availability = TRUE;
END$$

DROP PROCEDURE IF EXISTS `GetDistanceBranchProperty`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetDistanceBranchProperty` (IN `branchId` VARCHAR(5), IN `propertyId` VARCHAR(5))   BEGIN
    DECLARE branch_loc POINT;
    DECLARE property_loc POINT;
    DECLARE branch_name VARCHAR(255);
    DECLARE branch_city VARCHAR(100);
    DECLARE property_city VARCHAR(100);
    DECLARE distance_km DECIMAL(10, 2);

    -- Start labeled block
    main_block: BEGIN

        -- Check if branch exists
        IF NOT EXISTS (SELECT 1 FROM branch WHERE branch_id = branchId) THEN
            SELECT 'Error: Branch ID does not exist.' AS Message;
            LEAVE main_block;
        END IF;

        -- Check if property exists
        IF NOT EXISTS (SELECT 1 FROM property WHERE property_id = propertyId) THEN
            SELECT 'Error: Property ID does not exist.' AS Message;
            LEAVE main_block;
        END IF;

        -- Fetch branch details
        SELECT branch_location, branch_name, city INTO branch_loc, branch_name, branch_city
        FROM branch
        WHERE branch_id = branchId;

        -- Fetch property details
        SELECT property_location, city INTO property_loc, property_city
        FROM property
        WHERE property_id = propertyId;

        -- Handle NULL branch_name
        IF branch_name IS NULL THEN
            SET branch_name = 'Unknown Branch';
        END IF;

        -- Calculate distance in kilometers
        SET distance_km = ST_Distance_Sphere(branch_loc, property_loc) / 1000;  -- Converts meters to kilometers

        -- Display results
        SELECT  
            branch_city AS BranchCity, 
            property_city AS PropertyCity, 
            distance_km AS DistanceInKilometers;
    END main_block;

END$$

DROP PROCEDURE IF EXISTS `GetNearbyAvailableProperties`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetNearbyAvailableProperties` (IN `input_lat` DECIMAL(12,8), IN `input_long` DECIMAL(12,8), IN `radius_km` DECIMAL(10,2))   BEGIN
    DECLARE search_point POINT;
    
    -- Convert input latitude and longitude into a POINT
    SET search_point = ST_GeomFromText(CONCAT('POINT(', input_long, ' ', input_lat, ')'));

    -- Query to find nearby available properties with serial number
    SELECT 
        @row_number := @row_number + 1 AS sl_no,
        property_id,
        city,
        property_latitude,
        property_longitude,
        ROUND((ST_Distance_Sphere(property_location, search_point) / 1000), 2) AS DistanceInKilometers
    FROM 
        property, (SELECT @row_number := 0) AS row_num_init  -- Initialize row number
    WHERE 
        availability = TRUE  -- Only include available properties
        AND (ST_Distance_Sphere(property_location, search_point) / 1000) <= radius_km
    ORDER BY 
        DistanceInKilometers ASC;
END$$

DROP PROCEDURE IF EXISTS `GetNearbyProperties`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `GetNearbyProperties` (IN `input_lat` DECIMAL(12,8), IN `input_long` DECIMAL(12,8), IN `radius_km` DECIMAL(10,2))   BEGIN
    DECLARE search_point POINT;
    
    -- Convert input latitude and longitude into a POINT
    SET search_point = ST_GeomFromText(CONCAT('POINT(', input_long, ' ', input_lat, ')'));

    -- Query to find nearby properties with serial number
    SELECT 
        @row_number := @row_number + 1 AS sl_no,
        property_id,
        city,
        property_latitude,
        property_longitude,
        ROUND((ST_Distance_Sphere(property_location, search_point) / 1000), 2) AS DistanceInKilometers
    FROM 
        property, (SELECT @row_number := 0) AS row_num_init  -- Initialize row number
    WHERE 
        (ST_Distance_Sphere(property_location, search_point) / 1000) <= radius_km
    ORDER BY 
        DistanceInKilometers ASC;
END$$

DROP PROCEDURE IF EXISTS `getOwnerPaymentDetails`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getOwnerPaymentDetails` (IN `owner_id_param` VARCHAR(5))   BEGIN
DECLARE total_paid DECIMAL(15, 2) DEFAULT 0;
DECLARE total_contract_amount DECIMAL(15, 2) DEFAULT 0;
DECLARE amount_left_to_pay DECIMAL(15, 2) DEFAULT 0;

-- Get the total payments made for the owner
SELECT IFNULL(SUM(p.transaction_amount), 0)
INTO total_paid
FROM payment p
JOIN contract c ON p.contract_number = c.contract_number
WHERE c.owner_id = owner_id_param;
-- Get the total amount from all contracts for the owner
SELECT IFNULL(SUM(c.total_amount), 0)
INTO total_contract_amount
FROM contract c
WHERE c.owner_id = owner_id_param;
-- Calculate the remaining amount
SET amount_left_to_pay = total_contract_amount - total_paid;
-- Print all payments made till now
SELECT p.payment_id, p.contract_number, p.payment_mode, p.date,
       p.transaction_amount, p.status
FROM payment p
JOIN contract c ON p.contract_number = c.contract_number
WHERE c.owner_id = owner_id_param;
-- Print the total amount paid and amount left to pay
SELECT total_paid AS total_amount_paid, amount_left_to_pay AS amount_left_to_pay;

END$$

DROP PROCEDURE IF EXISTS `getPropertyDetailsByOwner`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `getPropertyDetailsByOwner` (IN `owner_id_param` VARCHAR(5))   BEGIN
SELECT p.property_id, p.survey_number, p.property_type, p.location_type,
p.property_latitude, p.property_longitude, p.property_height,
p.plot_number, p.street_name, p.city, p.district, p.state, p.pincode
FROM property p
WHERE p.owner_id = owner_id_param;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `advertisement_agency`
--

DROP TABLE IF EXISTS `advertisement_agency`;
CREATE TABLE IF NOT EXISTS `advertisement_agency` (
  `agency_id` varchar(5) NOT NULL,
  `agency_name` varchar(255) NOT NULL,
  `agency_email` varchar(255) NOT NULL,
  `agency_address` text NOT NULL,
  `cin_number` char(21) NOT NULL,
  PRIMARY KEY (`agency_id`),
  UNIQUE KEY `agency_email` (`agency_email`),
  UNIQUE KEY `cin_number` (`cin_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `advertisement_agency`
--

INSERT INTO `advertisement_agency` (`agency_id`, `agency_name`, `agency_email`, `agency_address`, `cin_number`) VALUES
('A001', 'Skyline Ads', 'contact@skylineads.com', '123 Main Street, Bangalore, Karnataka, India', 'U12345678901234567890');

-- --------------------------------------------------------

--
-- Table structure for table `branch`
--

DROP TABLE IF EXISTS `branch`;
CREATE TABLE IF NOT EXISTS `branch` (
  `branch_id` varchar(5) NOT NULL,
  `branch_name` varchar(255) NOT NULL,
  `branch_email` varchar(255) NOT NULL,
  `branch_phone` char(10) NOT NULL,
  `plot_number` varchar(50) DEFAULT NULL,
  `street_name` varchar(255) DEFAULT NULL,
  `address_line1` varchar(255) DEFAULT NULL,
  `address_line2` varchar(255) DEFAULT NULL,
  `landmark` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` char(6) NOT NULL,
  `agency_id` varchar(5) NOT NULL,
  `branch_latitude` decimal(12,8) NOT NULL,
  `branch_longitude` decimal(12,8) NOT NULL,
  `branch_location` point NOT NULL,
  PRIMARY KEY (`branch_id`),
  UNIQUE KEY `branch_email` (`branch_email`),
  SPATIAL KEY `branch_location` (`branch_location`),
  KEY `agency_id` (`agency_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `branch`
--

INSERT INTO `branch` (`branch_id`, `branch_name`, `branch_email`, `branch_phone`, `plot_number`, `street_name`, `address_line1`, `address_line2`, `landmark`, `city`, `district`, `state`, `pincode`, `agency_id`, `branch_latitude`, `branch_longitude`, `branch_location`) VALUES
('B0001', 'Skyline HQ', 'hq@skylineads.com', '9876543210', '101', 'MG Road', 'Near Central Mall', 'Opposite Cubbon Park', 'Cubbon Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 'A001', 12.97160000, 77.59460000, 0x000000000101000000e78c28ed0d6653405396218e75f12940),
('B0002', 'Skyline North', 'north@skylineads.com', '9876543211', '202', 'Hebbal Road', 'Near Manyata Tech Park', 'Opposite Nagavara Lake', 'Nagavara Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 'A001', 13.03580000, 77.59700000, 0x00000000010100000091ed7c3f35665340c364aa6054122a40),
('B0003', 'Skyline East', 'east@skylineads.com', '9876543212', '303', 'Whitefield Main Road', 'Near ITPL', 'Opposite Forum Shantiniketan', 'Forum Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', 'A001', 12.96980000, 77.74990000, 0x0000000001010000004ed1915cfe6f5340545227a089f02940),
('B0004', 'Skyline South', 'south@skylineads.com', '9876543213', '404', 'Jayanagar 4th Block', 'Near Cool Joint', 'Opposite Central Library', 'Central Library', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 'A001', 12.92510000, 77.59330000, 0x000000000101000000e02d90a0f8655340280f0bb5a6d92940),
('B0005', 'Skyline West', 'west@skylineads.com', '9876543214', '505', 'Vijayanagar Main Road', 'Near Maruthi Mandir', 'Opposite ESI Hospital', 'ESI Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 'A001', 12.96940000, 77.56050000, 0x0000000001010000001d5a643bdf6353401c7c613255f02940),
('B0006', 'Skyline Hubli', 'hubli@skylineads.com', '9876543215', '606', 'Lamington Road', 'Near Clock Tower', 'Opposite Rani Chennamma Circle', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 'A001', 15.36470000, 75.12400000, 0x0000000001010000000e2db29defc75240d0b359f5b9ba2e40),
('B0007', 'Skyline Mysore', 'mysore@skylineads.com', '9876543216', '707', 'Chamundi Hill Road', 'Near Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 'A001', 12.30520000, 76.65510000, 0x00000000010100000004e78c28ed295340787aa52c439c2840),
('B0008', 'Skyline Mangalore', 'mangalore@skylineads.com', '9876543217', '808', 'Hampankatta Road', 'Near City Center Mall', 'Opposite Mangala Stadium', 'Mangala Stadium', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', 'A001', 12.91410000, 74.85600000, 0x000000000101000000105839b4c8b65240158c4aea04d42940),
('B0009', 'Skyline Belgaum', 'belgaum@skylineads.com', '9876543218', '909', 'College Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 'A001', 15.84970000, 74.49770000, 0x00000000010100000007ce1951da9f524089d2dee00bb32f40),
('B0010', 'Skyline Davangere', 'davangere@skylineads.com', '9876543219', '1010', 'PB Road', 'Near GMIT College', 'Opposite Kundwada Lake', 'Kundwada Lake', 'Davangere', 'Davangere', 'Karnataka', '577002', 'A001', 14.46440000, 75.92170000, 0x000000000101000000492eff21fdfa5240598638d6c5ed2c40);

--
-- Triggers `branch`
--
DROP TRIGGER IF EXISTS `updateBranchLocation`;
DELIMITER $$
CREATE TRIGGER `updateBranchLocation` BEFORE INSERT ON `branch` FOR EACH ROW BEGIN
    SET NEW.branch_location = ST_PointFromText(
        CONCAT('POINT(', NEW.branch_longitude, ' ', NEW.branch_latitude, ')')
    );
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `updateBranchLocationOnUpdate`;
DELIMITER $$
CREATE TRIGGER `updateBranchLocationOnUpdate` BEFORE UPDATE ON `branch` FOR EACH ROW BEGIN
SET NEW.branch_location = ST_PointFromText(
CONCAT('POINT(', NEW.branch_longitude, ' ', NEW.branch_latitude, ')')
);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `contract`
--

DROP TABLE IF EXISTS `contract`;
CREATE TABLE IF NOT EXISTS `contract` (
  `contract_number` varchar(5) NOT NULL,
  `owner_id` varchar(5) NOT NULL,
  `branch_id` varchar(5) NOT NULL,
  `property_id` varchar(5) NOT NULL,
  `contract_file` text NOT NULL,
  `property_document_file` text NOT NULL,
  `sign_date` date NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `contract_period` int NOT NULL,
  `amount_per_installment` decimal(10,2) NOT NULL,
  `number_of_installments` int NOT NULL,
  `total_amount` decimal(15,2) GENERATED ALWAYS AS ((`amount_per_installment` * `number_of_installments`)) STORED,
  PRIMARY KEY (`contract_number`),
  KEY `owner_id` (`owner_id`),
  KEY `branch_id` (`branch_id`),
  KEY `property_id` (`property_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `contract`
--

INSERT INTO `contract` (`contract_number`, `owner_id`, `branch_id`, `property_id`, `contract_file`, `property_document_file`, `sign_date`, `start_date`, `end_date`, `contract_period`, `amount_per_installment`, `number_of_installments`) VALUES
('C0001', 'O0001', 'B0001', 'P0001', 'C0001Contractfile.pdf', 'P0001_property_documentfile.pdf', '2024-08-01', '2024-08-15', '2025-07-14', 12, 5000.00, 12),
('C0002', 'O0015', 'B0005', 'P0028', 'C0002Contractfile.pdf', 'P0028_property_documentfile.pdf', '2024-08-02', '2024-09-01', '2027-08-31', 36, 25000.00, 6),
('C0003', 'O0001', 'B0001', 'P0002', 'C0003Contractfile.pdf', 'P0002_property_documentfile.pdf', '2024-08-05', '2024-09-01', '2025-08-31', 12, 15000.00, 2),
('C0004', 'O0002', 'B0001', 'P0003', 'C0004Contractfile.pdf', 'P0003_property_documentfile.pdf', '2024-08-10', '2024-10-10', '2026-09-09', 24, 10000.00, 8),
('C0005', 'O0011', 'B0003', 'P0021', 'C0005Contractfile.pdf', 'P0021_property_documentfile.pdf', '2024-08-10', '2024-08-10', '2026-07-09', 24, 50000.00, 24),
('C0006', 'O0002', 'B0001', 'P0004', 'C0006Contractfile.pdf', 'P0004_property_documentfile.pdf', '2024-08-12', '2024-09-25', '2025-08-24', 12, 20000.00, 1),
('C0007', 'O0003', 'B0001', 'P0005', 'C0007Contractfile.pdf', 'P0005_property_documentfile.pdf', '2024-08-15', '2024-11-20', '2027-10-19', 36, 8000.00, 36),
('C0008', 'O0003', 'B0001', 'P0006', 'C0008Contractfile.pdf', 'P0006_property_documentfile.pdf', '2024-08-18', '2024-11-05', '2026-10-04', 24, 25000.00, 24),
('C0009', 'O0004', 'B0001', 'P0007', 'C0009Contractfile.pdf', 'P0007_property_documentfile.pdf', '2024-08-20', '2024-09-10', '2027-08-09', 36, 12000.00, 12),
('C0010', 'O0004', 'B0001', 'P0008', 'C0010Contractfile.pdf', 'P0008_property_documentfile.pdf', '2024-08-22', '2024-10-12', '2025-09-11', 12, 40000.00, 1),
('C0011', 'O0022', 'B0006', 'P0043', 'C0011Contractfile.pdf', 'P0043_property_documentfile.pdf', '2024-08-22', '2024-09-05', '2027-08-04', 36, 35000.00, 12),
('C0012', 'O0005', 'B0001', 'P0009', 'C0012Contractfile.pdf', 'P0009_property_documentfile.pdf', '2024-08-25', '2024-10-10', '2026-09-09', 24, 11000.00, 24),
('C0013', 'O0025', 'B0007', 'P0050', 'C0013Contractfile.pdf', 'P0050_property_documentfile.pdf', '2024-08-25', '2024-10-12', '2026-09-11', 24, 60000.00, 24),
('C0014', 'O0005', 'B0001', 'P0010', 'C0014Contractfile.pdf', 'P0010_property_documentfile.pdf', '2024-08-28', '2024-09-30', '2025-08-29', 12, 13000.00, 4),
('C0015', 'O0024', 'B0007', 'P0048', 'C0015Contractfile.pdf', 'P0048_property_documentfile.pdf', '2024-09-01', '2024-09-28', '2027-08-27', 36, 550000.00, 1),
('C0016', 'O0014', 'B0005', 'P0030', 'C0016Contractfile.pdf', 'P0030_property_documentfile.pdf', '2024-09-07', '2024-10-07', '2025-09-08', 12, 22000.00, 12),
('C0017', 'O0022', 'B0006', 'P0043', 'C0017Contractfile.pdf', 'P0043_property_documentfile.pdf', '2024-09-07', '2024-09-30', '2026-08-29', 24, 18000.00, 24),
('C0018', 'O0031', 'B0009', 'P0056', 'C0018Contractfile.pdf', 'P0056_property_documentfile.pdf', '2024-09-17', '2024-10-01', '2025-09-30', 12, 3000.00, 12),
('C0019', 'O0035', 'B0010', 'P0059', 'C0019Contractfile.pdf', 'P0059_property_documentfile.pdf', '2024-09-18', '2024-09-20', '2027-08-19', 36, 18000.00, 12),
('C0020', 'O0013', 'B0003', 'P0025', 'C0020Contractfile.pdf', 'P0025_property_documentfile.pdf', '2024-09-18', '2024-09-20', '2025-08-19', 12, 1000000.00, 1),
('C0021', 'O0022', 'B0006', 'P0044', 'C0021Contractfile.pdf', 'P0044_property_documentfile.pdf', '2024-09-28', '2024-10-25', '2025-09-24', 12, 50000.00, 2),
('C0022', 'O0023', 'B0007', 'P0046', 'C0022Contractfile.pdf', 'P0046_property_documentfile.pdf', '2024-10-01', '2024-10-19', '2025-09-18', 12, 60000.00, 12),
('C0023', 'O0017', 'B0004', 'P0034', 'C0023Contractfile.pdf', 'P0034_property_documentfile.pdf', '2024-10-10', '2024-11-20', '2027-10-19', 36, 17000.00, 36),
('C0024', 'O0019', 'B0004', 'P0038', 'C0024Contractfile.pdf', 'P0038_property_documentfile.pdf', '2024-10-12', '2024-10-12', '2026-09-11', 24, 22000.00, 4),
('C0025', 'O0026', 'B0008', 'P0051', 'C0025Contractfile.pdf', 'P0051_property_documentfile.pdf', '2024-10-15', '2024-11-25', '2026-10-24', 24, 3000.00, 2);

--
-- Triggers `contract`
--
DROP TRIGGER IF EXISTS `afterUpdateContract`;
DELIMITER $$
CREATE TRIGGER `afterUpdateContract` AFTER UPDATE ON `contract` FOR EACH ROW BEGIN
-- Check if contract_file was updated
IF NEW.contract_file <> OLD.contract_file THEN
-- Update the contract file name with the contract_number
UPDATE contract
SET contract_file = CONCAT(NEW.contract_number, 'Contractfile.pdf')
WHERE contract_number = NEW.contract_number;
END IF;

-- Check if property_document_file was updated
IF NEW.property_document_file <> OLD.property_document_file THEN
    -- Update the property document file name with the property_id
    UPDATE contract
    SET property_document_file = CONCAT(NEW.property_id, '_property_documentfile.pdf')
    WHERE contract_number = NEW.contract_number;
END IF;

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `beforeInsertContract`;
DELIMITER $$
CREATE TRIGGER `beforeInsertContract` BEFORE INSERT ON `contract` FOR EACH ROW BEGIN
-- Set the contract file name with the contract_number
SET NEW.contract_file = CONCAT(NEW.contract_number, 'Contractfile.pdf');

-- Set the property document file name with the property_id
SET NEW.property_document_file = CONCAT(NEW.property_id, '_property_documentfile.pdf');

END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `setPropertyAvailableOnContractEnd`;
DELIMITER $$
CREATE TRIGGER `setPropertyAvailableOnContractEnd` AFTER UPDATE ON `contract` FOR EACH ROW BEGIN
IF NEW.end_date = CURDATE() THEN
UPDATE property
SET availability = 1
WHERE property_id = NEW.property_id;
END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `setPropertyUnavailableAfterContractInsert`;
DELIMITER $$
CREATE TRIGGER `setPropertyUnavailableAfterContractInsert` AFTER INSERT ON `contract` FOR EACH ROW BEGIN
UPDATE property
SET availability = 0
WHERE property_id = NEW.property_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `owner_bank_details`
--

DROP TABLE IF EXISTS `owner_bank_details`;
CREATE TABLE IF NOT EXISTS `owner_bank_details` (
  `owner_bank_details_id` varchar(5) NOT NULL,
  `owner_id` varchar(5) NOT NULL,
  `owner_bank_account_number` char(12) NOT NULL,
  `owner_ifsc_code` varchar(11) NOT NULL,
  `owner_bank_name` varchar(255) NOT NULL,
  PRIMARY KEY (`owner_bank_details_id`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `owner_bank_details`
--

INSERT INTO `owner_bank_details` (`owner_bank_details_id`, `owner_id`, `owner_bank_account_number`, `owner_ifsc_code`, `owner_bank_name`) VALUES
('OB001', 'O0001', '123456734012', 'SBIN0001234', 'State Bank of India'),
('OB002', 'O0002', '234567832123', 'HDFC0002345', 'HDFC Bank'),
('OB003', 'O0003', '345678912234', 'ICIC0003456', 'ICICI Bank'),
('OB004', 'O0004', '456789012345', 'AXIS0004567', 'Axis Bank'),
('OB005', 'O0005', '567890156456', 'YESB0005678', 'YES Bank'),
('OB006', 'O0006', '678901235567', 'KKBK0006789', 'Kotak Mahindra Bank'),
('OB007', 'O0007', '789012376678', 'SIBL0007890', 'South Indian Bank'),
('OB008', 'O0008', '890123436789', 'RBLB0008901', 'RBL Bank'),
('OB009', 'O0009', '901234589890', 'PNB00009012', 'Punjab National Bank'),
('OB010', 'O0010', '012345698901', 'BAND0004534', 'Bank of Baroda'),
('OB011', 'O0011', '123456788012', 'SBIN0003734', 'State Bank of India'),
('OB012', 'O0012', '234567858123', 'HDFC0007834', 'HDFC Bank'),
('OB013', 'O0013', '345678947234', 'ICIC0002534', 'ICICI Bank'),
('OB014', 'O0014', '456789035345', 'AXIS0008934', 'Axis Bank'),
('OB015', 'O0015', '567890125456', 'PNB00004534', 'Punjab National Bank'),
('OB016', 'O0016', '678901227567', 'YESB0001364', 'YES Bank'),
('OB017', 'O0017', '789012378678', 'KARB0002634', 'Karnataka Bank'),
('OB018', 'O0018', '890123479789', 'SIBL0007364', 'South Indian Bank'),
('OB019', 'O0019', '901234550890', 'CBIN0002564', 'Central Bank of India'),
('OB020', 'O0020', '012345651901', 'SBIN0002758', 'State Bank of India'),
('OB021', 'O0021', '987654352012', 'SBIN0003742', 'State Bank of India'),
('OB022', 'O0022', '123456753012', 'HDFC0001234', 'HDFC Bank'),
('OB023', 'O0023', '765432154876', 'ICIC0007654', 'ICICI Bank'),
('OB024', 'O0024', '456789055345', 'KARB0004567', 'Karur Vysya Bank'),
('OB025', 'O0025', '789012356678', 'CBIN0001234', 'Central Bank of India'),
('OB026', 'O0026', '321098757432', 'SBIN0008765', 'State Bank of India'),
('OB027', 'O0027', '678901258567', 'HDFC0008765', 'HDFC Bank'),
('OB028', 'O0028', '109876559210', 'ICIC0009876', 'ICICI Bank'),
('OB029', 'O0029', '234567860123', 'KARB0002345', 'Karur Vysya Bank'),
('OB030', 'O0030', '876543261987', 'CBIN0009876', 'Central Bank of India'),
('OB031', 'O0031', '987654362098', 'SBIN0003210', 'State Bank of India'),
('OB032', 'O0032', '876543263987', 'HDFC0001234', 'HDFC Bank'),
('OB033', 'O0033', '123456764012', 'ICIC0007654', 'ICICI Bank'),
('OB034', 'O0034', '765432187556', 'KARB0008765', 'Karur Vysya Bank'),
('OB035', 'O0035', '109876543660', 'CBIN0003210', 'Central Bank of India');

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

DROP TABLE IF EXISTS `payment`;
CREATE TABLE IF NOT EXISTS `payment` (
  `payment_id` varchar(5) NOT NULL,
  `contract_number` varchar(5) DEFAULT NULL,
  `payment_mode` varchar(50) DEFAULT NULL,
  `date` date NOT NULL,
  `payment_identification_key` varchar(255) DEFAULT NULL,
  `transaction_amount` decimal(10,2) DEFAULT NULL,
  `owner_bank_details_id` varchar(5) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`payment_id`),
  KEY `contract_number` (`contract_number`),
  KEY `owner_bank_details_id` (`owner_bank_details_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`payment_id`, `contract_number`, `payment_mode`, `date`, `payment_identification_key`, `transaction_amount`, `owner_bank_details_id`, `status`) VALUES
('PY001', 'C0005', 'Net Banking', '2024-08-10', '782312024081093449090', 50000.00, 'OB011', 'Completed'),
('PY002', 'C0001', 'Net Banking', '2024-08-15', '782312024081583461072', 5000.00, 'OB001', 'Completed'),
('PY003', 'C0002', 'Net Banking', '2024-09-01', '782312024090183441072', 25000.00, 'OB015', 'Completed'),
('PY004', 'C0003', 'Net Banking', '2024-09-01', '782312024090183449072', 15000.00, 'OB001', 'Completed'),
('PY005', 'C0011', 'Net Banking', '2024-09-05', '782312024090593349090', 35000.00, 'OB022', 'Completed'),
('PY006', 'C0009', 'Net Banking', '2024-09-10', '782312024091093849090', 12000.00, 'OB004', 'Completed'),
('PY007', 'C0005', 'Net Banking', '2024-09-10', '782312024091093449090', 50000.00, 'OB011', 'Completed'),
('PY008', 'C0001', 'Net Banking', '2024-09-15', '782312024091583461072', 5000.00, 'OB001', 'Completed'),
('PY009', 'C0020', 'Cheque', '2024-09-20', 'CHQ127893', 1000000.00, 'OB013', 'Completed'),
('PY010', 'C0019', 'Net Banking', '2024-09-20', '782312024092095349090', 18000.00, 'OB035', 'Completed'),
('PY011', 'C0006', 'Cheque', '2024-09-25', 'CHQ723486', 20000.00, 'OB002', 'Completed'),
('PY012', 'C0015', 'Cheque', '2024-09-28', 'CHQ536873', 550000.00, 'OB024', 'Completed'),
('PY013', 'C0014', 'Net Banking', '2024-09-30', '782312024093095349190', 13000.00, 'OB005', 'Completed'),
('PY014', 'C0017', 'Net Banking', '2024-09-30', '782312024093095349090', 18000.00, 'OB022', 'Completed'),
('PY015', 'C0018', 'Net Banking', '2024-10-01', '782312024100195349090', 3000.00, 'OB031', 'Completed'),
('PY016', 'C0016', 'Net Banking', '2024-10-07', '782312024100795349190', 22000.00, 'OB014', 'Completed'),
('PY017', 'C0012', 'Net Banking', '2024-10-10', '782312024101093349090', 11000.00, 'OB005', 'Completed'),
('PY018', 'C0012', 'Net Banking', '2024-10-10', '782312024101093349090', 11000.00, 'OB005', 'Completed'),
('PY019', 'C0005', 'Net Banking', '2024-10-10', '782312024101093449090', 50000.00, 'OB011', 'Completed'),
('PY020', 'C0004', 'Net Banking', '2024-10-10', '782312024101083449090', 10000.00, 'OB002', 'Completed'),
('PY021', 'C0010', 'Cheque', '2024-10-12', 'CHQ672335', 40000.00, 'OB004', 'Completed'),
('PY022', 'C0013', 'Net Banking', '2024-10-12', '782312024101295349090', 60000.00, 'OB025', 'Completed'),
('PY023', 'C0024', 'Net Banking', '2024-10-12', '782312024101265349090', 22000.00, 'OB019', 'Completed'),
('PY024', 'C0001', 'Net Banking', '2024-10-15', '782312024101583461072', 5000.00, 'OB001', 'Completed'),
('PY025', 'C0022', 'Net Banking', '2024-10-19', '782312024101965349090', 60000.00, 'OB023', 'Completed'),
('PY026', 'C0021', 'Net Banking', '2024-10-25', '782312024102565349090', 50000.00, 'OB022', 'Completed'),
('PY027', 'C0017', 'Net Banking', '2024-10-30', '782312024103095349090', 18000.00, 'OB022', 'Completed'),
('PY028', 'C0018', 'Net Banking', '2024-11-01', '782312024110195349090', 3000.00, 'OB031', 'Completed'),
('PY029', 'C0008', 'Net Banking', '2024-11-05', '782312024110593849090', 25000.00, 'OB003', 'Completed'),
('PY030', 'C0016', 'Net Banking', '2024-11-07', '782312024110795349190', 22000.00, 'OB014', 'Completed'),
('PY031', 'C0005', 'Net Banking', '2024-11-10', '782312024111093449090', 50000.00, 'OB011', 'Completed'),
('PY032', 'C0013', 'Net Banking', '2024-11-12', '782312024111295349090', 60000.00, 'OB025', 'Completed'),
('PY033', 'C0001', 'Net Banking', '2024-11-15', '782312024111583461072', 5000.00, 'OB001', 'Completed'),
('PY034', 'C0022', 'Net Banking', '2024-11-19', '782312024111965349090', 60000.00, 'OB023', 'Completed'),
('PY035', 'C0023', 'Net Banking', '2024-11-20', '782312024112065349090', 17000.00, 'OB017', 'Completed'),
('PY036', 'C0007', 'Net Banking', '2024-11-20', '782312024112093449090', 8000.00, 'OB003', 'Completed'),
('PY037', 'C0025', 'Net Banking', '2024-11-25', '782312024112565349090', 3000.00, 'OB026', 'Completed');

-- --------------------------------------------------------

--
-- Table structure for table `property`
--

DROP TABLE IF EXISTS `property`;
CREATE TABLE IF NOT EXISTS `property` (
  `property_id` varchar(5) NOT NULL,
  `owner_id` varchar(5) NOT NULL,
  `survey_number` varchar(50) NOT NULL,
  `availability` tinyint(1) NOT NULL DEFAULT '1',
  `property_latitude` decimal(12,8) NOT NULL,
  `property_longitude` decimal(12,8) NOT NULL,
  `property_height` decimal(5,2) NOT NULL,
  `property_type` enum('Residential','Commercial','Highway','Open land','Traffic signals') NOT NULL,
  `location_type` enum('City','Village','Highway') NOT NULL,
  `plot_number` varchar(50) DEFAULT NULL,
  `street_name` varchar(255) DEFAULT NULL,
  `address_line1` varchar(255) DEFAULT NULL,
  `address_line2` varchar(255) DEFAULT NULL,
  `landmark` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` char(6) NOT NULL,
  `property_location` point NOT NULL,
  PRIMARY KEY (`property_id`),
  SPATIAL KEY `property_location` (`property_location`),
  KEY `owner_id` (`owner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `property`
--

INSERT INTO `property` (`property_id`, `owner_id`, `survey_number`, `availability`, `property_latitude`, `property_longitude`, `property_height`, `property_type`, `location_type`, `plot_number`, `street_name`, `address_line1`, `address_line2`, `landmark`, `city`, `district`, `state`, `pincode`, `property_location`) VALUES
('P0001', 'O0001', 'S-123/456', 0, 12.97160000, 77.59460000, 15.50, 'Residential', 'City', '202', 'Brigade Road', 'Near Church Street', NULL, 'MG Road Metro Station', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000e78c28ed0d6653405396218e75f12940),
('P0002', 'O0001', 'S-123/457', 0, 12.97050000, 77.59400000, 16.00, 'Commercial', 'City', '203', 'Brigade Road', 'Near MG Road', 'Opposite Church Street', 'Church Street', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000bc7493180466534037894160e5f02940),
('P0003', 'O0002', 'S-124/789', 0, 12.97110000, 77.60970000, 18.20, 'Commercial', 'City', '303', 'Residency Road', 'Opposite Bishop Cotton School', NULL, 'Richmond Circle', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000c2172653056753408c4aea0434f12940),
('P0004', 'O0002', 'S-124/790', 0, 12.97000000, 77.60900000, 20.00, 'Residential', 'City', '304', 'Residency Road', 'Next to Richmond Circle', NULL, 'Residency Road', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000e5d022dbf9665340713d0ad7a3f02940),
('P0005', 'O0003', 'S-125/001', 0, 12.96040000, 77.61360000, 17.00, 'Residential', 'City', '404', 'Church Street', 'Next to Empire Hotel', NULL, 'Church Street', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000d734ef384567534024287e8cb9eb2940),
('P0006', 'O0003', 'S-125/002', 0, 12.95950000, 77.61280000, 19.00, 'Commercial', 'City', '405', 'Church Street', 'Near Shivaji Nagar', 'Opposite Empire Hotel', 'Church Street', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x00000000010100000048bf7d1d386753402506819543eb2940),
('P0007', 'O0004', 'S-126/356', 0, 12.97400000, 77.60900000, 16.50, 'Residential', 'City', '505', 'MG Road', 'Near Lido Mall', NULL, 'Lido Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000e5d022dbf9665340a69bc420b0f22940),
('P0008', 'O0004', 'S-126/357', 0, 12.97320000, 77.60850000, 18.00, 'Commercial', 'City', '506', 'MG Road', 'Opposite Brigade Road', NULL, 'Lido Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x0000000001010000006de7fba9f166534035ef384547f22940),
('P0009', 'O0005', 'S-127/321', 0, 12.98320000, 77.60730000, 17.00, 'Residential', 'City', '606', 'Ulsoor Road', 'Near Ulsoor Lake', NULL, 'Ulsoor Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x00000000010100000017b7d100de665340bada8afd65f72940),
('P0010', 'O0005', 'S-127/322', 0, 12.98200000, 77.60650000, 16.00, 'Commercial', 'City', '607', 'Ulsoor Road', 'Near Ulsoor Lake', 'Opposite KSR College', 'Ulsoor Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', 0x000000000101000000894160e5d0665340105839b4c8f62940),
('P0011', 'O0006', 'S.N. 44/1', 1, 12.98765400, 77.63985200, 15.50, 'Residential', 'City', '101', 'Outer Ring Road', 'Near Manyata Embassy Tech Park', NULL, 'Manyata Tech Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x000000000101000000ef91cd55f3685340f486fbc8adf92940),
('P0012', 'O0006', 'S.N. 45/2', 1, 12.98780000, 77.64020000, 12.00, 'Commercial', 'City', '102', 'Outer Ring Road', 'Near Manyata Embassy Tech Park', NULL, 'Manyata Tech Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x0000000001010000008cb96b09f968534044faedebc0f92940),
('P0013', 'O0007', 'S.N. 47/1', 1, 12.99675400, 77.60564800, 20.30, 'Residential', 'City', '202', 'Thanisandra Road', 'Near Elements Mall', NULL, 'Elements Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x000000000101000000d238d4efc26653407a50508a56fe2940),
('P0014', 'O0007', 'S.N. 48/3', 1, 12.99710000, 77.60585000, 18.75, 'Commercial', 'City', '203', 'Thanisandra Road', 'Near Elements Mall', NULL, 'Elements Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x0000000001010000000612143fc6665340e6ae25e483fe2940),
('P0015', 'O0008', 'S.N. 49/1', 1, 13.02754600, 77.59531800, 25.00, 'Highway', 'Highway', '303', 'Nagavara Main Road', 'Close to Nagavara Lake', NULL, 'Nagavara Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x000000000101000000172eabb0196653406f4562821a0e2a40),
('P0016', 'O0008', 'S.N. 50/2', 1, 13.02785000, 77.59570000, 30.20, 'Commercial', 'Highway', '304', 'Nagavara Main Road', 'Close to Nagavara Lake', NULL, 'Nagavara Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x0000000001010000008a8ee4f21f6653402063ee5a420e2a40),
('P0017', 'O0009', 'S.N. 51/1', 1, 13.04010000, 77.60074000, 18.00, 'Residential', 'City', '404', 'Hebbal Kempapura', 'Opposite Esteem Mall', NULL, 'Esteem Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x0000000001010000008a592f8672665340a323b9fc87142a40),
('P0018', 'O0009', 'S.N. 52/2', 1, 13.04025000, 77.60090000, 20.50, 'Commercial', 'City', '405', 'Hebbal Kempapura', 'Opposite Esteem Mall', NULL, 'Esteem Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x000000000101000000a60a462575665340f853e3a59b142a40),
('P0019', 'O0010', 'S.N. 53/1', 1, 13.02796200, 77.62540300, 12.40, 'Open land', 'City', '505', 'Rachenahalli', 'Near Lake View Apartments', NULL, 'Lake View Apartments', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', 0x00000000010100000080f44d9a06685340bf0f0709510e2a40),
('P0021', 'O0011', 'S.N. 123/1', 0, 12.96370000, 77.70890000, 10.50, 'Commercial', 'City', '101', 'ITPL Main Road', 'Close to Vydehi Hospital', 'Vydehi Hospital', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', 0x0000000001010000009a081b9e5e6d5340764f1e166aed2940),
('P0022', 'O0011', 'Bangalore Survey No. 124/2', 1, 12.96150000, 77.70780000, 12.00, 'Residential', 'City', '101', 'ITPL Main Road', 'Close to Vydehi Hospital', NULL, 'Vydehi Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', 0x000000000101000000f7065f984c6d53403f355eba49ec2940),
('P0023', 'O0012', 'Bangalore Survey No. 125/3', 1, 12.95580000, 77.71540000, 15.00, 'Highway', 'Highway', '202', 'Whitefield Main Road', 'Near Prestige Shantiniketan', 'Prestige Shantiniketan', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', 0x000000000101000000bde3141dc96d53409a081b9e5ee92940),
('P0024', 'O0012', 'Bangalore Survey No. 126/4', 1, 12.95720000, 77.71700000, 14.00, 'Commercial', 'Highway', '202', 'Whitefield Main Road', 'Near Prestige Shantiniketan', 'Prestige Shantiniketan', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', 0x000000000101000000d9cef753e36d534060764f1e16ea2940),
('P0025', 'O0013', 'Bangalore Survey No. 127/5', 0, 12.96720000, 77.71020000, 20.00, 'Open land', 'Highway', '303', 'EPIP Zone', 'Close to SAP Labs', 'SAP Labs', 'Bangalore', NULL, 'Bangalore Urban', 'Karnataka', '560066', 0x000000000101000000a167b3ea736d5340e561a1d634ef2940),
('P0026', 'O0013', 'Bangalore Survey No. 128/6', 1, 12.96950000, 77.71200000, 18.50, 'Highway', 'Highway', '303', 'EPIP Zone', 'Close to SAP Labs', 'SAP Labs', 'Bangalore', NULL, 'Bangalore Urban', 'Karnataka', '560066', 0x00000000010100000021b07268916d5340aaf1d24d62f02940),
('P0027', 'O0014', 'Bangalore Survey No. 129/7', 1, 12.93750000, 77.58830000, 25.00, 'Residential', 'City', '101', 'Jayanagar 4th Block', 'Near Cool Joint', 'Opposite Central Library', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x000000000101000000280f0bb5a66553400000000000e02940),
('P0028', 'O0014', 'Bangalore Survey No. 130/8', 0, 12.93900000, 77.59010000, 22.00, 'Commercial', 'City', '101', 'Jayanagar 4th Block', 'Near Cool Joint', 'Opposite Central Library', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x000000000101000000a857ca32c465534054e3a59bc4e02940),
('P0029', 'O0015', 'Bangalore Survey No. 131/9', 1, 12.92780000, 77.58500000, 13.00, 'Residential', 'City', '202', 'Jayanagar 3rd Block', 'Near Jain Temple', 'Opposite Mini Forest Park', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x0000000001010000003d0ad7a3706553402575029a08db2940),
('P0030', 'O0015', 'Bangalore Survey No. 132/10', 0, 12.92920000, 77.58720000, 14.50, 'Commercial', 'City', '202', 'Jayanagar 3rd Block', 'Near Jain Temple', 'Opposite Mini Forest Park', NULL, 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x000000000101000000840d4faf94655340ebe2361ac0db2940),
('P0031', 'O0016', 'S-101/345', 1, 12.93560000, 77.59230000, 20.00, 'Residential', 'City', '303', 'Jayanagar 5th Block', 'Near Adiga’s Restaurant', 'Opposite Madhavan Park', 'Madhavan Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x000000000101000000ee5a423ee8655340744694f606df2940),
('P0032', 'O0016', 'S-102/346', 1, 12.93840000, 77.59170000, 18.00, 'Commercial', 'City', '303', 'Jayanagar 5th Block', 'Near Adiga’s Restaurant', 'Opposite Madhavan Park', 'Madhavan Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', 0x000000000101000000c442ad69de655340ff21fdf675e02940),
('P0033', 'O0017', 'S-201/567', 1, 12.93670000, 77.59440000, 25.00, 'Highway', 'Highway', '404', 'Vijayanagar Main Road', 'Near Maruthi Mandir', 'Opposite ESI Hospital', 'ESI Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x000000000101000000832f4ca60a6653408f53742497df2940),
('P0034', 'O0017', 'S-202/568', 0, 12.93810000, 77.59280000, 28.50, 'Commercial', 'Highway', '404', 'Vijayanagar Main Road', 'Near Maruthi Mandir', 'Opposite ESI Hospital', 'ESI Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x0000000001010000006744696ff065534055c1a8a44ee02940),
('P0035', 'O0018', 'S-301/789', 1, 12.94120000, 77.59400000, 22.00, 'Residential', 'City', '505', 'RPC Layout', 'Next to Vijayanagar Bus Stop', 'Opposite Domino’s Pizza', 'Domino’s Pizza', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x000000000101000000bc749318046653408bfd65f7e4e12940),
('P0036', 'O0018', 'S-302/790', 1, 12.94450000, 77.59510000, 19.00, 'Open land', 'City', '505', 'RPC Layout', 'Next to Vijayanagar Bus Stop', 'Opposite Domino’s Pizza', 'Domino’s Pizza', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x00000000010100000060764f1e16665340dd24068195e32940),
('P0037', 'O0019', 'S-401/901', 1, 12.93410000, 77.59850000, 18.50, 'Residential', 'City', '606', 'Chandra Layout', 'Near Satellite Bus Stand', 'Opposite UCO Bank', 'UCO Bank', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x000000000101000000fca9f1d24d6653402063ee5a42de2940),
('P0038', 'O0019', 'S-402/902', 0, 12.93600000, 77.60000000, 20.00, 'Commercial', 'City', '606', 'Chandra Layout', 'Near Satellite Bus Stand', 'Opposite UCO Bank', 'UCO Bank', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', 0x0000000001010000006666666666665340ac1c5a643bdf2940),
('P0039', 'O0020', 'S-101/45', 1, 15.36450000, 75.13280000, 10.00, 'Commercial', 'City', '101', 'Lamington Road', 'Near Neeligin Road', 'Close to BVB College', 'Clock Tower', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x0000000001010000002a3a92cb7fc85240b4c876be9fba2e40),
('P0040', 'O0020', 'S-102/46', 1, 15.37050000, 75.13420000, 12.50, 'Residential', 'City', '102', 'Station Road', 'Near Rani Chennamma Circle', 'Opposite SBI Bank', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x000000000101000000e3c798bb96c8524004560e2db2bd2e40),
('P0041', 'O0021', 'S-201/10', 1, 15.36800000, 75.13850000, 9.80, 'Highway', 'Highway', '202', 'Station Road', 'Next to SBI Bank', 'Opposite Railway Station', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x000000000101000000be9f1a2fddc8524023dbf97e6abc2e40),
('P0042', 'O0021', 'S-202/11', 1, 15.36920000, 75.13980000, 11.20, 'Open land', 'City', '203', 'Near Railway Station', 'Opposite Gokul Theater', NULL, 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x000000000101000000c5feb27bf2c85240cc5d4bc807bd2e40),
('P0043', 'O0022', 'S-303/20', 0, 15.37460000, 75.14100000, 13.50, 'Traffic signals', 'Highway', '303', 'Neeligin Road', 'Near Shankar Coffee', 'Close to Gokul Theater', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x0000000001010000001b2fdd2406c95240c7293a92cbbf2e40),
('P0044', 'O0022', 'S-304/21', 0, 15.37600000, 75.14250000, 14.00, 'Commercial', 'City', '304', 'Near Gokul Theater', 'Close to Shankar Coffee', NULL, 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', 0x00000000010100000085eb51b81ec952408d976e1283c02e40),
('P0045', 'O0023', 'S-342/564', 1, 12.30560000, 76.65470000, 10.20, 'Residential', 'City', '404', 'Chamundi Hill Road', 'Near Zoo Park', 'Opposite Mysore Palace', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x0000000001010000003d2cd49ae6295340b1506b9a779c2840),
('P0046', 'O0023', 'S-342/565', 0, 12.30740000, 76.65810000, 12.30, 'Commercial', 'City', '405', 'Chamundi Hill Road', 'Near Zoo Park', 'Opposite Mysore Palace', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x000000000101000000d95f764f1e2a5340af946588639d2840),
('P0047', 'O0024', 'S-343/567', 1, 12.30880000, 76.66020000, 14.70, 'Residential', 'City', '505', 'Chamundi Hill Road', 'Next to Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x0000000001010000006e3480b7402a534075029a081b9e2840),
('P0048', 'O0024', 'S-343/568', 0, 12.31000000, 76.66310000, 18.40, 'Commercial', 'City', '506', 'Chamundi Hill Road', 'Next to Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x000000000101000000917efb3a702a53401f85eb51b89e2840),
('P0049', 'O0025', 'S-345/569', 1, 12.31150000, 76.66530000, 11.20, 'Residential', 'City', '606', 'Chamundi Hill Road', 'Near Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x000000000101000000d8817346942a5340736891ed7c9f2840),
('P0050', 'O0025', 'S-345/570', 0, 12.31230000, 76.66840000, 16.50, 'Commercial', 'City', '607', 'Chamundi Hill Road', 'Near Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', 0x0000000001010000005f29cb10c72a5340e4141dc9e59f2840),
('P0051', 'O0026', 'S-101/789', 0, 12.91560000, 74.85240000, 12.50, 'Residential', 'City', '301', 'Hampankatta Road', 'Near City Center Mall', 'Opposite Mangala Stadium', 'Mangala Stadium', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', 0x00000000010100000011c7bab88db65240696ff085c9d42940),
('P0052', 'O0027', 'S-102/790', 1, 12.91800000, 74.85120000, 13.00, 'Commercial', 'City', '402', 'Balmatta Road', 'Near Mangala Stadium', 'Opposite City Center Mall', 'City Center Mall', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', 0x000000000101000000bc96900f7ab65240bc74931804d62940),
('P0053', 'O0028', 'S-103/791', 1, 12.91920000, 74.84980000, 14.00, 'Open land', 'City', '503', 'Kankanady', 'Near Bharat Mall', 'Opposite Mangala Stadium', 'Mangala Stadium', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', 0x00000000010100000003098a1f63b6524066f7e461a1d62940),
('P0054', 'O0029', 'S-104/792', 1, 15.84850000, 74.49760000, 18.00, 'Residential', 'City', '601', 'College Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 0x000000000101000000569fabadd89f5240df4f8d976eb22f40),
('P0055', 'O0030', 'S-105/793', 1, 15.86230000, 74.48910000, 16.50, 'Commercial', 'City', '702', 'Shivaji Nagar', 'Near KLE College', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 0x0000000001010000004f1e166a4d9f52407daeb6627fb92f40),
('P0056', 'O0031', 'S-106/794', 0, 15.85890000, 74.49170000, 17.00, 'Traffic signals', 'City', '803', 'Gokak Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 0x0000000001010000005ddc4603789f52409d11a5bdc1b72f40),
('P0057', 'O0032', 'S-107/795', 1, 15.85740000, 74.49030000, 15.20, 'Residential', 'City', '904', 'Camp Road', 'Near KLE College', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 0x000000000101000000a54e4013619f5240492eff21fdb62f40),
('P0058', 'O0033', 'S-108/796', 1, 15.85600000, 74.48980000, 19.00, 'Open land', 'City', '1005', 'Khanapur Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', 0x0000000001010000002c6519e2589f524083c0caa145b62f40),
('P0059', 'O0034', 'S-109/797', 0, 15.84810000, 74.49780000, 16.00, 'Commercial', 'City', '1101', 'PB Road', 'Near GMIT College', 'Opposite Kundwada Lake', 'Kundwada Lake', 'Davangere', 'Davangere', 'Karnataka', '577002', 0x000000000101000000b9fc87f4db9f5240a779c7293ab22f40),
('P0060', 'O0035', 'S-110/798', 1, 15.82000000, 74.49150000, 14.50, 'Traffic signals', 'City', '1202', 'Ashok Nagar', 'Near GMIT College', 'Opposite Kundwada Lake', 'Kundwada Lake', 'Davangere', 'Davangere', 'Karnataka', '577002', 0x000000000101000000fa7e6abc749f5240a4703d0ad7a32f40);

--
-- Triggers `property`
--
DROP TRIGGER IF EXISTS `updatePropertyLocation`;
DELIMITER $$
CREATE TRIGGER `updatePropertyLocation` BEFORE INSERT ON `property` FOR EACH ROW BEGIN
SET NEW.property_location = ST_PointFromText(
CONCAT('POINT(', NEW.property_longitude, ' ', NEW.property_latitude, ')')
);
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `updatePropertyLocationOnUpdate`;
DELIMITER $$
CREATE TRIGGER `updatePropertyLocationOnUpdate` BEFORE UPDATE ON `property` FOR EACH ROW BEGIN
SET NEW.property_location = ST_PointFromText(
CONCAT('POINT(', NEW.property_longitude, ' ', NEW.property_latitude, ')')
);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `property_owner`
--

DROP TABLE IF EXISTS `property_owner`;
CREATE TABLE IF NOT EXISTS `property_owner` (
  `owner_id` varchar(5) NOT NULL,
  `owner_name` varchar(255) NOT NULL,
  `owner_phone` char(10) NOT NULL,
  `owner_email` varchar(255) NOT NULL,
  `owner_password_hash_text` varchar(255) NOT NULL,
  `owner_username` varchar(50) NOT NULL,
  `owner_profile_pic` text,
  `plot_number` varchar(50) DEFAULT NULL,
  `street_name` varchar(255) DEFAULT NULL,
  `address_line1` varchar(255) DEFAULT NULL,
  `address_line2` varchar(255) DEFAULT NULL,
  `landmark` varchar(255) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` char(6) NOT NULL,
  `owner_aadhar_number` char(12) DEFAULT NULL,
  `owner_aadharfile` text,
  PRIMARY KEY (`owner_id`),
  UNIQUE KEY `owner_email` (`owner_email`),
  UNIQUE KEY `owner_username` (`owner_username`),
  UNIQUE KEY `owner_aadhar_number` (`owner_aadhar_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `property_owner`
--

INSERT INTO `property_owner` (`owner_id`, `owner_name`, `owner_phone`, `owner_email`, `owner_password_hash_text`, `owner_username`, `owner_profile_pic`, `plot_number`, `street_name`, `address_line1`, `address_line2`, `landmark`, `city`, `district`, `state`, `pincode`, `owner_aadhar_number`, `owner_aadharfile`) VALUES
('O0001', 'Rajesh Kumar', '9123456789', 'rajesh.kumar@gmail.com', 'hashed_password_1', 'rajesh_k', NULL, '202', 'Brigade Road', 'Near Church Street', NULL, 'MG Road Metro Station', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456789012', NULL),
('O0002', 'Ananya Sharma', '9876543210', 'ananya.sharma@gmail.com', 'hashed_password_2', 'ananya_sharma', NULL, '303', 'Residency Road', 'Opposite Bishop Cotton School', NULL, 'Richmond Circle', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456789013', NULL),
('O0003', 'Vinod Patil', '9012345678', 'vinod.patil@yahoo.com', 'hashed_password_3', 'vinod_p', NULL, '404', 'Church Street', 'Next to Empire Hotel', NULL, 'Church Street', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456789014', NULL),
('O0004', 'Priya Desai', '8765432109', 'priya.desai@outlook.com', 'hashed_password_4', 'priya_d', NULL, '505', 'MG Road', 'Near Lido Mall', NULL, 'Lido Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456789015', NULL),
('O0005', 'Arjun Nair', '8901234567', 'arjun.nair@rediffmail.com', 'hashed_password_5', 'arjun_nair', NULL, '606', 'Ulsoor Road', 'Near Ulsoor Lake', NULL, 'Ulsoor Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456789016', NULL),
('O0006', 'Siddharth Rao', '7890123456', 'siddharth.rao@gmail.com', 'hashed_password_6', 'siddharth_rao', NULL, '101', 'Outer Ring Road', 'Near Manyata Embassy Tech Park', NULL, 'Manyata Tech Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', '234567890123', NULL),
('O0007', 'Ritika Sen', '8901234568', 'ritika.sen@yahoo.com', 'hashed_password_7', 'ritika_sen', NULL, '202', 'Thanisandra Road', 'Near Elements Mall', NULL, 'Elements Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', '234567890124', NULL),
('O0008', 'Akash Mehta', '9012345679', 'akash.mehta@outlook.com', 'hashed_password_8', 'akash_mehta', NULL, '303', 'Nagavara Main Road', 'Close to Nagavara Lake', NULL, 'Nagavara Lake', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', '234567890125', NULL),
('O0009', 'Neha Agarwal', '9123456781', 'neha.agarwal@gmail.com', 'hashed_password_9', 'neha_agarwal', NULL, '404', 'Hebbal Kempapura', 'Opposite Esteem Mall', NULL, 'Esteem Mall', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', '234567890126', NULL),
('O0010', 'Manoj Kulkarni', '9876543212', 'manoj.kulkarni@rediffmail.com', 'hashed_password_10', 'manoj_kulkarni', NULL, '505', 'Rachenahalli', 'Near Lake View Apartments', NULL, 'Lake View Apartments', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560024', '234567890127', NULL),
('O0011', 'Rohan Iyer', '7987654321', 'rohan.iyer@gmail.com', 'hashed_password_11', 'rohan_iyer', NULL, '101', 'ITPL Main Road', 'Close to Vydehi Hospital', NULL, 'Vydehi Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', '345678901234', NULL),
('O0012', 'Anjali Gupta', '8123456789', 'anjali.gupta@yahoo.com', 'hashed_password_12', 'anjali_gupta', NULL, '202', 'Whitefield Main Road', 'Near Prestige Shantiniketan', NULL, 'Prestige Shantiniketan', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', '345678901235', NULL),
('O0013', 'Vikram Deshmukh', '9234567890', 'vikram.deshmukh@outlook.com', 'hashed_password_13', 'vikram_desh', NULL, '303', 'EPIP Zone', 'Close to SAP Labs', NULL, 'SAP Labs', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560066', '345678901236', NULL),
('O0014', 'Prakash Reddy', '7896543210', 'prakash.reddy@gmail.com', 'hashed_password_14', 'prakash_reddy', 'O0014_profile_pic.jpg', '101', 'Jayanagar 4th Block', 'Near Cool Joint', 'Opposite Central Library', 'Central Library', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', '456789012345', 'O0014_aadharfile.pdf'),
('O0015', 'Kavya Rao', '8123456781', 'kavya.rao@yahoo.com', 'hashed_password_15', 'kavya_rao', 'O0015_profile_pic.jpg', '202', 'Jayanagar 3rd Block', 'Near Jain Temple', 'Opposite Mini Forest Park', 'Mini Forest Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', '456789012346', 'O0015_aadharfile.pdf'),
('O0016', 'Rahul Verma', '9234567892', 'rahul.verma@outlook.com', 'hashed_password_16', 'rahul_verma', 'O0016_profile_pic.jpg', '303', 'Jayanagar 5th Block', 'Near Adiga’s Restaurant', 'Opposite Madhavan Park', 'Madhavan Park', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560011', '456789012347', 'O0016_aadharfile.pdf'),
('O0017', 'Meena Sharma', '8345678903', 'meena.sharma@gmail.com', 'hashed_password_17', 'meena_sharma', 'O0017_profile_pic.jpg', '404', 'Vijayanagar Main Road', 'Near Maruthi Mandir', 'Opposite ESI Hospital', 'ESI Hospital', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', '567890123456', 'O0017_aadharfile.pdf'),
('O0018', 'Abhishek Nair', '7456789123', 'abhishek.nair@yahoo.com', 'hashed_password_18', 'abhishek_nair', 'O0018_profile_pic.jpg', '505', 'RPC Layout', 'Next to Vijayanagar Bus Stop', 'Opposite Domino’s Pizza', 'Domino’s Pizza', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', '567890123457', 'O0018_aadharfile.pdf'),
('O0019', 'Sneha Joshi', '8567890124', 'sneha.joshi@rediffmail.com', 'hashed_password_19', 'sneha_joshi', 'O0019_profile_pic.jpg', '606', 'Chandra Layout', 'Near Satellite Bus Stand', 'Opposite UCO Bank', 'UCO Bank', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560040', '567890123458', 'O0019_aadharfile.pdf'),
('O0020', 'Suresh Patil', '7890123456', 'suresh.patil@gmail.com', 'hashed_password_20', 'suresh_patil', 'O0020_profile_pic.jpg', '101', 'Lamington Road', 'Near Neeligin Road', 'Close to BVB College', 'Clock Tower', 'Hubli', 'Dharwad', 'Karnataka', '580020', '546789012345', 'O0020_aadharfile.pdf'),
('O0021', 'Asha Kulkarni', '8901234567', 'asha.kulkarni@yahoo.com', 'hashed_password_21', 'asha_kulkarni', 'O0021_profile_pic.jpg', '202', 'Station Road', 'Next to SBI Bank', 'Opposite Railway Station', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', '423789012346', 'O0021_aadharfile.pdf'),
('O0022', 'Manoj Reddy', '9012345678', 'manoj.reddy@outlook.com', 'hashed_password_22', 'manoj_reddy', 'O0022_profile_pic.jpg', '303', 'Neeligin Road', 'Near Shankar Coffee', 'Close to Gokul Theater', 'Rani Chennamma Circle', 'Hubli', 'Dharwad', 'Karnataka', '580020', '456781212347', 'O0022_aadharfile.pdf'),
('O0023', 'Rajiv Desai', '7890123456', 'rajiv.desai@gmail.com', 'hashed_password_23', 'rajiv_desai', 'O0023_profile_pic.jpg', '404', 'Chamundi Hill Road', 'Near Zoo Park', 'Opposite Mysore Palace', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', '897890123456', 'O0023_aadharfile.pdf'),
('O0024', 'Kavita Nair', '8901234567', 'kavita.nair@yahoo.com', 'hashed_password_24', 'kavita_nair', 'O0024_profile_pic.jpg', '505', 'Chamundi Hill Road', 'Next to Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', '967890123457', 'O0024_aadharfile.pdf'),
('O0025', 'Shivani Mehta', '9012345678', 'shivani.mehta@outlook.com', 'hashed_password_25', 'shivani_mehta', 'O0025_profile_pic.jpg', '606', 'Chamundi Hill Road', 'Near Mysore Palace', 'Opposite Zoo Park', 'Zoo Park', 'Mysore', 'Mysore', 'Karnataka', '570010', '534890123458', 'O0025_aadharfile.pdf'),
('O0026', 'Prashant Rai', '9912345670', 'prashant.rai@gmail.com', 'hashed_password_26', 'prashant_rai', 'O0026_profile_pic.jpg', '301', 'Hampankatta Road', 'Near City Center Mall', 'Opposite Mangala Stadium', 'Mangala Stadium', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', '678901234567', 'O0026_aadharfile.pdf'),
('O0027', 'Kavitha Bhat', '9723456789', 'kavitha.bhat@yahoo.com', 'hashed_password_27', 'kavitha_bhat', 'O0027_profile_pic.jpg', '402', 'Balmatta Road', 'Near Mangala Stadium', 'Opposite City Center Mall', 'City Center Mall', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', '678901234568', 'O0027_aadharfile.pdf'),
('O0028', 'Ravi Shenoy', '9887654321', 'ravi.shenoy@outlook.com', 'hashed_password_28', 'ravi_shenoy', 'O0028_profile_pic.jpg', '503', 'Kankanady', 'Near Bharat Mall', 'Opposite Mangala Stadium', 'Mangala Stadium', 'Mangalore', 'Dakshina Kannada', 'Karnataka', '575001', '678901234569', 'O0028_aadharfile.pdf'),
('O0029', 'Veeresh Joshi', '9534678901', 'veeresh.joshi@gmail.com', 'hashed_password_29', 'veeresh_joshi', 'O0029_profile_pic.jpg', '601', 'College Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', '789012345670', 'O0029_aadharfile.pdf'),
('O0030', 'Sushma Desai', '9223345670', 'sushma.desai@yahoo.com', 'hashed_password_30', 'sushma_desai', 'O0030_profile_pic.jpg', '702', 'Shivaji Nagar', 'Near KLE College', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', '789012345671', 'O0030_aadharfile.pdf'),
('O0031', 'Shailesh Patil', '9334567891', 'shailesh.patil@rediffmail.com', 'hashed_password_31', 'shailesh_patil', 'O0031_profile_pic.jpg', '803', 'Gokak Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', '789012345672', 'O0031_aadharfile.pdf'),
('O0032', 'Vidya Kumar', '9401234567', 'vidya.kumar@gmail.com', 'hashed_password_32', 'vidya_kumar', 'O0032_profile_pic.jpg', '904', 'Camp Road', 'Near KLE College', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', '789012345673', 'O0032_aadharfile.pdf'),
('O0033', 'Ashok More', '9123456780', 'ashok.more@yahoo.com', 'hashed_password_33', 'ashok_more', 'O0033_profile_pic.jpg', '1005', 'Khanapur Road', 'Near KLE University', 'Opposite Military Mahadev', 'Military Mahadev', 'Belgaum', 'Belgaum', 'Karnataka', '590001', '789012345674', 'O0033_aadharfile.pdf'),
('O0034', 'Vijay Kumar', '9012345678', 'vijay.kumar@gmail.com', 'hashed_password_34', 'vijay_kumar', 'O0034_profile_pic.jpg', '1101', 'PB Road', 'Near GMIT College', 'Opposite Kundwada Lake', 'Kundwada Lake', 'Davangere', 'Davangere', 'Karnataka', '577002', '890123456789', 'O0034_aadharfile.pdf'),
('O0035', 'Sowmya Reddy', '9623456789', 'sowmya.reddy@yahoo.com', 'hashed_password_35', 'sowmya_reddy', 'O0035_profile_pic.jpg', '1202', 'Ashok Nagar', 'Near GMIT College', 'Opposite Kundwada Lake', 'Kundwada Lake', 'Davangere', 'Davangere', 'Karnataka', '577002', '890123456790', 'O0035_aadharfile.pdf'),
('O0100', 'Rajesh Kumar', '9123458789', 'rajsdsesh.kumar@gmail.com', 'hashed_passwsdsord_1', 'rajesdfdsh_k', 'O0100_profile_pic.jpg', '202', 'Brigade Road', 'Near Church Street', 'landmark', 'MG Road Metro Station', 'Bangalore', 'Bangalore Urban', 'Karnataka', '560001', '123456089012', 'O0100_aadharfile.pdf');

--
-- Triggers `property_owner`
--
DROP TRIGGER IF EXISTS `setDefaultFilesInsert`;
DELIMITER $$
CREATE TRIGGER `setDefaultFilesInsert` BEFORE INSERT ON `property_owner` FOR EACH ROW BEGIN
    -- Update owner_profile_pic to formatted value only if it is NOT NULL
    IF NEW.owner_profile_pic IS NOT NULL THEN
    SET NEW.owner_profile_pic = CONCAT(NEW.owner_id, '_profile_pic.jpg');
    END IF;
    
    -- Update owner_aadharfile to formatted value only if it is NOT NULL
    IF NEW.owner_aadharfile IS NOT NULL THEN
        SET NEW.owner_aadharfile = CONCAT(NEW.owner_id, '_aadharfile.pdf');
    END IF;
    
    END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `setDefaultFilesUpdate`;
DELIMITER $$
CREATE TRIGGER `setDefaultFilesUpdate` BEFORE UPDATE ON `property_owner` FOR EACH ROW BEGIN
-- Update owner_profile_pic to formatted value only if it is NOT NULL and has changed
IF NEW.owner_profile_pic IS NOT NULL AND NEW.owner_profile_pic != OLD.owner_profile_pic THEN
SET NEW.owner_profile_pic = CONCAT(NEW.owner_id, '_profile_pic.jpg');
END IF;

-- Update owner_aadharfile to formatted value only if it is NOT NULL and has changed
IF NEW.owner_aadharfile IS NOT NULL AND NEW.owner_aadharfile != OLD.owner_aadharfile THEN
    SET NEW.owner_aadharfile = CONCAT(NEW.owner_id, '_aadharfile.pdf');
END IF;

END
$$
DELIMITER ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `branch`
--
ALTER TABLE `branch`
  ADD CONSTRAINT `branch_ibfk_1` FOREIGN KEY (`agency_id`) REFERENCES `advertisement_agency` (`agency_id`) ON DELETE CASCADE;

--
-- Constraints for table `contract`
--
ALTER TABLE `contract`
  ADD CONSTRAINT `contract_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `property_owner` (`owner_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `contract_ibfk_2` FOREIGN KEY (`branch_id`) REFERENCES `branch` (`branch_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `contract_ibfk_3` FOREIGN KEY (`property_id`) REFERENCES `property` (`property_id`) ON DELETE CASCADE;

--
-- Constraints for table `owner_bank_details`
--
ALTER TABLE `owner_bank_details`
  ADD CONSTRAINT `owner_bank_details_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `property_owner` (`owner_id`) ON DELETE CASCADE;

--
-- Constraints for table `payment`
--
ALTER TABLE `payment`
  ADD CONSTRAINT `payment_ibfk_1` FOREIGN KEY (`contract_number`) REFERENCES `contract` (`contract_number`),
  ADD CONSTRAINT `payment_ibfk_2` FOREIGN KEY (`owner_bank_details_id`) REFERENCES `owner_bank_details` (`owner_bank_details_id`);

--
-- Constraints for table `property`
--
ALTER TABLE `property`
  ADD CONSTRAINT `property_ibfk_1` FOREIGN KEY (`owner_id`) REFERENCES `property_owner` (`owner_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
