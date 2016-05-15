chai = require 'chai'
chai.should()
chai.use require 'sinon-chai'
chai.use require 'chai-as-promised'
global.expect = chai.expect
global.assert = chai.assert
global.When = require 'when'
global.expect = chai.expect.bind chai
sinon = require 'sinon'
global.sinon = sinon
global.spy = sinon.spy.bind sinon
global.stub = sinon.stub.bind sinon
global.match = sinon.match.bind sinon
global.match.__proto__ = sinon.match  # to support match.has & match.string, etc
Factory = require('rosie').Factory
global.define = Factory.define.bind Factory
global.build = Factory.build.bind Factory
