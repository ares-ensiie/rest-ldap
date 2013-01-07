ldap = require 'ldapjs'
http = require 'http'
_ = require('underscore')._

httpRequest = (options, callback) ->
  options.params = JSON.stringify(options.data) if options.data

  req = http.request
    host: process.env.API_HOST || 'localhost'
    port: process.env.API_PORT || 80
    auth: "#{options.username}:#{options.password}" if options.username isnt 'ldap'
    path: options.path
    method:  options.method || 'GET'
    headers:
      Accept: 'application/json'
      'LDAP-Token': process.env.LDAP_TOKEN if options.username is 'ldap'
      'Content-Type': 'application/json' if options.params
      'Content-Length': options.params.length if options.params
    (res) ->
      if res.statusCode is 204
        callback(res.statusCode)
      res.on 'data', (chunk) ->
        data = JSON.parse(chunk.toString('utf-8'))
        callback(res.statusCode, data)
  req.write(options.params) if options.params
  req.end()

buildPosixAccount = (attributes) ->
  dn: "uid=#{attributes.username}, ou=#{attributes.group.name}, ou=users, dc=ares"
  attributes:
    uid: attributes.username
    cn: attributes.username
    userpassword: attributes.user_password
    uidnumber: String(attributes.uid_number)
    gidnumber: String(attributes.group.gid_number)
    gecos: "#{attributes.first_name} #{attributes.last_name}"
    homedirectory: attributes.home_directory
    loginshell: attributes.login_shell
    objectclass: "posixaccount"

buildPosixGroup = (attributes) ->
  dn: "cn=#{attributes.name}, dc=groups, dc=ares"
  attributes:
    cn: attributes.name
    gidnumber: String(attributes.gid_number)
    memberuid: _.map(attributes.users, (u) -> u.username)
    objectclass: "posixgroup"

# GLOBALS
basedn = "dc=ares"
pamBasedn = "cn=admin, #{basedn}"
usersBasedn = "ou=users, #{basedn}"
groupsBasedn = "ou=groups, #{basedn}"

server = ldap.createServer()

loadResource = (name, endpoint, buildPosix) ->
  (req, res, next) ->
    req[name] = new Array()
    httpRequest
      username: req.connection.ldap.uid || 'ldap'
      password: req.connection.ldap.password
      path: endpoint
      (statusCode, resources) ->
        _.each resources, (resource) ->
          req[name].push buildPosix(resource)
        next()

# pam_ldap bind
server.bind pamBasedn, (req, res, next) ->
  if req.credentials is process.env.LDAP_TOKEN
    req.connection.ldap.root = true
    res.end()
    return next()
  else
    return next(new ldap.InsufficientAccessRightsError())

uidFromDn = (dn) ->
  dn.rdns[0].uid

# user bind
server.bind "#{basedn}", (req, res, next) ->
  console.log "#{(new Date()).logFormat()} BIND #{req.dn.toString()}"
  uid = uidFromDn(req.dn)
  httpRequest username: uid, password: req.credentials, path: '/users/self', (statusCode, data) =>
    if statusCode is 200 and data.username is uid
      # attach login and password to connection
      req.connection.ldap.uid = uid
      req.connection.ldap.password = req.credentials
      res.end()
      return next()
    else
      return next(new ldap.InsufficientAccessRightsError())

Date.prototype.logFormat = ->
  "#{@getFullYear()}-#{@getMonth()}-#{@getDate()} #{@getHours()}:#{@getMinutes()}:#{@getSeconds()}"


# apply filter and send resource
searchResource = (resourceName) ->
  (req, res, next) ->
    console.log "#{(new Date()).logFormat()} SEARCH #{req.dn.toString()} #{req.filter.toString()}"
    _.each req[resourceName], (resource) ->
      if req.filter.matches(resource.attributes)
        res.send(resource)
    res.end()
    return next()


# function to declare search endpoint
serveResource = (name, resourceBasedn, endpoint, buildPosix) ->
  server.search resourceBasedn,
    loadResource(name, endpoint, buildPosix),
    searchResource(name)


# declare endpoints
serveResource 'users', usersBasedn, '/users', buildPosixAccount
serveResource 'groups', groupsBasedn, '/groups', buildPosixGroup

# modify endpoint
# replace userpassword and shadowlastchange
server.modify 'ou=users, dc=ares', (req, res, next) ->
  console.log "#{(new Date()).logFormat()} MODIFY #{req.dn.toString()} (#{_.map(req.changes, (c) -> c.modification.type).join(' ')})"

  modification = _.reduce req.changes,
    (hsh, c) ->
      if c.operation is 'replace'
        switch c.modification.type
          when 'userpassword' then hsh['password'] = c.modification.vals[0]
          when 'shadowlastchange' then hsh['shadowlastchange'] = c.modification.vals[0]
          else hsh[c.modification.type] = c.modification.vals
      hsh
    {}
  uid = uidFromDn(req.dn)
  httpRequest method: 'PUT', username: req.connection.ldap.uid, password: req.connection.ldap.password, path: "/users/#{uid}", data: modification, (statusCode, result) =>
    if statusCode is 204

      # change password for next ldap connection usage
      req.connection.ldap.password = modification.password if modification.password

      res.end();
    else
      next(new ldap.InsufficientAccessRightsError())

# Start server
server.listen 1348, ->
  console.log 'LDAP server up at: %s', server.url

