class Api::ServerapiController < ApplicationController
  layout nil
  before_filter :restrict_ip_visit
  protect_from_forgery  :except => [:create, :archived, :living, :location, :upload]

  #服务器端登录,验证流媒体密码
  def create
    challenge = params[:challenge]
    response = params[:response]
    username = params[:username]
    if User.authenticate_for_mobile?(username, challenge,response)
      render :status => 200, :layout => false, :text => "ok"
    else
      render :status => 400, :layout => false, :text => "fail"
    end
  end

  #save archived xml to database: id, title, author, length, size, encoding, preview, url
  def archived
    archived = Video.find_by_tag_id(params[:id])
    archived.update_attributes({
        :size => params[:size],
        :encoding => params[:encoding],
        :url => params[:url],
        :length => params[:length],
        :preview => params[:preview],
        :vstate => "archived",
        :filesize => params[:filesize].to_f
      }) if archived
    if archived and archived.save
      #events..................
      Rails.logger.info("save video event********************************************************")
      event = Event.new do |e|
        e.user_id  = archived.user_id
        e.model_name = "video"
        e.link_id = archived.id
        e.desc = "拍摄了视频"
      end
      event.save
      Rails.logger.info("archived the video -------------------------------")
      begin
        #current_user.histroy.remove_element(archived.user.id) unless current_user.histroy.nil?
        Juggernaut.publish(["/working","/living"], archived.to_hash)
      rescue Exception => e
        Rails.logger.info("#{e}")
        archived.update_attribute(:vstate, "archived")
      end
      render :text => "ok", :layout => false
    else
      archived.update_attribute(:vstate, "archived")
      render :text => "fail", :layout => false, :status => 400
    end
  end

  #save live.xml to database: tid, title, author,  encoding, url
  def living
    if params[:title].nil? or params[:title].blank?
      params[:title] = '无题'
    end
    living = Video.new
    living.tag_id = params[:id]
    living.title  = params[:title]
    living.encoding = params[:encoding]
    living.url = params[:url]
    living.length = params[:length]
    living.size = params[:size]
    living.shot_time =  Time.at(params[:created].to_i).to_datetime
    user = User.find_by_email_or_phone(params[:username])
    living.user = user
    living.vstate = "living"
    if living.save!
      Rails.logger.info("living the video, push message to /working and /living  -------------------------------")
      Juggernaut.publish(["/working","/living"], living.to_hash)
      render :text => "ok", :layout => false
    else
      render :text => "fail", :layout => false, :status => 400
    end
  end

  #location for video
  def location
    tid = params[:id]
    lat = params[:lat]
    lng = params[:lng]
    video = Video.find_by_tag_id(tid)
    hash = {}
    status = 404
    Rails.logger.info(video.inspect)
    if(video and video.lat.eql?(format("%.4f",lat).to_f) and video.lng.eql?(format("%.4f",lng).to_f))
      Rails.logger.info("--------------------------location still same-----------------------------")
      hash = {:result => "地理坐标没有变化" }
      status = 303
    elsif video and video.update_attributes({:lat => lat, :lng => lng})
      hash = { :result => "ok"}
      status = 200
      Rails.logger.info("push message to -/videos/#{video.id}-----------------------------")
      result = video.to_hash
      result[:type] = "location"
      result[:g_image] = video.static_google_map_photo(240,300,"mp2");
      begin
        Juggernaut.publish(["/videos/#{video.id}", "/working"], result)
      rescue Exception => e
        Rails.logger.info(e)
      end
    else
      hash = { :result => "视频不存在"}
    end
    render :json => hash.to_json, :status => status
  end

  def upload
  #  require 'ruby-debug'
  #  debugger
    user = User.find_by_email(params["username"])
    if user and params and !params.empty? and params.has_key?(:id) and params.has_key?(:url)
    #  Delayed::Job.enqueue(ConvertFile.new(params.to_hash))
    #  render :text => "ok", :layout => false
       video = Video.find_by_tag_id(params["id"])
       p = {
         :title => params["title"] || "无题",
	 :url => "#{params["id"]}.flv",
	 :tag_id => params["id"],
	 :encoding => "flv/mp3/h263",
         :user_id => user.id,
         :length => params[:length] || 100 ,
         :size => params[:size] || "176x144",
	 :shot_time => Time.now
       }
       unless video
         video = Video.create!(p)
       else
         video.update_attributes(p)
       end
       video.convert_3gp_to_flv
       render :text => "ok", :layout => false
    else
      render :text => "fail", :layout => false, :status => 400
    end
  end


  private
  def restrict_ip_visit
    ip = request.remote_ip
    allow_ip_list = ["127.0.0.1", "192.168.1.92", "182.50.0.210","0.0.0.0","192.168.1.104","223.4.10.125"]
    unless allow_ip_list.include?(ip)
      logger.info("#{ip} 越权访问服务端的业务")
      render :text => "forbidden", :status => 403
      return 
    end
  end
  
  
end
