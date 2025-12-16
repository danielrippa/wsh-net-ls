
  do ->

    { create-instance } = dependency 'value.Instance'
    { get: get-env-var } = dependency 'os.shell.EnvVar'
    { string-replace-segment: replace } = dependency 'value.string.Segment'
    { lower-case, camel-case } = dependency 'value.string.Case'

    { debug } = dependency 'os.shell.IO'

    cgi-vars = <[
      REQUEST_METHOD QUERY_STRING CONTENT_TYPE CONTENT_LENGTH
      PATH_INFO PATH_TRANSLATED SCRIPT_NAME SCRIPT_FILENAME
      SERVER_NAME SERVER_PORT SERVER_PROTOCOL SERVER_SOFTWARE
      GATEWAY_INTERFACE REMOTE_ADDR REMOTE_HOST REMOTE_USER
      AUTH_TYPE
    ]>

    http-headers = <[
      ACCEPT ACCEPT_ENCODING ACCEPT_LANGUAGE
      USER_AGENT REFERER COOKIE HOST CONNECTION
      CACHE_CONTROL PRAGMA
    ]>

    request-var-name = (name) -> name |> lower-case |> replace _ , [ '_', '-' ] |> camel-case

    get-cgi-request = ->

      request = { [ (request-var-name var-name), (get-env-var var-name) ] for var-name in cgi-vars }

        .. <<< headers: { [ (request-var-name var-name), (get-env-var "HTTP_#var-name") ] for var-name in http-headers }

    {
      get-cgi-request
    }