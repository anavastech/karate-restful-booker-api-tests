@regression @booking @filter
Feature: Filter bookings - GET /booking?firstname&lastname&checkin&checkout

  Background:
    * url baseUrl
    * path 'booking'
    * def gen = call read('classpath:common/data/data-generator.js')
    * def stay = { checkin: '#(gen.date(90))', checkout: '#(gen.date(95))' }
    * def payload = gen.booking({ bookingdates: stay })
    * def created = call read('classpath:common/create-booking.feature') { booking: '#(payload)' }
    * def expected = { bookingid: '#(created.bookingid)' }

  @smoke
  Scenario: Filter by firstname and lastname returns only the matching booking
    Given params { firstname: '#(payload.firstname)', lastname: '#(payload.lastname)' }
    When method get
    Then status 200
    And match response == [ '#(expected)' ]
    And assert responseTime < maxResponseTime

  Scenario: Filter by lastname only
    Given param lastname = payload.lastname
    When method get
    Then status 200
    And match response == [ '#(expected)' ]

  @negative
  Scenario: Filter with no matches returns an empty list
    Given param firstname = gen.uniqueName('Nobody')
    When method get
    Then status 200
    And match response == []

  Scenario: Filter by a date range that contains the booking
    Given params { lastname: '#(payload.lastname)', checkin: '#(gen.date(89))', checkout: '#(gen.date(96))' }
    When method get
    Then status 200
    And match response == [ '#(expected)' ]

  Scenario Outline: Filter by a date range that excludes the booking - <case>
    Given params { lastname: '#(payload.lastname)', <dateFilter> }
    When method get
    Then status 200
    And match response == []

    Examples:
      | case                         | dateFilter                  |
      | checkin after the booking    | checkin: '#(gen.date(91))'  |
      | checkout before the booking  | checkout: '#(gen.date(94))' |

  @bug
  Scenario: Checkin filter should include bookings that start on that exact date
    # Documented as "greater than or equal to", but the API applies "strictly greater than"
    Given params { lastname: '#(payload.lastname)', checkin: '#(payload.bookingdates.checkin)' }
    When method get
    Then status 200
    And match response == [ '#(expected)' ]
