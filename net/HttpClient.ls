
  do ->

    { create-error-context } = dependency 'prelude.error.Context'
    { create-instance } = dependency 'value.Instance'
    { create-xml-http } = dependency 'os.com.XmlHttp'
    { string-loosely-equals: loosely-equals } = dependency 'value.string.Case'
    { string-contains-segment: contains } = dependency 'value.string.Segment'

    { argtype, create-error } = create-error-context 'web.HttpClient'

    set-request-headers = (http, headers) -> for key, value of headers => http.set-request-header key, value

    asynchronous-request = (http, content, on-ready-state-change) ->

      if on-ready-state-change is void => throw create-error "Async requests require on-ready-state-change handler."

      http

        ..onreadystatechange = -> on-ready-state-change http
        ..send content

    synchronous-request = (http, content) ->

      http.send content ; { status, status-text, response-text, response-body } = http

      { ok: status >= 200 and status < 300, status, content: response-text, get-header: ((name) -> http.get-response-header name), get-all-headers: (-> get-all-response-headers!) }

    encode = -> encodeURIComponent it

    url-and-query = (url, query) ->

      components = [ "#{ encode key }=#{ encode value }" for key, value of query ] * '&'
      separator = if url `contains` '?' then '&' else '?'

      "#url#separator#components"

    request = (method, url, options = {}) ->

      { query, headers, content-type, content, timeout, async = no, on-ready-state-change } = options

      full-url = url-and-query url, query

      http = create-xml-http! => ..open method, full-url, (argtype '<Boolean>' {async})

      if (argtype '<String|Void>' {content-type}) isnt void => http.set-request-header 'Content-Type', content-type

      set-request-headers http, headers

      if (argtype '<Number|Void>' {timeout}) isnt void => try http.set-timeouts timeout, timeout, timeout

      if async => asynchronous-request http else synchronous-request http

    create-http-client = ->

      create-instance do

        get: method: (url, options) -> request 'GET', url, options
        post: method: (url, content, options) -> request 'POST', url, { ...options, content }
        put: method: (url, content, options) -> request 'PUT', url, { ...options, content }
        patch: method: (url, content, options) -> request 'PATCH', url, { ...options, content }
        delete: method: (url, options) -> request 'DELETE', url, options
        head: method: (url, options) -> request 'HEAD', url, options

    #

    json-mime-type = 'application/json'

    json-headers = (options) -> { ...options.headers, 'Accept': json-mime-type }

    json-options = (options) -> { ...options, headers: json-headers options }

    json-options-with-data = (data, options) ->

      content-type = json-mime-type ; content = if data isnt void then stringify data else void

      headers = json-headers options.headers

      { ...options, content-type, content, headers }

    response-json = (response) ->

      { ok, content } = response ; return null unless ok and content.length > 0
      eval "(#content)"

    parse-json-response = (response) -> response => ..json = response-json response

    json-request = (method, url, data-or-options, options) ->

      request method, url, (if options isnt void then json-options-with-data data-or-options, options else json-options data-or-options) |> parse-json-response

    create-json-http-client = ->

      create-instance do

        get: method: (url, options) -> json-request 'GET', url, options
        post: method: (url, data, options) -> json-request 'POST', url, data, options
        put: method: (url, data, options) -> json-request 'PUT', url, data, options
        patch: method: (url, data, options) -> json-request 'PATCH', url, data, options
        delete: method: (url, options) -> json-request 'DELETE', url, options

    #

    form-mime-type = 'application/x-www-form-urlencoded'

    encode-form-data = (data) -> [ "#{ encode-URI-component key }=#{ encode-URI-component value }" for key, value of data ] * '&'

    form-request = (method, url, data, options) -> content-type = form-mime-type ; content = encode-form-data data ; { ...options, content-type, content }

    {
      create-http-client, create-json-http-client,
      encode-form-data, form-request
    }