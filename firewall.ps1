#----------------------------------------
# Import All Module

Import-Module AWSPowerShell 

#-----------------------------------------------------------------------------------------
 
#-----------------------------------------------------------------------------------------
#AWS Credentials
#-----------------------------------------------------------------------------------------

$UserSecretKey  = ""

$UserAccessKey = ""

$ProfileName  = ""

$region = "us-east-1"

#-------------------------------------------------------------------------------------
#Setting Credentials
#-------------------------------------------------------------------------------------

$SetCredentials = Set-AWSCredential -AccessKey $UserAccessKey -SecretKey $UserSecretKey -StoreAs $ProfileName

#-------------------------------------------------------------------------------------
#Setting Sessions
#-------------------------------------------------------------------------------------

$session = Initialize-AWSDefaults -ProfileName $ProfileName  -Region $region

#-------------------------------------------------------------------------------------

$rulegrouptype = read-host "Do you want to create a stateful rule group or a stateless rule group ?"
if($rulegrouptype -eq "stateful" )
{
   #---------------------------------------------------------------------------------------
   #Creating Network Firewall Statefull Rule Groups.
   #---------------------------------------------------------------------------------------------
   $ruleevaluationorder = read-host "please choose the Rule evaluation order you want ?  for STRICT_ORDER press 1 and for DEFAULT_ACTION_ORDER press 2"
if ( $ruleevaluationorder -eq 1)
     {
        $ruleorder= "STRICT_ORDER"
     }
if ( $ruleevaluationorder -eq 2)
     {
        $ruleorder= "DEFAULT_ACTION_ORDER"
     }
    $rulegroupame= read-host "Enter the rule group name"
   [int]$capacity= read-host "Enter capacity (number of rules)"
    $domains= read-host "List the domain names you want to inspect and either allow or deny."
    $protocol= read-host "Spacify The protocols choose 1 to inspect https and 2 for http  "
if ( $protocol -eq 1)
     {
        $protocoltype= "TLS_SNI"
     }
if ( $protocol -eq 2)
     {
        $protocoltype= "HTTP_HOST"
     }

    $action= read-host "Spacify the Action to take when a request matches the domain names in this group if want to allow choose 1 and if want to denay choose 2 "
    if ( $action -eq 1)
     {
        $actiontype= "ALLOWLIST"
     }
if ( $action -eq 2)
     {
        $actiontype= "DENYLIST"
     }
     
}
$rulegroup= New-NWFWRuleGroup -Type "STATEFUL" `
                              -StatefulRuleOptions_RuleOrder $ruleorder `
                              -RuleGroupName $rulegroupame `
                              -Capacity $capacity `
                              -RulesSourceList_Target $domains `
                              -RulesSourceList_TargetType $protocoltype `
                              -RulesSourceList_GeneratedRulesType $actiontype
$rulegroups=Get-NWFWRuleGroupList

                  
$rule = Get-NWFWRuleGroupList
$rule.Arn

New-NWFWFirewallPolicy -FirewallPolicyName "FirePolicy" `
                       -StatefulEngineOptions_StreamExceptionPolicy DROP `
                       -StatefulEngineOptions_RuleOrder "STRICT_ORDER" `
                       -FirewallPolicy_StatefulDefaultAction "aws:drop_established" `
                       -FirewallPolicy_StatelessDefaultAction  "aws:forward_to_sfe" `
                       -FirewallPolicy_StatelessFragmentDefaultAction "aws:forward_to_sfe" `
                       -FirewallPolicy_StatefulRuleGroupReference @{ResourceArn = $rule.Arn ; Priority = 1}
                                        


$policy = Get-NWFWFirewallPolicyList
$policy.Arn 


$subnets = Get-EC2Subnet
function sub {
    foreach($subnet in $subnets){
           Write-Output " `e[34m$($subnet.Tag.Value)`e[0m `e[31m( $($subnet.SubnetId ) )`e[0m"   
    } 
}
$(sub)

[String]$subnetId = Read-Host "Enter your  subnet that you want to create your firewall  $(sub) "

New-NWFWFirewall -FirewallPolicyArn $policy.Arn  `
                 -FirewallName MyFw `
                 -VpcId "vpc-09678d8ebd5ed8092" `
                 -SubnetMapping @{IPAddressType = "IPV4" ; SubnetId = $subnetId }


#-----------------------------------------------< Create Route Tables and associate to Subnets >----------------------------------------------------------------




$vpce = Get-EC2VpcEndpoint -Region us-east-1 | Select-Object -ExpandProperty VpcEndpointId

$myvpc = Get-EC2Vpc

$igw = Get-EC2InternetGateway



$numberofroutetables = Read-Host "How many route tables do you want"

    for ($i = 1; $i -le $numberofroutetables; $i++) {
    $DestCidrBlock = Read-Host "Enter your Destination Cidr Block "
    $publicRouteTable = New-EC2RouteTable -VpcId $myvpc.VpcId  #"vpc-03c1cd9f299c225c8" 
    New-EC2Route -RouteTableId $publicRouteTable.RouteTableId `
                 -DestinationCidrBlock $DestCidrBlock `
                 -VpcEndpointId $vpce
          
           $tags = @(
            @{
                Key   = "Name";
                Value = (Read-Host "Enter your Route table tag value ")
            }
        )
        New-EC2Tag -Resource $($publicRouteTable.RouteTableId)  -Tag $tags

        $ask = Read-Host "Do you want to register these route to a subnet"
        if ($ask -eq "yes"){
            [String]$subnetId = Read-Host "Enter your  subnet that you want to create your Firewall  $(sub) "
            Register-EC2RouteTable  -RouteTableId $publicRouteTable.RouteTableId -SubnetId $subnetId
            Write-Output "Route Table With id: $($publicRouteTable.RouteTableId) created and tag: $($tags.Value) is associate to subnet id: $($subnetId) "

        } elseif ($ask -eq "no") {
            $askforeadge = Read-Host "Do you want to register eadge association to these route "
            if($askforeadge -eq "yes")
            {
            Register-EC2RouteTable -GatewayId $igw.InternetGatewayId -RouteTableId $publicRouteTable.RouteTableId


            }
            else{
                Write-Host "thanks "
            }
        
        } 
    
}

 
#---------------------------- Route Table for firewall subnet --------------------------------------------------------------------------

$publicRouteTable = New-EC2RouteTable -VpcId $myvpc.VpcId  #"vpc-03c1cd9f299c225c8" 

New-EC2Route -RouteTableId $publicRouteTable.RouteTableId `
        -DestinationCidrBlock 0.0.0.0/0 -GatewayId $igw.InternetGatewayId
       
        $tags = @(
         @{
             Key   = "Name";
             Value = (Read-Host "Enter your Route table tag value ")
         }
     )
 
     New-EC2Tag -Resource $($publicRouteTable.RouteTableId)  -Tag $tags

     [String]$subnetId = Read-Host "Enter your  subnet that you want to associate to routetable  $(sub) "

     Register-EC2RouteTable -RouteTableId $publicRouteTable.RouteTableId -SubnetId $subnetId
 
     Write-Output "Route Table With id: $($publicRouteTable.RouteTableId) created and tag: $($tags.Value) is associate to subnet id: $($subnetId) "