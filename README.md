# AWS Network Firewall Automation with PowerShell

This project automates the provisioning and configuration of AWS Network Firewall resources using PowerShell and the AWS Tools for PowerShell module. 
It guides users through creating stateful rule groups, setting firewall policies, and associating route tables and subnets dynamically in an interactive script.

## 🔧 Features

- Authenticate to AWS using access keys and profile.
- Create stateful rule groups with user-defined domain inspection rules.
- Define firewall policies with strict or default rule evaluation order.
- Deploy and configure AWS Network Firewall within a chosen VPC.
- Dynamically create and tag route tables.
- Associate route tables with subnets or internet gateways.
- Fully interactive CLI input using `Read-Host`.

## 🧰 Technologies Used

- PowerShell
- AWS PowerShell Module (`AWSPowerShell.NetCore`)
- AWS Network Firewall
- Amazon EC2 (for subnets, route tables, and gateways)

## 🚀 Getting Started

1. Install the AWS PowerShell module:

   ```powershell
   Install-Module -Name AWSPowerShell.NetCore -Force
