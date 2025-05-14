# SNS topic for alarm notifications
resource "aws_sns_topic" "cacs_alarm_topic" {
  name = var.alarm_topic_name
}

# Email subscription to SNS topic
resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.cacs_alarm_topic.arn
  protocol  = "email"
  endpoint  = var.email_alert
}

# Alarm for high average CPU usage across the Auto Scaling Group
resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "CACS-High-CPU-Utilization"
  alarm_description   = "Alarm when average CPU across ASG > 80% for 5 minutes"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  unit                = "Percent"
  alarm_actions       = [aws_sns_topic.cacs_alarm_topic.arn]
  insufficient_data_actions = []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.springboot_asg.name
  }
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "t2s_web_server_log_group" {
  name              = var.log_group_name
  retention_in_days = 14
}

# Log Stream within the log group
resource "aws_cloudwatch_log_stream" "t2s_web_server_log_stream" {
  name           = var.log_stream_name
  log_group_name = aws_cloudwatch_log_group.t2s_web_server_log_group.name
}

# CloudWatch Dashboard for EC2 and ALB metrics
resource "aws_cloudwatch_dashboard" "cacs_dashboard" {
  dashboard_name = "CACS-Dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        x    = 0
        y    = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", aws_autoscaling_group.springboot_asg.name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "EC2 CPU Utilization"
        }
      },
      {
        type = "metric"
        x    = 6
        y    = 0
        width  = 6
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.springboot_alb.arn_suffix]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "eu-west-2"
          title   = "ALB Request Count"
        }
      }
    ]
  })
}