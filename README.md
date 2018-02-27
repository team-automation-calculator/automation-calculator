[![CircleCI](https://circleci.com/gh/team-automation-calculator/automation-calculator/tree/master.svg?style=shield&circle-token=b5937e6c3aa7290dc6425381ce5be7ea98a027bb)](https://circleci.com/gh/team-automation-calculator/automation-calculator/tree/master) ![License](https://img.shields.io/badge/license-mit-blue.svg)

# automation-calculator

## Purpose

To help people make and communicate automation decisions quickly and effectively. 

## Setup
### Dependencies
* Ruby 2.0.0+
* Docker Engine 17.09.0+
* Docker Compose (Must support Compose 3.4 format)

### Install
`./go init`

## Use

### View app in local browser
* `./go start`
* Open browser, go to `http://localhost:3001/`.
* If you wish to configure the port to be something else, edit `RAILS_SERVER_PORT` inside `docker-compose.yml`.

### Interact with the app via terminal
* `./go shell`

### Run the tests
* `./go test`
* `./go lint`

### View available functions
* `./go help`

## Troubleshooting/Gotchas

* Problem: If you update the Gemfile and run `./go test`, `./go shell` or a similar command, you will see `Could not find NEW_GEM_DEPENDENCY_NAME_HERE`.
* Solution: Run `./go build` to update your development docker image to include the new dependency.
