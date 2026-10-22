@ignore
Feature: Helper - create a booking from the given payload

  Scenario: Create booking
    Given url baseUrl
    And path 'booking'
    And request booking
    When method post
    Then status 200
    And match response.booking == booking
    * def bookingid = response.bookingid
