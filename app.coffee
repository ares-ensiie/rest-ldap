ldap = require 'ldapjs'
Service = require './lib/service'
moment = require 'moment'
_ = require 'underscore'

api = new Service 'ldap', process.env.API_PASSWORD

# GLOBALS
basedn = "dc=ares"
pamdn = "cn=admin, #{basedn}"
usersBasedn = "ou=users, #{basedn}"
groupsBasedn = "ou=groups, #{basedn}"

server = ldap.createServer()

# pam_ldap bind
server.bind pamdn, (req, res, next) ->
  console.log "#{moment().format()} BIND #{req.dn.toString()}"
  if req.credentials is process.env.LDAP_TOKEN
    res.end()
    return next()
  else
    return next(new ldap.InsufficientAccessRightsError())

# user bind
server.bind usersBasedn, (req, res, next) ->
  console.log "#{moment().format()} BIND #{req.dn.toString()}"
  uid = req.dn.rdns[0].cn
  api.bind
    username: uid
    password: req.credentials
    success: ->
      res.end()
      next()
    error: ->
      next(new ldap.InsufficientAccessRightsError())

server.search usersBasedn, (req, res, next) ->
  console.log "#{moment().format()} SEARCH #{req.dn.toString()} #{req.filter.toString()}"
  api.users
    success: (users) ->
      _.each users, (user) ->
        if req.filter.matches user.attributes
          console.log user
          res.send user
      res.end()
      next()
    error: ->
      res.end()
      next()

server.search groupsBasedn, (req, res, next) ->
  console.log "#{moment().format()} SEARCH #{req.dn.toString()} #{req.filter.toString()}"
  api.groups
    success: (groups) ->
      _.each groups, (group) ->
        if req.filter.matches group.attributes
          console.log group
          res.send group
      res.end()
      next()
    error: ->
      res.end()
      next()

# Start server
server.listen parseInt(process.env.LDAP_PORT), ->
  console.log 'LDAP server up at: %s', server.url
