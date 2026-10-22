-- Sample CloudRecover inventory data for a database with the Prisma
-- migrations already applied. Run with: psql "$DATABASE_URL" -f backup.sql
BEGIN;

INSERT INTO "products" (
    "id",
    "sku",
    "name",
    "description",
    "quantity",
    "createdAt",
    "updatedAt",
    "deletedAt"
) VALUES
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

INSERT INTO "stock_movements" (
    "id",
    "productId",
    "change",
    "reason",
    "createdAt"
) VALUES
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

COMMIT;
