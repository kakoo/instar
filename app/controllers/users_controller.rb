class UsersController < ApplicationController
  # GET /users
  # GET /users.json
  def index
    @users = User.all

    #render :inline => "#{Rails.root.join 'img'}"
    #return

    require 'restclient'
    require 'json'
    #require 'mini_magick'
    require "open-uri"
    require 'tempfile'
    require 'fileutils'
    require 'rmagick'
    require 'pathname'

    photos_per_request = 200
    photos_per_row     = params[:count].to_i || 9
    start_date = Date.parse params[:start_date] || "2013-1-1"
    end_date = Date.parse params[:end_date] || "2013-12-31"

    max_photos = 1000

    if user_signed_in? && !current_user.instagram_id.empty?
      @thumbnails = []
      #firstday = Date.new(start_date).strftime('%s').to_i
      firstday = start_date.strftime('%s').to_i
      logger.debug "firstday ---------------- #{start_date}"



      url = "https://api.instagram.com/v1/users/#{current_user.instagram_id}/media/recent?access_token=#{current_user.instagram_token}&count=#{photos_per_request}"
      while true
        logger.debug "-------------------------------Fetching from #{url}"
        response = RestClient.get url
        feed = JSON.parse response
        logger.debug "------------------------------#{feed['data'].length} has been fetched.----------------------------------------------"
        feed['data'].each {|e| @thumbnails << e if e['created_time'].to_i > 0 }
        logger.debug "------------------------------#{@thumbnails.length} has been filtered.----------------------------------------------"
        logger.debug "Last created_time : #{feed['data'].last['created_time']}"
        break if @thumbnails.length >= max_photos
        break if firstday > feed['data'].last['created_time'].to_i
        url = feed['pagination']['next_url']
        logger.debug "Keep going..."
      end
      logger.debug "You have total #{@thumbnails.length} photos this year."

      @thumbnails.sort! {|x, y| y['likes']['count'] <=> x['likes']['count']}

      logger.debug "------------first count #{@thumbnails.length}"
      @thumbnails = @thumbnails[0..(photos_per_row**2-1)]
      logger.debug "change #{@thumbnails.length}"
      1.upto(photos_per_row) do |i|
        logger.debug "i: #{i}"
        if @thumbnails.length < (i**2)
          @thumbnails = @thumbnails[0..((i-1)**2-1)]
          break
        end
      end
      logger.debug "You have total #{@thumbnails.length} photos this year."

      path = "#{Rails.root}/log/#{current_user.instagram_id}"
      FileUtils.mkdir_p(path) unless File.exists?(path)
      FileUtils.rm_f("#{path}/urls.txt")
      @thumbnails.each do |photo|
        File.open("#{path}/urls.txt", "a+") do |fo|
          fo.write("#{photo['images']['thumbnail']['url']}\n")
          logger.debug photo['images']['thumbnail']['url']
        end
      end


      logger.debug "going to run the script"
      #run the script.
      #`ruby saveimage.rb #{current_user.instagram_id}`

      ruby = `which ruby`.chomp

      logger.debug "ruby path = #{ruby}"

      command = "#{ruby} #{Rails.root}/test/saveimage.rb #{current_user.instagram_id}"

      logger.debug command
      #system command

      case Rails.env
        when /development|test/
          system command
        when /production/
          exec command
      end

      #out = `#{command}`
      #logger.debug out
      logger.debug "finish"
      @out = '/images/' + current_user.instagram_id + '/out.jpg'
      logger.debug @out

      #id       = ARGV.first.to_s
      #path     = Pathname.new($0 + '/../../').realpath()
      #path     = Rails.root
      #url_path = '/Users/kakoo/RubymineProjects/instar/log/' + id

      #id = current_user.instagram_id
      #url_path = Rails.root.join('log', id)
      #img_path = Rails.root.join 'img', id
      #
      ##logger.debug path
      #
      ##puts path
      ##puts url_path
      ##puts img_path
      #
      #line_num=0
      ##text=File.open(url_path + '/urls.txt').read
      #text = url_path.join('urls.txt').read
      #text.gsub!(/\r\n?/, "\n")
      #
      #FileUtils.mkdir_p(img_path) unless File.exists?(img_path)
      #text.each_line do |line|
      #  line_num += 1
      #  #filename =  img_path + "/" + line_num.to_s + ".jpg"
      #  filename =  img_path.join("#{line_num}.jpg")  # + "/" + line_num.to_s + ".jpg"
      #  File.open(filename, "wb") do |fo|
      #    puts filename
      #    fo.write open(line).read
      #  end
      #end
      #
      #row = col = Math.sqrt(line_num).to_i
      #
      #logger.debug "going to make an image file."
      #ilg = Magick::ImageList.new
      #1.upto(col) do |x|
      #  il = Magick::ImageList.new
      #  1.upto(row) do |y|
      #    il.push(Magick::Image.read(img_path + "/" + (y + (x-1)*col).to_s + ".jpg").first)
      #    FileUtils.rm_f(img_path + (y + (x-1)*col).to_s + ".jpg")
      #  end
      #  ilg.push(il.append(false))
      #end
      #ilg.append(true).write(img_path + "/out.jpg")


    end

    logger.debug "done"


    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @users }
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end
end
