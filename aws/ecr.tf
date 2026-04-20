resource "aws_ecr_repository" "visual_dictionary" {
  name                 = "visual-dictionary"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "ci-cd-terraform-lab"
  }
}

# Lifecycle policy — keep only last 10 images to save storage costs
resource "aws_ecr_lifecycle_policy" "visual_dictionary" {
  repository = aws_ecr_repository.visual_dictionary.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_repository" "jenkins" {
  name                 = "jenkins-custom"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = "ci-cd-terraform-lab"
  }
}

resource "aws_ecr_repository" "react_app" {
  name                 = "visual-dictionary-react"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

output "react_ecr_url" {
  value = aws_ecr_repository.react_app.repository_url
}
