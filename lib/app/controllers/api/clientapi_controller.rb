class Api::ClientapiController < ApplicationController
  layout nil
  protect_from_forgery :except => [:upload_file, :update]

  # private final static String  REGISTER_HTTP_INFO_USER_EXIST = "username_exist";
  #	private final static String  REGISTER_HTTP_INFO_EMAIL_EXIST = "email_exist";
  #	private final static String  REGISTER_HTTP_INFO_PHONE_EXIST = "phone_exist";
  def register
    u = User.new do |obj|
      obj.username = params[:username]
      obj.password = params[:password]
      obj.email = params[:email]
      obj.phone = params[:phone] || ""
    end
    if u.valid? and  u.errors.empty? and u.save
      logger.info("save the user data, and return ok")
      render :text => "ok"
    else
      render :status => 400, :text =>  u.errors.each_full{|msg| msg.gsub!(' ','')}.join(",")
    end
  end


  # new login api for client(android, iphone, ...)
  # ======params
  # <tt>:usr</tt> -- username
  # <tt>:pwd</tt> -- password
  # <tt>:ver</tt> -- version, <platform ><enterprise><svn release> format string  s0000126 => s|a|i + 0000() + 128(svn version)
  # ======return json string
  #  {
  #  "newversion" => true,
  #  "url" => "http://url/welcome/download?soft=android&from=0000&version=125",
  #  "ss_key" => "xxxxxxxxxxxxxxxxxxxxxxxxxxx",
  #  "key_duration" => 1200,
  #  "ss_ip" => "rayclear.com",
  #  "ss_port" => "25412"
  #  }
  #判断是否有版本更新
  #soft: soft system
  #company: default 000
  #ver: 版本号
  #filename: 文件名
  #upgrade_to(default => 0): 升级到的版本
  #生成密钥
  #request.session_options[:id]
  def login2
    username = params[:username]
    password = params[:password]
    ver = params[:ver]
    hash = User.login_from_client(username, password, ver, {:key => request.session_options[:id], :host_with_port => request.host_with_port})
    logger.info(hash.inspect)
    status = hash.has_key?(:reason) ? 404 : 200
    render :json => hash.to_json, :layout => false, :status => status
  end

  #upgrade soft for client
  #file name is :  filename_time_version.type(apk...)
  def upgrade
    ver = params[:ver]
    soft = SoftVersion.find_new_version_by_ver(ver)
    hash = {}
    if soft
      hash[:newversion] = true
      hash[:url] = "http://#{request.host_with_port}/welcome/download?soft=#{soft.soft_name}&version=#{soft.version}"
    else
      hash["newversion"] = false
      hash["url"] = "no upgrade"
    end

    #    hash = {
    #      "newversion" => true,
    #      "url" => "http://192.168.1.92/welcome/download?soft=android&from=upgrade"
    #    }
    render :json => hash.to_json, :layout => false
  end

  #upload the address list
  #eg:
  #
  #  def upload_address
  #    #debugger
  #    username = params[:username]
  #    password = params[:ss_key]
  #    phones = params[:phones]
  #    hash = {}
  #    user = User.authenticate_flow?(username, password)
  #    if(user)
  #      phones_arr = parse_json_to_array(phones)
  #      phones_arr.uniq.each do |phone|
  #        Address.create({:user_id => user.id, :phone => phone })
  #      end
  #      hash[:result] = true
  #    else
  #      hash[:result] = false
  #      hash[:reason] = "username or password was wrong"
  #    end
  #    render :layout => false, :json => hash.to_json
  #  end



  def update
    id = params[:id]
    living = Video.find_by_tag_id(id)
    if living
      Rails.logger.info(living.inspect)
      if params[:title]
        unless living.title.eql?(params[:title])
          data = {}
          data[:type] = "title"
          data[:title] = params[:title]
          data[:id] = living.id
          begin
            Juggernaut.publish(["/working","/videos/#{living.id}"], data) if living.living?
          rescue => e
            logger.info("#{e}")
          end
          living.title = params[:title]
        end
        living.save!
      end

      render :text => "ok"
    else
      render :text => "fail", :status => 403
    end
  end

  #upload file,没有认证
  def upload_file
    filename = User.save_log(params[:file])
    recipient = ["wen-hanyang@163.com", "hexudong08@gmail.com"]
    subject = "客户端日志bug文件"
    LoggerMailer.deliver_contact(recipient, subject, filename)
    render :json => {:result => "ok"}.to_json
  end

  
end
