
-- CloudRecover inventory test data
-- Requires Prisma migrations to have been applied.
-- Run against an empty test database.
-- This is a seed script, not an RDS backup.

BEGIN;

-- ==========================================
-- ORIGINAL PRODUCTS
-- ==========================================

INSERT INTO "products" (
    "id",
    "sku",
    "name",
    "description",
    "quantity",
    "createdAt",
    "updatedAt",
    "deletedAt"
)
VALUES
(
    '4ad67f61-70b9-43f1-a496-1d9f63aeb101',
    'CR-SSD-001',
    'Enterprise SSD 1TB',
    '1TB NVMe solid-state drive for recovery server storage.',
    24,
    '2026-10-01 09:00:00',
    '2026-10-05 14:30:00',
    NULL
),
(
    '4ad67f61-70b9-43f1-a496-1d9f63aeb102',
    'CR-RAM-016',
    'DDR5 Memory Module 16GB',
    '16GB DDR5 memory module for application servers.',
    12,
    '2026-10-02 10:15:00',
    '2026-10-06 11:45:00',
    NULL
),
(
    '4ad67f61-70b9-43f1-a496-1d9f63aeb103',
    'CR-NIC-10G',
    '10GbE Network Adapter',
    'Dual-port 10 Gigabit Ethernet adapter for infrastructure hosts.',
    7,
    '2026-10-03 13:20:00',
    '2026-10-07 16:10:00',
    NULL
);

-- ==========================================
-- ORIGINAL STOCK MOVEMENTS
-- ==========================================

INSERT INTO "stock_movements" (
    "id",
    "productId",
    "change",
    "reason",
    "createdAt"
)
VALUES
(
    '8be36115-449e-4815-a2b7-1b1c5ea20101',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb101',
    30,
    'Initial stock received',
    '2026-10-01 09:00:00'
),
(
    '8be36115-449e-4815-a2b7-1b1c5ea20102',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb101',
    -6,
    'Allocated to recovery server deployment',
    '2026-10-05 14:30:00'
),
(
    '8be36115-449e-4815-a2b7-1b1c5ea20103',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb102',
    16,
    'Initial stock received',
    '2026-10-02 10:15:00'
),
(
    '8be36115-449e-4815-a2b7-1b1c5ea20104',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb102',
    -4,
    'Allocated to application server deployment',
    '2026-10-06 11:45:00'
),
(
    '8be36115-449e-4815-a2b7-1b1c5ea20105',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb103',
    10,
    'Initial stock received',
    '2026-10-03 13:20:00'
),
(
    '8be36115-449e-4815-a2b7-1b1c5ea20106',
    '4ad67f61-70b9-43f1-a496-1d9f63aeb103',
    -3,
    'Allocated to network recovery hosts',
    '2026-10-07 16:10:00'
);

-- ==========================================
-- GENERATE 80 ADDITIONAL PRODUCTS
-- ==========================================

WITH inventory AS (
    SELECT
        n,
        md5('cloudrecover-product-' || n)::uuid AS id,
        (ARRAY[
            'Enterprise SSD 2TB',
            'Enterprise SSD 4TB',
            'SATA SSD 960GB',
            'NAS Hard Drive 8TB',
            'NAS Hard Drive 12TB',
            'DDR5 Memory Module 32GB',
            'DDR5 Memory Module 64GB',
            'DDR4 ECC Memory 16GB',
            'Server CPU 8-Core',
            'Server CPU 16-Core',
            'Server CPU 32-Core',
            '25GbE Network Adapter',
            '40GbE Network Adapter',
            '100GbE Network Adapter',
            'Managed Switch 8-Port',
            'Managed Switch 24-Port',
            'Managed Switch 48-Port',
            '10GbE Aggregation Switch',
            'Enterprise Edge Router',
            'VPN Gateway Appliance',
            'Firewall Appliance',
            'Wi-Fi 6 Access Point',
            'SFP+ Optical Transceiver',
            'Fiber Patch Cable',
            'Cat6 Ethernet Cable',
            'UPS 1000VA',
            'UPS 2200VA',
            'UPS 3000VA',
            'Rack Power Distribution Unit',
            'Redundant Server PSU',
            'Server Cooling Fan',
            'Server Rack 24U',
            'Server Rack 42U',
            'Server Rail Kit',
            'NAS Storage Enclosure',
            'Backup Tape Cartridge',
            'LTO Tape Drive',
            'Hardware Security Key',
            'TPM Security Module',
            'Rack Server 2U'
        ])[(n - 1) % 40 + 1] AS product_name,
        20 + (n % 30) AS initial_stock,
        2 + (n % 9) AS first_allocation,
        10 + (n % 17) AS restock,
        3 + (n % 12) AS regular_final_allocation
    FROM generate_series(1, 80) AS n
),
calculated AS (
    SELECT
        *,
        CASE
            WHEN n % 10 = 0 THEN
                initial_stock - first_allocation + restock
            ELSE regular_final_allocation
        END AS final_allocation
    FROM inventory
)
INSERT INTO "products" (
    "id",
    "sku",
    "name",
    "description",
    "quantity",
    "createdAt",
    "updatedAt",
    "deletedAt"
)
SELECT
    id,
    'CR-INV-' || lpad(n::text, 3, '0'),
    product_name || ' - Batch ' || n,
    'Infrastructure inventory item for CloudRecover disaster recovery testing. Batch ' || n || '.',
    initial_stock - first_allocation + restock - final_allocation,
    timestamp '2026-10-01 08:00:00'
        + (n % 12) * interval '1 day',
    timestamp '2026-10-16 11:00:00'
        + (n % 12) * interval '1 day',
    NULL
FROM calculated;

-- ==========================================
-- GENERATE STOCK MOVEMENT HISTORY
-- ==========================================

WITH inventory AS (
    SELECT
        n,
        md5('cloudrecover-product-' || n)::uuid AS product_id,
        20 + (n % 30) AS initial_stock,
        2 + (n % 9) AS first_allocation,
        10 + (n % 17) AS restock,
        3 + (n % 12) AS regular_final_allocation
    FROM generate_series(1, 80) AS n
),
calculated AS (
    SELECT
        *,
        CASE
            WHEN n % 10 = 0 THEN
                initial_stock - first_allocation + restock
            ELSE regular_final_allocation
        END AS final_allocation
    FROM inventory
),
movements AS (
    SELECT
        n,
        product_id,
        1 AS movement_number,
        initial_stock AS stock_change,
        'Initial stock received' AS reason
    FROM calculated

    UNION ALL

    SELECT
        n,
        product_id,
        2,
        -first_allocation,
        'Allocated to primary infrastructure deployment'
    FROM calculated

    UNION ALL

    SELECT
        n,
        product_id,
        3,
        restock,
        'Restocked for disaster recovery readiness'
    FROM calculated

    UNION ALL

    SELECT
        n,
        product_id,
        4,
        -final_allocation,
        'Allocated to recovery-region equipment pool'
    FROM calculated
)
INSERT INTO "stock_movements" (
    "id",
    "productId",
    "change",
    "reason",
    "createdAt"
)
SELECT
    md5(
        'cloudrecover-movement-'
        || n || '-' || movement_number
    )::uuid,
    product_id,
    stock_change,
    reason,
    timestamp '2026-10-01 08:00:00'
        + (n % 12) * interval '1 day'
        + (movement_number - 1) * interval '5 days'
        + movement_number * interval '1 hour'
FROM movements;

COMMIT;

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Expected: 83
SELECT COUNT(*) AS total_products
FROM "products";

-- Expected: 326
SELECT COUNT(*) AS total_movements
FROM "stock_movements";

-- Expected: 8
SELECT COUNT(*) AS out_of_stock
FROM "products"
WHERE "quantity" = 0;

-- Expected: 0 mismatches
SELECT
    p."sku",
    p."name",
    p."quantity",
    COALESCE(SUM(sm."change"), 0) AS calculated_quantity
FROM "products" p
LEFT JOIN "stock_movements" sm
    ON p."id" = sm."productId"
GROUP BY
    p."id",
    p."sku",
    p."name",
    p."quantity"
HAVING
    p."quantity" <> COALESCE(SUM(sm."change"), 0);
