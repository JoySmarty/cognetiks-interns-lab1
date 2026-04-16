provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "app_repo" {
  name = "cloud-lab-app"
}
output "repository_url" {
  value = aws_ecr_repository.app_repo.repository_url
}
