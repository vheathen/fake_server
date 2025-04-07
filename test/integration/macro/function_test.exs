defmodule FakeServer.Integration.FunctionTest do
  use ExUnit.Case, async: false

  import FakeServer
  alias FakeServer.Request
  alias FakeServer.Response

  describe "when using functions as response" do
    test_with_server "raises FakeServer.Error if the function arity is not 1" do
      assert_raise FakeServer.Error, fn ->
        route("/test", fn -> FakeServer.Response.ok!() end)
      end
    end

    test_with_server "returns the default response if the function does not return a FakeServer.Response object" do
      route("/test", fn _ -> :ok end)
      response = Req.get!(FakeServer.http_address() <> "/test")
      assert response.status == 200
      assert response.body == ~s<{"message": "This is a default response from FakeServer"}>
    end

    test_with_server "returns the corresponding response if the function returns a FakeServer.Response object" do
      route("/test", fn _ -> Response.bad_request!() end)
      response = Req.get!(FakeServer.http_address() <> "/test")
      assert response.status == 400
    end

    test_with_server "returns the corresponding response if the function returns a {:ok, FakeServer.Response} tuple" do
      route("/test", fn _ -> Response.bad_request() end)
      response = Req.get!(FakeServer.http_address() <> "/test")
      assert response.status == 400
    end

    test_with_server "computes hits for the corresponding route" do
      route("/test", fn _ -> Response.bad_request!() end)
      assert hits() == 0
      assert hits("/test") == 0
      Req.get!(FakeServer.http_address() <> "/test")
      assert hits() == 1
      assert hits("/test") == 1
    end

    test_with_server "ensures the request has a body" do
      route("/test", fn %Request{body: body} ->
        if body == "TEST", do: Response.no_content!(), else: Response.bad_request!()
      end)

      response1 = Req.post!("#{FakeServer.http_address()}/test", body: "TEST")
      assert response1.status == 204
      response2 = Req.post!("#{FakeServer.http_address()}/test", body: "NOT_TEST")
      assert response2.status == 400
    end

    test_with_server "decode the body if the content_type header is application/json and the body is decodable" do
      route("/test", fn %Request{body: body} ->
        if body == %{"test" => true}, do: Response.ok!(), else: Response.bad_request!()
      end)

      response1 =
        Req.post!(
          "#{FakeServer.http_address()}/test",
          body: ~s<{"test": true}>,
          headers: ["content-type": "application/json"]
        )

      assert response1.status == 200

      response2 =
        Req.post!(
          "#{FakeServer.http_address()}/test",
          body: ~s<not a valid json>,
          headers: ["content-type": "application/json"]
        )

      assert response2.status == 400
    end

    test_with_server "ensures the request has cookies" do
      route("/test", fn %Request{cookies: cookies} ->
        if Map.get(cookies, "logged_in") == "true",
          do: Response.ok!(),
          else: Response.forbidden!()
      end)

      response1 =
        Req.get!("#{FakeServer.http_address()}/test",
          body: %{},
          headers: [cookie: ["logged_in=true"]]
        )

      assert response1.status == 200

      response2 =
        Req.get!("#{FakeServer.http_address()}/test",
          body: %{},
          headers: [cookie: ["logged_in=false"]]
        )

      assert response2.status == 403
    end

    test_with_server "ensures the request has headers" do
      route("/test", fn %Request{headers: headers} ->
        if Map.get(headers, "authorization") == "Bearer 1234",
          do: Response.ok!(),
          else: Response.forbidden!()
      end)

      response1 =
        Req.get!("#{FakeServer.http_address()}/test", headers: [authorization: "Bearer 1234"])

      assert response1.status == 200
      response2 = Req.get!("#{FakeServer.http_address()}/test")
      assert response2.status == 403
    end

    test_with_server "ensures the request has a method" do
      route("/test", fn %Request{method: method} ->
        if method == "GET", do: Response.ok!(), else: Response.bad_request!()
      end)

      response1 = Req.get!("#{FakeServer.http_address()}/test")
      assert response1.status == 200
      response2 = Req.post!("#{FakeServer.http_address()}/test")
      assert response2.status == 400
    end

    test_with_server "ensures the request has a query" do
      route("/test", fn %Request{query: query} ->
        if Map.get(query, "access_token") == "1234",
          do: Response.ok!(),
          else: Response.forbidden!()
      end)

      response1 = Req.get!("#{FakeServer.http_address()}/test?access_token=1234")
      assert response1.status == 200
      response2 = Req.get!("#{FakeServer.http_address()}/test")
      assert response2.status == 403
    end

    test_with_server "ensures the request has a query_string" do
      route("/test", fn %Request{query_string: query_string} ->
        if query_string == "access_token=1234", do: Response.ok!(), else: Response.forbidden!()
      end)

      response1 = Req.get!("#{FakeServer.http_address()}/test?access_token=1234")
      assert response1.status == 200
      response2 = Req.get!("#{FakeServer.http_address()}/test")
      assert response2.status == 403
    end
  end
end
