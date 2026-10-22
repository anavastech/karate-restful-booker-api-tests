@regression @health
Feature: Health check - GET /ping

  Background:
    * url baseUrl

  @smoke
  Scenario: API responds to the health check
    Given path 'ping'
    When method get
    # Restful Booker answers a health check with 201 Created (see README > Findings)
    Then status 201
    And match response == 'Created'
    And assert responseTime < maxResponseTime
