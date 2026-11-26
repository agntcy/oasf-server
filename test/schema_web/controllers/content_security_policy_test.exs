# Copyright AGNTCY Contributors (https://github.com/agntcy)
# SPDX-License-Identifier: Apache-2.0

defmodule SchemaWeb.ContentSecurityPolicyTest do
  use SchemaWeb.ConnCase, async: false

  test "browser pages send a Content-Security-Policy" do
    conn = get(build_conn(), "/")

    assert conn.status == 200
    assert [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "default-src 'self'"
    assert csp =~ "object-src 'none'"
    assert csp =~ "frame-ancestors 'self'"
  end
end
