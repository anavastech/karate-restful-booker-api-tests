@regression @booking
Feature: Update booking - PUT /booking/{id}

  Background:
    * url baseUrl
    * def auth = callonce read('classpath:common/auth.feature')
    * def token = auth.token
    * def gen = call read('classpath:common/data/data-generator.js')
    * def original = gen.booking()
    * def created = call read('classpath:common/create-booking.feature') { booking: '#(original)' }
    * def bookingId = created.bookingid
    * def changes = gen.booking({ totalprice: 420, depositpaid: false, additionalneeds: 'Lunch' })

  @smoke
  Scenario: Update a booking using the token cookie
    Given path 'booking', bookingId
    And cookie token = token
    And request changes
    When method put
    Then status 200
    And match response == read('classpath:common/schemas/booking.json')
    And match response == changes
    And assert responseTime < maxResponseTime

    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response == changes

  Scenario: Update a booking using Basic authentication
    * def authorization = call read('classpath:common/basic-auth.js') credentials
    Given path 'booking', bookingId
    And header Authorization = authorization
    And request changes
    When method put
    Then status 200
    And match response == changes

  @negative
  Scenario Outline: Update is forbidden <case> and the booking is unchanged
    Given path 'booking', bookingId
    And cookie token = <token>
    And request changes
    When method put
    Then status 403
    And match response == 'Forbidden'

    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response == original

    Examples:
      | case                  | token           |
      | without a token       | null            |
      | with an invalid token | 'invalid-token' |

  @negative
  Scenario: Update with Basic auth and wrong password is forbidden
    * def authorization = call read('classpath:common/basic-auth.js') { username: '#(credentials.username)', password: 'nope' }
    Given path 'booking', bookingId
    And header Authorization = authorization
    And request changes
    When method put
    Then status 403

  @negative
  Scenario: PUT with an incomplete body is rejected with 400
    Given path 'booking', bookingId
    And cookie token = token
    And request { firstname: 'OnlyFirstname' }
    When method put
    Then status 400
    And match response == 'Bad Request'

  @negative @bug
  Scenario: Updating a non-existent booking should return 404 Not Found
    Given path 'booking', 2147483647
    And cookie token = token
    And request changes
    When method put
    Then status 404
