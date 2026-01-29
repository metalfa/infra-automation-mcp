"""AWS API Client for EKS and IAM Operations"""

import os
import boto3
from typing import Optional
from botocore.exceptions import ClientError


class AWSError(Exception):
    def __init__(self, message: str):
        self.message = message
        super().__init__(self.message)


class AWSClient:
    """Client for AWS operations - EKS, IAM, EC2."""
    
    def __init__(self):
        self.region = os.getenv("AWS_REGION", "us-east-1")
        self.eks = boto3.client("eks", region_name=self.region)
        self.iam = boto3.client("iam", region_name=self.region)
        self.ec2 = boto3.client("ec2", region_name=self.region)
        self.sts = boto3.client("sts", region_name=self.region)

    def get_caller_identity(self) -> dict:
        """Get the current AWS identity."""
        try:
            response = self.sts.get_caller_identity()
            return {
                "account": response["Account"],
                "arn": response["Arn"],
                "user_id": response["UserId"]
            }
        except ClientError as e:
            raise AWSError(f"Failed to get identity: {e}")

    # EKS Operations
    def list_clusters(self) -> list:
        """List all EKS clusters."""
        try:
            response = self.eks.list_clusters()
            return response.get("clusters", [])
        except ClientError as e:
            raise AWSError(f"Failed to list clusters: {e}")

    def describe_cluster(self, cluster_name: str) -> dict:
        """Get details of an EKS cluster."""
        try:
            response = self.eks.describe_cluster(name=cluster_name)
            cluster = response["cluster"]
            return {
                "name": cluster["name"],
                "status": cluster["status"],
                "version": cluster["version"],
                "endpoint": cluster["endpoint"],
                "created_at": cluster["createdAt"].isoformat(),
                "role_arn": cluster["roleArn"],
                "vpc_id": cluster["resourcesVpcConfig"]["vpcId"],
                "subnet_ids": cluster["resourcesVpcConfig"]["subnetIds"]
            }
        except ClientError as e:
            raise AWSError(f"Failed to describe cluster: {e}")

    def list_nodegroups(self, cluster_name: str) -> list:
        """List node groups in an EKS cluster."""
        try:
            response = self.eks.list_nodegroups(clusterName=cluster_name)
            return response.get("nodegroups", [])
        except ClientError as e:
            raise AWSError(f"Failed to list nodegroups: {e}")

    def describe_nodegroup(self, cluster_name: str, nodegroup_name: str) -> dict:
        """Get details of a node group."""
        try:
            response = self.eks.describe_nodegroup(
                clusterName=cluster_name,
                nodegroupName=nodegroup_name
            )
            ng = response["nodegroup"]
            return {
                "name": ng["nodegroupName"],
                "status": ng["status"],
                "instance_types": ng.get("instanceTypes", []),
                "desired_size": ng["scalingConfig"]["desiredSize"],
                "min_size": ng["scalingConfig"]["minSize"],
                "max_size": ng["scalingConfig"]["maxSize"],
                "ami_type": ng.get("amiType"),
                "node_role": ng["nodeRole"]
            }
        except ClientError as e:
            raise AWSError(f"Failed to describe nodegroup: {e}")

    # IAM Operations
    def list_roles(self, path_prefix: str = "/") -> list:
        """List IAM roles."""
        try:
            paginator = self.iam.get_paginator("list_roles")
            roles = []
            for page in paginator.paginate(PathPrefix=path_prefix):
                for role in page["Roles"]:
                    roles.append({
                        "name": role["RoleName"],
                        "arn": role["Arn"],
                        "created": role["CreateDate"].isoformat(),
                        "description": role.get("Description", "")
                    })
            return roles
        except ClientError as e:
            raise AWSError(f"Failed to list roles: {e}")

    def get_role(self, role_name: str) -> dict:
        """Get details of an IAM role."""
        try:
            response = self.iam.get_role(RoleName=role_name)
            role = response["Role"]
            
            # Get attached policies
            policies_response = self.iam.list_attached_role_policies(RoleName=role_name)
            policies = [p["PolicyName"] for p in policies_response["AttachedPolicies"]]
            
            return {
                "name": role["RoleName"],
                "arn": role["Arn"],
                "created": role["CreateDate"].isoformat(),
                "description": role.get("Description", ""),
                "attached_policies": policies
            }
        except ClientError as e:
            raise AWSError(f"Failed to get role: {e}")

    def list_users(self) -> list:
        """List IAM users."""
        try:
            paginator = self.iam.get_paginator("list_users")
            users = []
            for page in paginator.paginate():
                for user in page["Users"]:
                    users.append({
                        "name": user["UserName"],
                        "arn": user["Arn"],
                        "created": user["CreateDate"].isoformat()
                    })
            return users
        except ClientError as e:
            raise AWSError(f"Failed to list users: {e}")

    # EC2/VPC Operations
    def list_vpcs(self) -> list:
        """List VPCs."""
        try:
            response = self.ec2.describe_vpcs()
            vpcs = []
            for vpc in response["Vpcs"]:
                name = ""
                for tag in vpc.get("Tags", []):
                    if tag["Key"] == "Name":
                        name = tag["Value"]
                        break
                vpcs.append({
                    "id": vpc["VpcId"],
                    "name": name,
                    "cidr": vpc["CidrBlock"],
                    "state": vpc["State"],
                    "is_default": vpc["IsDefault"]
                })
            return vpcs
        except ClientError as e:
            raise AWSError(f"Failed to list VPCs: {e}")

    def list_instances(self, filters: list = None) -> list:
        """List EC2 instances."""
        try:
            kwargs = {}
            if filters:
                kwargs["Filters"] = filters
            response = self.ec2.describe_instances(**kwargs)
            
            instances = []
            for reservation in response["Reservations"]:
                for instance in reservation["Instances"]:
                    name = ""
                    for tag in instance.get("Tags", []):
                        if tag["Key"] == "Name":
                            name = tag["Value"]
                            break
                    instances.append({
                        "id": instance["InstanceId"],
                        "name": name,
                        "type": instance["InstanceType"],
                        "state": instance["State"]["Name"],
                        "private_ip": instance.get("PrivateIpAddress"),
                        "public_ip": instance.get("PublicIpAddress"),
                        "vpc_id": instance.get("VpcId")
                    })
            return instances
        except ClientError as e:
            raise AWSError(f"Failed to list instances: {e}")