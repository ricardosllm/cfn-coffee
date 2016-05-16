TestStack = require '../helper'

SQS = class TestSQS extends TestStack
  CFN: () -> super @merge [
    Description: 'test SQS stack'

    Resources: @merge [
      @SQS 'cfnCoffee'
    ]
  ]

describe 'SQS', ->
  describe '.bucket', ->
    describe 'object', ->
      beforeEach ->
        @cfn = new SQS
        @template = { TemplateBody: @cfn.print() }

      it 'returns result', ->
        cloudformation.validateTemplate @template, (err, data) ->
          if err then @response = err else @response = data

          expect @response
            .to.have.property 'ResponseMetadata'

