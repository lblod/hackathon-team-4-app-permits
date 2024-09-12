defmodule Dispatcher do
  use Matcher
  define_accept_types [
    html: [ "text/html", "application/xhtml+html" ],
    json: [ "application/json", "application/vnd.api+json" ]
  ]

  @any %{}
  @json %{ accept: %{ json: true } }
  @html %{ accept: %{ html: true } }

  define_layers [ :static, :services, :fall_back, :not_found ]

  # In order to forward the 'themes' resource to the
  # resource service, use the following forward rule:
  #
  # match "/themes/*path", @json do
  #   Proxy.forward conn, path, "http://resource/themes/"
  # end
  #
  # Run `docker-compose restart dispatcher` after updating
  # this file.


  # FRONTEND

  match "/assets/*path", %{ layer: :static } do
    Proxy.forward conn, path, "http://frontend/assets/"
  end

  match "/@appuniversum/*path", %{ layer: :static } do
    Proxy.forward conn, path, "http://frontend/@appuniversum/"
  end

  match "/*path", %{ layer: :fall_back } do
    Proxy.forward conn, [], "http://frontend/index.html"
  end


  # METIS SUBJECT-PAGES BACKEND

  get "/uri-info/*path", %{ accept: %{ json: true }, layer: :services } do
    forward conn, path, "http://uri-info/"
  end

  get "/resource-labels/*path", %{ accept: %{ json: true }, layer: :services } do
    forward conn, path, "http://resource-labels-cache/"
  end

  get "/id-search/*path", %{ accept: %{ json: true }, layer: :services } do
    forward conn, path, "http://idsearch/"
  end


  # FALLBACK ERROR PAGES

  match "/*_", %{ layer: :not_found } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end
end
