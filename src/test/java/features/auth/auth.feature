@regression @auth
Feature: Authentication - POST /auth

  Background:
    * url baseUrl
    * path 'auth'

  @smoke
  Scenario: Valid credentials return a token
    Given request credentials
    When method post
    Then status 200
    And match response == read('classpath:common/schemas/token.json')
    And assert responseTime < maxResponseTime

  @negative
  Scenario Outline: Login with <case> does not return a token
    Given request <body>
    When method post
    # The API signals failure in the body, not in the status code (see @bug below)
    Then status 200
    And match response == { reason: 'Bad credentials' }

    Examples:
      | case               | body                                                     |
      | a wrong password   | { username: '#(credentials.username)', password: 'nope' } |
      | an unknown user    | { username: 'ghost', password: '#(credentials.password)' } |
      | empty credentials  | { username: '', password: '' }                           |
      | an empty body      | {}                                                       |

  @negative @bug
  Scenario: Invalid credentials should be rejected with 401 Unauthorized
    Given request { username: '#(credentials.username)', password: 'nope' }
    When method post
    Then status 401
