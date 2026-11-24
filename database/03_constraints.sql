-- =====================================================================
-- 03_constraints.sql: қосымша шектеулер, индекстер, есеп беру view-ы және
-- деректер тұтастығын тексеру сұраныстары (PostgreSQL)
-- Файл 02_insert_data.sql орындалғаннан кейін іске қосылады.
-- =====================================================================

-- ---------------------------------------------------------------------
-- A. Кестелер арасындағы бағандарға қатысты қосымша CHECK шектеулері
-- ---------------------------------------------------------------------
ALTER TABLE flights
    ADD CONSTRAINT chk_flights_route CHECK (origin_destination_id <> arrival_destination_id);
ALTER TABLE flights
    ADD CONSTRAINT chk_flights_times CHECK (arrival_at > departure_at);
ALTER TABLE clients
    ADD CONSTRAINT chk_clients_passport_len CHECK (LENGTH(passport_number) >= 8);
ALTER TABLE payments
    ADD CONSTRAINT chk_payments_ref_prefix CHECK (transaction_ref LIKE 'TXN-%');
ALTER TABLE insurance
    ADD CONSTRAINT chk_insurance_coverage_min CHECK (coverage_amount_eur >= 15000);
ALTER TABLE tours
    ADD CONSTRAINT chk_tours_cost_sane CHECK (net_cost_per_person < price_per_person * 2);

-- ---------------------------------------------------------------------
-- B. Индекстер (сыртқы кілттер мен жиі қолданылатын сүзгі бағандары)
-- ---------------------------------------------------------------------
CREATE INDEX idx_destinations_country   ON destinations (country_id);
CREATE INDEX idx_hotels_destination     ON hotels (destination_id);
CREATE INDEX idx_packages_destination   ON tour_packages (destination_id);
CREATE INDEX idx_tours_package          ON tours (package_id);
CREATE INDEX idx_tours_departure        ON tours (departure_date);
CREATE INDEX idx_flights_route          ON flights (origin_destination_id, arrival_destination_id);
CREATE INDEX idx_bookings_client        ON bookings (client_id);
CREATE INDEX idx_bookings_tour          ON bookings (tour_id);
CREATE INDEX idx_bookings_date          ON bookings (booking_date);
CREATE INDEX idx_participants_booking   ON booking_participants (booking_id);
CREATE INDEX idx_participants_client    ON booking_participants (client_id);
CREATE INDEX idx_payments_booking       ON payments (booking_id);
CREATE INDEX idx_payments_date          ON payments (payment_date);
CREATE INDEX idx_reviews_booking        ON reviews (booking_id);

-- ---------------------------------------------------------------------
-- C. Есеп беру view-ы: брондаудың ақшалай көрсеткіштері.
--    Жалпы сома кестеде сақталмайды (3NF), ол жолаушылар бағасынан
--    және жеңілдік ережесінен есептеледі.
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS v_booking_financials;
CREATE VIEW v_booking_financials AS
SELECT x.booking_id, x.client_id, x.tour_id, x.booking_date, x.booking_status,
       x.participants_cnt, x.gross_amount, x.discount_amount,
       x.gross_amount - x.discount_amount AS net_amount
FROM (
    SELECT b.booking_id, b.client_id, b.tour_id, b.booking_date, b.booking_status,
           COUNT(bp.participant_id) AS participants_cnt,
           SUM(bp.unit_price)       AS gross_amount,
           CASE
               WHEN d.discount_type = 'percent' THEN ROUND(SUM(bp.unit_price) * d.discount_value / 100, 2)
               WHEN d.discount_type = 'fixed' AND d.discount_value > SUM(bp.unit_price) THEN SUM(bp.unit_price)
               WHEN d.discount_type = 'fixed' THEN d.discount_value
               ELSE 0
           END AS discount_amount
    FROM bookings b
    JOIN booking_participants bp ON bp.booking_id = b.booking_id
    LEFT JOIN discounts d        ON d.discount_id = b.discount_id
    GROUP BY b.booking_id, b.client_id, b.tour_id, b.booking_date, b.booking_status,
             d.discount_type, d.discount_value
) x;

-- ---------------------------------------------------------------------
-- D. Деректер тұтастығын тексеру. Төмендегі сұраныстардың бәрі 0 жол қайтаруы тиіс.
-- ---------------------------------------------------------------------

-- D1. Тур сыйымдылығынан артық жолаушы жазылған турлар
SELECT t.tour_id, t.max_participants, COUNT(bp.participant_id) AS booked
FROM tours t
JOIN bookings b ON b.tour_id = t.tour_id AND b.booking_status <> 'cancelled'
JOIN booking_participants bp ON bp.booking_id = b.booking_id
GROUP BY t.tour_id, t.max_participants
HAVING COUNT(bp.participant_id) > t.max_participants;

-- D2. Брондау күні ұшу күнінен кейін болған жазбалар
SELECT b.booking_id
FROM bookings b JOIN tours t ON t.tour_id = b.tour_id
WHERE b.booking_date >= t.departure_date;

-- D3. Паспорт мерзімі тур аяқталған күннен бұрын бітетін жолаушылар
SELECT bp.participant_id
FROM booking_participants bp
JOIN bookings b ON b.booking_id = bp.booking_id
JOIN tours t    ON t.tour_id = b.tour_id
JOIN clients c  ON c.client_id = bp.client_id
WHERE c.passport_expiry <= t.return_date;

-- D4. Брондаушы клиент жолаушылар тізімінде жоқ брондаулар
SELECT b.booking_id
FROM bookings b
WHERE NOT EXISTS (SELECT 1 FROM booking_participants bp
                  WHERE bp.booking_id = b.booking_id AND bp.client_id = b.client_id);

-- D5. Жеңілдік жарамдылық мерзімінен тыс қолданылған брондаулар
SELECT b.booking_id
FROM bookings b JOIN discounts d ON d.discount_id = b.discount_id
WHERE b.booking_date NOT BETWEEN d.valid_from AND d.valid_to;

-- D6. Тур күндері мен рейс күндері сәйкес келмейтін турлар
SELECT t.tour_id
FROM tours t
JOIN flights f ON f.flight_id = t.outbound_flight_id
JOIN flights r ON r.flight_id = t.return_flight_id
WHERE CAST(f.departure_at AS DATE) <> t.departure_date
   OR CAST(r.departure_at AS DATE) <> t.return_date;

-- D7. Көлік елі мен бағыт елі сәйкес келмейтін турлар
SELECT t.tour_id
FROM tours t
JOIN tour_packages p ON p.package_id = t.package_id
JOIN destinations d  ON d.destination_id = p.destination_id
JOIN transport tr    ON tr.transport_id = t.transport_id
WHERE tr.country_id <> d.country_id;
