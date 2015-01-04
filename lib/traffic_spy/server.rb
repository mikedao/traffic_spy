require 'json'
module TrafficSpy
  class Server < Sinatra::Base
    set :views, 'lib/views'

    get '/' do
      erb :index
    end

    post '/sources' do
      status_message = Identifier.register(params)
      status status_message[:status]
      body status_message[:body]
    end

    post '/sources/:identifier/data' do
      status_message = Payload.create(params)
      status status_message[:status]
      body status_message[:body]
    end

    get '/sources/:identifier' do
      identifier         = Identifier.find(params[:identifier])
      @rank_url          = Url.rank_url(identifier)
      @rank_browser      = Agent.rank_browser(identifier)
      @rank_os           = Agent.rank_os(identifier)
      @resolution        = Resolution.display_resolution(identifier)
      @avg_response_time = Url.rank_url_by_reponse_time(identifier)
      erb :identifier_display
    end

    get '/sources/:identifier/urls/:relative_path' do
      identifier = Identifier.find(params[:identifier])
      @url = identifier[:rooturl] +"/"+ params[:relative_path]
      if Url.exists?(@url)
        @longest_response_time = Url.longest_response_time(identifier, @url)
        @shortest_response_time = Url.shortest_response_time(identifier, @url)
        @average_response_time = Url.average_response_time(identifier, @url)
        @http_verbs = Url.http_verbs(identifier, @url)
        @popular_referrers = Url.popular_referrers(identifier, @url)
        @popular_user_agents = Url.popular_user_agents(identifier, @url)
        erb :url_display
      else
        @message = "The url #{@url} has never been requested"
        erb :error
      end
    end

    get '/test/:identifier' do
      identifier = Identifier.find(params[:identifier])
      UserAgent.browser_rank(identifier)
    end

    get '/sources/:identifier/events' do
      identifier = params[:identifier]
      events_list = EventName.display_events(Identifier.find(params[:identifier]))
      erb :events, locals: {events_list: events_list, identifier: identifier}
    end

    not_found do
      erb :error
    end
  end
end
