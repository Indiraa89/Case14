# 01_basic_queries.sql: орындау нәтижелері

Негізгі SELECT сұраныстары. Нәтижелер сұраныс файлының өзінен автоматты түрде алынды. Әр кестеде алғашқы 15 жол көрсетілген.

## Q1.1. Елдер тізімі: Қазақстан азаматтарына кіру режимі бойынша топталған

```sql
SELECT country_name, iso_code, entry_regime, insurance_mandatory
FROM countries
ORDER BY entry_regime, country_name;
```

Жолдар саны: 20

| country_name | iso_code | entry_regime | insurance_mandatory |
|---|---|---|---|
| Kazakhstan | KZ | domestic | 0 |
| Azerbaijan | AZ | visa_free | 0 |
| China | CN | visa_free | 0 |
| Georgia | GE | visa_free | 0 |
| Kyrgyzstan | KG | visa_free | 0 |
| Maldives | MV | visa_free | 0 |
| Montenegro | ME | visa_free | 0 |
| Sri Lanka | LK | visa_free | 0 |
| Thailand | TH | visa_free | 0 |
| Turkey | TR | visa_free | 0 |
| United Arab Emirates | AE | visa_free | 0 |
| Uzbekistan | UZ | visa_free | 0 |
| Vietnam | VN | visa_free | 0 |
| Egypt | EG | visa_on_arrival | 0 |
| Czechia | CZ | visa_required | 1 |

## Q1.2. Клиенттер тұратын қалалар (қайталанбайтын мәндер)

```sql
SELECT DISTINCT city
FROM clients
ORDER BY city;
```

Жолдар саны: 10

| city |
|---|
| Aktobe |
| Almaty |
| Astana |
| Atyrau |
| Karaganda |
| Kostanay |
| Oral |
| Pavlodar |
| Semey |
| Shymkent |

## Q1.3. Нетто тарифі ең жоғары 10 қонақүй

```sql
SELECT hotel_name, star_rating, board_type, price_per_night
FROM hotels
ORDER BY price_per_night DESC, hotel_name
LIMIT 10;
```

Жолдар саны: 10

| hotel_name | star_rating | board_type | price_per_night |
|---|---|---|---|
| Lagoon Atoll Retreat | 5 | FB | 210000 |
| Creek View Grand | 5 | BB | 88000 |
| Montmartre Garden Hotel | 4 | BB | 84000 |
| Corniche Pearl Hotel | 5 | BB | 79000 |
| Shinjuku Metro Hotel | 4 | BB | 78000 |
| Trastevere Classic Hotel | 4 | BB | 72000 |
| Eixample Court Hotel | 4 | BB | 69000 |
| Azure Bay Resort & Spa | 5 | UAI | 68000 |
| Long Beach Sanctuary | 5 | BB | 64000 |
| Marina Crest Hotel | 4 | BB | 62000 |

## Q1.4. Каталогтағы ең арзан 8 турпакет

```sql
SELECT package_name, tour_type, duration_days, base_price
FROM tour_packages
ORDER BY base_price ASC, package_name
LIMIT 8;
```

Жолдар саны: 8

| package_name | tour_type | duration_days | base_price |
|---|---|---|---|
| Almaty Mountains and Charyn | adventure | 5 | 250000 |
| Issyk-Kul Lakeside Summer | wellness | 6 | 265000 |
| Samarkand Silk Road | cultural | 5 | 275000 |
| Mangystau Expedition | adventure | 5 | 305000 |
| Shymbulak Ski Week | ski | 6 | 320000 |
| Baku Weekend | city_break | 4 | 345000 |
| Tbilisi and Batumi Combo | cultural | 6 | 390000 |
| Dubai Winter Escape | city_break | 6 | 490000 |

## Q1.5. Төлем әдістері мен төлем түрлерінің қолданылған үйлесімдері

```sql
SELECT DISTINCT payment_method, payment_type
FROM payments
ORDER BY payment_method, payment_type;
```

Жолдар саны: 25

| payment_method | payment_type |
|---|---|
| bank_transfer | balance |
| bank_transfer | deposit |
| bank_transfer | full_payment |
| bank_transfer | installment |
| bank_transfer | refund |
| card | balance |
| card | deposit |
| card | full_payment |
| card | installment |
| card | refund |
| cash | balance |
| cash | deposit |
| cash | full_payment |
| cash | installment |
| cash | refund |
