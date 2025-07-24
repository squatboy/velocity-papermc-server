output "velocity_security_group_id" {
  description = "Velocity 보안 그룹 ID"
  value       = aws_security_group.mcserver_velocity_sg.id
}

output "paper_security_group_id" {
  description = "Paper Server 보안 그룹 ID"
  value       = aws_security_group.mcserver_paper_sg.id
}

# 보안 그룹 정보 (디버깅/검증용)
output "security_groups_info" {
  description = "생성된 보안 그룹들의 상세 정보"
  value = {
    velocity = {
      id   = aws_security_group.mcserver_velocity_sg.id
      name = aws_security_group.mcserver_velocity_sg.name
      arn  = aws_security_group.mcserver_velocity_sg.arn
    }
    paper = {
      id   = aws_security_group.mcserver_paper_sg.id
      name = aws_security_group.mcserver_paper_sg.name
      arn  = aws_security_group.mcserver_paper_sg.arn
    }
  }
}
