# LDAP-OAuth bindings

Le but de ce projet est de permettre l'utilisation de la librairie pam_ldap sur un webservice REST OAuth. Ce n'est pas un proxy LDAP <-> REST, l'usage est dédié à la manipulation des classes `posixAccount` et `posixGroup`.

Ce projet s'addresse à toute entité qui souhaiterais baser son authentifcation sur OAuth mais souhaiterais quand même profiter du très large support de LDAP.

## Fonctionnalités

- Authentification
- Changement de mot de passe

## Installation

- Install [node.js](http://nodejs.org/)
- Install dependancies : `npm`
- Start

## ROADMAP

- Easier deployment (chef ?)
- Tests automatisés (Vagrant, chef)
- Support d'autre methodes d'authentification que 
- Permettre de decrire le webservice dans un fichier de config.
- Support de classes personnalisées

## Contribuer

- forkez
- ajouter une fonctionnalité | corriger un bug
- envoyer votre pull request (point bonus pour les "[topic branches](http://progit.org/book/ch3-4.html)")