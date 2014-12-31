require 'json'
module TrafficSpy

  # Sinatra::Base - Middleware, Libraries, and Modular Apps
  #
  # Defining your app at the top-level works well for micro-apps but has
  # considerable drawbacks when building reusable components such as Rack
  # middleware, Rails metal, simple libraries with a server component, or even
  # Sinatra extensions. The top-level DSL pollutes the Object namespace and
  # assumes a micro-app style configuration (e.g., a single application file,
  # ./public and ./views directories, logging, exception detail page, etc.).
  # That's where Sinatra::Base comes into play:
  #
  class Server < Sinatra::Base
    set :views, 'lib/views'

    get '/' do
      erb :index
    end

    post '/sources' do

      if params["identifier"].nil? || params["rootUrl"].nil?
        status 400
        body "Missing parameters\n"
      elsif DB.from(:identifiers).select(:identifier).to_a.any?{ |identifier| identifier[:identifier] == params[:identifier] }
        status 403
        body "Identifier already exists\n"
      else
        DB.from(:identifiers).insert(:identifier => params["identifier"], :rooturl => params["rootUrl"])
        # => p DB.from(:identifiers).select(:identifier).to_a
        status 200
        body "Success " + {identifier: params["identifier"]}.to_json + "\n"
      end
    end

    post '/sources/:identifier/data' do
        # puts params[:identifier]
      if params["payload"].nil? || params["payload"].empty?
        status 400
        body "Missing Payload"
      elsif !DB.from(:identifiers).select(:identifier).to_a.any?{|identifier| identifier[:identifier] == params[:identifier]}
        status 403
        body "Application Not Registered"
      else
        payload_hash = JSON.parse(params[:payload])
        incoming_url = payload_hash["url"]
        incomng_identifier = params["identifier"]
        requested_at = payload_hash["requested_at"]
        responded_in = payload_hash["responded_in"]

        incoming_referred_by = payload_hash["referred_by"]
        referred_by_id = referred_by_table(incoming_referred_by)
        parameters = payload_hash["parameters"]
        incoming_event_name = payload_hash["eventName"]
        event_name_id = event_names_table(incoming_event_name)
        incoming_user_agent = payload_hash["userAgent"]
        user_agent_id = user_agents_table(incoming_user_agent)
        incoming_ip = payload_hash["ip"]
        ip_id = ip_table(incoming_ip)

        incoming_request_type =payload_hash["request_type"]
        request_type_id = find_request_type_id(incoming_request_type)

        resolution_width = payload_hash["resolutionWidth"]
        resolution_height = payload_hash["resolutionHeight"]
        resolution_id = find_resolution_id(resolution_width, resolution_height)

        puts "Incoming URL: #{incoming_url}"

        if DB.from(:urls).select(:url).to_a.any? {|item| item[:url] == incoming_url }
          url_id = DB.from(:urls).select(:id).where(:url => incoming_url)
          puts "We found URL ID"
        else
          puts "we didn't find URL ID"
          DB.from(:urls).insert(:url => incoming_url)
          url_id = DB.from(:urls).where(:url => incoming_url)
          # url_id = DB.from("urls").select("id").where("url" => incoming_url)
        end
      end
      puts "url_id #{url_id.to_a[0][:id]}"
      puts "referred_by_id: #{referred_by_id}"
      puts "request_type_id: #{request_type_id}"
      puts "resolution_id: #{resolution_id}"
      puts "event_name_id: #{event_name_id}"
      puts "user_agent_id: #{user_agent_id}"
      puts "ip_id: #{ip_id}"
      status 200
    end

    not_found do
      erb :error
    end


    def referred_by_table(incoming_referred_by)
      if DB.from(:referred_bys).select(:referred_by).to_a.any? {|item| item[:referred_by] == incoming_referred_by }
        referred_by_id = DB.from(:referred_bys).select(:id).where(:referred_by => incoming_referred_by)
        puts "We found referred by"
      else
        puts "we didn't find referred by"
        DB.from(:referred_bys).insert(:referred_by => incoming_referred_by)
        referred_by_id = DB.from(:referred_bys).where(:referred_by => incoming_referred_by)
        # url_id = DB.from("urls").select("id").where("url" => incoming_url)
      end
      referred_by_id.to_a[0][:id]
    end

    def find_request_type_id(incoming_request_type)
      if DB.from(:request_types).select(:request_type).to_a.any? {|item| item[:request_type] == incoming_request_type }
        request_type_id = DB.from(:request_types).select(:id).where(:request_type => incoming_request_type)
        puts "We found request type"
      else
        puts "we didn't find request type"
        DB.from(:request_types).insert(:request_type => incoming_request_type)
        request_type_id = DB.from(:request_types).where(:request_type => incoming_request_type)
      end
      request_type_id.to_a[0][:id]
    end

    def find_resolution_id(resolution_width, resolution_height)
      if DB.from(:resolutions).select(:width, :height).to_a.any? {|item| item[:width] == resolution_width && item[:height] == resolution_height}
        resolution_id = DB.from(:resolutions).select(:id).where(:width => resolution_width).where(:height => resolution_height)
        puts "We found resolution"
      else
        puts "we didn't find resolution"
        DB.from(:resolutions).insert(:width => resolution_width, :height => resolution_height)
        resolution_id = DB.from(:resolutions).where(:width => resolution_width, :height => resolution_height)
      end
      resolution_id.to_a[0][:id]
    end

    def event_names_table(incoming_event_name)
      if DB.from(:event_names).select(:event_name).to_a.any? {|item| item[:event_name] == incoming_event_name }
        event_name_id = DB.from(:event_names).select(:id).where(:event_name => incoming_event_name)
        puts "We found event name"
      else
        puts "we didn't find event name"
        DB.from(:event_names).insert(:event_name => incoming_event_name)
        event_name_id = DB.from(:event_names).where(:event_name => incoming_event_name)
        # url_id = DB.from("urls").select("id").where("url" => incoming_url)
      end
      event_name_id.to_a[0][:id]
    end

    def user_agents_table(incoming_user_agent)
      if DB.from(:user_agents).select(:user_agent).to_a.any? {|item| item[:user_agent] == incoming_user_agent }
        user_agent_id = DB.from(:user_agents).select(:id).where(:user_agent => incoming_user_agent)
        puts "We found user agents"
      else
        puts "we didn't find user agents"
        DB.from(:user_agents).insert(:user_agent => incoming_user_agent)
        user_agent_id = DB.from(:user_agents).where(:user_agent => incoming_user_agent)
        # url_id = DB.from("urls").select("id").where("url" => incoming_url)
      end
      user_agent_id.to_a[0][:id]
    end

    def ip_table(incoming_ip)
      if DB.from(:ips).select(:ip).to_a.any? {|item| item[:ip] == incoming_ip }
        ip_id = DB.from(:ips).select(:id).where(:ip => incoming_ip)
        puts "We found ip"
      else
        puts "we didn't find ip"
        DB.from(:ips).insert(:ip => incoming_ip)
        ip_id = DB.from(:ips).where(:ip => incoming_ip)
        # url_id = DB.from("urls").select("id").where("url" => incoming_url)
      end
      ip_id.to_a[0][:id]
    end
  end
end
