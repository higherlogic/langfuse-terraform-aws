# Langfuse 3.83+ uses the AWS SDK default credential chain for Amazon Bedrock
# (playground, evals, LLM-as-judge). On EKS that resolves to this IRSA role.
# See https://langfuse.com/changelog/2025-07-18-aws-sdk-default-credential-provider

data "aws_iam_policy_document" "langfuse_bedrock_invoke" {
  count = var.bedrock_invoke_enabled ? 1 : 0

  statement {
    sid    = "BedrockInvokeModel"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = [
      "arn:aws:bedrock:*::foundation-model/anthropic.*",
      "arn:aws:bedrock:*:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.*",
    ]
  }

  # Anthropic inference profiles on Bedrock may require marketplace subscription checks.
  statement {
    sid    = "AwsMarketplaceBedrockSubscriptions"
    effect = "Allow"
    actions = [
      "aws-marketplace:Subscribe",
      "aws-marketplace:ViewSubscriptions",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "langfuse_bedrock_invoke" {
  count = var.bedrock_invoke_enabled ? 1 : 0

  name   = "bedrock-invoke"
  role   = aws_iam_role.langfuse_irsa.id
  policy = data.aws_iam_policy_document.langfuse_bedrock_invoke[0].json
}
