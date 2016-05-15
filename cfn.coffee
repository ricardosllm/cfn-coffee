module.exports = class CFN    # CloudFormation
  any: "0.0.0.0/0"
  constructor: (@env = '<env>', @domain = '<domain>', @tld = '<tld>', @gen = '<gen1>') ->
    @zone        = @domain + '.' + @tld
    @zoneWithDot = @zone + '.'

  extend: (o1, o2) =>
    m = {}
    for k, v of o1
      m[k] = v
    for k, v of o2
      if k == 'Tags'
        if v instanceof Array and v != m[k]
          m[k].push.apply m[k], v
      else
        m[k] = if   m[k] instanceof Object and v instanceof Object  then   @extend m[k], v   else   v
        m[k] = v if k == 'ImageId'
    m

  merge: (a) => a.reduce @extend

  withKey: (k, x) -> o = {}; o[k] = x; o

  prettyPrintJson: (o) -> JSON.stringify o, undefined, 2

  print: -> @prettyPrintJson @CFN()

  CFN: (x) ->
    @extend
      Description: [@env, "stack"].join ' '
      AWSTemplateFormatVersion: "2010-09-09"

      Parameters:
        CloudInitScript: @Parameter "Cloud Init Script", "String",
          @CloudInitScript

      Mappings:
        # Search for AMIs of a region on
        # http://cloud-images.ubuntu.com/locator/ec2/
        RegionMap:
          # result for "ap-southeast-1 ebs 12.04 lts 64":
          "ap-southeast-1":
            AMI: "ami-f094c0a2"   # Release: 20131205, aki-fe1354ac

          # result for "ap-northeast-1 ebs 12.04 lts 64":
          "ap-northeast-1":
            AMI: "ami-8f78188e"   # Release: 20131205, aki-44992845

          # result for "us-west-2 ebs 12.04 lts 64":
          "us-west-2":
            AMI: "ami-927613a2"   # Release: 20131205 aki-fc37bacc

          # result for "us-east-1 ebs 12.04 lts 64":
          "us-east-1":
            AMI: "ami-8f2718e6"   # Release: 20140127 aki-88aa75e1

      Resources: undefined
      Outputs: undefined
      x

  Parameter: (desc, type, def, allowed, x) ->
    @extend
      Description: desc
      Type: type
      Default: def
      AllowedValues: allowed
      x

  SecurityGroup: (name, x, deps) ->
    appendSgIfMissing = (name) ->
      endsWith = (str, suffix) -> str.indexOf(suffix, str.length - suffix.length) != -1
      return name if endsWith name, 'Sg'
      return name + 'Sg'
    name = appendSgIfMissing name

    @withKey name,
      Type: "AWS::EC2::SecurityGroup"
      DependsOn: deps
      Properties:
        @extend
          GroupDescription: name
          VpcId: Ref: "Vpc"
          SecurityGroupIngress: undefined
          SecurityGroupEgress: [ IpProtocol: "-1", CidrIp: @any ]
          x

  ELB: (x) ->
    Type: "AWS::ElasticLoadBalancing::LoadBalancer"
    Properties:
      @extend
        Scheme: undefined
        # Subnets: [ { Ref: "SubnetA" }, { Ref: "SubnetB" } ]
        Subnets: [ { Ref: "SubnetA" } ]
        HealthCheck:
          Target: undefined
          Interval: "30"
          Timeout: "5"
          HealthyThreshold: "2"
          UnhealthyThreshold: "2"
        Listeners: undefined
        SecurityGroups: undefined
        Instances: undefined
        x

  Allow: (a) ->
    SecurityGroupIngress: a

  Group: (proto, port, sgRef) ->
    IpProtocol: proto, FromPort: port, ToPort: port, SourceSecurityGroupId: Ref: sgRef

  Network: (proto, port, network) ->
    IpProtocol: proto, FromPort: port, ToPort: port, CidrIp: network

  Proxy: (inProto, inPort, outProto, outPort, certId, x) ->
    @extend
      LoadBalancerPort: inPort, Protocol: inProto
      InstancePort: outPort, InstanceProtocol: outProto
      SSLCertificateId: certId
      x

  DBSubnetGroup: (name, x) ->
    @withKey name+"SubnetGroup",
      Type: "AWS::RDS::DBSubnetGroup"
      Properties:
        DBSubnetGroupDescription: name+"SubnetGroup"
        SubnetIds: [ { Ref: "SubnetA" }, { Ref: "SubnetB" } ]

  RDS: (name, x) ->
    @merge [
      @DBSubnetGroup name

      @withKey name,
        Type: "AWS::RDS::DBInstance"
        Properties: @extend
          AllocatedStorage: undefined
          DBInstanceClass: undefined

          Engine: "mysql"
          EngineVersion: "5.6.13"
          LicenseModel: "general-public-license"

          DBName: "MySQLRDS"
          MasterUsername: "mysql"
          MasterUserPassword: { Ref: "DBPassword" }

          AvailabilityZone: undefined
          DBSubnetGroupName: Ref: name+"SubnetGroup"
          Port: "3306"
          AutoMinorVersionUpgrade: "true"

          BackupRetentionPeriod: "7"
          PreferredBackupWindow: "07:11-07:41"
          PreferredMaintenanceWindow: "fri:14:20-fri:15:20"

          VPCSecurityGroups: [ { Ref: "MySQLSg" }, { Ref: "AdminSg" } ]
          x
    ]

  PostgreSQL: (name, x) ->
    @merge [
      @DBSubnetGroup name

      @withKey name,
        Type: "AWS::RDS::DBInstance"
        Properties: @extend
          AllocatedStorage: undefined
          DBInstanceClass: undefined

          Engine: "postgres"
          EngineVersion: "9.4.1"
          LicenseModel: "postgresql-license"

          DBName: "MySQLRDS"
          MasterUsername: "mysql"
          MasterUserPassword: { Ref: "DBPassword" }

          AvailabilityZone: undefined
          DBSubnetGroupName: Ref: name+"SubnetGroup"
          Port: "5432"
          AutoMinorVersionUpgrade: "true"

          BackupRetentionPeriod: "7"
          PreferredBackupWindow: "07:11-07:41"
          PreferredMaintenanceWindow: "fri:14:20-fri:15:20"

          VPCSecurityGroups: [ { Ref: "PostgreSQLSg" }, { Ref: "AdminSg" } ]
          x
    ]

  EC2: (name, hostname, x, deps) ->
    @merge [
      @withKey name,
        Type: "AWS::EC2::Instance"
        DependsOn: deps
        Properties: @extend
          Tags: [ { Key: "Name", Value: @env+'-'+name } ]
          InstanceType: "t1.micro"
          SubnetId: Ref: "SubnetA"
          ImageId: "Fn::FindInMap": [ "RegionMap", { Ref: "AWS::Region" }, "AMI" ]
          KeyName: Ref: "KeyName"
          SecurityGroupIds: undefined
          UserData: "Fn::Base64": Ref: "CloudInitScript"
          x

      # Allocate and assign an ElasticIP and register into DNS
      @withKey name+"Ip",
        Type: "AWS::EC2::EIP"
        Properties: Domain: "vpc"

      @withKey name+"IpAssoc",
        Type: "AWS::EC2::EIPAssociation"
        DependsOn: [ name+"Ip", name ]
        Properties:
          AllocationId: "Fn::GetAtt": [ name+"Ip", "AllocationId" ]
          InstanceId: Ref: name

      # @DNS hostname, 'A', name, 'PrivateIp'
      @DNS hostname, 'CNAME', name, 'PublicDnsName', {},
        [ name+"IpAssoc" ]    # but only depend on it for public IPs
    ]

  NetworkInterfaces: (subnetId, groupSet) ->
    [{
      AssociatePublicIpAddress: "true"
      DeviceIndex: "0"
      DeleteOnTermination: "true"
      SubnetId: subnetId
      GroupSet: groupSet
    }]

  EC2WithoutEIP: (name, hostname, x, groupSet, deps) ->
    @merge [
      @withKey name,
        Type: "AWS::EC2::Instance"
        DependsOn: deps
        Properties: @extend
          Tags: [ { Key: "Name", Value: @env+'-'+name } ]
          InstanceType: "t1.micro"
          # SubnetId: Ref: "SubnetA"
          ImageId: "Fn::FindInMap": [ "RegionMap", { Ref: "AWS::Region" }, "AMI" ]
          KeyName: Ref: "KeyName"
          # SecurityGroupIds: undefined
          UserData: "Fn::Base64": Ref: "CloudInitScript"
          NetworkInterfaces: @NetworkInterfaces {Ref: "SubnetA"}, groupSet
          x

      @DNS hostname, 'CNAME', name, 'PublicDnsName'
    ]

  RecordSetName: (hostname, type) ->
    if type is undefined or type is null
      throw new Error "Record set type must be specficied for #{hostname}"

    name = if not hostname? or hostname == '' or hostname == '@'
      'Root'
    else
      hostname
    @DomainNameToLogicalID(name) + type

  DomainNameToLogicalID: (name) ->
    name.replace(/-/g, '').replace(/\./g, '')

  FQDN: (hostname) -> (if hostname? then hostname+'.' else '')+@zoneWithDot

  DNSAlias: (hostname, resource, x) ->
    @withKey @RecordSetName(hostname, 'CNAME'),
      Type: "AWS::Route53::RecordSet"
      Properties: @extend
        HostedZoneName: @zoneWithDot
        AliasTarget:
          HostedZoneId: "Fn::GetAtt": [ resource, "CanonicalHostedZoneNameID" ]
          DNSName: "Fn::GetAtt": [ resource, "CanonicalHostedZoneName" ]
        Name: @FQDN hostname
        Type: 'A'
        x

  CloudFrontDNSAlias: (hostname, resource, hostedZoneName, x) ->
    @withKey @RecordSetName(hostname, 'CNAME'),
      Type: "AWS::Route53::RecordSet"
      Properties: @extend
        HostedZoneName: hostedZoneName
        AliasTarget:
          HostedZoneId: "Z2FDTNDATAQYW2"
          DNSName: "Fn::GetAtt": [ resource, "DomainName" ]
        Name: @FQDN hostname
        Type: 'A'
        x

  _DNS: (hostname, type, x, deps) ->
    @withKey @RecordSetName(hostname, type),
      Type: "AWS::Route53::RecordSet"
      DependsOn: deps
      Properties: @extend
        HostedZoneName: @zoneWithDot
        Name: @FQDN hostname
        Type: type
        TTL: "300"
        x

  DNS: (hostname, type, resource, attr, x, deps) ->
    @_DNS hostname, type,
      @extend
        ResourceRecords: [ "Fn::GetAtt": [ resource, attr ] ]
        x
      deps

  Queue: (name, x) ->
    @withKey name+'Queue',
      Type: "AWS::SQS::Queue"
      Properties: @extend
        QueueName: @env+'-'+name.toLowerCase()
        MessageRetentionPeriod: 345600    # 4 days, which is the AWS default
        ReceiveMessageWaitTimeSeconds: 20   # Max long poll time
        x

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
        MaxAge: 3000  # Preflight request cache time
      ]

  CorsEnableGet:
    CorsConfiguration:
      CorsRules: [
        AllowedOrigins: ["*"]
        AllowedMethods: ["GET"]
        AllowedHeaders: ["*"]
        MaxAge: 3000  # Preflight request cache time
      ]

  WebsiteConfiguration:
    WebsiteConfiguration:
      IndexDocument: "index.html"

  PublicReadAccess:
    AccessControl: "PublicRead"

  EC2Role: (name, x) ->
    @withKey name+'Role',
      Type: 'AWS::IAM::Role'
      Properties: @extend
        AssumeRolePolicyDocument:
          Statement: [
            {
              Effect: "Allow"
              Principal: Service: [ "ec2.amazonaws.com" ]
              Action: [ "sts:AssumeRole" ]
            }
          ]
        Path: '/'
        x

  Policy: (name, x) ->
    @withKey name+'Policy',
      Type: 'AWS::IAM::Policy'
      Properties: @extend
        PolicyName: name+'Policy'
        x

  InstanceProfile: (name, x) ->
    @withKey name+'InstanceProfile',
      Type: 'AWS::IAM::InstanceProfile'
      Properties: @extend
        Path: '/'
        x

  CacheSubnetGroup: (name, x) ->
    @withKey name+"SubnetGroup",
      Type: "AWS::ElastiCache::SubnetGroup"
      Properties:
        Description: name+"SubnetGroup"
        SubnetIds: [ { Ref: "SubnetA" }, { Ref: "SubnetB" } ]

  MemcacheName: ->
    "b2c-#{@env}-gen1-m"

  Memcache: (name, x) ->
    @merge [
      @withKey name,
        Type: 'AWS::ElastiCache::CacheCluster'
        Properties: @extend
          ClusterName: @MemcacheName name
          Engine: 'memcached'
          EngineVersion: '1.4.5'
          NumCacheNodes: 1
          CacheNodeType: 'cache.m1.small'
          CacheSubnetGroupName: Ref: 'MemcacheSubnetGroup'
          VpcSecurityGroupIds: [ Ref: 'MemcacheSg' ]
          x
    ]

  CloudFront: (name, originDomainName, originId, aliases, deps) ->
    @withKey name + 'CloudFront',
      Type: "AWS::CloudFront::Distribution"
      DependsOn: deps
      Properties:
        DistributionConfig:
          Aliases: aliases
          Origins: [{
            DomainName: originDomainName
            Id: originId
            CustomOriginConfig:
              HTTPPort: "80"
              HTTPSPort: "443"
              OriginProtocolPolicy: "http-only"
            }]
          Enabled: true
          DefaultRootObject: "index.html"
          DefaultCacheBehavior:
            AllowedMethods: [
                "GET",
                "HEAD"
            ]
            TargetOriginId: originId
            ForwardedValues:
              QueryString: "false"
              Cookies:
                Forward: "none"
            ViewerProtocolPolicy: "redirect-to-https"
          ViewerCertificate:
            IamCertificateId: Ref: 'WWWSniCertificateId'
            SslSupportMethod: "sni-only"

  NestedStackTemplateUrl: (stack, nestedStack) ->
    "https://#{@domain}-#{@env}-update.s3.amazonaws.com/cfn/#{stack}/#{nestedStack}.json"

  NestedStack: (name, templateURL, parameters) ->
    @withKey name,
      Type: "AWS::CloudFormation::Stack"
      Properties:
        @extend
          TemplateURL: templateURL
          TimeoutInMinutes: 60
          Parameters: parameters
