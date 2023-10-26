defmodule OperatelyEmail.Views.ProjectReviewRequestSubmitted do
  require EEx
  @templates_root "lib/operately_email/templates"

  import OperatelyEmail.Views.UIComponents

  EEx.function_from_file(:def, :html, "#{@templates_root}/project_review_request_submitted.html.eex", [:assigns])
  EEx.function_from_file(:def, :text, "#{@templates_root}/project_review_request_submitted.text.eex", [:assigns])
end