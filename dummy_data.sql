INSERT INTO payments (id, transaction_id, community_id, payer_id, payment_type, amount, escrow_status, idempotency_key) VALUES
(UUID(), '0555bc8d-96e8-4750-9b42-832094ed3536', 'c1000000-0000-0000-0000-000000000001', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', 'rental_fee', 20.00, 'released', UUID()),
(UUID(), '0555bc8d-96e8-4750-9b42-832094ed3536', 'c1000000-0000-0000-0000-000000000001', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', 'security_deposit', 50.00, 'refunded', UUID()),
(UUID(), '2a8bb11c-4840-4ccd-aba7-1a52a8a08b71', 'c1000000-0000-0000-0000-000000000001', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', 'rental_fee', 15.00, 'released', UUID()),
(UUID(), '8fda06d6-0bae-4cf5-9f39-24d930e59d68', 'c1000000-0000-0000-0000-000000000001', 'ccfd8b08-ce68-4c31-aa72-98aeb2564c2d', 'rental_fee', 10.00, 'held_in_escrow', UUID()),
(UUID(), '8fda06d6-0bae-4cf5-9f39-24d930e59d68', 'c1000000-0000-0000-0000-000000000001', 'ccfd8b08-ce68-4c31-aa72-98aeb2564c2d', 'security_deposit', 30.00, 'held_in_escrow', UUID());

INSERT INTO reviews (id, transaction_id, community_id, reviewer_id, reviewee_id, rating, comment) VALUES
(UUID(), '0555bc8d-96e8-4750-9b42-832094ed3536', 'c1000000-0000-0000-0000-000000000001', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', '08d29f91-3a97-4efa-91a5-126b0ff929d2', 5, 'Great item, exactly what I needed!'),
(UUID(), '0555bc8d-96e8-4750-9b42-832094ed3536', 'c1000000-0000-0000-0000-000000000001', '08d29f91-3a97-4efa-91a5-126b0ff929d2', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', 5, 'Returned right on time and in perfect condition.'),
(UUID(), '2a8bb11c-4840-4ccd-aba7-1a52a8a08b71', 'c1000000-0000-0000-0000-000000000001', '0ee57674-e6eb-4c31-9d39-d1cc26ddaaed', '08d29f91-3a97-4efa-91a5-126b0ff929d2', 4, 'Good experience overall. Host is very friendly.'),
(UUID(), '8fda06d6-0bae-4cf5-9f39-24d930e59d68', 'c1000000-0000-0000-0000-000000000001', 'ccfd8b08-ce68-4c31-aa72-98aeb2564c2d', '08d29f91-3a97-4efa-91a5-126b0ff929d2', 5, 'Smooth rental! Highly recommend this owner.'),
(UUID(), '8fda06d6-0bae-4cf5-9f39-24d930e59d68', 'c1000000-0000-0000-0000-000000000001', '08d29f91-3a97-4efa-91a5-126b0ff929d2', 'ccfd8b08-ce68-4c31-aa72-98aeb2564c2d', 5, 'Reliable borrower.');
