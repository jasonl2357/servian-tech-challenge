# All database related resources are defined in this file

# For simplicity for this task, we have put the database in the default subnet. It can be further segregated in the future.
resource "aws_db_subnet_group" "database" {
  name       = "database"
  subnet_ids = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}", "${aws_default_subnet.default_subnet_c.id}"]
}

resource "aws_db_instance" "challengeappdb" {
  identifier             = "challengeappdb"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "10.7"
  port                   = "${var.dbport}"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.database.id
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_security_group" "database" {
  name   = "database"
  vpc_id = "${aws_default_vpc.default_vpc.id}"
}

resource "aws_security_group_rule" "allow_db_access" {
  type              = "ingress"
  from_port         = "${var.dbport}"
  to_port           = "${var.dbport}"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.database.id}"
  cidr_blocks       = ["${aws_default_subnet.default_subnet_a.cidr_block}", "${aws_default_subnet.default_subnet_b.cidr_block}", "${aws_default_subnet.default_subnet_c.cidr_block}"]
}