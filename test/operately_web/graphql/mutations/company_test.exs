defmodule OperatelyWeb.GraphQL.Mutations.CompanyTest do
  use OperatelyWeb.ConnCase

  import Operately.PeopleFixtures

  @add_first_company """
  mutation AddFirstCompany($input: AddFirstCompanyInput!) {
    addFirstCompany(input: $input) {
      id
    }
  }
  """

  @add_first_company_input %{
    :input => %{
      :companyName => "Acme Co.",
      :fullName => "John Doe",
      :email => "john@your-company.com",
      :role => "CEO",
      :password => "Aa12345#&!123",
      :passwordConfirmation => "Aa12345#&!123"
    }
  }

  describe "mutation: AddFirstCompany" do
    test "creates company and admin account", ctx do
      conn = graphql(ctx.conn, @add_first_company, "AddFirstCompany", @add_first_company_input)
      res = json_response(conn, 200)

      assert Map.has_key?(res["data"]["addFirstCompany"], "id")

      company = Operately.Companies.get_company_by_name("Acme Co.")
      account = Operately.People.get_account_by_email_and_password("john@your-company.com", "Aa12345#&!123")
      group = Operately.Groups.get_group(company.company_space_id)

      assert Operately.Repo.aggregate(Operately.People.Person, :count, :id) == 1
      assert account != nil
      assert group != nil
    end

    test "allows company and admin account creation only once", ctx do
      conn = graphql(ctx.conn, @add_first_company, "AddFirstCompany", @add_first_company_input)
      res = json_response(conn, 200)

      assert res["data"] != nil

      conn = graphql(ctx.conn, @add_first_company, "AddFirstCompany", @add_first_company_input)
      res = json_response(conn, 200)

      assert res["data"] == nil
      assert Operately.Companies.count_companies() == 1
    end
  end


  @add_company_member """
  mutation AddCompanyMember($input: AddCompanyMemberInput!) {
    addCompanyMember(input: $input) {
      id
      token
    }
  }
  """

  @add_company_member_input %{
    :input => %{
      :fullName => "John Doe",
      :email => "john@your-company.com",
      :title => "Developer",
    }
  }

  describe "mutation: AddCompanyMember" do
    setup :register_and_log_in_account

    test "member account can't invite other members", ctx do
      conn = graphql(ctx.conn, @add_company_member, "AddCompanyMember", @add_company_member_input)
      res = json_response(conn, 200)

      assert res["data"] == nil
      assert res["errors"] |> List.first() |> Map.get("message") == "Only admins can add members"
    end

    test "creates first-time-access token for new member", ctx do
      account = account_fixture()
      person_fixture(%{
        account_id: account.id,
        company_id: ctx.company.id,
        company_role: :admin,
      })
      conn = log_in_account(ctx.conn, account)

      conn = graphql(conn, @add_company_member, "AddCompanyMember", @add_company_member_input)
      res = json_response(conn, 200)

      assert Map.has_key?(res["data"]["addCompanyMember"], "token")
    end
  end

  defp graphql(conn, query, operation_name, variables) do
    payload = %{
      operationName: operation_name,
      query: query,
      variables: variables,
    }

    conn |> post("/api/gql", payload)
  end
end
