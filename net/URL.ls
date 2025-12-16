
  do ->

    { create-error-context } = dependency 'prelude.error.Context'
    { create-instance } = dependency 'value.Instance'
    { is-empty-array, map-array-items } = dependency 'value.Array'
    { object-member-names } = dependency 'value.Object'
    { encode-object } = dependency 'net.URI'

    { argtype, create-error } = create-error-context 'net.URL'

    slash = '/'

    secure-schemes = { [ scheme, "#{scheme}s" ] for scheme in <[ http ftp ws ]> }

    join-path = -> it * "#slash"

    serialize-url = (scheme, secure, host, port, path, query, fragment) ->

      if scheme is '' => scheme = 'http'

      actual-scheme = if secure then secure-schemes[scheme] else scheme

      authority = join-path [ '', '', (if port is '' then host else "#host:#port") ]

      path-string = if is-empty-array path then '' else "#{ join-path [ '' ] ++ path }"

      query-string = if is-empty-array object-member-names query then '' else "?#{ encode-object query }"

      fragment = if fragment is '' then '' else "##fragment"

      "#actual-scheme:#authority#path-string#query-string#fragment"

    port-as-string = (port) ->

      switch typeof port

        | 'number' => "#port"
        | 'string' =>

          if port is ''
            port
          else

            number = parse-int port
            throw create-error "Invalid port value '#port'" if isNaN number
            "#number"

        | void => ''

        else throw create-error "Invalid port value '#port'"

    validate-url-options = (options) ->

      { scheme = '', secure = yes, port = '', path = [], query = {}, fragment = '' } = (argtype '<Object>' {options})

      argtype '<String>' {scheme} ; argtype '<Boolean>' {secure} ; argtype '[ *:String ]' {path} ; argtype '<String>' {fragment}

      { scheme, secure, port: (port-as-string port), path, query, fragment }

    create-url-builder = (host, options = {}) ->

      { scheme, secure, port, path, query, fragment } = validate-url-options options

      create-instance do

        path: getter: -> path
        secure: getter: -> secure
        port: getter: -> port
        query: getter: -> query
        fragment: getter: -> fragment

        clone-with: method: (options) ->

          { scheme: new-scheme, secure: new-secure, port: new-port, path: new-path, query: new-query, fragment: new-fragment } = (argtype '<Object>' {options})

          if new-scheme is void => new-scheme = scheme
          if new-secure is void => new-secure = secure
          if new-port is void => new-port = port
          if new-path is void => new-path = path
          if new-query is void => new-query = query
          if new-fragment is void => new-fragment = fragment

          create-url-builder host, { scheme: new-scheme, secure: new-secure, port: new-port, path: new-path, query: new-query, fragment: new-fragment }

        with-path: method: (additional-path) -> new-path = @get-path! ++ (argtype '<Array>' {additional-path}) ; @clone-with { path: new-path }

        as-string: method: -> serialize-url scheme, secure, host, port, path, query, fragment

    urls-from-url-builder = (url-builder, paths) -> argtype '<Array>' {paths} ; builders = [ (url-builder.with-path path) for path in paths ] ; map-array-items builders, (.as-string!)

    {
      create-url-builder,
      urls-from-url-builder
    }