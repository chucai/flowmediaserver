#  map.connect "api/update.:format", :namespace  => "api", :controller => "clientapi", :action => "update"
#  map.connect "api/register.:format", :namespace  => "api", :controller => "clientapi", :action => "register"
#  map.connect "api/upgrade.:format", :namespace  => "api", :controller => "clientapi", :action => "upgrade"
#  map.connect "api/uploadfile.:format", :namespace  => "api", :controller => "clientapi", :action => "upload_file"
module Flowmediaserver #nodoc
  module Routing #nodoc 
    module MapperExtensions
      def flow_routes
        @set.add_route("/api/update.:format", {:namespace => "api", :controller => "clientapi", :action => "update" })   
        @set.add_route("/api/register.:format", {:namespace => "api", :controller => "clientapi", :action => "register" })   
        @set.add_route("/api/upgrade.:format", {:namespace => "api", :controller => "clientapi", :action => "upgrade" })   
        @set.add_route("/api/uploadfile.:format", {:namespace => "api", :controller => "clientapi", :action => "update_file" })   
      end
    end
  end
end

ActionController::Routing::RouteSet::Mapper.send :include, Flowmediaserver::Routing::MapperExtensions
