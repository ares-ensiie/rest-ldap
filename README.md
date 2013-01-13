# REST-LDAP

## Webservice Specs

### BIND USERS
#### request
<pre>POST /auth</pre>
##### parameters
- `username`
- `password`

#### response
##### success
- status `200`
- no content

##### failure
- status `401` 
- no content

### SEARCH USERS
#### request
<pre>GET /users</pre>
#### response
- status `200`

```json
[
    {
        "dn": "cn=chobert2010, ou=users, dc=ares",
        "attributes": {
            "cn": "chobert2010",
            "uid": "chobert2010",
            "uidnumber": 1001,
            "gidnumber": 1010,
            "homedirectory": "/home/chobert2010",
            "loginshell": "/bin/sh",
            "objectclass": ["posixaccount"]
        }
    }
]
```

### SEARCH GROUPS
#### request
<pre>GET /groups</pre>
#### response
- status `200`

```json
[
    {
        "dn": "cn=ares, ou=groups, dc=ares",
        "attributes": {
            "gidnumber": 1010,
            "memberuid": ["bee2010", "bertot2010", "chobert2010", "unbekandt2011"],
            "objectclass": ["posixgroup"]
        }
    }
]
```