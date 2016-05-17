TestStack = require '../helper'

EC2 = class TestSQS extends TestStack
  CFN: () -> super @merge [
    Description: 'test EC2 stack'

    Resources: @merge [
      @EC2 "test", 'test',
        InstanceType: 't2.micro'
        ImageId: 'ami-94f3ccc6'
    ]
  ]

describe 'EC2', ->
  describe 'instance', ->
    beforeEach ->
      @cfn = new EC2
      @template = { TemplateBody: @cfn.print() }

    it 'validates template', ->
      cloudformation.validateTemplate @template, (err, data) ->
        if err then @response = err else @response = data

        expect @response
          .to.have.property 'ResponseMetadata'

