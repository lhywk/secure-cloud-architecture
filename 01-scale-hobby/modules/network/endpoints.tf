# S3 Gateway Endpoint
# EC2 → S3 트래픽을 AWS 내부망으로 라우팅 (인터넷 경유 없음, 무료)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id]

  tags = merge(local.common_tags, {
    Name = "${var.project}-${var.environment}-vpce-s3"
  })
}

data "aws_region" "current" {}
