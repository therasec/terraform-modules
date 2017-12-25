resource "aws_sns_topic" "validation" {
  name = "${var.name}-terraform-provisioning-validation"
}

/*
data "aws_iam_policy_document" "sns_publish" {
  statement {
    actions = ["sns:Publish"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = ["${aws_sns_topic.validation.arn}"]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn = "${aws_sns_topic.validation.arn}"
  policy = "${data.aws_iam_policy_document.sns_publish.json}"
}
*/

