-- Neighborly: remove obvious test/demo item chains from the database.
-- Run this after backing up the database.

START TRANSACTION;

CREATE TEMPORARY TABLE tmp_test_items AS
SELECT id
FROM items
WHERE
    title IN (
        'Txn Visibility Final Test',
        'Key Ring Auto Txn Test 2',
        'Key Ring Auto Txn Test',
        'Incoming Visibility Test 2',
        'Incoming Visibility Test',
        'Approval Rule Test'
    )
    OR LOWER(title) LIKE '%txn visibility final test%'
    OR LOWER(title) LIKE '%final test%'
    OR LOWER(title) LIKE '%test item%'
    OR LOWER(title) LIKE '%test listing%'
    OR LOWER(title) LIKE '%sample item%'
    OR LOWER(title) LIKE '%demo item%'
    OR LOWER(title) LIKE '%placeholder item%'
    OR LOWER(title) LIKE '%dummy item%'
    OR LOWER(description) LIKE '%test data%'
    OR LOWER(description) LIKE '%sample data%'
    OR LOWER(description) LIKE '%demo data%'
    OR LOWER(description) LIKE '%placeholder%'
    OR LOWER(description) LIKE '%dummy%';

DELETE p
FROM payments p
INNER JOIN transactions t ON t.id = p.transaction_id
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE sd
FROM security_deposits sd
INNER JOIN transactions t ON t.id = sd.transaction_id
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE rl
FROM return_logs rl
INNER JOIN transactions t ON t.id = rl.transaction_id
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE d
FROM disputes d
INNER JOIN transactions t ON t.id = d.transaction_id
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE r
FROM reviews r
INNER JOIN transactions t ON t.id = r.transaction_id
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE t
FROM transactions t
INNER JOIN rental_requests rr ON rr.id = t.rental_request_id
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE rr
FROM rental_requests rr
INNER JOIN tmp_test_items ti ON ti.id = rr.item_id;

DELETE i
FROM items i
INNER JOIN tmp_test_items ti ON ti.id = i.id;

DROP TEMPORARY TABLE tmp_test_items;

COMMIT;