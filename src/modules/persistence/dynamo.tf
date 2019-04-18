variable "environment" {
  default = "staging"
}

resource "aws_dynamodb_table" "codingtips-dynamodb-table" {
  name = "CodingTips-${var.environment}"
  read_capacity = 5
  write_capacity = 5
  hash_key = "Author"
  range_key = "Date"

  attribute = [
    {
      name = "Author"
      type = "S"
    },
    {
      name = "Date"
      type = "N"
    }]

  tags {
    Name        = "codingtips-dynamodb-table"
    Environment = "${var.environment}"
    STAGE       = "${var.environment}"
  }
}

output "tables" {
  value = {
    CodingTipsTable = "${aws_dynamodb_table.codingtips-dynamodb-table.id}"
  }
}
