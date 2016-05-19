TestStack = require '../helper'

S3 = class TestS3 extends TestStack
  CFN: () -> super @merge [
    Description: 'test stack'

    Resources: @merge [
      @Bucket null, 'bucket'
    ]
  ]

describe 's3', ->
  describe 'bucket', ->
    beforeEach ->
      @cfn = new S3
      @template = { TemplateBody: @cfn.print() }

    it 'validates template', ->
      cloudformation.validateTemplate @template, (err, data) ->
        if err then @response = err else @response = data

        expect @response
          .to.have.property 'ResponseMetadata'

