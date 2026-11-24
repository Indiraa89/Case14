# Деректер қорының құжаттамасы

Жоба: Saryarka Voyage турагенттігінің ақпараттық жүйесі (Case 14, Travel Agency Management System). ДҚБЖ: PostgreSQL 14+. Барлық деректер ойдан шығарылған және оқу мақсатында генерацияланған.

## 1. Жалпы құрылым

Қор 18 кестеден тұрады. Тапсырмада талап етілген 15 міндетті кестенің (clients, countries, destinations, tour_packages, hotels, flights, guides, tours, bookings, booking_participants, payments, insurance, transport, reviews, discounts) бәрі бар. Үшеуі қосымша енгізілді: `airlines` (авиакомпания атауын рейс жолында қайталамау үшін), `package_hotels` және `tour_guides` (көпке-көп байланыстарды шешетін аралық кестелер). Үшінші қосымша аралық кесте ретінде `booking_participants` қызмет етеді: ол брондау мен клиент арасындағы байланысты жүзеге асырады және өз бетінше атрибуттарға (баға, виза, тамақтану) ие.

Сыртқы кілттер арқылы байланыс құрылымы `erd.png` файлында көрсетілген. Негізгі логика төмендегідей: турпакет белгілі бір бағытқа жатады және қонақүйлермен көпке-көп байланысады; турпакеттің нақты күнге жоспарланған орындалуы (департур) `tours` кестесінде сақталады және екі рейске, бір көлікке, бір немесе бірнеше гидке байланады; клиент турға `bookings` арқылы жазылады, ал жолаушылар құрамы `booking_participants` кестесінде жүргізіледі; ақша қозғалысы `payments`, сақтандыру `insurance`, баға `reviews` кестелерінде.

## 2. Байланыс түрлері

| Байланыс | Түрі | Іске асуы |
|---|---|---|
| countries - destinations | 1:M | destinations.country_id |
| countries - airlines, transport, guides | 1:M | country_id |
| destinations - hotels, tour_packages | 1:M | destination_id |
| destinations - flights | 1:M (екі рет) | origin_destination_id, arrival_destination_id |
| airlines - flights | 1:M | flights.airline_id |
| tour_packages - tours | 1:M | tours.package_id |
| transport - tours | 1:M | tours.transport_id |
| flights - tours | 1:1 (екі рет) | tours.outbound_flight_id, tours.return_flight_id (UNIQUE) |
| tours - bookings | 1:M | bookings.tour_id |
| clients - bookings | 1:M | bookings.client_id |
| discounts - bookings | 1:M (міндетті емес) | bookings.discount_id |
| bookings - payments | 1:M | payments.booking_id |
| bookings - insurance | 1:1 | insurance.booking_id (UNIQUE) |
| bookings - reviews | 1:M | reviews.booking_id |
| tour_packages - hotels | M:M | package_hotels (package_id, hotel_id) |
| tours - guides | M:M | tour_guides (tour_id, guide_id) |
| bookings - clients | M:M | booking_participants (booking_id, client_id) |

## 3. Нормализация (3NF) негіздемесі

Бірінші қалыпты форма: барлық бағандар атомарлы. Мысалы, гидтің тілдері бір бағанда үтірмен жазылмай, `primary_language` және `secondary_language` ретінде бөлінген; жолаушылар құрамы брондау жолына тізім ретінде жазылмай, `booking_participants` кестесінде бір жолаушы бір жол болып сақталады.

Екінші қалыпты форма: құрама кілті бар кестелердің (`package_hotels`, `tour_guides`) атрибуттары кілттің екі бөлігіне де тәуелді. Түн саны мен нөмір санаты нақты бір турпакеттегі нақты бір қонақүйге, ал гид сыйақысы нақты бір турдағы нақты бір гидке қатысты.

Үшінші қалыпты форма: кілттік емес атрибуттар бір-біріне транзитивті тәуелді емес. Авиакомпания атауы мен елі рейс жолына емес, `airlines` кестесіне шығарылған; ел атауы мен визалық режим бағыт жолында қайталанбайды; жеңілдік пайызы брондау жолына көшірілмейді.

Саналы түрде сақталған тарихи (брондау сәтіндегі) мәндер: `booking_participants.unit_price` (жолаушыға брондау сәтіндегі баға, тур бағасы кейін өзгерсе де бұрынғы шарт бұзылмауы үшін), `tours.net_cost_per_person` (калькуляция парағының нәтижесі, оның құрамдас бөліктері кестелерде толық сақталмайды) және `tour_packages.base_price`. Брондаудың жалпы сомасы бөлек бағанда сақталмайды: ол `v_booking_financials` view-ында жолаушылар бағасы мен жеңілдік ережесінен есептеледі, осылайша есептелетін мән мен бастапқы деректер арасында қайшылық пайда болмайды.

## 4. Шектеулер

Әр кестеде бастапқы кілт (PK) бар; барлық байланыстар FOREIGN KEY арқылы бекітілген. NOT NULL міндетті бағандарға қойылған, UNIQUE бірегей сәйкестендіргіштерге (паспорт нөмірі, электрондық пошта, промокод, полис нөмірі, транзакция коды, ISO және IATA кодтары), DEFAULT статус және белгі бағандарына, CHECK мәндер диапазондары мен тізімдеріне қолданылады.

Бірнеше баған бойынша бизнес ережелері кесте деңгейінде жазылған: `chk_tour_dates` (оралу күні шығу күнінен кейін), `chk_cancel_consistency` (бас тартылған брондауда күні мен себебі міндетті, ал бас тартылмағанда болмауы тиіс), `chk_discount_period`, `chk_discount_percent` (пайыздық жеңілдік 50%-дан аспайды), `chk_package_group`, `chk_insurance_period`. `03_constraints.sql` файлында рейстің бағыты мен уақытына, паспорт ұзындығына, транзакция кодының форматына қатысты қосымша шектеулер ALTER TABLE арқылы қосылады.

Каскадты өшіру тек толық тәуелді жолдарға қолданылады: турпакет өшірілсе, оның қонақүй тізімі, тур өшірілсе, гид тағайындаулары, брондау өшірілсе, жолаушылар тізімі, полис және пікірлер өшіріледі. Төлемдер брондаумен ON DELETE CASCADE арқылы байланыспаған: қаржылық жазбаларды абайсызда жоюға жол берілмейді.

## 5. Индекстер мен view

Сыртқы кілттерге және жиі сүзілетін бағандарға 14 индекс құрылған (`03_constraints.sql`, B бөлімі). `v_booking_financials` view-ы әр брондау бойынша жолаушылар санын, жалпы соманы, жеңілдік сомасын және төленуге тиісті соманы қайтарады. Жеңілдік сомасы пайыздық жағдайда жалпы соманың пайызы, тұрақты жағдайда жалпы соманы аспайтындай тұрақты мән ретінде есептеледі.

## 6. Деректер көлемі

| Кесте | Жазба саны | Тапсырма бойынша талап | Талапқа сәйкестік |
|---|---|---|---|
| countries | 20 | 10-30 | иә |
| airlines | 20 | 10-30 | иә |
| destinations | 30 | 10-30 | иә |
| hotels | 35 | 30-200 | иә |
| tour_packages | 28 | 10-30 | иә |
| package_hotels | 34 | 30-200 | иә |
| transport | 27 | 10-30 | иә |
| guides | 18 | 10-30 | иә |
| flights | 154 | 30-200 | иә |
| tours | 77 | 30-200 | иә |
| tour_guides | 131 | 30-200 | иә |
| clients | 284 | 100-300 | иә |
| discounts | 14 | 10-30 | иә |
| bookings | 351 | 300-1000 | иә |
| booking_participants | 780 | 500-2000 | иә |
| payments | 628 | 200-700 | иә |
| insurance | 138 | 30-200 | иә |
| reviews | 114 | 30-200 | иә |

Жалпы жазба саны: 2883.

## 7. Деректерді генерациялау әдісі және жорамалдар

Деректер оқу мақсатына арналған синтетикалық жиынтық, бірақ құрылымы нақты нарық мәліметтеріне сүйенеді. Елдер тізімі, олардың визалық режимі және Schengen елдері үшін міндетті сақтандыру қамту сомасы (кемінде 30 000 еуро) ашық дереккөздерден алынды (Қазақстан МСІМ, egov.kz, Еуропа елдерінің сыртқы істер министрліктері). Туристік ағынның маусымдылығы мен сатып алу алдындағы орташа мерзім (шамамен екі ай) Қазақстан нарығы туралы жарияланған шолулардан алынды; турпакеттердің маусымдық салмақтары осы бақылауларға сәйкес орнатылған. Қонақүй, сақтандырушы, тасымалдаушы атаулары және барлық клиенттер ойдан шығарылған.

Негізгі жорамалдар: турлар 2025 жылдың ақпанынан 2027 жылдың қаңтарына дейін жоспарланған, брондау күндері 2024 жылдың қарашасынан 2026 жылдың 20 қарашасына дейін; бақылау күні 2026-11-22. Брондау мерзімі шамамен 55 күн орташа мәнмен таратылған. Клиенттер үй шаруашылықтары (отбасы, жұп, жалғыз жолаушы) ретінде генерацияланған, сондықтан бір отбасы бірнеше рет сапарға шығады және сапарлары уақыт бойынша қиылыспайды. Өзіндік құн авиабилет, қонақүй (екі кісілік нөмірдің жартысы), көлік пен гид үлестерінің және қосымша шығындардың қосындысы ретінде есептеліп, 12-25% үстеме қойылған; шамамен 10% тур төмен маржамен сатылған. Рейс уақыттары әуежайдың жергілікті уақытымен берілген, ұшу ұзақтығы шамамен алынған, нақты кестені көрсетпейді.

Деректердің тұтастығы тексерілген: сыртқы кілттердің бәрі дұрыс, тур сыйымдылығы асырылмаған, брондау күні ұшу күнінен бұрын, паспорт мерзімі оралудан кейін, жеңілдік өз жарамдылық кезеңінде қолданылған, төленген сома жеңілдіктен кейінгі соммаға сәйкес келеді (`03_constraints.sql`, D бөлімі).

## 8. Кестелер сөздігі

### countries

Қазақстан азаматтарына визалық режимі көрсетілген елдер анықтамалығы. Санаты: Анықтамалық, 20 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| country_id | INTEGER (identity) | PK | Елдің бірегей нөмірі |
| country_name | VARCHAR(60) | NOT NULL; UNIQUE | Ағылшын тіліндегі атауы |
| iso_code | CHAR(2) | NOT NULL; UNIQUE | ISO 3166-1 alpha-2 коды |
| continent | VARCHAR(20) | NOT NULL; CHECK (continent IN ('Asia', 'Europe', 'Africa')) | Құрлық |
| currency_code | CHAR(3) | NOT NULL | Ұлттық валюта коды (ISO 4217) |
| entry_regime | VARCHAR(20) | NOT NULL; CHECK (entry_regime IN ('domestic', 'visa_free', 'visa_on_arrival', 'visa_required')) | Қазақстан азаматтарына кіру режимі |
| insurance_mandatory | BOOLEAN | NOT NULL; DEFAULT FALSE | Медициналық сақтандыру визаның міндетті талабы ма |

### airlines

Рейс орындайтын авиакомпаниялар. Санаты: Анықтамалық, 20 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| airline_id | INTEGER (identity) | PK | Авиакомпания нөмірі |
| airline_name | VARCHAR(60) | NOT NULL; UNIQUE | Атауы |
| iata_code | CHAR(2) | NOT NULL; UNIQUE | IATA екі әріпті коды |
| country_id | INTEGER | FK → countries.country_id; NOT NULL | Тіркелген елі |
| is_low_cost | BOOLEAN | NOT NULL; DEFAULT FALSE | Лоукост белгісі |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Қазір жұмыс істейді ме |

### destinations

Бағыттар: қалалар, курорттар және Қазақстандағы ұшу хабтары. Санаты: Анықтамалық, 30 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| destination_id | INTEGER (identity) | PK | Бағыт нөмірі |
| country_id | INTEGER | FK → countries.country_id; NOT NULL | Бағыт орналасқан ел |
| destination_name | VARCHAR(80) | NOT NULL | Атауы |
| destination_type | VARCHAR(20) | NOT NULL; CHECK (destination_type IN ('beach_resort', 'city', 'island', 'mountain', 'cultural_site')) | Бағыт түрі |
| airport_code | CHAR(3) | UNIQUE | Әуежайдың IATA коды |
| utc_offset | NUMERIC(3,1) | NOT NULL; CHECK (utc_offset BETWEEN -12 AND 14) | UTC-тен ауытқуы, сағатпен |
| best_season | VARCHAR(10) | NOT NULL; CHECK (best_season IN ('winter', 'spring', 'summer', 'autumn', 'all_year')) | Ең қолайлы маусым |
| is_departure_hub | BOOLEAN | NOT NULL; DEFAULT FALSE | Агенттіктің ұшу хабы ма |
| description | VARCHAR(255) | - | Қысқаша сипаттама |
| (кесте деңгейі) | | CONSTRAINT uq_destination_country_name UNIQUE (country_id, destination_name) | |

### hotels

Қонақүйлер, нетто тариф бір түнге екі кісілік нөмір үшін (теңге). Санаты: Қосымша, 35 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| hotel_id | INTEGER (identity) | PK | Қонақүй нөмірі |
| destination_id | INTEGER | FK → destinations.destination_id; NOT NULL | Орналасқан бағыты |
| hotel_name | VARCHAR(100) | NOT NULL; UNIQUE | Атауы (ойдан шығарылған) |
| star_rating | SMALLINT | NOT NULL; CHECK (star_rating BETWEEN 1 AND 5) | Жұлдыз саны |
| board_type | VARCHAR(3) | NOT NULL; DEFAULT 'BB'; CHECK (board_type IN ('RO', 'BB', 'HB', 'FB', 'AI', 'UAI')) | Тамақтану түрі (RO, BB, HB, FB, AI, UAI) |
| price_per_night | NUMERIC(10,2) | NOT NULL; CHECK (price_per_night > 0) | Бір түнгі нетто тариф |
| rooms_total | SMALLINT | NOT NULL; CHECK (rooms_total > 0) | Нөмір қоры |
| distance_to_center_km | NUMERIC(4,1) | CHECK (distance_to_center_km >= 0) | Орталыққа дейінгі қашықтық, км |
| contact_email | VARCHAR(100) | - | Брондау электрондық поштасы |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Келісімшарт күшінде ме |

### tour_packages

Турпакеттер: өнім шаблоны, нақты күндерсіз. Санаты: Анықтамалық, 28 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| package_id | INTEGER (identity) | PK | Турпакет нөмірі |
| package_name | VARCHAR(120) | NOT NULL; UNIQUE | Атауы |
| destination_id | INTEGER | FK → destinations.destination_id; NOT NULL | Негізгі бағыты |
| tour_type | VARCHAR(20) | NOT NULL; CHECK (tour_type IN ('beach', 'cultural', 'city_break', 'adventure', 'wellness', 'ski')) | Тур түрі |
| duration_days | SMALLINT | NOT NULL; CHECK (duration_days BETWEEN 2 AND 30) | Ұзақтығы, күн |
| base_price | NUMERIC(12,2) | NOT NULL; CHECK (base_price > 0) | Бағыттың орташа тур бағасына негізделген тізімдік баға |
| min_group_size | SMALLINT | NOT NULL; DEFAULT 2; CHECK (min_group_size > 0) | Топтың ең аз мөлшері |
| max_group_size | SMALLINT | NOT NULL; CHECK (max_group_size >= 2) | Топтың ең көп мөлшері |
| visa_support | BOOLEAN | NOT NULL; DEFAULT FALSE | Визалық қолдау ұсынылады ма |
| description | VARCHAR(255) | - | Сипаттама |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Сатылымда ма |
| (кесте деңгейі) | | CONSTRAINT chk_package_group CHECK (max_group_size >= min_group_size) | |

### package_hotels

Турпакет пен қонақүй арасындағы көпке-көп байланыс (аралық кесте). Санаты: Қосымша, 34 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| package_id | INTEGER | FK → tour_packages.package_id; NOT NULL | Турпакет |
| hotel_id | INTEGER | FK → hotels.hotel_id; NOT NULL | Қонақүй |
| nights | SMALLINT | NOT NULL; CHECK (nights > 0) | Осы қонақүйдегі түн саны |
| stay_order | SMALLINT | NOT NULL; DEFAULT 1; CHECK (stay_order > 0) | Маршруттағы реті |
| room_category | VARCHAR(20) | NOT NULL; DEFAULT 'standard'; CHECK (room_category IN ('standard', 'superior', 'deluxe', 'family', 'suite')) | Нөмір санаты |
| (кесте деңгейі) | | PRIMARY KEY (package_id, hotel_id) | |

### transport

Жергілікті көлік: трансфер, автобус, пойыз, катер. Санаты: Анықтамалық, 27 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| transport_id | INTEGER (identity) | PK | Көлік нөмірі |
| country_id | INTEGER | FK → countries.country_id; NOT NULL | Қызмет көрсететін ел |
| transport_type | VARCHAR(15) | NOT NULL; CHECK (transport_type IN ('bus', 'minibus', 'van', 'car', 'train', 'boat')) | Көлік түрі |
| provider_name | VARCHAR(100) | NOT NULL | Тасымалдаушы |
| vehicle_model | VARCHAR(60) | - | Көлік моделі |
| capacity | SMALLINT | NOT NULL; CHECK (capacity > 0) | Орын саны |
| daily_rate | NUMERIC(10,2) | NOT NULL; CHECK (daily_rate > 0) | Тәуліктік тариф |
| has_air_conditioning | BOOLEAN | NOT NULL; DEFAULT TRUE | Кондиционер бар ма |
| plate_number | VARCHAR(20) | UNIQUE | Мемлекеттік нөмірі |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Жұмыс істей ме |

### guides

Гидтер мен топ жетекшілері. Санаты: Анықтамалық, 18 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| guide_id | INTEGER (identity) | PK | Гид нөмірі |
| full_name | VARCHAR(100) | NOT NULL | Аты-жөні |
| country_id | INTEGER | FK → countries.country_id; NOT NULL | Тұрақты жұмыс істейтін елі |
| primary_language | VARCHAR(20) | NOT NULL | Негізгі тіл |
| secondary_language | VARCHAR(20) | - | Қосымша тіл |
| phone | VARCHAR(20) | - | Телефон |
| email | VARCHAR(100) | UNIQUE | Электрондық пошта |
| license_number | VARCHAR(20) | NOT NULL; UNIQUE | Куәлік нөмірі |
| experience_years | SMALLINT | NOT NULL; DEFAULT 0; CHECK (experience_years BETWEEN 0 AND 50) | Жұмыс өтілі |
| daily_fee | NUMERIC(10,2) | NOT NULL; CHECK (daily_fee > 0) | Тәуліктік сыйақы |
| specialization | VARCHAR(15) | NOT NULL; CHECK (specialization IN ('escort', 'cultural', 'adventure', 'beach', 'city')) | Мамандануы |
| hire_date | DATE | NOT NULL | Жұмысқа алынған күн |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Белсенді ме |

### flights

Рейстер: әр тур үшін бір бару және бір қайту рейсі (жергілікті уақытпен). Санаты: Қосымша, 154 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| flight_id | INTEGER (identity) | PK | Рейс нөмірі |
| flight_number | VARCHAR(8) | NOT NULL | Рейс коды |
| airline_id | INTEGER | FK → airlines.airline_id; NOT NULL | Авиакомпания |
| origin_destination_id | INTEGER | FK → destinations.destination_id; NOT NULL | Ұшып шығу пункті |
| arrival_destination_id | INTEGER | FK → destinations.destination_id; NOT NULL | Ұшып келу пункті |
| departure_at | TIMESTAMP | NOT NULL | Ұшу уақыты |
| arrival_at | TIMESTAMP | NOT NULL | Қону уақыты |
| cabin_class | VARCHAR(10) | NOT NULL; DEFAULT 'economy'; CHECK (cabin_class IN ('economy', 'premium', 'business')) | Салон класы |
| seat_price | NUMERIC(10,2) | NOT NULL; CHECK (seat_price > 0) | Бір орынның нетто бағасы |
| seats_blocked | SMALLINT | NOT NULL; CHECK (seats_blocked > 0) | Топқа бұғатталған орын саны |
| flight_status | VARCHAR(10) | NOT NULL; DEFAULT 'scheduled'; CHECK (flight_status IN ('scheduled', 'completed', 'cancelled')) | Рейс статусы |
| delay_minutes | SMALLINT | NOT NULL; DEFAULT 0; CHECK (delay_minutes >= 0) | Кешігу, минут |
| (кесте деңгейі) | | CONSTRAINT uq_flight_number_departure UNIQUE (flight_number, departure_at) | |

### tours

Тур департурлары: турпакеттің нақты күнге жоспарланған орындалуы. Санаты: Қосымша, 77 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| tour_id | INTEGER (identity) | PK | Тур нөмірі |
| package_id | INTEGER | FK → tour_packages.package_id; NOT NULL | Турпакет |
| transport_id | INTEGER | FK → transport.transport_id; NOT NULL | Жергілікті көлік |
| outbound_flight_id | INTEGER | FK → flights.flight_id; NOT NULL; UNIQUE | Бару рейсі |
| return_flight_id | INTEGER | FK → flights.flight_id; NOT NULL; UNIQUE | Қайту рейсі |
| departure_date | DATE | NOT NULL | Шығу күні |
| return_date | DATE | NOT NULL | Оралу күні |
| price_per_person | NUMERIC(12,2) | NOT NULL; CHECK (price_per_person > 0) | Бір адамға сату бағасы |
| net_cost_per_person | NUMERIC(12,2) | NOT NULL; CHECK (net_cost_per_person >= 0) | Калькуляция бойынша өзіндік құн |
| max_participants | SMALLINT | NOT NULL; CHECK (max_participants > 0) | Ең көп қатысушы |
| tour_status | VARCHAR(10) | NOT NULL; DEFAULT 'scheduled'; CHECK (tour_status IN ('scheduled', 'confirmed', 'completed', 'cancelled')) | Тур статусы |
| (кесте деңгейі) | | CONSTRAINT chk_tour_dates CHECK (return_date > departure_date) | |
| (кесте деңгейі) | | CONSTRAINT uq_tour_package_date UNIQUE (package_id, departure_date) | |

### tour_guides

Тур мен гид арасындағы көпке-көп байланыс (аралық кесте). Санаты: Қосымша, 131 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| tour_id | INTEGER | FK → tours.tour_id; NOT NULL | Тур |
| guide_id | INTEGER | FK → guides.guide_id; NOT NULL | Гид |
| assignment_role | VARCHAR(15) | NOT NULL; DEFAULT 'lead'; CHECK (assignment_role IN ('lead', 'assistant', 'local_expert')) | Рөлі: lead, assistant, local_expert |
| assigned_on | DATE | NOT NULL | Тағайындалған күн |
| agreed_fee | NUMERIC(10,2) | NOT NULL; CHECK (agreed_fee > 0) | Келісілген жалпы сыйақы |
| (кесте деңгейі) | | PRIMARY KEY (tour_id, guide_id) | |

### clients

Клиенттер; балалар жолаушылар да осы кестеде сақталады. Санаты: Клиенттер, 284 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| client_id | INTEGER (identity) | PK | Клиент нөмірі |
| first_name | VARCHAR(40) | NOT NULL | Аты |
| last_name | VARCHAR(50) | NOT NULL | Тегі |
| gender | CHAR(1) | NOT NULL; CHECK (gender IN ('M', 'F')) | Жынысы (M/F) |
| birth_date | DATE | NOT NULL; CHECK (birth_date >= DATE '1930-01-01') | Туған күні |
| email | VARCHAR(100) | UNIQUE; CHECK (email IS NULL OR email LIKE '%_@_%._%') | Электрондық пошта (балаларда жоқ) |
| phone | VARCHAR(20) | - | Телефон |
| city | VARCHAR(40) | NOT NULL | Тұрақты тұратын қаласы |
| passport_number | VARCHAR(12) | NOT NULL; UNIQUE | Паспорт нөмірі |
| passport_expiry | DATE | NOT NULL | Паспорттың жарамдылық мерзімі |
| registration_date | DATE | NOT NULL; DEFAULT CURRENT_DATE | Базаға тіркелген күн |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Белсенді ме |

### discounts

Жеңілдіктер мен промокодтар. Санаты: Анықтамалық, 14 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| discount_id | INTEGER (identity) | PK | Жеңілдік нөмірі |
| discount_code | VARCHAR(20) | NOT NULL; UNIQUE | Промокод |
| discount_name | VARCHAR(80) | NOT NULL | Атауы |
| discount_type | VARCHAR(10) | NOT NULL; CHECK (discount_type IN ('percent', 'fixed')) | Түрі: percent немесе fixed |
| discount_value | NUMERIC(10,2) | NOT NULL; CHECK (discount_value > 0) | Мәні (пайыз немесе теңге) |
| valid_from | DATE | NOT NULL | Басталу күні |
| valid_to | DATE | NOT NULL | Аяқталу күні |
| min_participants | SMALLINT | NOT NULL; DEFAULT 1; CHECK (min_participants >= 1) | Ең аз жолаушы саны |
| max_uses | INTEGER | CHECK (max_uses > 0) | Қолданудың шекті саны |
| is_active | BOOLEAN | NOT NULL; DEFAULT TRUE | Белсенді ме |
| (кесте деңгейі) | | CONSTRAINT chk_discount_period CHECK (valid_to >= valid_from) | |
| (кесте деңгейі) | | CONSTRAINT chk_discount_percent CHECK (discount_type <> 'percent' OR discount_value <= 50) | |

### bookings

Брондаулар: клиенттің турға тапсырысы. Санаты: Негізгі транзакция, 351 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| booking_id | INTEGER (identity) | PK | Брондау нөмірі |
| client_id | INTEGER | FK → clients.client_id; NOT NULL | Брондаған клиент |
| tour_id | INTEGER | FK → tours.tour_id; NOT NULL | Тур |
| discount_id | INTEGER | FK → discounts.discount_id | Қолданылған жеңілдік |
| booking_date | DATE | NOT NULL | Брондау күні |
| booking_status | VARCHAR(10) | NOT NULL; DEFAULT 'pending'; CHECK (booking_status IN ('pending', 'confirmed', 'completed', 'cancelled')) | Статусы |
| booking_channel | VARCHAR(15) | NOT NULL; DEFAULT 'office'; CHECK (booking_channel IN ('office', 'website', 'phone', 'instagram', 'partner')) | Сату арнасы |
| cancellation_date | DATE | - | Бас тартылған күн |
| cancellation_reason | VARCHAR(30) | CHECK (cancellation_reason IN ('client_request', 'illness', 'visa_refused', 'tour_cancelled', 'schedule_conflict', 'payment_overdue')) | Бас тарту себебі |
| special_requests | VARCHAR(200) | - | Ерекше тілектер |
| (кесте деңгейі) | | CONSTRAINT chk_cancel_dates CHECK (cancellation_date IS NULL OR cancellation_date >= booking_date) | |
| (кесте деңгейі) | | CONSTRAINT chk_cancel_consistency CHECK ( (booking_status = 'cancelled' AND cancellation_date IS NOT NULL AND cancellation_reason IS NOT NULL) OR (booking_status <> 'cancelled' AND cancellation_date IS NULL AND cancellation_reason IS NULL)) | |

### booking_participants

Брондау мен клиент арасындағы көпке-көп байланыс: жолаушылар құрамы. Санаты: Операциялық бөлшек, 780 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| participant_id | INTEGER (identity) | PK | Жазба нөмірі |
| booking_id | INTEGER | FK → bookings.booking_id; NOT NULL | Брондау |
| client_id | INTEGER | FK → clients.client_id; NOT NULL | Жолаушы |
| traveler_type | VARCHAR(10) | NOT NULL; CHECK (traveler_type IN ('adult', 'child', 'infant')) | Жолаушы түрі |
| unit_price | NUMERIC(12,2) | NOT NULL; CHECK (unit_price >= 0) | Жолаушыға қолданылған баға |
| visa_status | VARCHAR(15) | NOT NULL; DEFAULT 'not_required'; CHECK (visa_status IN ('not_required', 'pending', 'approved', 'rejected')) | Виза статусы |
| room_type | VARCHAR(10) | NOT NULL; DEFAULT 'double'; CHECK (room_type IN ('single', 'double', 'twin', 'family')) | Нөмір түрі |
| meal_preference | VARCHAR(12) | NOT NULL; DEFAULT 'standard'; CHECK (meal_preference IN ('standard', 'vegetarian', 'halal', 'child_menu')) | Тамақтану ерекшелігі |
| (кесте деңгейі) | | CONSTRAINT uq_participant UNIQUE (booking_id, client_id) | |

### payments

Төлемдер мен қайтарымдар. Санаты: Төлем, 628 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| payment_id | INTEGER (identity) | PK | Төлем нөмірі |
| booking_id | INTEGER | FK → bookings.booking_id; NOT NULL | Брондау |
| payment_date | DATE | NOT NULL | Төлем күні |
| amount | NUMERIC(12,2) | NOT NULL; CHECK (amount > 0) | Сома |
| payment_method | VARCHAR(15) | NOT NULL; CHECK (payment_method IN ('card', 'mobile_banking', 'bank_transfer', 'cash', 'installment')) | Төлем әдісі |
| payment_type | VARCHAR(15) | NOT NULL; CHECK (payment_type IN ('deposit', 'installment', 'balance', 'full_payment', 'refund')) | Төлем түрі |
| payment_status | VARCHAR(10) | NOT NULL; DEFAULT 'completed'; CHECK (payment_status IN ('completed', 'pending', 'failed')) | Статусы |
| transaction_ref | VARCHAR(20) | NOT NULL; UNIQUE | Транзакция коды |
| currency_code | CHAR(3) | NOT NULL; DEFAULT 'KZT' | Валюта |
| note | VARCHAR(120) | - | Ескертпе |

### insurance

Сақтандыру полистері, брондауға бір полис. Санаты: Қосымша, 138 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| insurance_id | INTEGER (identity) | PK | Полис жазбасының нөмірі |
| booking_id | INTEGER | FK → bookings.booking_id; NOT NULL; UNIQUE | Брондау |
| insurer_name | VARCHAR(60) | NOT NULL | Сақтандырушы (ойдан шығарылған) |
| plan_type | VARCHAR(10) | NOT NULL; CHECK (plan_type IN ('basic', 'standard', 'premium')) | Жоспар |
| coverage_amount_eur | NUMERIC(10,2) | NOT NULL; CHECK (coverage_amount_eur > 0) | Қамту сомасы, еуро |
| insured_persons | SMALLINT | NOT NULL; CHECK (insured_persons > 0) | Сақтандырылған адам саны |
| premium_amount | NUMERIC(10,2) | NOT NULL; CHECK (premium_amount > 0) | Жалпы сыйақы, теңге |
| coverage_start | DATE | NOT NULL | Басталуы |
| coverage_end | DATE | NOT NULL | Аяқталуы |
| policy_number | VARCHAR(20) | NOT NULL; UNIQUE | Полис нөмірі |
| policy_status | VARCHAR(10) | NOT NULL; DEFAULT 'active'; CHECK (policy_status IN ('active', 'expired', 'cancelled', 'claimed')) | Статусы |
| (кесте деңгейі) | | CONSTRAINT chk_insurance_period CHECK (coverage_end >= coverage_start) | |

### reviews

Аяқталған сапарлар бойынша пікірлер. Санаты: Қосымша, 114 жазба.

| Баған | Түрі | Шектеулер | Сипаттама |
|---|---|---|---|
| review_id | INTEGER (identity) | PK | Пікір нөмірі |
| booking_id | INTEGER | FK → bookings.booking_id; NOT NULL | Брондау |
| client_id | INTEGER | FK → clients.client_id; NOT NULL | Пікір жазған клиент |
| review_date | DATE | NOT NULL | Күні |
| overall_rating | SMALLINT | NOT NULL; CHECK (overall_rating BETWEEN 1 AND 5) | Жалпы баға (1-5) |
| hotel_rating | SMALLINT | NOT NULL; CHECK (hotel_rating BETWEEN 1 AND 5) | Қонақүй бағасы |
| guide_rating | SMALLINT | NOT NULL; CHECK (guide_rating BETWEEN 1 AND 5) | Гид бағасы |
| service_rating | SMALLINT | NOT NULL; CHECK (service_rating BETWEEN 1 AND 5) | Қызмет көрсету бағасы |
| would_recommend | BOOLEAN | NOT NULL | Басқаға ұсынады ма |
| comment_text | VARCHAR(300) | - | Пікір мәтіні |
| (кесте деңгейі) | | CONSTRAINT uq_review UNIQUE (booking_id, client_id) | |
