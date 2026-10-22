@regression @booking
Feature: Partial update booking - PATCH /booking/{id}

  Background:
    * url baseUrl
    * def auth = callonce read('classpath:common/auth.feature')
    * def token = auth.token
    * def gen = call read('classpath:common/data/data-generator.js')
    * def original = gen.booking()
    * def created = call read('classpath:common/create-booking.feature') { booking: '#(original)' }
    * def bookingId = created.bookingid

  @smoke
  Scenario: Patch changes only the given fields
    * def patch = { firstname: 'Patched', totalprice: 999 }
    Given path 'booking', bookingId
    And cookie token = token
    And request patch
    When method patch
    Then status 200
    And match response == karate.merge(original, patch)
    And assert responseTime < maxResponseTime

  Scenario Outline: Patch a single field - <field>
    * def patch = <patch>
    * def expected = karate.merge(original, patch)
    Given path 'booking', bookingId
    And cookie token = token
    And request patch
    When method patch
    Then status 200
    And match response == expected

    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response == expected

    Examples:
      | field           | patch                                                                   |
      | lastname        | { lastname: 'Patchson' }                                                |
      | totalprice      | { totalprice: 1 }                                                       |
      | depositpaid     | { depositpaid: false }                                                  |
      | additionalneeds | { additionalneeds: 'Spa access' }                                       |
      | bookingdates    | { bookingdates: { checkin: '#(gen.date(60))', checkout: '#(gen.date(62))' } } |

  @negative
  Scenario Outline: Patch is forbidden <case> and the booking is unchanged
    Given path 'booking', bookingId
    And cookie token = <token>
    And request { firstname: 'Hacker' }
    When method patch
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

  @negative @bug
  Scenario: Patching a non-existent booking should return 404 Not Found
    Given path 'booking', 2147483647
    And cookie token = token
    And request { firstname: 'Ghost' }
    When method patch
    Then status 404
