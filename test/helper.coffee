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

AWS = require 'aws-sdk'
config = require 'config'
awsCfg = config.get 'aws'
AWS.config.update awsCfg
AWS.config.apiVersions = config.awsApiVersions
CFN = require '../cfn'
global.cloudformation = new AWS.CloudFormation

module.exports = class TestStack extends CFN
  constructor: () ->
    @env         = 'test'
    @domain      = 'cfncoffee'
    @tld         = 'com'
    @zone        = @domain + '.' + @tld
    @zoneWithDot = @zone + '.'

  CFN: () -> super @merge [
    Description: 'test stack'

    Resources: @merge [
      @SQS 'cfnCoffee'
    ]

    Outputs:
      Region: Value: Ref: "AWS::Region"
  ]
