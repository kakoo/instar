class UsersController < ApplicationController
  # GET /users
  # GET /users.json
  def index
    @users = User.all

    require 'restclient'
    require 'json'
    require 'mini_magick'


    if user_signed_in? && !current_user.instagram_id.empty?
      @thumbnails = []
      firstday = Date.new(2012, 1, 1).strftime('%s').to_i
      c = 60
      url = "https://api.instagram.com/v1/users/#{current_user.instagram_id}/media/recent?access_token=#{current_user.instagram_token}&count=#{c}"
      while true
        logger.debug "Fetching from #{url}"
        response = RestClient.get url
        feed = JSON.parse response
        feed['data'].each {|e| @thumbnails << e if e['created_time'].to_i >= firstday }
        logger.debug "#{@thumbnails.length} has been fetched."
        logger.debug "Last created_time : #{feed['data'].last['created_time']}"
        break if @thumbnails.length >= 900
        break if firstday > feed['data'].last['created_time'].to_i
        url = feed['pagination']['next_url']
        logger.debug "Keep going..."
      end
      logger.debug "You have total #{@thumbnails.length} photos this year."

      @thumbnails.sort! {|x, y| y['likes']['count'] <=> x['likes']['count']}

      @thumbnails = @thumbnails[0..99]
      1.upto(9) do |i|
        if @thumbnails.length <= (i*i)
          j = i-1
          @thumbnails = @thumbnails[0..(j*j-1)]
          break
        end
      end
    end

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
