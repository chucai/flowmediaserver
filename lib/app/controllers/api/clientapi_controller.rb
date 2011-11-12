class Api::ClientapiController < ApplicationController
  layout nil
  #protect_from_forgery :except => [:upload_file, :update]
  before_filter :authenticate_user!, :except => [:register, :upgrade]

  def register
    respond_to do |wants|
      wants.json  {
        user  = User.new(params[:user])
        result = {}
        if  user.save
          logger.info("save the user data, and return ok")
          result[:result] = "register success"
          render :json => result.to_json
        else
          result[:result] = user.errors_full_messages
          render :status => 400, :json => user 
        end
      }
    end
  end

  #upgrade soft for client
  #file name is :  filename_time_version.type(apk...)
  #params
  # =>ver: a0000128
  def upgrade
    respond_to do |wants|
      wants.json {
        ver = params[:ver]
        soft = SoftVersion.find_new_version_by_ver(ver)
        hash = {}
        if soft and soft.is_a?SoftVersion
          hash[:newversion] = true
          hash[:url] = "http://#{request.host_with_port}/welcome/download?soft=#{soft.soft_name}&version=#{soft.version}"
        else
          hash["newversion"] = false
          hash["url"] = "No new version"
        end
        render :json => hash.to_json, :layout => false
      }
    end

  end


  #update video title , should sign in
  #params
  # =>tid=xxxxxx&video[:title]=xxxxxxxx
  def update
    respond_to do |wants|
      wants.json {
        result = {}
        video = Video.find_by_tag_id(params[:tid])
        if video
          if video.update_attributes(params[:video])
            result[:result] = "ok"
            render :json => result.to_json
            return
          else
            result[:result] = video.errors_full_messages
          end
        else
          result[:result] = "不存在该视频"
        end
        render :json => result.to_json, :status => 400
      }
    end
  end

  #cookie auth
  #format: json
  def upload_file
    respond_to do |wants|
      wants.json{
        filename = User.save_log(params[:file])
        recipient = ["wen-hanyang@163.com", "hexudong08@gmail.com"]
        subject = "客户端日志bug文件"
        LoggerMailer.deliver_contact(recipient, subject, filename)
        render :json => {:result => "ok"}.to_json
      }
    end
  end

  
end
