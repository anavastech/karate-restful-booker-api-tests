@regression @e2e
Feature: Booking lifecycle end to end

  Background:
    * url baseUrl
    * def gen = call read('classpath:common/data/data-generator.js')
    * def bookingSchema = read('classpath:common/schemas/booking.json')

  @smoke
  Scenario: Create, read, update, partially update and delete a booking
    # Authenticate
    * def auth = call read('classpath:common/auth.feature')
    * def token = auth.token

    # Create
    * def booking = gen.booking()
    Given path 'booking'
    And request booking
    When method post
    Then status 200
    And match response == read('classpath:common/schemas/created-booking.json')
    * def bookingId = response.bookingid

    # Read
    Given path 'booking', bookingId
    When method get
    Then status 200
    And match response == booking

    # Full update
    * def updated = gen.booking({ totalprice: 500, depositpaid: false, additionalneeds: 'Dinner' })
    Given path 'booking', bookingId
    And cookie token = token
    And request updated
    When method put
    Then status 200
    And match response == updated

    # Partial update
    * def patch = { firstname: 'Lifecycle', additionalneeds: 'Late checkout' }
    Given path 'booking', bookingId
    And cookie token = token
    And request patch
    When method patch
    Then status 200
    And match response == karate.merge(updated, patch)
    And match response == bookingSchema

    # Delete
    Given path 'booking', bookingId
    And cookie token = token
    When method delete
    Then status 201

    # Confirm it no longer exists
    Given path 'booking', bookingId
    When method get
    Then status 404
