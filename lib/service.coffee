rest = require 'restler'

Service = rest.service(
  (username, password) ->
    @defaults.username = username
    @defaults.password = password
  {
    baseURL: "#{process.env.API_HOST}"
  }
  bind: (options={}) ->
    @post('/ldap/bind', data: { username: options.username, password: options.password}).on 'complete', (data, response) ->
      if response.statusCode is 200
        options.success()
      else
        options.error()
  users: (options={}) ->
    @get('/ldap/users').on 'complete', (data, response) ->
      if response.statusCode is 200
        options.success(data)
      else
        options.error()
  groups: (options={}) ->
    @get('/ldap/groups').on 'complete', (data, response) ->
      if response.statusCode is 200
        options.success(data)
      else
        options.error()
)

module.exports = Service
