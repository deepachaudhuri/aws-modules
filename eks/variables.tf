variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "node_groups" {
  description = "Configuration for EKS node groups"
  type = list(object({
    name           = string
    subnet_ids     = list(string)
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    disk_size      = number
  }))
  default = [
    {
      name           = "default"
      subnet_ids     = []
      desired_size   = 2
      min_size       = 1
      max_size       = 4
      instance_types = ["t3.medium"]
      disk_size      = 20
    }
  ]
}

variable "enable_cluster_logging" {
  description = "Enable CloudWatch logging for the EKS cluster"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 7
}

variable "enable_aws_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller add-on"
  type        = bool
  default     = true
}

variable "aws_load_balancer_controller_version" {
  description = "Version of the AWS Load Balancer Controller add-on"
  type        = string
  default     = ""  # Use empty string to let AWS select the recommended version for the cluster
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI Driver add-on"
  type        = bool
  default     = true
}

variable "ebs_csi_driver_version" {
  description = "Version of the EBS CSI Driver add-on"
  type        = string
  default     = ""  # Use empty string to let AWS select the recommended version for the cluster
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI Driver add-on"
  type        = bool
  default     = true
}

variable "efs_csi_driver_version" {
  description = "Version of the EFS CSI Driver add-on"
  type        = string
  default     = ""  # Use empty string to let AWS select the recommended version for the cluster
}

variable "enable_cloudwatch_observability" {
  description = "Enable CloudWatch Container Insights add-on"
  type        = bool
  default     = true
}

variable "cloudwatch_observability_version" {
  description = "Version of the CloudWatch Observability add-on"
  type        = string
  default     = ""  # Use empty string to let AWS select the recommended version for the cluster
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
