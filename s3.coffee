CFN = require './cfn'

module.exports = class S3 extends CFN
	Bucket: (product, name, x) ->
		@withKey name+'Bucket',
			Type: "AWS::S3::Bucket"
			Properties: @extend
				AccessControl: "AuthenticatedRead"
				BucketName:
					# According to AWS S3 policy,
					# bucket names can not contain uppercase characters
					if product
						"#{@domain}-#{product}-#{@env}-#{name}".toLowerCase()
					else
						"#{@domain}-#{@env}-#{name}".toLowerCase()
				x

	WebBucket: (name, x) ->
		@merge [
			@withKey @DomainNameToLogicalID(name)+'Bucket',
				Type: "AWS::S3::Bucket"
				Properties: @extend
					AccessControl: "AuthenticatedRead"
					BucketName: "#{name}.#{@zone}"
					WebsiteConfiguration:
						IndexDocument: 'index.html'
						# ErrorDocument: String
						# RedirectAllRequestsTo: Redirect all requests rule,
						# RoutingRules: [ Routing rule, ... ]
					x

			@_DNS name, 'CNAME',
				ResourceRecords: [
					"Fn::Join": [ "", [
						Ref: name+"Bucket"
						".s3-website-"
						Ref: 'AWS::Region'
						'.amazonaws.com'
					] ]
				]

			@BucketPolicy name
		]

	BucketPolicy: (name, x) ->
		@withKey name+'BucketPolicy',
			Type: 'AWS::S3::BucketPolicy'
			Properties: @extend
				Bucket: Ref: name+'Bucket'
				PolicyDocument:
					Statement: [
						Sid: "AddPerm"
						Effect: "Allow"
						Principal: AWS: "*"
						Action: [ "s3:GetObject" ]
						Resource: "Fn::Join": [ "",
							[ "arn:aws:s3:::",   Ref: name+"Bucket",   "/*" ]
						]
					]
				x

	CorsEnableUpload:
		CorsConfiguration:
			CorsRules: [
				AllowedOrigins: ["*"]
				AllowedMethods: ["GET", "POST", "PUT"]
				AllowedHeaders: ["*"]
				MaxAge: 3000	# Preflight request cache time
			]

	CorsEnableGet:
		CorsConfiguration:
			CorsRules: [
				AllowedOrigins: ["*"]
				AllowedMethods: ["GET"]
				AllowedHeaders: ["*"]
				MaxAge: 3000	# Preflight request cache time
			]

	WebsiteConfiguration:
		WebsiteConfiguration:
			IndexDocument: "index.html"

	PublicReadAccess:
		AccessControl: "PublicRead"
