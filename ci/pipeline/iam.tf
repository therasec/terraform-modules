/*
 * CodeBuild IAM Role
 */
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild_role" {
  name               = "${var.name}-codebuild-role"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid    = "CodeBuildLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]

    # FIXME: Scope logs
    #- !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/${ServiceName}_build'
    #- !Sub 'arn:aws:logs:${AWS::Region}:${AWS::AccountId}:log-group:/aws/codebuild/${ServiceName}_build:*'
  }

  statement {
    sid    = "CodeBuildToS3Artifacts"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
    ]

    resources = ["*"]

    # FIXME: Scope S3
    #Resource: !Sub 'arn:aws:s3:::${BuildArtifactsBucket}/*'
  }
}

resource "aws_iam_policy" "codebuild" {
  name        = "${var.name}-codebuild"
  policy      = "${data.aws_iam_policy_document.codebuild.json}"
  description = "Policy used in trust relationship with CodeBuild"
  path        = "/service-role/"
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  policy_arn = "${aws_iam_policy.codebuild.arn}"
  role       = "${aws_iam_role.codebuild_role.id}"
}

#FIXME: reduce access
resource "aws_iam_role_policy_attachment" "power_user" {
  role       = "${aws_iam_role.codebuild_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

/*
PipelineExecutionRole:
      Type: AWS::IAM::Role
      Properties:
          Path: '/managed/'
          AssumeRolePolicyDocument:
              Version: '2012-10-17'
              Statement:
                -
                  Action: 'sts:AssumeRole'
                  Effect: Allow
                  Principal:
                    Service:
                      - codepipeline.amazonaws.com
          Policies:
              -
                PolicyName: CodePipelinePassRoleAccess
                PolicyDocument:
                  Version: '2012-10-17'
                  Statement:
                      -
                        Action: 'iam:PassRole'
                        Effect: Allow
                        Resource: !GetAtt CodeBuildServiceRole.Arn
              -
                PolicyName: CodePipelineS3ArtifactAccess
                PolicyDocument:
                  Version: '2012-10-17'
                  Statement:
                      -
                        Action:
                          - 's3:GetObject'
                          - 's3:GetObjectVersion'
                          - 's3:GetBucketVersioning'
                          - 's3:PutObject'
                        Effect: Allow
                        Resource:
                          - !Sub 'arn:aws:s3:::${BuildArtifactsBucket}'
                          - !Sub 'arn:aws:s3:::${BuildArtifactsBucket}/*'
              -
                PolicyName: CodePipelineGitRepoAccess
                PolicyDocument:
                  Version: '2012-10-17'
                  Statement:
                      -
                        Action:
                          - 'codecommit:GetBranch'
                          - 'codecommit:GetCommit'
                          - 'codecommit:UploadArchive'
                          - 'codecommit:GetUploadArchiveStatus'
                          - 'codecommit:CancelUploadArchive'
                        Effect: Allow
                        Resource: !GetAtt CodeRepository.Arn
              -
                PolicyName: CodePipelineBuildAccess
                PolicyDocument:
                  Version: '2012-10-17'
                  Statement:
                      -
                        Action:
                          - 'codebuild:StartBuild'
                          - 'codebuild:StopBuild'
                          - 'codebuild:BatchGetBuilds'
                        Effect: Allow
                        Resource: !GetAtt CodeBuildProject.Arn
*/

