TestStack = require '../helper'

ELB = class TestELB extends TestStack
  CFN: () -> super @merge [
    Description: 'test stack'

    Resources: @merge [
      @ELB()
    ]
  ]

describe 'elb', ->
  beforeEach ->
    @cfn = new ELB
    @template = { TemplateBody: @cfn.print() }

  it 'validates template', ->
    cloudformation.validateTemplate @template, (err, data) ->
      if err then @response = err else @response = data
      expect @response
      .to.have.property 'ResponseMetadata'

