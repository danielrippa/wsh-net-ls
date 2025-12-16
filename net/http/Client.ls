
  do ->

    { create-error-context } = dependency 'prelude.error.Context'
    { create-instance } = dependency 'value.Instance'
    { create-xml-http } = dependency 'os.com.XmlHttp'
    { encode-object } = dependency 'net.URI'
    { compose-with } = dependency 'value.instance.Composition'
    { deserialize-object } = dependency 'value.Object'

    { argtype } = create-error-context 'net.http.Client'

    json-mime-type = 'application/json' ; form-mime-type = 'application/x-www-form-urlencoded'

    request-states = <[ pending connecting loading complete error timeout ]>

    request-transitions =

      connect: <[ pending connecting ]>
      start-loading: <[ connecting loading ]>
      receive-chunk: <[ loading loading ]>
      finish: <[ loading complete ]>
      fail: <[ pending error ]>
      fail-loading: <[ loading error ]>
      fail-connecting: <[ connecting error ]>
      timeout: <[ loading timeout ]>

    request-events = <[ chunk complete error timeout ]>

    create-response = (http) ->

      { status, status-text, response-text, response-body } = http
      { ok: status >= 200 and status < 300, status, content: response-text, get-header: ((name) -> http.get-response-header name), get-all-headers: (-> get-all-response-headers!) }

    create-async-request = (http, content) ->

      create-instance do

        state: state: [ request-states, request-transitions, 'request' ]

        notifier: notifier: request-events

        start: method: ->

          last-position = 0

          http.onreadystatechange = ->

            switch http.ready-state

              | 1 => @connect!
              | 2 => @start-loading!
              | 3 =>

                text = http.response-text
                chunk = text.substring last-position
                last-position := text.length

                if chunk.length > 0
                  @receive-chunk! ; @notify <[ chunk ]>,chunk, http

              | 4 =>

                response = create-response http ; { ok } = response

                if ok is yes
                  @finish! ; @notify <[ complete ]>, response
                else
                  @fail-loading! ; @notify <[ error ]>, response

          try http.send content
          catch error => @fail-loading! ; @notify <[ error ]>, { ok: no, status: 0, content: error.message }

    #

    synchronous-request = (http, content) -> http.send content ; create-response http

    #

    set-request-headers = (http, headers) -> for key, value of headers => http.set-request-header key, value

    url-and-query = (url, query = {}) ->

      query-string = encode-object query ; if query-string isnt '' => query-string = "?#query-string"

      "#url#query-string"

    request = (method, url, options = {}) ->

      { query, headers, content-type, content, timeout, async = no } = options

      full-url = if query isnt void then url-and-query url, query else url

      http = create-xml-http! => ..open method, full-url, (argtype '<Boolean>' {async})

      if (argtype '<String|Void>' {content-type}) isnt void => http.set-request-header 'Content-Type', content-type

      set-request-headers http, headers

      if (argtype '<Number|Void>' {timeout}) isnt void => try http.set-timeouts timeout, timeout, timeout

      if async is yes

        create-async-request http, content => ..start!

      else

        synchronous-request http, content

    request-with-content = (method, url, content, options) -> request method, url { ...options, content }

    #

    create-methods = (get-fn, with-data-fn) ->

      get: method: (url, options) -> get-fn 'GET', url, options
      post: method: (url, data, options) -> with-data-fn 'POST', url, data, options
      put: method: (url, data, options) -> with-data-fn 'PUT', url, data, options
      patch: method: (url, data, options) -> with-data-fn 'PATCH', url, data, options
      delete: method: (url, options) -> get-fn 'DELETE', url, options

    create-form-method = (request-fn) -> (url, data, options = {}, method = 'POST') ->

      request-fn method, url, { ...options, content-type: form-mime-type, content: encode-object data }

    #

    create-http-client = ->

      instance = create-instance create-methods request, request-with-content

      head-and-form = create-instance do

        head: method: (url, options) -> request 'HEAD', url, options
        form: method: create-form-method request

      instance `compose-with` [ head-and-form ]

    #

    json-headers = (options) -> { ...options.headers, 'Accept': json-mime-type }

    json-options = (options) -> { ...options, headers: json-headers options }

    json-options-with-data = (data, options) ->

      content-type = json-mime-type ; content = if data isnt void then stringify data else void

      { ...options, content-type, content, headers: json-headers options }

    response-json = (response) ->

      { ok, content } = response ; return null unless ok and content.length > 0
      deserialize-object content

    parse-json-response = (response) -> response => ..json = response-json response

    json-request = (method, url, data-or-options, options) ->

      request method, url, (if options isnt void then json-options-with-data data-or-options, options else json-options data-or-options) |> parse-json-response

    json-request-with-data = (method, url, data, options) -> json-request method, url, data, options

    create-json-http-client = ->

      instance = create-instance create-methods json-request, json-request-with-data

      json-form = create-instance form: create-form-method (method, url, options) -> request method, url, options |> parse-json-response

      instance `compose-with` [ json-form ]

    {
      create-http-client,
      create-json-http-client
    }
