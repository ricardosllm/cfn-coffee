AWS = require 'aws-sdk'
config = require 'config'
awsCfg = config.get 'aws'
AWS.config.update awsCfg
AWS.config.apiVersions = config.awsApiVersions
cloudformation = new AWS.CloudFormation
CFN = require '../../cfn'

S3 = class TestS3 extends CFN
  constructor: () ->
    @env         = 'test'
    @domain      = 'cfncoffee'
    @tld         = 'com'
    @zone        = @domain + '.' + @tld
    @zoneWithDot = @zone + '.'

  CFN: () -> super @merge [
    Description: 'test stack'

    Resources: @merge [
      @Bucket null, 'bucket'
    ]

    Outputs:
      Region: Value: Ref: "AWS::Region"
  ]

describe 's3', ->
  # beforeEach ->

  describe '.bucket', ->
    describe 'object', ->
      beforeEach ->
        @cfn = new S3
        @template = { TemplateBody: @cfn.print() }

      it 'returns result', ->
        cloudformation.validateTemplate @template, (err, data) ->
          if err then @response = err else @response = data

          expect @response
            .to.have.property 'ResponseMetadata'

