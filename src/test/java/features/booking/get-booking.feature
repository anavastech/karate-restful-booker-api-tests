@regression @booking
Feature: Read bookings - GET /booking and GET /booking/{id}

  Background:
    * url baseUrl
    * def gen = call read('classpath:common/data/data-generator.js')
    * def createBooking = read('classpath:common/create-booking.feature')

  @smoke
  Scenario: List returns booking ids
    Given path 'booking'
    When method get
    Then status 200
    And match response == '#[_ > 0]'
    And match each response == read('classpath:common/schemas/booking-id.json')
    And assert responseTime < maxResponseTime

  @smoke
  Scenario: Get an existing booking by id
    * def payload = gen.booking()
    * def created = call createBooking { booking: '#(payload)' }
    Given path 'booking', created.bookingid
    When method get
    Then status 200
    And match response == read('classpath:common/schemas/booking.json')
    And match response == payload
    And match responseHeaders['Content-Type'][0] contains 'application/json'
    And assert responseTime < maxResponseTime

  @negative
  Scenario Outline: Get a booking with a non-existent id (<id>) returns 404
    Given path 'booking', '<id>'
    When method get
    Then status 404
    And match response == 'Not Found'

    Examples:
      | id         |
      | 2147483647 |
      | 0          |
      | abc        |
