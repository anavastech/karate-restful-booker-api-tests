@regression @booking
Feature: Create booking - POST /booking

  Background:
    * url baseUrl
    * path 'booking'
    * def gen = call read('classpath:common/data/data-generator.js')

  @smoke
  Scenario: Create a booking and validate the response contract
    * def payload = gen.booking()
    Given request payload
    When method post
    Then status 200
    And match response == read('classpath:common/schemas/created-booking.json')
    And match response.booking == payload
    And assert responseTime < maxResponseTime

  Scenario: Created booking is persisted and retrievable by id
    * def payload = gen.booking()
    Given request payload
    When method post
    Then status 200
    * def bookingId = response.bookingid

    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response == payload

  Scenario: additionalneeds is optional
    * def payload = gen.booking({}, ['additionalneeds'])
    Given request payload
    When method post
    Then status 200
    And match response.booking == payload
    And match response.booking.additionalneeds == '#notpresent'

  Scenario Outline: Create booking with valid data - <description>
    * def payload = gen.booking(overrides)
    Given request payload
    When method post
    Then status 200
    And match response == read('classpath:common/schemas/created-booking.json')
    And match response.booking == payload

    Given path 'booking', response.bookingid
    When method get
    Then status 200
    And match response == payload

    Examples:
      | read('classpath:common/data/valid-bookings.json') |

  @negative
  Scenario Outline: Booking without required field "<field>" is not created
    * def payload = gen.booking({}, [field])
    Given request payload
    When method post
    # Rejected, but with 500 instead of 400 (see the @bug outline below)
    Then assert responseStatus >= 400
    And match response !contains { bookingid: '#notnull' }

    Examples:
      | read('classpath:common/data/missing-required-fields.json') |

  @negative @bug
  Scenario Outline: Invalid booking should be rejected with 400 Bad Request - <description>
    * def payload = gen.booking(overrides, removals)
    Given request payload
    When method post
    Then status 400

    Examples:
      | read('classpath:common/data/invalid-bookings.json') |

  @negative @bug
  Scenario: Empty body should be rejected with 400 Bad Request
    Given request {}
    When method post
    Then status 400

  @bug
  Scenario: Successful creation should return 201 Created
    Given request gen.booking()
    When method post
    Then status 201
