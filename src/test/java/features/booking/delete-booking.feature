@regression @booking
Feature: Delete booking - DELETE /booking/{id}

  Background:
    * url baseUrl
    * def auth = callonce read('classpath:common/auth.feature')
    * def token = auth.token
    * def gen = call read('classpath:common/data/data-generator.js')
    * def created = call read('classpath:common/create-booking.feature') { booking: '#(gen.booking())' }
    * def bookingId = created.bookingid

  @smoke
  Scenario: Delete a booking with a valid token and confirm it is gone
    Given path 'booking', bookingId
    And cookie token = token
    When method delete
    # The API answers a successful DELETE with 201 Created (see @bug below)
    Then status 201
    And assert responseTime < maxResponseTime

    Given path 'booking', bookingId
    When method get
    Then status 404

  @negative
  Scenario Outline: Delete is forbidden <case> and the booking still exists
    Given path 'booking', bookingId
    And cookie token = <token>
    When method delete
    Then status 403
    And match response == 'Forbidden'

    Given path 'booking', bookingId
    When method get
    Then status 200

    Examples:
      | case                  | token           |
      | without a token       | null            |
      | with an invalid token | 'invalid-token' |

  @bug
  Scenario: Successful delete should return 200 OK or 204 No Content
    Given path 'booking', bookingId
    And cookie token = token
    When method delete
    Then match [200, 204] contains responseStatus

  @negative @bug
  Scenario: Deleting an already deleted booking should return 404 Not Found
    Given path 'booking', bookingId
    And cookie token = token
    When method delete

    Given path 'booking', bookingId
    And cookie token = token
    When method delete
    Then status 404
