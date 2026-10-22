@ignore
Feature: Helper - obtain an auth token

  Scenario: Create token with the configured credentials
    Given url baseUrl
    And path 'auth'
    And request credentials
    When method post
    Then status 200
    And match response == read('classpath:common/schemas/token.json')
    * def token = response.token
